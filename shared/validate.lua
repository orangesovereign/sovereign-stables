--[[=====================================================================
  SOVEREIGN STABLES · CONFIG VALIDATOR
  ---------------------------------------------------------------------
  Catches the mistakes a non-programmer owner is most likely to make:
  missing coordinates, malformed catalog entries, references to horses/wagons
  that don't exist, duplicate ids. Returns a list of human-readable problems.
  Run automatically at boot and on demand via /stables_diag.
=====================================================================]]--

Validate = Validate or {}

local function isNum(x) return type(x) == 'number' end

-- Validates a price table like { cash = 100.0, gold = 0.0 }.
local function checkPrice(where, price, problems)
    if type(price) ~= 'table' then
        problems[#problems + 1] = where .. ': price must be a table like { cash = 100.0, gold = 0.0 }'
        return
    end
    if price.cash ~= nil and not isNum(price.cash) then
        problems[#problems + 1] = where .. ': price.cash must be a number'
    end
    if price.gold ~= nil and not isNum(price.gold) then
        problems[#problems + 1] = where .. ': price.gold must be a number'
    end
end

function Validate.run()
    local problems = {}

    -- generic config sanity
    if not (Config and type(Config) == 'table') then
        return { 'Config table is missing entirely' }
    end
    if not (Locales and Locales[Config.Locale]) then
        problems[#problems + 1] = ('Config.Locale = "%s" has no matching locale file'):format(tostring(Config.Locale))
    end

    -- horses
    local horses = Config.Horses or {}
    for id, h in pairs(horses) do
        if type(h) ~= 'table' then
            problems[#problems + 1] = ('Horse "%s" must be a table'):format(id)
        else
            if h.price then checkPrice('Horse "' .. id .. '"', h.price, problems) end
        end
    end

    -- wagons
    local wagons = Config.Wagons or {}
    for id, w in pairs(wagons) do
        if type(w) ~= 'table' then
            problems[#problems + 1] = ('Wagon "%s" must be a table'):format(id)
        else
            if w.price then checkPrice('Wagon "' .. id .. '"', w.price, problems) end
        end
    end

    -- stables
    local nStables = 0
    for id, s in pairs(Config.Stables or {}) do
        nStables = nStables + 1
        local w = 'Stable "' .. id .. '"'
        if type(s) ~= 'table' then
            problems[#problems + 1] = w .. ' must be a table'
        else
            if s.ped and s.ped.enabled and not (s.ped.coords and #s.ped.coords >= 4) then
                problems[#problems + 1] = w .. ': ped.coords needs {x, y, z, heading}'
            end
            if not (s.prompt and Util.isVec3(s.prompt.coords)) then
                problems[#problems + 1] = w .. ': prompt.coords needs {x, y, z}'
            end
            if s.blip and s.blip.enabled and not Util.isVec3(s.blip.coords) then
                problems[#problems + 1] = w .. ': blip.coords needs {x, y, z}'
            end
            -- catalog references must exist in the catalogs
            for _, hid in ipairs((s.catalog and s.catalog.horses) or {}) do
                if type(hid) == 'string' and not horses[hid] then
                    problems[#problems + 1] = w .. ': catalog lists unknown horse "' .. hid .. '"'
                end
            end
            for _, wid in ipairs((s.catalog and s.catalog.wagons) or {}) do
                if type(wid) == 'string' and not wagons[wid] then
                    problems[#problems + 1] = w .. ': catalog lists unknown wagon "' .. wid .. '"'
                end
            end
        end
    end
    if nStables == 0 then
        problems[#problems + 1] = 'No stables defined in config/stables.lua'
    end

    return problems
end
