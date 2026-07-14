--[[=====================================================================
  SOVEREIGN STABLES · CLIENT CORE
  ---------------------------------------------------------------------
  Phase 0: starts the client module registry and provides the branded NUI
  shell so we can prove the UI opens/closes with correct focus handling.
  Real storefront screens arrive in Phase 1.
=====================================================================]]--

local uiOpen = false

local function openShell()
    if uiOpen then return end
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', screen = 'shell' })
end

local function closeShell()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    closeShell()
    cb({ ok = true })
end)

-- Dev/test commands (Phase 0). These get replaced by stable interactions in Phase 1.
RegisterCommand('stables_ui', function() openShell() end, false)
RegisterCommand('stables_diag', function() TriggerServerEvent(Events.RequestDiag) end, false)

-- Safety: close the shell if the resource stops while it's open.
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and uiOpen then closeShell() end
end)

CreateThread(function()
    Wait(1500)
    Registry.start()
    Util.log('client core ready — /stables_ui to open the shell, /stables_diag for health')
end)
