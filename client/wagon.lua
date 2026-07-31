--[[=====================================================================
  SOVEREIGN STABLES · YOUR WAGON IN THE FIELD  (client)
  ---------------------------------------------------------------------
  The wagon you actually drive: called out, dismissed, and its damage
  remembered [WG9]. The server decides IF a wagon may come out; this file
  only puts it there.

  A wagon is a VEHICLE, not a ped — so this does NOT reuse client/horse.lua's
  spawn. Different natives, different ownership calls. The ground-snap gotcha
  still applies though: RDR3 will happily place a vehicle in the air.

  ⚠️ OWNER RULING (1.4 ledger Q2): "No binding for wagon call. You must get
  your wagon from the STABLE ONLY." So there is deliberately no keybind AND
  no /sovwagon command — a wagon is collected in person, at a stable, full
  stop. `Config.Keys.callWagon` stays unbound. Do not add a summon command
  back; it was ruled out, not overlooked.

  ⚠️ AND IT ARRIVES AT THE STABLE'S YARD, not in front of you (1.4 V1/V2:
  a wagon spawned where the player stood appeared inside the building, in
  the air, wedged in the scenery). Each stable configures its own
  `retrieve.wagonPos` — outside, clear of the building.
=====================================================================]]--

Wagon = Wagon or {}

local active = nil    -- { ent, id, name, model }

local wagonBlip = nil

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and (GetGameTimer() - t) < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

--------------------------------------------------------------------------------
-- CONDITION  [WG9]  — modelled on bcc-wagons' Condition feature
--------------------------------------------------------------------------------
-- ⚠️ WHY THIS IS WEAR, NOT COMBAT DAMAGE. We proved via /sovwagonhp that RDR3
-- exposes no readable wagon health — every native returns a constant (body 0,
-- engine 150, petrol 1000, and GetEntityHealth 0 even on a FRESH wagon). Visual
-- damage (holes, missing wheels) can be neither read nor written. So a wagon can
-- never be made to look damaged, and "gradual damage from getting shot" is not
-- buildable in this engine.
--
-- Every shipping wagon script lives with this the same way, bcc-wagons included:
-- condition is an ABSTRACT 0-100 number the server owns. It DEGRADES AS THE WAGON
-- IS USED (bcc: -1 every 60s) and is restored by REPAIRING. Shooting the wagon
-- does nothing to it — that's the engine, not a design choice. (bcc read for the
-- MODEL only; it is GPL and no code was copied.)
--
-- The one real-damage signal RDR3 gives is IsEntityDead — false while you drive,
-- true when the wagon is genuinely destroyed. That's the OTHER path below: a
-- wrecked wagon drops to 0 and stays in place (owner ruling), needing repair.
--
-- Condition is never written to the entity: it's a stat + a "needs repairs"
-- notice, exactly like bcc. It does not affect handling.
local function cfg()      return Config.WagonCondition or Config.WagonDamage or {} end
local function condMax()  return cfg().maxHealth or 100 end

-- Diagnostic only — kept so the "no readable health" finding stays reproducible.
-- NOT used for condition. `/sovwagonhp` shows the natives are constants.
local function probeHealth(veh)
    if not (veh and DoesEntityExist(veh)) then return {} end
    local function try(fn, ...) if type(fn) ~= 'function' then return nil end
        local ok, v = pcall(fn, ...); return ok and v or nil end
    return {
        body   = try(GetVehicleBodyHealth, veh),   engine = try(GetVehicleEngineHealth, veh),
        petrol = try(GetVehiclePetrolTankHealth, veh),
        entity = try(GetEntityHealth, veh),         entityMax = try(GetEntityMaxHealth, veh),
    }
end

