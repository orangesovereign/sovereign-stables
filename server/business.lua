--[[=====================================================================
  SOVEREIGN STABLES · BUSINESS  (server) — employees, ledger, funds
  ---------------------------------------------------------------------
  The native stable-business layer the management panel writes through
  (owner ruling 2026-07-31: business is native here, not sovereign_stores).
  Foundation phase: EMPLOYEES (hire/fire/role/grade/duty), the SOCIETY LEDGER
  (every money movement writes a row), and FUNDS (deposit/withdraw). The
  training, breeding and horse-creator subsystems post to the ledger through
  Business.postLedger.

  Gating is server-authoritative and role-scoped (owner/admin manage; withdraw
  is owner-only; an employee may clock only themselves). Reuses the role helpers
  exposed by server/management.lua (loaded first).

  Tables: sovereign_stable_business (funds), sovereign_stable_employees (roster),
  sovereign_stable_ledger (money log).
=====================================================================]]--

Business = Business or {}

local function exec(sql, params)
    local p = promise.new()
    Db.execute(sql, params, function(a) p:resolve(a or 0) end)
    return Citizen.Await(p)
end

--------------------------------------------------------------------------------
-- Funds + ledger
--------------------------------------------------------------------------------
local function fundsOf(stableId)
    local r = Db.awaitQuery('SELECT funds_cash, funds_gold FROM sovereign_stable_business WHERE stable_id = ?', { stableId })
    if not (r and r[1]) then return 0, 0 end
    return tonumber(r[1].funds_cash) or 0, tonumber(r[1].funds_gold) or 0
end

-- Every money movement in the business goes through here: it shifts the funds and
-- writes one ledger row with the resulting balance. cash/gold are SIGNED.
function Business.postLedger(stableId, desc, category, actorCharid, actorName, cash, gold)
    cash, gold = tonumber(cash) or 0, tonumber(gold) or 0
    exec('UPDATE sovereign_stable_business SET funds_cash = GREATEST(0, funds_cash + ?), funds_gold = GREATEST(0, funds_gold + ?) WHERE stable_id = ?',
        { cash, gold, stableId })
    local c = fundsOf(stableId)
    exec([[INSERT INTO sovereign_stable_ledger
             (stable_id, description, category, actor_charid, actor_name, amount_cash, amount_gold, balance_after)
           VALUES (?,?,?,?,?,?,?,?)]],
        { stableId, tostring(desc or ''), tostring(category or 'misc'), actorCharid, actorName, cash, gold, c })
end

--------------------------------------------------------------------------------
-- Role / gating (via management.lua helpers)
--------------------------------------------------------------------------------
local function canManage(src, stableId, charid) return Management.canManage(src, stableId, charid) end
local function isOwnerOrAdmin(src, stableId, charid)
    return Management.isAdmin(src) or Management.roleAt(src, stableId, charid) == 'owner'
end

local function nameOfCharid(charid)
    local r = Db.awaitQuery('SELECT firstname, lastname FROM characters WHERE charidentifier = ? LIMIT 1', { charid })
    if r and r[1] then return ((r[1].firstname or '') .. ' ' .. (r[1].lastname or '')):gsub('^%s+', ''):gsub('%s+$', '') end
    return nil
end

--------------------------------------------------------------------------------
-- ACTIONS  (each returns ok, message). Shared registry so other business modules
-- (training, breeding, horse creator) can add their own actions to the same
-- RequestManageAction dispatcher: `Business.actions.myAction = function(...) end`.
--------------------------------------------------------------------------------
Business.actions = Business.actions or {}
local Actions = Business.actions
-- Expose the shared helpers other modules need.
Business.canManage    = canManage
Business.isOwnerOrAdmin = isOwnerOrAdmin
Business.nameOfCharid = nameOfCharid

-- Hire: add an employee by charid (the panel picks a nearby player → charid).
function Actions.hire(src, stableId, charid, p)
    if not canManage(src, stableId, charid) then return false, 'Not allowed.' end
    local target = tonumber(p.charid)
    if not target then return false, 'Pick a person to hire.' end
    local role = (p.role == 'trainer') and 'trainer' or 'stablehand'
    local grade = math.max(1, math.min(tonumber(p.grade) or 1, 5))
    local name = p.name or nameOfCharid(target)
    exec([[INSERT INTO sovereign_stable_employees (stable_id, charid, name, role, grade)
           VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE role = VALUES(role), grade = VALUES(grade), name = VALUES(name)]],
        { stableId, target, name, role, grade })
    return true, ('Hired %s as %s.'):format(name or ('#' .. target), role)
end

function Actions.fire(src, stableId, charid, p)
    if not canManage(src, stableId, charid) then return false, 'Not allowed.' end
    local id = tonumber(p.employeeId)
    if not id then return false, 'Which employee?' end
    exec('DELETE FROM sovereign_stable_employees WHERE id = ? AND stable_id = ?', { id, stableId })
    return true, 'Employee removed.'
end

