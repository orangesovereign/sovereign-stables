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
    --
    -- ⚠️ SWITCHED OFF (owner ruling 2026-07-27): "Do not want it to show golden
    -- state. Actually remove Golden state altogether or just turn it off."
    -- Off rather than deleted, because the mechanic is sound and costs nothing
    -- while dormant — flip `enabled` back to true and it returns intact, cores,
    -- drain bonus and all. With it off, no horse ever becomes golden, so the
    -- slower drain never applies and nothing displays it.
    golden = {
        enabled           = false,
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
        max              = 100,

        -- ⚠️ WE OWN THE DIRT NUMBER AND PAINT IT (reworked 2026-07-28).
        -- R11 settled the confusion: _SET_PED_DIRT_CLEANED WRITES the coat to any
        -- level (the owner watched /sovdirtset 100 go filthy, 0 go clean), while
        -- _GET_PED_DIRT_LEVEL reads a different layer and can't see it. So reading
        -- the engine was a dead end — we simulate a number and write it. That's
        -- what puts these knobs back in charge of the RATE and the mud bonus.
        -- The client clears the engine's own grime each tick and writes THIS
        -- number, so the coat shows exactly what's configured here.

        -- HOW FAST A HORSE GETS DIRTY while out and ridden (owner 2026-07-28:
        -- "10-15% faster"). At 7.0 a ridden horse is filthy in ~14 min; a gallop
        -- and mud push it faster still. Raise for a grubbier county.
        gainPerMinute    = 7.0,

        -- HARD RIDING kicks up more ground — a gallop dirties faster.
        gallopSpeed      = 9.0,    -- m/s that counts as a gallop
        gallopMultiplier = 1.5,    -- x gainPerMinute at a gallop

        -- MUD (owner: "going through mud should accumulate 25% faster"). RDR3 has
        -- NO native to read the ground material (confirmed), so real mud terrain
        -- can't be detected. The closest honest signal is wet ground — while it's
        -- raining, the ground is muddy — so the bonus applies then. Set
        -- mudWhenWet = false to switch it off until a mud signal exists.
        mudWhenWet       = true,
        mudMultiplier    = 1.25,   -- x rate on wet/muddy ground

        -- WATER cleans a little (fording a river rinses the worst off, not a bath).
        waterCleanPerMinute = 25.0,
        waterFloor          = 15.0,   -- water alone can't get it below this

        -- RAIN washes it down properly.
        rainCleanPerMinute  = 40.0,

        -- [H10] A dirty horse LEFT AT THE STABLE is groomed clean by the
        -- stablehand over this many real minutes (dirties while OUT, cleaned while
        -- STORED — that's why "gets dirty" and "auto-cleans" don't conflict).
        stableAutoCleanMinutes = 30,

        -- [L9] The storefront/preview horse is ALWAYS shown spotless.
        previewAlwaysClean = true,
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
        -- Watering is a CHOICE from the lock-on menu, not automatic (2026-07-27).
        -- One press = one proper drink of this many thirst points, then a short
        -- cooldown so it can't be mashed. A horse already full gets a "not
        -- thirsty" chip instead. (thirstPerMinute is retired with the old trickle.)
        drinkFill           = 100,  -- points restored per drink (capped at max)
        drinkCooldownSeconds = 8,   -- wait between full drinks
        -- The horse must be standing still to drink — you can't gulp at a gallop.
        maxSpeed        = 1.5,    -- m/s

        -- TROUGHS. Any of these props within `troughDistance` counts as water.
        -- Add your own trough props here if your map has custom ones.
        troughDistance  = 3.5,

        -- ⚠️ THE LIST BELOW IS THE OWNER'S, NOT MINE (2026-07-27, R5 M6/G3).
        -- My first pass was five prop names I'd assumed; Blackwater's trough
        -- wasn't among them, so a horse stood at it simply never drank and
        -- automatic drinking read as broken. Rivers worked the whole time,
        -- which is what made it look like a drinking bug rather than a list bug.
        -- If you add a stable whose trough isn't here, add its prop name.
        troughProps = {
            'p_feedtrough01x', 'p_feedtroughsml01x',
            'p_watertrough01x', 'p_watertrough01x_new',
            'p_watertrough02x', 'p_watertrough03x', 'p_watertroughsml01x',
            'p_troughtable01x', 'p_trough01_h',
            -- kept from the first pass, harmless if a map doesn't use them
            'p_trough01x', 'p_trough02x', 'p_trough03x',
            'p_troughwater01x', 'p_waterpump01x',
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
