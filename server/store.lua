--[[=====================================================================
  SOVEREIGN STABLES · STORE  (server logic)
  ---------------------------------------------------------------------
  The player-run store tied to a stable. Owner + employees run one counter:
  list stock for sale, post buy orders, manage the shared till. Customers buy
  listings and sell into buy orders.

  DESIGN (owner rulings 2026-07-30):
    • A store belongs to a STABLE; its owner/employees operate it.
    • ONE shared till per store (money in from sales, out to buy-order payouts).
      Withdraw is OWNER-ONLY; employees trade but don't pocket the till.
    • Stock is DEPOSITED: goods live as DB counts (sovereign_store_stock) we move
      programmatically — deposit takes from the player, a sale gives to the buyer.
    • Gated UI is HIDDEN, not greyed: a plain customer's view carries NO till, NO
      stock, NO caps — only listings + buy orders. Staff get the rest. The client
      can't show what it never received. Server re-checks every action anyway.

  Tables: sovereign_stable_business (owner + till), sovereign_stable_employees
  (roster + role), sovereign_store_stock, sovereign_store_listings,
  sovereign_store_orders. See sql/install.sql.
=====================================================================]]--

Store = Store or {}

local function cfg()    return Config.Store or {} end
local function limits() return cfg().limits or {} end

-- oxmysql execute wrapped to a synchronous return (affected rows).
local function exec(sql, params)
    local p = promise.new()
    Db.execute(sql, params, function(affected) p:resolve(affected or 0) end)
    return Citizen.Await(p)
end

--------------------------------------------------------------------------------
-- Ownership / roles / capabilities
--------------------------------------------------------------------------------
local function businessRow(stableId)
    local r = Db.awaitQuery('SELECT * FROM sovereign_stable_business WHERE stable_id = ?', { stableId })
    return r and r[1] or nil
end

-- Returns caps table, role string, business row. caps/role are nil for someone
-- who neither owns nor works this store (a plain customer).
local function capsFor(charid, stableId)
    if not charid then return nil, nil, nil end
    local biz = businessRow(stableId)
    if not biz then return nil, nil, nil end   -- unowned = no store business
    if tostring(biz.owner_charid) == tostring(charid) then
        return cfg().ownerCaps or {}, 'owner', biz
    end
    local e = Db.awaitQuery('SELECT role FROM sovereign_stable_employees WHERE stable_id = ? AND charid = ?', { stableId, charid })
    local role = e and e[1] and e[1].role
    if role and cfg().roles and cfg().roles[role] then
        return cfg().roles[role], role, biz
    end
    return nil, role, biz
end

local function can(charid, stableId, capability)
    local caps = capsFor(charid, stableId)
    return caps ~= nil and caps[capability] == true
end

--------------------------------------------------------------------------------
-- Till + stock helpers (till lives on the business row; stock is a count table)
--------------------------------------------------------------------------------
local function addTill(stableId, cash, gold)
    exec('UPDATE sovereign_stable_business SET till_cash = GREATEST(0, till_cash + ?), till_gold = GREATEST(0, till_gold + ?) WHERE stable_id = ?',
        { cash or 0, gold or 0, stableId })
end

local function tillOf(biz)
    return tonumber(biz and biz.till_cash) or 0, tonumber(biz and biz.till_gold) or 0
end

local function stockQty(stableId, item)
    local r = Db.awaitQuery('SELECT qty FROM sovereign_store_stock WHERE stable_id = ? AND item = ?', { stableId, item })
    return r and r[1] and tonumber(r[1].qty) or 0
end

local function addStock(stableId, item, delta)
    exec('INSERT INTO sovereign_store_stock (stable_id, item, qty) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE qty = GREATEST(0, qty + ?)',
        { stableId, item, math.max(0, delta), delta })
end

local function ledger(charid, action, subject, cash, gold, meta)
    if logLedger then pcall(logLedger, charid, action, subject, cash, gold, meta) end
end

local function clampQty(n)   return math.max(0, math.min(math.floor(tonumber(n) or 0), limits().maxQty or 100000)) end
local function clampCash(n)  return math.max(0, math.min(math.floor(tonumber(n) or 0), limits().maxUnitPriceCash or 100000)) end
local function clampGold(n)  return math.max(0, math.min(math.floor(tonumber(n) or 0), limits().maxUnitPriceGold or 1000)) end

