--[[=====================================================================
  SOVEREIGN STABLES · WAGON OWNERSHIP  (server, authoritative)
  ---------------------------------------------------------------------
  The horse rules apply here unchanged: the client never decides price,
  permission or funds — it only asks. Every money-moving action is written
  to the ledger (X2) so the economy stays auditable.

  Deliberately a near-mirror of server/horses.lua rather than a shared
  generic. The two diverge from Phase 5 (work wagons, crafting, wheel
  damage) and a merged abstraction would only have to be unpicked.
=====================================================================]]--

Wagons = Wagons or {}

local busy = {}   -- [src] = true while a purchase is in flight (anti-spam/dupe)

--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------
function Wagons.listOwned(charid)
    return Db.awaitQuery(
        'SELECT id, name, model, is_default, stable_origin, health, tint FROM sovereign_wagons WHERE charid = ? ORDER BY id',
        { charid }) or {}
end

function Wagons.countOwned(charid)
    local rows = Db.awaitQuery('SELECT COUNT(*) AS n FROM sovereign_wagons WHERE charid = ?', { charid })
    return (rows and rows[1] and rows[1].n) or 0
end

local function logLedger(charid, action, subject, cash, gold, meta)
    if not (Config.Economy and Config.Economy.transactionLog) then return end
    Db.execute('INSERT INTO sovereign_ledger (charid, action, subject, cash, gold, meta) VALUES (?, ?, ?, ?, ?, ?)',
        { charid, action, subject, cash or 0, gold or 0, meta and json.encode(meta) or nil })
end

