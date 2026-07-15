--[[=====================================================================
  SOVEREIGN STABLES · TACK  (server, authoritative)
  ---------------------------------------------------------------------
  Owner ruling 2026-07-15: TACK BELONGS TO THE PLAYER, NOT THE HORSE.
  Buy a saddle once and it goes on whichever horse you ride. Two separate
  questions live here:

      OWN    → sovereign_tack rows, keyed by charid
      APPLY  → sovereign_horses.components JSON, keyed by horse

  A dead horse therefore loses its components but never your tack — the
  saddle is still yours, it just isn't on anything. (The cargo the horse
  was carrying IS lost; that's inventory, not tack.)
=====================================================================]]--

Tack = Tack or {}

local busy = {}   -- [src] = true while a tack purchase is in flight

local function logLedger(charid, action, subject, cash, gold, meta)
    if not (Config.Economy and Config.Economy.transactionLog) then return end
    Db.execute('INSERT INTO sovereign_ledger (charid, action, subject, cash, gold, meta) VALUES (?, ?, ?, ?, ?, ?)',
        { charid, action, subject, cash or 0, gold or 0, meta and json.encode(meta) or nil })
end

--------------------------------------------------------------------------------
-- Ownership
--------------------------------------------------------------------------------
function Tack.listOwned(charid)
    return Db.awaitQuery('SELECT id, category, item FROM sovereign_tack WHERE charid = ? ORDER BY category, item',
        { charid }) or {}
end

function Tack.owns(charid, itemId)
    local rows = Db.awaitQuery('SELECT id FROM sovereign_tack WHERE charid = ? AND item = ? LIMIT 1',
        { charid, itemId })
    return rows and rows[1] ~= nil
end

-- What the character already owns in a slot (for the trade-in rule).
local function ownedInCategory(charid, category)
    return Db.awaitQuery('SELECT id, item FROM sovereign_tack WHERE charid = ? AND category = ?',
        { charid, category }) or {}
end

-- The dearest piece a character owns in a slot — the thing a trade-in credits.
local function bestOwnedValue(charid, category)
    local best, bestItem = 0.0, nil
    for _, row in ipairs(ownedInCategory(charid, category)) do
        local card = Catalog.tack(row.item)
        local v = card and card.price and card.price.cash or 0.0
        if v > best then best, bestItem = v, row.item end
    end
    return best, bestItem
end

--------------------------------------------------------------------------------
-- What's on a horse
--------------------------------------------------------------------------------
-- components JSON is { [slot] = itemId }. Slot, not category, because that's
-- what the apply pipeline cares about.
local function readComponents(charid, horseId)
    local rows = Db.awaitQuery('SELECT components FROM sovereign_horses WHERE id = ? AND charid = ?',
        { horseId, charid })
    if not (rows and rows[1]) then return nil end
    local raw = rows[1].components
    if not raw or raw == '' then return {} end
    local ok, decoded = pcall(json.decode, raw)
    return (ok and type(decoded) == 'table') and decoded or {}
end

local function writeComponents(charid, horseId, comps)
    Db.execute('UPDATE sovereign_horses SET components = ? WHERE id = ? AND charid = ?',
        { json.encode(comps), horseId, charid })
end

Tack.componentsOf = readComponents

--------------------------------------------------------------------------------
-- Purchase
--------------------------------------------------------------------------------
-- Returns ok:boolean, message:string
function Tack.buy(src, itemId)
    if not (Config.Economy and Config.Economy.enableBuying) then
        return false, 'The stables are not selling today.'
    end

    local charid = Bridge.getCharId(src)
    if not charid then return false, 'No active character.' end

    local card = Catalog.tack(itemId)
    if not card or card.buyable == false then return false, 'No such tack.' end
    if not card.hash then
        -- A catalog entry with no verified hash would apply nothing and look
        -- like a silent failure. Refuse it rather than sell a no-op.
        return false, 'That piece is not in stock.'
    end

    local rules = Config.TackRules or {}

    -- RULING: never re-buy what you own.
    if rules.neverRebuyOwned ~= false and Tack.owns(charid, itemId) then
        return false, 'You already own that — it is yours to use on any horse.'
    end

    local job = Bridge.getJob(src)
    if card.jobs and card.jobs ~= 'all' then
        local ok = false
        for _, j in ipairs(card.jobs) do if j == job then ok = true break end end
        if not ok then return false, 'Reserved for another trade.' end
    end

    -- Price, server-side. RULING: "adjust a tack and you pay only the difference."
    local full  = (card.price and card.price.cash) or 0.0
    local gold  = (card.price and card.price.gold) or 0.0
    if not (Config.Economy.enableGold) then gold = 0.0 end

    local cash, tradedIn = full, nil
    if rules.tradeInWithinSlot then
        local credit, creditItem = bestOwnedValue(charid, card.category)
        if credit > 0 then
            cash = full - credit
            if cash < 0 and not rules.allowDowngradeRefund then cash = 0.0 end
            tradedIn = creditItem
        end
    end

    if not Bridge.canAfford(src, cash, gold) then return false, "You can't afford that." end
    if cash > 0 or gold > 0 then
        if not Bridge.charge(src, cash, gold) then return false, 'Payment failed.' end
    end

    -- Trade-in consumes the old piece and strips it off any horse wearing it,
    -- or the player would keep using tack they no longer own.
    if tradedIn then
        Db.execute('DELETE FROM sovereign_tack WHERE charid = ? AND item = ?', { charid, tradedIn })
        Tack.stripItemEverywhere(charid, tradedIn)
    end

    local id = Db.awaitInsert(
        'INSERT INTO sovereign_tack (identifier, charid, category, item) VALUES (?, ?, ?, ?)',
        { Bridge.getIdentifier(src), charid, card.category, itemId })

    if not id then
        if cash > 0 or gold > 0 then Bridge.pay(src, cash, gold) end   -- refund
        return false, 'The paperwork failed — you were not charged.'
    end

    logLedger(charid, 'buy_tack', itemId, cash, gold, { category = card.category, tradedIn = tradedIn, full = full })
    Util.log(('char %s bought tack %s for %s/%s%s'):format(
        charid, itemId, cash, gold, tradedIn and (' (traded in ' .. tradedIn .. ')') or ''))
    return true, ('%s is yours.'):format(card.label)