RegisterCommand('sovwagonhp', function()
    local veh = active and active.ent
    if not (veh and DoesEntityExist(veh)) then
        print('^3[sov_wagon]^7 no wagon out'); return
    end
    local p = probeHealth(veh)
    print('^2[sov_wagon]^7 native readings (all constants on a wagon — condition is a stored stat, not these):')
    print(('    body=%s engine=%s petrol=%s entity=%s (max %s) dead=%s')
        :format(tostring(p.body), tostring(p.engine), tostring(p.petrol),
                tostring(p.entity), tostring(p.entityMax), tostring(IsEntityDead(veh))))
    print(('    stored condition = %s / %d'):format(tostring(active and active.condition), condMax()))
    -- Entry diagnostics: if you STILL can't climb in, these say why.
    local ok, lock = pcall(function() return Citizen.InvokeNative(0xC867FD144F2469D3, veh, Citizen.ResultAsInteger()) end)  -- GET_VEHICLE_DOOR_LOCK_STATUS
    local haveCtrl = pcall(function() return Citizen.InvokeNative(0xB2E1E1FB4B0FEAAF, veh) end)   -- NETWORK_HAS_CONTROL_OF_ENTITY
    print(('    lockStatus=%s (1=unlocked, 2=locked)  hasNetControl=%s')
        :format(ok and tostring(lock) or '?', tostring(haveCtrl)))
    -- Draft diagnostics: is it a real draft rig, and does its team exist? A wagon
    -- with no team is why you can't drive and why the look randomises.
    local okD, isDraft = pcall(function() return Citizen.InvokeNative(0xEA44E97849E9F3DD, veh) end)  -- IS_DRAFT_VEHICLE
    local harnessed = 0
    for slot = 0, 5 do
        local okH, ped = pcall(function() return Citizen.InvokeNative(0xA8BA0BAE0173457B, veh, slot) end)  -- _GET_PED_IN_DRAFT_HARNESS
        if okH and ped and ped ~= 0 and DoesEntityExist(ped) then harnessed = harnessed + 1 end
    end
    print(('    isDraftVehicle=%s  harnessedHorses(0-5)=%d')
        :format(tostring(okD and isDraft), harnessed))
    -- Seat count for the model (0 would explain "no driver seat to take").
    local okS, seats = pcall(function()
        return Citizen.InvokeNative(0x9A578736FF3A17C3, GetHashKey(active.model), Citizen.ResultAsInteger())  -- GET_VEHICLE_MODEL_NUMBER_OF_SEATS
    end)
    local okF, free = pcall(function()
        return Citizen.InvokeNative(0xE052C1B1CAA4ECE4, veh, -1)  -- IS_VEHICLE_SEAT_FREE (driver)
    end)
    print(('    model=%s  modelSeats=%s  driverSeatFree=%s')
        :format(tostring(active.model), okS and tostring(seats) or '?', okF and tostring(free) or '?'))
end, false)

-- ⚠️ DIAGNOSTIC for "can't get on the wagon". Force-seats you in the driver's bench,
-- bypassing the walk-up prompt. If this seats you and you can DRIVE, the wagon is
-- fine and only the mount PROMPT (seat authorisation) is the problem. If it does
-- NOT seat you, or you can't drive after, the entity itself isn't a working rideable
-- vehicle — a different fix. Tells a prompt problem from an entity problem.
RegisterCommand('sovwagonsit', function()
    if not (active and active.ent and DoesEntityExist(active.ent)) then
        print('^3[sov_wagonsit]^7 no wagon out'); Bridge.notify('No wagon out.'); return
    end
    local ped, veh = PlayerPedId(), active.ent
    pcall(function() Citizen.InvokeNative(0xB69317BF5E782347, veh) end)  -- NETWORK_REQUEST_CONTROL_OF_ENTITY
    pcall(function() Citizen.InvokeNative(0xE2487779957FE897, veh, 528) end)  -- re-authorise seats first
    Wait(50)
    local okSeat = pcall(function() Citizen.InvokeNative(0xF75B0D629E1C063D, ped, veh, -1) end)  -- SET_PED_INTO_VEHICLE (driver)
    Wait(200)
    local inVeh = IsPedInVehicle(ped, veh, false)
    print(('^2[sov_wagonsit]^7 set-into-seat ok=%s  nowInVehicle=%s'):format(tostring(okSeat), tostring(inVeh)))
    Bridge.notify(inVeh and 'Seated — try to drive.' or 'Could not seat you on the wagon.')
end, false)

