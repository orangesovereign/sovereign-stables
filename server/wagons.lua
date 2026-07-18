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
    local job, grade = Bridge.getJob(src)
    local allowed, why = Catalog.canBuy(card, stableId, job)
    if not allowed then return false, why or 'You may not buy that here.' end

    -- Ownership cap (global vs job cap, whichever is stricter)
    local cap   = Perms.maxWagons(job, grade)
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

        -- A WRECKED or badly-worn wagon [WG9]. Owner ruling: "everyone can repair
        -- their wagon to the lowest health to get going." The stable IS that
        -- patch job — a wagon below the field floor is brought up to it on
        -- retrieval (for anyone who can field-repair, which is everyone by
        -- default), and persisted. It limps out; a Wagon Maker takes it to 100%.
        -- So a wreck is never bricked and never lost, just costly until a pro
        -- sees it. Set wreckedNeedsRepair = false to skip the auto-patch.
        local c = Config.WagonCondition or Config.WagonDamage or {}
        local health = tonumber(row.health) or (c.maxHealth or 100)
        local floor  = c.fieldRepairTo or 40
        if c.wreckedNeedsRepair ~= false and health < floor then
            local job, grade = Bridge.getJob(src)
            if Perms.can(job, grade, 'wagonRepair') or Perms.can(job, grade, 'wagonFullRepair') then
                Db.execute('UPDATE sovereign_wagons SET health = ? WHERE id = ? AND charid = ?', { floor, row.id, charid })
                health = floor
                Bridge.notify(src, ('Patched up to %d%% to get you moving.'):format(floor))
            else
                TriggerClientEvent(Events.CallWagonResult, src, { ok = false,
                    message = ('%s is wrecked — it needs a repair before it will move.'):format(row.name or 'That wagon') })
                return
            end
        end

        Util.log(('wagon call granted: #%s (char %s) at %s — condition %s')
            :format(tostring(row.id), tostring(charid), tostring(stableId), tostring(health)))
        TriggerClientEvent(Events.CallWagonResult, src, { ok = true, wagon = {
            id = row.id, name = row.name, model = row.model, health = health, tint = row.tint,
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

-- Persist WEAR [WG9]. The client owns the live condition as the wagon is used
-- (bcc's model) and reports the new value; the server clamps and stores. Never
-- lets the reported value climb — wear only ever goes down here, so a spoofed
-- higher number can't repair a wagon for free (repair goes through its own
-- permission-gated path).
RegisterNetEvent(Events.ReportWagonHealth, function(wagonId, condition)
    local src = source
    if not wagonId then return end
    if (Config.WagonCondition or Config.WagonDamage or {}).persist == false then return end

    local maxHp = (Config.WagonCondition or Config.WagonDamage or {}).maxHealth or 100
    condition = math.max(0, math.min(maxHp, math.floor(tonumber(condition) or maxHp)))
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        -- GREATEST guard: only accept a value that is <= what's stored. Wear
        -- decreases; anything trying to raise condition must go via repair.
        Db.execute('UPDATE sovereign_wagons SET health = LEAST(health, ?) WHERE id = ? AND charid = ?',
            { condition, wagonId, charid })
    end)
end)

-- A wagon was RENDERED UNUSABLE [WG9]. The client can't read a health scalar
-- (RDR3 exposes none — see client/wagon.lua CONDITION note), but it CAN tell us
-- the wagon was wrecked. That's a hard write to 0. Repair brings it back.
RegisterNetEvent(Events.ReportWagonWrecked, function(wagonId)
    local src = source
    if not wagonId then return end
    if (Config.WagonDamage or {}).persist == false then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        Db.execute('UPDATE sovereign_wagons SET health = 0 WHERE id = ? AND charid = ?', { wagonId, charid })
        Db.execute('INSERT INTO sovereign_ledger (charid, action, subject, cash, gold, meta) VALUES (?, ?, ?, 0, 0, ?)',
            { charid, 'wagon_wrecked', tostring(wagonId), json.encode({ wagonId = wagonId }) })
        Util.log(('wagon #%s WRECKED -> condition 0 (char %s)'):format(tostring(wagonId), tostring(charid)))
    end)
end)

-- REPAIR [WG9 / J14] — owner ruling: anyone repairs to a floor to get going;
-- a Wagon Maker (wagonFullRepair) repairs to 100%. Repair sets condition UP to
-- the permitted target and never lowers it. Server decides the target from the
-- caller's grade — the client only asks.
RegisterNetEvent(Events.RequestRepairWagon, function(wagonId)
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid or not wagonId then return end

        local c = Config.WagonCondition or Config.WagonDamage or {}
        local job, grade = Bridge.getJob(src)

        -- What level can THIS person restore to?
        local target
        if Perms.can(job, grade, 'wagonFullRepair') then
            target = c.proRepairTo or 100
        elseif Perms.can(job, grade, 'wagonRepair') then
            target = c.fieldRepairTo or 40
        else
            TriggerClientEvent(Events.WagonRepaired, src, { ok = false, message = 'You do not know how to repair a wagon.' })
            return
        end

        local row = ownedWagon(charid, wagonId)
        if not row then
            TriggerClientEvent(Events.WagonRepaired, src, { ok = false, message = 'That is not your wagon.' })
            return
        end

        local cur = tonumber(row.health) or 0
        if cur >= target then
            local msg = (target >= (c.maxHealth or 100))
                and 'It is already in perfect order.'
                or  'You have patched it as well as you can — a Wagon Maker could do more.'
            TriggerClientEvent(Events.WagonRepaired, src, { ok = false, message = msg })
            return
        end

        -- TODO(inventory): consume c.repairItem for a field repair once
        -- vorp_inventory is wired (Bridge.registerRideInventory is still a stub).
        Db.execute('UPDATE sovereign_wagons SET health = ? WHERE id = ? AND charid = ?', { target, wagonId, charid })
        Db.execute('INSERT INTO sovereign_ledger (charid, action, subject, cash, gold, meta) VALUES (?, ?, ?, 0, 0, ?)',
            { charid, 'wagon_repair', tostring(wagonId), json.encode({ from = cur, to = target, full = (target >= (c.maxHealth or 100)) }) })
        TriggerClientEvent(Events.WagonRepaired, src, { ok = true, wagonId = wagonId, condition = target,
            message = ('Repaired to %d%%.'):format(target) })
        Util.log(('wagon #%s repaired %d -> %d (char %s)'):format(tostring(wagonId), cur, target, tostring(charid)))
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
