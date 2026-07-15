--[[=====================================================================
  SOVEREIGN STABLES · JOB PERMISSIONS RESOLVER
  ---------------------------------------------------------------------
  Merges config/jobs.lua (per-job overrides over JobDefaults, then per-GRADE
  overrides over those) and folds in the global caps from config/config.lua.
  One place decides "may this character do X, and how many may they own" —
  server and client agree.

  ⚠️ GRADES ARE ROLES, NOT RANKS  (owner ruling, 2026-07-15)
  A grade's permission block is applied WHOLE and is NEVER rolled up from the
  grades beneath it. Grade 2 is not "more than" grade 1 — the numbers are
  names. This exists because the stable's grades are peers with different
  trades: a Wagon Maker (2) has storefronts but cannot train horses, while a
  Horse Trainer (0) can train but has no storefronts. Neither contains the
  other, so no ladder can express them.

  If you ever feel tempted to make higher grades inherit from lower ones:
  don't. A Wagon Maker would silently gain horse training, which is the exact
  bug the ruling exists to prevent. See docs/07-HORSE-TRAINER.md.
=====================================================================]]--

Perms = Perms or {}

local function merge(into, from)
    for k, v in pairs(from or {}) do
        if k ~= 'grades' then into[k] = v end   -- never leak the grade table itself
    end
    return into
end

-- Full permission table for a job at a grade.
--   JobDefaults  <-  Config.Jobs[job]  <-  Config.Jobs[job].grades[grade]
-- Later layers win. `grade` is optional; omit it and you get the job-wide
-- values only, which is what a non-job-holder or an ungraded job resolves to.
function Perms.get(job, grade)
    local out = {}
    merge(out, Config.JobDefaults)
    merge(out, (Config.Jobs or {})[job or ''])

    local jobCfg = (Config.Jobs or {})[job or '']
    if jobCfg and jobCfg.grades and grade ~= nil then
        local g = jobCfg.grades[tonumber(grade) or -1]
        if g then merge(out, g) end
    end
    return out
end

-- The grade's display title, or nil.
function Perms.title(job, grade)
    local jobCfg = (Config.Jobs or {})[job or '']
    local g = jobCfg and jobCfg.grades and jobCfg.grades[tonumber(grade) or -1]
    return g and g.title
end

--------------------------------------------------------------------------------
-- CAPS
--   `Config.Caps` is the BASELINE everyone gets. A job (or grade) that sets its
--   own cap REPLACES it — higher or lower.
--
--   ⚠️ This used to be math.min(global, job), i.e. the global clamped the job.
--   That silently broke two rulings at once: the Horse Trainer's "higher horse
--   cap" (8) resolved to 3, and the owner's "wagon limit should be 5" resolved
--   to 1, because JobDefaults still said 1 and min() picked it. A job perk that
--   can never exceed the default isn't a perk. Caught by tests/perms_spec.py.
--------------------------------------------------------------------------------
function Perms.maxHorses(job, grade)
    local p = Perms.get(job, grade)
    return p.maxHorses or (Config.Caps and Config.Caps.maxHorses) or 3
end

function Perms.maxWagons(job, grade)
    local p = Perms.get(job, grade)
    return p.maxWagons or (Config.Caps and Config.Caps.maxWagons) or 1
end

-- Total stored slots (horses + wagons) allowed.
function Perms.maxSlots()
    return (Config.Caps and Config.Caps.maxStableSlots) or 3
end

-- Generic boolean gate, e.g. Perms.can(job, grade, 'training').
function Perms.can(job, grade, key)
    local p = Perms.get(job, grade)
    return p[key] == true
end
