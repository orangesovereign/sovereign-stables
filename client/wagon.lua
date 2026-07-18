--[[=====================================================================
  SOVEREIGN STABLES · YOUR WAGON IN THE FIELD  (client)
  ---------------------------------------------------------------------
  The wagon you actually drive: called out, dismissed, and its damage
  remembered [WG9]. The server decides IF a wagon may come out; this file
  only puts it there.

  A wagon is a VEHICLE, not a ped — so this does NOT reuse client/horse.lua's
  spawn. Different natives, different ownership calls. The ground-snap gotcha
  still applies though: RDR3 will happily place a vehicle in the air.

  ⚠️ OWNER RULING (1.4 ledger Q2): "No binding for wagon call. You must get
  your wagon from the STABLE ONLY." So there is deliberately no keybind AND
  no /sovwagon command — a wagon is collected in person, at a stable, full
  stop. `Config.Keys.callWagon` stays unbound. Do not add a summon command
  back; it was ruled out, not overlooked.

  ⚠️ AND IT ARRIVES AT THE STABLE'S YARD, not in front of you (1.4 V1/V2:
  a wagon spawned where the player stood appeared inside the building, in
  the air, wedged in the scenery). Each stable configures its own
  `retrieve.wagonPos` — outside, clear of the building.
=====================================================================]]--

Wagon = Wagon or {}

local active = nil    -- { ent, id, name, model }

local wagonBlip = nil

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and (GetGameTimer() - t) < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

--------------------------------------------------------------------------------
-- HEALTH  [WG9]
--------------------------------------------------------------------------------
-- ⚠️ WHICH NATIVE REPORTS A WAGON'S DAMAGE IN RDR3 IS NOT SETTLED.
--
-- None of vorp_stables, bcc-stables or coal_stables persist wagon health, so
-- there is no reference implementation to copy — we are first here.
--
-- 1.4 round 1 used `GetEntityHealth`, which is the PED health native, on a
-- VEHICLE. It reported a constant, so every save wrote full health and damage
-- never persisted (ledger V5/V6/V7). The comment at the top of this file even
-- said "a wagon is a VEHICLE, not a ped — different natives", and then the code
-- used the ped one anyway.
--
-- So rather than guess a second time: read EVERY candidate, log them all, and
-- use the first that exists. The next test round's F8 capture tells us which one
-- actually moves when you shoot a wagon — then this collapses to one call.
-- OUR health is 0-100 (matches horses). The game's native is 0-gameMax; we
-- translate at this one boundary and nowhere else.
local function ourMax()  return (Config.WagonDamage and Config.WagonDamage.maxHealth) or 100 end
local function gameMax() return (Config.WagonDamage and Config.WagonDamage.gameMaxHealth) or 1000 end

-- Read every candidate health native. Some may not exist or may return a
-- constant on RDR3 wagons — that's the whole open question, so we gather them
-- all and let the diagnostic tell us which one actually moves.
local function probeHealth(veh)
    if not (veh and DoesEntityExist(veh)) then return {} end
    local function try(fn, ...) if type(fn) ~= 'function' then return nil end
        local ok, v = pcall(fn, ...); return ok and v or nil end
    return {
        body      = try(GetVehicleBodyHealth, veh),
        engine    = try(GetVehicleEngineHealth, veh),
        petrol    = try(GetVehiclePetrolTankHealth, veh),
        entity    = try(GetEntityHealth, veh),
        entityMax = try(GetEntityMaxHealth, veh),
    }
end

-- ✅ SETTLED by the /sovwagonhp capture, 2026-07-15. On a horse-drawn RDR3
-- wagon the GTA vehicle-component natives return CONSTANTS, not damage:
--     body = 0.0 (always) · engine = 150.0 · petrol = 1000.0
-- A wagon has no engine or fuel tank, so those two being flat defaults exposes
-- the whole family — including body. `GetEntityHealth` is the only reading that
-- actually tracks damage, and it reports a real max of 1000 via
-- GetEntityMaxHealth. So: entity is the source; body/engine/petrol stay in the
-- diagnostic only, as the evidence for this decision.
local function pickRaw(p)
    return p.entity
