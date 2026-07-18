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
Events.RequestSummon     = e('requestSummon')    -- whistle for your default horse
Events.RequestBringOut   = e('requestBringOut')  -- fetch a specific horse at a stable
Events.ReportDismiss     = e('reportDismiss')    -- horse sent away
Events.ReportDeath       = e('reportDeath')      -- horse died (hard-death bookkeeping)

-- wagons [WG1/WG2/WG13] — milestone 1.4
Events.RequestOwnedWagons     = e('requestOwnedWagons')
Events.RequestSetDefaultWagon = e('requestSetDefaultWagon')
Events.RequestCallWagon       = e('requestCallWagon')     -- bring out a wagon
Events.ReportWagonDismiss     = e('reportWagonDismiss')   -- wagon sent away
Events.ReportWagonHealth      = e('reportWagonHealth')    -- persist wear [WG9]
Events.ReportWagonWrecked     = e('reportWagonWrecked')   -- rendered unusable, stays in place [WG9]
Events.RequestRepairWagon     = e('requestRepairWagon')   -- field/pro repair [WG9/J14]
Events.WagonRepaired          = e('wagonRepaired')        -- client-bound: new condition

-- tack [F1/F5] — milestone 1.4
Events.RequestOwnedTack  = e('requestOwnedTack')   -- what tack do I own + what's on this horse
Events.RequestBuyTack    = e('requestBuyTack')
Events.RequestApplyTack  = e('requestApplyTack')   -- put an owned piece on an owned horse
Events.RequestRemoveTack = e('requestRemoveTack')  -- clear a slot

-- transfer [F3 / ride transfer] — milestone 1.4.
-- Phase 3's trainer custody transfer reuses this exact system.
Events.RequestTransfer   = e('requestTransfer')    -- offer a horse/wagon to a server id
Events.RespondTransfer   = e('respondTransfer')    -- target accepts/declines

-- client-bound
Events.OpenStorefront    = e('openStorefront')
Events.HeaderData        = e('headerData')
Events.PurchaseResult    = e('purchaseResult')
Events.OwnedData         = e('ownedData')
Events.OwnedWagonData    = e('ownedWagonData')
Events.OwnedTackData     = e('ownedTackData')
Events.TackResult        = e('tackResult')
Events.SummonResult      = e('summonResult')
Events.CallWagonResult   = e('callWagonResult')
Events.TransferOffer     = e('transferOffer')      -- "X wants to give you Y"
Events.TransferResult    = e('transferResult')
Events.SyncOwnedRides    = e('syncOwnedRides')
Events.DiagResult        = e('diagResult')
