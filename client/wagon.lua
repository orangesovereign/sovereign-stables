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
local function place(model, x, y, z, heading, name)
    local hash = GetHashKey(model)
    if not loadModel(hash) then Util.err('wagon model failed: ' .. tostring(model)); return nil end

    local found, gz = GetGroundZAndNormalFor_3dCoord(x, y, z + 2.0)
    if found then z = gz end

    -- networked: other players should see your wagon
    local veh = CreateVehicle(hash, x, y, z, heading or 0.0, true, true, false)
    local t = GetGameTimer()
    while not DoesEntityExist(veh) and (GetGameTimer() - t) < 2000 do Wait(10) end
    if not DoesEntityExist(veh) then return nil end

    SetVehicleOnGroundProperly(veh)
    SetEntityVisible(veh, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
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

    local veh = place(data.model, spot[1], spot[2], spot[3], spot[4] or 0.0, data.name)
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
    active = { ent = veh, id = data.id, name = data.name, model = data.model, condition = cond }
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
