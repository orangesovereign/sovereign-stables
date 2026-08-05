--[[=====================================================================
  SOVEREIGN STABLES · MANAGEMENT PANEL  (server)
  ---------------------------------------------------------------------
  The role-scoped stable-business panel (owner ruling 2026-07-31: business
  layer is NATIVE here, not sovereign_stores). One panel; the nav + data widen
  by role — a trainer sees their own work, an owner sees the whole stable, a
  server admin sees every stable + the Admin Panel. Gated data is never sent to
  someone who can't see it, so the client cannot render what it never received
  (hidden, not greyed). Every action re-checks
  server-side.

  This first cut ships the SHELL + Operations Overview. Panels whose subsystems
  don't exist yet (client-horse training/raising phases, breeding register) are
  sent as honest placeholders, not faked data.

  Tables: sovereign_stable_business (owner + funds), sovereign_stable_employees
  (roster + role + grade + duty), sovereign_stable_ledger (society ledger).
=====================================================================]]--

Management = Management or {}

--------------------------------------------------------------------------------
-- Identity / role resolution
--------------------------------------------------------------------------------
local function isAdmin(src)
    -- Server admin per Config.Admin (VORP group / ace / boss perm). See bridge.lua.
    return Bridge.isAdmin(src)
end

local function businessRow(stableId)
    local r = Db.awaitQuery('SELECT * FROM sovereign_stable_business WHERE stable_id = ?', { stableId })
    return r and r[1] or nil
end

local function employeeRow(stableId, charid)
    local r = Db.awaitQuery('SELECT * FROM sovereign_stable_employees WHERE stable_id = ? AND charid = ?', { stableId, charid })
    return r and r[1] or nil
end

-- Returns 'admin' | 'owner' | 'trainer' | 'stablehand' | nil for this player at a stable.
local function roleAt(src, stableId, charid)
    if isAdmin(src) then return 'admin' end
    local biz = businessRow(stableId)
    if biz and tostring(biz.owner_charid) == tostring(charid) then return 'owner' end
    local e = employeeRow(stableId, charid)
    if e then return e.role or 'stablehand' end
    return nil
end

-- The stable the player is standing at (near its prompt/ped), if any.
local function stableAt(src)
    local ped = GetPlayerPed(src); if not ped or ped == 0 then return nil end
    local pc = GetEntityCoords(ped)
    local best, bestD = nil, 20.0
    for id, s in pairs(Config.Stables or {}) do
        local c = (s.prompt and s.prompt.coords) or (s.ped and s.ped.coords)
        if c then
            local d = #(pc - vector3(c[1] + 0.0, c[2] + 0.0, c[3] + 0.0))
            if d < bestD then best, bestD = id, d end
        end
    end
    return best
end