-- Same sanitizer rules as horse names [N8]: never trust a client string.
local function sanitizeName(raw, fallback)
    if type(raw) ~= 'string' then return fallback end
    local s = raw:gsub('[%c]', ' '):gsub('[<>~\\]', ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then return fallback end
    if #s > 24 then s = s:sub(1, 24) end
    return s
end

-- Does this stable actually sell this wagon? (Stops a spoofed model id.)
local function stableSells(stableId, model)
    for _, w in ipairs(Catalog.wagonsFor(stableId)) do
        if w.model == model then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- Purchase
--------------------------------------------------------------------------------
-- Returns ok:boolean, message:string
function Wagons.buy(src, stableId, model, wanted)
    if not (Config.Economy and Config.Economy.enableBuying) then
        return false, 'The stables are not selling today.'
    end

    local charid = Bridge.getCharId(src)
    if not charid then return false, 'No active character.' end

    if not Config.Stables[stableId] then return false, 'Unknown stable.' end
    if not stableSells(stableId, model) then return false, 'This stable does not sell that wagon.' end

    local card = Catalog.wagon(model)
    if not card or card.buyable == false then return false, 'That wagon is not for sale.' end

    -- Job / stable permission (same gate as horses)
    local job = Bridge.getJob(src)
    local allowed, why = Catalog.canBuy(card, stableId, job)
    if not allowed then return false, why or 'You may not buy that here.' end

    -- Ownership cap (global vs job cap, whichever is stricter)
    local cap   = Perms.maxWagons(job)
    local owned = Wagons.countOwned(charid)
    if owned >= cap then
        return false, ('You already keep %d wagon(s) — your limit.'):format(cap)
    end

    -- Price + funds (server-side price, never the client's)
    local cash = (card.price and card.price.cash) or 0.0
    local gold = (card.price and card.price.gold) or 0.0
    if not (Config.Economy.enableGold) then gold = 0.0 end
    if not Bridge.canAfford(src, cash, gold) then
        return false, "You can't afford that."
    end
    if not Bridge.charge(src, cash, gold) then
        return false, 'Payment failed.'
    end

    wanted = wanted or {}
    local name = sanitizeName(wanted.name, card.name or card.label or model)

    -- First wagon becomes the default.
    local isDefault = (owned == 0) and 1 or 0
    local id = Db.awaitInsert(
        'INSERT INTO sovereign_wagons (identifier, charid, name, model, stable_origin, is_default, tint) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { Bridge.getIdentifier(src), charid, name, model, stableId, isDefault, card.defaultTint })

    if not id then
        Bridge.pay(src, cash, gold)   -- refund: never take money without a wagon
        return false, 'The paperwork failed — you were not charged.'
    end

    logLedger(charid, 'buy_wagon', model, cash, gold, { stable = stableId, wagonId = id, name = name })
    Util.log(('char %s bought wagon %s (%s) at %s for %s/%s (wagon #%s)'):format(
        charid, model, name, stableId, cash, gold, id))
    return true, ('%s is yours.'):format(name)
end

--------------------------------------------------------------------------------
-- Net events
--------------------------------------------------------------------------------
local function pushOwnedWagons(src, charid)
    TriggerClientEvent(Events.OwnedWagonData, src, {
        owned = Wagons.listOwned(charid),
        cap   = Perms.maxWagons(Bridge.getJob(src)),
    })
end
Wagons.push = pushOwnedWagons

RegisterNetEvent(Events.RequestBuyWagon, function(stableId, model, wanted)
    local src = source
    if busy[src] then return end
    busy[src] = true
    CreateThread(function()
        local ok, msg = false, 'Something went wrong.'
        local success, err = pcall(function() ok, msg = Wagons.buy(src, stableId, model, wanted) end)
        if not success then Util.err('wagon purchase failed: ' .. tostring(err)) end

        local cash, gold = Bridge.getBalance(src)
        TriggerClientEvent(Events.PurchaseResult, src, { ok = ok, message = msg, cash = cash, gold = gold })
        local charid = Bridge.getCharId(src)
        if ok and charid then pushOwnedWagons(src, charid) end
        busy[src] = nil
    end)
end)

RegisterNetEvent(Events.RequestOwnedWagons, function()
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if charid then pushOwnedWagons(src, charid) end
    end)
end)

--------------------------------------------------------------------------------
-- Call a wagon out  [WG2]
--   Wagons have no whistle rule (they don't come when called from a hilltop) —
--   but they DO honour the recall cooldown, so a wagon can't be spammed in and
--   out to dodge damage or reset a wreck.
--------------------------------------------------------------------------------
local wagonCooldown = {}   -- [charid][wagonId] = os.time() when callable again

local function cdLeft(charid, wagonId)
    local c = wagonCooldown[charid]
    local until_ = (c and c[wagonId]) or 0
    return until_ - os.time()
end

local function ownedWagon(charid, wagonId)
    local rows = Db.awaitQuery(
        'SELECT id, name, model, health, tint FROM sovereign_wagons WHERE id = ? AND charid = ?',
        { wagonId, charid })
    return rows and rows[1]
end

local function defaultWagon(charid)
    local rows = Db.awaitQuery(
        'SELECT id, name, model, health, tint FROM sovereign_wagons WHERE charid = ? ORDER BY is_default DESC, id ASC LIMIT 1',
        { charid })
    return rows and rows[1]
end

-- A wagon is collected AT A STABLE (owner ruling Q2 — there is no summon).
-- `stableId` is where the player is standing; the wagon arrives in that
-- stable's yard, not wherever the player happens to be.
RegisterNetEvent(Events.RequestCallWagon, function(wagonId, stableId)
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then
            TriggerClientEvent(Events.CallWagonResult, src, { ok = false, message = 'No active character.' })
            return
        end

        -- Validate the stable server-side rather than trusting the id, and
        -- refuse one with no yard configured — that's how a wagon ended up
        -- inside the building.
        local stable = stableId and Config.Stables[stableId]
        if not stable then
            TriggerClientEvent(Events.CallWagonResult, src, { ok = false, message = 'Collect it at a stable.' })
            return
        end
        if not (stable.retrieve and stable.retrieve.wagonPos) then
            Util.err(('stable "%s" has no retrieve.wagonPos — cannot bring a wagon out here'):format(tostring(stableId)))
            TriggerClientEvent(Events.CallWagonResult, src, { ok = false, message = 'This stable has nowhere to bring a wagon out.' })
            return
        end

        local row = wagonId and ownedWagon(charid, wagonId) or defaultWagon(charid)
        if not row then
            TriggerClientEvent(Events.CallWagonResult, src, { ok = false, message = 'You keep no wagon.' })
            return
        end

        local left = cdLeft(charid, row.id)
        if left > 0 then
            TriggerClientEvent(Events.CallWagonResult, src, { ok = false, message = ('Give it a moment — %ds.'):format(left) })
            return
        end

        Util.log(('wagon call granted: #%s (char %s) at %s'):format(tostring(row.id), tostring(charid), tostring(stableId)))
        TriggerClientEvent(Events.CallWagonResult, src, { ok = true, wagon = {
            id = row.id, name = row.name, model = row.model, health = row.health, tint = row.tint,
            stableId = stableId,
        }})
    end)
end)

RegisterNetEvent(Events.ReportWagonDismiss, function(wagonId)
    local src = source
    local charid = Bridge.getCharId(src)
    if not charid or not wagonId then return end
    wagonCooldown[charid] = wagonCooldown[charid] or {}
    wagonCooldown[charid][wagonId] = os.time() + ((Config.Summon and Config.Summon.recallCooldownSeconds) or 30)
end)

-- Persist damage [WG9]. Client reports; the server is still the one that writes,
-- and it only ever writes to a row this character owns.
RegisterNetEvent(Events.ReportWagonHealth, function(wagonId, health)
    local src = source
    if not wagonId then return end
    health = math.max(0, math.floor(tonumber(health) or 0))
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        Db.execute('UPDATE sovereign_wagons SET health = ? WHERE id = ? AND charid = ?', { health, wagonId, charid })
    end)
end)

RegisterNetEvent(Events.RequestSetDefaultWagon, function(wagonId)
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        -- Only ever touch rows this character owns.
        Db.execute('UPDATE sovereign_wagons SET is_default = 0 WHERE charid = ?', { charid })
        Db.execute('UPDATE sovereign_wagons SET is_default = 1 WHERE id = ? AND charid = ?', { wagonId, charid })
        pushOwnedWagons(src, charid)
    end)
end)

AddEventHandler('playerDropped', function() busy[source] = nil end)