-- Is the wagon actually moving? Wear only accrues in use (bcc onlyWhileMoving).
local function isMoving(veh)
    local spd = Citizen.InvokeNative(0xFB6BA510A533DF81, veh, Citizen.ResultAsFloat()) -- GetEntitySpeed (m/s)
    return (spd or 0.0) > 0.5
end

--------------------------------------------------------------------------------
-- BLIP  — owner request 2026-07-15: a wagon blip that follows it once it's out.
--------------------------------------------------------------------------------
-- Uses R★'s OWN player-wagon blip style (`blip_mp_player_wagon`, 1612913921),
-- which already does the thing you'd otherwise hand-roll: its documented
-- conditional style HIDES the blip while you are riding the entity. Same trick
-- as the player horse blip. Don't invent a sprite — the game has one.
local function makeWagonBlip(veh, name)
    local cfg = Config.WagonBlip or {}
    if cfg.enabled == false then return end
    if not (veh and DoesEntityExist(veh)) then return end

    -- BlipAddForEntity — the blip tracks the entity, so no per-frame updating.
    -- ⚠️ UNVERIFIED IN THIS ENVIRONMENT: no local reference resource uses it, so
    -- it is wrapped. If it fails, the wagon still works — you just lose the blip.
    local ok, blip = pcall(function()
        return Citizen.InvokeNative(0x23F74C2FDA6E7C61, cfg.style or 1664425300, veh)
    end)
    if not ok or not blip or blip == 0 then
        Util.warn('wagon blip: BlipAddForEntity failed — wagon is fine, blip is not')
        return
    end
    pcall(function()
        Citizen.InvokeNative(0x74F74D3207ED525C, blip, cfg.sprite or 1612913921, 1)  -- SetBlipSprite
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, name or cfg.label or 'Wagon') -- SetBlipName
    end)
    wagonBlip = blip
    Util.log(('wagon blip created (%s)'):format(tostring(blip)))
end

local function removeWagonBlip()
    if wagonBlip then
        pcall(function() RemoveBlip(wagonBlip) end)
        wagonBlip = nil
    end
end

local function isDriving()
    local ped = PlayerPedId()
    if not active or not active.ent then return false end
    return IsPedInVehicle(ped, active.ent, false)
end

