--[[=====================================================================
  SOVEREIGN STABLES · SUMMON & FIELD  (server, authoritative)
  ---------------------------------------------------------------------
  Decides whether a horse may come out: do you own it, is it allowed to be
  whistled, is it dead or on cooldown. The client spawns the ped, but only
  with data the server hands it — and death/hard-death bookkeeping is ours.
=====================================================================]]--

Summon = Summon or {}

-- [charid][horseId] = os.time() when it may be called again
local cooldowns = {}

local function cdGet(charid, horseId)
    local c = cooldowns[charid]
    return (c and c[horseId]) or 0
end

local function cdSet(charid, horseId, seconds)
    cooldowns[charid] = cooldowns[charid] or {}
    cooldowns[charid][horseId] = os.time() + (seconds or 0)
end

-- One owned horse row, scoped to the caller (never trust a client id).
local function ownedHorse(charid, horseId)
    local rows = Db.awaitQuery(
        'SELECT id, name, model, is_default, stable_origin, long_term_hp, components FROM sovereign_horses WHERE id = ? AND charid = ?',
        { horseId, charid })
    return rows and rows[1]
end

local function defaultHorse(charid)
    local rows = Db.awaitQuery(
        'SELECT id, name, model, is_default, stable_origin, long_term_hp, components FROM sovereign_horses WHERE charid = ? ORDER BY is_default DESC, id ASC LIMIT 1',
        { charid })
    return rows and rows[1]
end

-- May this model be whistled from anywhere, or must it be collected? [S6]
local function whistleAllowed(model)
    local card = Catalog.horse(model)
    if card and card.whistle ~= nil then return card.whistle end
    return (Config.Summon and Config.Summon.whistleAllowedByDefault) ~= false
end

-- Shared gate for both whistle and stable pick-up.
-- Returns ok, payloadOrMessage
local function authorize(src, row, requireWhistle)
    if not row then return false, 'You keep no horse.' end
    local charid = Bridge.getCharId(src)

    if requireWhistle and not whistleAllowed(row.model) then
        return false, 'That one waits for you at the stable.'
    end

    local until_ = cdGet(charid, row.id)
    local left = until_ - os.time()
    if left > 0 then
        return false, ('Give it a moment — %ds.'):format(left)
    end

    return true, {
        id         = row.id,
        name       = row.name,
        model      = row.model,
        components = row.components,
    }
end

--------------------------------------------------------------------------------
-- Net events
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestSummon, function()
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        local ok, res = authorize(src, defaultHorse(charid), true)
        TriggerClientEvent(Events.SummonResult, src,
            ok and { ok = true, horse = res } or { ok = false, message = res })
    end)
end)

RegisterNetEvent(Events.RequestBringOut, function(horseId)
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        -- Collected in person at a stable: no whistle rule applies.
        local ok, res = authorize(src, ownedHorse(charid, horseId), false)
        TriggerClientEvent(Events.SummonResult, src,
            ok and { ok = true, horse = res } or { ok = false, message = res })
    end)
end)

-- Horse sent away: start the recall cooldown.
RegisterNetEvent(Events.ReportDismiss, function(horseId)
    local src = source
    local charid = Bridge.getCharId(src)
    if not charid or not horseId then return end
    cdSet(charid, horseId, (Config.Summon and Config.Summon.recallCooldownSeconds) or 30)
end)

-- Horse died: hard-death bookkeeping. The client only reports THAT it died;
-- the damage and the permanent-death ruling are made here.
RegisterNetEvent(Events.ReportDeath, function(horseId)
    local src = source
    if not horseId then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        local row = ownedHorse(charid, horseId)
        if not row then return end

        local wait = (Config.Death and Config.Death.deadRespawnSeconds)
            or (Config.Summon and Config.Summon.deadRespawnSeconds) or 120
        cdSet(charid, horseId, wait)

        if not (Config.Death and Config.Death.hardDeath) then
            Util.log(('horse %s died (char %s) — soft death'):format(horseId, charid))
            return
        end

        -- Flat toll per death for now; per-reason damage tables land in Phase 3.
        local toll = 25
        local hp = math.max(0, (tonumber(row.long_term_hp) or 100) - toll)
        Db.execute('UPDATE sovereign_horses SET long_term_hp = ? WHERE id = ? AND charid = ?', { hp, horseId, charid })

        if hp <= 0 then
            Db.execute('DELETE FROM sovereign_horses WHERE id = ? AND charid = ?', { horseId, charid })
            Db.execute('INSERT INTO sovereign_ledger (charid, action, subject, cash, gold, meta) VALUES (?, ?, ?, 0, 0, ?)',
                { charid, 'horse_lost', row.model, json.encode({ horseId = horseId, reason = 'hard_death' }) })
            Bridge.notifyCard(src, 'failed', 'Stables', ('%s is gone for good.'):format(row.name or 'Your horse'))
            Util.log(('horse %s PERMANENTLY dead (char %s)'):format(horseId, charid))
        else
            Bridge.notifyCard(src, 'failed', 'Stables', ('%s is badly hurt (%d%%).'):format(row.name or 'Your horse', hp))
            Util.log(('horse %s died (char %s) — long-term hp now %d'):format(horseId, charid, hp))
        end
    end)
end)

AddEventHandler('playerDropped', function()
    local charid = Bridge.getCharId(source)
    if charid then cooldowns[charid] = nil end
end)
