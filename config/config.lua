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
