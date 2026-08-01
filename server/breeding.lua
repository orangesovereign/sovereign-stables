--[[=====================================================================
  SOVEREIGN STABLES · BREEDING  (server) — the stud register
  ---------------------------------------------------------------------
  Pair a sire and dam; after a gestation a foal is produced and the parents
  enter a restoration cooldown. Drives the Breeding Register panel. Stud fees
  post to the society ledger via Business.postLedger.

  Status flow (advanced by a light server thread on real time):
    in_progress ──(result_at)──▶ restoring ──(restore_until)──▶ completed

  Role perms come from Config.Breeding.perms; actions register into the shared
  RequestManageAction dispatcher. Table: sovereign_breedings.
=====================================================================]]--

Breeding = Breeding or {}

local function exec(sql, params)
    local p = promise.new(); Db.execute(sql, params, function(a) p:resolve(a or 0) end); return Citizen.Await(p)
end

local function cfg() return Config.Breeding or {} end

local function permsFor(role)
    return (cfg().perms and cfg().perms[role]) or {}
end
local function may(src, stableId, charid, cap)
    if Management.isAdmin(src) then return true end
    local role = Management.roleAt(src, stableId, charid)
    return permsFor(role)[cap] == true
end

local function shape(row)
    return {
        id = row.id, sire = row.sire_name, dam = row.dam_name, client = row.client_name,
        handler = row.handler_name, status = row.status, result = row.result,
        startedAt = tonumber(row.started_at), resultAt = tonumber(row.result_at),
        restoreUntil = tonumber(row.restore_until), fee = tonumber(row.fee) or 0,
    }
end

function Breeding.register(stableId)
    local rows = Db.awaitQuery(
        "SELECT * FROM sovereign_breedings WHERE stable_id = ? ORDER BY FIELD(status,'in_progress','restoring','completed'), result_at", { stableId }) or {}
    local out = {}
    for _, r in ipairs(rows) do out[#out + 1] = shape(r) end
    return out
end

function Breeding.stats(stableId)
    local rows = Db.awaitQuery('SELECT status, COUNT(*) AS n FROM sovereign_breedings WHERE stable_id = ? GROUP BY status', { stableId }) or {}
    local s = { active = 0, restoring = 0, completed = 0 }
    for _, r in ipairs(rows) do s[r.status] = tonumber(r.n) or 0 end
    -- revenue this week from breeding-category ledger income
    local rev = Db.awaitQuery([[SELECT COALESCE(SUM(amount_cash),0) AS c FROM sovereign_stable_ledger
        WHERE stable_id = ? AND category = 'breeding' AND amount_cash > 0 AND created_at >= (NOW() - INTERVAL 7 DAY)]], { stableId })
    return {
        active   = s.in_progress or s.active or 0,
        restoring = s.restoring or 0,
        completed = s.completed or 0,
        revenueWeek = rev and rev[1] and tonumber(rev[1].c) or 0,
        -- eligible-horse pairing count needs a horse-eligibility model that doesn't
        -- exist yet; sent as a placeholder rather than faked.
        availablePairs = { value = 0, pending = true },
    }
end

--------------------------------------------------------------------------------
-- Data endpoint
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestBreedingData, function(stableId)
    local src = source
    if not (stableId and Config.Stables[stableId]) then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src); if not charid then return end
        local role = Management.isAdmin(src) and 'admin' or Management.roleAt(src, stableId, charid)
        if not role then return end
        TriggerClientEvent(Events.BreedingData, src, {
            stableId = stableId, role = role,
            register = Breeding.register(stableId),
            stats    = Breeding.stats(stableId),
            perms    = (role == 'admin') and { create = true, cancel = true, review = true } or permsFor(role),
        })
    end)
end)

--------------------------------------------------------------------------------
-- Actions
--------------------------------------------------------------------------------
Business.actions.beginPairing = function(src, stableId, charid, p)
    if not may(src, stableId, charid, 'create') then return false, 'Not allowed.' end
    local sire = tostring(p.sire or ''):sub(1, 64)
    local dam  = tostring(p.dam or ''):sub(1, 64)
    if sire == '' or dam == '' then return false, 'Pick a sire and a dam.' end
    local started = os.time()
    local resultAt = started + (tonumber(cfg().gestationDays) or 5) * 86400
    local fee = tonumber(cfg().fee) or 0
    local handler = Business.nameOfCharid(charid) or 'Handler'
    exec([[INSERT INTO sovereign_breedings
             (stable_id, sire_name, dam_name, client_name, handler_charid, handler_name, status, fee, started_at, result_at)
           VALUES (?,?,?,?,?,?, 'in_progress', ?,?,?)]],
        { stableId, sire, dam, p.client, charid, handler, fee, started, resultAt })
    if fee > 0 then
        Business.postLedger(stableId, ('Stud fee · %s × %s'):format(sire, dam), 'breeding', charid, handler, fee, 0)
    end
    return true, ('Pairing booked: %s × %s.'):format(sire, dam)
end

Business.actions.cancelPairing = function(src, stableId, charid, p)
    if not may(src, stableId, charid, 'cancel') then return false, 'Only the owner may cancel.' end
    local id = tonumber(p.id); if not id then return false, 'Which pairing?' end
    exec("DELETE FROM sovereign_breedings WHERE id = ? AND stable_id = ? AND status = 'in_progress'", { id, stableId })
    return true, 'Pairing cancelled.'
end

--------------------------------------------------------------------------------
-- Time advance: gestate to a foal, then run the cooldown. Light, on real time.
--------------------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(120000)   -- every 2 minutes
        local ok = pcall(function()
            local now = os.time()
            local results = cfg().results or { 'Filly', 'Colt' }
            -- in_progress → restoring (foal produced)
            local due = Db.awaitQuery("SELECT id, stable_id FROM sovereign_breedings WHERE status = 'in_progress' AND result_at IS NOT NULL AND result_at <= ?", { now }) or {}
            for _, r in ipairs(due) do
                local foal = results[math.random(1, #results)] or 'Foal'
                local restore = now + (tonumber(cfg().restorationDays) or 3) * 86400
                exec("UPDATE sovereign_breedings SET status = 'restoring', result = ?, restore_until = ? WHERE id = ?", { foal, restore, r.id })
            end
            -- restoring → completed (cooldown over)
            exec("UPDATE sovereign_breedings SET status = 'completed' WHERE status = 'restoring' AND restore_until IS NOT NULL AND restore_until <= ?", { now })
        end)
        if not ok then Util.warn('breeding tick failed') end
    end
end)
