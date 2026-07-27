--[[=====================================================================
  SOVEREIGN STABLES · METABOLISM & CARE  (client)  [C-series]
  ---------------------------------------------------------------------
  Shows the horse's care state and applies its consequences. The server owns
  the numbers; this file paints dirt on the ped, slows a starving horse, warns
  the rider, and tells the server which horse is out so a used feed item knows
  its target.

  Dirt native (confirmed, PHASE1_SPIKE_FINDINGS): SET_PED_DIRT_LEVEL + the
  clear-pass. The horse's 0-100 dirt maps onto the game's 0.0-1.0 level.
=====================================================================]]--

Metabolism = Metabolism or {}

local function mcfg() return Config.Metabolism or {} end
local current = nil   -- the active horse's live card { hunger, thirst, dirt, golden, ... }

--------------------------------------------------------------------------------
-- Dirt on the ped
--------------------------------------------------------------------------------
-- Our 0-100 dirt -> the game's 0.0-1.0 level, WITH A GRACE THRESHOLD.
--
-- Owner, 2026-07-26: "I don't think dirty should begin to show until a certain
-- threshold. As a player if I brush my horse and then ride out of Valentine and
-- see dirt I would lose it."
--
-- Dead right. A freshly brushed horse should LOOK freshly brushed for a good
-- while. So `visibleAbove` is a grace band: below it the coat renders perfectly
-- clean, and above it the remaining range is rescaled across the full 0-1 so you
-- still get the whole span of filth. The stored number keeps ticking up either
-- way — this is about when it starts to SHOW, not when it starts to count.
local function dirtToLevel(dirt0to100)
    local c = (mcfg().cleanliness or {})
    local maxD  = c.max or 100
    local grace = c.visibleAbove or 0
    local d = math.max(0, math.min(maxD, tonumber(dirt0to100) or 0))
    if d <= grace then return 0.0 end
    return math.max(0.0, math.min(1.0, (d - grace) / math.max(1, maxD - grace)))
end

function Metabolism.applyDirt(ped, dirt0to100)
    if not (ped and DoesEntityExist(ped)) then return end
    Citizen.InvokeNative(0x7A56D66C78D1AAB7, ped, dirtToLevel(dirt0to100) + 0.0)  -- SET_PED_DIRT_LEVEL
end

-- Scrub a ped spotless — the full clear-pass. Used for the storefront preview
-- [L9] and after a grooming brush.
--
-- ⚠️ A ONE-SHOT CLEAR DOESN'T STICK. RDR3 re-applies environmental grime over the
-- next few frames after a horse renders, so a single call cleans it and then it
-- dirties right back up — which is exactly why the preview still showed dirt
-- (2.1 ledger S2). coal_stables hit the same thing and solved it by re-running
-- the clear a handful of times over ~800ms. We do the same.
local function clearPass(ped)
    Citizen.InvokeNative(0x7A56D66C78D1AAB7, ped, 0.0)   -- SET_PED_DIRT_LEVEL 0
    Citizen.InvokeNative(0x6585D955A68452A5, ped)         -- CLEAR_PED_ENV_DIRT
    Citizen.InvokeNative(0x9C720776DAA43E7E, ped)         -- CLEAR_PED_DAMAGE_DECAL
    Citizen.InvokeNative(0xB63B9178D0F58D82, ped)         -- _CLEAR_PED_TEXTURE
    if ClearPedWetness then ClearPedWetness(ped) end
end

function Metabolism.forceClean(ped)
    if not (ped and DoesEntityExist(ped)) then return end
    clearPass(ped)
    CreateThread(function()
        for _ = 1, 8 do
            Wait(100)
            if not (ped and DoesEntityExist(ped)) then return end
            clearPass(ped)
        end
    end)
end

-- Immediate clean-and-set, for the instant a value changes.
function Metabolism.setDirt(ped, dirt0to100)
    if not (ped and DoesEntityExist(ped)) then return end
    local lvl = dirtToLevel(dirt0to100)
    clearPass(ped)                                              -- wipe env dirt + decals
    Citizen.InvokeNative(0x7A56D66C78D1AAB7, ped, lvl + 0.0)
end

