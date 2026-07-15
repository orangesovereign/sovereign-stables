--[[=====================================================================
  SOVEREIGN STABLES · YOUR WAGON IN THE FIELD  (client)
  ---------------------------------------------------------------------
  The wagon you actually drive: called out, dismissed, and its damage
  remembered [WG9]. The server decides IF a wagon may come out; this file
  only puts it there.

  A wagon is a VEHICLE, not a ped — so this does NOT reuse client/horse.lua's
  spawn. Different natives, different ownership calls. The ground-snap gotcha
  still applies though: RDR3 will happily place a vehicle in the air.

  ⚠️ NOTE ON KEYS: RDR2 gives us INPUT_WHISTLE for horses, which is why the
  whistle needs no keybind. There is NO native equivalent for wagons. Rather
  than invent a binding (RegisterKeyMapping only takes effect after a full
  CLIENT restart — see PHASE1_SPIKE_FINDINGS gotcha #2), a wagon is called
  with a command or from the stable, which is also what vorp_stables does.
  `Config.Keys.callWagon` is therefore not bound yet — see the 1.4 ledger.
=====================================================================]]--

Wagon = Wagon or {}

local active = nil    -- { ent, id, name, model }

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and (GetGameTimer() - t) < 5000 do Wait(10) end
    return HasModelLoaded(hash)
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

-- Bring the wagon out in front of the player, same as the owner asked for horses.
function Wagon.spawn(data)
    if not data or not data.model then return end
    Wagon.despawn(true)

    local ped = PlayerPedId()
    local infront = GetOffsetFromEntityInWorldCoords(ped, 0.0, 8.0, 0.0)
    local veh = place(data.model, infront.x, infront.y, infront.z, GetEntityHeading(ped) + 90.0, data.name)
    if not veh then
        Util.err(('wagon spawn FAILED for model %s'):format(tostring(data.model)))
        Bridge.notify('Your wagon could not be brought round.')
        return
    end

    -- Restore remembered damage [WG9]. Health is stored server-side, so a wagon
    -- you wrecked yesterday is still wrecked today.
    if data.health then
        local hp = math.max(1, tonumber(data.health) or 1000)
        SetEntityHealth(veh, hp)
        SetVehicleEngineHealth(veh, hp + 0.0)
    end

    -- Livery / colour [WG4], when the tint table lands.
    if data.tint and SetVehicleTint then
        pcall(function() SetVehicleTint(veh, data.tint) end)
    end

    active = { ent = veh, id = data.id, name = data.name, model = data.model }
    Bridge.notify(('%s is brought round.'):format(data.name or 'Your wagon'))
    local c = GetEntityCoords(veh)
    Util.log(('wagon #%s (%s) spawned at %.1f, %.1f, %.1f (entity %s)'):format(
        tostring(data.id), tostring(data.model), c.x, c.y, c.z, tostring(veh)))
end

-- Save damage before the wagon leaves the world, or a wreck heals itself by
-- being dismissed — which would make WG9 pointless.
local function reportHealth()
    if not (active and active.ent and DoesEntityExist(active.ent)) then return end
    local hp = math.floor(GetEntityHealth(active.ent) or 1000)
    TriggerServerEvent(Events.ReportWagonHealth, active.id, hp)
end

function Wagon.despawn(silent)
    if active and active.ent and DoesEntityExist(active.ent) then
        reportHealth()
        DeleteEntity(active.ent)
    end
    active = nil
    if not silent then Bridge.notify('Your wagon is put away.') end
end

function Wagon.active() return active end

-- Ask for your default wagon. Server decides if it may come.
function Wagon.call(wagonId)
    if active and DoesEntityExist(active.ent) then
        Bridge.notify(('%s is already out.'):format(active.name or 'Your wagon'))
        return
    end
    TriggerServerEvent(Events.RequestCallWagon, wagonId)
end

function Wagon.dismiss()
    if not (active and DoesEntityExist(active.ent)) then
        Bridge.notify('You have no wagon out.')
        return
    end
    if isDriving() then Bridge.notify('Step down first.'); return end

    reportHealth()
    TriggerServerEvent(Events.ReportWagonDismiss, active.id)
    Bridge.notify(('%s is put away.'):format(active.name or 'Your wagon'))
    Wagon.despawn(true)
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
                active = nil
            elseif IsEntityDead(active.ent) then
                Util.log(('wagon #%s destroyed'):format(tostring(active.id)))
                TriggerServerEvent(Events.ReportWagonHealth, active.id, 0)
                Wagon.despawn(true)
                Bridge.notify('Your wagon is wrecked.')
            else
                reportHealth()   -- cheap, and means a crash never loses the damage
            end
        end
        Wait(10000)
    end
end)

RegisterCommand('sovwagon', function(_, args)
    Wagon.call(args and args[1] and tonumber(args[1]) or nil)
end, false)
RegisterCommand('sovwagonaway', function() Wagon.dismiss() end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Wagon.despawn(true) end
end)
