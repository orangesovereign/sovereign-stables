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
    local heading = GetEntityHeading(ped) + 180.0

    -- CreatePed(model, x, y, z, heading, isNetwork, bScriptHostPed, p7, p8)
    local horse = CreatePed(hash, fwd.x, fwd.y, fwd.z, heading, false, false, false, false)
    Wait(150)
    if not DoesEntityExist(horse) then
        print('^1[spike]^7 CreatePed returned nothing')
        return nil
    end
    SetEntityInvincible(horse, true)
    FreezeEntityPosition(horse, true)
    SetModelAsNoLongerNeeded(hash)

    Spike.previewHorse = horse
    Spike.currentModel = modelName
    print(('^2[spike]^7 preview horse spawned: %s (entity %s)'):format(modelName, horse))
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

print('^5[spike]^7 loaded. Commands: /spike_horse [model], /spike_coat <model>, /spike_mane [1-5], /spike_tail [1-5], /spike_saddle, /spike_clear, /spike_cam [radius] [speed], /spike_camstop')
