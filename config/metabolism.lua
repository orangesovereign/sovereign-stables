--[[=====================================================================
  SOVEREIGN STABLES · METABOLISM & CARE  [C-series · milestone 2.1]
  ---------------------------------------------------------------------
  Hunger, thirst, cleanliness and "golden" condition for a horse. If you are
  not a programmer: change the numbers after '=', keep the quotes and commas,
  and run /stables_diag in game after a restart to check for mistakes.

  HOW IT WORKS (so the numbers make sense):
    • Each horse carries hunger, thirst and dirt values. They DRIFT over time —
      hunger and thirst fall, dirt rises — and you restore them by feeding,
      watering, and cleaning.
    • Time is measured on the WALL CLOCK, but only counts WHILE THE HORSE IS OUT
      with you (see `drainWhile`). A horse resting in the stable is looked after
      by the stablehand — it does not starve in its stall.
    • Nothing is polled every second. A horse's values are recomputed from the
      elapsed time whenever it is brought out or fed — cheap, and exact.
=====================================================================]]--

Config = Config or {}

Config.Metabolism = {
    enabled = true,

    ----------------------------------------------------------------------------
    -- WHEN does a horse get hungry?
    --   'active'  — only while it's OUT with you. Stored horses are cared for.
    --               The gentle default: care is a cost of USING a horse.
    --   'always'  — on wall time, even in the stable. Harsher; a real chore.
    ----------------------------------------------------------------------------
    drainWhile = 'active',

    ----------------------------------------------------------------------------
    -- SHARED vs INDIVIDUAL status  [H4]
    --   false — every horse is fed, watered and cleaned on its own. Realistic.
    --   true  — one shared pool: feed any horse, they're all fed. Forgiving.
    ----------------------------------------------------------------------------
    sharedStatus = false,

    ----------------------------------------------------------------------------
    -- HUNGER & THIRST  [H1]. Values run 0 (empty) to 100 (full). A fresh or
    -- rested horse starts full. `drainPerMinute` is how many points are lost
    -- for each real minute the horse is out.
    ----------------------------------------------------------------------------
    hunger = {
        max            = 100,
        start          = 100,
        drainPerMinute = 0.7,   -- ~2.4 hours from full to empty while out
        warnBelow      = 1,    -- a Tick warning to the rider
        criticalBelow  = 5,    -- penalties bite (see `penalties`)
    },
    thirst = {
        max            = 100,
        start          = 100,
        drainPerMinute = 1.0,   -- thirst outpaces hunger, as in life
        warnBelow      = 1,
        criticalBelow  = 5,
    },

    ----------------------------------------------------------------------------
    -- PENALTIES when a core is CRITICAL. Multipliers on the horse's speed and
    -- stamina (1.0 = normal). A neglected horse is sluggish — never frozen; you
    -- can always limp it to water. Applied client-side while critical, lifted
    -- the moment you feed/water it.
    ----------------------------------------------------------------------------
    penalties = {
        speedMult   = 0.8,
        staminaMult = 0.7,
        -- Below this combined (hunger+thirst)/2, the horse may stumble/refuse —
        -- wired in Phase 3 with the tuning surface; noted so the number exists.
        collapseBelow = 3,
    },

    ----------------------------------------------------------------------------
    -- GOLDEN CONDITION  [C]. RDR2's horses have a second, "golden" tier of cores
    -- that only fills when the animal is thriving. Here: keep BOTH hunger and
    -- thirst above `goldenAbove` for `goldenAfterMinutes` and the horse turns
    -- golden — it drains slower and (Phase 3) bonds faster. Let it slip and the
    -- glow fades. A reward for good husbandry, not a grind.
    ----------------------------------------------------------------------------
    golden = {
        enabled           = true,
        goldenAbove       = 80,
        goldenAfterMinutes = 20,
        drainMultiplier   = 0.5,   -- golden horses get hungry/thirsty half as fast
    },

    ----------------------------------------------------------------------------
    -- CLEANLINESS  [H5 · H10 · L9 · L6]. Dirt runs 0 (spotless) to 100 (filthy).
    -- RDR2 tracks two visible tiers; we map our 0-100 onto the game's dirt level.
    -- The natives are confirmed (PHASE1_SPIKE_FINDINGS): SET_PED_DIRT_LEVEL +
    -- the clear-pass. No spike.
    ----------------------------------------------------------------------------
    cleanliness = {
        enabled          = true,
        start            = 0,
        gainPerMinute    = 1.5,   -- gets dirtier while OUT and ridden [L6]
        max              = 100,

        -- [H10] A dirty horse LEFT AT THE STABLE is groomed clean by the
        -- stablehand over this many real minutes. This is why L6 ("gets dirty")
        -- and H10 ("auto-cleans") don't conflict: it dirties while OUT, and the
        -- stable cleans it while STORED.
        stableAutoCleanMinutes = 30,

        -- [L9] The storefront/preview horse is ALWAYS shown spotless, whatever
        -- the real horse's state. A showroom model is clean.
        previewAlwaysClean = true,

        -- WHEN DIRT STARTS TO SHOW  (owner ruling 2026-07-26)
        --   "I don't think dirty should begin to show until a certain threshold.
        --    As a player if I brush my horse and then ride out of Valentine and
        --    see dirt I would lose it."
        --
        -- A grace band. Below this the coat renders perfectly clean; above it the
        -- rest of the range is stretched across the full visible span, so you
        -- still get everything from a light dusting to filthy.
        --
        -- The stored number keeps climbing either way — this changes when dirt
        -- SHOWS, not when it counts. Raise it if horses still look grubby too
        -- soon after a brush; drop it toward 0 for a grimier, harder world.
        visibleAbove = 25,

        ------------------------------------------------------------------------
        -- WHAT DIRTIES A HORSE, AND WHAT WASHES IT (owner ruling 2026-07-25)
        ------------------------------------------------------------------------
        -- ❌ I had this backwards. The first version treated water and rain as
        -- dirt SOURCES ("wet ground is mud"). The owner corrected it, and they're
        -- plainly right: water WASHES a horse. Rain washes it clean.
        --
        -- So the model is now the sensible one:
        --   HARD RIDING dirties      — hooves kick up ground
        --   WATER cleans, a little   — fording a river rinses the worst off
        --   RAIN cleans completely   — and leaves the coat gleaming
        --
        -- ⚠️ Still honest about the limit: RDR3 gives us no "am I standing in
        -- mud" native — no ground-material or dirt-level READ, only the write.
        -- So "dirty" is inferred from hard riding rather than from real terrain.
        dirtying = {
            enabled     = true,
            galloping   = 2.0,     -- hard riding kicks up the ground (x gainPerMinute)
            gallopSpeed = 9.0,     -- m/s that counts as a gallop
        },

        -- WATER: riding through a river or shallows rinses SOME dirt off. It is
        -- not a bath — it takes the edge off, and won't get a filthy horse clean.
        water = {
            enabled        = true,
            cleanPerMinute = 25.0,   -- dirt removed per minute spent in water
            floor          = 20.0,   -- water alone can't get it below this
        },

        -- RAIN: a proper wash. Standing out in it cleans the horse to spotless
        -- and leaves the coat SHINY [M3] — the shine is the reward for it, and
        -- fades as the horse dirties again.
        rain = {
            enabled        = true,
            cleanPerMinute = 60.0,   -- rain scrubs fast — a few minutes and it's clean
            shine          = true,   -- gleaming coat once rain gets it to spotless
            shineFadesAt   = 10.0,   -- dirt above this and the shine is gone
        },
    },

    ----------------------------------------------------------------------------
    -- DRINKING  [H2] (owner ruling 2026-07-25)
    --   "To fill the horses thirst they should be able to drink out of horse
    --    troughs and be able to drink from bodies of water."
    --
    -- A horse standing at water drinks by itself — no item, no prompt. Leave it
    -- at a river or a trough for a moment and its thirst fills. This is why
    -- water items are a convenience rather than a necessity: the world is full
    -- of water, and a rider who plans around it never needs to carry any.
    ----------------------------------------------------------------------------
    drinking = {
        enabled         = true,
        thirstPerMinute = 40.0,   -- a good long drink fills it in well under a minute
        -- The horse must be standing still to drink — you can't gulp at a gallop.
        maxSpeed        = 1.5,    -- m/s

        -- TROUGHS. Any of these props within `troughDistance` counts as water.
        -- Add your own trough props here if your map has custom ones.
        troughDistance  = 3.5,
        troughProps = {
            'p_trough02x', 'p_trough03x', 'p_troughwater01x',
            'p_waterpump01x', 'p_trough01x',
        },
    },

    ----------------------------------------------------------------------------
    -- FEED / WATER / CLEAN ITEMS  [H3 · H5]. Map an inventory item name to what
    -- using it does. The item must exist in your vorp_inventory database.
    --   hunger/thirst — points restored (capped at max)
    --   dirt          — points of dirt removed (a brush) [H5]
    --   golden        — if true, this feed also counts toward golden condition
    --   uses          — DURABILITY. A tool with `uses` isn't consumed each time;
    --                   it loses one use and only breaks at zero (stored in the
    --                   item's own metadata, so each brush tracks its own count).
    --                   Omit for one-shot consumables like feed.
    --   horsebackOnly — the item can only be used while MOUNTED.
    -- Animation is chosen automatically: dirt items play the brushing anim, food
    -- items the feeding anim (both work mounted or on foot unless horsebackOnly).
    ----------------------------------------------------------------------------
    items = {
        ['horsemeal']    = { label = 'Horse Meal',    hunger = 45 },
        ['horse_oats']   = { label = 'Oats',          hunger = 70, golden = false },
        ['apple']        = { label = 'Apple',         hunger = 20, golden = false },
        ['wild_carrot']  = { label = 'Wild Carrot',   hunger = 20, thirst = 10 },

        -- ⚠️ THIRST HAS ALMOST NOTHING TO RESTORE IT — add your water item here.
        -- Thirst drains FASTER than hunger (1.0/min vs 0.7), but the only thing
        -- above that touches it is the carrot, at 10 points. So a horse's thirst
        -- is effectively unrecoverable, which is why the retest couldn't do it.
        -- Uncomment/rename these to water items that exist in YOUR inventory:
        -- ['water_canteen'] = { label = 'Canteen',      thirst = 60 },
        -- ['water_bucket']  = { label = 'Water Bucket', thirst = 100, uses = 10 },
        -- (/stables_diag warns at boot if a core has no item that restores it.)

        -- The grooming brush: the ONLY thing that cleans a horse [H5]. A TOOL —
        -- 20 uses before it wears out.
        -- Usable BOTH from the saddle and stood beside the horse (owner ruling
        -- 2026-07-25) — the game's interaction system picks the right animation
        -- for wherever you are. Set `horsebackOnly = true` to require the saddle.
        ['horsebrush']   = { label = 'Grooming Brush', dirt = 100, uses = 20 },
    },

    -- Default durability if an item has `uses = true` but no number.
    defaultUses = 20,

    -- Play the brushing/feeding animations. We hand the job to the GAME'S own
    -- interaction system, which picks the right variant for where you are —
    -- mounted, or stood at the horse's left or right. Set false to skip the
    -- animation entirely; the care effect still applies either way.
    careAnimations = true,

    -- If true, feeding/cleaning requires the horse to be OUT and near you.
    requireHorsePresent = true,
    interactDistance    = 4.0,
}
