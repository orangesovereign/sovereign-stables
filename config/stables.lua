--[[=====================================================================
  SOVEREIGN STABLES · STABLE LOCATIONS
  ---------------------------------------------------------------------
  Each entry is one stable in the world. Every stable is fully independent:
  its own catalog, prices, cameras, job restrictions and toggles.

  Coordinates are {x, y, z} and headings are degrees. To capture a position
  in game, stand where you want it and use your admin coords tool.

  Camera format: {x, y, z, rotX, rotY, rotZ, fov}
=====================================================================]]--

Config = Config or {}

Config.Stables = {

    ['valentine'] = {                                   -- unique id (letters/numbers, no spaces)
        label       = 'Valentine Stables',              -- shown in prompts / NUI header

        -- BLIP (each stable's blip can be toggled independently) [L3]
        blip = {
            enabled = true,
            sprite  = 1938782895,
            coords  = { -366.69, 787.06, 116.16 },
        },

        -- AMBIENT STABLEHAND [L2]. Toward the back of the stable, grooming a
        -- horse whose breed re-rolls each time a player opens this stable.
        ped = {
            enabled  = true,
            model    = 'u_m_m_bwmstablehand_01',
            coords   = { -367.61, 787.17, 116.16, 92.52 },   -- stablehand stands here (x,y,z,heading)
            scenario = 'WORLD_HUMAN_WAITING_IMPATIENT',        -- fallback only when grooming.enabled = false
            grooming = {
                enabled  = true,
                horsePos = nil,   -- nil = auto-place the horse just in front of the ped; set {x,y,z,h} to override
                breeds   = nil,   -- nil = random from this stable's catalog; or a list like { 'A_C_Horse_Morgan_Bay' }
            },
        },

        -- INTERACTION prompt point + radius (on the stablehand)
        prompt = { coords = { -367.61, 787.17, 116.16 }, distance = 1.0 },

        -- PREVIEW positions & cameras used by the storefront/customizer
        preview = {
            horsePos = { -398.02, 773.43, 115.79, 86.77 },
            wagonPos = { -370.11, 786.99, 115.16, 274.18 },
            camHorse = { -367.92, 783.02, 117.77, -36.42, 0.0, -100.98, 50.0 },
            camWagon = { -363.58, 792.11, 118.04, -16.35, 0.0, 143.97, 50.0 },
        },

        -- ACCESS RULES
        jobs = {
            restricted = false,         -- true = only listed jobs may use this stable [S3]
            allowed    = {},            -- e.g. { 'horsetrainer', 'rancher' }
        },
        faction = { enabled = false, job = nil },  -- same-job players share a horse pool [S16]

        -- CATALOG. Empty = sells everything defined in config/horses.lua / config/wagons.lua.
        -- Otherwise list model ids to limit this vendor. Price overrides are optional:
        --   horses = { 'A_C_Horse_Morgan_Bay', ['A_C_Horse_Turkoman_Gold'] = { cash = 350, gold = 5 } }
        -- Any model NOT priced here falls back to its price in config/horses.lua.
        catalog = {
            horses = {},   -- {} = all buyable horses from config/horses.lua
            wagons = {},   -- {} = all buyable wagons from config/wagons.lua
        },

        -- PER-STABLE TOGGLES (override globals just for this location)
        options = {
            storedHorsesGetDirty = true,     -- [L6]
            breedingEnabled      = true,     -- [G]
            wildSalesEnabled     = false,    -- black-market counter here? [S10]
        },
    },

    -- Duplicate the block above to add more stables. Keep each id unique.
    -- ['rhodes'] = { label = 'Rhodes Stables', ... },
}
