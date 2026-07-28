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
-- Dirt on the ped — REAL RDR3 NATIVES (alloc8or nativedb, confirmed 2026-07-27)
--------------------------------------------------------------------------------
-- ⚠️ THE MYSTERY, SOLVED. Every "set dirt" we ever wrote used 0x7A56D66C78D1AAB7,
-- which is a GTA V native that DOES NOT EXIST in RDR3 — so every call was a silent
-- no-op. The horse got dirty entirely from the ENGINE's own environmental grime,
-- and the only real native in our old clear-pass was CLEAR_PED_ENV_DIRT — which is
-- why we could only ever CLEAN a horse, never dirty one, and why the guard's
-- every-2-seconds clear killed the natural dirt the owner watched appear early on.
--
-- The real system: the engine paints dirt automatically; we READ it, PERSIST it,
-- and RESTORE it. Dirt is a float 0.0-1.0; our number is that × 100.
local N_GET_DIRT  = 0x0105FEE8F9091255  -- _GET_PED_DIRT_LEVEL(ped, useComposite) -> float
local N_SET_DIRT  = 0xE3144B932DFDFF65  -- _SET_PED_DIRT_CLEANED(ped, lvl, -1, true, true)
local N_CLEAR_ENV = 0x6585D955A68452A5  -- CLEAR_PED_ENV_DIRT(ped)

-- Read the engine's current dirt as 0-100, or nil if the native won't answer.
-- `composite` selects which of RDR3's two dirt slots to read; R9 showed the two
-- do NOT mirror each other (the clean moved the coat but not the composite read),
-- so the layer matters and is a parameter.
function Metabolism.readDirt(ped, composite)
    if not (ped and DoesEntityExist(ped)) then return nil end
    if composite == nil then composite = true end
    local ok, v = pcall(function()
        return Citizen.InvokeNative(N_GET_DIRT, ped, composite, Citizen.ResultAsFloat())
    end)
    if ok and type(v) == 'number' then return math.max(0, math.min(100, math.floor(v * 100 + 0.5))) end
    return nil
end

-- Write a 0-100 dirt value onto the horse. The nativedb's own read-add-write
-- example shows this native SETTING the level (not just zeroing), so this is how
-- we restore a stored dirty coat on spawn.
function Metabolism.applyDirt(ped, dirt0to100)
    if not (ped and DoesEntityExist(ped)) then return end
    local f = math.max(0.0, math.min(1.0, (tonumber(dirt0to100) or 0) / 100.0))
    pcall(function() Citizen.InvokeNative(N_SET_DIRT, ped, f + 0.0, -1, true, true) end)
end

-- Groom a horse fully clean: zero the dirt level AND clear the accumulated
-- environmental layer, or the engine repaints grime within a few frames.
local function clearPass(ped)
    pcall(function() Citizen.InvokeNative(N_SET_DIRT, ped, 0.0, -1, true, true) end)
    pcall(function() Citizen.InvokeNative(N_CLEAR_ENV, ped) end)
    if ClearPedWetness then pcall(ClearPedWetness, ped) end
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

-- Set the coat to a specific 0-100 value. 0 fully grooms (clear-pass); anything
-- above just writes the level and lets the engine keep it.
function Metabolism.setDirt(ped, dirt0to100)
    if not (ped and DoesEntityExist(ped)) then return end
    local d = tonumber(dirt0to100) or 0
    if d <= 0 then clearPass(ped); return end
    pcall(function() Citizen.InvokeNative(N_SET_DIRT, ped, (d / 100.0) + 0.0, -1, true, true) end)
end

--------------------------------------------------------------------------------
-- THE DIRT SYNC — the engine dirties the horse; we read it and persist it.
--------------------------------------------------------------------------------
-- The whole three-round fight with "the guard" is over, because it was built on a
-- native that did nothing (see above). No more holding the coat at our number, no
-- more clearing every two seconds — THAT was what scrubbed the engine's dirt off
-- and stopped horses getting dirty at all.
--
-- Now the engine owns the visual: it dirties the horse as it rides through the
-- world, and washes it in rain, exactly as it did before we ever interfered. Our
-- only jobs are to READ what the engine has painted so it can be saved, and to
-- RESTORE it when the horse comes back out. A freshly brushed horse starts clean
-- and the world dirties it again naturally — no grace band needed, because the
-- engine doesn't slap dirt on the instant you leave town.
Metabolism._probing = false   -- still honoured by the probe below

