--[[=====================================================================
  SOVEREIGN STABLES · ADMIN AGGREGATES  (server) — read layer
  ---------------------------------------------------------------------
  The Admin Panel's read-only views + the owner Ledger/Staff panels, aggregated
  over the business data built in management/business/training/breeding. No new
  state of its own except reads. Gating: directory/profile/activity are admin;
  ledger + employees are owner-of-that-stable OR admin.
=====================================================================]]--

local function scalar(sql, params, key)
    local r = Db.awaitQuery(sql, params)
    return (r and r[1] and tonumber(r[1][key])) or 0
end

local function ownerOrAdmin(src, stableId, charid)
    return Management.isAdmin(src) or Management.roleAt(src, stableId, charid) == 'owner'
end

--------------------------------------------------------------------------------
-- Stable Directory (admin) — every configured stable + live counts
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestStableDirectory, function()
    local src = source
    CreateThread(function()
        if not Bridge.isAdmin(src) then return end
        local list, totalTrainers, totalClientHorses = {}, 0, 0
        for id, s in pairs(Config.Stables or {}) do
            local biz = Management.businessRow(id)
            local emps = scalar('SELECT COUNT(*) AS n FROM sovereign_stable_employees WHERE stable_id = ?', { id }, 'n')
            local trainers = scalar("SELECT COUNT(*) AS n FROM sovereign_stable_employees WHERE stable_id = ? AND role = 'trainer'", { id }, 'n')
            local horses = scalar("SELECT COUNT(*) AS n FROM sovereign_client_horses WHERE stable_id = ? AND phase <> 'returned'", { id }, 'n')
            totalTrainers = totalTrainers + trainers
            totalClientHorses = totalClientHorses + horses
            list[#list + 1] = {
                stableId = id, name = (biz and biz.name) or s.label or id,
                owner = biz and biz.owner_charid and (Business.nameOfCharid(biz.owner_charid)) or nil,
                status = (biz and biz.status) or (biz and biz.owner_charid and 'open') or 'unowned',
                employees = emps, trainers = trainers, clientHorses = horses,
            }
        end
        table.sort(list, function(a, b) return a.name < b.name end)
        TriggerClientEvent(Events.StableDirectoryData, src, {
            stables = list,
            totals = { stables = #list, trainers = totalTrainers, clientHorses = totalClientHorses },
        })
    end)
end)

--------------------------------------------------------------------------------
-- Stable Profile (admin)
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestStableProfile, function(stableId)
    local src = source
    if not (stableId and Config.Stables[stableId]) then return end
    CreateThread(function()
        if not Bridge.isAdmin(src) then return end
        local biz = Management.businessRow(stableId)
        local staff = Db.awaitQuery('SELECT name, role, grade FROM sovereign_stable_employees WHERE stable_id = ? ORDER BY role', { stableId }) or {}
        TriggerClientEvent(Events.StableProfileData, src, {
            stableId = stableId,
            name = (biz and biz.name) or Config.Stables[stableId].label or stableId,
            owner = biz and biz.owner_charid and Business.nameOfCharid(biz.owner_charid) or nil,
            status = (biz and biz.status) or 'unowned',
            funds = { cash = tonumber(biz and biz.funds_cash) or 0, gold = tonumber(biz and biz.funds_gold) or 0 },
            taxDue = tonumber(biz and biz.tax_due) or 0,
            employees = staff,
            clientHorses = scalar("SELECT COUNT(*) AS n FROM sovereign_client_horses WHERE stable_id = ? AND phase <> 'returned'", { stableId }, 'n'),
        })
    end)
end)

--------------------------------------------------------------------------------
-- Activity Log (admin)
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestActivityLog, function(stableId)
    local src = source
    if not (stableId and Config.Stables[stableId]) then return end
    CreateThread(function()
        if not Bridge.isAdmin(src) then return end
        local rows = Db.awaitQuery([[SELECT actor_name, action, target, category, result, source, created_at
            FROM sovereign_stable_activity WHERE stable_id = ? ORDER BY id DESC LIMIT 60]], { stableId }) or {}
        TriggerClientEvent(Events.ActivityLogData, src, { stableId = stableId, entries = rows })
    end)
end)

--------------------------------------------------------------------------------
-- Society Ledger (owner of the stable, or admin) — entries + summaries
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestLedger, function(stableId)
    local src = source
    if not (stableId and Config.Stables[stableId]) then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src); if not charid then return end
        if not ownerOrAdmin(src, stableId, charid) then return end
        local biz = Management.businessRow(stableId)
        local entries = Db.awaitQuery([[SELECT id, description, category, actor_name, amount_cash, amount_gold, balance_after, created_at
            FROM sovereign_stable_ledger WHERE stable_id = ? ORDER BY id DESC LIMIT 60]], { stableId }) or {}
        local income = scalar([[SELECT COALESCE(SUM(amount_cash),0) AS n FROM sovereign_stable_ledger
            WHERE stable_id = ? AND amount_cash > 0 AND created_at >= (NOW() - INTERVAL 30 DAY)]], { stableId }, 'n')
        local expense = scalar([[SELECT COALESCE(-SUM(amount_cash),0) AS n FROM sovereign_stable_ledger
            WHERE stable_id = ? AND amount_cash < 0 AND created_at >= (NOW() - INTERVAL 30 DAY)]], { stableId }, 'n')
        TriggerClientEvent(Events.LedgerData, src, {
            stableId = stableId,
            funds = { cash = tonumber(biz and biz.funds_cash) or 0, gold = tonumber(biz and biz.funds_gold) or 0 },
            taxDue = tonumber(biz and biz.tax_due) or 0,
            entries = entries,
            summary = { income30 = income, expense30 = expense },
        })
    end)
end)

--------------------------------------------------------------------------------
-- Employees (owner of the stable, or admin) — roster + permission snapshot
--------------------------------------------------------------------------------
local ROLE_CAPS = {
    owner      = 'Full stable management',
    trainer    = 'Own assigned horses and client notes',
    stablehand = 'Care tasks and basic records',
}
RegisterNetEvent(Events.RequestEmployees, function(stableId)
    local src = source
    if not (stableId and Config.Stables[stableId]) then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src); if not charid then return end
        if not ownerOrAdmin(src, stableId, charid) then return end
        local biz = Management.businessRow(stableId)
        local roster = Db.awaitQuery([[SELECT id, charid, name, role, grade, on_duty, hired_at, last_active
            FROM sovereign_stable_employees WHERE stable_id = ? ORDER BY FIELD(role,'trainer','stablehand'), name]], { stableId }) or {}
        -- The owner sits on the business row, not the roster — surface them too.
        local owner = biz and biz.owner_charid and { name = Business.nameOfCharid(biz.owner_charid), role = 'owner', grade = 3, on_duty = 1, isOwner = true } or nil
        TriggerClientEvent(Events.EmployeesData, src, {
            stableId = stableId, owner = owner, roster = roster,
            caps = ROLE_CAPS,
        })
    end)
end)
