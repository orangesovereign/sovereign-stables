--[[=====================================================================
  SOVEREIGN STABLES · TRAINING  (server) — client-horse boarding
  ---------------------------------------------------------------------
  The stable-as-a-service business: take in a client's horse for raising or
  training, assign a trainer, move it through phases, hand it back. Drives the
  Trainer Panel and the Overview's operations. Training income posts to the
  society ledger via Business.postLedger.

  Role scoping: a TRAINER sees only their own assignments; an OWNER/ADMIN sees
  the whole stable and may reassign. Registers its actions into the shared
  RequestManageAction dispatcher (Business.actions).

  Table: sovereign_client_horses.
=====================================================================]]--

Training = Training or {}

local function exec(sql, params)
    local p = promise.new(); Db.execute(sql, params, function(a) p:resolve(a or 0) end); return Citizen.Await(p)
end

local function tierBy(id)
    for _, t in ipairs((Config.Training and Config.Training.tiers) or {}) do
        if t.id == id then return t end
    end
    return nil
end

-- 0..100 progress from the received→ready window.
local function progressOf(row)
    local rec, rdy = tonumber(row.received_at), tonumber(row.ready_at)
    if not (rec and rdy and rdy > rec) then return (row.phase == 'ready' or row.phase == 'returned') and 100 or 0 end
    if row.phase == 'ready' or row.phase == 'returned' then return 100 end
    local now = os.time()
    return math.max(0, math.min(100, math.floor((now - rec) / (rdy - rec) * 100)))
end

local function shape(row)
    return {
        id = row.id, horse = row.horse_name, breed = row.breed, model = row.model,
        gender = row.gender, age = row.age, client = row.client_name, poBox = row.po_box,
        tier = row.tier, phase = row.phase, trainer = row.trainer_name, trainerCharid = row.trainer_charid,
        progress = progressOf(row), readyAt = tonumber(row.ready_at), notes = row.notes,
    }
end

-- The roster this viewer may see: a trainer's own, else the whole stable.
function Training.roster(stableId, role, charid)
    local rows
    if role == 'trainer' then
        rows = Db.awaitQuery('SELECT * FROM sovereign_client_horses WHERE stable_id = ? AND trainer_charid = ? ORDER BY phase, ready_at', { stableId, charid })
    else
        rows = Db.awaitQuery('SELECT * FROM sovereign_client_horses WHERE stable_id = ? ORDER BY phase, ready_at', { stableId })
    end
    local out = {}
    for _, r in ipairs(rows or {}) do out[#out + 1] = shape(r) end
    return out
end

-- Phase counts (for the stat pills). Optionally scoped to a trainer.
function Training.counts(stableId, trainerCharid)
    local where = trainerCharid and ' AND trainer_charid = ?' or ''
    local params = trainerCharid and { stableId, trainerCharid } or { stableId }
    local rows = Db.awaitQuery(
        'SELECT phase, COUNT(*) AS n FROM sovereign_client_horses WHERE stable_id = ?' .. where .. ' GROUP BY phase', params) or {}
    local c = { raising = 0, training = 0, ready = 0, returned = 0, total = 0 }
    for _, r in ipairs(rows) do
        local n = tonumber(r.n) or 0
        c[r.phase] = (c[r.phase] or 0) + n
        if r.phase ~= 'returned' then c.total = c.total + n end
    end
    return c
end

-- Trainer summary (for the owner's "Stable Trainers" list).
local function trainerSummary(stableId)
    local rows = Db.awaitQuery([[SELECT trainer_charid, trainer_name,
          SUM(phase='training') AS training, SUM(phase='raising') AS raising, COUNT(*) AS assigned
        FROM sovereign_client_horses
        WHERE stable_id = ? AND phase <> 'returned' AND trainer_charid IS NOT NULL
        GROUP BY trainer_charid, trainer_name]], { stableId }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = { charid = r.trainer_charid, name = r.trainer_name,
            assigned = tonumber(r.assigned) or 0, training = tonumber(r.training) or 0, raising = tonumber(r.raising) or 0 }
    end
    return out
end

--------------------------------------------------------------------------------
-- Data endpoint (the future Trainer Panel binds to this)
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestTrainingData, function(stableId)
    local src = source
    if not (stableId and Config.Stables[stableId]) then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src); if not charid then return end
        local role = Management.isAdmin(src) and 'admin' or Management.roleAt(src, stableId, charid)
        if not role then return end
        local isTrainerView = (role == 'trainer')
        TriggerClientEvent(Events.TrainingData, src, {
            stableId = stableId,
            role = role,
            roster   = Training.roster(stableId, role, charid),
            counts   = Training.counts(stableId, isTrainerView and charid or nil),
            trainers = (not isTrainerView) and trainerSummary(stableId) or nil,
            tiers    = Config.Training and Config.Training.tiers or {},
        })
    end)
end)