function Actions.setRole(src, stableId, charid, p)
    if not canManage(src, stableId, charid) then return false, 'Not allowed.' end
    local id = tonumber(p.employeeId)
    local role = (p.role == 'trainer') and 'trainer' or 'stablehand'
    if not id then return false, 'Which employee?' end
    exec('UPDATE sovereign_stable_employees SET role = ? WHERE id = ? AND stable_id = ?', { role, id, stableId })
    return true, 'Role updated.'
end

function Actions.setGrade(src, stableId, charid, p)
    if not canManage(src, stableId, charid) then return false, 'Not allowed.' end
    local id = tonumber(p.employeeId)
    local grade = math.max(1, math.min(tonumber(p.grade) or 1, 5))
    if not id then return false, 'Which employee?' end
    exec('UPDATE sovereign_stable_employees SET grade = ? WHERE id = ? AND stable_id = ?', { grade, id, stableId })
    return true, 'Grade updated.'
end

-- Clock on/off. An employee may clock ONLY themselves; owner/admin may clock anyone.
local function setDuty(src, stableId, charid, employeeId, on)
    local rows
    if employeeId then
        rows = Db.awaitQuery('SELECT charid FROM sovereign_stable_employees WHERE id = ? AND stable_id = ?', { employeeId, stableId })
    else
        rows = Db.awaitQuery('SELECT id, charid FROM sovereign_stable_employees WHERE charid = ? AND stable_id = ?', { charid, stableId })
    end
    local row = rows and rows[1]
    if not row then return false, 'No such employee here.' end
    local isSelf = tostring(row.charid) == tostring(charid)
    if not (isSelf or canManage(src, stableId, charid)) then return false, 'You can only clock yourself.' end
    exec('UPDATE sovereign_stable_employees SET on_duty = ?, last_active = CURRENT_TIMESTAMP WHERE ' ..
        (employeeId and 'id = ?' or 'charid = ?') .. ' AND stable_id = ?',
        { on and 1 or 0, employeeId or charid, stableId })
    return true, on and 'Clocked on duty.' or 'Clocked off.'
end
function Actions.clockOn(src, stableId, charid, p)  return setDuty(src, stableId, charid, tonumber(p.employeeId), true)  end
function Actions.clockOff(src, stableId, charid, p) return setDuty(src, stableId, charid, tonumber(p.employeeId), false) end

-- Funds: deposit your own money INTO the till; withdraw is OWNER-only.
function Actions.fundDeposit(src, stableId, charid, p)
    if not canManage(src, stableId, charid) then return false, 'Not allowed.' end
    local cash = math.max(0, math.floor(tonumber(p.cash) or 0))
    local gold = math.max(0, math.floor(tonumber(p.gold) or 0))
    if cash <= 0 and gold <= 0 then return false, 'Nothing to deposit.' end
    if not Bridge.canAfford(src, cash, gold) then return false, 'You do not have that.' end
    if not Bridge.charge(src, cash, gold) then return false, 'Payment failed.' end
    Business.postLedger(stableId, 'Society deposit', 'deposit', charid, nameOfCharid(charid), cash, gold)
    return true, 'Deposited to society funds.'
end

function Actions.fundWithdraw(src, stableId, charid, p)
    if not isOwnerOrAdmin(src, stableId, charid) then return false, 'Only the owner may withdraw.' end
    local cash = math.max(0, math.floor(tonumber(p.cash) or 0))
    local gold = math.max(0, math.floor(tonumber(p.gold) or 0))
    local fc, fg = fundsOf(stableId)
    if cash <= 0 and gold <= 0 then return false, 'Nothing to withdraw.' end
    if cash > fc or gold > fg then return false, 'Society funds cannot cover that.' end
    Business.postLedger(stableId, 'Society withdrawal', 'withdraw', charid, nameOfCharid(charid), -cash, -gold)
    Bridge.pay(src, cash, gold)
    return true, 'Withdrew from society funds.'
end

-- A manual ledger note (owner/admin) — no money moved unless amounts given.
function Actions.ledgerEntry(src, stableId, charid, p)
    if not canManage(src, stableId, charid) then return false, 'Not allowed.' end
    local desc = tostring(p.description or ''):sub(1, 96)
    if desc == '' then return false, 'Describe the entry.' end
    local cash = math.floor(tonumber(p.cash) or 0)
    local gold = math.floor(tonumber(p.gold) or 0)
    Business.postLedger(stableId, desc, tostring(p.category or 'misc'):sub(1, 24), charid, nameOfCharid(charid), cash, gold)
    return true, 'Ledger entry recorded.'
end

--------------------------------------------------------------------------------
-- Dispatcher
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestManageAction, function(stableId, action, payload)
    local src = source
    if not (stableId and Config.Stables[stableId] and action and Actions[action]) then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src); if not charid then return end
        local ok, msg = false, 'Something went wrong.'
        local good, err = pcall(function() ok, msg = Actions[action](src, stableId, charid, payload or {}) end)
        if not good then Util.err(('manage action "%s": %s'):format(tostring(action), tostring(err))) end
        TriggerClientEvent(Events.ManageActionResult, src, { ok = ok, message = msg })
        if ok and Management and Management.push then Management.push(src, stableId) end   -- refresh the panel
    end)
end)
