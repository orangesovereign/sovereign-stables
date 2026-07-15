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
    -- Each move must be worked this many times during training before the horse
    -- learns the matching ability. Nothing is announced — the owner finds out the
    -- first time they ask for it and get nothing. Mirror all night and you get a
    -- level-4 horse that follows beautifully and can't rear, dance or jump.
    repertoire = {
        enabled = true,
        repsToLearn = {
            mirroring   = 20,   -- responsiveness: follows, comes quicker, listens
            dance       = 15,   -- dance under saddle (hold SPACE)
            jump        = 15,   -- clears ground obstacles cleanly
            rear        = 15,   -- rears on command
            footScratch = 15,   -- ability TBD
            longeing    = 20,   -- ability TBD (gait control / works at distance?)
        },
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
