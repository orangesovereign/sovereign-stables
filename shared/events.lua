--[[=====================================================================
  SOVEREIGN STABLES · EVENT NAMES
  ---------------------------------------------------------------------
  Central registry of net-event names so client and server never disagree
  on a string. Prefix keeps them from colliding with other resources.
=====================================================================]]--

Events = {
    prefix = 'sovereign_stables',
}

local function e(name) return Events.prefix .. ':' .. name end

-- server-bound
Events.RequestBuyHorse   = e('requestBuyHorse')
Events.RequestBuyWagon   = e('requestBuyWagon')
Events.RequestStore      = e('requestStore')
Events.RequestRetrieve   = e('requestRetrieve')
Events.RequestSell       = e('requestSell')
Events.RequestDiag       = e('requestDiag')

Events.RequestHeader     = e('requestHeader')
Events.RequestPurchase   = e('requestPurchase')
Events.RequestOwned      = e('requestOwned')
Events.RequestSetDefault = e('requestSetDefault')

-- client-bound
Events.OpenStorefront    = e('openStorefront')
Events.HeaderData        = e('headerData')
Events.PurchaseResult    = e('purchaseResult')
Events.OwnedData         = e('ownedData')
Events.SyncOwnedRides    = e('syncOwnedRides')
Events.DiagResult        = e('diagResult')
