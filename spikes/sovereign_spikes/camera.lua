--[[=====================================================================
  SOVEREIGN SPIKES · ORBITAL PREVIEW CAMERA  (throwaway)
  ---------------------------------------------------------------------
  Proves a smooth camera that auto-centers on the previewed horse and
  orbits it — the storefront's signature look (L5).
  Create native: 0x40C23491CE83708E (CreateCamWithParams / DEFAULT_SCRIPTED_CAMERA)
  Then per-frame SetCamCoord + PointCamAtCoord to orbit + auto-aim.

  /spike_cam [radius] [degPerSec]   /spike_camstop
=====================================================================]]--

local cam = nil
local orbiting = false

local function stopCam()
    orbiting = false
    RenderScriptCams(false, true, 800, true, true, 0)
    if cam then DestroyCam(cam, true); cam = nil end
    FreezeEntityPosition(PlayerPedId(), false)
    print('^3[spike]^7 camera stopped')
end

RegisterCommand('spike_cam', function(_, args)
    local radius = tonumber(args[1] or '4.0') or 4.0
    local speed  = tonumber(args[2] or '25.0') or 25.0   -- degrees per second

    local horse = Spike.getOrSpawn()
    if not horse then return end

    local hc = GetEntityCoords(horse)
    local centerZ = hc.z + 0.7   -- aim a touch above ground for the horse's mass

    -- Create the scripted cam at a starting offset, then activate + render.
    cam = Citizen.InvokeNative(0x40C23491CE83708E, 'DEFAULT_SCRIPTED_CAMERA',
        hc.x + radius, hc.y, centerZ, 0.0, 0.0, 0.0, 45.0, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 800, true, true, 0)

    FreezeEntityPosition(PlayerPedId(), true)
    orbiting = true
    print(('^2[spike]^7 orbiting: radius=%.1f speed=%.0f deg/s — /spike_camstop to end'):format(radius, speed))

    CreateThread(function()
        local angle = 0.0
        local last = GetGameTimer()
        while orbiting and cam do
            local now = GetGameTimer()
            local dt = (now - last) / 1000.0
            last = now
            angle = (angle + speed * dt) % 360.0
            local rad = math.rad(angle)

            local cx = hc.x + radius * math.cos(rad)
            local cy = hc.y + radius * math.sin(rad)
            local cz = centerZ + 0.6   -- slight downward look

            SetCamCoord(cam, cx, cy, cz)
            PointCamAtCoord(cam, hc.x, hc.y, centerZ)
            Wait(0)
        end
    end)
end, false)

RegisterCommand('spike_camstop', function() stopCam() end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then stopCam() end
end)
