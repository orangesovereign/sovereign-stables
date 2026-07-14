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

    -- Storefront display card [N1-N4]. `tier` sorts it into the Specialty or
    -- Stock tab. Stats are configured base values now; they go live once the
    -- progression system lands (Phase 3).
    tier   = 'stock',        -- 'specialty' | 'stock'
    name   = nil,            -- showcase name (specialty). nil = use label.
    breed  = nil,            -- breed line under the name. nil = use label.
    sex    = 'Gelding',      -- Stallion | Mare | Gelding
    age    = 4,              -- years (display)
    hands  = 15.2,           -- height in hands [N3]
    lore   = 'A dependable mount, sound of wind and limb.',
    traits = {},             -- { { name='Steadfast', desc='...', level=1 }, ... }
    stats  = { health = 70, stamina = 70, speed = 70, acceleration = 70 },
}

Config.Horses = {

    ['A_C_Horse_Turkoman_Gold'] = {
        label = 'Gold Turkoman',
        tier  = 'specialty',
        name  = 'Vesper',
        breed = 'Gold Turkoman',
        price = { cash = 3200.0, gold = 12.0 },
        storage = 40, breedable = true,
        sex = 'Stallion', age = 6, hands = 16.2,
        lore = 'A refined warmblood with a willing mind and disciplined heart. Built for stamina, born for the long road ahead.',
        traits = {
            { name = 'Steadfast', desc = 'Handles pressure with calm resolve.', level = 1 },
            { name = 'Endurance', desc = 'Stays strong and steady over distance.' },
        },
        stats = { health = 88, stamina = 94, speed = 82, acceleration = 76 },
    },

    ['A_C_Horse_KentuckySaddle_Grey'] = {
        label = 'Kentucky Saddler', tier = 'stock', breed = 'Grey Kentucky Saddler',
        price = { cash = 130.0, gold = 0.0 },
        sex = 'Mare', age = 5, hands = 15.1,
        lore = 'A steady grey saddler — even-tempered and honest under saddle.',
        stats = { health = 66, stamina = 70, speed = 72, acceleration = 68 },
    },

    ['A_C_Horse_Ardennes_BayRoan'] = {
        label = 'Ardennes', tier = 'stock', breed = 'Bay Roan Ardennes',
        price = { cash = 180.0, gold = 0.0 },
        sex = 'Gelding', age = 7, hands = 16.0, storage = 38,
        lore = 'A heavy draft breed — strong of back, calm in a storm.',
        stats = { health = 90, stamina = 78, speed = 58, acceleration = 52 },
    },

    ['A_C_HorseMule_01'] = {
        label = 'Mule', tier = 'stock', breed = 'Working Mule',
        price = { cash = 60.0, gold = 0.0 },
        breedable = false, maxHides = 5,
        sex = 'Gelding', age = 8, hands = 14.3,
        lore = 'Stubborn, sure-footed, and worth its weight on a long haul.',
        stats = { health = 72, stamina = 82, speed = 44, acceleration = 40 },
    },
}
