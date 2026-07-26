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

    -- Which XP ladder this breed trains on [E9]: 'lowMid' (1,450 XP to level 4)
    -- or 'high' (2,460). The fast breeds are 'high' — they cost more to buy AND
    -- ~70% more work to finish. Set per breed; see Config.Training.levelXp.
    xpTier = 'lowMid',

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

    --==========================================================================
    -- THE FULL ROSTER — 107 models, 27 breeds  [M1, owner request 2026-07-25]
    --==========================================================================
    -- The four SHOWCASE horses come first: hand-written, with names, lore and
    -- trait cards. They're what the Specialty tab is for. Everything after them
    -- is generated from the breed table so the numbers stay internally consistent
    -- — edit any line freely, nothing regenerates over the top of you.
    --
    -- HOW EACH GENERATED VALUE WAS DECIDED (all from rulings already made):
    --   stats        docs/06-BREEDS.md figures (1-10) mapped onto our 0-100
    --                scale, calibrated against the four curated horses. These are
    --                TRAINED CEILINGS — a shop horse arrives 10-20 points below.
    --   price        the ladder in this file's header: pack $35 · work/draft $95
    --                · standard riding $130-150 · superior $260 · race/elite $750+6g
    --   declineAge   25 for the fast breeds (Arabian, Thoroughbred, Turkoman),
    --                27 for everything else. Death is always 31.
    --   xpTier       'high' for the fast breeds (2,460 XP to finish), else 'lowMid'
    --   storeLevel   {2,3} for middle and high-stat stock, {1,2} for the rest —
    --                the shop never rolls a 4, that tier is trainer-only
    --   courageFloor Mustang 3 · drafts/pack 2 · standard 1 · RACERS 0.
    --                The best horse money can buy is the most likely to throw you.
    --
    -- Model ids come from vorp_stables' MIT-licensed data.lua — see docs/CREDITS.md.
    -- Any coat NOT installed on your server simply never appears in a storefront.
    --==========================================================================

    ['A_C_Horse_Turkoman_Gold'] = {
        label = 'Gold Turkoman',
        tier  = 'specialty',
        name  = 'Vesper',
        breed = 'Gold Turkoman',
        price = { cash = 750.0, gold = 6.0 },   -- race/elite tier (see the ladder above)
        storage = 40, breedable = true,
        declineAge = 25,          -- Turkoman: a FAST breed — burns brighter, fades sooner
        storeLevel = { 2, 3 },    -- high-stat stock: the shop may roll 2-3
        xpTier     = 'high',      -- 2,460 XP to finish — the good ones take real work
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

    -- Arabian — Elite racer (speed 9)
    ['A_C_Horse_Arabian_Black'] = { label = 'Black Arabian', breed = 'Arabian', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 78, speed = 83, acceleration = 73, turn = 78 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    ['A_C_Horse_Arabian_Grey'] = { label = 'Grey Arabian', breed = 'Arabian', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 78, speed = 83, acceleration = 73, turn = 78 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    ['A_C_Horse_Arabian_RedChestnut'] = { label = 'Red Chestnut Arabian', breed = 'Arabian', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 78, speed = 83, acceleration = 73, turn = 78 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    ['A_C_Horse_Arabian_RoseGreyBay'] = { label = 'Rose Grey Bay Arabian', breed = 'Arabian', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 78, speed = 83, acceleration = 73, turn = 78 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    ['A_C_Horse_Arabian_WarpedBrindle_PC'] = { label = 'Warped Brindle Arabian', breed = 'Arabian', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 78, speed = 83, acceleration = 73, turn = 78 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    ['A_C_Horse_Arabian_White'] = { label = 'White Arabian', breed = 'Arabian', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 78, speed = 83, acceleration = 73, turn = 78 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },

    -- Thoroughbred — Pure racer (speed 9)
    ['A_C_Horse_Thoroughbred_BlackChestnut'] = { label = 'Black Chestnut Thoroughbred', breed = 'Thoroughbred', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 83, speed = 83, acceleration = 78, turn = 73 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    ['A_C_Horse_Thoroughbred_BloodBay'] = { label = 'Blood Bay Thoroughbred', breed = 'Thoroughbred', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 83, speed = 83, acceleration = 78, turn = 73 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    ['A_C_Horse_Thoroughbred_Brindle'] = { label = 'Brindle Thoroughbred', breed = 'Thoroughbred', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 83, speed = 83, acceleration = 78, turn = 73 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    ['A_C_Horse_Thoroughbred_DappleGrey'] = { label = 'Dapple Grey Thoroughbred', breed = 'Thoroughbred', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 83, speed = 83, acceleration = 78, turn = 73 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    ['A_C_Horse_Thoroughbred_ReverseDappleBlack'] = { label = 'Reverse Dapple Black Thoroughbred', breed = 'Thoroughbred', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 83, speed = 83, acceleration = 78, turn = 73 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },

    -- Turkoman — Elite war/race (speed 9)
    ['A_C_Horse_Turkoman_DarkBay'] = { label = 'Dark Bay Turkoman', breed = 'Turkoman', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 78, speed = 83, acceleration = 78, turn = 78 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },
    -- A_C_Horse_Turkoman_Gold: curated above
    ['A_C_Horse_Turkoman_Silver'] = { label = 'Silver Turkoman', breed = 'Turkoman', price = { cash = 750.0, gold = 6.0 }, stats = { health = 88, stamina = 78, speed = 83, acceleration = 78, turn = 78 }, courageFloor = 0, tier = 'specialty', declineAge = 25, xpTier = 'high', storeLevel = { 2, 3 } },

    -- American Standardbred — Standard riding (speed 6)
    ['A_C_Horse_AmericanStandardbred_Black'] = { label = 'Black American Standardbred', breed = 'American Standardbred', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_AmericanStandardbred_Buckskin'] = { label = 'Buckskin American Standardbred', breed = 'American Standardbred', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_AmericanStandardbred_PalominoDapple'] = { label = 'Palomino Dapple American Standardbred', breed = 'American Standardbred', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_AmericanStandardbred_SilverTailBuckskin'] = { label = 'Silver Tail Buckskin American Standardbred', breed = 'American Standardbred', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Andalusian — Standard / war (speed 6)
    ['A_C_Horse_Andalusian_DarkBay'] = { label = 'Dark Bay Andalusian', breed = 'Andalusian', price = { cash = 150.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 68, acceleration = 63, turn = 73 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Andalusian_Perlino'] = { label = 'Perlino Andalusian', breed = 'Andalusian', price = { cash = 150.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 68, acceleration = 63, turn = 73 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Andalusian_RoseGray'] = { label = 'Rose Gray Andalusian', breed = 'Andalusian', price = { cash = 150.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 68, acceleration = 63, turn = 73 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Kentucky Saddler — Standard riding (speed 6)
    ['A_C_Horse_KentuckySaddle_Black'] = { label = 'Black Kentucky Saddler', breed = 'Kentucky Saddler', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC'] = { label = 'Butter Milk Buckskin Kentucky Saddler', breed = 'Kentucky Saddler', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_KentuckySaddle_ChestnutPinto'] = { label = 'Chestnut Pinto Kentucky Saddler', breed = 'Kentucky Saddler', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    -- A_C_Horse_KentuckySaddle_Grey: curated above
    ['A_C_Horse_KentuckySaddle_SilverBay'] = { label = 'Silver Bay Kentucky Saddler', breed = 'Kentucky Saddler', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Kladruber — Standard (speed 6)
    ['A_C_Horse_Kladruber_Black'] = { label = 'Black Kladruber', breed = 'Kladruber', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 58, turn = 53 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Kladruber_Cremello'] = { label = 'Cremello Kladruber', breed = 'Kladruber', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 58, turn = 53 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Kladruber_DappleRoseGrey'] = { label = 'Dapple Rose Grey Kladruber', breed = 'Kladruber', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 58, turn = 53 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Kladruber_Grey'] = { label = 'Grey Kladruber', breed = 'Kladruber', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 58, turn = 53 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Kladruber_Silver'] = { label = 'Silver Kladruber', breed = 'Kladruber', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 58, turn = 53 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Kladruber_White'] = { label = 'White Kladruber', breed = 'Kladruber', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 58, turn = 53 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Missouri Fox Trotter — Superior all-rounder (speed 6)
    ['A_C_Horse_MissouriFoxTrotter_AmberChampagne'] = { label = 'Amber Champagne Missouri Fox Trotter', breed = 'Missouri Fox Trotter', price = { cash = 260.0, gold = 0.0 }, stats = { health = 73, stamina = 73, speed = 68, acceleration = 68, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_MissouriFoxTrotter_SableChampagne'] = { label = 'Sable Champagne Missouri Fox Trotter', breed = 'Missouri Fox Trotter', price = { cash = 260.0, gold = 0.0 }, stats = { health = 73, stamina = 73, speed = 68, acceleration = 68, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_MissouriFoxTrotter_SilverDapplePinto'] = { label = 'Silver Dapple Pinto Missouri Fox Trotter', breed = 'Missouri Fox Trotter', price = { cash = 260.0, gold = 0.0 }, stats = { health = 73, stamina = 73, speed = 68, acceleration = 68, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Morgan — Quick but no launch (speed 6)
    ['A_C_Horse_Morgan_Bay'] = { label = 'Bay Morgan', breed = 'Morgan', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Morgan_BayRoan'] = { label = 'Bay Roan Morgan', breed = 'Morgan', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Morgan_FlaxenChestnut'] = { label = 'Flaxen Chestnut Morgan', breed = 'Morgan', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Morgan_LiverChestnut_PC'] = { label = 'Liver Chestnut Morgan', breed = 'Morgan', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Morgan_Palomino'] = { label = 'Palomino Morgan', breed = 'Morgan', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Mustang — Hardy, brave (speed 6)
    ['A_C_Horse_Mustang_BlackOvero'] = { label = 'Black Overo Mustang', breed = 'Mustang', price = { cash = 150.0, gold = 0.0 }, stats = { health = 74, stamina = 78, speed = 68, acceleration = 63, turn = 78 }, courageFloor = 3, storeLevel = { 2, 3 } },
    ['A_C_Horse_Mustang_Buckskin'] = { label = 'Buckskin Mustang', breed = 'Mustang', price = { cash = 150.0, gold = 0.0 }, stats = { health = 74, stamina = 78, speed = 68, acceleration = 63, turn = 78 }, courageFloor = 3, storeLevel = { 2, 3 } },
    ['A_C_Horse_Mustang_ChestNuttOvero'] = { label = 'Chest Nutt Overo Mustang', breed = 'Mustang', price = { cash = 150.0, gold = 0.0 }, stats = { health = 74, stamina = 78, speed = 68, acceleration = 63, turn = 78 }, courageFloor = 3, storeLevel = { 2, 3 } },
    ['A_C_Horse_Mustang_GoldenDun'] = { label = 'Golden Dun Mustang', breed = 'Mustang', price = { cash = 150.0, gold = 0.0 }, stats = { health = 74, stamina = 78, speed = 68, acceleration = 63, turn = 78 }, courageFloor = 3, storeLevel = { 2, 3 } },
    ['A_C_Horse_Mustang_GrulloDun'] = { label = 'Grullo Dun Mustang', breed = 'Mustang', price = { cash = 150.0, gold = 0.0 }, stats = { health = 74, stamina = 78, speed = 68, acceleration = 63, turn = 78 }, courageFloor = 3, storeLevel = { 2, 3 } },
    ['A_C_Horse_Mustang_RedDunOvero'] = { label = 'Red Dun Overo Mustang', breed = 'Mustang', price = { cash = 150.0, gold = 0.0 }, stats = { health = 74, stamina = 78, speed = 68, acceleration = 63, turn = 78 }, courageFloor = 3, storeLevel = { 2, 3 } },
    ['A_C_Horse_Mustang_TigerStripedBay'] = { label = 'Tiger Striped Bay Mustang', breed = 'Mustang', price = { cash = 150.0, gold = 0.0 }, stats = { health = 74, stamina = 78, speed = 68, acceleration = 63, turn = 78 }, courageFloor = 3, storeLevel = { 2, 3 } },
    ['A_C_Horse_Mustang_WildBay'] = { label = 'Wild Bay Mustang', breed = 'Mustang', price = { cash = 150.0, gold = 0.0 }, stats = { health = 74, stamina = 78, speed = 68, acceleration = 63, turn = 78 }, courageFloor = 3, storeLevel = { 2, 3 } },

    -- Nokota — Standard (speed 6)
    ['A_C_Horse_Nokota_BlueRoan'] = { label = 'Blue Roan Nokota', breed = 'Nokota', price = { cash = 150.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 68, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Nokota_ReverseDappleRoan'] = { label = 'Reverse Dapple Roan Nokota', breed = 'Nokota', price = { cash = 150.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 68, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Nokota_WhiteRoan'] = { label = 'White Roan Nokota', breed = 'Nokota', price = { cash = 150.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 68, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Tennessee Walker — Standard riding (speed 6)
    ['A_C_Horse_TennesseeWalker_BlackRabicano'] = { label = 'Black Rabicano Tennessee Walker', breed = 'Tennessee Walker', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_TennesseeWalker_Chestnut'] = { label = 'Chestnut Tennessee Walker', breed = 'Tennessee Walker', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_TennesseeWalker_DappleBay'] = { label = 'Dapple Bay Tennessee Walker', breed = 'Tennessee Walker', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_TennesseeWalker_FlaxenRoan'] = { label = 'Flaxen Roan Tennessee Walker', breed = 'Tennessee Walker', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_TennesseeWalker_GoldPalomino_PC'] = { label = 'Gold Palomino Tennessee Walker', breed = 'Tennessee Walker', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_TennesseeWalker_MahoganyBay'] = { label = 'Mahogany Bay Tennessee Walker', breed = 'Tennessee Walker', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_TennesseeWalker_RedRoan'] = { label = 'Red Roan Tennessee Walker', breed = 'Tennessee Walker', price = { cash = 150.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 68, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- American Paint — Nimble, punchy (speed 5)
    ['A_C_Horse_AmericanPaint_Greyovero'] = { label = 'Greyovero American Paint', breed = 'American Paint', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 73, turn = 73 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_AmericanPaint_Overo'] = { label = 'Overo American Paint', breed = 'American Paint', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 73, turn = 73 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_AmericanPaint_SplashedWhite'] = { label = 'Splashed White American Paint', breed = 'American Paint', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 73, turn = 73 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_AmericanPaint_Tobiano'] = { label = 'Tobiano American Paint', breed = 'American Paint', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 73, turn = 73 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Appaloosa — Standard (speed 5)
    ['A_C_Horse_Appaloosa_BlackSnowflake'] = { label = 'Black Snowflake Appaloosa', breed = 'Appaloosa', price = { cash = 130.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 63, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Appaloosa_Blanket'] = { label = 'Blanket Appaloosa', breed = 'Appaloosa', price = { cash = 130.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 63, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Appaloosa_BrownLeopard'] = { label = 'Brown Leopard Appaloosa', breed = 'Appaloosa', price = { cash = 130.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 63, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Appaloosa_FewSpotted_PC'] = { label = 'Few Spotted Appaloosa', breed = 'Appaloosa', price = { cash = 130.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 63, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Appaloosa_Leopard'] = { label = 'Leopard Appaloosa', breed = 'Appaloosa', price = { cash = 130.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 63, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Appaloosa_LeopardBlanket'] = { label = 'Leopard Blanket Appaloosa', breed = 'Appaloosa', price = { cash = 130.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 63, acceleration = 63, turn = 68 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Criollo — Modest work (speed 5)
    ['A_C_Horse_Criollo_BayBrindle'] = { label = 'Bay Brindle Criollo', breed = 'Criollo', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 53, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Criollo_BayFrameOvero'] = { label = 'Bay Frame Overo Criollo', breed = 'Criollo', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 53, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Criollo_BlueRoanOvero'] = { label = 'Blue Roan Overo Criollo', breed = 'Criollo', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 53, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Criollo_Dun'] = { label = 'Dun Criollo', breed = 'Criollo', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 53, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Criollo_MarbleSabino'] = { label = 'Marble Sabino Criollo', breed = 'Criollo', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 53, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_Criollo_SorrelOvero'] = { label = 'Sorrel Overo Criollo', breed = 'Criollo', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 53, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Mangy Backup — Mangy backup (speed 5)
    ['A_C_Horse_MP_Mangy_Backup'] = { label = 'Mangy Backup', breed = 'Mangy Backup', price = { cash = 130.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 63, acceleration = 63, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Norfolk Roadster — Standard (speed 5)
    ['A_C_Horse_NorfolkRoadster_Black'] = { label = 'Black Norfolk Roadster', breed = 'Norfolk Roadster', price = { cash = 130.0, gold = 0.0 }, stats = { health = 70, stamina = 58, speed = 63, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_NorfolkRoadster_DappledBuckskin'] = { label = 'Dappled Buckskin Norfolk Roadster', breed = 'Norfolk Roadster', price = { cash = 130.0, gold = 0.0 }, stats = { health = 70, stamina = 58, speed = 63, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_NorfolkRoadster_PiebaldRoan'] = { label = 'Piebald Roan Norfolk Roadster', breed = 'Norfolk Roadster', price = { cash = 130.0, gold = 0.0 }, stats = { health = 70, stamina = 58, speed = 63, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_NorfolkRoadster_RoseGrey'] = { label = 'Rose Grey Norfolk Roadster', breed = 'Norfolk Roadster', price = { cash = 130.0, gold = 0.0 }, stats = { health = 70, stamina = 58, speed = 63, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_NorfolkRoadster_SpeckledGrey'] = { label = 'Speckled Grey Norfolk Roadster', breed = 'Norfolk Roadster', price = { cash = 130.0, gold = 0.0 }, stats = { health = 70, stamina = 58, speed = 63, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },
    ['A_C_Horse_NorfolkRoadster_SpottedTricolor'] = { label = 'Spotted Tricolor Norfolk Roadster', breed = 'Norfolk Roadster', price = { cash = 130.0, gold = 0.0 }, stats = { health = 70, stamina = 58, speed = 63, acceleration = 48, turn = 63 }, courageFloor = 1, storeLevel = { 2, 3 } },

    -- Suffolk Punch — Draft (speed 4)
    ['A_C_Horse_SuffolkPunch_RedChestnut'] = { label = 'Red Chestnut Suffolk Punch', breed = 'Suffolk Punch', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 68, speed = 58, acceleration = 48, turn = 58 }, courageFloor = 2 },
    ['A_C_Horse_SuffolkPunch_Sorrel'] = { label = 'Sorrel Suffolk Punch', breed = 'Suffolk Punch', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 68, speed = 58, acceleration = 48, turn = 58 }, courageFloor = 2 },

    -- Belgian — Draft (speed 3)
    ['A_C_Horse_Belgian_BlondChestnut'] = { label = 'Blond Chestnut Belgian', breed = 'Belgian', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 68, speed = 53, acceleration = 48, turn = 53 }, courageFloor = 2 },
    ['A_C_Horse_Belgian_MealyChestnut'] = { label = 'Mealy Chestnut Belgian', breed = 'Belgian', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 68, speed = 53, acceleration = 48, turn = 53 }, courageFloor = 2 },

    -- Dutch Warmblood — Work (speed 3)
    ['A_C_Horse_DutchWarmblood_ChocolateRoan'] = { label = 'Chocolate Roan Dutch Warmblood', breed = 'Dutch Warmblood', price = { cash = 95.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 53, acceleration = 58, turn = 58 }, courageFloor = 1 },
    ['A_C_Horse_DutchWarmblood_SealBrown'] = { label = 'Seal Brown Dutch Warmblood', breed = 'Dutch Warmblood', price = { cash = 95.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 53, acceleration = 58, turn = 58 }, courageFloor = 1 },
    ['A_C_Horse_DutchWarmblood_SootyBuckskin'] = { label = 'Sooty Buckskin Dutch Warmblood', breed = 'Dutch Warmblood', price = { cash = 95.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 53, acceleration = 58, turn = 58 }, courageFloor = 1 },

    -- Hungarian Halfbred — Work (speed 3)
    ['A_C_Horse_HungarianHalfbred_DarkDappleGrey'] = { label = 'Dark Dapple Grey Hungarian Halfbred', breed = 'Hungarian Halfbred', price = { cash = 95.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 53, acceleration = 58, turn = 58 }, courageFloor = 1 },
    ['A_C_Horse_HungarianHalfbred_FlaxenChestnut'] = { label = 'Flaxen Chestnut Hungarian Halfbred', breed = 'Hungarian Halfbred', price = { cash = 95.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 53, acceleration = 58, turn = 58 }, courageFloor = 1 },
    ['A_C_Horse_HungarianHalfbred_LiverChestnut'] = { label = 'Liver Chestnut Hungarian Halfbred', breed = 'Hungarian Halfbred', price = { cash = 95.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 53, acceleration = 58, turn = 58 }, courageFloor = 1 },
    ['A_C_Horse_HungarianHalfbred_PiebaldTobiano'] = { label = 'Piebald Tobiano Hungarian Halfbred', breed = 'Hungarian Halfbred', price = { cash = 95.0, gold = 0.0 }, stats = { health = 71, stamina = 63, speed = 53, acceleration = 58, turn = 58 }, courageFloor = 1 },

    -- Ardennes — Heavy draft (speed 2)
    -- A_C_Horse_Ardennes_BayRoan: curated above
    ['A_C_Horse_Ardennes_IronGreyRoan'] = { label = 'Iron Grey Roan Ardennes', breed = 'Ardennes', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 68, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2 },
    ['A_C_Horse_Ardennes_StrawberryRoan'] = { label = 'Strawberry Roan Ardennes', breed = 'Ardennes', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 68, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2 },

    -- Breton — Heavy draft (speed 2)
    ['A_C_Horse_Breton_GrulloDun'] = { label = 'Grullo Dun Breton', breed = 'Breton', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 58, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2 },
    ['A_C_Horse_Breton_MealyDapple'] = { label = 'Mealy Dapple Breton', breed = 'Breton', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 58, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2 },
    ['A_C_Horse_Breton_RedRoan'] = { label = 'Red Roan Breton', breed = 'Breton', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 58, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2 },
    ['A_C_Horse_Breton_SealBrown'] = { label = 'Seal Brown Breton', breed = 'Breton', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 58, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2 },
    ['A_C_Horse_Breton_Sorrel'] = { label = 'Sorrel Breton', breed = 'Breton', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 58, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2 },
    ['A_C_Horse_Breton_SteelGrey'] = { label = 'Steel Grey Breton', breed = 'Breton', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 58, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2 },

    -- Donkey — Pack animal (speed 2)
    ['A_C_Donkey_01'] = { label = 'Donkey', breed = 'Donkey', price = { cash = 35.0, gold = 0.0 }, stats = { health = 72, stamina = 63, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2, scale = 0.90, breedable = false },

    -- Mule — Pack animal (speed 2)
    -- A_C_HorseMule_01: curated above

    -- Painted Mule — Pack animal (speed 2)
    ['A_C_HorseMulePainted_01'] = { label = 'Painted Mule', breed = 'Painted Mule', price = { cash = 35.0, gold = 0.0 }, stats = { health = 72, stamina = 68, speed = 48, acceleration = 48, turn = 53 }, courageFloor = 2, scale = 0.90, breedable = false },

    -- Shire — Heaviest draft (speed 2)
    ['A_C_Horse_Shire_DarkBay'] = { label = 'Dark Bay Shire', breed = 'Shire', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 63, speed = 48, acceleration = 48, turn = 48 }, courageFloor = 2 },
    ['A_C_Horse_Shire_LightGrey'] = { label = 'Light Grey Shire', breed = 'Shire', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 63, speed = 48, acceleration = 48, turn = 48 }, courageFloor = 2 },
    ['A_C_Horse_Shire_RavenBlack'] = { label = 'Raven Black Shire', breed = 'Shire', price = { cash = 95.0, gold = 0.0 }, stats = { health = 90, stamina = 63, speed = 48, acceleration = 48, turn = 48 }, courageFloor = 2 },
}
