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

  ---------------------------------------------------------------------
  THE PRICE LADDER (tune freely — every number here is yours)
  ---------------------------------------------------------------------
  Anchored on RDR2's own stable prices so the numbers feel familiar, then
  pulled down to suit a low-wage economy. See docs/06-BREEDS.md for which
  breed sits in which band.

    Pack (mule, donkey)                            $30 -  $50
    Work / draft   (spd 2-4: Shire, Belgian,       $60 - $110
                    Ardennes, Suffolk Punch,
                    Breton, Gypsy Cob, Dutch
                    Warmblood, Hungarian Halfbred)
    Standard riding (spd 5-6: Kentucky Saddler,   $120 - $190
                    Tennessee Walker, Am.
                    Standardbred, Morgan, Criollo,
                    Norfolk Roadster, Appaloosa,
                    Am. Paint)
    Superior       (Missouri Fox Trotter, Nokota, $220 - $320
                    Andalusian, Mustang, Kladruber)
    Race / elite   (spd 9: Arabian, Thoroughbred, $550 - $850  (+ a gold option)
                    Turkoman)

  A gold price is optional and sits alongside cash — the buyer picks.
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

    -- This breed's base ped scale at full size (1.0 = the model's natural size;
    -- a mule sits nearer 0.90). Foals render at breed.scale x a growth-phase
    -- multiplier, so this must never be treated as absolute. See 05-LIFECYCLE.
    scale  = 1.0,

    -- The age at which speed + stamina begin their quiet decline [E8]. 27 for
    -- everything; 25 for the FAST BREEDS (Arabian, Thoroughbred, Turkoman) —
    -- they burn brighter and shorter. Death is always 31. See docs/06-BREEDS.md.
    declineAge = 27,

    -- The training level range the SHOP may generate for this horse, { min, max }.
    -- Low-stat stock tops out at 2; middle and high-stat stock can roll 2-3.
    -- The shop never generates a 4 — that tier is trainer-only.
    storeLevel = { 1, 2 },

    -- Storefront display card [N1-N4]. `tier` sorts it into the Specialty or
    -- Stock tab. Stats are configured base values now; they go live once the
    -- progression system lands (Phase 3).
    tier   = 'stock',        -- 'specialty' | 'stock'
    name   = nil,            -- showcase name (specialty). nil = use label.
    breed  = nil,            -- breed line under the name. nil = use label.
    sex    = 'Gelding',      -- Stallion | Mare | Gelding (buyers pick Stallion/Mare at purchase [N9])
    -- Age in years. STABLES MAY ONLY SELL 5-7 — anything older exists only in the
    -- wild. Foals (bred, or bought by a Horse Trainer) enter at 3-4 and become
    -- adults at 5. Death at 31. See docs/05-LIFECYCLE.md.
    age    = 5,
    hands  = 15.2,           -- height in hands [N3]
    lore   = 'A dependable mount, sound of wind and limb.',
    traits = {},             -- { { name='Steadfast', desc='...', level=1 }, ... }

    -- The five stats, 0-100. These are PREDETERMINED at birth and fixed for life
    -- (a foal is not weaker than its adult self). Each number here is the FULLY
    -- TRAINED ceiling — an untrained horse starts 10-20 points BELOW it, and
    -- training walks it up to the ceiling but never past. Only speed + stamina
    -- decline with old age (27, or 25 for the faster breeds). Courage is separate
    -- and trainable. Max health is 100. See docs/05-LIFECYCLE.md.
    stats  = { health = 70, stamina = 70, speed = 70, acceleration = 70, turn = 70 },
}

Config.Horses = {

    ['A_C_Horse_Turkoman_Gold'] = {
        label = 'Gold Turkoman',
        tier  = 'specialty',
        name  = 'Vesper',
        breed = 'Gold Turkoman',
        price = { cash = 750.0, gold = 6.0 },   -- race/elite tier (see the ladder above)
        storage = 40, breedable = true,
        declineAge = 25,          -- Turkoman: a FAST breed — burns brighter, fades sooner
        storeLevel = { 2, 3 },    -- high-stat stock: the shop may roll 2-3
        sex = 'Stallion', age = 6, hands = 16.2,
        lore = 'A refined warmblood with a willing mind and disciplined heart. Built for stamina, born for the long road ahead.',
        traits = {
            { name = 'Steadfast', desc = 'Handles pressure with calm resolve.', level = 1 },
            { name = 'Endurance', desc = 'Stays strong and steady over distance.' },
        },
        stats = { health = 88, stamina = 94, speed = 82, acceleration = 76, turn = 80 },
    },

    ['A_C_Horse_KentuckySaddle_Grey'] = {
        label = 'Kentucky Saddler', tier = 'stock', breed = 'Grey Kentucky Saddler',
        price = { cash = 130.0, gold = 0.0 },   -- standard riding tier
        storeLevel = { 2, 3 },                  -- middling stats: the shop may roll 2-3
        sex = 'Mare', age = 5, hands = 15.1,
        lore = 'A steady grey saddler — even-tempered and honest under saddle.',
        stats = { health = 66, stamina = 70, speed = 72, acceleration = 68, turn = 50 },
    },

    ['A_C_Horse_Ardennes_BayRoan'] = {
        label = 'Ardennes', tier = 'stock', breed = 'Bay Roan Ardennes',
        price = { cash = 95.0, gold = 0.0 },    -- work/draft tier
        storeLevel = { 1, 2 },                  -- lower-end stats: tops out at 2
        sex = 'Gelding', age = 7, hands = 16.0, storage = 38,
        lore = 'A heavy draft breed — strong of back, calm in a storm.',
        stats = { health = 90, stamina = 78, speed = 58, acceleration = 52, turn = 30 },
    },

    ['A_C_HorseMule_01'] = {
        label = 'Mule', tier = 'stock', breed = 'Working Mule',
        price = { cash = 35.0, gold = 0.0 },    -- pack tier
        storeLevel = { 1, 2 },                  -- lower-end stats: tops out at 2
        breedable = false, maxHides = 5,
        scale = 0.90,   -- a mule is smaller than a horse at "full size"
        -- Stables only sell horses aged 5-7; anything older is wild-only (see docs/05-LIFECYCLE.md).
        sex = 'Gelding', age = 7, hands = 14.3,
        lore = 'Stubborn, sure-footed, and worth its weight on a long haul.',
        stats = { health = 72, stamina = 82, speed = 44, acceleration = 40, turn = 40 },
    },
}
