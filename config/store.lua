--[[=====================================================================
  SOVEREIGN STABLES · STORE  (player-run shop, tied to a stable)
  ---------------------------------------------------------------------
  A store belongs to a STABLE and is run by that stable's owner + employees
  (owner ruling 2026-07-30). One panel: list stock for sale, post buy orders,
  and manage the shared till. Customers walk up and buy listings or sell into
  buy orders.

  This file is the tuning surface: employee ROLES and what each may do, plus a
  few limits. Ownership/employees/till/stock/listings/orders live in the DB
  (sql/install.sql: sovereign_stable_business, _employees, _store_stock,
  _store_listings, _store_orders). server/store.lua is the logic.

  ⚠️ Gated UI is HIDDEN, not greyed (owner ruling): the store panel shows each
  person only the controls their role unlocks. `capsFor` below drives that.
=====================================================================]]--

Config = Config or {}

Config.Store = {
    enabled = true,

    -- Employee ROLES → capabilities. Add or rename roles freely; a stable's
    -- employees are assigned one of these role names. The OWNER is not a role —
    -- they implicitly get `ownerCaps` below (which no employee role can grant).
    --   trade         — operate the counter: sell listings to customers, fill buy orders
    --   manageStock    — deposit/withdraw the store's goods
    --   manageListings — create/remove items-for-sale
    --   manageOrders   — create/cancel buy orders
    --   hire           — add/remove employees
    --   withdraw       — take money OUT of the till (owner-only; never grant to a role)
    roles = {
        clerk = {
            trade = true, manageStock = false, manageListings = false,
            manageOrders = false, hire = false, withdraw = false,
        },
        manager = {
            trade = true, manageStock = true, manageListings = true,
            manageOrders = true, hire = false, withdraw = false,
        },
    },

    -- The owner always has everything, including withdraw + hire. withdraw is
    -- owner-ONLY regardless of any role table above.
    ownerCaps = {
        trade = true, manageStock = true, manageListings = true,
        manageOrders = true, hire = true, withdraw = true,
    },

    -- Anyone (a passing customer) may always BUY listings and FILL buy orders —
    -- that's the whole point of a shop. Those aren't gated capabilities.

    limits = {
        listingsPerStable = 60,     -- max distinct items-for-sale
        ordersPerStable   = 60,     -- max standing buy orders
        maxUnitPriceCash  = 100000, -- sanity clamp on any price a player sets
        maxUnitPriceGold  = 1000,
        maxQty            = 100000, -- clamp on any quantity
    },
}
