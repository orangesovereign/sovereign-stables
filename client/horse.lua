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

--------------------------------------------------------------------------------
-- NO-SPAWN ZONES (owner 2026-07-28): "Buildings and Stables are no spawn zones."
--------------------------------------------------------------------------------
-- A whistled horse normally appears 4m in front of you. Indoors or on top of a
-- stable that drops it through a wall or into the furniture. So if the natural
-- spot is in a no-spawn zone, we search OUTWARD for clear open ground and bring
-- the horse out there instead — it arrives outside, and you walk to it.
-- GET_INTERIOR_AT_COORDS asks "is this point inside a building?" — returns an
-- interior handle, 0 = outdoors. This is the RDR3 hash (alloc8or nativedb); the
-- GTA V hash is different and would silently no-op, letting horses spawn indoors.
local INTERIOR_AT_COORDS = 0xCDD36C9E5C469070

-- Within the no-spawn radius of any stable?
local function nearStable(x, y, z)
    local r = (Config.Summon and Config.Summon.noSpawnStableRadius) or 15.0
    if r <= 0 then return false end
    for _, s in pairs(Config.Stables or {}) do
        local p = (s.prompt and s.prompt.coords) or (s.ped and s.ped.coords)
        if p then
            local dx, dy, dz = x - p[1], y - p[2], z - (p[3] or z)
            if (dx*dx + dy*dy + dz*dz) <= r*r then return true end
        end
    end
    return false
end

-- Inside a building? interior id 0 = outdoors. Wrapped: if the native is
-- unavailable the stable check still protects the common case.
local function inInterior(x, y, z)
    if type(INTERIOR_AT_COORDS) ~= 'number' then return false end
    local ok, id = pcall(function()
        return Citizen.InvokeNative(INTERIOR_AT_COORDS, x + 0.0, y + 0.0, z + 0.0, Citizen.ResultAsInteger())
    end)
    return ok and id and id ~= 0 or false
end

local function isNoSpawn(x, y, z)
    return nearStable(x, y, z) or inInterior(x, y, z)
end

-- Where should the horse come out? The natural spot unless it's a no-spawn zone,
-- in which case the first clear open-ground point found by spiralling outward.
local function chooseSpawnPos(ped)
    local h = GetEntityHeading(ped) + 180.0
    local infront = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.0)
    if not isNoSpawn(infront.x, infront.y, infront.z) then
        return infront.x, infront.y, infront.z, h, false
    end

    local pc = GetEntityCoords(ped)
    for _, dist in ipairs({ 8.0, 12.0, 16.0, 22.0, 30.0 }) do
        for i = 0, 7 do
            local ang = (i / 8) * math.pi * 2
            local x = pc.x + math.cos(ang) * dist
            local y = pc.y + math.sin(ang) * dist
            local found, gz = GetGroundZAndNormalFor_3dCoord(x, y, pc.z + 2.0)
            local z = found and gz or pc.z
            if not isNoSpawn(x, y, z) then
                return x, y, z, h, true
            end
        end
    end
    -- Nothing clearly outside within reach — fall back rather than fail to summon.
    Util.warn('no clear spot outside the no-spawn zone; bringing the horse to the default spot')
    return infront.x, infront.y, infront.z, h, false
end

