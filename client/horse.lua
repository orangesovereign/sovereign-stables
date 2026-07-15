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
    -- In FRONT of the player, facing them, so it's obviously arrived — then it
    -- trots the last few metres to you.
    local infront = GetOffsetFromEntityInWorldCoords(ped, 0.0, 8.0, 0.0)
    local horse = place(data.model, infront.x, infront.y, infront.z, GetEntityHeading(ped) + 180.0, data.name)
    if not horse then
        Util.err(('horse spawn FAILED for model %s'):format(tostring(data.model)))
        Bridge.notify('Your horse could not reach you.')
        return
    end

    active = { ent = horse, id = data.id, name = data.name, model = data.model }
    following = false

    -- Put its tack on [F1/F5]. The server hands us the stored components with
    -- the horse; the pieces are the player's, not the horse's, but what a given
    -- horse is WEARING is stored per horse.
    if data.components then
        local n = Components.applySet(horse, data.components)
        if n > 0 then Util.log(('applied %d tack piece(s) to horse #%s'):format(n, tostring(data.id))) end
    end

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

-- Send a horse trotting off and only then take it out of the world. Used by
-- dismiss, and by the flee-home command (D13) when that lands.
function Horse.fleeAndDespawn(ent)
    if not (ent and DoesEntityExist(ent)) then return end
    FreezeEntityPosition(ent, false)
    ClearPedTasks(ent)
    local away = GetOffsetFromEntityInWorldCoords(ent, 0.0, 40.0, 0.0)
    TaskGoStraightToCoord(ent, away.x, away.y, away.z, 3.0, -1, 0.0, 0.0)
    CreateThread(function()
        Wait(4500)                       -- let it get clear before it vanishes
        if DoesEntityExist(ent) then DeleteEntity(ent) end
    end)
end

function Horse.dismiss()
    if not (active and DoesEntityExist(active.ent)) then
        Bridge.notify('You have no horse out.')
        return
    end
    if isMounted() then Bridge.notify('Step down first.'); return end

    local ent = active.ent
    TriggerServerEvent(Events.ReportDismiss, active.id)
    Bridge.notify(('%s wanders off.'):format(active.name or 'Your horse'))

    -- Let go of it first, then let it walk away on its own before it goes.
    active, following = nil, false
    Horse.fleeAndDespawn(ent)
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

-- A ride we no longer own — sold, or handed to someone else. It must leave our
-- world or the old owner keeps riding a horse that is now legally theirs.
RegisterNetEvent(Events.SyncOwnedRides, function(data)
    local rel = data and data.released
    if not rel then return end
    if rel.kind == 'horse' and active and active.id == rel.id then
        local ent = active.ent
        active, following = nil, false
        Horse.fleeAndDespawn(ent)
    end
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
-- THE WHISTLE  [D11]
--------------------------------------------------------------------------------
-- We use RDR2's OWN whistle control rather than RegisterKeyMapping. H is
-- already the game's whistle key, so this works immediately — no client
-- restart, no clash with E (which is the mount key).
--     INPUT_WHISTLE           0x24978A28  H  (on foot)
--     INPUT_WHISTLE_HORSEBACK 0xE7EB9185  H  (mounted)
-- Owner ruling: a SHORT whistle (tap) tells the horse to follow / stop
-- following. A LONG whistle (hold) calls it to you from wherever it is.
--------------------------------------------------------------------------------
local WHISTLE_ONFOOT = 0x24978A28
local WHISTLE_MOUNT  = 0xE7EB9185
local LONG_WHISTLE_MS = 350      -- held at least this long = a long whistle

function Horse.shortWhistle()
    if not (active and DoesEntityExist(active.ent)) then
        Bridge.notify('No horse at hand to answer.')
        return
    end
    Horse.toggleFollow()
end

function Horse.longWhistle()
    Horse.summon()   -- spawns it if it's away, or calls it over if it's already out
end

CreateThread(function()
    local downAt = nil
    while true do
        local ctrl = IsPedOnMount(PlayerPedId()) and WHISTLE_MOUNT or WHISTLE_ONFOOT
        if IsControlJustPressed(0, ctrl) then
            downAt = GetGameTimer()
        elseif IsControlJustReleased(0, ctrl) and downAt then
            local held = GetGameTimer() - downAt
            downAt = nil
            Util.log(('whistle: %dms -> %s'):format(held, held >= LONG_WHISTLE_MS and 'LONG' or 'SHORT'))
            if held >= LONG_WHISTLE_MS then Horse.longWhistle() else Horse.shortWhistle() end
        end
        Wait(0)
    end
end)

-- Commands remain as a fallback / for testing. No RegisterKeyMapping: its
-- defaults only bind after a full CLIENT restart, and E is the mount key.
RegisterCommand('sovwhistle', function() Horse.longWhistle() end, false)
RegisterCommand('sovfollow', function() Horse.shortWhistle() end, false)
RegisterCommand('sovdismiss', function() Horse.dismiss() end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Horse.despawn(true) end
end)