end

-- Native raw (0-gameMax) -> our stored 0-100. Uses the ped's own reported max
-- when it has one, else the configured gameMax.
local function toStored(raw, entityMax)
    if not raw then return nil end
    local gm = (entityMax and entityMax > 0) and entityMax or gameMax()
    local pct = raw / gm * ourMax()
    return math.max(0, math.min(ourMax(), math.floor(pct + 0.5)))
end

-- Our stored 0-100 -> native raw (0-gameMax), for writing damage back.
local function toGame(stored, entityMax)
    local gm = (entityMax and entityMax > 0) and entityMax or gameMax()
    return (stored / ourMax()) * gm
end

-- Returns a 0..ourMax integer, or nil if nothing readable.
local function readHealth(veh)
    local p = probeHealth(veh)
    local raw = pickRaw(p)
    if raw == nil then return nil end
    return toStored(raw, p.entityMax)
end

-- ⚠️ DIAGNOSTIC [1.4 V5/V6/V7] — `/sovwagonhp`, run while sitting in a damaged
-- wagon BEFORE it's destroyed. Prints every native's reading so we can see which
-- one drops when you shoot the cart. Delete once the native is confirmed.
RegisterCommand('sovwagonhp', function()
    local veh = active and active.ent
    if not (veh and DoesEntityExist(veh)) then
        print('^3[sov_wagon]^7 no wagon out — bring one round first'); return
    end
    local p = probeHealth(veh)
    print('^2[sov_wagon] HEALTH PROBE ^7(shoot the wagon, run this again, see what moved):')
    print(('    body   = %s'):format(tostring(p.body)))
    print(('    engine = %s'):format(tostring(p.engine)))
    print(('    petrol = %s'):format(tostring(p.petrol)))
    print(('    entity = %s  (max %s)  dead=%s')
        :format(tostring(p.entity), tostring(p.entityMax), tostring(IsEntityDead(veh))))
    print(('    -> ENTITY is the source; we would save (0-%d): %s')
        :format(ourMax(), tostring(toStored(pickRaw(p), p.entityMax))))
    print('    (body/engine/petrol are GTA constants on a wagon — ignore them)')
    Bridge.notify(('Wagon soundness: %s%% (F8 for detail)')
        :format(tostring(toStored(pickRaw(p), p.entityMax))))
end, false)

-- `hp` is OUR stored scale (0-ourMax). Translated to the game's scale here.
local function applyHealth(veh, hp)
    hp = tonumber(hp)
    if not hp then return end
    hp = math.max(0, math.min(ourMax(), hp))
    if hp >= ourMax() then return end            -- nothing to restore

    local cfg = Config.WagonDamage or {}
    -- A wrecked wagon comes out at the field-repair floor rather than at 0 —
    -- a 0-hp wagon explodes the moment you look at it. Whether it should come
    -- out at all is Q3, and the owner hasn't ruled.
    if hp <= 0 then hp = cfg.fieldRepairTo or 15 end

    local entMax = GetEntityMaxHealth and GetEntityMaxHealth(veh) or nil
    local game = toGame(hp, entMax)              -- 0-100 -> native scale
    if SetVehicleBodyHealth   then SetVehicleBodyHealth(veh, game + 0.0) end
    if SetVehicleEngineHealth then SetVehicleEngineHealth(veh, game + 0.0) end
    SetEntityHealth(veh, math.max(1, math.floor(game)))
end