--------------------------------------------------------------------------------
-- ⚠️ THE DIRT GUARD — why brushing failed THREE rounds running.
--------------------------------------------------------------------------------
-- R1/R2 failed again in the 2.1 R3 ledger: "Does nothing to the horse after the
-- brushing animation. Still dirty." Both on foot and mounted.
--
-- Everything upstream was correct and I kept re-checking it: the item is taken,
-- the server sets dirt to 0, the card comes back clean, the client calls the
-- clearing setter. The bug was never in the LOGIC — it was in HOW LONG we held
-- the result. Each fix re-asserted the value for a fixed burst (~800ms), and the
-- brushing animation runs for SEVERAL SECONDS. The engine repaints environmental
-- grime after our burst has already finished, so the horse is genuinely clean
-- for a moment you never see, then dirty again by the time the animation ends.
--
-- Chasing that with a longer burst is the same bug with a bigger number. The
-- real problem is that a one-shot write is a GUESS about when the engine will
-- next disagree with us. So: stop guessing, and hold the value continuously.
--
-- ❌ AND THAT INVARIANT WAS WRONG. (Corrected 2026-07-27 after R5.)
--
-- The first version of this guard held the coat at EXACTLY our number every
-- 500ms, in both directions — asserting dirt as confidently as it asserted
-- clean. Owner, R5: "It seems you've removed or disabled the visible dirty
-- entirely. Shows no dirty at any time." Six checks failed on it.
--
-- The mistake was assuming SET_PED_DIRT_LEVEL is symmetrical. Everything we
-- actually PROVED about it (PHASE1_SPIKE_FINDINGS) was in the clean direction —
-- coal uses it as `0.0` plus a clear-pass, and that is the only use we ever
-- verified. I extended it to mean "and 1.0 makes a horse filthy", which nothing
-- established. So the guard suppressed the engine's own environmental grime —
-- the thing that was ACTUALLY making horses look dirty all along — and put
-- nothing in its place. A horse could no longer get dirty at all.
--
-- Worse, R4 passed it. Every dirt check that round tested CLEANING, so the half
-- that worked was the only half under test.
--
-- SO THE GUARD IS NOW ONE-DIRECTIONAL: it asserts CLEAN and never asserts DIRT.
-- Below the visible threshold we hold the horse spotless, which is what keeps a
-- brushed horse brushed. Above it we take our hands off entirely and let the
-- world dirty the horse the way it always did. We decide when a horse is CLEAN;
-- the engine decides what dirty looks like. That's the half of the split each
-- side can actually deliver.
-- Set true by /sovdirtprobe so the guard stops fighting the probe. THIS is why
-- R6 D3 read "none" for every candidate: the guard below runs twice a second and,
-- whenever stored dirt is under the grace band, calls SET_PED_DIRT_LEVEL(0.0) and
-- a full clearPass — so a probe that dirtied the horse was scrubbed clean before
-- the owner could look. The probe was never testing the native; it was racing our
-- own cleaner and losing.
Metabolism._probing = false

