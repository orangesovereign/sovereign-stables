--[[=====================================================================
  SOVEREIGN STABLES · WORLD PRESENCE  (client)
  ---------------------------------------------------------------------
  Blips, ambient stablehand peds, and the "press G to speak" interaction that
  opens the storefront. One module, registered on the lifecycle bus.
=====================================================================]]--

Stables = Stables or {}

local blips = {}
local peds  = {}
local nearId = nil

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and (GetGameTimer() - t) < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function makeBlip(stable)
    local b = stable.blip
    if not (b and b.enabled and Util.isVec3(b.coords)) then return end
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, b.coords[1], b.coords[2], b.coords[3]) -- BlipAddForCoords
    Citizen.InvokeNative(0x74F74D3207ED525C, blip, b.sprite or 1938782895, 1) -- SetBlipSprite
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, stable.label)              -- SetBlipName
    blips[#blips + 1] = blip
end

local function makePed(stable)
    local p = stable.ped
    if not (p and p.enabled and p.coords and #p.coords >= 4) then return end
    local hash = GetHashKey(p.model)
    if not loadModel(hash) then Util.warn('stablehand model failed: ' .. tostring(p.model)); return end

    local x, y, z, h = p.coords[1], p.coords[2], p.coords[3], p.coords[4]
    local found, gz = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
    if found then z = gz end

    local ped = CreatePed(hash, x, y, z, h, false, true, true, true)
    local t = GetGameTimer()
    while not DoesEntityExist(ped) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(ped) then return end

    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)   -- variation init → renders
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(hash)
    if p.scenario then
        TaskStartScenarioInPlace(ped, GetHashKey(p.scenario), -1, true, false, false, false)
    end
    peds[#peds + 1] = ped
end

function Stables.spawnAll()
    for _, stable in pairs(Config.Stables or {}) do
        makeBlip(stable)
        makePed(stable)
    end
    Util.log(('world presence up: %d blip(s), %d ped(s)'):format(#blips, #peds))
end

-- Nearest stable whose prompt point is within reach of the player, or nil.
local function nearestInRange()
    local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId()))
    local bestId, bestDist
    for id, stable in pairs(Config.Stables or {}) do
        local pr = stable.prompt
        if pr and Util.isVec3(pr.coords) then
            local d = #(vector3(px, py, pz) - vector3(pr.coords[1], pr.coords[2], pr.coords[3]))
            if d <= (pr.distance or 2.0) and (not bestDist or d < bestDist) then
                bestId, bestDist = id, d
            end
        end
    end
    return bestId
end

function Stables.interact()
    local id = nearestInRange()
    Util.log(('interact: nearest=%s open=%s'):format(tostring(id), tostring(Storefront.isOpen())))
    if not id then
        Bridge.notify('Step up to the stablehand first.')
        return
    end
    if not Storefront.isOpen() then Storefront.open(id) end
end

-- Open the nearest stable regardless of range — a reliable test/debug entry.
function Stables.forceNearest()
    local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId()))
    local bestId, bestDist
    for id, stable in pairs(Config.Stables or {}) do
        local pr = stable.prompt
        if pr and Util.isVec3(pr.coords) then
            local d = #(vector3(px, py, pz) - vector3(pr.coords[1], pr.coords[2], pr.coords[3]))
            if not bestDist or d < bestDist then bestId, bestDist = id, d end
        end
    end
    Util.log(('forceNearest: %s at %.1fm'):format(tostring(bestId), bestDist or -1))
    if bestId and not Storefront.isOpen() then Storefront.open(bestId) end
end

-- Proximity hint (debounced): a quiet tick when you step into range.
local function proximityLoop()
    CreateThread(function()
        while true do
            local id = Storefront.isOpen() and nil or nearestInRange()
            if id ~= nearId then
                nearId = id
                if id then
                    Bridge.notifyTick(('Press G to speak with the stablehand at %s'):format(Config.Stables[id].label))
                end
            end
            Wait(400)
        end
    end)
end

-- Register on the lifecycle bus so the core starts us after config validation.
Registry.register({
    name = 'stables',
    onInit = function()
        Stables.spawnAll()
        proximityLoop()
    end,
})

-- Interact key (rebindable in the RedM settings menu) + a test command.
RegisterCommand('sov_stable_interact', function() Stables.interact() end, false)
RegisterKeyMapping('sov_stable_interact', 'Sovereign Stables: speak with stablehand', 'keyboard', 'G')
RegisterCommand('stable', function() Stables.interact() end, false)
-- Debug: force-open the nearest stable from anywhere (ignores range).
RegisterCommand('sovstable', function() Stables.forceNearest() end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, blip in ipairs(blips) do RemoveBlip(blip) end
    for _, ped in ipairs(peds) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
end)
