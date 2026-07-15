--[[=====================================================================
  SOVEREIGN STABLES · GLOBAL CONFIG
  ---------------------------------------------------------------------
  This file holds server-wide options. Per-stable, per-horse, per-wagon
  and per-job settings live in their own files:
      config/stables.lua   config/horses.lua
      config/wagons.lua     config/jobs.lua    config/tack.lua

  Every option is commented. If you are not a programmer: only change the
  values after the '=' sign, keep the quotes and commas exactly as shown,
  and run  /stables_diag  in game after a restart to check for mistakes.
=====================================================================]]--

Config = Config or {}

-- Language file to use (see config/locales/). 'en' ships by default.
Config.Locale = 'en'

-- Print extra debug info to the server/client console. Turn OFF on a live server.
Config.Debug = true

--------------------------------------------------------------------------------
-- OWNERSHIP CAPS  (a player can be further limited per job in config/jobs.lua)
--------------------------------------------------------------------------------
Config.Caps = {
    maxHorses      = 3,   -- most horses one character may own
    maxWagons      = 1,   -- most wagons one character may own
    maxStableSlots = 3,   -- most horses + wagons combined kept stored at once
}

--------------------------------------------------------------------------------
-- KEYBINDS  (players may rebind these in-game if Config.AllowRebind = true)
--   Names are RedM control names; see shared/util.lua Keys table.
--------------------------------------------------------------------------------
Config.AllowRebind = true
Config.Keys = {
    callHorse = 'H',   -- whistle for your default horse
    callWagon = 'J',   -- call your default wagon
    follow    = 'E',   -- toggle horse follow after calling
}

--------------------------------------------------------------------------------
-- SUMMONING / RECALL
--------------------------------------------------------------------------------
Config.Summon = {
    -- Default rule for whether a horse may be whistled from anywhere, or must be
    -- collected at a stable. Can be overridden per-horse in config/horses.lua.
    whistleAllowedByDefault = true,
    whistleDistance         = 60.0,  -- metres a whistled horse will travel to reach you
    recallCooldownSeconds   = 30,    -- wait after dismissing before you can recall
    deadRespawnSeconds      = 120,   -- wait after a horse dies before it can return
    autoRecallDistance      = 200.0, -- a stray, unused ride further than this is respawned near you
}

--------------------------------------------------------------------------------
-- STORAGE ACCESS
--------------------------------------------------------------------------------
Config.Access = {
    horseInventory = 'owner',   -- 'owner' | 'everyone' | 'permitted'  (see config/jobs.lua J13)
    wagonInventory = 'owner',   -- 'owner' | 'everyone' | 'permitted'
    ignoreStackLimit = { horse = true, wagon = true },
    defaultMaxWeight = 125,     -- fallback inventory capacity; per-model caps live in config/horses|wagons
}

--------------------------------------------------------------------------------
-- TRANSFER  — handing a horse or wagon to another player [milestone 1.4]
--   Identified by SERVER SESSION ID ("hat size" in RP). Ownership genuinely
--   moves; there is no lending flag. The Horse Trainer's custody transfer in
--   Phase 3 reuses this same system, so anything changed here changes that.
--------------------------------------------------------------------------------
Config.Transfer = {
    enabled     = true,
    allowWagons = true,
    -- Both players must be standing together — stops "hat size" transfers across
    -- the map, and keeps the handover an actual scene. 0 disables the check.
    maxDistance = 5.0,
    -- How long the other player has to answer before the offer lapses.
    offerTimeoutSeconds = 30,
}

--------------------------------------------------------------------------------
-- ECONOMY  (VORP has two currencies: 0 = cash, 1 = gold)
--------------------------------------------------------------------------------
Config.Economy = {
    enableBuying   = true,   -- master switch for purchasing horses/wagons
    enableSelling  = true,   -- allow selling horses back
    enableGold     = true,   -- allow gold pricing alongside cash
    -- Anti-dupe / audit: log every money-moving action server-side (X2).
    transactionLog = true,
}

--------------------------------------------------------------------------------
-- DEATH  (long-term "hard death" — a horse permanently dies after enough damage)
--------------------------------------------------------------------------------
Config.Death = {
    hardDeath        = true,
    longTermHealth   = 100,   -- starting pool; damage per reason set in config (Phase 3)
    xpLossOnRestart  = 0,     -- XP a horse loses each server restart (0 = none)  [S9/E7]
}

