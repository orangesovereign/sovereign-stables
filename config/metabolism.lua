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
        warnBelow      = 35,    -- a Tick warning to the rider
        criticalBelow  = 15,    -- penalties bite (see `penalties`)
    },
    thirst = {
        max            = 100,
        start          = 100,
        drainPerMinute = 1.0,   -- thirst outpaces hunger, as in life
        warnBelow      = 35,
        criticalBelow  = 15,
    },

    ----------------------------------------------------------------------------
    -- PENALTIES when a core is CRITICAL. Multipliers on the horse's speed and
    -- stamina (1.0 = normal). A neglected horse is sluggish — never frozen; you
    -- can always limp it to water. Applied client-side while critical, lifted
    -- the moment you feed/water it.
    ----------------------------------------------------------------------------
    penalties = {
        speedMult   = 0.7,
        staminaMult = 0.6,
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
    },

    ----------------------------------------------------------------------------
    -- FEED / WATER / CLEAN ITEMS  [H3 · H5]. Map an inventory item name to what
    -- using it does. The item must exist in your vorp_inventory database; these
    -- names are placeholders — rename them to match your items.
    --   hunger/thirst — points restored (capped at max)
    --   dirt          — points of dirt removed (a brush)
    --   golden        — if true, this feed also counts toward golden condition
    ----------------------------------------------------------------------------
    items = {
        ['horse_feed']    = { label = 'Horse Feed',    hunger = 45 },
        ['horse_oats']    = { label = 'Oats',          hunger = 70, golden = true },
        ['horse_apple']   = { label = 'Apple',         hunger = 20, golden = true },
        ['horse_carrot']  = { label = 'Carrot',        hunger = 20, thirst = 10 },
        ['water_canteen'] = { label = 'Canteen',       thirst = 60 },
        ['horse_brush']   = { label = 'Grooming Brush', dirt = 100 },   -- a full brush-down
    },

    -- If true, feeding/cleaning requires the horse to be OUT and near you. If
    -- false, you can tend a stabled horse from the menu too.
    requireHorsePresent = true,
    interactDistance    = 4.0,
}