--------------------------------------------------------------------------------
-- Nav — which sections this role may open (hidden, not greyed).
--------------------------------------------------------------------------------
local NAV = {
    { key = 'overview', label = 'Overview' },
    { key = 'trainer',  label = 'Trainer Panel' },
    { key = 'staff',    label = 'Staff & Roles' },
    { key = 'breeding', label = 'Breeding' },
    { key = 'ledger',   label = 'Ledger' },
    { key = 'settings', label = 'Settings' },
}
local function navFor(role)
    local out = {}
    for _, n in ipairs(NAV) do
        local allow = true
        if role == 'trainer' or role == 'stablehand' then
            -- staff see Overview + Trainer Panel; owner/admin see everything.
            allow = (n.key == 'overview' or n.key == 'trainer')
        end
        if allow then out[#out + 1] = n end
    end
    if role == 'admin' then out[#out + 1] = { key = 'admin', label = 'Admin Panel' } end
    return out
end

--------------------------------------------------------------------------------
-- Operations Overview payload (role-scoped).
--------------------------------------------------------------------------------
local function overview(stableId, role, biz)
    local staff = Db.awaitQuery(
        'SELECT name, role, grade, on_duty FROM sovereign_stable_employees WHERE stable_id = ? ORDER BY on_duty DESC, role', { stableId }) or {}
    local onDuty = 0
    for _, e in ipairs(staff) do if tonumber(e.on_duty) == 1 then onDuty = onDuty + 1 end end

    local ledger = Db.awaitQuery(
        'SELECT description, category, amount_cash, created_at FROM sovereign_stable_ledger WHERE stable_id = ? ORDER BY id DESC LIMIT 6', { stableId }) or {}

    -- Client Pickup Queue: horses that finished training and await collection.
    local pickup = Db.awaitQuery(
        "SELECT id, horse_name, model, breed, client_name FROM sovereign_client_horses WHERE stable_id = ? AND phase = 'ready' ORDER BY ready_at LIMIT 6", { stableId }) or {}

    local view = {
        section  = 'overview',
        staff    = staff,
        onDuty   = onDuty,
        staffCount = #staff,
        ledger   = ledger,
        pickup   = pickup,
        -- Client-horse training (real once server/training.lua is loaded).
        clientHorses = (Training and Training.counts and Training.counts(stableId))
                        or { total = 0, raising = 0, training = 0, ready = 0, pending = true },
        breeding     = (Breeding and Breeding.stats and Breeding.stats(stableId))
                        or { active = 0, pending = true },
    }
    -- Money is owner/admin only.
    if role == 'owner' or role == 'admin' then
        view.funds = { cash = tonumber(biz and biz.funds_cash) or 0, gold = tonumber(biz and biz.funds_gold) or 0 }
        view.taxDue = tonumber(biz and biz.tax_due) or 0
    end
    return view
end

--------------------------------------------------------------------------------
-- Open
--------------------------------------------------------------------------------
-- The admin's fallback stable when they open from anywhere: the admin stable
-- (Braithwaite), else the first configured stable.
local function adminDefaultStable()
    for id, s in pairs(Config.Stables or {}) do if s.adminStable then return id end end
    for id in pairs(Config.Stables or {}) do return id end
    return nil
end

-- Build + send the role-scoped panel payload to a client. Exposed so the other
-- business modules can refresh the panel after an action.
function Management.push(src, stableId)
    if not (stableId and Config.Stables[stableId]) then return end
    local charid = Bridge.getCharId(src); if not charid then return end
    local admin = isAdmin(src)
    local role = admin and 'admin' or roleAt(src, stableId, charid)
    if not role then return end
    local biz = businessRow(stableId)
    local ch = Bridge.getCharacter(src)
    local cash, gold = Bridge.getBalance(src)
    local scfg = Config.Stables[stableId] or {}
    local payload = {
        stableId = stableId,
        stableName = (biz and biz.name) or scfg.label or 'Stable',
        county = scfg.county or scfg.region or scfg.town or nil,
        role = role,
        roleLabel = ({ admin = 'Server Administrator', owner = 'Owner', trainer = 'Trainer', stablehand = 'Stablehand' })[role] or role,
        playerName = (ch and (ch.firstname and (ch.firstname .. ' ' .. (ch.lastname or '')))) or GetPlayerName(src),
        wallet = { cash = tonumber(cash) or 0, gold = tonumber(gold) or 0 },
        nav = navFor(role),
        overview = overview(stableId, role, biz),
    }
    TriggerClientEvent(Events.ManagementData, src, payload)
end

-- Shared helpers for the other management modules (server/business.lua, etc.).
Management.isAdmin      = isAdmin
Management.roleAt       = roleAt
Management.businessRow  = businessRow
Management.canManage    = function(src, stableId, charid)   -- owner or admin
    return isAdmin(src) or roleAt(src, stableId, charid) == 'owner'
end

--------------------------------------------------------------------------------
-- Section data (redesign book fetches each section lazily on nav).
--------------------------------------------------------------------------------
-- Role-scoped data for one book section. Backends already hold the data; this
-- just gathers it per section. Sections not yet built return { pending = true }.
function Management.sectionData(stableId, section, role, charid)
    if section == 'trainer' or section == 'training' then
        local trainerView = (role == 'trainer' or role == 'stablehand')
        return {
            roster   = Training.roster(stableId, role, charid),
            counts   = Training.counts(stableId, trainerView and charid or nil),
            trainers = (not trainerView) and Training.trainerSummary(stableId) or nil,
            tiers    = (Config.Training and Config.Training.tiers) or {},
            role     = role,
        }
    end
    return { pending = true }
end

RegisterNetEvent(Events.RequestManageSection, function(stableId, section)
    local src = source
    CreateThread(function()
        if not (stableId and Config.Stables[stableId] and section) then return end
        local charid = Bridge.getCharId(src); if not charid then return end
        local role = isAdmin(src) and 'admin' or roleAt(src, stableId, charid)
        if not role then return end
        TriggerClientEvent(Events.ManageSectionData, src, {
            section = section,
            role    = role,
            data    = Management.sectionData(stableId, section, role, charid),
        })
    end)
end)

RegisterNetEvent(Events.RequestManagement, function(clientStable)
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        local admin = isAdmin(src)
        -- Trust the client's nearest-stable (reliable coords); fall back to a
        -- server check only if it wasn't sent.
        local stableId = (clientStable and Config.Stables[clientStable] and clientStable) or stableAt(src)
        if not (stableId and Config.Stables[stableId]) then
            if admin then
                stableId = adminDefaultStable()   -- an admin may manage from anywhere
            else
                Bridge.notify(src, 'Stand at a stable to manage it.'); return
            end
        end
        if not (stableId and Config.Stables[stableId]) then return end
        if not (admin or roleAt(src, stableId, charid)) then
            Bridge.notify(src, 'You have no business here.'); return   -- hidden: no panel for outsiders
        end
        Management.push(src, stableId)
    end)
end)

--------------------------------------------------------------------------------
-- Ownership bootstrap (until the Admin Panel's assign-owner lands).
--   sovsetstableowner <stableId> [charid]
--------------------------------------------------------------------------------
-- Diagnostic: what does the server see about YOU? Prints group, job/grade, ace
-- results, identifier, and the final isAdmin verdict — so we can pin admin access.
RegisterCommand('sovwhoami', function(src)
    if src == 0 then print('run in-game'); return end
    CreateThread(function()
        local grp  = Bridge.getGroup(src)
        local job, grade = Bridge.getJob(src)
        local id   = Bridge.getIdentifier(src)
        local parts = {}
        for _, ace in ipairs((Config.Admin and Config.Admin.aces) or {}) do
            local ok = false; pcall(function() ok = IsPlayerAceAllowed(src, ace) end)
            parts[#parts + 1] = ace .. '=' .. tostring(ok)
        end
        local adm = Bridge.isAdmin(src)
        print(('^3[sov_whoami]^7 group=%s  job=%s  grade=%s  isAdmin=%s'):format(tostring(grp), tostring(job), tostring(grade), tostring(adm)))
        print(('^3[sov_whoami]^7 identifier=%s'):format(tostring(id)))
        print(('^3[sov_whoami]^7 aces: %s'):format(table.concat(parts, '  ')))
        Bridge.notify(src, ('group=%s · isAdmin=%s (see F8)'):format(tostring(grp), tostring(adm)))
    end)
end, false)

RegisterCommand('sovsetstableowner', function(src, args)
    if src ~= 0 and not isAdmin(src) then Bridge.notify(src, 'Admins only.'); return end
    local stableId = args and args[1]
    if not (stableId and Config.Stables[stableId]) then print('^3usage:^7 sovsetstableowner <stableId> [charid]'); return end
    CreateThread(function()
        local charid = tonumber(args and args[2]) or (src ~= 0 and Bridge.getCharId(src)) or nil
        if not charid then print('^3[sov_mgmt]^7 need a charid (or run in-game)'); return end
        local label = Config.Stables[stableId].label or stableId
        Db.execute([[INSERT INTO sovereign_stable_business (stable_id, owner_charid, name)
                     VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE owner_charid = ?]],
            { stableId, charid, label, charid })
        print(('^2[sov_mgmt]^7 %s owner set to charid %s'):format(stableId, tostring(charid)))
        if src ~= 0 then Bridge.notify(src, ('You now own %s.'):format(label)) end
    end)
end, true)
