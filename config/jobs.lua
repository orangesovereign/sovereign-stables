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
    maxHorses          = 3,      -- [J1]
    maxWagons          = 1,      -- [J2]
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
    wagonRepair        = true,   -- wagon & wheel repairs [J14]
    horseHealing       = true,   -- [J15]
    hoofCleaning       = true,   -- horseshoe/hoof cleaning [J16]
    statsVisibility    = true,   -- see detailed horse statistics [J17]
    recall             = true,   -- horse & wagon recall [J18]
    customization      = true,   -- appearance/component customization [J19]
    painting           = true,   -- coat painting [J20]
    wagonCrafting      = false,  -- build wagons via crafting [J21]
    horseCreator       = false,  -- access the Horse Creator [J22] (see minGrade below)
}

-- Override per job. Only list the fields that differ from JobDefaults.
Config.Jobs = {

    ['horsetrainer'] = {
        maxHorses          = 8,
        xpModifier         = 1.25,
        accessOthersHorses = true,
        wagonCrafting      = true,
        horseCreator       = true,
        horseCreatorMinGrade = 2,   -- job+grade lock for the Horse Creator [J22/M2]
    },

    ['rancher'] = {
        maxHorses    = 6,
        maxWagons    = 3,
        maxBreedings = 3,
    },
}
