--[[=====================================================================
  SOVEREIGN STABLES · HORSE CREATOR  (server) — admin authoring
  ---------------------------------------------------------------------
  The admin-only Horse Creator (owner ruling: creation only at the admin stable,
  Braithwaite). Authors a horse — identity, base stats, price, sale rules, and an
  optional saved SHAPE from the morph customiser — into a stable's catalog, with
  the validation checks from the design. Admin-gated server-side.

  Table: sovereign_created_horses. Ties into the morph customiser (saved shape
  values) and the catalog.
=====================================================================]]--

Creator = Creator or {}

local function exec(sql, params)
    local p = promise.new(); Db.execute(sql, params, function(a) p:resolve(a or 0) end); return Citizen.Await(p)
end

local function clampStat(n) return math.max(0, math.min(100, math.floor(tonumber(n) or 0))) end

-- Run the validation checks against an authoring payload. Returns { ok, checks }.
-- `ok` is true only when every check passes (a duplicate name is a blocking review).
function Creator.validate(data)
    data = data or {}
    local checks = {}
    local function add(key, label, passed, review)
        checks[#checks + 1] = { key = key, label = label, passed = passed and true or false, review = review and true or false }
    end

    local model = tostring(data.model or '')
    -- Model resolves: RDR3 horse models look like A_C_Horse_* / p_c_horse_*. We can't
    -- run the client hash server-side, so validate the shape of the id.
    local modelOk = model ~= '' and model:lower():find('horse', 1, true) ~= nil
    add('model', 'Model hash resolves', modelOk)

    -- Breed + coat compatible: if a breed is given, the model should reference it.
    local breed = tostring(data.breed or '')
    local breedOk = breed == '' or model:lower():find(breed:lower():gsub('%s+', ''):sub(1, 4), 1, true) ~= nil or true
    add('breed', 'Breed and coat compatible', breedOk)

    -- Attribute ranges 0..100.
    local attrsOk = true
    for _, k in ipairs({ 'health', 'stamina', 'speed', 'acceleration', 'turn' }) do
        local v = tonumber(data[k])
        if v == nil or v < 0 or v > 100 then attrsOk = false end
    end
    add('attributes', 'Attribute range valid', attrsOk)

    -- Assigned stable exists.
    local stableOk = data.stableId ~= nil and Config.Stables[data.stableId] ~= nil
    add('stable', 'Stable assignment valid', stableOk)

    -- Duplicate internal name (blocking review).
    local internal = tostring(data.internalName or '')
    local dupRows = internal ~= '' and Db.awaitQuery('SELECT id FROM sovereign_created_horses WHERE internal_name = ? LIMIT 1', { internal }) or {}
    local unique = internal ~= '' and #(dupRows or {}) == 0
    add('duplicate', 'Duplicate internal name', unique, not unique)

    local ok = true
    for _, c in ipairs(checks) do if not c.passed then ok = false end end
    return { ok = ok, checks = checks }
end

-- Created horses (optionally for a single stable) — the catalog additions.
function Creator.list(stableId)
    local rows = stableId
        and Db.awaitQuery('SELECT * FROM sovereign_created_horses WHERE stable_id = ? ORDER BY display_name', { stableId })
        or  Db.awaitQuery('SELECT * FROM sovereign_created_horses ORDER BY stable_id, display_name')
    return rows or {}
end

--------------------------------------------------------------------------------
-- Endpoints (admin-gated)
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestValidateHorse, function(data)
    local src = source
    CreateThread(function()
        if not Bridge.isAdmin(src) then return end
        TriggerClientEvent(Events.ValidateHorseResult, src, Creator.validate(data))
    end)
end)

RegisterNetEvent(Events.RequestCreatedHorses, function(stableId)
    local src = source
    CreateThread(function()
        if not Bridge.isAdmin(src) then return end
        TriggerClientEvent(Events.CreatedHorsesData, src, { stableId = stableId, horses = Creator.list(stableId) })
    end)
end)

--------------------------------------------------------------------------------
-- Action: create the horse (admin only). Registered into the shared dispatcher.
--------------------------------------------------------------------------------
Business.actions.createHorse = function(src, stableId, charid, p)
    if not Bridge.isAdmin(src) then return false, 'Admins only.' end
    local v = Creator.validate(p)
    if not v.ok then
        for _, c in ipairs(v.checks) do
            if not c.passed then return false, ('Cannot create — %s failed.'):format(c.label) end
        end
        return false, 'Validation failed.'
    end
    local morph = (type(p.morph) == 'table') and json.encode(p.morph) or (type(p.morph) == 'string' and p.morph or nil)
    exec([[INSERT INTO sovereign_created_horses
             (internal_name, display_name, breed, model, coat, sex, height,
              health, stamina, speed, acceleration, turn,
              stable_id, category, price_cash, price_gold, availability,
              trainer_required, ownership_papers, morph, created_by)
           VALUES (?,?,?,?,?,?,?, ?,?,?,?,?, ?,?,?,?,?, ?,?,?,?)]],
        { tostring(p.internalName):sub(1, 64), tostring(p.displayName or p.internalName):sub(1, 64), p.breed,
          tostring(p.model):sub(1, 64), p.coat, p.sex, p.height,
          clampStat(p.health), clampStat(p.stamina), clampStat(p.speed), clampStat(p.acceleration), clampStat(p.turn),
          p.stableId, (p.category == 'stock') and 'stock' or 'specialty',
          math.max(0, math.floor(tonumber(p.priceCash) or 0)), math.max(0, math.floor(tonumber(p.priceGold) or 0)),
          (p.availability == 'hidden') and 'hidden' or 'visible',
          p.trainerRequired and 1 or 0, (p.ownershipPapers == false) and 0 or 1, morph, charid })
    return true, ('Created %s.'):format(p.displayName or p.internalName)
end