--------------------------------------------------------------------------------
-- Actions (registered into the shared dispatcher)
--------------------------------------------------------------------------------
local function assignedTrainerOf(id, stableId)
    local r = Db.awaitQuery('SELECT trainer_charid FROM sovereign_client_horses WHERE id = ? AND stable_id = ?', { id, stableId })
    return r and r[1] and r[1].trainer_charid or nil
end

-- Take a client horse in. A trainer may intake to their OWN roster; owner/admin
-- for any trainer. Bills the client (posts the tier price to the ledger).
Business.actions.intake = function(src, stableId, charid, p)
    local manages = Business.canManage(src, stableId, charid)
    local role = Management.roleAt(src, stableId, charid)
    local mayIntake = manages or ((Config.Training and Config.Training.trainersMayIntake) and role == 'trainer')
    if not mayIntake then return false, 'Not allowed.' end

    local horse = tostring(p.horse or ''):sub(1, 64)
    local client = tostring(p.client or ''):sub(1, 64)
    if horse == '' or client == '' then return false, 'Need a horse and a client name.' end
    local tier = tierBy(p.tier) or (Config.Training and Config.Training.tiers[1])
    if not tier then return false, 'No training tiers configured.' end

    -- Trainer assignment: owner/admin may name one; a trainer takes it themselves.
    local trainerCharid = manages and (tonumber(p.trainerCharid) or charid) or charid
    local trainerName = Business.nameOfCharid(trainerCharid) or 'Trainer'
    local received = os.time()
    local ready = received + (tonumber(tier.days) or 7) * 86400

    exec([[INSERT INTO sovereign_client_horses
             (stable_id, horse_name, breed, model, gender, age, client_name, client_charid, po_box,
              tier, phase, trainer_charid, trainer_name, received_at, ready_at, created_by)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)]],
        { stableId, horse, p.breed, p.model, p.gender, p.age, client, tonumber(p.clientCharid), p.poBox,
          tier.id, tier.startPhase or 'raising', trainerCharid, trainerName, received, ready, charid })

    if (tonumber(tier.price) or 0) > 0 then
        Business.postLedger(stableId, ('Intake · %s'):format(horse), 'service', charid,
            Business.nameOfCharid(charid), tonumber(tier.price), 0)
    end
    return true, ('%s taken in (%s).'):format(horse, tier.label)
end

-- Set/advance the phase. Owner/admin, or the horse's own trainer.
Business.actions.setPhase = function(src, stableId, charid, p)
    local id = tonumber(p.id); local phase = tostring(p.phase or '')
    local valid = false
    for _, ph in ipairs((Config.Training and Config.Training.phases) or {}) do if ph == phase then valid = true end end
    if not (id and valid) then return false, 'Invalid phase.' end
    local mine = tostring(assignedTrainerOf(id, stableId)) == tostring(charid)
    if not (Business.canManage(src, stableId, charid) or mine) then return false, 'Not your assignment.' end
    exec('UPDATE sovereign_client_horses SET phase = ? WHERE id = ? AND stable_id = ?', { phase, id, stableId })
    return true, ('Moved to %s.'):format(phase)
end

-- Mark ready for pickup.
Business.actions.markReady = function(src, stableId, charid, p)
    p.phase = 'ready'; return Business.actions.setPhase(src, stableId, charid, p)
end

-- Return the horse to its owner: mark returned (kept for history/audit).
Business.actions.returnHorse = function(src, stableId, charid, p)
    p.phase = 'returned'; return Business.actions.setPhase(src, stableId, charid, p)
end

-- Trainer notes for a horse (the assigned trainer or a manager).
Business.actions.trainerNote = function(src, stableId, charid, p)
    local id = tonumber(p.id)
    if not id then return false, 'Which horse?' end
    local mine = tostring(assignedTrainerOf(id, stableId)) == tostring(charid)
    if not (Business.canManage(src, stableId, charid) or mine) then return false, 'Not your assignment.' end
    exec('UPDATE sovereign_client_horses SET notes = ? WHERE id = ? AND stable_id = ?', { tostring(p.notes or ''):sub(1, 1000), id, stableId })
    return true, 'Note saved.'
end

-- Reassign a horse to another trainer (owner/admin only).
Business.actions.reassign = function(src, stableId, charid, p)
    if not Business.canManage(src, stableId, charid) then return false, 'Not allowed.' end
    local id = tonumber(p.id); local newTrainer = tonumber(p.trainerCharid)
    if not (id and newTrainer) then return false, 'Pick a horse and a trainer.' end
    exec('UPDATE sovereign_client_horses SET trainer_charid = ?, trainer_name = ? WHERE id = ? AND stable_id = ?',
        { newTrainer, Business.nameOfCharid(newTrainer) or 'Trainer', id, stableId })
    return true, 'Reassigned.'
end
