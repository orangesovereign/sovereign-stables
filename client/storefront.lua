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

    -- Ask the server for the real identity + wallet; header fills in when it arrives.
    TriggerServerEvent(Events.RequestHeader, stableId)
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

RegisterNUICallback('purchase', function(data, cb)
    -- Milestone 1.2 wires the real server-authoritative purchase.
    Bridge.notifyCard('started', 'Stables', 'Purchasing opens in the next update.')
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    Storefront.close()
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then Storefront.close() end
end)