-- Bring the horse out near the player (outside any building/stable).
function Horse.spawn(data)
    if not data or not data.model then return end
    Horse.despawn(true)

    local ped = PlayerPedId()
    -- Normally 4m in front, facing you, and it STAYS THERE (1.4 ledger C1 — the
    -- horse arriving is the moment, not the approach). If that spot is inside a
    -- building or on a stable, chooseSpawnPos moves it to clear ground outside.
    local sx, sy, sz, sh, relocated = chooseSpawnPos(ped)
    local horse = place(data.model, sx, sy, sz, sh, data.name)
    if not horse then
        Util.err(('horse spawn FAILED for model %s'):format(tostring(data.model)))
        Bridge.notify('Your horse could not reach you.')
        return
    end

    active = { ent = horse, id = data.id, name = data.name, model = data.model }
    following = false

    -- Hand the server this horse's NET ID so it can delete the horse itself if
    -- you disconnect. Horse.despawn below can't cover that case: a dropped
    -- player runs no client code at all, so the cleanup has to live somewhere
    -- that is still running. See server/horses.lua.
    -- The model goes with it: net ids get recycled, so the server checks the
    -- entity is still THIS horse before deleting anything.
    local netId = NetworkGetNetworkIdFromEntity(horse)
    if netId and netId ~= 0 then
        TriggerServerEvent(Events.ReportHorseEntity, netId, GetEntityModel(horse))
    end

    -- Put its tack on [F1/F5]. The server hands us the stored components with
    -- the horse; the pieces are the player's, not the horse's, but what a given
    -- horse is WEARING is stored per horse.
    if data.components then
        local n = Components.applySet(horse, data.components)
        if n > 0 then Util.log(('applied %d tack piece(s) to horse #%s'):format(n, tostring(data.id))) end
    end

    -- Care state [C]: dirt on the coat, a warning if it's hungry/thirsty, and the
    -- penalty if it's critical. The server sent the current card with the horse.
    if Metabolism and Metabolism.onHorseOut then
        pcall(Metabolism.onHorseOut, horse, data.id, data.care)
    end

    -- It waits. No approach task — see above. If we had to move it out of a
    -- building/stable, say so, so a horse appearing 20m away doesn't read as a bug.
    if relocated then
        Bridge.notify(('%s waits for you outside.'):format(data.name or 'Your horse'))
    else
        Bridge.notify(('%s answers your whistle.'):format(data.name or 'Your horse'))
    end
    local hc = GetEntityCoords(horse)
    Util.log(('horse #%s (%s) spawned at %.1f, %.1f, %.1f (entity %s)'):format(
        tostring(data.id), tostring(data.model), hc.x, hc.y, hc.z, tostring(horse)))
end

function Horse.despawn(silent)
    if Metabolism and Metabolism.onHorseAway then pcall(Metabolism.onHorseAway) end
    if active and active.ent and DoesEntityExist(active.ent) then
        DeleteEntity(active.ent)
    end
    active, following = nil, false
    -- Nothing out any more: retract the net id so a later disconnect doesn't
    -- have the server hunting an entity that's already gone.
    TriggerServerEvent(Events.ReportHorseEntity, nil)
    if not silent then Bridge.notify('Your horse wanders off.') end
end

function Horse.active() return active end

-- Set when an AUTO summon (login) is in flight, so a "you keep no horse" answer
-- for a player who owns none doesn't pop a chip on every login.
Horse.suppressSummonFail = false

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

-- Send a horse WALKING off, and only then take it out of the world.
--
-- Speed matters here: at 3.0 it sprinted away like it had been startled (1.4
-- ledger C2), which reads as fleeing, not as being dismissed. A dismissed
-- horse is not frightened of you — it just wanders off. 1.0 is a walk.
--
-- D13 (flee-home, F on lock-on) is the OPPOSITE case and will want the fast
-- version, so the speed is a parameter rather than baked in.
local WALK_AWAY, BOLT_AWAY = 1.0, 3.0

function Horse.fleeAndDespawn(ent, speed)
    if not (ent and DoesEntityExist(ent)) then return end
    FreezeEntityPosition(ent, false)
    ClearPedTasks(ent)
    local away = GetOffsetFromEntityInWorldCoords(ent, 0.0, 40.0, 0.0)
    TaskGoStraightToCoord(ent, away.x, away.y, away.z, speed or WALK_AWAY, -1, 0.0, 0.0)
    CreateThread(function()
        Wait(4000)                       -- long enough to turn and get clear
        if DoesEntityExist(ent) then DeleteEntity(ent) end
    end)
