--[[=====================================================================
  SOVEREIGN STABLES · ORBITAL CAMERA  (client)
  ---------------------------------------------------------------------
  The storefront's signature preview camera (spike-confirmed, L5). Holds the
  horse dead-centre and orbits it. Because the NUI owns the mouse while open,
  drag-to-orbit and scroll-to-zoom are driven from the NUI via Camera.nudge /
  Camera.zoom; when the player isn't dragging, it drifts on its own.
=====================================================================]]--

Camera = Camera or {}

local cam
local active   = false
local target   = { x = 0.0, y = 0.0, z = 0.0 }
local orbit    = { angle = 210.0, radius = 4.2, height = 0.9 }
local limits   = { radius = { 2.4, 7.5 }, height = { -0.4, 2.2 } }
local autoDrift = 8.0            -- degrees/sec when idle
local idleAfter = 2.5            -- seconds of no input before drifting resumes
local lastInput = 0.0

local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end

local function place()
    if not cam then return end
    local rad = math.rad(orbit.angle)
    local ex = target.x + orbit.radius * math.cos(rad)
    local ey = target.y + orbit.radius * math.sin(rad)
    local ez = target.z + orbit.height
    SetCamCoord(cam, ex, ey, ez)
    PointCamAtCoord(cam, target.x, target.y, target.z)
end

-- centre = { x, y, z } (aim point, usually the horse's mid-body)
function Camera.start(centre, fov)
    Camera.stop()
    target.x, target.y, target.z = centre[1], centre[2], centre[3]
    cam = Citizen.InvokeNative(0x40C23491CE83708E, 'DEFAULT_SCRIPTED_CAMERA',
        target.x, target.y, target.z, 0.0, 0.0, 0.0, fov or 42.0, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true, 0)
    active = true
    place()

    CreateThread(function()
        local last = GetGameTimer()
        while active and cam do
            local now = GetGameTimer()
            local dt = (now - last) / 1000.0; last = now
            if (now / 1000.0) - lastInput > idleAfter then
                orbit.angle = (orbit.angle + autoDrift * dt) % 360.0
                place()
            end
            Wait(0)
        end
    end)
end

-- Retarget/reposition when the selected horse changes.
-- `radius` is optional: a wagon needs the camera further back than a horse or
-- it fills the frame. Omit it to keep whatever distance the player has zoomed
-- to — retargeting between horses must not yank their zoom back.
function Camera.retarget(centre, radius)
    target.x, target.y, target.z = centre[1], centre[2], centre[3]
    if radius then
        -- Widen the zoom-out limit if this subject needs it, or the clamp below
        -- would quietly refuse the very distance we just asked for.
        if radius > limits.radius[2] then limits.radius[2] = radius end
        orbit.radius = clamp(radius, limits.radius[1], limits.radius[2])
    end
    place()
end

-- From the NUI: drag delta in pixels.
function Camera.nudge(dx, dy)
    lastInput = GetGameTimer() / 1000.0
    orbit.angle = (orbit.angle - dx * 0.35) % 360.0
    orbit.height = clamp(orbit.height + dy * 0.01, limits.height[1], limits.height[2])
    place()
end

-- From the NUI: wheel delta (negative = zoom in).
function Camera.zoom(delta)
    lastInput = GetGameTimer() / 1000.0
    orbit.radius = clamp(orbit.radius + delta * 0.0016, limits.radius[1], limits.radius[2])
    place()
end

function Camera.stop()
    active = false
    RenderScriptCams(false, true, 400, true, true, 0)
    if cam then DestroyCam(cam, true); cam = nil end
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Camera.stop() end
end)
