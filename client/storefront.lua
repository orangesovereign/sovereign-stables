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

-- Ask the server to buy. It decides price, permission, caps and funds.
RegisterNUICallback('purchase', function(data, cb)
    if data and data.model and currentStable then
        TriggerServerEvent(Events.RequestPurchase, currentStable, data.model)
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

RegisterNUICallback('close', function(_, cb)
    Storefront.close()
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then Storefront.close() end
end)
