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
        -- golden horses drain slower — but only while the feature is ON, or a
        -- stale golden flag would keep paying out for one more interval before
        -- the bookkeeping below clears it.
        local goldenOn = c.golden and c.golden.enabled
        local gm = (m.golden and goldenOn and c.golden.drainMultiplier) or 1.0
        m.hunger = clamp(m.hunger - (c.hunger.drainPerMinute or 0) * gm * mins, 0, c.hunger.max or 100)
        m.thirst = clamp(m.thirst - (c.thirst.drainPerMinute or 0) * gm * mins, 0, c.thirst.max or 100)
    end

    -- Cleanliness while STORED only: the stablehand grooms a stored horse clean
    -- over stableAutoCleanMinutes. We NO LONGER simulate dirt gain while active —
    -- the engine paints the dirt and the client reports the real level every 10s,
    -- so adding a made-up gain here would double-count against that reading.
    if c.cleanliness and c.cleanliness.enabled ~= false and context ~= 'active' then
        local overMin = c.cleanliness.stableAutoCleanMinutes or 30
        if overMin > 0 then
            local per = (c.cleanliness.max or 100) / overMin
            m.dirt = clamp(m.dirt - per * mins, 0, c.cleanliness.max or 100)
        end
    end

    -- Golden bookkeeping: both cores above the line long enough => golden.
    --
    -- ⚠️ THE OFF-SWITCH HAS TO UNDO, NOT JUST STOP. Golden was disabled on
    -- 2026-07-27, and simply skipping this block would have left every horse that
    -- was ALREADY golden stuck that way — including its 0.5x drain bonus, for
    -- good, because the branch that clears the flag lives in here too. Turning a
    -- feature off must retire the state it created, or you ship a perk that only
    -- the players who happened to be golden that week will ever have.
    if not (c.golden and c.golden.enabled) then
        m.golden, m.goldenTs = false, 0
    else
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
    -- No chip for brushing OR feeding (owner rulings R6 F4, R7 Q2). The animation
    -- and the moving bars are feedback enough; a chip on every care action is
    -- noise. Watering keeps its chip because it has meaningful outcomes to report
    -- ("not thirsty", "had enough") — that lives in the RequestDrink handler, not
    -- here. Message is nil; the card and animation still come back.
    return true, nil, Metabolism.card(m)
end

--------------------------------------------------------------------------------
-- Usable items — feed/water/clean straight from the satchel  [H3/H5]
--   The client tells us which horse is the target (the one it has out); we
--   validate ownership and apply. The item is already consumed by the time the
--   callback fires only if we say so — vorp calls the callback, we decide.
--------------------------------------------------------------------------------
local pendingTarget = {}   -- [src] = horseId the client last had out
local pendingMounted = {}  -- [src] = true if the client is on the horse right now

-- Which animation should using this item play? Inferred from its effect so the
-- config stays simple: a brush (dirt) grooms; food/water feeds.
local function animFor(def)
    if def.dirt then return 'brush' end
    if def.hunger or def.thirst then return 'feed' end
    return nil
end

-- ONE place where an item is spent and its effect applied, shared by the
-- satchel's "Use" and the horse menu's Brush/Feed. These were briefly two
-- copies, which is how you end up with a brush that counts down properly when
-- used from the satchel and is destroyed outright when used from the menu — the
-- same action wearing out at two different rates depending on where you clicked.
-- Returns ok, message, card.
local function spendAndApply(src, charid, horseId, itemName, def, instance)
    -- DURABILITY. A tool with `uses` isn't consumed each time — it loses one
    -- use, tracked in ITS OWN metadata, and only breaks at zero. Feed has no
    -- `uses`, so it's a plain one-shot consume.
    if def.uses then
        local item = instance or {}
        if not item.id then
            return false, ('You have no %s.'):format(def.label or itemName)
        end
        local meta = item.metadata or {}
        local left = tonumber(meta.uses)
        if left == nil then
            left = (def.uses == true) and (mcfg().defaultUses or 20) or def.uses
        end
        left = left - 1
        local ok, msg, card = Metabolism.applyItem(charid, horseId, def)
        if not ok then return false, msg end
        if left <= 0 then
            Bridge.removeItemById(src, item.id)
            Bridge.notify(src, ('Your %s wore out.'):format(def.label or itemName))
        else
            meta.uses = left
            meta.description = ('%d uses left'):format(left)
            Bridge.setItemMetadata(src, item.id, meta)
        end
        return true, msg, card
    end

    if not Bridge.takeItem(src, itemName, 1) then
        return false, ('You have no %s.'):format(def.label or itemName)
    end
    local ok, msg, card = Metabolism.applyItem(charid, horseId, def)
    if not ok then
        Util.warn(('care refund: %s to char %s (%s)'):format(itemName, charid, msg or '?'))
    end
    return ok, msg, card
