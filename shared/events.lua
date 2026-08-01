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
Events.ReportHorseEntity = e('reportHorseEntity')-- net id of the horse you have out,
                                                 -- so the server can delete it if you drop

-- wagons [WG1/WG2/WG13] — milestone 1.4
Events.RequestOwnedWagons     = e('requestOwnedWagons')
Events.RequestSetDefaultWagon = e('requestSetDefaultWagon')
Events.RequestCallWagon       = e('requestCallWagon')     -- bring out a wagon
Events.ReportWagonDismiss     = e('reportWagonDismiss')   -- wagon sent away
Events.ReportWagonHealth      = e('reportWagonHealth')    -- persist wear [WG9]
Events.ReportWagonWrecked     = e('reportWagonWrecked')   -- rendered unusable, stays in place [WG9]
Events.RequestRepairWagon     = e('requestRepairWagon')   -- field/pro repair [WG9/J14]
Events.WagonRepaired          = e('wagonRepaired')        -- client-bound: new condition
Events.RequestWagonInventory  = e('requestWagonInventory')-- open a wagon's cargo hold

-- metabolism / care [C-series] — milestone 2.1
Events.RequestCare     = e('requestCare')      -- feed/water/clean a horse (named item)
Events.CareResult      = e('careResult')       -- outcome + fresh status
Events.SyncCare        = e('syncCare')          -- push current status to the client
Events.ReportDirt      = e('reportDirt')        -- client tells server how dirty it got
Events.ReportDrank     = e('reportDrank')       -- (retired) auto-drink at a trough / body of water
Events.RequestDrink    = e('requestDrink')      -- player CHOSE to water the horse from the menu

-- tack [F1/F5] — milestone 1.4
Events.RequestOwnedTack  = e('requestOwnedTack')   -- what tack do I own + what's on this horse
Events.RequestBuyTack    = e('requestBuyTack')
Events.RequestApplyTack  = e('requestApplyTack')   -- put an owned piece on an owned horse
Events.RequestRemoveTack = e('requestRemoveTack')  -- clear a slot
Events.RequestTintTack   = e('requestTintTack')    -- recolour a fitted slot [2.3]
Events.SaveHorseMorph    = e('saveHorseMorph')     -- persist a horse's shape (Config.HorseMorph values) [2.4]
Events.RequestCustomize  = e('requestCustomize')   -- ask to open the shape customiser (server gates) [2.4]
Events.OpenCustomizer    = e('openCustomizer')     -- client-bound: server approved; open the panel [2.4]

-- stable management panel [3.x] — role-scoped business panel
Events.RequestManagement = e('requestManagement')  -- open the management panel for a stable
Events.ManagementData    = e('managementData')     -- client-bound: role-scoped panel payload
Events.RequestManageAction = e('requestManageAction') -- a management action (hire/fire/duty/fund/...) [3.x]
Events.ManageActionResult  = e('manageActionResult')  -- client-bound: action outcome (panel then refreshes)
Events.RequestTrainingData = e('requestTrainingData') -- open the Trainer Panel (client-horse roster)
Events.TrainingData        = e('trainingData')        -- client-bound: role-scoped training roster + counts
Events.RequestBreedingData = e('requestBreedingData') -- open the Breeding Register
Events.BreedingData        = e('breedingData')        -- client-bound: pairings + stats + perms
-- horse creator [admin] — author a horse into a stable's catalog
Events.RequestValidateHorse = e('requestValidateHorse') -- run the validation checks (no write)
Events.ValidateHorseResult  = e('validateHorseResult')  -- client-bound: {checks, ok}
Events.RequestCreatedHorses = e('requestCreatedHorses') -- list admin-created horses (optionally a stable)
Events.CreatedHorsesData    = e('createdHorsesData')    -- client-bound: created-horse catalog

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
