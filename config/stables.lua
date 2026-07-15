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
                -- Where the groomed horse stands. X/Y/heading matter; Z ground-snaps
                -- to the floor (entities stream in near the player, so snap works). nil = no horse.
                horsePos = { -368.328, 786.878, 116.030, 167.8 },
                breeds   = nil,   -- nil = random from this stable's catalog; or a list like { 'A_C_Horse_Morgan_Bay' }
            },
        },

        -- INTERACTION prompt point + radius (on the stablehand)
        prompt = { coords = { -367.61, 787.17, 116.16 }, distance = 1.0 },

        -- PREVIEW positions used by the storefront/customizer. {x, y, z, heading}
        --   horsePos — where the previewed horse stands while you browse horses
        --              AND while you fit tack to your own horse in Components.
        --   wagonPos — where the previewed WAGON stands while you browse wagons.
        --              The horse preview is removed while you're looking at wagons.
        --
        -- Both need CLEAR GROUND of their own. These are showroom models, not the
        -- thing you drive away (that's `retrieve` below) — but they are still real
        -- entities that collide with real scenery and real NPCs.
        --
        -- There are no camera entries here: the storefront camera ORBITS whatever
        -- is on the stand, aiming at the position above, so moving a preview moves
        -- its camera automatically. (Dead `camHorse`/`camWagon` keys were removed
        -- 2026-07-15 — nothing ever read them, and they still held coords from an
        -- older layout, which is worse than having none.)
        preview = {
            horsePos = { -398.02, 773.43, 115.79, 86.77 },
            -- Moved 2026-07-15: the old spot (-370.11, 786.99) was inside the
            -- stable and the previewed wagon collided with the NPCs standing
            -- there. A wagon is a big entity and the yard is busy.
            wagonPos = { -394.64, 802.39, 115.80, 274.18 },
        },

        -- WHERE YOUR RIDE ACTUALLY ARRIVES when you collect it here.
        -- This is NOT the preview position — the preview is a showroom model
        -- standing where the camera can see it; this is the real vehicle you
        -- drive away. It MUST be outside, clear of the building and of the
        -- preview spots: a wagon brought out indoors collides with everything
        -- in the stable (1.4 ledger V1/V2).
        retrieve = {
            wagonPos = { -361.88, 805.78, 116.027, 0.0 },   -- x, y, z, heading
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
