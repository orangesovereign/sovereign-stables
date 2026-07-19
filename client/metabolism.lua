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
function Metabolism.forceClean(ped)
    if not (ped and DoesEntityExist(ped)) then return end
    Citizen.InvokeNative(0x7A56D66C78D1AAB7, ped, 0.0)   -- SET_PED_DIRT_LEVEL 0
    Citizen.InvokeNative(0x6585D955A68452A5, ped)         -- CLEAR_PED_ENV_DIRT
    Citizen.InvokeNative(0x9C720776DAA43E7E, ped)         -- CLEAR_PED_DAMAGE_DECAL
    Citizen.InvokeNative(0xB63B9178D0F58D82, ped)         -- _CLEAR_PED_TEXTURE
    if ClearPedWetness then ClearPedWetness(ped) end
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
function Metabolism.onHorseOut(ped, horseId, care)
    current = care
    if care then
        Metabolism.applyDirt(ped, care.dirt)
        applyPenalties(ped, care)
        if care.hungerWarn or care.thirstWarn then
            local what = care.thirstWarn and 'thirsty' or 'hungry'
            Bridge.notify(('Your horse is getting %s.'):format(what))
        end
    end
    -- Tell the server which horse is out, so a fed item knows its target.
    if horseId then TriggerServerEvent(Events.SyncCare, horseId) end
end

function Metabolism.onHorseAway()
    current = nil
    TriggerServerEvent(Events.SyncCare, nil)
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
    if res.message then
        if res.ok then Bridge.notify(res.message) else Bridge.notify(res.message) end
    end
    if res.ok and res.card then
        current = res.card
        local a = Horse and Horse.active and Horse.active()
        if a and a.ent and DoesEntityExist(a.ent) then
            Metabolism.applyDirt(a.ent, res.card.dirt)
            applyPenalties(a.ent, res.card)
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
