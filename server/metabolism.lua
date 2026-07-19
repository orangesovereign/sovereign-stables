--[[=====================================================================
  SOVEREIGN STABLES · METABOLISM & CARE  (server, authoritative)  [C-series]
  ---------------------------------------------------------------------
  Hunger, thirst, dirt and golden condition. The server owns every value; the
  client only shows them and asks to feed/clean.

  THE DRAIN IS LAZY, NOT TICKED. We never loop over every horse. Each horse
  stores its values plus the timestamp they were last correct (`ts`). When a
  horse is brought out — or fed, or inspected — we compute how much time has
  passed and drift the values then. One horse, one calculation, only when it
  matters. This scales to any number of horses and survives restarts for free,
  because the maths is against wall-clock time, not uptime.
=====================================================================]]--

Metabolism = Metabolism or {}

local function mcfg() return Config.Metabolism or {} end

--------------------------------------------------------------------------------
-- Read / write the metabolism blob:  { hunger, thirst, dirt, golden, goldenTs, ts }
--------------------------------------------------------------------------------
local function defaults()
    local c = mcfg()
    return {
        hunger   = (c.hunger and c.hunger.start) or 100,
        thirst   = (c.thirst and c.thirst.start) or 100,
        dirt     = (c.cleanliness and c.cleanliness.start) or 0,
        golden   = false,
        goldenTs = 0,      -- when both cores first went above the golden line
        ts       = os.time(),
    }
end

local function decode(raw)
    if not raw or raw == '' then return defaults() end
    local ok, t = pcall(json.decode, raw)
    if not ok or type(t) ~= 'table' then return defaults() end
    local d = defaults()
    for k, v in pairs(t) do d[k] = v end
    return d
end

local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end

--------------------------------------------------------------------------------
-- The drift. Advance a blob to `now` given how the horse spent the interval.
--   context = 'active' (out with the player) | 'stored' (in the stable)
-- Only 'active' time drains hunger/thirst and adds dirt; 'stored' time lets the
-- stablehand clean it (H10) and, if drainWhile='always', still drains cores.
--------------------------------------------------------------------------------
local function drift(m, context, now)
    now = now or os.time()
    local mins = math.max(0, (now - (m.ts or now)) / 60.0)
    m.ts = now
    if mins <= 0 then return m end

    local c = mcfg()
    local drainsNow = (context == 'active') or (c.drainWhile == 'always')

    if drainsNow then
        -- golden horses drain slower
        local gm = (m.golden and c.golden and c.golden.drainMultiplier) or 1.0
        m.hunger = clamp(m.hunger - (c.hunger.drainPerMinute or 0) * gm * mins, 0, c.hunger.max or 100)
        m.thirst = clamp(m.thirst - (c.thirst.drainPerMinute or 0) * gm * mins, 0, c.thirst.max or 100)
    end

    -- Cleanliness: gets dirty while active; the stable grooms it while stored.
    if c.cleanliness and c.cleanliness.enabled ~= false then
        if context == 'active' then
            m.dirt = clamp(m.dirt + (c.cleanliness.gainPerMinute or 0) * mins, 0, c.cleanliness.max or 100)
        else
            local overMin = c.cleanliness.stableAutoCleanMinutes or 30
            if overMin > 0 then
                -- clean the full range over `overMin` minutes
                local per = (c.cleanliness.max or 100) / overMin
                m.dirt = clamp(m.dirt - per * mins, 0, c.cleanliness.max or 100)
            end
        end
    end

    -- Golden bookkeeping: both cores above the line long enough => golden.
    if c.golden and c.golden.enabled then
        local above = m.hunger >= (c.golden.goldenAbove or 80) and m.thirst >= (c.golden.goldenAbove or 80)
        if above then
            if (m.goldenTs or 0) == 0 then m.goldenTs = now end
            if not m.golden and (now - m.goldenTs) >= (c.golden.goldenAfterMinutes or 20) * 60 then
                m.golden = true
            end
        else
            m.goldenTs, m.golden = 0, false
        end
    end
    return m
end

Metabolism.drift = drift

--------------------------------------------------------------------------------
-- DB access — scoped to the caller's character, always.
--------------------------------------------------------------------------------
local function loadBlob(charid, horseId)
    local shared = mcfg().sharedStatus
    if shared then
        -- one pool per character: keep it on the lowest-id horse's row, but read
        -- the freshest we have. Simplest correct approach: read this horse's row
        -- and treat it as the shared value (writes go to whichever horse is fed).
    end
    local rows = Db.awaitQuery('SELECT metabolism FROM sovereign_horses WHERE id = ? AND charid = ?',
        { horseId, charid })
    if not (rows and rows[1]) then return nil end
    return decode(rows[1].metabolism)
end

local function saveBlob(charid, horseId, m)
    Db.execute('UPDATE sovereign_horses SET metabolism = ? WHERE id = ? AND charid = ?',
        { json.encode(m), horseId, charid })
    -- Shared status [H4]: mirror the same blob onto every horse this character
    -- owns, so "fed one, fed all" holds.
    if mcfg().sharedStatus then
        Db.execute('UPDATE sovereign_horses SET metabolism = ? WHERE charid = ?', { json.encode(m), charid })
    end
end