CreateThread(function()
    local tick = 0
    while true do
        Wait(500)
        local a = Horse and Horse.active and Horse.active()
        if Metabolism._probing then
            -- hands entirely off while probing
        elseif current and a and a.ent and DoesEntityExist(a.ent) then
            local lvl = dirtToLevel(current.dirt or 0)
            if lvl <= 0.0 then
                -- Below the threshold: hold it spotless. The level alone isn't
                -- enough — env dirt and decals are separate layers — so the full
                -- clear runs every 2s.
                Citizen.InvokeNative(0x7A56D66C78D1AAB7, a.ent, 0.0)
                tick = tick + 1
                if (tick % 4) == 0 then clearPass(a.ent) end
            else
                -- Above it: hands off. We still nudge the level up, because if
                -- SET_PED_DIRT_LEVEL does paint dirt it costs nothing — but we
                -- no longer CLEAR anything, so engine grime is free to build.
                Citizen.InvokeNative(0x7A56D66C78D1AAB7, a.ent, lvl + 0.0)
                tick = 0
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- ⚠️ TEMPORARY: WHICH NATIVE ACTUALLY PAINTS DIRT?  (remove once answered)
--------------------------------------------------------------------------------
-- ⚠️ R6 D3 returned "none" for all five, but that test was INVALID: the dirt
-- guard above was scrubbing the horse clean twice a second while the probe ran.
-- The probe now SUSPENDS the guard (Metabolism._probing) so the native's effect
-- can survive long enough to see. Candidate 3 (SET_PED_DIRT_LEVEL 100.0) is the
-- one I most expect to work now that nothing is fighting it — the clean
-- direction of this exact native is already proven.
local DIRT_CANDIDATES = {
    { name = 'SET_PED_DIRT_LEVEL 1.0',    fn = function(e) Citizen.InvokeNative(0x7A56D66C78D1AAB7, e, 1.0) end },
    { name = 'SET_PED_DIRT_LEVEL 5.0',    fn = function(e) Citizen.InvokeNative(0x7A56D66C78D1AAB7, e, 5.0) end },
    { name = 'SET_PED_DIRT_LEVEL 100.0',  fn = function(e) Citizen.InvokeNative(0x7A56D66C78D1AAB7, e, 100.0) end },
    { name = '_SET_PED_DAMAGE_CLEANLINESS 3', fn = function(e) Citizen.InvokeNative(0x397CF3E1E2947A62, e, 3) end },
    { name = 'SET_PED_WETNESS_HEIGHT 1.0',fn = function(e) Citizen.InvokeNative(0x9B0D4B9B3C2D6B5F, e, 1.0) end },
}

RegisterCommand('sovdirtprobe', function(_, args)
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then
        Bridge.notify('Bring your horse out first.'); return
    end
    local first = args and args[1]
    if first == 'off' then
        Metabolism._probing = false
        Bridge.notify('Dirt guard back on.')
        return
    end
    local n = tonumber(first)
    if not n then
        print('^3[sov_dirt]^7 candidates (the guard is suspended while probing):')
        for i, c in ipairs(DIRT_CANDIDATES) do print(('  %d = %s'):format(i, c.name)) end
        print('  off = re-enable the coat guard')
        Bridge.notify('See F8 — then /sovdirtprobe <number>, /sovdirtprobe off when done')
        return
    end
    local c = DIRT_CANDIDATES[n]
    if not c then Bridge.notify('No such candidate.'); return end
    -- Suspend the guard, then re-assert the native for a few seconds so a
    -- one-shot that the engine repaints over still has time to be seen.
    Metabolism._probing = true
    CreateThread(function()
        for _ = 1, 30 do            -- ~6s of holding the dirty value
            if not Metabolism._probing then break end
            if a.ent and DoesEntityExist(a.ent) then c.fn(a.ent) end
            Wait(200)
        end
    end)
    print(('^3[sov_dirt]^7 applied #%d — %s (guard suspended, held ~6s). Does the horse LOOK dirty?'):format(n, c.name))
    Bridge.notify(('Tried: %s — /sovdirtprobe off to restore'):format(c.name))
end, false)

--------------------------------------------------------------------------------
-- Penalties — a starving/parched horse is sluggish (never frozen).
--------------------------------------------------------------------------------
local function applyPenalties(ped, card)
    if not (ped and DoesEntityExist(ped)) then return end
    local p = card and card.penalties
    local slow = card and (card.hungerCritical or card.thirstCritical)
    if not p then return end
    -- SET_PED_MOVE_RATE_OVERRIDE — a soft, immediate throttle that lifts the
    -- moment the horse is fed. Cheap, and it doesn't touch the horse's real
    -- stats (those are the trainer's domain).
    local rate = slow and (p.speedMult or 0.7) or 1.0
    Citizen.InvokeNative(0x085BF80FA50A39D1, ped, rate + 0.0)   -- SET_PED_MOVE_RATE_OVERRIDE
end

--------------------------------------------------------------------------------
-- Called by client/horse.lua when a horse is spawned / dismissed.
--------------------------------------------------------------------------------
local activeHorseId = nil

function Metabolism.onHorseOut(ped, horseId, care)
    current = care
    activeHorseId = horseId
    if care then
        Metabolism.applyDirt(ped, care.dirt)
        applyPenalties(ped, care)
        if care.hungerWarn or care.thirstWarn then
            local what = care.thirstWarn and 'thirsty' or 'hungry'
            Bridge.notify(('Your horse is getting %s.'):format(what))
        end
    end
    -- Tell the server which horse is out + whether we're on it, so a used item
    -- knows its target and can enforce horseback-only tools.
    if horseId then
        TriggerServerEvent(Events.SyncCare, horseId, IsPedOnMount(PlayerPedId()))
    end
end

function Metabolism.onHorseAway()
    current, activeHorseId = nil, nil
    TriggerServerEvent(Events.SyncCare, nil, false)
end

-- Keep the server's idea of "am I mounted" fresh, so horseback-only tools and
-- the on-foot animation choice are correct without spamming.
CreateThread(function()
    local wasMounted = nil
    while true do
        Wait(1000)
        if activeHorseId then
            local m = IsPedOnMount(PlayerPedId())
            if m ~= wasMounted then
                wasMounted = m
                TriggerServerEvent(Events.SyncCare, activeHorseId, m)
            end
        else
            wasMounted = nil
        end
    end
end)

--------------------------------------------------------------------------------
-- Care animations  [H3/H5] — RDR2 HAS BOTH ON-FOOT AND MOUNTED VERSIONS.
--------------------------------------------------------------------------------
-- ✅ CORRECTION (2026-07-19): an earlier note here claimed "RDR3 has no mounted
-- brushing animation". That was WRONG. The animation dictionaries are a complete,
-- symmetric family — `left@` and `right@` for approaching on foot, and `mounted@`
-- for doing it from the saddle:
--
--     mech_animal_interaction@horse@mounted@brushing   clips: idle_a, brushing_horse
--     mech_animal_interaction@horse@mounted@feeding    clips: feeding_player,
--                                                             feeding_horse,
--                                                             feeding_horse_face
--
-- So the brush CAN be horseback-only and still look right.
--
-- TWO DIFFERENT MECHANISMS, on purpose:
--   ON FOOT  — TASK_ANIMAL_INTERACTION. The engine walks the player to the
--              horse, spawns the brush prop and plays the paired animation. It
--              handles positioning, which is the hard part when you're stood
--              beside a horse. (This is what coal_stables uses.)
--   MOUNTED  — the rider is ALREADY positioned by the mount system, so there's
--              nothing to walk to. We play the mounted clip directly as an
--              UPPER-BODY animation so the ride isn't interrupted.
--
-- ❌ WHAT WENT WRONG IN ROUND 2, and the lesson (2026-07-25).
-- I found the mounted dictionaries and played them BY HAND with TaskPlayAnim.
-- The rider "contorts completely 90 degrees to the side and into the horse" —
-- which is PHASE1_SPIKE_FINDINGS gotcha #4, word for word: `mech_*` clips are
-- SYNCED-INTERACTION anims and contort a ped when played raw. It wrecked the
-- grooming stablehand in 1.1, and I did it again here. I even wrote the warning
-- in this file and then shipped the thing it warns about.
--
-- ✅ THE POINT I MISSED: the left@ / right@ / mounted@ family exists *because*
-- TASK_ANIMAL_INTERACTION picks between them. It's the engine's own interaction
-- system — you tell it "brush this horse" and IT decides which variant fits your
-- position, plays both halves in sync, and handles the prop. That's exactly why
-- the on-foot path "works perfect" and my hand-played mounted path didn't.
--
-- So: ONE call, both cases. Never TaskPlayAnim for these. If the engine has no
-- mounted variant for something, it plays nothing — which is a clean no-op, not
-- a broken pose.
local INTERACTIONS = {
    brush = { hash = 'Interaction_Brush', prop = 'p_brushHorse02x' },
    feed  = { hash = 'Interaction_Food',  prop = nil },
}

local function playCareAnim(kind)
    if (mcfg().careAnimations == false) then return end
    local ped = PlayerPedId()
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then return end

    local i = INTERACTIONS[kind]; if not i then return end
    Citizen.InvokeNative(0xCD181A959CFDD7F4,             -- TASK_ANIMAL_INTERACTION
        ped, a.ent,
        GetHashKey(i.hash),
        i.prop and GetHashKey(i.prop) or 0,
        1)                                                -- 1 = skip the idle intro
end

function Metabolism.card() return current end

--------------------------------------------------------------------------------
-- Dirt accrual while the horse is out — reported up so it persists on dismiss.
-- The server clamps and only ever accepts a DIRTIER value, so this can't be used
-- to clean a horse for free.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- WHAT DIRTIES AND WHAT WASHES  (owner ruling 2026-07-25)
--------------------------------------------------------------------------------
-- Hard riding dirties. Water rinses some off. Rain washes it clean and leaves
-- the coat shining. (An earlier version had water and rain DIRTYING the horse —
-- backwards, and the owner corrected it.)
local RAINY = { RAIN = true, DRIZZLE = true, SHOWER = true, THUNDER = true,
                THUNDERSTORM = true, SLEET = true, SNOW = true }

local function isRaining()
    local ok, w = pcall(function()
        return Citizen.InvokeNative(0x564B884A05EC45A3, Citizen.ResultAsString())  -- GetPrevWeatherTypeHashName
    end)
    return ok and type(w) == 'string' and RAINY[w:upper()] or false
end

local function inWater(ent)
    local ok, v = pcall(function() return IsEntityInWater(ent) end)
    return ok and v or false
end

local function speedOf(ent)
    local ok, s = pcall(function()
        return Citizen.InvokeNative(0xFB6BA510A533DF81, ent, Citizen.ResultAsFloat())  -- GetEntitySpeed
    end)
    return ok and (s or 0.0) or 0.0
end

-- Net change in dirt over `minutes`. Positive = dirtier, negative = cleaner.
-- Cleaning WINS over dirtying when both apply — you can't get muddier while
-- standing in a rainstorm.
local function dirtDelta(ent, dirt, minutes)
    local cl = mcfg().cleanliness or {}
    local raining = (cl.rain and cl.rain.enabled ~= false) and isRaining()
    local wet     = (cl.water and cl.water.enabled ~= false) and inWater(ent)

    if raining then
        return -((cl.rain.cleanPerMinute or 60.0) * minutes), 'rain'
    end
    if wet then
        -- Water only rinses down to its floor; it's not a proper wash.
        local floor = cl.water.floor or 20.0
        if dirt > floor then
            local wash = (cl.water.cleanPerMinute or 25.0) * minutes
            return -math.min(wash, dirt - floor), 'water'
        end
        return 0.0, 'water'
    end

    -- Otherwise it dirties, faster if you're riding hard.
    local base = (cl.gainPerMinute or 0) * minutes
    local d = cl.dirtying
    if d and d.enabled ~= false and speedOf(ent) >= (d.gallopSpeed or 9.0) then
        base = base * (d.galloping or 1.0)
    end
    return base, nil
end

-- Shine [M3]: rain that gets a horse spotless leaves the coat gleaming, and it
-- fades as the horse dirties again. Applied via the wetness native — a clean wet
-- coat IS the shine, which is why rain gives it and a brush doesn't.
local function applyShine(ent, dirt)
    local cl = mcfg().cleanliness or {}
    if not (cl.rain and cl.rain.shine) then return end
    if not (ent and DoesEntityExist(ent)) then return end
    if dirt <= (cl.rain.shineFadesAt or 10.0) then
        pcall(function() Citizen.InvokeNative(0x9B0D4B9B3C2D6B5F, ent, 1.0) end)  -- SET_PED_WETNESS_HEIGHT
    else
        pcall(function() if ClearPedWetness then ClearPedWetness(ent) end end)
    end
end

--------------------------------------------------------------------------------
-- DRINKING  [H2] — a horse at water drinks by itself (owner ruling 2026-07-25)
--------------------------------------------------------------------------------
-- No prompt, no item: stand the horse at a river or a trough and its thirst
-- fills. The server decides how much from elapsed time; this only reports that
-- the horse IS at water.
function Metabolism.atWater(ent)
    local d = mcfg().drinking or {}
    if d.enabled == false then return false end
    if speedOf(ent) > (d.maxSpeed or 1.5) then return false end   -- must be still

    if inWater(ent) then return true end                          -- stood in a river

    -- Or beside a trough.
    local c = GetEntityCoords(ent)
    local dist = d.troughDistance or 3.5
    for _, prop in ipairs(d.troughProps or {}) do
        local ok, obj = pcall(function()
            return GetClosestObjectOfType(c.x, c.y, c.z, dist, GetHashKey(prop), false, false, false)
        end)
        if ok and obj and obj ~= 0 and DoesEntityExist(obj) then return true end
    end
    return false
end

-- ⚠️ The automatic "drink a little every five seconds while stood at water"
-- thread lived here and is GONE (owner ruling 2026-07-27). That behaviour WAS
-- "the horse drinks by itself", which is exactly what was asked to stop.
-- Watering is now a deliberate Drink entry in the lock-on menu — see
-- client/horsemenu.lua. Metabolism.atWater stays: the menu uses it to decide
-- whether to OFFER Drink, so the option only appears when there's water to hand.

CreateThread(function()
    while true do
        Wait(15000)   -- 15s: rain should visibly clean within a minute or two
        local c = mcfg()
        if c.enabled ~= false and current and Horse and Horse.active then
            local a = Horse.active()
            if a and a.ent and DoesEntityExist(a.ent) and c.cleanliness and c.cleanliness.enabled ~= false then
                local minutes = 0.25   -- 15s
                local delta, source = dirtDelta(a.ent, current.dirt or 0, minutes)
                local before = current.dirt or 0
                current.dirt = math.max(0, math.min(c.cleanliness.max or 100, before + delta))
                -- Going DOWN (rain/water) needs the re-asserting setter, or the
                -- engine paints the grime straight back on. Going up is fine
                -- with a single set.
                if current.dirt < before then
                    Metabolism.setDirt(a.ent, current.dirt)
                else
                    Metabolism.applyDirt(a.ent, current.dirt)
                end
                applyShine(a.ent, current.dirt)

                -- Tell the server. Dirt going UP uses the clamped report; going
                -- DOWN is a real clean and needs the authoritative path, or the
                -- server's "never accept a cleaner value" rule would discard it.
                if current.dirt > before then
                    TriggerServerEvent(Events.ReportDirt, a.id, math.floor(current.dirt + 0.5))
                elseif current.dirt < before then
                    TriggerServerEvent(Events.ReportWashed, a.id, math.floor(current.dirt + 0.5), source)
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- Server → client
--------------------------------------------------------------------------------
RegisterNetEvent(Events.CareResult, function(res)
    res = res or {}
    -- `quiet` = a background update (drinking at a trough). Update the numbers,
    -- but don't fire a notification every few seconds while the horse drinks.
    if res.message and not res.quiet then Bridge.notify(res.message) end
    if res.ok then
        if res.animate then playCareAnim(res.animate) end
        if res.card then
            current = res.card
            local a = Horse and Horse.active and Horse.active()
            if a and a.ent and DoesEntityExist(a.ent) then
                -- setDirt, NOT applyDirt: an item that cleans (the brush) is a
                -- dirt DECREASE, and a single set gets painted over within a few
                -- frames. This was the R1/R2 bug — animation played, uses counted
                -- down, server cleaned the horse, and the coat stayed filthy.
                Metabolism.setDirt(a.ent, res.card.dirt)
                applyPenalties(a.ent, res.card)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- Feed / clean from a command (fallback to the usable-item path). Uses the
-- horse you have out.
--------------------------------------------------------------------------------
RegisterCommand('sovfeed', function(_, args)
    local item = args and args[1]
    local a = Horse and Horse.active and Horse.active()
    if not a then Bridge.notify('Bring your horse out first.'); return end
    if not item then Bridge.notify('Which feed? e.g. /sovfeed horse_oats'); return end
    TriggerServerEvent(Events.RequestCare, a.id, item)
end, false)

-- Animation check — play a care animation WITHOUT using an item, so the mounted
-- clips can be eyeballed on their own. `/sovanim brush` or `/sovanim feed`; do it
-- mounted and on foot to compare. Testing aid; remove once confirmed.
RegisterCommand('sovanim', function(_, args)
    local kind = (args and args[1]) or 'brush'
    if kind ~= 'brush' and kind ~= 'feed' then
        Bridge.notify('Use /sovanim brush  or  /sovanim feed'); return
    end
    local a = Horse and Horse.active and Horse.active()
    if not a then Bridge.notify('Bring your horse out first.'); return end
    print(('^2[sov_anim]^7 %s — mounted=%s'):format(kind, tostring(IsPedOnMount(PlayerPedId()))))
    playCareAnim(kind)
end, false)

-- Readout — see the current care values on the horse you have out. Testing aid;
-- becomes the right-click horse-info panel in Phase 3 (shared with courage).
RegisterCommand('sovcare', function()
    local c = current
    if not c then Bridge.notify('No care data — bring your horse out.'); return end
    -- Golden was switched off (ruled 2026-07-27), so it no longer appears here.
    -- `shows=` is the coat's rendered level vs the stored number — the two differ
    -- by the grace band, and seeing both is how you tell "brush didn't work" from
    -- "brush worked and the dirt is simply below the visible threshold".
    print(('^2[sov_care]^7 hunger=%s thirst=%s dirt=%s shows=%.2f')
        :format(tostring(c.hunger), tostring(c.thirst), tostring(c.dirt), dirtToLevel(c.dirt or 0)))
    Bridge.notifyCard('info', 'Your Horse',
        ('Hunger %s%% · Thirst %s%% · Dirt %s%%')
        :format(tostring(c.hunger), tostring(c.thirst), tostring(c.dirt)))
end, false)