--------------------------------------------------------------------------------
-- BLIP  — owner request 2026-07-15: a wagon blip that follows it once it's out.
--------------------------------------------------------------------------------
-- Uses R★'s OWN player-wagon blip style (`blip_mp_player_wagon`, 1612913921),
-- which already does the thing you'd otherwise hand-roll: its documented
-- conditional style HIDES the blip while you are riding the entity. Same trick
-- as the player horse blip. Don't invent a sprite — the game has one.
local function makeWagonBlip(veh, name)
    local cfg = Config.WagonBlip or {}
    if cfg.enabled == false then return end
    if not (veh and DoesEntityExist(veh)) then return end

    -- BlipAddForEntity — the blip tracks the entity, so no per-frame updating.
    -- ⚠️ UNVERIFIED IN THIS ENVIRONMENT: no local reference resource uses it, so
    -- it is wrapped. If it fails, the wagon still works — you just lose the blip.
    local ok, blip = pcall(function()
        return Citizen.InvokeNative(0x23F74C2FDA6E7C61, cfg.style or 1664425300, veh)
    end)
    if not ok or not blip or blip == 0 then
        Util.warn('wagon blip: BlipAddForEntity failed — wagon is fine, blip is not')
        return
    end
    pcall(function()
        Citizen.InvokeNative(0x74F74D3207ED525C, blip, cfg.sprite or 1612913921, 1)  -- SetBlipSprite
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, name or cfg.label or 'Wagon') -- SetBlipName
    end)
    wagonBlip = blip
    Util.log(('wagon blip created (%s)'):format(tostring(blip)))
end

local function removeWagonBlip()
    if wagonBlip then
        pcall(function() RemoveBlip(wagonBlip) end)
        wagonBlip = nil
    end
end

local function isDriving()
    local ped = PlayerPedId()
    if not active or not active.ent then return false end
    return IsPedInVehicle(ped, active.ent, false)
end

