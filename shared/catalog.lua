--[[=====================================================================
  SOVEREIGN STABLES · CATALOG RESOLVER
  ---------------------------------------------------------------------
  Turns raw config (defaults + per-model overrides + per-stable vendor lists)
  into the display data the storefront renders. Usable on client and server so
  both agree on what a stable sells and for how much. Model/coat-agnostic:
  every entry is keyed by model id.
=====================================================================]]--

Catalog = Catalog or {}

local function merge(defaults, entry)
    local out = {}
    for k, v in pairs(defaults or {}) do out[k] = v end
    for k, v in pairs(entry or {}) do out[k] = v end
    return out
end

-- Resolve one horse model into a full card (defaults + overrides + price override).
local function resolveHorse(model, priceOverride)
    local base = Config.Horses[model]
    if not base then return nil end
    local h = merge(Config.HorseDefaults, base)
    h.model = model
    h.name  = h.name or h.label or model
    h.breed = h.breed or h.label or model
    if type(priceOverride) == 'table' then h.price = priceOverride end
    return h
end

-- The list of horse cards a stable offers. Empty vendor list = the whole catalog.
function Catalog.horsesFor(stableId)
    local stable = Config.Stables[stableId]
    local wanted = stable and stable.catalog and stable.catalog.horses or {}
    local out = {}

    local function push(model, override)
        local h = resolveHorse(model, type(override) == 'table' and override or nil)
        if h and h.buyable ~= false then out[#out + 1] = h end
    end

    if next(wanted) == nil then
        for model in pairs(Config.Horses) do push(model) end
    else
        for k, v in pairs(wanted) do
            if type(k) == 'number' then push(v) else push(k, v) end
        end
    end

    table.sort(out, function(a, b) return (a.price.cash or 0) > (b.price.cash or 0) end)
    return out
end

-- Look up a single resolved horse card by model.
function Catalog.horse(model) return resolveHorse(model) end

--------------------------------------------------------------------------------
-- WAGONS  [WG1/WG13]
--   Same shape as horses: defaults + per-model overrides + per-stable vendor
--   list, keyed by model id. Kept as its own resolver rather than a shared
--   generic one — the two catalogs drift apart from Phase 5 (work wagons,
--   crafting) and a clever abstraction now would only have to be unpicked.
--------------------------------------------------------------------------------
local function resolveWagon(model, priceOverride)
    local base = Config.Wagons[model]
    if not base then return nil end
    local w = merge(Config.WagonDefaults, base)
    w.model = model
    w.name  = w.name or w.label or model
    if type(priceOverride) == 'table' then w.price = priceOverride end
    return w
end

-- The list of wagon cards a stable offers. Empty vendor list = the whole catalog.
function Catalog.wagonsFor(stableId)
    local stable = Config.Stables[stableId]
    local wanted = stable and stable.catalog and stable.catalog.wagons or {}
    local out = {}

    local function push(model, override)
        local w = resolveWagon(model, type(override) == 'table' and override or nil)
        if w and w.buyable ~= false then out[#out + 1] = w end
    end

    if next(wanted) == nil then
        for model in pairs(Config.Wagons) do push(model) end
    else
        for k, v in pairs(wanted) do
            if type(k) == 'number' then push(v) else push(k, v) end
        end
    end

    table.sort(out, function(a, b) return (a.price.cash or 0) > (b.price.cash or 0) end)
    return out
end

function Catalog.wagon(model) return resolveWagon(model) end

--------------------------------------------------------------------------------
-- TACK  [F1/F5]
--   Flat lookup by item id across every category, because tack is PLAYER-owned:
--   what matters is "do you own this piece", not "which horse is it on".
--------------------------------------------------------------------------------
-- One resolved tack card, or nil. Returns the card with `id` and `category` set.
function Catalog.tack(itemId)
    for _, cat in ipairs(Config.TackCategories or {}) do
        local items = (Config.Tack or {})[cat.id]
        local item  = items and items[itemId]
        if item then
            local t = merge({ price = { cash = 0.0, gold = 0.0 } }, item)
            t.id       = itemId
            t.category = cat.id
            t.slot     = cat.slot
            t.label    = t.label or itemId
            return t
        end
    end
    return nil
end

-- Every tack card in a category, sorted dearest first (matches the horse list).
function Catalog.tackIn(category)
    local out = {}
    for itemId in pairs((Config.Tack or {})[category] or {}) do
        local t = Catalog.tack(itemId)
        if t and t.buyable ~= false then out[#out + 1] = t end
    end
    table.sort(out, function(a, b) return (a.price.cash or 0) > (b.price.cash or 0) end)
    return out
end

-- Categories that actually have something in them. Keeps the customizer from
-- showing nine empty tabs while the hash tables are still being filled.
function Catalog.tackCategories()
    local out = {}
    for _, cat in ipairs(Config.TackCategories or {}) do
        local items = (Config.Tack or {})[cat.id]
        if items and next(items) ~= nil then
            out[#out + 1] = { id = cat.id, label = cat.label, slot = cat.slot,
                              count = #Catalog.tackIn(cat.id) }
        end
    end
    return out
end

-- Whether a character (job/grade) may buy a given horse at a given stable.
-- Returns ok:boolean, reason:string|nil. (Faction/grade rules expand in later phases.)
function Catalog.canBuy(card, stableId, job)
    local stable = Config.Stables[stableId]
    if stable and stable.jobs and stable.jobs.restricted then
        local ok = false
        for _, j in ipairs(stable.jobs.allowed or {}) do if j == job then ok = true break end end
        if not ok then return false, 'This stable serves another trade.' end
    end
    if card.jobs and card.jobs ~= 'all' then
        local ok = false
        for _, j in ipairs(card.jobs) do if j == job then ok = true break end end
        if not ok then return false, 'Reserved for another trade.' end
    end
    return true
end
