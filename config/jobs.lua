--[[=====================================================================
  SOVEREIGN STABLES · JOB PERMISSIONS
  ---------------------------------------------------------------------
  Per-job (and, where noted, per-grade) permissions. Any job NOT listed here
  uses Config.JobDefaults. A permission of `true` allows it, `false` denies it,
  numbers set limits, and a modifier of 1.0 means "normal".

  These gates layer on top of the global caps in config/config.lua.
=====================================================================]]--

Config = Config or {}

Config.JobDefaults = {
    -- ⚠️ maxHorses / maxWagons deliberately DO NOT live here any more.
    -- They duplicated Config.Caps in config/config.lua, and because a job value
    -- always wins, these defaults silently overrode the global caps for EVERY
    -- player — that's how "wagon limit should be 5" resolved to 1. The caps live
    -- in ONE place now (Config.Caps); list them under a specific job below only
    -- when that job genuinely differs.
    maxBreedings       = 1,      -- concurrent active breedings [J3]
    xpModifier         = 1.0,    -- multiplies horse XP gain [J4]

    training           = true,   -- general horse training [J5]
    lunging            = true,   -- [J6]
    obstacleCourses    = true,   -- [J7]
    bonding            = true,   -- [J8]
    courageTraining    = true,   -- [J9]
    taming             = true,   -- wild horse taming [J10]
    breeding           = true,   -- [J11]
    horseshoeInstall   = true,   -- [J12]
    accessOthersHorses = false,  -- open other players' horse inventories [J13]
    -- ⚖️ RULED 2026-07-15. TRUE for everyone, and that is deliberate.
    -- `wagonRepair` is the FIELD repair: anyone can patch a wagon up to
    -- Config.WagonDamage.fieldRepairTo — enough to get going, no more. Nobody is
    -- ever stranded because no Wagon Maker is online.
    -- Taking a wagon to 100% is `wagonFullRepair`, and that is Wagon-Maker-only.
    -- Same shape as horse training: the floor is free, the ceiling is a service.
    wagonRepair        = true,   -- field repair, to the floor [J14]
    wagonFullRepair    = false,  -- restore to 100% — Wagon Maker (grade 2) + boss
    horseHealing       = true,   -- [J15]
    hoofCleaning       = true,   -- horseshoe/hoof cleaning [J16]
    statsVisibility    = true,   -- see detailed horse statistics [J17]
    recall             = true,   -- horse & wagon recall [J18]
    -- CUSTOMIZATION IS TIERED (ruled 2026-07-15) — see Config.Customization.
    -- `customization` is the counter: buy tack, fit it, and pick from the short
    -- public colour list. Everyone gets this; nobody is ever blocked from
    -- dressing their own horse.
    customization      = true,   -- buy + fit tack, limited colours [J19]
    -- `fullCustomization` is the whole palette — a Horse Trainer's perk. NOT the
    -- Wagon Maker's: their trade is wagons, not horses.
    fullCustomization  = false,  -- the entire tint range [J19+]
    painting           = true,   -- coat painting [J20]
    wagonCrafting      = false,  -- build wagons via crafting [J21]
    wagonCustomizing   = false,  -- wagon livery/colour [WG4]
    storefronts        = false,  -- manage a stable's storefront (not built yet)
    horseCreator       = false,  -- access the Horse Creator [J22]
}

-- Override per job. Only list the fields that differ from JobDefaults.
Config.Jobs = {

    ['horsetrainer'] = {
        -- Job-wide values. These apply to EVERY grade of the job; anything that
        -- differs between grades belongs in `grades` below, not here.
        maxHorses          = 8,
        xpModifier         = 1.25,
        accessOthersHorses = true,

        --======================================================================
        -- GRADES ARE ROLES, NOT RANKS  (owner ruling, 2026-07-15)
        --======================================================================
        -- Read `docs/07-HORSE-TRAINER.md` before touching this table.
        --
        -- Each grade below lists its permissions EXPLICITLY. **Nothing is
        -- inherited from a lower grade.** Grade 2 is not "more than" grade 1 —
        -- the numbers are names, not a ladder.
        --
        -- This is deliberate and load-bearing. A Wagon Maker (2) has storefronts
        -- but CANNOT train horses; a Horse Trainer (0) can train but has NO
        -- storefronts. Neither contains the other — they're peers with different
        -- trades, and no ladder can rank peers. If these inherited, a Wagon Maker
        -- would silently gain horse training the moment someone reordered the
        -- list, which is the exact thing the ruling exists to prevent.
        --
        -- A grade not listed here gets the job's values above + JobDefaults.
        grades = {
            [0] = {
                title             = 'Horse Trainer',
                training          = true,
                fullCustomization = true,   -- the whole palette; the Horse Maker is not theirs
                storefronts       = false,
                wagonCrafting     = false,
                wagonCustomizing  = false,
                wagonFullRepair   = false,   -- field repair only, like everyone
            },
            [1] = {
                title             = 'Senior Horse Trainer',
                training          = true,
                fullCustomization = true,
                storefronts       = true,
                wagonCrafting     = false,
                wagonCustomizing  = false,
                wagonFullRepair   = false,   -- field repair only, like everyone
            },
            [2] = {
                -- "Wagon makers don't get horse training perms. Their only job is
                --  Wagon Making, wagon customization and wagon repair and
                --  storefronts." — owner, 2026-07-15
                title             = 'Wagon Maker',
                training          = false,  -- ← the whole point. Not a trainer.
                -- No full HORSE customization either: their trade is wagons.
                -- They still get the public counter like everyone else.
                fullCustomization = false,
                storefronts       = true,
                wagonCrafting     = true,
                wagonCustomizing  = true,
                wagonFullRepair   = true,    -- ← THE TRADE: only they reach 100%
            },
            [3] = {
                -- The boss. Admin-granted only, and the one grade that legitimately
                -- has everything — a policy, not an inheritance rule.
                title             = 'Stable Owner',
                training          = true,
                fullCustomization = true,
                storefronts       = true,
                wagonCrafting     = true,
                wagonCustomizing  = true,
                wagonFullRepair   = true,
                horseCreator      = true,   -- [J22/M2] the Horse Creator is boss-only
            },
        },
    },

    ['rancher'] = {
        maxHorses    = 6,
        maxWagons    = 3,
        maxBreedings = 3,
    },
}
