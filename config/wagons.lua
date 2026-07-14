--[[=====================================================================
  SOVEREIGN STABLES · WAGON & CART CATALOG
  ---------------------------------------------------------------------
  One entry per buyable wagon/cart MODEL. Same model-agnostic rule as horses.
=====================================================================]]--

Config = Config or {}

Config.WagonDefaults = {
    price       = { cash = 100.0, gold = 0.0 },
    resaleValue = 0.5,
    storage     = 100,        -- inventory capacity
    buyable     = true,
    stables     = 'all',
    jobs        = 'all',
    spawnDelay  = 0,          -- seconds before the wagon appears after calling [WG2]
    defaultTint = nil,        -- e.g. 'green' for the stock green livery [WG4]
    workWagon   = nil,        -- e.g. { resources = { 'wood', 'stone', 'water' } } [WG14]
    craftable   = false,      -- can be built via crafting instead of bought [WG8]
}

Config.Wagons = {

    ['cart01'] = {
        label = 'Open Cart',
        price = { cash = 30.0, gold = 0.0 },
        storage = 50,
    },

    ['wagon02x'] = {
        label = 'Covered Wagon',
        price = { cash = 100.0, gold = 0.0 },
        storage = 100,
    },

    ['chuckwagon002x'] = {
        label = 'Chuck Wagon',
        price = { cash = 110.0, gold = 0.0 },
        storage = 110,
    },
}
