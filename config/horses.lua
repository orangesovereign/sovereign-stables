--[[=====================================================================
  SOVEREIGN STABLES · HORSE CATALOG
  ---------------------------------------------------------------------
  One entry per buyable horse MODEL. This catalog is model/coat-agnostic:
  the id can be any horse installed on the server — a stock RDR2 breed OR a
  legitimately-obtained community add-on coat (which ships as its own
  `stream` resource). We only reference it by model id; we never contain the
  asset. (See docs/00-README.md · Assets & coats policy.)

  Only a couple of examples are filled in for Phase 0. The full 60+ roster is
  populated as the storefront comes online.
=====================================================================]]--

Config = Config or {}

-- Shared defaults applied to every horse unless the entry overrides them.
Config.HorseDefaults = {
    price        = { cash = 100.0, gold = 0.0 },
    resaleValue  = 0.5,      -- fraction of cash price returned when sold [I7]
    storage      = 30,       -- inventory weight capacity [I4]
    maxHides     = 3,        -- hides that can be strapped on [I5]
    buyable      = true,     -- [I1]
    breedable    = true,     -- [I8]
    stables      = 'all',    -- 'all' or a list of stable ids that may sell it [I2]
    jobs         = 'all',    -- 'all' or a list of jobs allowed to buy it [I6]
    whistle      = nil,      -- nil = use Config.Summon.whistleAllowedByDefault; true/false to force [S6]
    wild         = { capturable = false, storable = false, blackMarket = { cash = 0.0, gold = 0.0 } }, -- [I12]
    flamingShoe  = false,    -- eligible for the flaming horseshoe [I11]
    sizeOptions  = {},       -- allowed body-size presets [I9] (filled after appearance spike)
    coatOptions  = {},       -- allowed mane/tail/coat preset ids [I10]
}

Config.Horses = {

    ['A_C_Horse_KentuckySaddle_Grey'] = {
        label = 'Kentucky Saddler (Grey)',
        price = { cash = 130.0, gold = 0.0 },
        -- inherits every other field from Config.HorseDefaults
    },

    ['A_C_Horse_Turkoman_Gold'] = {
        label     = 'Gold Turkoman',
        price     = { cash = 950.0, gold = 12.0 },
        storage   = 40,
        breedable = true,
    },

    ['A_C_HorseMule_01'] = {
        label     = 'Mule',
        price     = { cash = 60.0, gold = 0.0 },
        breedable = false,
        maxHides  = 5,
    },
}
