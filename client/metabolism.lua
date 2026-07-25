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
-- 0-100 dirt -> the game's 0.0-1.0 dirt level, applied to a horse ped.
function Metabolism.applyDirt(ped, dirt0to100)
    if not (ped and DoesEntityExist(ped)) then return end
    local lvl = math.max(0.0, math.min(1.0, (tonumber(dirt0to100) or 0) / 100.0))
    Citizen.InvokeNative(0x7A56D66C78D1AAB7, ped, lvl + 0.0)   -- SET_PED_DIRT_LEVEL
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
-- ⚠️ PHASE1_SPIKE_FINDINGS gotcha #4 warns that `mech_*` clips are synced
-- interaction anims that contort a ped when played raw — that bit us on the
-- grooming stablehand. It applied to the ON-FOOT paired clips, where the ped has
-- to be placed relative to the horse. The mounted clips don't have that problem
-- (the rider is already in place), and we mask to the upper body. Even so, this
-- is the exact class of thing that has misbehaved before: NEEDS IN-GAME
-- CONFIRMATION, and `Config.Metabolism.mountedAnimations = false` turns it off
-- without losing the care effect.
local MOUNTED_ANIMS = {
    brush = { dict = 'mech_animal_interaction@horse@mounted@brushing', clip = 'brushing_horse' },
    feed  = { dict = 'mech_animal_interaction@horse@mounted@feeding',  clip = 'feeding_player',
              horseClip = 'feeding_horse' },   -- the horse's half of the paired anim
}
local UPPER_BODY_FLAG = 48   -- 16 (upper body) + 32 (keep player control)

local function loadDict(dict, timeoutMs)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(dict) and (GetGameTimer() - t) < (timeoutMs or 2000) do Wait(10) end
    return HasAnimDictLoaded(dict)
end

local function playCareAnim(kind)
    local ped = PlayerPedId()
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then return end

    if IsPedOnMount(ped) then
        if (mcfg().mountedAnimations == false) then return end
        local m = MOUNTED_ANIMS[kind]; if not m then return end
        CreateThread(function()
            if not loadDict(m.dict) then
                Util.warn(('mounted care anim dict failed to load: %s'):format(m.dict))
                return
            end
            -- Upper body only: the horse keeps walking, the rider leans over.
            TaskPlayAnim(ped, m.dict, m.clip, 4.0, -4.0, -1, UPPER_BODY_FLAG, 0.0, false, false, false)
            -- Feeding is a PAIRED animation — the horse has its own half.
            if m.horseClip and DoesEntityExist(a.ent) then
                TaskPlayAnim(a.ent, m.dict, m.horseClip, 4.0, -4.0, -1, 0, 0.0, false, false, false)
            end
            Wait(4000)
            if DoesEntityExist(ped) then ClearPedSecondaryTask(ped) end
            RemoveAnimDict(m.dict)
        end)
        return
    end

    -- On foot: let the engine do the positioning + prop.
    if kind == 'brush' then
        Citizen.InvokeNative(0xCD181A959CFDD7F4, ped, a.ent,
            GetHashKey('Interaction_Brush'), GetHashKey('p_brushHorse02x'), 1)  -- TASK_ANIMAL_INTERACTION
    elseif kind == 'feed' then
        Citizen.InvokeNative(0xCD181A959CFDD7F4, ped, a.ent,
            GetHashKey('Interaction_Food'), 0, 1)
    end
end

function Metabolism.card() return current end

--------------------------------------------------------------------------------
-- Dirt accrual while the horse is out — reported up so it persists on dismiss.
-- The server clamps and only ever accepts a DIRTIER value, so this can't be used
-- to clean a horse for free.
--------------------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(30000)   -- every 30s; dirt is slow, this is plenty
        local c = mcfg()
        if c.enabled ~= false and current and Horse and Horse.active then
            local a = Horse.active()
            if a and a.ent and DoesEntityExist(a.ent) and c.cleanliness and c.cleanliness.enabled ~= false then
                current.dirt = math.min(c.cleanliness.max or 100,
                    (current.dirt or 0) + (c.cleanliness.gainPerMinute or 0) * 0.5)  -- 30s = 0.5 min
                Metabolism.applyDirt(a.ent, current.dirt)
                TriggerServerEvent(Events.ReportDirt, a.id, math.floor(current.dirt + 0.5))
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- Server → client
--------------------------------------------------------------------------------
RegisterNetEvent(Events.CareResult, function(res)
    res = res or {}
    if res.message then Bridge.notify(res.message) end
    if res.ok then
        if res.animate then playCareAnim(res.animate) end
        if res.card then
            current = res.card
            local a = Horse and Horse.active and Horse.active()
            if a and a.ent and DoesEntityExist(a.ent) then
                Metabolism.applyDirt(a.ent, res.card.dirt)
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
