--[[=====================================================================
  SOVEREIGN STABLES · STOREFRONT  (client)
  ---------------------------------------------------------------------
  Orchestrates the branded NUI, the live preview horse and the orbital camera
  into one storefront. Milestone 1.1 is browse-only: walk up, open, cycle
  horses with the real preview. Purchasing lands in 1.2.
=====================================================================]]--

Storefront = Storefront or {}

local isOpen        = false
local currentStable = nil
local currentModel  = nil
local ownedList     = {}   -- horses this character owns (from the server)

-- Build the aim point for the camera from a stable's horse preview position.
local function centreOf(pos) return { pos[1], pos[2], pos[3] + 0.9 } end

-- Assemble the lightweight catalog rows the NUI list renders.
local function catalogRows(stableId)
    local rows = {}
    for _, h in ipairs(Catalog.horsesFor(stableId)) do
        rows[#rows + 1] = {
            model = h.model, name = h.name, breed = h.breed, tier = h.tier,
            cash = h.price.cash or 0, gold = h.price.gold or 0, locked = false,
        }
    end
    return rows
end

-- Full detail payload for the right-hand panel.
local function detailOf(model)
    local h = Catalog.horse(model); if not h then return nil end
    return {
        model = model, name = h.name, breed = h.breed,
        sex = h.sex, age = h.age, hands = h.hands, lore = h.lore,
        traits = h.traits or {}, stats = h.stats or {},
        cash = h.price.cash or 0, gold = h.price.gold or 0, tier = h.tier,
    }
end

-- Spawn/retarget the preview horse. Never let a spawn failure abort the UI.
local function showPreview(model)
    local stable = Config.Stables[currentStable]; if not stable then return end
    local ok, err = pcall(function()
        Preview.show(model, stable.preview.horsePos)
        Camera.retarget(centreOf(stable.preview.horsePos))
    end)
    if not ok then Util.err('preview swap failed: ' .. tostring(err)) end
end

-- Put a WAGON on the stand instead [1.4 G2]. The horse preview is removed by
-- Preview.showWagon, and the camera moves to the wagon's own spot — both are
-- per-stable config (preview.wagonPos), because where a cart looks good is not
-- where a horse looks good.
local function showWagonPreview(model)
    local stable = Config.Stables[currentStable]; if not stable then return end
    local pos = stable.preview and stable.preview.wagonPos
    if not pos then
        Util.warn(('stable "%s" has no preview.wagonPos — leaving the stand empty'):format(tostring(currentStable)))
        pcall(Preview.hide)
        return
    end
    local ok, err = pcall(function()
        Preview.showWagon(model, pos)
        -- A wagon is bigger than a horse: pull the camera back or it fills the frame.
        Camera.retarget({ pos[1], pos[2], pos[3] + 0.9 }, 6.4)
    end)
    if not ok then Util.err('wagon preview swap failed: ' .. tostring(err)) end
end

-- Swap the previewed horse and refresh the detail panel.
local function selectModel(model)
    currentModel = model
    showPreview(model)
    SendNUIMessage({ action = 'detail', detail = detailOf(model) })
end

