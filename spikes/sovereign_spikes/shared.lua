--[[=====================================================================
  SOVEREIGN SPIKES · SHARED HELPERS  (throwaway)
  ---------------------------------------------------------------------
  A preview horse spawner + cleanup shared by the appearance and camera
  spikes. All results print to the F8 console — open it while testing.
=====================================================================]]--

Spike = Spike or {}

Spike.previewHorse = nil
Spike.defaultModel = 'A_C_Horse_KentuckySaddle_Grey'

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and (GetGameTimer() - t) < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

-- Spawn a frozen, invincible preview horse ~3m in front of the player.
-- rev 2: ground-snap (fixes airborne spawn) + variation init (fixes invisible
-- horse), mirroring the proven vorp_utils + vorp_stables patterns.
function Spike.spawnPreview(modelName)
    modelName = modelName or Spike.defaultModel
    local hash = GetHashKey(modelName)
    if not loadModel(hash) then
        print(('^1[spike]^7 model failed to load: %s'):format(modelName))
        return nil
    end

    Spike.clearPreview()

    local ped = PlayerPedId()
    local fwd = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
    local x, y, z = fwd.x, fwd.y, fwd.z

    -- Snap Z to the ground so the horse doesn't spawn airborne (vorp_utils pattern).
    local found, groundZ = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
    if found then z = groundZ end

    local heading = GetEntityHeading(ped) + 180.0

    -- CreatePed(model, x, y, z, heading, isNetwork, bScriptHostPed, p7, p8)
    local horse = CreatePed(hash, x, y, z, heading, false, true, false, false)
    local t = GetGameTimer()
    while not DoesEntityExist(horse) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(horse) then
        print('^1[spike]^7 CreatePed returned nothing')
        return nil
    end

    -- Initialize the metaped variation so the model actually RENDERS. Without
    -- this a freshly created RDR3 horse spawns invisible. (vorp_stables pattern.)
    Citizen.InvokeNative(0x283978A15512B2FE, horse, true)   -- SetRandomOutfitVariation
    SetEntityVisible(horse, true, false)
    Wait(100)

    SetEntityInvincible(horse, true)
    FreezeEntityPosition(horse, true)
    SetModelAsNoLongerNeeded(hash)

    Spike.previewHorse = horse
    Spike.currentModel = modelName
    print(('^2[spike]^7 preview horse spawned: %s (entity %s) — ground z=%.2f, found=%s'):format(
        modelName, horse, z, tostring(found)))
    return horse
end

function Spike.getOrSpawn(modelName)
    if Spike.previewHorse and DoesEntityExist(Spike.previewHorse) then
        return Spike.previewHorse
    end
    return Spike.spawnPreview(modelName)
end

function Spike.clearPreview()
    if Spike.previewHorse and DoesEntityExist(Spike.previewHorse) then
        DeleteEntity(Spike.previewHorse)
    end
    Spike.previewHorse = nil
end

RegisterCommand('spike_horse', function(_, args)
    Spike.spawnPreview(args[1])
end, false)

RegisterCommand('spike_clear', function()
    Spike.clearPreview()
    print('^3[spike]^7 preview cleared')
end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Spike.clearPreview() end
end)

print('^5[spike]^7 loaded (rev 2 — ground-snap + visibility fix). Commands: /spike_horse [model], /spike_coat <model>, /spike_mane [1-5], /spike_tail [1-5], /spike_saddle, /spike_clear, /spike_cam [radius] [speed], /spike_camstop')
