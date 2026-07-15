--[[=====================================================================
  SOVEREIGN STABLES · HORSE OWNERSHIP  (server, authoritative)
  ---------------------------------------------------------------------
  Buying and owning horses. The client never decides price, permission or
  funds — it only asks. Every money-moving action is written to the ledger
  (X2) so the economy is auditable and dupes are traceable.
=====================================================================]]--

Horses = Horses or {}

local busy = {}   -- [src] = true while a purchase is in flight (anti-spam/dupe)

--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------
function Horses.listOwned(charid)
    return Db.awaitQuery(
        'SELECT id, name, sex, model, is_default, stable_origin, xp, age FROM sovereign_horses WHERE charid = ? ORDER BY id',
        { charid }) or {}
end

function Horses.countOwned(charid)
    local rows = Db.awaitQuery('SELECT COUNT(*) AS n FROM sovereign_horses WHERE charid = ?', { charid })
    return (rows and rows[1] and rows[1].n) or 0
end

local function logLedger(charid, action, subject, cash, gold, meta)
    if not (Config.Economy and Config.Economy.transactionLog) then return end
    Db.execute('INSERT INTO sovereign_ledger (charid, action, subject, cash, gold, meta) VALUES (?, ?, ?, ?, ?, ?)',
        { charid, action, subject, cash or 0, gold or 0, meta and json.encode(meta) or nil })
end

-- Clean up a player-supplied horse name [N8]. Never trust it: strip control
-- characters and markup, collapse whitespace, cap the length, fall back to the
-- catalog name if they left it blank.
local function sanitizeName(raw, fallback)
    if type(raw) ~= 'string' then return fallback end
    local s = raw:gsub('[%c]', ' '):gsub('[<>~\\]', ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then return fallback end
    if #s > 24 then s = s:sub(1, 24) end
    return s
end

-- Gender is chosen at purchase [N9]. Only these are valid — a Gelding is made
-- by neutering (G5), never bought.
local VALID_SEX = { Stallion = true, Mare = true }
local function sanitizeSex(raw, fallback)
    return VALID_SEX[raw] and raw or (fallback or 'Stallion')
end

-- Does this stable actually sell this model? (Stops a spoofed model id.)
local function stableSells(stableId, model)
    for _, h in ipairs(Catalog.horsesFor(stableId)) do
        if h.model == model then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- Purchase
--------------------------------------------------------------------------------
-- Returns ok:boolean, message:string
-- `wanted` = { name, sex } chosen by the buyer at purchase (N8/N9).
function Horses.buy(src, stableId, model, wanted)
    if not (Config.Economy and Config.Economy.enableBuying) then
        return false, 'The stables are not selling today.'
    end

    local charid = Bridge.getCharId(src)
    if not charid then return false, 'No active character.' end

    if not Config.Stables[stableId] then return false, 'Unknown stable.' end
    if not stableSells(stableId, model) then return false, 'This stable does not sell that horse.' end

    local card = Catalog.horse(model)
    if not card or card.buyable == false then return false, 'That horse is not for sale.' end

    -- Job / stable permission
    local job = Bridge.getJob(src)
    local allowed, why = Catalog.canBuy(card, stableId, job)
    if not allowed then return false, why or 'You may not buy that here.' end

    -- Ownership cap (global cap vs job cap, whichever is stricter)
    local cap   = Perms.maxHorses(job)
    local owned = Horses.countOwned(charid)
    if owned >= cap then
        return false, ('You already keep %d horse(s) — your limit.'):format(cap)
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

    -- The buyer names it and picks its gender (N8/N9); both sanitized here.
    wanted = wanted or {}
    local name = sanitizeName(wanted.name, card.name or card.label or model)
    local sex  = sanitizeSex(wanted.sex, card.sex)

    -- Record it. First horse becomes the default ride.
    local isDefault = (owned == 0) and 1 or 0
    local id = Db.awaitInsert(
        'INSERT INTO sovereign_horses (identifier, charid, name, sex, model, stable_origin, is_default) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { Bridge.getIdentifier(src), charid, name, sex, model, stableId, isDefault })

    if not id then
        Bridge.pay(src, cash, gold)   -- refund: never take money without a horse
        return false, 'The paperwork failed — you were not charged.'
    end

    logLedger(charid, 'buy_horse', model, cash, gold, { stable = stableId, horseId = id, name = name, sex = sex })
    Util.log(('char %s bought %s (%s, %s) at %s for %s/%s (horse #%s)'):format(charid, model, name, sex, stableId, cash, gold, id))
    return true, ('%s is yours.'):format(name)
end

--------------------------------------------------------------------------------
-- Net events
--------------------------------------------------------------------------------
local function pushOwned(src, charid)
    TriggerClientEvent(Events.OwnedData, src, {
        owned = Horses.listOwned(charid),
        cap   = Perms.maxHorses(Bridge.getJob(src)),
    })
end

RegisterNetEvent(Events.RequestPurchase, function(stableId, model, wanted)
    local src = source
    if busy[src] then return end
    busy[src] = true
    CreateThread(function()
        local ok, msg = false, 'Something went wrong.'
        local success, err = pcall(function() ok, msg = Horses.buy(src, stableId, model, wanted) end)
        if not success then Util.err('purchase failed: ' .. tostring(err)) end

        local cash, gold = Bridge.getBalance(src)
        TriggerClientEvent(Events.PurchaseResult, src, { ok = ok, message = msg, cash = cash, gold = gold })
        local charid = Bridge.getCharId(src)
        if ok and charid then pushOwned(src, charid) end
        busy[src] = nil
    end)
end)

RegisterNetEvent(Events.RequestOwned, function()
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if charid then pushOwned(src, charid) end
    end)
end)

RegisterNetEvent(Events.RequestSetDefault, function(horseId)
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        -- Only ever touch rows this character owns.
        Db.execute('UPDATE sovereign_horses SET is_default = 0 WHERE charid = ?', { charid })
        Db.execute('UPDATE sovereign_horses SET is_default = 1 WHERE id = ? AND charid = ?', { horseId, charid })
        pushOwned(src, charid)
    end)
end)

AddEventHandler('playerDropped', function() busy[source] = nil end)