-- Put a wagon on the ground and hand it to the player.
local function place(model, x, y, z, heading, name)
    local hash = GetHashKey(model)
    if not loadModel(hash) then Util.err('wagon model failed: ' .. tostring(model)); return nil end

    local found, gz = GetGroundZAndNormalFor_3dCoord(x, y, z + 2.0)
    if found then z = gz end

    -- networked: other players should see your wagon
    local veh = CreateVehicle(hash, x, y, z, heading or 0.0, true, true, false)
    local t = GetGameTimer()
    while not DoesEntityExist(veh) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(veh) then return nil end

    SetVehicleOnGroundProperly(veh)
    SetEntityVisible(veh, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetModelAsNoLongerNeeded(hash)
    return veh
end

-- Bring the wagon out to the STABLE YARD. `data.stableId` says which stable it
-- was collected from; that stable's `retrieve.wagonPos` is where it appears.
function Wagon.spawn(data)
    if not data or not data.model then return end
    Wagon.despawn(true)

    local stable = data.stableId and Config.Stables[data.stableId]
    local spot = stable and stable.retrieve and stable.retrieve.wagonPos
    if not spot then
        -- Never fall back to spawning on the player: that is exactly what put a
        -- wagon inside the building. Refuse loudly so the config gets fixed.
        Util.err(('stable "%s" has no retrieve.wagonPos configured — refusing to spawn a wagon on top of the player')
            :format(tostring(data.stableId)))
        Bridge.notify('This stable has nowhere to bring a wagon out. Tell an admin.')
        return
    end

    local veh = place(data.model, spot[1], spot[2], spot[3], spot[4] or 0.0, data.name)
    if not veh then
        Util.err(('wagon spawn FAILED for model %s'):format(tostring(data.model)))
        Bridge.notify('Your wagon could not be brought round.')
        return
    end

    -- Restore remembered damage [WG9]. Health is stored server-side, so a wagon
    -- you wrecked yesterday is still wrecked today.
    -- NOTE `~= nil`, not `if data.health`: a wrecked wagon's health is 0, which
    -- is falsy, so `if data.health` skipped the restore and spawned a pristine
    -- cart every time — half of "it keeps giving me a brand new wagon".
    if data.health ~= nil then applyHealth(veh, data.health) end

    -- Livery / colour [WG4], when the tint table lands.
    if data.tint and SetVehicleTint then
        pcall(function() SetVehicleTint(veh, data.tint) end)
    end

    active = { ent = veh, id = data.id, name = data.name, model = data.model }
    makeWagonBlip(veh, data.name)
    Bridge.notify(('%s is brought round.'):format(data.name or 'Your wagon'))
    local c = GetEntityCoords(veh)
    Util.log(('wagon #%s (%s) spawned at %.1f, %.1f, %.1f (entity %s)'):format(
        tostring(data.id), tostring(data.model), c.x, c.y, c.z, tostring(veh)))
end

-- Save damage before the wagon leaves the world, or a wreck heals itself by
-- being dismissed — which would make WG9 pointless.
local function reportHealth()
    if not (active and active.ent and DoesEntityExist(active.ent)) then return end
    local hp = readHealth(active.ent)
    if not hp then return end          -- nothing readable: never write a guess
    TriggerServerEvent(Events.ReportWagonHealth, active.id, hp)
end

-- `keepReported` = we have ALREADY sent a final figure (e.g. 0 for a wreck), so
-- do not re-read and overwrite it. Round 1 reported 0 on destruction and then
-- immediately called despawn(), which read the dead entity and clobbered it.
function Wagon.despawn(silent, keepReported)
    if active and active.ent and DoesEntityExist(active.ent) then
        if not keepReported then reportHealth() end
        DeleteEntity(active.ent)
    end
    removeWagonBlip()
    active = nil
    if not silent then Bridge.notify('Your wagon is put away.') end
end

function Wagon.active() return active end

-- Collect a wagon at a stable. Called only from the storefront (owner ruling
-- Q2: stable only). `stableId` is the stable you are standing in.
function Wagon.call(wagonId, stableId)
    if active and DoesEntityExist(active.ent) then
        Bridge.notify(('%s is already out.'):format(active.name or 'Your wagon'))
        return
    end
    TriggerServerEvent(Events.RequestCallWagon, wagonId, stableId)
end

function Wagon.dismiss()
    if not (active and DoesEntityExist(active.ent)) then
        Bridge.notify('You have no wagon out.')
        return
    end
    if isDriving() then Bridge.notify('Step down first.'); return end

    TriggerServerEvent(Events.ReportWagonDismiss, active.id)
    Bridge.notify(('%s is put away.'):format(active.name or 'Your wagon'))
    Wagon.despawn(true)   -- saves the damage on its way out
end

--------------------------------------------------------------------------------
-- Server → client
--------------------------------------------------------------------------------
RegisterNetEvent(Events.CallWagonResult, function(res)
    res = res or {}
    if not res.ok then
        Bridge.notify(res.message or 'No wagon comes.')
        return
    end
    Wagon.spawn(res.wagon)
end)

-- A wagon we no longer own (handed over / sold) must leave our world.
RegisterNetEvent(Events.SyncOwnedRides, function(data)
    local rel = data and data.released
    if not rel then return end
    if rel.kind == 'wagon' and active and active.id == rel.id then
        Wagon.despawn(true)
    end
end)

--------------------------------------------------------------------------------
-- Watchdog: persist damage while it's out, and let go of a destroyed wagon
--------------------------------------------------------------------------------
CreateThread(function()
    while true do
        if active and active.ent then
            if not DoesEntityExist(active.ent) then
                -- Vanished from under us (streamed out, cleaned up by the engine).
                -- Drop the blip too, or it hangs on the map pointing at nothing.
                removeWagonBlip()
                active = nil
            elseif IsEntityDead(active.ent) then
                Util.log(('wagon #%s destroyed'):format(tostring(active.id)))
                TriggerServerEvent(Events.ReportWagonHealth, active.id, 0)
                Wagon.despawn(true, true)   -- keep the 0; don't re-read a corpse
                Bridge.notify('Your wagon is wrecked.')
            else
                reportHealth()   -- cheap, and means a crash never loses the damage
            end
        end
        -- 3s, not 10s: the gap between "drove it off a cliff" and "put it away"
        -- is often shorter than 10 seconds, and an unsaved tick loses the damage.
        Wait(3000)
    end
end)

-- NO /sovwagon command — ruled out (Q2): a wagon is collected at a stable.
-- Putting it away is still a field action, so that one stays.
RegisterCommand('sovwagonaway', function() Wagon.dismiss() end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Wagon.despawn(true) end
end)
