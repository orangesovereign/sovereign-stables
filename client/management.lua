--[[=====================================================================
  SOVEREIGN STABLES · MANAGEMENT PANEL  (client)
  ---------------------------------------------------------------------
  Opens the role-scoped stable-business panel. The SERVER decides your role at
  the stable and sends only what you may see (hidden, not greyed), so the client
  just renders the payload. Entry: /sovmanage while standing at a stable (a
  prompt at the counter comes later).
=====================================================================]]--

Management = Management or {}

RegisterNetEvent(Events.ManagementData, function(payload)
    if type(payload) ~= 'table' then return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'manage:open', panel = payload })
end)

RegisterNUICallback('manageClose', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Ask to open the panel for the stable you're standing at.
RegisterCommand('sovmanage', function()
    TriggerServerEvent(Events.RequestManagement)
end, false)