--------------------------------------------------------------------------------
-- The role-scoped view sent to a client that opens the store.
--------------------------------------------------------------------------------
local function viewFor(src, stableId)
    local charid = Bridge.getCharId(src)
    local caps, role, biz = capsFor(charid, stableId)
    if not biz then return { stableId = stableId, open = false } end   -- unowned stable = no store

    local listings = Db.awaitQuery(
        'SELECT id, item, qty, price_cash, price_gold FROM sovereign_store_listings WHERE stable_id = ? AND qty > 0 ORDER BY item', { stableId })
    local orders = Db.awaitQuery(
        'SELECT id, item, qty_wanted, qty_filled, price_cash, price_gold FROM sovereign_store_orders WHERE stable_id = ? AND qty_filled < qty_wanted ORDER BY item', { stableId })

    local view = {
        stableId = stableId,
        open     = true,
        name     = (Config.Stables[stableId] and Config.Stables[stableId].label) or 'Store',
        listings = listings or {},
        orders   = orders or {},
        role     = role,          -- nil for a plain customer
        caps     = caps or nil,   -- nil for a customer -> client renders no mgmt controls
    }
    -- ⚠️ Staff-only data. A customer NEVER receives till or stock, so the client
    -- cannot render management surfaces it has no data for (hidden, not greyed).
    if caps then
        local c, g = tillOf(biz)
        view.isOwner = (role == 'owner')
        if caps.withdraw or caps.manageStock or role == 'owner' then
            view.till = { cash = c, gold = g }
        end
        if caps.manageStock or caps.manageListings then
            view.stock = Db.awaitQuery('SELECT item, qty FROM sovereign_store_stock WHERE stable_id = ? AND qty > 0 ORDER BY item', { stableId }) or {}
        end
    end
    return view
end

local function push(src, stableId, ok, message)
    TriggerClientEvent(Events.StoreActionResult, src, { ok = ok, message = message, view = viewFor(src, stableId) })
end

--------------------------------------------------------------------------------
-- ACTIONS. Customer actions (buy, fill) are ungated; management actions check caps.
--------------------------------------------------------------------------------
local Actions = {}

-- Customer: buy from a listing. Listed goods were moved out of stock at list time,
-- so a sale only touches the listing quantity + the till.
function Actions.buy(src, stableId, charid, p)
    local id  = tonumber(p.listingId)
    local r   = id and Db.awaitQuery('SELECT * FROM sovereign_store_listings WHERE id = ? AND stable_id = ?', { id, stableId })
    local L   = r and r[1]
    if not L then return false, 'That listing is gone.' end
    local qty = math.min(clampQty(p.qty ~= nil and p.qty or 1), tonumber(L.qty))
    if qty <= 0 then return false, 'Out of stock.' end
    local cash, gold = qty * tonumber(L.price_cash), qty * tonumber(L.price_gold)
    if not Bridge.canAfford(src, cash, gold) then return false, 'You cannot afford that.' end
    if not Bridge.canCarry(src, L.item, qty)  then return false, 'You cannot carry that many.' end
    if not Bridge.charge(src, cash, gold)     then return false, 'Payment failed.' end
    exec('UPDATE sovereign_store_listings SET qty = qty - ? WHERE id = ?', { qty, id })
    exec('DELETE FROM sovereign_store_listings WHERE id = ? AND qty <= 0', { id })
    addTill(stableId, cash, gold)
    Bridge.giveItem(src, L.item, qty)
    ledger(charid, 'store_buy', L.item, cash, gold, { stable = stableId, qty = qty })
    return true, ('Bought %d× %s.'):format(qty, L.item)
end

-- Customer: sell into a buy order. Paid from the till; item lands in store stock.
function Actions.fill(src, stableId, charid, p)
    local id = tonumber(p.orderId)
    local r  = id and Db.awaitQuery('SELECT * FROM sovereign_store_orders WHERE id = ? AND stable_id = ?', { id, stableId })
    local O  = r and r[1]
    if not O then return false, 'That order is gone.' end
    local remaining = tonumber(O.qty_wanted) - tonumber(O.qty_filled)
    local have = Bridge.itemCount(src, O.item)
    local qty = math.min(clampQty(p.qty ~= nil and p.qty or remaining), remaining, have)
    if qty <= 0 then return false, (have <= 0 and 'You have none to sell.' or 'Nothing left to fill.') end
    local cash, gold = qty * tonumber(O.price_cash), qty * tonumber(O.price_gold)
    local biz = businessRow(stableId)
    local tc, tg = tillOf(biz)
    if tc < cash or tg < gold then return false, 'The store cannot cover that right now.' end
    if not Bridge.takeItem(src, O.item, qty) then return false, 'You do not have those.' end
    addTill(stableId, -cash, -gold)
    addStock(stableId, O.item, qty)
    Bridge.pay(src, cash, gold)
    exec('UPDATE sovereign_store_orders SET qty_filled = qty_filled + ? WHERE id = ?', { qty, id })
    exec('DELETE FROM sovereign_store_orders WHERE id = ? AND qty_filled >= qty_wanted', { id })
    ledger(charid, 'store_fill', O.item, cash, gold, { stable = stableId, qty = qty })
    return true, ('Sold %d× %s to the store.'):format(qty, O.item)
