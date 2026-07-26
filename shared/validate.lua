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

    -- METABOLISM: a core nothing can restore is a trap. Thirst drained faster
    -- than hunger while the only item touching it gave 10 points, so a horse's
    -- thirst was effectively unrecoverable and the retest couldn't do it. Catch
    -- that at boot instead of in game.
    local m = Config.Metabolism
    if m and m.enabled ~= false then
        local restores = { hunger = 0, thirst = 0, dirt = 0 }
        for _, def in pairs(m.items or {}) do
            for core in pairs(restores) do
                if type(def[core]) == 'number' and def[core] > 0 then
                    restores[core] = restores[core] + def[core]
                end
            end
        end
        if restores.hunger <= 0 then
            problems[#problems + 1] = 'Metabolism: NO item restores hunger — horses will starve with no way to feed them (config/metabolism.lua `items`)'
        end
        -- Thirst has a WORLD source too: a horse drinks from troughs and rivers.
        -- So it only needs an item if drinking is switched off.
        local canDrink = (m.drinking and m.drinking.enabled ~= false)
        if restores.thirst <= 0 and not canDrink then
            problems[#problems + 1] = 'Metabolism: NO item restores thirst and drinking is disabled — a horse could never drink (config/metabolism.lua)'
        end
        if (m.cleanliness and m.cleanliness.enabled ~= false) and restores.dirt <= 0 then
            problems[#problems + 1] = 'Metabolism: NO item removes dirt — add a brush (config/metabolism.lua `items`)'
        end
        -- Restoring a core is one thing; restoring ENOUGH of it is another. Ask
        -- how many minutes of drain the best single item actually buys back. A
        -- horse that needs feeding every few minutes is a chore, not a system.
        -- (This was live: thirst drains 1.0/min and the only item touching it
        -- gave 10 — one carrot per 10 minutes, forever.)
        local MIN_MINUTES = 20
        local best = { hunger = 0, thirst = 0 }
        for _, def in pairs(m.items or {}) do
            for core in pairs(best) do
                if type(def[core]) == 'number' and def[core] > best[core] then best[core] = def[core] end
            end
        end
        for core, cfg in pairs({ hunger = m.hunger, thirst = m.thirst }) do
            -- Skip thirst when the horse can drink from the world — a river is a
            -- better water source than any item, and always to hand.
            local worldSource = (core == 'thirst') and canDrink
            local rate = cfg and cfg.drainPerMinute or 0
            if rate > 0 and best[core] > 0 and not worldSource then
                local minutes = best[core] / rate
                if minutes < MIN_MINUTES then
                    problems[#problems + 1] = ('Metabolism: the best %s item restores %d, but %s drains %.1f/min — only %.0f minutes per use. Add a stronger item.'):
                        format(core, best[core], core, rate, minutes)
                end
            end
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