--------------------------------------------------------------------------------
-- TRAINING  [07-HORSE-TRAINER]
--   Only a Horse Trainer may train. A horse's stats in config/horses.lua are
--   its FULLY TRAINED ceiling (tier 4); a greener horse sits below it.
--   The shop never generates above tier 3 — tier 4 is the thing you cannot buy.
--------------------------------------------------------------------------------
Config.Training = {
    maxTier      = 4,   -- the ceiling. Trainer-only.
    storeMaxTier = 3,   -- the highest level the shop can ever generate

    -- How far below the ceiling each tier sits, in stat points (0-100 scale).
    -- A store horse is therefore always 10-20 points off its ceiling, and only
    -- a trainer closes the last (biggest) step.
    tierOffset = { [1] = -20, [2] = -15, [3] = -10, [4] = 0 },

    -- Real-life DAYS of training to reach a tier. The tier's number IS the day
    -- count, whatever level the horse arrived at: tier 4 is always 4 days.
    daysForTier = { [1] = 1, [2] = 2, [3] = 3, [4] = 4 },

    -- Training takes custody: the owner transfers the horse to the trainer
    -- (server session id — "hat size"), it becomes the trainer's property for
    -- the duration, and the trainer transfers it back when done.
    custodyTransfer = true,

    -- Horses a trainer is holding for training don't count against their cap.
    heldHorsesIgnoreCap = true,

    -- XP needed to reach each level, by the horse's xpTier (config/horses.lua).
    -- A horse bought at level 2 starts with that level's XP already banked.
    levelXp = {
        lowMid = { [1] = 0, [2] = 483,  [3] = 966,  [4] = 1450 },
        high   = { [1] = 0, [2] = 820,  [3] = 1640, [4] = 2460 },
    },

    -- XP PER SECOND while performing a move [E9].
    --   Mirroring is the fastest — and you can walk while doing it, so it's how
    --     you bring an unmountable foal home. Widely seen as the lazy way out.
    --   Longeing is the middle ground, with a bonus for jumping mid-longe.
    --   The flourishes are the slowest.
    -- FIRST PASS — tune these against real sessions. At these rates a low/mid
    -- horse (1450) finishes in ~8 min mirrored, ~12 longeing, ~24 on flourishes;
    -- a high-tier horse (2460) takes ~70% longer.
    xpPerSecond = {
        mirroring   = 3.0,
        longeing    = 2.0,
        dance       = 1.0,
        footScratch = 1.0,
        jump        = 1.0,
        rear        = 1.0,
    },
    longeJumpBonus = 25,   -- one-off XP for pressing Jump during a longe

    -- THE REPERTOIRE [E10]: a horse only knows what you actually taught it.
    -- Each move must be worked this many times before the horse learns it.
    -- Nothing is announced and nothing is ever displayed — the owner finds out
    -- the first time they ask for it and get nothing (or get it badly).
    --
    -- Everything here teaches a TRICK, with ONE exception: longeing is the only
    -- move that touches a STAT, and it's stamina. In the West stamina beats
    -- speed — a horse that goes all day beats one that goes fast for ten
    -- minutes. So mirror all night and you get a level-4 horse that is fast,
    -- handsome, obedient, and CANNOT GO THE DISTANCE. You can't shortcut wind.
    repertoire = {
        enabled = true,
        repsToLearn = {
            mirroring   = 20,   -- trick: responsiveness — follows, comes quicker, listens
            dance       = 15,   -- trick: dance under saddle (hold SPACE)
            jump        = 15,   -- trick: clears ground obstacles cleanly
            rear        = 15,   -- trick: rears on command
            footScratch = 15,   -- trick: teaches nothing — the horse just foot-scratches LESS
            longeing    = 20,   -- STAT: stamina. The only stat a trainer cannot fake.
        },
        -- Stamina is gated behind longeing reps ON TOP of the tier ladder: a
        -- tier-4 horse that was never longed still falls short of its stamina
        -- ceiling. Every other stat closes with the tier as normal.
        staminaRequiresLongeing = true,
    },

    -- The longeing sub-menu (its own panel, bottom-right).
    longeing = {
        radiusStep = 10.0,          -- metres per "Change Radius" press
        radiusMin  = 10.0,
        radiusMax  = 40.0,
        -- "Adjust Speed Up" cycles through these; past the last it wraps to the first.
        speeds     = { 'walk', 'trot', 'canter', 'gallop' },
    },
}