end

-- Staff (manageStock): deposit goods from your satchel into store stock.
function Actions.deposit(src, stableId, charid, p)
    if not can(charid, stableId, 'manageStock') then return false, 'Not allowed.' end
    local item = tostring(p.item or '')
    local qty  = clampQty(p.qty)
    if item == '' or qty <= 0 then return false, 'Pick an item and quantity.' end
    if Bridge.itemCount(src, item) < qty then return false, 'You do not have that many.' end
    if not Bridge.takeItem(src, item, qty) then return false, 'Could not take the goods.' end
    addStock(stableId, item, qty)
    return true, ('Deposited %d× %s.'):format(qty, item)
end

-- Staff (manageStock): withdraw goods from stock back to your satchel.
function Actions.withdrawStock(src, stableId, charid, p)
    if not can(charid, stableId, 'manageStock') then return false, 'Not allowed.' end
    local item = tostring(p.item or '')
    local qty  = math.min(clampQty(p.qty), stockQty(stableId, item))
    if item == '' or qty <= 0 then return false, 'Nothing to withdraw.' end
    if not Bridge.canCarry(src, item, qty) then return false, 'You cannot carry that many.' end
    addStock(stableId, item, -qty)
    Bridge.giveItem(src, item, qty)
    return true, ('Withdrew %d× %s.'):format(qty, item)
end

-- Staff (manageListings): put stock up for sale (moves qty from stock into a listing).
function Actions.list(src, stableId, charid, p)
    if not can(charid, stableId, 'manageListings') then return false, 'Not allowed.' end
    local item = tostring(p.item or '')
    local qty  = clampQty(p.qty)
    local pc, pg = clampCash(p.priceCash), clampGold(p.priceGold)
    if item == '' or qty <= 0 then return false, 'Pick an item and quantity.' end
    if pc <= 0 and pg <= 0 then return false, 'Set a price.' end
    if stockQty(stableId, item) < qty then return false, 'Not enough in stock to list.' end
    local cnt = Db.awaitQuery('SELECT COUNT(*) AS n FROM sovereign_store_listings WHERE stable_id = ?', { stableId })
    if cnt and cnt[1] and tonumber(cnt[1].n) >= (limits().listingsPerStable or 60) then
        return false, 'This store has too many listings already.'
    end
    addStock(stableId, item, -qty)
    exec('INSERT INTO sovereign_store_listings (stable_id, item, qty, price_cash, price_gold, listed_by) VALUES (?,?,?,?,?,?)',
        { stableId, item, qty, pc, pg, charid })
    return true, ('Listed %d× %s.'):format(qty, item)
end

-- Staff (manageListings): pull a listing; its remaining stock returns to the store.
function Actions.unlist(src, stableId, charid, p)
    if not can(charid, stableId, 'manageListings') then return false, 'Not allowed.' end
    local id = tonumber(p.listingId)
    local r  = id and Db.awaitQuery('SELECT * FROM sovereign_store_listings WHERE id = ? AND stable_id = ?', { id, stableId })
    local L  = r and r[1]
    if not L then return false, 'That listing is gone.' end
    addStock(stableId, L.item, tonumber(L.qty))
    exec('DELETE FROM sovereign_store_listings WHERE id = ?', { id })
    return true, ('Unlisted %s (returned %d to stock).'):format(L.item, tonumber(L.qty))
end

-- Staff (manageOrders): post a standing buy order (paid from the till when filled).
function Actions.order(src, stableId, charid, p)
    if not can(charid, stableId, 'manageOrders') then return false, 'Not allowed.' end
    local item = tostring(p.item or '')
    local qty  = clampQty(p.qty)
    local pc, pg = clampCash(p.priceCash), clampGold(p.priceGold)
    if item == '' or qty <= 0 then return false, 'Pick an item and quantity.' end
    if pc <= 0 and pg <= 0 then return false, 'Set a price.' end
    local cnt = Db.awaitQuery('SELECT COUNT(*) AS n FROM sovereign_store_orders WHERE stable_id = ?', { stableId })
    if cnt and cnt[1] and tonumber(cnt[1].n) >= (limits().ordersPerStable or 60) then
        return false, 'This store has too many buy orders already.'
    end
    exec('INSERT INTO sovereign_store_orders (stable_id, item, qty_wanted, qty_filled, price_cash, price_gold, created_by) VALUES (?,?,?,0,?,?,?)',
        { stableId, item, qty, pc, pg, charid })
    return true, ('Posted a buy order for %d× %s.'):format(qty, item)