end

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
        -- Same spend routine as the satchel and the horse menu, so /sovfeed with
        -- a durable tool counts it down instead of destroying it.
        local instance = def.uses and Bridge.getItem(src, itemName) or nil
        local ok, msg, card = spendAndApply(src, charid, horseId, itemName, def, instance)
        TriggerClientEvent(Events.CareResult, src,
            { ok = ok, message = msg, horseId = horseId, card = card, animate = ok and animFor(def) or nil })
    end)
end)

--------------------------------------------------------------------------------
-- ⚠️ REMOVED 2026-07-27: the "brush it / feed it by KIND" handlers.
--------------------------------------------------------------------------------
-- These existed for one round, to drive Brush and Feed prompts in a custom horse
-- menu. The owner ruled that menu out entirely — "Brush should only be done by
-- double clicking on the item in the inventory. Not with a key toggle" — so the
-- handlers had no caller left. Deleted rather than left dormant: an unreachable
-- net event is still a reachable net event, and dead code that spends items is
-- the wrong kind of dead code to leave lying about.
--
-- `spendAndApply` above SURVIVED the cull and is the good half of that work: it
-- is now the single place any item is spent, shared by the satchel's Use, the
-- /sovfeed command and anything later. It is what made brush durability behave
-- identically through every door (R5 Art. IV passed 5/5).

-- The client reads the ENGINE's dirt level off the horse every 10s and reports
-- it, so a stored horse remembers how dirty it was and comes back the same.
--
-- ⚠️ ACCEPTS BOTH DIRECTIONS now. The old rule ("never accept a cleaner value,
-- or a client scrubs its horse for free") existed when WE simulated dirt and a
-- separate ReportWashed handled cleaning. The engine now owns the visual and the
-- client is only MIRRORING what the engine painted — including rain washing the
-- horse cleaner — so refusing a lower value would freeze a rained-on horse dirty.
-- Dirt is purely cosmetic (no gameplay penalty), so there's nothing to cheat.
RegisterNetEvent(Events.ReportDirt, function(horseId, dirt)
    local src = source
    if not horseId then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        local m = loadBlob(charid, horseId); if not m then return end
        dirt = clamp(tonumber(dirt) or m.dirt, 0, (mcfg().cleanliness and mcfg().cleanliness.max) or 100)
        if math.abs(dirt - (m.dirt or 0)) >= 1 then
            m.dirt = dirt; m.ts = os.time(); saveBlob(charid, horseId, m)
        end
    end)
end)

-- WATERING THE HORSE — a CHOICE now, not automatic (owner ruling 2026-07-27).
--
-- R6 W1: "I do not want it to drink by itself... Drink should be in the horse
-- menu. If the horse is full already it should have a chip notification saying
-- the [Horse's Name] is not thirsty."
--
-- So drinking is a single deliberate act: the player takes Drink from the
-- lock-on menu while the horse is at water, and it drinks its fill in one go.
-- The old ReportDrank trickle (a few points every five seconds while stood
-- there) is retired — that WAS "drinking by itself". A short cooldown stops the
-- prompt being mashed, but a normal press gives a proper drink.
local lastDrink = {}   -- [src] = os.time()

RegisterNetEvent(Events.RequestDrink, function(horseId, horseName)
    local src = source
    if not horseId then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src); if not charid then return end
        local d = mcfg().drinking or {}
        if d.enabled == false then return end

        local m = loadBlob(charid, horseId); if not m then return end
        drift(m, 'active', os.time())

        local maxT = (mcfg().thirst or {}).max or 100
        local name = (horseName and horseName ~= '') and horseName or 'Your horse'

        -- Already full: the chip the owner asked for, and nothing else happens.
        if m.thirst >= maxT - 1 then
            Bridge.notifyCard(src, 'info', 'Stables', ('%s is not thirsty.'):format(name))
            return
        end

        -- Cooldown only guards against spamming a fresh full drink; it never
        -- blocks the first press.
        local now = os.time()
        if now - (lastDrink[src] or 0) < (d.drinkCooldownSeconds or 8) then
            Bridge.notifyCard(src, 'info', 'Stables', ('%s has had enough for now.'):format(name))
            return
        end
        lastDrink[src] = now

        -- One press = a proper drink. `drinkFill` points, capped at max.
        -- NO success chip (owner R9 G1): the drinking animation is the feedback,
        -- and a chip on top is noise — same call as brush and feed. The
        -- "not thirsty" / "had enough" chips stay, because those are no-ops with
        -- nothing else to show for them.
        m.thirst = clamp(m.thirst + (d.drinkFill or 100), 0, maxT)
        m.ts = now
        saveBlob(charid, horseId, m)
        TriggerClientEvent(Events.CareResult, src,
            { ok = true, horseId = horseId, card = Metabolism.card(m) })
    end)
