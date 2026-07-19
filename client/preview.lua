--[[=====================================================================
  SOVEREIGN STABLES · THE PREVIEW STAND  (client)
  ---------------------------------------------------------------------
  Spawns the frozen showcase HORSE — or WAGON — that the storefront orbits.
  Exactly ONE preview entity exists at a time: switching to wagons removes
  the horse and vice versa, so the stand is never double-booked.

  Uses the spawn sequence proven in the Phase 1 spike
  (docs/PHASE1_SPIKE_FINDINGS.md): ground-snap + variation-init, or the
  horse spawns invisible and airborne.
=====================================================================]]--

Preview = Preview or {}

local current     -- the ONE live preview entity: a horse OR a wagon
local curModel    -- its model id

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

    current = CreatePed(hash, x, y, z, heading, false, true, false, false)
    local t = GetGameTimer()
    while not DoesEntityExist(current) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(current) then
        Util.err('preview CreatePed returned nothing')
        return nil
    end

    Citizen.InvokeNative(0x283978A15512B2FE, current, true)   -- variation init → renders
    SetEntityVisible(current, true, false)
    SetEntityInvincible(current, true)
    FreezeEntityPosition(current, true)
    SetBlockingOfNonTemporaryEvents(current, true)
    SetModelAsNoLongerNeeded(hash)

    -- [L9] A showroom horse is always spotless, whatever the real one's state.
    if (Config.Metabolism and Config.Metabolism.cleanliness
        and Config.Metabolism.cleanliness.previewAlwaysClean ~= false)
        and Metabolism and Metabolism.forceClean then
        pcall(Metabolism.forceClean, current)
    end

    curModel = model
    return current
end

-- The showroom WAGON [1.4 G2]. Browsing wagons shows a wagon, not a horse —
-- the horse preview is removed first so you aren't shopping for a cart while a
-- Turkoman stands in the frame. Its own spot per stable (preview.wagonPos).
--
-- Kept separate from Preview.show rather than branched: a wagon is a vehicle,
-- so it is a different create call, a different ground-snap, and it has no
-- variation-init step (that's a ped thing).
function Preview.showWagon(model, pos)
    Preview.hide()
    local hash = GetHashKey(model)
    if not loadModel(hash) then
        Util.err('preview wagon model failed to load: ' .. tostring(model))
        return nil
    end

    local x, y, z, heading = pos[1], pos[2], pos[3], pos[4] or 0.0
    local found, groundZ = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
    if found then z = groundZ end

    local veh = CreateVehicle(hash, x, y, z, heading, false, true, false)
    local t = GetGameTimer()
    while not DoesEntityExist(veh) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(veh) then
        Util.err('preview CreateVehicle returned nothing')
        return nil
    end

    SetVehicleOnGroundProperly(veh)
    SetEntityVisible(veh, true, false)
    SetEntityInvincible(veh, true)
    FreezeEntityPosition(veh, true)
    SetModelAsNoLongerNeeded(hash)

    current  = veh          -- same slot: only ever ONE preview entity exists
    curModel = model
    return veh
end

-- Named `ped` for history; it is whatever is on the stand right now.
function Preview.ped()   return current end
function Preview.model() return curModel end

-- Apply a metaped component (mane/tail/tack hash) to the preview horse.
function Preview.apply(hash)
    if not (current and DoesEntityExist(current)) then return end
    Citizen.InvokeNative(0xD3A7B003ED343FD9, current, hash, true, true, true)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, current, 0, 1, 1, 1, 0)
end

function Preview.hide()
    if current and DoesEntityExist(current) then DeleteEntity(current) end
    current, curModel = nil, nil
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Preview.hide() end
end)