end
Horse.WALK_AWAY, Horse.BOLT_AWAY = WALK_AWAY, BOLT_AWAY

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
    -- Retract the net id here too: this path deletes the horse itself rather
    -- than going through Horse.despawn, so without this the server would keep
    -- holding a net id for a horse that is already gone.
    TriggerServerEvent(Events.ReportHorseEntity, nil)
    Horse.fleeAndDespawn(ent)
end

--------------------------------------------------------------------------------
-- Server → client
--------------------------------------------------------------------------------
RegisterNetEvent(Events.SummonResult, function(res)
    res = res or {}
    Util.log(('summon result: ok=%s msg=%s horse=%s'):format(
        tostring(res.ok), tostring(res.message), res.horse and tostring(res.horse.model) or 'nil'))
    local suppress = Horse.suppressSummonFail
    Horse.suppressSummonFail = false
    if not res.ok then
        if not suppress then Bridge.notify(res.message or 'No horse answers.') end
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
-- ⚠️ TELEPORTING IS NOT STRAYING, AND THEY NEED OPPOSITE ANSWERS.
-- (Owner ruling 2026-07-27: "when teleporting away from the area horse should
-- also despawn.")
--
-- The strayed-horse case below RE-SPAWNS the horse beside you, which is right
-- when it has wandered off — but applied to a teleport it means your horse
-- follows you across the map and pops into existence wherever you land. Same
-- distance check, wrong answer.
--
-- We can tell them apart by watching the PLAYER rather than the horse: nobody
-- covers 100 metres in two seconds on foot, so a jump that large is a teleport.
-- A teleport leaves the horse behind, exactly as if you had walked away and left
-- it — and since you are now nowhere near it, it goes.
local lastPos = nil

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        -- Seed on the first pass, or a resource restart reads as a teleport.
        local jumped = lastPos and (#(pos - lastPos) > ((Config.Summon and Config.Summon.teleportJumpDistance) or 100.0))
        lastPos = pos

        if active and active.ent then
            if not DoesEntityExist(active.ent) then
                active, following = nil, false
            elseif IsEntityDead(active.ent) then
                Util.log(('horse #%s died'):format(tostring(active.id)))
                TriggerServerEvent(Events.ReportDeath, active.id)
                Horse.despawn(true)
            elseif jumped and not isMounted() then
                -- You teleported and left it behind. Mounted is excluded on
                -- purpose: the horse came WITH you, so there is nothing stranded.
                Util.log(('horse #%s left behind by a teleport — despawning'):format(tostring(active.id)))
                Horse.despawn(true)
                Bridge.notify('Your horse is no longer with you.')
            else
                local maxD = (Config.Summon and Config.Summon.autoRecallDistance) or 200.0
                local d = #(pos - GetEntityCoords(active.ent))
                if d > maxD and not isMounted() then
                    -- Strayed, not teleported: quietly bring it back.
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

-- ⚠️ DO NOT bind a RegisterKeyMapping to H. Tried it R11, it broke everything:
-- H is already the game's own whistle key, so RedM routes the press to the GAME
-- control and our command never fires — H just played the whistle sound and did
-- nothing else, taking follow/recall (and the horse ever coming out, hence Flee)
-- down with it.
--
-- THE LOGIN PROBLEM (owner: "Holding H does not work after logging in; I want to
-- whistle it out without visiting a stable"). RDR2 keeps the native whistle
-- control (INPUT_WHISTLE) INERT until the game has a registered horse — which
-- only happens once you've fetched one at a stable. So at login, holding H does
-- nothing.
--
-- The fix without auto-spawning and without touching H: INPUT_INTERACT_OPTION2
-- (0x84543902) also sits on the H key but is NOT gated on having a horse, so it
-- fires from login. We listen on it as a SECOND path, but ONLY while no horse is
-- out — so once you have one, normal follow/recall runs purely off the real
-- whistle control and this never interferes.
local H_LOGIN = 0x84543902   -- INPUT_INTERACT_OPTION2 (H) — the ungated login path

-- TASK_WHISTLE_ANIM plays the whistle GESTURE + SOUND together (RDR3-verified,
-- alloc8or). The native whistle control makes this itself when a horse is
-- registered — but on the login path it's inert and silent, so we play it by
-- hand there, matching the game's own short/long whistle.
local WHISTLE_ANIM  = 0xD6401A1B2F63BED6
local WHISTLE_SHORT = 0x659F956D   -- WHISTLEHORSESHORT
local WHISTLE_LONG  = 0x33D023F4   -- WHISTLEHORSELONG

CreateThread(function()
    local downAt = nil
    while true do
        local mounted = IsPedOnMount(PlayerPedId())
        local ctrl = mounted and WHISTLE_MOUNT or WHISTLE_ONFOOT
        -- The login fallback only matters when nothing is out and you're on foot:
        -- that's the one window where the native whistle control is dead.
        local useLogin = (not active) and (not mounted)

        if useLogin then
            -- LOGIN PATH — fire on PRESS, not release, so it's fluid. The native
            -- whistle is inert here (no registered horse), so it plays no sound of
            -- its own; we play the whistle the instant you press H and summon in the
            -- same beat. Tap or hold doesn't matter: with nothing out, the only
            -- thing to do is call your horse.
            if IsControlJustPressed(0, H_LOGIN) then
                pcall(function() Citizen.InvokeNative(WHISTLE_ANIM, PlayerPedId(), WHISTLE_LONG, 0) end)
                Horse.longWhistle()
            end
            downAt = nil
        else
            -- NATIVE PATH — a horse is out (or you're mounted): the game plays its
            -- own whistle sound, and here tap vs hold means follow vs recall.
            if IsControlJustPressed(0, ctrl) then
                downAt = GetGameTimer()
            elseif IsControlJustReleased(0, ctrl) and downAt then
                local held = GetGameTimer() - downAt
                downAt = nil
                Util.log(('whistle: %dms -> %s'):format(held, held >= LONG_WHISTLE_MS and 'LONG' or 'SHORT'))
                if held >= LONG_WHISTLE_MS then Horse.longWhistle() else Horse.shortWhistle() end
            end
        end
        Wait(0)
    end
end)

--------------------------------------------------------------------------------
-- FLEE  [D13] — send the horse home
--------------------------------------------------------------------------------
-- The owner reported "the flee option in the horse menu does not work." We build
-- no horse menu, so that's RDR2's OWN Flee command — INPUT_HORSE_COMMAND_FLEE
-- (F, in the HorseCommands / lock-on context: look at the horse, focus, F). We
-- hook the control and make it dismiss the horse home — the same
-- walk-off-then-despawn as /sovdismiss. (PHASE1_SPIKE_FINDINGS flagged this
-- control as "exactly D13".)
--
-- NOTE: we do NOT force the control context — doing so disables most other
-- inputs. So F registers here only when the game is already in the horse-command
-- context (aiming at / locked onto the horse), which is the intended flow. The
-- /sovflee command below is the guaranteed path.
local FLEE_CTRL = 0x4216AF06   -- INPUT_HORSE_COMMAND_FLEE

CreateThread(function()
    while true do
        if active and DoesEntityExist(active.ent) then
            if IsControlJustPressed(0, FLEE_CTRL) then
                Horse.dismiss()   -- walks off, then despawns home
            end
            Wait(0)
        else
            Wait(400)   -- no horse out — idle cheaply
        end
    end
end)

-- Commands remain as a fallback / for testing. No RegisterKeyMapping: its
-- defaults only bind after a full CLIENT restart, and E is the mount key.
RegisterCommand('sovwhistle', function() Horse.longWhistle() end, false)
RegisterCommand('sovfollow', function() Horse.shortWhistle() end, false)
RegisterCommand('sovdismiss', function() Horse.dismiss() end, false)
RegisterCommand('sovflee', function() Horse.dismiss() end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Horse.despawn(true) end
end)
