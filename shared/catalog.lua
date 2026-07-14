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