end

-- Staff (manageOrders): cancel a buy order.
function Actions.cancelOrder(src, stableId, charid, p)
    if not can(charid, stableId, 'manageOrders') then return false, 'Not allowed.' end
    local id = tonumber(p.orderId)
    if not id then return false, 'Which order?' end
    exec('DELETE FROM sovereign_store_orders WHERE id = ? AND stable_id = ?', { id, stableId })
    return true, 'Buy order cancelled.'
end

-- Staff (manageStock): put your own money INTO the till (float).
function Actions.tillDeposit(src, stableId, charid, p)
    if not can(charid, stableId, 'manageStock') then return false, 'Not allowed.' end
    local cash, gold = clampCash(p.cash), clampGold(p.gold)
    if cash <= 0 and gold <= 0 then return false, 'Nothing to deposit.' end
    if not Bridge.charge(src, cash, gold) then return false, 'You do not have that.' end
    addTill(stableId, cash, gold)
    ledger(charid, 'store_till_in', stableId, cash, gold, { stable = stableId })
    return true, 'Added to the till.'
end

-- OWNER ONLY (withdraw): take money OUT of the till to your pocket.
function Actions.tillWithdraw(src, stableId, charid, p)
    if not can(charid, stableId, 'withdraw') then return false, 'Only the owner can withdraw.' end
    local cash, gold = clampCash(p.cash), clampGold(p.gold)
    local biz = businessRow(stableId)
    local tc, tg = tillOf(biz)
    if cash > tc or gold > tg then return false, 'The till does not hold that much.' end
    if cash <= 0 and gold <= 0 then return false, 'Nothing to withdraw.' end
    addTill(stableId, -cash, -gold)
    Bridge.pay(src, cash, gold)
    ledger(charid, 'store_till_out', stableId, cash, gold, { stable = stableId })
    return true, 'Withdrew from the till.'
end

--------------------------------------------------------------------------------
-- Net wiring
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestStoreData, function(stableId)
    local src = source
    if not (stableId and Config.Stables[stableId]) then return end
    CreateThread(function()
        TriggerClientEvent(Events.StoreData, src, viewFor(src, stableId))
    end)
end)

RegisterNetEvent(Events.RequestStoreAction, function(stableId, action, payload)
    local src = source
    if not (stableId and Config.Stables[stableId] and action) then return end
    local fn = Actions[action]
    if not fn then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then push(src, stableId, false, 'No active character.'); return end
        if cfg().enabled == false then push(src, stableId, false, 'The store is closed.'); return end
        local ok, msg = false, 'Something went wrong.'
        local good, err = pcall(function() ok, msg = fn(src, stableId, charid, payload or {}) end)
        if not good then Util.err(('store action "%s" failed: %s'):format(tostring(action), tostring(err))) end
        push(src, stableId, ok, msg)
    end)
end)

--------------------------------------------------------------------------------
-- OWNERSHIP BOOTSTRAP. Until the Stable Management Menu lands, this is how a
-- store's first owner is set (it creates the business row + till). Ace-restricted
-- (add `add_ace` for it) and, in-game, also requires the admin horseCreator grade.
--   sovsetstoreowner <stableId> [charid]   ([charid] defaults to you)
--------------------------------------------------------------------------------
RegisterCommand('sovsetstoreowner', function(src, args)
    if src ~= 0 then
        local job, grade = Bridge.getJob(src)
        if not (Perms and Perms.can and Perms.can(job, grade, 'horseCreator')) then
            Bridge.notify(src, 'Admins only.'); return
        end
    end
    local stableId = args and args[1]
    if not (stableId and Config.Stables[stableId]) then
        print('^3usage:^7 sovsetstoreowner <stableId> [charid]'); return
    end
    CreateThread(function()
        local charid = tonumber(args[2]) or (src ~= 0 and Bridge.getCharId(src)) or nil
        if not charid then print('^3[sov_store]^7 need a charid (or run in-game)'); return end
        exec('INSERT INTO sovereign_stable_business (stable_id, owner_charid) VALUES (?, ?) ON DUPLICATE KEY UPDATE owner_charid = ?',
            { stableId, charid, charid })
        print(('^2[sov_store]^7 %s store owner set to charid %s'):format(stableId, tostring(charid)))
        if src ~= 0 then Bridge.notify(src, ('You now own the %s store.'):format(stableId)) end
    end)
end, true)
