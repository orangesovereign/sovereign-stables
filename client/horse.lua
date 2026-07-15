--[[=====================================================================
  SOVEREIGN STABLES · YOUR HORSE IN THE FIELD  (client)
  ---------------------------------------------------------------------
  The horse you actually ride: whistled out, follows, gets dismissed, comes
  back if it strays, and reports its death. The server decides IF a horse may
  come out (ownership, whistle rule, cooldown); this file only puts it there.

  Spawn uses the Phase 1 spike pattern (ground-snap + variation-init) — a raw
  CreatePed horse is invisible and airborne without it.
=====================================================================]]--

Horse = Horse or {}

local active    = nil     -- { ent, id, name, model }
local following = false

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and (GetGameTimer() - t) < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function isMounted()
    return IsPedOnMount(PlayerPedId()) or (active and GetMount and GetMount(PlayerPedId()) == active.ent)
end

-- Place the horse at a spot and make it the player's ride.
local function place(model, x, y, z, heading, name)
    local hash = GetHashKey(model)
    if not loadModel(hash) then Util.err('horse model failed: ' .. tostring(model)); return nil end

    local found, gz = GetGroundZAndNormalFor_3dCoord(x, y, z + 2.0)
    if found then z = gz end

    -- networked: other players should see your horse
    local horse = CreatePed(hash, x, y, z, heading or 0.0, true, true, false, false)
    local t = GetGameTimer()
    while not DoesEntityExist(horse) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(horse) then return nil end

    Citizen.InvokeNative(0x283978A15512B2FE, horse, true)   -- variation init → renders
    SetEntityVisible(horse, true, false)
    SetModelAsNoLongerNeeded(hash)

    -- Make it behave like a player's own mount (vorp_stables-proven natives).
    Citizen.InvokeNative(0xADB3F206518799E8, horse, GetHashKey('PLAYER'))       -- SetPedRelationshipGroup
    Citizen.InvokeNative(0xB8B6430EAD2D2437, horse, GetHashKey('PLAYER_HORSE')) -- SetPedPersonality
    Citizen.InvokeNative(0x931B241409216C1F, PlayerPedId(), horse, false)       -- owns animal (still rideable)
    SetPedPromptName(horse, name or 'Horse')
    if Config.UI and Config.UI.showNameTags == false then
        -- tags off: nothing else to do, the prompt name simply isn't shown by config
    end
    return horse
end

-- Bring the horse out behind the player and send it to them.
function Horse.spawn(data)
    if not data or not data.model then return end
    Horse.despawn(true)

    local ped = PlayerPedId()
    local behind = GetOffsetFromEntityInWorldCoords(ped, 0.0, -12.0, 0.0)
    local horse = place(data.model, behind.x, behind.y, behind.z, GetEntityHeading(ped), data.name)
    if not horse then
        Util.err(('horse spawn FAILED for model %s'):format(tostring(data.model)))
        Bridge.notify('Your horse could not reach you.')
        return
    end

    active = { ent = horse, id = data.id, name = data.name, model = data.model }
    following = false

    -- Trot over to the player rather than appearing on top of them.
    TaskGoToEntity(horse, ped, -1, 3.0, 3.0, 1073741824, 0)
    Bridge.notify(('%s answers your whistle.'):format(data.name or 'Your horse'))
    local hc = GetEntityCoords(horse)
    Util.log(('horse #%s (%s) spawned at %.1f, %.1f, %.1f (entity %s)'):format(
        tostring(data.id), tostring(data.model), hc.x, hc.y, hc.z, tostring(horse)))
end

function Horse.despawn(silent)
    if active and active.ent and DoesEntityExist(active.ent) then
        DeleteEntity(active.ent)
    end
    active, following = nil, false
    if not silent then Bridge.notify('Your horse wanders off.') end
end

function Horse.active() return active end

-- Whistle for your default horse. Server decides if it may come.
function Horse.summon()
    if active and DoesEntityExist(active.ent) then
        -- already out: call it over instead of spawning a second one
        Util.log('whistle: horse already out, calling it over')
        TaskGoToEntity(active.ent, PlayerPedId(), -1, 3.0, 3.0, 1073741824, 0)
        Bridge.notify(('%s comes to you.'):format(active.name or 'Your horse'))
        return
    end
    Util.log('whistle: asking the server for your default horse')
    TriggerServerEvent(Events.RequestSummon)
end

function Horse.toggleFollow()
    if not (active and DoesEntityExist(active.ent)) then
        Bridge.notify('You have no horse out.')
        return
    end
    following = not following
    if following then
        TaskFollowToOffsetOfEntity(active.ent, PlayerPedId(), 0.0, -2.0, 0.0, 2.0, -1, 2.0, true)
        Bridge.notify(Util.L('horse_following'))
    else
        ClearPedTasks(active.ent)
        Bridge.notify(Util.L('horse_staying'))
    end
end

function Horse.dismiss()
    if not (active and DoesEntityExist(active.ent)) then
        Bridge.notify('You have no horse out.')
        return
    end
    if isMounted() then Bridge.notify('Step down first.'); return end
    TriggerServerEvent(Events.ReportDismiss, active.id)
    Horse.despawn()
end

--------------------------------------------------------------------------------
-- Server → client
--------------------------------------------------------------------------------
RegisterNetEvent(Events.SummonResult, function(res)
    res = res or {}
    Util.log(('summon result: ok=%s msg=%s horse=%s'):format(
        tostring(res.ok), tostring(res.message), res.horse and tostring(res.horse.model) or 'nil'))
    if not res.ok then
        Bridge.notify(res.message or 'No horse answers.')
        return
    end
    Horse.spawn(res.horse)
end)

--------------------------------------------------------------------------------
-- Watchdog: death reporting + auto-recall of a strayed horse
--------------------------------------------------------------------------------
CreateThread(function()
    while true do
        if active and active.ent then
            if not DoesEntityExist(active.ent) then
                active, following = nil, false
            elseif IsEntityDead(active.ent) then
                Util.log(('horse #%s died'):format(tostring(active.id)))
                TriggerServerEvent(Events.ReportDeath, active.id)
                Horse.despawn(true)
            else
                local maxD = (Config.Summon and Config.Summon.autoRecallDistance) or 200.0
                local d = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(active.ent))
                if d > maxD and not isMounted() then
                    -- Too far and nobody's on it: quietly bring it back.
                    local data = { id = active.id, name = active.name, model = active.model }
                    Horse.despawn(true)
                    Horse.spawn(data)
                end
            end
        end
        Wait(2000)
    end
end)

--------------------------------------------------------------------------------
-- Keys & commands
-- NOTE: RegisterKeyMapping defaults only bind after a full CLIENT restart —
-- the commands always work immediately.
--------------------------------------------------------------------------------
RegisterCommand('sovwhistle', function() Horse.summon() end, false)
RegisterKeyMapping('sovwhistle', 'Sovereign Stables: whistle for your horse', 'keyboard',
    (Config.Keys and Config.Keys.callHorse) or 'H')

RegisterCommand('sovfollow', function() Horse.toggleFollow() end, false)
RegisterKeyMapping('sovfollow', 'Sovereign Stables: horse follow / stay', 'keyboard',
    (Config.Keys and Config.Keys.follow) or 'E')

RegisterCommand('sovdismiss', function() Horse.dismiss() end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Horse.despawn(true) end
end)
