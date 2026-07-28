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
    ['blackwater'] = {                                   -- unique id (letters/numbers, no spaces)
        label       = 'Blackwater Stables',              -- shown in prompts / NUI header

        -- BLIP (each stable's blip can be toggled independently) [L3]
        blip = {
            enabled = true,
            sprite  = 1938782895,
            coords  = { -871.761, -1366.035, 43.481 },
        },


        -- AMBIENT STABLEHAND [L2]. Toward the back of the stable, grooming a
        -- horse whose breed re-rolls each time a player opens this stable.
        ped = {
            enabled  = true,
            model    = 'u_m_m_bwmstablehand_01',
            coords   = { -874.128, -1367.980, 43.479, 173.0},   -- stablehand stands here (x,y,z,heading)
            scenario = 'WORLD_HUMAN_WAITING_IMPATIENT',        -- fallback only when grooming.enabled = false
            grooming = {
                enabled  = true,
                -- Where the groomed horse stands. X/Y/heading matter; Z ground-snaps
                -- to the floor (entities stream in near the player, so snap works). nil = no horse.
                horsePos = { -874.129, -1368.645, 43.479, 266.1 },
                breeds   = nil,   -- nil = random from this stable's catalog; or a list like { 'A_C_Horse_Morgan_Bay' }
            },
        },

        -- INTERACTION prompt point + radius (ON THE STABLEHAND — must match the
        -- `ped.coords` above, or there is no way to open this stable).
        prompt = { coords = { -874.128, -1367.980, 43.479 }, distance = 1.5 },

        -- PREVIEW positions used by the storefront/customizer. {x, y, z, heading}
        --   horsePos — where the previewed horse stands while you browse horses
        --              AND while you fit tack to your own horse in Components.
        --   wagonPos — where the previewed WAGON stands while you browse wagons.
        preview = {
            horsePos = { -862.902, -1366.345, 43.499, 270.300 },
            wagonPos = { -880.378, -1355.786, 43.289, 269.800 },
        },

        -- WHERE YOUR RIDE ACTUALLY ARRIVES when you collect it here.
        -- This is NOT the preview position — the preview is a showroom model
        -- standing where the camera can see it; this is the real vehicle you
        -- drive away. It MUST be outside, clear of the building and of the
        -- preview spots: a wagon brought out indoors collides with everything
        -- in the stable (1.4 ledger V1/V2).
        retrieve = {
            wagonPos = { -884.942, -1359.446, 43.383, 357.600 },   -- x, y, z, heading
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
            storedHorsesGetDirty = false,     -- [L6]
            breedingEnabled      = true,     -- [G]
            wildSalesEnabled     = false,    -- black-market counter here? [S10]
        },
    },

    ['saintdenis'] = {
        label       = 'Saint Denis Stables',
        -- ⚠️ COORDS ARE APPROXIMATE — verify each with /sovcoords in game.
        -- All six are derived from one anchor so they're internally consistent
        -- and near each other; nudge them onto the real building.
        blip = {
            enabled = true,
            sprite  = 1938782895,
            coords  = { 2493.000, -1360.000, 46.000 },
        },
        ped = {
            enabled  = true,
            model    = 'u_m_m_bwmstablehand_01',
            coords   = { 2490.500, -1362.000, 46.000, 180.0 },   -- /sovcoords ped
            scenario = 'WORLD_HUMAN_WAITING_IMPATIENT',
            grooming = {
                enabled  = true,
                horsePos = { 2490.500, -1362.700, 46.000, 270.0 },   -- /sovcoords horse
                breeds   = nil,
            },
        },
        -- ⚠️ PUT THIS ON THE STABLEHAND. If it doesn't match ped.coords there is
        -- no way to open this stable — the ped and horse will still spawn, which
        -- is what makes the mistake so quiet.
        prompt = { coords = { 2490.500, -1362.000, 46.000 }, distance = 1.5 },
        preview = {
            horsePos = { 2502.000, -1359.000, 46.000, 270.0 },   -- /sovcoords horse
            wagonPos = { 2485.000, -1349.000, 46.000, 270.0 },   -- /sovcoords wagon
        },
        -- OUTSIDE and clear — this is the wagon you actually drive away.
        retrieve = {
            wagonPos = { 2479.000, -1353.000, 46.000, 0.0 },     -- /sovcoords wagon
        },
        jobs = { restricted = false, allowed = {} },
        faction = { enabled = false, job = nil },
        catalog = { horses = {}, wagons = {} },
        options = {
            storedHorsesGetDirty = true,
            breedingEnabled      = true,
            wildSalesEnabled     = false,
        },
    },
    ['rhodes'] = {
        label       = 'Rhodes Stables',
        -- ⚠️ COORDS ARE APPROXIMATE — verify each with /sovcoords in game.
        -- All six are derived from one anchor so they're internally consistent
        -- and near each other; nudge them onto the real building.
        blip = {
            enabled = true,
            sprite  = 1938782895,
            coords  = { 1237.000, -1276.000, 76.000 },
        },
        ped = {
            enabled  = true,
            model    = 'u_m_m_bwmstablehand_01',
            coords   = { 1234.500, -1278.000, 76.000, 180.0 },   -- /sovcoords ped
            scenario = 'WORLD_HUMAN_WAITING_IMPATIENT',
            grooming = {
                enabled  = true,
                horsePos = { 1234.500, -1278.700, 76.000, 270.0 },   -- /sovcoords horse
                breeds   = nil,
            },
        },
        -- ⚠️ PUT THIS ON THE STABLEHAND. If it doesn't match ped.coords there is
        -- no way to open this stable — the ped and horse will still spawn, which
        -- is what makes the mistake so quiet.
        prompt = { coords = { 1234.500, -1278.000, 76.000 }, distance = 1.5 },
        preview = {
            horsePos = { 1246.000, -1275.000, 76.000, 270.0 },   -- /sovcoords horse
            wagonPos = { 1229.000, -1265.000, 76.000, 270.0 },   -- /sovcoords wagon
        },
        -- OUTSIDE and clear — this is the wagon you actually drive away.
        retrieve = {
            wagonPos = { 1223.000, -1269.000, 76.000, 0.0 },     -- /sovcoords wagon
        },
        jobs = { restricted = false, allowed = {} },
        faction = { enabled = false, job = nil },
        catalog = { horses = {}, wagons = {} },
        options = {
            storedHorsesGetDirty = true,
            breedingEnabled      = true,
            wildSalesEnabled     = false,
        },
    },
    ['strawberry'] = {
        label       = 'Strawberry Stables',
        -- ✅ REAL COORDS — captured in game by the owner 2026-07-28.
        blip = {
            enabled = true,
            sprite  = 1938782895,
            -- No separate blip point was captured; the marker sits on the
            -- stablehand, which is the stable's door. Nudge if you want it moved.
            coords  = { -1819.66, -562.01, 156.01 },
        },
        ped = {
            enabled  = true,
            model    = 'u_m_m_bwmstablehand_01',
            coords   = { -1819.66, -562.01, 156.01, 72.41 },   -- Ped Coord
            scenario = 'WORLD_HUMAN_WAITING_IMPATIENT',
            grooming = {
                enabled  = true,
                horsePos = { -1820.29, -561.8, 156.01, 164.05 },   -- Ped Horse Coord
                breeds   = nil,
            },
        },
        -- On the stablehand — matches ped.coords, so the prompt opens the stable.
        prompt = { coords = { -1819.66, -562.01, 156.01 }, distance = 1.5 },
        preview = {
            horsePos = { -1794.0, -573.89, 155.92, 286.52 },   -- Preview Horse Coord
            wagonPos = { -1828.02, -589.29, 155.27, 253.46 },   -- Preview Wagon Coord
        },
        -- OUTSIDE and clear — this is the wagon you actually drive away.
        retrieve = {
            wagonPos = { -1818.17, -588.14, 155.71, 339.52 },     -- Wagon Spawn Coord
        },
        jobs = { restricted = false, allowed = {} },
        faction = { enabled = false, job = nil },
        catalog = { horses = {}, wagons = {} },
        options = {
            storedHorsesGetDirty = true,
            breedingEnabled      = true,
            wildSalesEnabled     = false,
        },
    },
    ['tumbleweed'] = {
        label       = 'Tumbleweed Stables',
        -- ⚠️ COORDS ARE APPROXIMATE — verify each with /sovcoords in game.
        -- All six are derived from one anchor so they're internally consistent
        -- and near each other; nudge them onto the real building.
        blip = {
            enabled = true,
            sprite  = 1938782895,
            coords  = { -5514.000, -3040.000, -2.000 },
        },
        ped = {
            enabled  = true,
            model    = 'u_m_m_bwmstablehand_01',
            coords   = { -5516.500, -3042.000, -2.000, 180.0 },   -- /sovcoords ped
            scenario = 'WORLD_HUMAN_WAITING_IMPATIENT',
            grooming = {
                enabled  = true,
                horsePos = { -5516.500, -3042.700, -2.000, 270.0 },   -- /sovcoords horse
                breeds   = nil,
            },
        },
        -- ⚠️ PUT THIS ON THE STABLEHAND. If it doesn't match ped.coords there is
        -- no way to open this stable — the ped and horse will still spawn, which
        -- is what makes the mistake so quiet.
        prompt = { coords = { -5516.500, -3042.000, -2.000 }, distance = 1.5 },
        preview = {
            horsePos = { -5505.000, -3039.000, -2.000, 270.0 },   -- /sovcoords horse
            wagonPos = { -5522.000, -3029.000, -2.000, 270.0 },   -- /sovcoords wagon
        },
        -- OUTSIDE and clear — this is the wagon you actually drive away.
        retrieve = {
            wagonPos = { -5528.000, -3033.000, -2.000, 0.0 },     -- /sovcoords wagon
        },
        jobs = { restricted = false, allowed = {} },
        faction = { enabled = false, job = nil },
        catalog = { horses = {}, wagons = {} },
        options = {
            storedHorsesGetDirty = true,
            breedingEnabled      = true,
            wildSalesEnabled     = false,
        },
    },
    ['vanhorn'] = {
        label       = 'Van Horn Stables',
        -- ⚠️ COORDS ARE APPROXIMATE — verify each with /sovcoords in game.
        -- All six are derived from one anchor so they're internally consistent
        -- and near each other; nudge them onto the real building.
        blip = {
            enabled = true,
            sprite  = 1938782895,
            coords  = { 2955.000, 570.000, 44.000 },
        },
        ped = {
            enabled  = true,
            model    = 'u_m_m_bwmstablehand_01',
            coords   = { 2952.500, 568.000, 44.000, 180.0 },   -- /sovcoords ped
            scenario = 'WORLD_HUMAN_WAITING_IMPATIENT',
            grooming = {
                enabled  = true,
                horsePos = { 2952.500, 567.300, 44.000, 270.0 },   -- /sovcoords horse
                breeds   = nil,
            },
        },
        -- ⚠️ PUT THIS ON THE STABLEHAND. If it doesn't match ped.coords there is
        -- no way to open this stable — the ped and horse will still spawn, which
        -- is what makes the mistake so quiet.
        prompt = { coords = { 2952.500, 568.000, 44.000 }, distance = 1.5 },
        preview = {
            horsePos = { 2964.000, 571.000, 44.000, 270.0 },   -- /sovcoords horse
            wagonPos = { 2947.000, 581.000, 44.000, 270.0 },   -- /sovcoords wagon
        },
        -- OUTSIDE and clear — this is the wagon you actually drive away.
        retrieve = {
            wagonPos = { 2941.000, 577.000, 44.000, 0.0 },     -- /sovcoords wagon
        },
        jobs = { restricted = false, allowed = {} },
        faction = { enabled = false, job = nil },
        catalog = { horses = {}, wagons = {} },
        options = {
            storedHorsesGetDirty = true,
            breedingEnabled      = true,
            wildSalesEnabled     = false,
        },
    },
    ['annesburg'] = {
        label       = 'Annesburg Stables',
        -- ⚠️ COORDS ARE APPROXIMATE — verify each with /sovcoords in game.
        -- All six are derived from one anchor so they're internally consistent
        -- and near each other; nudge them onto the real building.
        blip = {
            enabled = true,
            sprite  = 1938782895,
            coords  = { 2930.000, 1279.000, 45.000 },
        },
        ped = {
            enabled  = true,
            model    = 'u_m_m_bwmstablehand_01',
            coords   = { 2927.500, 1277.000, 45.000, 180.0 },   -- /sovcoords ped
            scenario = 'WORLD_HUMAN_WAITING_IMPATIENT',
            grooming = {
                enabled  = true,
                horsePos = { 2927.500, 1276.300, 45.000, 270.0 },   -- /sovcoords horse
                breeds   = nil,
            },
        },
        -- ⚠️ PUT THIS ON THE STABLEHAND. If it doesn't match ped.coords there is
        -- no way to open this stable — the ped and horse will still spawn, which
        -- is what makes the mistake so quiet.
        prompt = { coords = { 2927.500, 1277.000, 45.000 }, distance = 1.5 },
        preview = {
            horsePos = { 2939.000, 1280.000, 45.000, 270.0 },   -- /sovcoords horse
            wagonPos = { 2922.000, 1290.000, 45.000, 270.0 },   -- /sovcoords wagon
        },
        -- OUTSIDE and clear — this is the wagon you actually drive away.
        retrieve = {
            wagonPos = { 2916.000, 1286.000, 45.000, 0.0 },     -- /sovcoords wagon
        },
        jobs = { restricted = false, allowed = {} },
        faction = { enabled = false, job = nil },
        catalog = { horses = {}, wagons = {} },
        options = {
            storedHorsesGetDirty = true,
            breedingEnabled      = true,
            wildSalesEnabled     = false,
        },
    },
    --==========================================================================
    -- ADDING A STABLE — copy a block above, then change ALL SIX POSITIONS
    --==========================================================================
    -- ⚠️ The trap: a stable block holds six separate sets of coordinates. Miss
    -- one and it silently keeps pointing at the stable you copied from, which
    -- may be a thousand metres away. Nothing errors — the pieces you DID change
    -- work fine, and the one you missed just never fires. (This bit Blackwater:
    -- everything spawned, but `prompt.coords` still held Valentine's, so there
    -- was no way to open the stable.)
    --
    -- `/stables_diag` now catches this: any position more than 300m from its own
    -- stable is reported by name. RUN IT AFTER ADDING A STABLE.
    --
    -- The six, and what each one is:
    --   1. blip.coords            the map marker
    --   2. ped.coords             where the stablehand stands  (x,y,z,HEADING)
    --   3. ped.grooming.horsePos  the horse he's brushing      (x,y,z,HEADING)
    --   4. prompt.coords          ⚠️ where you press G — PUT THIS ON THE PED
    --   5. preview.horsePos       the showroom horse           (x,y,z,HEADING)
    --      preview.wagonPos       the showroom wagon           (x,y,z,HEADING)
    --   6. retrieve.wagonPos      where YOUR wagon arrives — OUTSIDE, clear
    --                             of the building and of the preview spots
    --
    -- Rules of thumb learned the hard way:
    --   • preview and retrieve spots need CLEAR GROUND. They are real entities
    --     and will collide with scenery and NPCs (1.4 V1/V2).
    --   • a wagon is big — give it more room than a horse.
    --   • no camera entries needed: the camera orbits whatever is on the stand.
    --
    -- ['rhodes'] = { label = 'Rhodes Stables', ... },
}