CreateThread(function()
    while true do
        Wait(10000)   -- every 10s: read the engine's dirt and persist if it moved
        local a = Horse and Horse.active and Horse.active()
        if not Metabolism._probing and current and a and a.ent and DoesEntityExist(a.ent) then
            local lvl = Metabolism.readDirt(a.ent)
            if lvl and math.abs(lvl - (current.dirt or 0)) >= 2 then
                current.dirt = lvl
                TriggerServerEvent(Events.ReportDirt, a.id, lvl)   -- server clamps; see note
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- ⚠️ TEMPORARY: prove the REAL dirt native paints and reads.  (remove once green)
--------------------------------------------------------------------------------
-- The R6/R7 probes tested a GTA V native that doesn't exist in RDR3, so of course
-- nothing happened. This one uses the confirmed RDR3 native
-- _SET_PED_DIRT_CLEANED, which the nativedb's own example uses to RAISE dirt, not
-- just zero it. `/sovdirtset 25|50|100` writes that level and reads it straight
-- back so we can see the coat AND confirm the value stuck; `/sovdirtset 0` grooms.
RegisterCommand('sovdirtset', function(_, args)
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then
        Bridge.notify('Bring your horse out first.'); return
    end
    local n = tonumber(args and args[1])
    if n == nil then
        Bridge.notify('Usage: /sovdirtset 0 | 25 | 50 | 100')
        return
    end
    n = math.max(0, math.min(100, n))
    Metabolism.setDirt(a.ent, n)
    -- Read BOTH layers back. R9 proved the clean moved the coat but not the
    -- layer we were reading, so the two dirt slots are different things. Whichever
    -- of these tracks what you SEE is the one we should persist.
    CreateThread(function()
        Wait(300)
        local comp = Metabolism.readDirt(a.ent, true)
        local base = Metabolism.readDirt(a.ent, false)
        print(('^3[sov_dirt]^7 set %d%% -> composite=%s%%  base=%s%%. Which matches what the horse LOOKS like?')
            :format(n, tostring(comp), tostring(base)))
        Bridge.notify(('Set %d%% — composite %s / base %s'):format(n, tostring(comp), tostring(base)))
    end)
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
-- Helpers shared with the drinking check below.
--------------------------------------------------------------------------------
-- ⚠️ The whole "dirtDelta / applyShine / what-dirties-what-washes" simulation
-- that lived here is GONE (2026-07-27). It existed to dirty and wash the horse
-- ourselves — but the engine already does BOTH: it muddies a horse as it rides
-- and rinses it in the rain, with its own shine. We were duplicating the engine
-- with a fake native that did nothing, and the real halves fought it. The engine
-- owns the visual now; the sync thread above just reads and persists the result.
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

--------------------------------------------------------------------------------
-- DRINKING  [H2] — offered in the lock-on menu; the horse never drinks unprompted
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

-- ⚠️ Two threads used to live here — the auto-drink trickle and the rain/water
-- dirt simulation — and BOTH are gone (2026-07-27). Drinking is now the deliberate
-- menu action; dirtying and washing are the engine's own, read and persisted by
-- the sync thread near the top of this file. Metabolism.atWater stays because the
-- Give Water prompt uses it to know whether a drink is possible right now.

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
            local prevDirt = current and current.dirt
            current = res.card
            local a = Horse and Horse.active and Horse.active()
            if a and a.ent and DoesEntityExist(a.ent) then
                applyPenalties(a.ent, res.card)

                -- R7 Q1: "The cleaning shouldn't occur until the brushing
                -- animation is done." So when a brush LOWERS the dirt, we hold the
                -- old coat until the animation has played out, THEN clean — the
                -- horse visibly gets groomed rather than snapping clean the instant
                -- you press. The number is already updated; only the coat waits.
                local cleaned = res.animate == 'brush' and prevDirt and res.card.dirt < prevDirt
                if cleaned then
                    Metabolism.applyDirt(a.ent, prevDirt)   -- keep looking dirty for now
                    local horseEnt = a.ent
                    CreateThread(function()
                        Wait((((Config.UI and Config.UI.horseMenu and Config.UI.horseMenu.brushAnimSeconds)) or 4) * 1000)
                        if horseEnt and DoesEntityExist(horseEnt) then
                            -- setDirt, NOT applyDirt: cleaning is a DECREASE and a
                            -- single set gets repainted within a few frames (the
                            -- original R1/R2 bug). setDirt runs the full clear pass.
                            Metabolism.setDirt(horseEnt, res.card.dirt)
                        end
                    end)
                else
                    Metabolism.setDirt(a.ent, res.card.dirt)
                end
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
    -- `engine=` is what _GET_PED_DIRT_LEVEL reports on the horse right now, vs our
    -- stored `dirt=`. They should track: the engine paints dirt, we read it. If
    -- they diverge, the sync thread hasn't caught up (it runs every 10s).
    local a = Horse and Horse.active and Horse.active()
    local engine = a and a.ent and Metabolism.readDirt(a.ent)
    print(('^2[sov_care]^7 hunger=%s thirst=%s dirt=%s engine=%s')
        :format(tostring(c.hunger), tostring(c.thirst), tostring(c.dirt), tostring(engine)))
    Bridge.notifyCard('info', 'Your Horse',
        ('Hunger %s%% · Thirst %s%% · Dirt %s%%')
        :format(tostring(c.hunger), tostring(c.thirst), tostring(c.dirt)))
end, false)