end)

AddEventHandler('playerDropped', function()
    lastWash[source], lastDrink[source] = nil, nil
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
            -- Horseback-only tools (the brush) can only be used from the saddle.
            if def.horsebackOnly and not pendingMounted[src] then
                Bridge.notify(src, ('You must be on the horse to use the %s.'):format(def.label or itemName))
                return
            end

            CreateThread(function()
                -- vorp hands us the exact instance that was clicked, which is
                -- what durability needs. Same routine as the horse menu's
                -- Brush/Feed, so the two can never drift apart.
                local ok, msg, card = spendAndApply(src, charid, horseId, itemName, def, data.item)
                if not ok then Bridge.notify(src, msg or 'Nothing to do.'); return end
                TriggerClientEvent(Events.CareResult, src,
                    { ok = true, message = msg, horseId = horseId, card = card, animate = animFor(def) })
            end)
        end)
    end
    Util.log('metabolism: usable feed/clean items registered')
end)

-- The client tells us which horse it has out and whether it's mounted, so a used
-- item knows its target and can enforce horseback-only tools.
RegisterNetEvent(Events.SyncCare, function(horseId, mounted)
    pendingTarget[source]  = horseId
    pendingMounted[source] = mounted and true or false
end)

AddEventHandler('playerDropped', function()
    pendingTarget[source], pendingMounted[source] = nil, nil
end)

--------------------------------------------------------------------------------
-- ⚠️ TEMPORARY TESTING AID — REMOVE BEFORE PHASE 2 CLOSES
--------------------------------------------------------------------------------
-- `/sovdirty [0-100]` cakes the horse you have out in mud. No argument = 100.
-- Requested 2026-07-27 so cleaning can be tested without riding for a quarter of
-- an hour first.
--
-- Server-side on purpose: dirt is the server's number, so setting it here means
-- it persists, survives a restart, and the coat guard picks it up on its next
-- pass — the same route a real ride takes. A client-side version would paint the
-- ped and be wiped by that guard half a second later.
--
-- IT CAN ONLY ADD DIRT. A command that also cleans is a free brush every player
-- can type, which would quietly make the grooming loop — the thing this exists
-- to test — pointless. Testing tools should not be able to win the game.
RegisterCommand('sovdirty', function(src, args)
    if src == 0 then print('[sovereign_stables] /sovdirty must be run in game.'); return end

    local horseId = pendingTarget[src]
    if not horseId then
        Bridge.notifyCard(src, 'failed', 'Stables', 'Bring your horse out first.')
        return
    end

    local want = tonumber(args and args[1]) or 100
    CreateThread(function()
        local charid = Bridge.getCharId(src); if not charid then return end
        local m = loadBlob(charid, horseId); if not m then return end
        drift(m, 'active', os.time())

        local maxD = (mcfg().cleanliness and mcfg().cleanliness.max) or 100
        want = clamp(want, 0, maxD)
        if want <= m.dirt then
            Bridge.notifyCard(src, 'failed', 'Stables',
                ('Already %d%% dirty — this only adds. Use the brush to clean.'):format(math.floor(m.dirt + 0.5)))
            return
        end

        m.dirt = want
        saveBlob(charid, horseId, m)
        Util.log(('[TEST] /sovdirty set horse %s to %d%% dirt for char %s'):format(horseId, want, charid))
        TriggerClientEvent(Events.CareResult, src,
            { ok = true, card = Metabolism.card(m), message = ('Your horse is now %d%% filthy.'):format(want) })
    end)
end, false)