end

-- Remove an item from every horse this character owns (used on trade-in).
function Tack.stripItemEverywhere(charid, itemId)
    local rows = Db.awaitQuery('SELECT id, components FROM sovereign_horses WHERE charid = ?', { charid }) or {}
    for _, row in ipairs(rows) do
        if row.components and row.components ~= '' then
            local ok, comps = pcall(json.decode, row.components)
            if ok and type(comps) == 'table' then
                local changed = false
                for slot, v in pairs(comps) do
                    if v == itemId then comps[slot] = nil; changed = true end
                end
                if changed then writeComponents(charid, row.id, comps) end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Apply / remove
--------------------------------------------------------------------------------
-- Returns ok, message. Both the horse AND the tack must belong to the caller.
function Tack.apply(src, horseId, itemId)
    local charid = Bridge.getCharId(src)
    if not charid then return false, 'No active character.' end

    local card = Catalog.tack(itemId)
    if not card then return false, 'No such tack.' end
    if not Tack.owns(charid, itemId) then return false, 'You do not own that piece.' end

    local comps = readComponents(charid, horseId)
    if not comps then return false, 'That is not your horse.' end

    comps[card.slot] = itemId
    writeComponents(charid, horseId, comps)
    Util.log(('char %s applied %s to horse #%s'):format(charid, itemId, horseId))
    return true, ('%s fitted.'):format(card.label)
end

function Tack.remove(src, horseId, slot)
    local charid = Bridge.getCharId(src)
    if not charid then return false, 'No active character.' end

    local comps = readComponents(charid, horseId)
    if not comps then return false, 'That is not your horse.' end
    if not comps[slot] then return true, 'Nothing there.' end

    comps[slot] = nil
    writeComponents(charid, horseId, comps)
    return true, 'Removed.'
end

--------------------------------------------------------------------------------
-- Net events
--------------------------------------------------------------------------------
local function pushOwnedTack(src, charid, horseId)
    TriggerClientEvent(Events.OwnedTackData, src, {
        owned      = Tack.listOwned(charid),
        categories = Catalog.tackCategories(),
        horseId    = horseId,
        components = horseId and readComponents(charid, horseId) or nil,
    })
end

RegisterNetEvent(Events.RequestOwnedTack, function(horseId)
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if charid then pushOwnedTack(src, charid, horseId) end
    end)
end)

RegisterNetEvent(Events.RequestBuyTack, function(itemId)
    local src = source
    if busy[src] then return end
    busy[src] = true
    CreateThread(function()
        local ok, msg = false, 'Something went wrong.'
        local success, err = pcall(function() ok, msg = Tack.buy(src, itemId) end)
        if not success then Util.err('tack purchase failed: ' .. tostring(err)) end

        local cash, gold = Bridge.getBalance(src)
        TriggerClientEvent(Events.TackResult, src, { ok = ok, message = msg, cash = cash, gold = gold })
        local charid = Bridge.getCharId(src)
        if ok and charid then pushOwnedTack(src, charid) end
        busy[src] = nil
    end)
end)

RegisterNetEvent(Events.RequestApplyTack, function(horseId, itemId)
    local src = source
    CreateThread(function()
        local ok, msg = false, 'Something went wrong.'
        local success, err = pcall(function() ok, msg = Tack.apply(src, horseId, itemId) end)
        if not success then Util.err('tack apply failed: ' .. tostring(err)) end
        TriggerClientEvent(Events.TackResult, src, { ok = ok, message = msg, applied = ok })
        local charid = Bridge.getCharId(src)
        if ok and charid then pushOwnedTack(src, charid, horseId) end
    end)
end)

RegisterNetEvent(Events.RequestRemoveTack, function(horseId, slot)
    local src = source
    CreateThread(function()
        local ok, msg = false, 'Something went wrong.'
        local success, err = pcall(function() ok, msg = Tack.remove(src, horseId, slot) end)
        if not success then Util.err('tack remove failed: ' .. tostring(err)) end
        TriggerClientEvent(Events.TackResult, src, { ok = ok, message = msg, applied = ok })
        local charid = Bridge.getCharId(src)
        if ok and charid then pushOwnedTack(src, charid, horseId) end
    end)
end)

AddEventHandler('playerDropped', function() busy[source] = nil end)
