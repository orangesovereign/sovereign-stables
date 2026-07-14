--[[=====================================================================
  SOVEREIGN STABLES · WORLD PRESENCE  (client)
  ---------------------------------------------------------------------
  Blips, ambient stablehand peds, and the "press G to speak" interaction that
  opens the storefront. One module, registered on the lifecycle bus.
=====================================================================]]--

Stables = Stables or {}

local blips  = {}
local stalls = {}      -- [stableId] = { ped, groomHorse, cfg, groomThread }
local nearId = nil

local BRUSH      = GetHashKey('Interaction_Brush')
local BRUSH_PROP = GetHashKey('p_brushHorse02x')
local INTERACT   = GetHashKey('INTERACT')

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

-- Spawn a ped using the confirmed render/ground pattern. Grooming peds stay
-- unfrozen so they can play the brushing interaction.
local function spawnPed(model, x, y, z, h, freeze)
    local hash = GetHashKey(model)
    if not loadModel(hash) then Util.warn('ped model failed: ' .. tostring(model)); return nil end
    local found, gz = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
    if found then z = gz end
    local ped = CreatePed(hash, x, y, z, h or 0.0, false, true, true, true)
    local t = GetGameTimer()
    while not DoesEntityExist(ped) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(ped) then return nil end
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)   -- variation init → renders
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if freeze then FreezeEntityPosition(ped, true) end
    SetModelAsNoLongerNeeded(hash)
    return ped
end

-- A frozen, invincible ambient horse (same spawn pattern as the preview).
local function spawnHorseAt(model, pos)
    local hash = GetHashKey(model)
    if not loadModel(hash) then return nil end
    local x, y, z, h = pos[1], pos[2], pos[3], pos[4] or 0.0
    local found, gz = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
    if found then z = gz end
    local horse = CreatePed(hash, x, y, z, h, false, true, false, false)
    local t = GetGameTimer()
    while not DoesEntityExist(horse) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(horse) then return nil end
    Citizen.InvokeNative(0x283978A15512B2FE, horse, true)
    SetEntityVisible(horse, true, false)
    SetEntityInvincible(horse, true)
    FreezeEntityPosition(horse, true)
    SetBlockingOfNonTemporaryEvents(horse, true)
    SetModelAsNoLongerNeeded(hash)
    return horse
end

-- Pick a random model: the grooming.breeds list, else this stable's catalog.
local function rollBreed(stableId, cfg)
    local pool = cfg.breeds
    if not pool or #pool == 0 then
        pool = {}
        for _, h in ipairs(Catalog.horsesFor(stableId)) do pool[#pool + 1] = h.model end
    end
    if #pool == 0 then return nil end
    return pool[math.random(#pool)]
end

-- Keep the stablehand brushing the ambient horse, on a loop.
local function groomLoop(stall)
    if stall.groomThread then return end
    stall.groomThread = true
    CreateThread(function()
        while stall.cfg and stall.cfg.enabled and DoesEntityExist(stall.ped) do
            local horse = stall.groomHorse
            if horse and DoesEntityExist(horse) then
                TaskAnimalInteraction(stall.ped, horse, BRUSH, BRUSH_PROP, false)
                local t = GetGameTimer()
                repeat Wait(0) until HasAnimEventFired(stall.ped, INTERACT)
                    or (GetGameTimer() - t) > 8000
                    or not (stall.groomHorse and DoesEntityExist(stall.groomHorse))
                Wait(600)
            else
                Wait(500)
            end
        end
        stall.groomThread = nil
    end)
end

-- Swap the groomed horse for a fresh random breed. Called on world load and
-- again each time a player opens this stable.
function Stables.rerollGroom(stableId)
    local stall = stalls[stableId]
    if not (stall and stall.cfg and stall.cfg.enabled and DoesEntityExist(stall.ped)) then return end
    if not (stall.cfg.horsePos and #stall.cfg.horsePos >= 3) then return end
    local model = rollBreed(stableId, stall.cfg)
    if not model then return end
    if stall.groomHorse and DoesEntityExist(stall.groomHorse) then DeleteEntity(stall.groomHorse) end
    stall.groomHorse = spawnHorseAt(model, stall.cfg.horsePos)
    Util.log(('groom horse at %s -> %s'):format(stableId, model))
    groomLoop(stall)
end

local function makePed(id, stable)
    local p = stable.ped
    if not (p and p.enabled and p.coords and #p.coords >= 4) then return end
    local groom = p.grooming
    local grooming = groom and groom.enabled or false
    local ped = spawnPed(p.model, p.coords[1], p.coords[2], p.coords[3], p.coords[4], not grooming)
    if not ped then return end
    stalls[id] = { ped = ped, cfg = groom }
    if grooming then
        Stables.rerollGroom(id)                 -- spawn a random horse + start brushing
    elseif p.scenario then
        TaskStartScenarioInPlace(ped, GetHashKey(p.scenario), -1, true, false, false, false)
    end
end

function Stables.spawnAll()
    for id, stable in pairs(Config.Stables or {}) do
        makeBlip(stable)
        makePed(id, stable)
    end
    Util.log(('world presence up: %d blip(s), %d stall(s)'):format(#blips, Util.tableCount(stalls)))
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

-- On-screen interaction prompt — the proven RDR3 UiPrompt pattern (works this
-- session, unlike RegisterKeyMapping which only binds after a client restart).
local promptGroup = GetRandomIntInRange(0, 0xFFFFFF)
local openPrompt

local function setupPrompt()
    openPrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(openPrompt, 0x760A9C6F)
    UiPromptSetText(openPrompt, CreateVarString(10, 'LITERAL_STRING', 'Speak with the Stablehand'))
    UiPromptSetEnabled(openPrompt, true)
    UiPromptSetVisible(openPrompt, true)
    UiPromptSetStandardMode(openPrompt, true)
    UiPromptSetGroup(openPrompt, promptGroup, 0)
    UiPromptRegisterEnd(openPrompt)
end

-- Show the prompt while in range; a tap opens the storefront.
local function promptLoop()
    CreateThread(function()
        while true do
            local wait = 500
            local id = (not Storefront.isOpen()) and nearestInRange() or nil
            nearId = id
            if id then
                wait = 0
                UiPromptSetActiveGroupThisFrame(promptGroup,
                    CreateVarString(10, 'LITERAL_STRING', Config.Stables[id].label), 0, 0, 0, 0)
                if UiPromptHasStandardModeCompleted(openPrompt) then
                    Storefront.open(id)
                end
            end
            Wait(wait)
        end
    end)
end

-- Register on the lifecycle bus so the core starts us after config validation.
Registry.register({
    name = 'stables',
    onInit = function()
        Stables.spawnAll()
        setupPrompt()
        promptLoop()
    end,
})

-- Interact key (rebindable in the RedM settings menu) + a test command.
-- The on-screen prompt above is the primary way in. These are extras:
RegisterCommand('sovstable', function() Stables.interact() end, false)               -- typed command
RegisterKeyMapping('sovstable', 'Sovereign Stables: speak with stablehand', 'keyboard', 'G') -- rebindable key
RegisterCommand('stable', function() Stables.interact() end, false)                  -- alias
RegisterCommand('sovstableforce', function() Stables.forceNearest() end, false)      -- debug: ignores range

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, blip in ipairs(blips) do RemoveBlip(blip) end
    for _, stall in pairs(stalls) do
        if stall.ped and DoesEntityExist(stall.ped) then DeleteEntity(stall.ped) end
        if stall.groomHorse and DoesEntityExist(stall.groomHorse) then DeleteEntity(stall.groomHorse) end
    end
end)
