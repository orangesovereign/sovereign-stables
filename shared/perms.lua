--[[=====================================================================
  SOVEREIGN STABLES · JOB PERMISSIONS RESOLVER
  ---------------------------------------------------------------------
  Merges config/jobs.lua (per-job overrides over JobDefaults) and folds in the
  global caps from config/config.lua. One place decides "may this character do
  X, and how many may they own" — server and client agree.
=====================================================================]]--

Perms = Perms or {}

-- Full permission table for a job (defaults + that job's overrides).
function Perms.get(job)
    local out = {}
    for k, v in pairs(Config.JobDefaults or {}) do out[k] = v end
    for k, v in pairs((Config.Jobs or {})[job or ''] or {}) do out[k] = v end
    return out
end

-- The effective horse cap: the stricter of the global cap and the job cap.
function Perms.maxHorses(job)
    local p = Perms.get(job)
    local globalCap = (Config.Caps and Config.Caps.maxHorses) or 3
    local jobCap = p.maxHorses or globalCap
    return math.min(globalCap, jobCap)
end

function Perms.maxWagons(job)
    local p = Perms.get(job)
    local globalCap = (Config.Caps and Config.Caps.maxWagons) or 1
    local jobCap = p.maxWagons or globalCap
    return math.min(globalCap, jobCap)
end

-- Total stored slots (horses + wagons) allowed.
function Perms.maxSlots()
    return (Config.Caps and Config.Caps.maxStableSlots) or 3
end

-- Generic boolean gate, e.g. Perms.can(job, 'breeding').
function Perms.can(job, key)
    local p = Perms.get(job)
    return p[key] == true
end
