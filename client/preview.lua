--[[=====================================================================
  SOVEREIGN STABLES · PREVIEW HORSE  (client)
  ---------------------------------------------------------------------
  Spawns the frozen showcase horse the storefront orbits. Uses the exact
  spawn sequence proven in the Phase 1 spike (docs/PHASE1_SPIKE_FINDINGS.md):
  ground-snap + variation-init or the horse spawns invisible / airborne.
=====================================================================]]--

Preview = Preview or {}

local horse       -- current preview entity
local curModel    -- current model id

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and (GetGameTimer() - t) < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

-- pos = { x, y, z, heading }
function Preview.show(model, pos)
    Preview.hide()
    local hash = GetHashKey(model)
    if not loadModel(hash) then
        Util.err('preview model failed to load: ' .. tostring(model))
        return nil
    end

    local x, y, z, heading = pos[1], pos[2], pos[3], pos[4] or 0.0
    local found, groundZ = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
    if found then z = groundZ end

    horse = CreatePed(hash, x, y, z, heading, false, true, false, false)
    local t = GetGameTimer()
    while not DoesEntityExist(horse) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(horse) then
        Util.err('preview CreatePed returned nothing')
        return nil
    end

    Citizen.InvokeNative(0x283978A15512B2FE, horse, true)   -- variation init → renders
    SetEntityVisible(horse, true, false)
    SetEntityInvincible(horse, true)
    FreezeEntityPosition(horse, true)
    SetBlockingOfNonTemporaryEvents(horse, true)
    SetModelAsNoLongerNeeded(hash)

    curModel = model
    return horse
end

function Preview.ped()   return horse end
function Preview.model() return curModel end

-- Apply a metaped component (mane/tail/tack hash) to the preview horse.
function Preview.apply(hash)
    if not (horse and DoesEntityExist(horse)) then return end
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horse, hash, true, true, true)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, horse, 0, 1, 1, 1, 0)
end

function Preview.hide()
    if horse and DoesEntityExist(horse) then DeleteEntity(horse) end
    horse, curModel = nil, nil
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Preview.hide() end
end)
