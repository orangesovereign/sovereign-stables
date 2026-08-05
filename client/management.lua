--[[=====================================================================
  SOVEREIGN STABLES · MANAGEMENT PANEL  (client)
  ---------------------------------------------------------------------
  Opens the role-scoped stable-business panel. The SERVER decides your role at
  the stable and sends only what you may see (hidden, not greyed), so the client
  just renders the payload. Entry: /sovmanage while standing at a stable (a
  prompt at the counter comes later).
=====================================================================]]--

Management = Management or {}

local currentStable = nil   -- the stable this panel is bound to (for action/section requests)

RegisterNetEvent(Events.ManagementData, function(payload)
    if type(payload) ~= 'table' then return end
    currentStable = payload.stableId
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'manage:open', panel = payload })
end)

-- One book section's data (Training/Staff/Breeding/...) — pushed on nav.
RegisterNetEvent(Events.ManageSectionData, function(payload)
    if type(payload) ~= 'table' then return end
    SendNUIMessage({ action = 'manage:section', section = payload.section, role = payload.role, data = payload.data })
end)

-- Outcome of a management action (toast + the NUI refreshes the section).
RegisterNetEvent(Events.ManageActionResult, function(res)
    SendNUIMessage({ action = 'manage:result', result = res or {} })
end)

RegisterNUICallback('manageClose', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- The book asks for a section's data as the user navigates to it.
RegisterNUICallback('requestSection', function(data, cb)
    if currentStable and data and data.section then
        TriggerServerEvent(Events.RequestManageSection, currentStable, data.section)
    end
    cb('ok')
end)

-- A book action (hire/fire/duty, setPhase/markReady/return, funds, settings, ...).
RegisterNUICallback('manageAction', function(data, cb)
    if currentStable and data and data.action then
        TriggerServerEvent(Events.RequestManageAction, currentStable, data.action, data.payload or {})
    end
    cb('ok')
end)

-- Nearest stable to the player, computed CLIENT-side (reliable coords, unlike a
-- server GetEntityCoords which lags/reads 0,0,0). nil if not near any.
local function nearestStable(range)
    local pc = GetEntityCoords(PlayerPedId())
    local best, bestD = nil, range or 30.0
    for id, s in pairs(Config.Stables or {}) do
        local c = (s.prompt and s.prompt.coords) or (s.ped and s.ped.coords)
        if c then
            local d = #(pc - vector3(c[1] + 0.0, c[2] + 0.0, c[3] + 0.0))
            if d < bestD then best, bestD = id, d end
        end
    end
    return best
end

-- Ask to open the panel. We send the nearest stable; the server decides access
-- (owners/trainers must be AT a stable; an admin may manage from anywhere).
RegisterCommand('sovmanage', function()
    TriggerServerEvent(Events.RequestManagement, nearestStable(30.0))
end, false)
