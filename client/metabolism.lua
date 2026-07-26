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

-- ⚠️ USE THIS WHENEVER DIRT GOES **DOWN** (brushing, rain, fording a river).
--
-- The 2.1 R3 brush bug: the animation played, the server correctly cleaned the
-- horse, uses counted down — and the coat stayed filthy. Cause: a single
-- SET_PED_DIRT_LEVEL is overwritten within a few frames as the engine re-applies
-- environmental grime. It's the same thing that made the storefront preview
-- stay dirty, and the same reason forceClean loops. Setting it once is only ever
-- reliable when dirt is going UP (the engine agrees with you).
--
-- So: clear properly first, then re-assert the target over ~800ms.
function Metabolism.setDirt(ped, dirt0to100)
    if not (ped and DoesEntityExist(ped)) then return end
    local lvl = dirtToLevel(dirt0to100)
    clearPass(ped)                                              -- wipe env dirt + decals
    Citizen.InvokeNative(0x7A56D66C78D1AAB7, ped, lvl + 0.0)
    CreateThread(function()
        for _ = 1, 8 do
            Wait(100)
            if not (ped and DoesEntityExist(ped)) then return end
            if lvl <= 0.0 then clearPass(ped) end
            Citizen.InvokeNative(0x7A56D66C78D1AAB7, ped, lvl + 0.0)
        end
    end)
end

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
local function atWater(ent)
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

CreateThread(function()
    while true do
        Wait(5000)   -- drinking should feel responsive: a few seconds at a trough
        local c = mcfg()
        if c.enabled ~= false and current and Horse and Horse.active then
            local a = Horse.active()
            if a and a.ent and DoesEntityExist(a.ent) and atWater(a.ent) then
                TriggerServerEvent(Events.ReportDrank, a.id)
            end
        end
    end
end)

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
    print(('^2[sov_care]^7 hunger=%s thirst=%s dirt=%s golden=%s')
        :format(tostring(c.hunger), tostring(c.thirst), tostring(c.dirt), tostring(c.golden)))
    Bridge.notifyCard(c.golden and 'complete' or 'info', 'Your Horse',
        ('Hunger %s%% · Thirst %s%% · Dirt %s%%%s')
        :format(tostring(c.hunger), tostring(c.thirst), tostring(c.dirt),
                c.golden and ' · GOLDEN' or ''))
end, false)