function Storefront.open(stableId)
    if isOpen then Util.log('storefront open ignored — already open'); return end
    local stable = Config.Stables[stableId]
    if not stable then Util.warn('storefront open: unknown stable ' .. tostring(stableId)); return end

    local rows = catalogRows(stableId)
    if #rows == 0 then Bridge.notify('This stable has nothing for sale.'); return end

    currentStable = stableId
    currentModel  = rows[1].model
    isOpen        = true

    -- Re-roll the stablehand's groomed horse on entry (cosmetic ambience).
    if Stables and Stables.rerollGroom then pcall(Stables.rerollGroom, stableId) end

    -- Open the NUI FIRST — browsing must not depend on the server round-trip.
    SetNuiFocus(true, true)
    SendNUIMessage({
        action  = 'open',
        header  = { stableLabel = stable.label, collection = stable.label,
                    charName = 'Rider', job = '', permTier = '', cash = 0, gold = 0 },
        catalog = { rows = rows },
        detail  = detailOf(currentModel),
    })
    Util.log(('storefront opened at %s (%d horse[s])'):format(stableId, #rows))

    -- Preview horse + orbital camera (isolated so a failure can't block the UI).
    local ok, err = pcall(function()
        Preview.show(currentModel, stable.preview.horsePos)
        Camera.start(centreOf(stable.preview.horsePos), 42.0)
    end)
    if not ok then Util.err('preview/camera start failed: ' .. tostring(err)) end

    -- Ask the server for the real identity + wallet, and this character's horses.
    TriggerServerEvent(Events.RequestHeader, stableId)
    TriggerServerEvent(Events.RequestOwned)
end

function Storefront.close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    pcall(function() Camera.stop(); Preview.hide() end)
    currentStable, currentModel = nil, nil
end

function Storefront.isOpen() return isOpen end

-- Server → client: real identity + wallet arrived; update the header in place.
RegisterNetEvent(Events.HeaderData, function(header)
    if not isOpen then return end
    local stable = Config.Stables[currentStable]
    SendNUIMessage({
        action = 'header',
        header = {
            stableLabel = stable and stable.label or '',
            collection  = stable and stable.label or '',
            charName    = header.charName or 'Rider',
            job         = header.job or '',
            permTier    = header.permTier or '',
            cash        = header.cash or 0,
            gold        = header.gold or 0,
        },
    })
end)

-- NUI → client callbacks -------------------------------------------------------
RegisterNUICallback('select', function(data, cb)
    if data and data.model then selectModel(data.model) end
    cb({ ok = true })
end)

RegisterNUICallback('orbit', function(data, cb)
    Camera.nudge(tonumber(data.dx) or 0.0, tonumber(data.dy) or 0.0)
    cb({ ok = true })
end)

RegisterNUICallback('zoom', function(data, cb)
    Camera.zoom(tonumber(data.delta) or 0.0)
    cb({ ok = true })
end)

-- Ask the server to buy. It decides price, permission, caps and funds; the
-- buyer only chooses the name and gender (N8/N9), which the server sanitizes.
RegisterNUICallback('purchase', function(data, cb)
    if data and data.model and currentStable then
        TriggerServerEvent(Events.RequestPurchase, currentStable, data.model,
            { name = data.name, sex = data.sex })
    end
    cb({ ok = true })
end)

-- Preview + detail for a horse the player already owns.
RegisterNUICallback('selectOwned', function(data, cb)
    local row
    for _, r in ipairs(ownedList) do
        if tostring(r.id) == tostring(data.id) then row = r break end
    end
    if row then
        currentModel = row.model
        showPreview(row.model)
        local d = detailOf(row.model) or {}
        d.name      = row.name or d.name
        d.sex       = row.sex or d.sex      -- the gender chosen at purchase [N9]
        d.ownedId   = row.id
        d.isDefault = (tonumber(row.is_default) == 1)
        SendNUIMessage({ action = 'detail', detail = d })
    end
    cb({ ok = true })
end)

RegisterNUICallback('setDefault', function(data, cb)
    if data and data.id then TriggerServerEvent(Events.RequestSetDefault, data.id) end
    cb({ ok = true })
end)

-- Collect a horse in person: close the shop, then the server brings it out.
RegisterNUICallback('bringOut', function(data, cb)
    if data and data.id then
        Storefront.close()
        TriggerServerEvent(Events.RequestBringOut, data.id)
    end
    cb({ ok = true })
end)

-- Server → client: purchase outcome (never trust the client's copy of money).
RegisterNetEvent(Events.PurchaseResult, function(res)
    res = res or {}
    Bridge.notifyCard(res.ok and 'complete' or 'failed', 'Stables', res.message or '')
    SendNUIMessage({ action = 'wallet', cash = res.cash or 0, gold = res.gold or 0 })
end)

-- Server → client: the player's owned horses (for My Horses + the count badge).
RegisterNetEvent(Events.OwnedData, function(data)
    data = data or {}
    ownedList = data.owned or {}
    SendNUIMessage({ action = 'owned', owned = ownedList, cap = data.cap or 0 })
end)

--------------------------------------------------------------------------------
-- WAGONS  [WG1/WG13] — milestone 1.4
--------------------------------------------------------------------------------
local function wagonCatalogRows(stableId)
    local rows = {}
    for _, w in ipairs(Catalog.wagonsFor(stableId)) do
        rows[#rows + 1] = {
            model = w.model, name = w.name, storage = w.storage,
            cash = w.price.cash or 0, gold = w.price.gold or 0, locked = false,
        }
    end
    return rows
end

RegisterNUICallback('requestWagons', function(_, cb)
    if currentStable then
        local rows = wagonCatalogRows(currentStable)
        SendNUIMessage({ action = 'wagons', catalog = rows })
        -- Swap the stand to a wagon the moment they open the view, rather than
        -- waiting for a click — otherwise a horse stands there looking like the
        -- thing you're about to buy.
        if rows[1] then showWagonPreview(rows[1].model) end
    end
    TriggerServerEvent(Events.RequestOwnedWagons)
    cb({ ok = true })
end)

-- A wagon for sale: show it on the stage like a horse, so the preview column
-- isn't dead air while you're shopping for one.
RegisterNUICallback('selectWagonModel', function(data, cb)
    local w = data and data.model and Catalog.wagon(data.model)
    if w then
        showWagonPreview(w.model)
        SendNUIMessage({ action = 'detail', detail = {
            model = w.model, name = w.name, breed = 'Wagon',
            lore = w.lore, stats = {}, traits = {},
            cash = w.price.cash or 0, gold = w.price.gold or 0,
            isWagon = true,
        }})
    end
    cb({ ok = true })
end)

RegisterNUICallback('selectWagon', function(data, cb)
    if data and data.id then
        SendNUIMessage({ action = 'detail', detail = { ownedWagonId = data.id, isWagon = true } })
    end
    cb({ ok = true })
end)

RegisterNUICallback('purchaseWagon', function(data, cb)
    if data and data.model and currentStable then
        TriggerServerEvent(Events.RequestBuyWagon, currentStable, data.model, { name = data.name })
    end
    cb({ ok = true })
end)

RegisterNUICallback('setDefaultWagon', function(data, cb)
    if data and data.id then TriggerServerEvent(Events.RequestSetDefaultWagon, data.id) end
    cb({ ok = true })
end)

-- Bring a wagon round: close the shop first, same as collecting a horse — you
-- can't stand in a menu and watch a wagon arrive. The stable id goes with it:
-- the wagon appears in THIS stable's yard (owner ruling Q2 — stable only).
RegisterNUICallback('callWagon', function(data, cb)
    if data and data.id and currentStable then
        local stableId = currentStable
        Storefront.close()
        TriggerServerEvent(Events.RequestCallWagon, data.id, stableId)
    end
    cb({ ok = true })
end)

RegisterNetEvent(Events.OwnedWagonData, function(data)
    data = data or {}
    SendNUIMessage({ action = 'wagons', owned = data.owned or {}, cap = data.cap or 0 })
end)

--------------------------------------------------------------------------------
-- TACK  [F1/F5] — milestone 1.4
--   Tack is PLAYER-owned: bought once, worn by whichever horse you choose. The
--   catalog is built client-side from config (both sides share it), but every
--   purchase and every fitting is decided by the server.
--------------------------------------------------------------------------------
local function tackCatalogPayload()
    local out = {}
    for _, cat in ipairs(Catalog.tackCategories()) do
        local items = {}
        for _, t in ipairs(Catalog.tackIn(cat.id)) do
            items[#items + 1] = {
                id = t.id, label = t.label, slot = t.slot,
                cash = t.price.cash or 0, gold = t.price.gold or 0,
            }
        end
        out[cat.id] = items
    end
    return out
end

RegisterNUICallback('requestTack', function(data, cb)
    SendNUIMessage({ action = 'tack', catalog = tackCatalogPayload(),
                     categories = Catalog.tackCategories() })

    -- [1.4 T2] The tack room fits YOUR horse, so YOUR horse goes on the stand —
    -- not whatever was last being sold. Prefer the one they picked in My Horses,
    -- else their default ride.
    local horseId = data and data.horseId or nil
    local row
    for _, r in ipairs(ownedList) do
        if horseId and tostring(r.id) == tostring(horseId) then row = r break end
        if not horseId and tonumber(r.is_default) == 1 then row = r break end
    end
    row = row or ownedList[1]
    if row then
        currentModel = row.model
        showPreview(row.model)
    end

    TriggerServerEvent(Events.RequestOwnedTack, horseId or (row and row.id) or nil)
    cb({ ok = true })
end)

-- Leaving the wagon view: put a horse back on the stand [1.4 G2].
RegisterNUICallback('restoreHorsePreview', function(_, cb)
    if currentModel then showPreview(currentModel) end
    cb({ ok = true })
end)

RegisterNUICallback('buyTack', function(data, cb)
    if data and data.item then TriggerServerEvent(Events.RequestBuyTack, data.item) end
    cb({ ok = true })
end)

RegisterNUICallback('applyTack', function(data, cb)
    if data and data.item and data.horseId then
        TriggerServerEvent(Events.RequestApplyTack, data.horseId, data.item)
    end
    cb({ ok = true })
end)

RegisterNUICallback('removeTack', function(data, cb)
    if data and data.slot and data.horseId then
        TriggerServerEvent(Events.RequestRemoveTack, data.horseId, data.slot)
    end
    cb({ ok = true })
end)

RegisterNetEvent(Events.OwnedTackData, function(data)
    data = data or {}
    SendNUIMessage({ action = 'tack', owned = data.owned or {},
                     categories = data.categories, horseId = data.horseId,
                     components = data.components })
    -- Show the fitting on the preview horse immediately — the whole point of a
    -- tack room is seeing it on the animal before you commit.
    if data.components and Preview.ped() then
        pcall(function() Components.applySet(Preview.ped(), data.components) end)
    end
end)

RegisterNetEvent(Events.TackResult, function(res)
    res = res or {}
    if res.message then
        Bridge.notifyCard(res.ok and 'complete' or 'failed', 'Stables', res.message)
    end
    if res.cash or res.gold then
        SendNUIMessage({ action = 'wallet', cash = res.cash or 0, gold = res.gold or 0 })
    end
end)

RegisterNUICallback('close', function(_, cb)
    Storefront.close()
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then Storefront.close() end
end)