-- Put a wagon on the ground and hand it to the player.
--
-- ⚠️ THE DRIVE PROMPT WAS MISSING ONE NATIVE (owner 2026-07-28: "can't get on and
-- drive"). A wagon is an AITRANSPORT entity: its seats must be AUTHORISED with
-- _SET_TRANSPORT_USAGE_FLAGS or the game shows no mount prompt, no matter what else
-- you do. This is the native both shipping wagon scripts (bcc-wagons, rsg-wagonmaker)
-- use and this file never did — verified by reading their spawn paths for mechanism
-- only. The old ownership trio (considered / request-control / mission-entity) does
-- NOT grant seat access, which is why every previous attempt failed.
--
-- ⚠️ TEAM AUTO-CREATED AT SPAWN. A deferred team (bDontAutoCreateDraftAnimals=true)
-- came out with NO horses (owner 2026-07-28): "allow auto-creation" only permits the
-- team, it does not trigger it, so nothing ever made them. Both shipping scripts let
-- the team auto-create at spawn, which reliably hitches horses — so we do the same.
-- (Pinning appearance with a fixed seed needs the team to exist at seed-time; that's
-- a follow-up, tracked separately. A hitched team you can drive beats a tidy no-team.)
--
-- Every hash below is verified against the alloc8or RDR3 nativedb. No GTA V natives.
local function place(model, x, y, z, heading, name, id)
    local hash = GetHashKey(model)
    if not loadModel(hash) then Util.err('wagon model failed: ' .. tostring(model)); return nil end

    local found, gz = GetGroundZAndNormalFor_3dCoord(x, y, z + 2.0)
    if found then z = gz end

    -- _CREATE_DRAFT_VEHICLE, team AUTO-CREATED: params 6/7/8/9/10 =
    --   isNetwork(true), bScriptHostVeh(false), bDontAutoCreateDraftAnimals(FALSE=make
    --   the horses now), draftAnimalPopGroup(0=default breeds), p9(false).
    local veh = Citizen.InvokeNative(0x214651FB1DFEBA89, hash,
        x + 0.0, y + 0.0, z + 0.0, (heading or 0.0) + 0.0, true, false, false, 0, false,
        Citizen.ResultAsInteger())
    local t = GetGameTimer()
    while not DoesEntityExist(veh) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(veh) or veh == 0 then
        Util.err('draft wagon create failed for ' .. tostring(model)); return nil
    end

    -- Keep the auto-created team hitched to the wagon.
    pcall(function() Citizen.InvokeNative(0x87344305778E5415, veh, true) end)   -- _SET_DRAFT_VEHICLE_ALLOW_DRAFT_ANIMAL_AUTO_CREATION
    pcall(function() Citizen.InvokeNative(0x6090A031C69F384E, veh, false) end)  -- _SET_DRAFT_VEHICLE_ANIMALS_CAN_DETACH (stay hitched)

    Citizen.InvokeNative(0x7263332501E07F52, veh, true)  -- SET_VEHICLE_ON_GROUND_PROPERLY
    SetEntityVisible(veh, true, false)

    -- Register as a proper networked, player-owned entity (the rsg-wagonmaker path):
    -- register → wait for a live net id → claim ownership. This is what lets the
    -- wagon be driven and networked instead of a local ghost.
    pcall(function() NetworkRegisterEntityAsNetworked(veh) end)
    local nt = GetGameTimer()
    while GetGameTimer() - nt < 1500 do
        local netId = NetworkGetNetworkIdFromEntity(veh)
        if netId and netId ~= 0 and NetworkDoesEntityExistWithNetworkId(netId) then break end
        Wait(10)
    end
    pcall(function() Citizen.InvokeNative(0xD0E02AA618020D17, PlayerId(), veh) end)  -- _SET_PLAYER_OWNS_VEHICLE

    -- Keep it from being population-culled while parked (so put-away can still find
    -- it after you walk off). Not a seat native — safe alongside the transport flags.
    SetEntityAsMissionEntity(veh, true, true)

    -- ★ THE MOUNT ENABLER. 528 = TUF_ALLOW_DRIVER_ANYONE (1<<4) |
    --   TUF_ALLOW_PASSENGER_ANYONE (1<<9). Without this an AITRANSPORT wagon offers
    --   no drive prompt.
    -- ⚠️ RE-APPLIED over the first couple seconds, not just once: the draft team
    -- hitches ASYNCHRONOUSLY after spawn, and when it attaches it re-initialises the
    -- transport's seat config and WIPES this authorisation — so a single call at spawn
    -- was flaky ("sometimes can't get on"). Re-stamping it after the team settles makes
    -- entry reliable.
    local function authoriseSeats()
        if DoesEntityExist(veh) then
            pcall(function() Citizen.InvokeNative(0xE2487779957FE897, veh, 528) end)  -- _SET_TRANSPORT_USAGE_FLAGS
        end
    end
    authoriseSeats()
    CreateThread(function()
        for _ = 1, 8 do          -- ~2.4s of re-stamping (8 × 300ms) covers the team hitch
            Wait(300)
            if not DoesEntityExist(veh) then return end
            authoriseSeats()
        end
    end)

    SetModelAsNoLongerNeeded(hash)
    return veh
end

-- Bring the wagon out to the STABLE YARD. `data.stableId` says which stable it
-- was collected from; that stable's `retrieve.wagonPos` is where it appears.
function Wagon.spawn(data)
    if not data or not data.model then return end
    Wagon.despawn(true)

    local stable = data.stableId and Config.Stables[data.stableId]
    local spot = stable and stable.retrieve and stable.retrieve.wagonPos
    if not spot then
        -- Never fall back to spawning on the player: that is exactly what put a
        -- wagon inside the building. Refuse loudly so the config gets fixed.
        Util.err(('stable "%s" has no retrieve.wagonPos configured — refusing to spawn a wagon on top of the player')
            :format(tostring(data.stableId)))
        Bridge.notify('This stable has nowhere to bring a wagon out. Tell an admin.')
        return
    end

    local veh = place(data.model, spot[1], spot[2], spot[3], spot[4] or 0.0, data.name, data.id)
    if not veh then
        Util.err(('wagon spawn FAILED for model %s'):format(tostring(data.model)))
        Bridge.notify('Your wagon could not be brought round.')
        return
    end

    -- Livery / colour [WG4], when the tint table lands.
    if data.tint and SetVehicleTint then
        pcall(function() SetVehicleTint(veh, data.tint) end)
    end

    -- Condition is an ABSTRACT stat we carry on `active`, seeded from the stored
    -- value. It is NOT written to the entity (RDR3 has nowhere to put it) — it
    -- drives the wear loop, the "needs repairs" notice, and what we persist.
    local cond = tonumber(data.health)
    if cond == nil then cond = condMax() end
    -- stableId is kept so the "park at the spawn point, press R to put away" prompt
    -- knows WHERE the spawn point is (this stable's retrieve.wagonPos).
    active = { ent = veh, id = data.id, name = data.name, model = data.model,
               condition = cond, stableId = data.stableId }
    makeWagonBlip(veh, data.name)

    Bridge.notify(('%s is brought round.'):format(data.name or 'Your wagon'))
    if cond < (cfg().needsRepairBelow or 50) then
        Bridge.notify(('%s is in poor condition (%d%%) — it needs repairs.'):format(data.name or 'It', cond))
    end
    local c = GetEntityCoords(veh)
    Util.log(('wagon #%s (%s) spawned at %.1f, %.1f, %.1f (entity %s)'):format(
        tostring(data.id), tostring(data.model), c.x, c.y, c.z, tostring(veh)))
end

-- ⚠️ WE DO NOT POLL THE ENTITY FOR CONDITION. See the CONDITION MODEL note near
-- the top of the file: RDR3 exposes no readable wagon health, so condition is a
-- stored number the server owns, and the ONLY thing the client reports is the
-- one binary transition it CAN detect reliably — the wagon being wrecked
-- (IsEntityDead). There is no per-tick reportHealth any more; it only ever wrote
-- a constant.
function Wagon.despawn(silent)
    if active and active.ent and DoesEntityExist(active.ent) then
        DeleteEntity(active.ent)
    end
    removeWagonBlip()
    active = nil
    if not silent then Bridge.notify('Your wagon is put away.') end
end

function Wagon.active() return active end

-- Collect a wagon at a stable. Called only from the storefront (owner ruling
-- Q2: stable only). `stableId` is the stable you are standing in.
function Wagon.call(wagonId, stableId)
    if active and DoesEntityExist(active.ent) then
        Bridge.notify(('%s is already out.'):format(active.name or 'Your wagon'))
        return
    end
    TriggerServerEvent(Events.RequestCallWagon, wagonId, stableId)
end

function Wagon.dismiss()
    if not (active and DoesEntityExist(active.ent)) then
        Bridge.notify('You have no wagon out.')
        return
    end
    if isDriving() then Bridge.notify('Step down first.'); return end

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

-- Repair result — the server decided the level from our grade. Reflect it on the
-- live wagon so the wear loop and the "poor condition" notice update at once.
RegisterNetEvent(Events.WagonRepaired, function(res)
    res = res or {}
    if res.ok then
        if active and active.id == res.wagonId and res.condition then
            active.condition = res.condition
        end
        Bridge.notifyCard('complete', 'Stables', res.message or 'Repaired.')
    else
        Bridge.notify(res.message or 'It cannot be repaired.')
    end
end)

--------------------------------------------------------------------------------
-- Watchdog: catch the wagon being WRECKED. That's the one damage signal RDR3
-- gives us reliably (IsEntityDead), and it's binary — usable or wrecked.
--------------------------------------------------------------------------------
local reportedWreck = false   -- so we tell the server once, not every 2s

CreateThread(function()
    while true do
        if active and active.ent then
            if not DoesEntityExist(active.ent) then
                -- Streamed out / engine-cleaned. Drop the blip or it hangs on the
                -- map pointing at nothing. The condition is unchanged — a wagon
                -- that streamed out was not wrecked.
                removeWagonBlip()
                active, reportedWreck = nil, false
            elseif IsEntityDead(active.ent) and not reportedWreck then
                -- RENDERED UNUSABLE. Owner ruling 2026-07-15:
                --   • it hits 0% only now, not before
                --   • it must REMAIN IN PLACE, not despawn
                -- So we mark it wrecked server-side and STOP TRACKING it, but we
                -- do NOT delete it — the wreck sits in the world where it died.
                reportedWreck = true
                Util.log(('wagon #%s wrecked in place'):format(tostring(active.id)))
                TriggerServerEvent(Events.ReportWagonWrecked, active.id)
                Bridge.notify('Your wagon is wrecked — it will need repairs.')
                removeWagonBlip()
                active = nil          -- let go of it; the wreck stays put
            end
        end
        Wait(2000)
    end
end)

--------------------------------------------------------------------------------
-- WEAR  [WG9] — condition ticks down as the wagon is used (the bcc mechanic).
--   Every `decreaseSeconds` the wagon is out (and, if onlyWhileMoving, moving),
--   condition drops by `decreasePerTick`. The client owns the live value and
--   reports it up; the server clamps and stores. Client-authoritative wear is
--   low-stakes — worst case a wagon never wears — and the wagon only exists on
--   the client while it's out, so this is where it has to live.
--------------------------------------------------------------------------------
CreateThread(function()
    while true do
        local c = cfg()
        local every = math.max(5, tonumber(c.decreaseSeconds) or 60)
        Wait(every * 1000)

        if c.enabled ~= false and active and active.ent and DoesEntityExist(active.ent)
           and not IsEntityDead(active.ent) and active.condition ~= nil then
            local moving = (c.onlyWhileMoving == false) or isMoving(active.ent)
            if moving then
                local before = active.condition
                active.condition = math.max(0, before - (tonumber(c.decreasePerTick) or 1))
                if active.condition ~= before then
                    TriggerServerEvent(Events.ReportWagonHealth, active.id, active.condition)
                    -- Warn once as it crosses the threshold, not every tick.
                    local thr = c.needsRepairBelow or 50
                    if before >= thr and active.condition < thr then
                        Bridge.notify(('%s is wearing down (%d%%) — see a repair.')
                            :format(active.name or 'Your wagon', active.condition))
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- PUT AWAY AT THE SPAWN POINT — park the wagon where it came out, press R.
--------------------------------------------------------------------------------
-- Owner request 2026-07-28: "when you park your wagon in the wagon spawn point R
-- lets you put it back into the stable." So this is the mirror of collecting one:
-- drive it back to its stable's retrieve.wagonPos, and a prompt offers to stable
-- it. Uses the SAME UiPrompt pattern proven at the stable door (client/stables).
local function putCfg()     return Config.WagonPutAway or {} end
local function putControl() return putCfg().control or 0x0D55A0F0 end   -- R (INPUT_INTERACT_HORSE_FEED)
local putGroup  = GetRandomIntInRange(0, 0xFFFFFF)
local putPrompt

-- Is the out-wagon parked at (near) its own stable's spawn point, AND is the
-- player nearby? Both matter: the wagon has to be on the spot, and you have to be
-- with it — otherwise the prompt would hang on screen after you park and walk off.
local function atSpawnPoint()
    if not (active and active.ent and DoesEntityExist(active.ent)) then return false end
    local stable = active.stableId and Config.Stables[active.stableId]
    local spot = stable and stable.retrieve and stable.retrieve.wagonPos
    if not spot then return false end
    local r = (putCfg().distance or 6.0)
    local wc = GetEntityCoords(active.ent)
    local dx, dy, dz = wc.x - spot[1], wc.y - spot[2], wc.z - spot[3]
    if (dx*dx + dy*dy + dz*dz) > r*r then return false end            -- wagon on the spot?
    local p = GetEntityCoords(PlayerPedId())
    return #(p - wc) <= ((putCfg().playerDistance or 8.0))            -- and you're with it?
end

-- Put the wagon away. If you're sat on it, step down first, then stable it.
function Wagon.putAway()
    if not (active and DoesEntityExist(active.ent)) then return end
    local ped = PlayerPedId()
    if IsPedInVehicle(ped, active.ent, false) then
        local veh = active.ent
        pcall(function() TaskLeaveVehicle(ped, veh, 0) end)
        CreateThread(function()
            local t = GetGameTimer()
            while IsPedInVehicle(PlayerPedId(), veh, false) and GetGameTimer() - t < 3000 do Wait(50) end
            Wagon.dismiss()
        end)
    else
        Wagon.dismiss()
    end
end

local function setupPutPrompt()
    putPrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(putPrompt, putControl())
    UiPromptSetText(putPrompt, CreateVarString(10, 'LITERAL_STRING', 'Put Away Wagon'))
    UiPromptSetEnabled(putPrompt, true)      -- enable+visible ONCE, exactly like the
    UiPromptSetVisible(putPrompt, true)      -- stablehand prompt.
    UiPromptSetStandardMode(putPrompt, true)
    UiPromptSetGroup(putPrompt, putGroup, 0)
    UiPromptRegisterEnd(putPrompt)
end

local function putLoop()
    CreateThread(function()
        while true do
            local wait = 500
            if putCfg().enabled ~= false and putPrompt and atSpawnPoint() then
                wait = 0
                UiPromptSetActiveGroupThisFrame(putGroup,
                    CreateVarString(10, 'LITERAL_STRING', ('Stable %s'):format(active.name or 'Wagon')), 0, 0, 0, 0)
                if UiPromptHasStandardModeCompleted(putPrompt) then
                    Wagon.putAway()
                end
            end
            Wait(wait)
        end
    end)
end

--------------------------------------------------------------------------------
-- CARGO HOLD — open the wagon's storage from a prompt at its BACK, on foot.
--------------------------------------------------------------------------------
local function stoCfg()     return Config.WagonStorage or {} end
local stoGroup  = GetRandomIntInRange(0, 0xFFFFFF)
local stoPrompt

-- Standing on foot at the back of the out-wagon?
local function atWagonRear()
    if not (active and active.ent and DoesEntityExist(active.ent)) then return false end
    if IsPedInVehicle(PlayerPedId(), active.ent, false) then return false end   -- on foot only
    -- Forgiving zone: a hitched wagon is long, so a tight 2.4m rear pocket was easy
    -- to miss. Default 3.5m around the rear point.
    local rear = GetOffsetFromEntityInWorldCoords(active.ent, 0.0, -(stoCfg().rearOffset or 2.6), 0.0)
    return #(GetEntityCoords(PlayerPedId()) - rear) <= (stoCfg().distance or 3.5)
end

function Wagon.openStorage()
    if active and active.id then TriggerServerEvent(Events.RequestWagonInventory, active.id) end
end

local function setupStoPrompt()
    stoPrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(stoPrompt, stoCfg().control or 0x760A9C6F)
    UiPromptSetText(stoPrompt, CreateVarString(10, 'LITERAL_STRING', 'Open Storage'))
    UiPromptSetEnabled(stoPrompt, true)
    UiPromptSetVisible(stoPrompt, true)
    UiPromptSetStandardMode(stoPrompt, true)
    UiPromptSetGroup(stoPrompt, stoGroup, 0)
    UiPromptRegisterEnd(stoPrompt)
end

local function stoLoop()
    CreateThread(function()
        while true do
            local wait = 500
            if stoCfg().enabled ~= false and stoPrompt and atWagonRear() then
                wait = 0
                UiPromptSetActiveGroupThisFrame(stoGroup,
                    CreateVarString(10, 'LITERAL_STRING', ('%s Storage'):format(active.name or 'Wagon')), 0, 0, 0, 0)
                if UiPromptHasStandardModeCompleted(stoPrompt) then Wagon.openStorage() end
            end
            Wait(wait)
        end
    end)
end

-- ⚠️ Register BOTH prompts through the module lifecycle, EXACTLY like the proven
-- stablehand prompt (client/stables onInit). The core fires onInit after config
-- validation, when the UiPrompt natives are actually live; the old raw Wait(2000)
-- threads registered too early and never rendered (owner: "can't put it away or
-- access the inventory"). This is the one structural difference from working code.
Registry.register({
    name = 'wagon',
    onInit = function()
        setupPutPrompt(); putLoop()
        setupStoPrompt(); stoLoop()
    end,
})

-- Fallback / test path — open the out-wagon's storage from anywhere.
RegisterCommand('sovwagonstorage', function() Wagon.openStorage() end, false)

-- ⚠️ TEMPORARY diagnostic for "put away doesn't work". Prints WHY the prompt is
-- or isn't eligible; `/sovputaway now` stables the wagon directly (bypassing the
-- prompt) so we can tell a prompt-DISPLAY problem from an ACTION problem.
RegisterCommand('sovputaway', function(_, args)
    if not (active and active.ent and DoesEntityExist(active.ent)) then
        print('^3[sov_putaway]^7 no wagon out'); Bridge.notify('No wagon out.'); return
    end
    local stable = active.stableId and Config.Stables[active.stableId]
    local spot   = stable and stable.retrieve and stable.retrieve.wagonPos
    local wc = GetEntityCoords(active.ent)
    local wToSpot = spot and #(wc - vector3(spot[1], spot[2], spot[3])) or -1
    local pToW = #(GetEntityCoords(PlayerPedId()) - wc)
    print(('^2[sov_putaway]^7 stableId=%s  spotSet=%s  wagon->spot=%.1f (need<=%.1f)  you->wagon=%.1f (need<=%.1f)  eligible=%s')
        :format(tostring(active.stableId), tostring(spot ~= nil),
                wToSpot, (putCfg().distance or 6.0), pToW, (putCfg().playerDistance or 8.0),
                tostring(atSpawnPoint())))
    if args and args[1] == 'now' then Wagon.putAway() end
end, false)

-- NO /sovwagon command — ruled out (Q2): a wagon is collected at a stable.
-- Putting it away is still a field action, so that one stays.
RegisterCommand('sovwagonaway', function() Wagon.dismiss() end, false)

-- Repair the wagon you're standing with. The SERVER decides how far it goes from
-- your grade (field floor for anyone, 100% for a Wagon Maker). A stopgap command
-- until the repair item + prompt lands; a Wagon Maker repairing someone else's
-- wagon is the near-term extension (target a wagon, not just your own).
RegisterCommand('sovwagonfix', function()
    if not (active and active.id) then Bridge.notify('Bring your wagon round first.'); return end
    TriggerServerEvent(Events.RequestRepairWagon, active.id)
end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Wagon.despawn(true) end
end)
