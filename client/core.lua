--[[=====================================================================
  SOVEREIGN STABLES · CLIENT CORE
  ---------------------------------------------------------------------
  Boots the client: starts the module registry (which brings up world
  presence, the storefront, preview and camera). Feature behaviour lives in
  the feature modules, not here.
=====================================================================]]--

RegisterCommand('stables_diag', function() TriggerServerEvent(Events.RequestDiag) end, false)

CreateThread(function()
    Wait(1500)          -- let dependencies + config settle
    Registry.start()    -- fires onInit across all registered modules
    Util.log('client ready — walk up to a stable and press G (or /stable)')
end)