--------------------------------------------------------------------------------
-- COURAGE TRAINING  [E3/E4 · 07-HORSE-TRAINER]
--   NOT the Training Menu. Courage is its own 0-9 ladder, trained by walking a
--   horse at something that wants to eat it. Horse Trainers only (J9). Foals
--   may never train it. Once earned it is NEVER lost — the horse keeps it for
--   life. Unlike the repertoire, courage IS visible: the owner stands at the
--   horse, right-clicks, and reads it on the horse info panel.
--------------------------------------------------------------------------------
Config.Courage = {
    enabled  = true,
    maxLevel = 9,        -- the ceiling. Always earned, never bought.

    -- XP to reach each level. Escalating, so 9 is an achievement.
    -- FIRST PASS — tune against real sessions in the Phase 3 spike.
    levelXp = { [0] = 0, [1] = 120, [2] = 280, [3] = 500, [4] = 800,
                [5] = 1200, [6] = 1750, [7] = 2500, [8] = 3500, [9] = 5000 },

    -- Starting floor by breed. Set per-horse in config/horses.lua via
    -- `courageFloor`; this is the fallback. Breed gives a FLOOR, not a head
    -- start — see docs/06-BREEDS.md. Racers start at 0 on purpose: the fastest
    -- horse in the county is also the one most likely to throw you at a wolf.
    defaultFloor = 1,

    -- THE FEAR ANIMALS. We spawn NOTHING — these are the world's own animals.
    -- The trainer finds them, leads the horse to them, or pens their own.
    --   radius  = how close the horse must be to earn XP (metres)
    --   xpPerSecond = paid for TIME IN RADIUS, scaled to the animal's real danger
    -- The gator is safe because gators are lazy; the bear is fast because bears
    -- are bears. The world already priced this trade — we just pay it out.
    fearAnimals = {
        { models = { 'a_c_alligator_01', 'a_c_alligator_02', 'a_c_alligator_03' },
          name = 'Alligator', radius = 18.0, xpPerSecond = 1.0 },   -- the swamp method
        { models = { 'a_c_snake_01', 'a_c_snakeblacktailrattle_01', 'a_c_snakeferdelance_01',
                     'a_c_snakewater_01', 'a_c_snakeredboa_01' },
          name = 'Snake',     radius = 10.0, xpPerSecond = 1.2 },
        { models = { 'a_c_wolf', 'a_c_wolf_01', 'a_c_wolf_medium', 'a_c_wolf_small' },
          name = 'Wolf',      radius = 25.0, xpPerSecond = 2.5 },
        { models = { 'a_c_cougar_01' },
          name = 'Cougar',    radius = 25.0, xpPerSecond = 3.0 },
        { models = { 'a_c_bear_01', 'a_c_bearblack_01' },
          name = 'Bear',      radius = 30.0, xpPerSecond = 4.0 },   -- if you live
    },

    -- One-off bonus when a pat/calm actually lands (EVENT_CALM_PED idx 3,
    -- isFullyCalmed). The pat is the TOOL that buys time in the radius — it is
    -- not the wage. Time is the wage. Keep this small.
    fullyCalmedBonus = 5,

    -- The horse must actually be frightened to be learning anything. If false,
    -- proximity alone pays (easier, but a courage-9 horse would farm itself).
    requireSpooked = true,

    -- THE LADDER: what each courage rung writes to the animal tuning natives.
    --   bravery         -> ATF_BraveryMin (6) / ATF_BraveryMax (5)
    --   spookedRange    -> ATF_SpookedRangeOverride (146)  — lower = calmer
    --   fearRange       -> ATF_FearRange (10)              — lower = calmer
    -- These are re-applied on EVERY spawn from the DB, so "persists for life"
    -- holds through despawn, restart and crash. FIRST PASS — the spike measures
    -- what these actually feel like and replaces these numbers.
    ladder = {
        [0] = { bravery = 0.0, spookedRange = 40.0, fearRange = 40.0 },
        [1] = { bravery = 0.1, spookedRange = 36.0, fearRange = 36.0 },
        [2] = { bravery = 0.2, spookedRange = 32.0, fearRange = 32.0 },
        [3] = { bravery = 0.3, spookedRange = 28.0, fearRange = 28.0 },
        [4] = { bravery = 0.4, spookedRange = 24.0, fearRange = 24.0 },
        [5] = { bravery = 0.5, spookedRange = 20.0, fearRange = 20.0 },
        [6] = { bravery = 0.6, spookedRange = 16.0, fearRange = 16.0 },
        [7] = { bravery = 0.7, spookedRange = 12.0, fearRange = 12.0 },
        [8] = { bravery = 0.85, spookedRange = 8.0, fearRange = 8.0 },
        [9] = { bravery = 1.0, spookedRange = 4.0, fearRange = 4.0, neverThrowsRider = true },
    },
}

--------------------------------------------------------------------------------
-- INTEGRATION HOOKS  (built now, switched on when the partner scripts arrive)
--------------------------------------------------------------------------------
Config.Integrations = {
    -- Sovereign Medical Suite: let a vet job treat injured/sick horses. [X4]
    vet     = { enabled = false },
    -- Sovereign Ranching: feed horses from ranch-produced hay/feed. [X5]
    ranching = { enabled = false },
    -- Horse registry / county papers surfaced on the Sovereign County site. [X3]
    registry = { enabled = true, surfaceOnSite = false },
}

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
Config.UI = {
    -- 'circular' or 'arrows' — how horse components are cycled in the customizer. [S15]
    componentControl = 'circular',
    showNameTags     = false,   -- floating names above horses [S17-baseline]
    orbitalCamera    = true,    -- auto-centering orbit on the previewed horse [L5]
}
