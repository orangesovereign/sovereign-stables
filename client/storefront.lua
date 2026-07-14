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

-- Swap the previewed horse and refresh the detail panel.
local function selectModel(model)
    local stable = Config.Stables[currentStable]; if not stable then return end
    currentModel = model
    Preview.show(model, stable.preview.horsePos)
    Camera.retarget(centreOf(stable.preview.horsePos))
    SendNUIMessage({ action = 'detail', detail = detailOf(model) })
end

-- Show everything once the server has returned the header (name/job/wallet).
local function show(header)
    local stable = Config.Stables[currentStable]; if not stable then return end
    local rows = catalogRows(currentStable)
    if #rows == 0 then Bridge.notify('This stable has nothing for sale.'); return end

    isOpen = true
    currentModel = rows[1].model
    Preview.show(currentModel, stable.preview.horsePos)
    Camera.start(centreOf(stable.preview.horsePos), 42.0)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action  = 'open',
        header  = {
            stableLabel = stable.label,
            collection  = stable.label,
            charName    = header.charName or 'Rider',
            job         = header.job or '',
            permTier    = header.permTier or '',
            cash        = header.cash or 0,
            gold        = header.gold or 0,
        },
        catalog = { rows = rows },
        detail  = detailOf(currentModel),
    })
end

function Storefront.open(stableId)
    if isOpen or not Config.Stables[stableId] then return end
    currentStable = stableId
    TriggerServerEvent(Events.RequestHeader, stableId)   -- server replies with HeaderData
end

function Storefront.close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    Camera.stop()
    Preview.hide()
    currentStable, currentModel = nil, nil
end

function Storefront.isOpen() return isOpen end

-- Server → client: header data arrived, open the storefront.
RegisterNetEvent(Events.HeaderData, function(header)
    if currentStable then show(header) end
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