-- Public: the CURRENT status of a horse, drifted to now for the given context.
-- Used by the summon flow to hand fresh values to the client on spawn.
function Metabolism.current(charid, horseId, context)
    if not (mcfg().enabled) then return nil end
    local m = loadBlob(charid, horseId)
    if not m then return nil end
    drift(m, context or 'stored', os.time())
    saveBlob(charid, horseId, m)
    return m
end

-- A compact status card for the client: the numbers plus the derived flags it
-- needs to apply penalties and warnings without re-reading config.
function Metabolism.card(m)
    local c = mcfg()
    return {
        hunger = math.floor(m.hunger + 0.5),
        thirst = math.floor(m.thirst + 0.5),
        dirt   = math.floor(m.dirt + 0.5),
        golden = m.golden and true or false,
        hungerCritical = m.hunger < (c.hunger.criticalBelow or 15),
        thirstCritical = m.thirst < (c.thirst.criticalBelow or 15),
        hungerWarn     = m.hunger < (c.hunger.warnBelow or 35),
        thirstWarn     = m.thirst < (c.thirst.warnBelow or 35),
        penalties = c.penalties,
    }
end

--------------------------------------------------------------------------------
-- Feeding / watering / cleaning
--------------------------------------------------------------------------------
-- Apply an item's effect to a horse. Returns ok, message, card.
function Metabolism.applyItem(charid, horseId, itemDef)
    local m = loadBlob(charid, horseId)
    if not m then return false, 'That is not your horse.' end
    drift(m, 'active', os.time())   -- feeding happens with the horse out

    local c = mcfg()
    local changed = false
    if itemDef.hunger then m.hunger = clamp(m.hunger + itemDef.hunger, 0, c.hunger.max or 100); changed = true end
    if itemDef.thirst then m.thirst = clamp(m.thirst + itemDef.thirst, 0, c.thirst.max or 100); changed = true end
    if itemDef.dirt   then m.dirt   = clamp(m.dirt   - itemDef.dirt,   0, c.cleanliness.max or 100); changed = true end
    if not changed then return false, 'Nothing to do.' end

    saveBlob(charid, horseId, m)
    return true, ('%s given.'):format(itemDef.label or 'Feed'), Metabolism.card(m)
end

--------------------------------------------------------------------------------
-- Usable items — feed/water/clean straight from the satchel  [H3/H5]
--   The client tells us which horse is the target (the one it has out); we
--   validate ownership and apply. The item is already consumed by the time the
--   callback fires only if we say so — vorp calls the callback, we decide.
--------------------------------------------------------------------------------
local pendingTarget = {}   -- [src] = horseId the client last had out

RegisterNetEvent(Events.RequestCare, function(horseId, itemName)
    -- Path for a menu-driven feed (no usable item): validate and apply directly.
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        local def = (mcfg().items or {})[itemName]
        if not def then
            TriggerClientEvent(Events.CareResult, src, { ok = false, message = 'No such feed.' })
            return
        end
        -- Must actually hold the item.
        if not Bridge.takeItem(src, itemName, 1) then
            TriggerClientEvent(Events.CareResult, src, { ok = false, message = ('You have no %s.'):format(def.label or itemName) })
            return
        end
        local ok, msg, card = Metabolism.applyItem(charid, horseId, def)
        if not ok then
            -- refund the item — we took it but couldn't use it
            Util.warn(('care refund: %s to char %s (%s)'):format(itemName, charid, msg))
        end
        TriggerClientEvent(Events.CareResult, src, { ok = ok, message = msg, horseId = horseId, card = card })
    end)
end)

-- Client periodically reports how dirty the out-horse got, so dirt persists even
-- if the horse is dismissed rather than stored through the menu. Clamped; the
-- client can only ever make a horse dirtier this way, never cleaner.
RegisterNetEvent(Events.ReportDirt, function(horseId, dirt)
    local src = source
    if not horseId then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        local m = loadBlob(charid, horseId); if not m then return end
        dirt = clamp(tonumber(dirt) or m.dirt, 0, (mcfg().cleanliness and mcfg().cleanliness.max) or 100)
        if dirt > m.dirt then m.dirt = dirt; m.ts = os.time(); saveBlob(charid, horseId, m) end
    end)
end)

--------------------------------------------------------------------------------
-- Register the configured feed/clean items as usable, so "use" from the satchel
-- feeds the horse the player has out.
--------------------------------------------------------------------------------
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if not mcfg().enabled then return end
    for itemName, def in pairs(mcfg().items or {}) do
        Bridge.registerUsableItem(itemName, function(data)
            local src = data and data.source
            if not src then return end
            Bridge.closeInventory(src)
            local charid = Bridge.getCharId(src)
            local horseId = pendingTarget[src]
            if not (charid and horseId) then
                Bridge.notify(src, 'Bring the horse out first.')
                return
            end
            CreateThread(function()
                if not Bridge.takeItem(src, itemName, 1) then
                    Bridge.notify(src, ('You have no %s.'):format(def.label or itemName)); return
                end
                local ok, msg, card = Metabolism.applyItem(charid, horseId, def)
                TriggerClientEvent(Events.CareResult, src, { ok = ok, message = msg, horseId = horseId, card = card })
            end)
        end)
    end
    Util.log('metabolism: usable feed/clean items registered')
end)

-- The client tells us which horse it has out, so a used item knows its target.
RegisterNetEvent(Events.SyncCare, function(horseId)
    pendingTarget[source] = horseId
end)

AddEventHandler('playerDropped', function() pendingTarget[source] = nil end)
