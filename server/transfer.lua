--[[=====================================================================
  SOVEREIGN STABLES · TRANSFER  (server, authoritative)
  ---------------------------------------------------------------------
  Hand a horse or a wagon to another player, identified by their SERVER
  SESSION ID — "hat size" in RP. Ownership genuinely moves: the row's
  charid changes. There is no lending flag and no shared access.

  ⚠️ PHASE 3 DEPENDS ON THIS FILE. The Horse Trainer's custody transfer is
  not a lockout flag — it is a real change of ownership using this exact
  system (07-HORSE-TRAINER: "the horse is unusable during training… not a
  lockout flag, but genuine change of ownership"). Two hooks are already
  in place for it:
      • `reason` ('gift' | 'custody' | 'sale') is carried to the ledger, so
        a custody move is distinguishable from a sale in the audit trail.
      • `ignoreCap` lets a trainer take work without their own cap locking
        them out (Config.Training.heldHorsesIgnoreCap).
  Do not collapse those away as unused — they are the seam Phase 3 needs.
=====================================================================]]--

Transfer = Transfer or {}

-- [targetSrc] = { from, kind, assetId, name, expires, reason, ignoreCap }
local offers  = {}
local pending = {}   -- [src] = true while a transfer is resolving

local function cfg()
    return Config.Transfer or {}
end

local function logLedger(charid, action, subject, meta)
    if not (Config.Economy and Config.Economy.transactionLog) then return end
    Db.execute('INSERT INTO sovereign_ledger (charid, action, subject, cash, gold, meta) VALUES (?, ?, ?, 0, 0, ?)',
        { charid, action, subject, meta and json.encode(meta) or nil })
end

local function charName(src)
    local ch = Bridge.getCharacter(src)
    if not ch then return 'Someone' end
    local first, last = ch.firstname, ch.lastname
    if first or last then return ((first or '') .. ' ' .. (last or '')):gsub('^%s+', ''):gsub('%s+$', '') end
    return 'Someone'
end

--------------------------------------------------------------------------------
-- Asset abstraction — horses and wagons transfer identically, so the rules are
-- written once and the table below is the only thing that differs.
--------------------------------------------------------------------------------
local KINDS = {
    horse = {
        table   = 'sovereign_horses',
        label   = 'horse',
        cap     = function(job) return Perms.maxHorses(job) end,
        count   = function(charid) return Horses.countOwned(charid) end,
        ledger  = 'transfer_horse',
    },
    wagon = {
        table   = 'sovereign_wagons',
        label   = 'wagon',
        cap     = function(job) return Perms.maxWagons(job) end,
        count   = function(charid) return Wagons.countOwned(charid) end,
        ledger  = 'transfer_wagon',
    },
}

-- Fetch a row ONLY if this character owns it. Never trust a client-supplied id.
local function ownedAsset(kind, charid, assetId)
    local k = KINDS[kind]; if not k then return nil end
    local rows = Db.awaitQuery(
        ('SELECT id, name, model, is_default FROM %s WHERE id = ? AND charid = ?'):format(k.table),
        { assetId, charid })
    return rows and rows[1]
end

local function playersInRange(a, b, maxDist)
    if not maxDist or maxDist <= 0 then return true end
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if not pa or not pb or pa == 0 or pb == 0 then return false end
    local ca, cb = GetEntityCoords(pa), GetEntityCoords(pb)
    return #(ca - cb) <= maxDist
end

--------------------------------------------------------------------------------
-- Offer
--------------------------------------------------------------------------------
-- Returns ok, message. `opts` = { reason = 'gift'|'custody'|'sale', ignoreCap = bool }
function Transfer.offer(src, kind, assetId, targetSrc, opts)
    opts = opts or {}
    if cfg().enabled == false then return false, 'Transfers are closed.' end

    local k = KINDS[kind]
    if not k then return false, 'You cannot hand that over.' end
    if kind == 'wagon' and cfg().allowWagons == false then
        return false, 'Wagons stay with their owner.'
    end

    targetSrc = tonumber(targetSrc)
    if not targetSrc then return false, 'That is not a hat size.' end
    if targetSrc == src then return false, 'You already own it.' end

    local charid = Bridge.getCharId(src)
    if not charid then return false, 'No active character.' end

    local targetChar = Bridge.getCharId(targetSrc)
    if not targetChar then return false, 'Nobody is wearing that hat size.' end

    local row = ownedAsset(kind, charid, assetId)
    if not row then return false, ('That is not your %s.'):format(k.label) end

    if not playersInRange(src, targetSrc, cfg().maxDistance or 5.0) then
        return false, 'They need to be standing with you.'
    end

    -- One offer at a time, each way.
    if offers[targetSrc] and offers[targetSrc].expires > os.time() then
        return false, 'They are already being handed something.'
    end
    if pending[src] then return false, 'Finish the last one first.' end

    -- Cap check on the RECEIVING side. A trainer taking work is the documented
    -- exception (Config.Training.heldHorsesIgnoreCap) — Phase 3 passes ignoreCap.
    if not opts.ignoreCap then
        local tJob = Bridge.getJob(targetSrc)
        if k.count(targetChar) >= k.cap(tJob) then
            return false, ('They have no room for another %s.'):format(k.label)
        end
    end

    local timeout = cfg().offerTimeoutSeconds or 30
    offers[targetSrc] = {
        from      = src,
        fromChar  = charid,
        kind      = kind,
        assetId   = assetId,
        name      = row.name,
        model     = row.model,
        reason    = opts.reason or 'gift',
        ignoreCap = opts.ignoreCap and true or false,
        expires   = os.time() + timeout,
    }
    pending[src] = true

    TriggerClientEvent(Events.TransferOffer, targetSrc, {
        from    = charName(src),
        kind    = kind,
        name    = row.name,
        reason  = offers[targetSrc].reason,
        seconds = timeout,
    })

    -- Reap the offer if they never answer, or `pending` would strand the sender.
    CreateThread(function()
        Wait((timeout + 1) * 1000)
        local o = offers[targetSrc]
        if o and o.from == src and o.expires <= os.time() then
            offers[targetSrc] = nil
            pending[src] = nil
            TriggerClientEvent(Events.TransferResult, src, { ok = false, message = 'They never answered.' })
        end
    end)

    return true, ('Offered %s to %s.'):format(row.name or k.label, charName(targetSrc))
end

--------------------------------------------------------------------------------
-- Response
--------------------------------------------------------------------------------
function Transfer.respond(targetSrc, accept)
    local o = offers[targetSrc]
    offers[targetSrc] = nil
    if not o then return end

    local fromSrc = o.from
    pending[fromSrc] = nil

    if o.expires <= os.time() then
        TriggerClientEvent(Events.TransferResult, fromSrc, { ok = false, message = 'Too slow — the offer lapsed.' })
        return
    end

    if not accept then
        TriggerClientEvent(Events.TransferResult, fromSrc, { ok = false, message = 'They said no.' })
        TriggerClientEvent(Events.TransferResult, targetSrc, { ok = true, message = 'Declined.' })
        return
    end

    local k = KINDS[o.kind]
    local targetChar = Bridge.getCharId(targetSrc)
    if not targetChar then
        TriggerClientEvent(Events.TransferResult, fromSrc, { ok = false, message = 'They left.' })
        return
    end

    -- Re-check EVERYTHING at the moment of the move. The offer may be seconds
    -- old: they could have walked off, sold the horse, or filled their stable.
    local row = ownedAsset(o.kind, o.fromChar, o.assetId)
    if not row then
        TriggerClientEvent(Events.TransferResult, fromSrc, { ok = false, message = 'It is no longer yours to give.' })
        return
    end
    if not playersInRange(fromSrc, targetSrc, cfg().maxDistance or 5.0) then
        TriggerClientEvent(Events.TransferResult, fromSrc, { ok = false, message = 'They walked off.' })
        TriggerClientEvent(Events.TransferResult, targetSrc, { ok = false, message = 'Too far away.' })
        return
    end
    if not o.ignoreCap and k.count(targetChar) >= k.cap(Bridge.getJob(targetSrc)) then
        TriggerClientEvent(Events.TransferResult, fromSrc, { ok = false, message = 'They have no room.' })
        TriggerClientEvent(Events.TransferResult, targetSrc, { ok = false, message = 'You have no room.' })
        return
    end

    -- The move. Clears is_default: the receiver decides their own default ride,
    -- and the giver's default must not point at a row they no longer own.
    Db.execute(
        ('UPDATE %s SET charid = ?, identifier = ?, is_default = 0 WHERE id = ? AND charid = ?'):format(k.table),
        { targetChar, Bridge.getIdentifier(targetSrc), o.assetId, o.fromChar })

    logLedger(o.fromChar, k.ledger .. '_out', row.model,
        { assetId = o.assetId, to = targetChar, reason = o.reason, name = row.name })
    logLedger(targetChar, k.ledger .. '_in', row.model,
        { assetId = o.assetId, from = o.fromChar, reason = o.reason, name = row.name })

    -- The giver may have it standing in front of them — take it off their client.
    TriggerClientEvent(Events.SyncOwnedRides, fromSrc, { released = { kind = o.kind, id = o.assetId } })

    TriggerClientEvent(Events.TransferResult, fromSrc,
        { ok = true, message = ('%s is theirs now.'):format(row.name or k.label) })
    TriggerClientEvent(Events.TransferResult, targetSrc,
        { ok = true, message = ('%s is yours.'):format(row.name or k.label) })

    -- Refresh both stables.
    if o.kind == 'horse' then
        TriggerClientEvent(Events.OwnedData, fromSrc,   { owned = Horses.listOwned(o.fromChar), cap = k.cap(Bridge.getJob(fromSrc)) })
        TriggerClientEvent(Events.OwnedData, targetSrc, { owned = Horses.listOwned(targetChar), cap = k.cap(Bridge.getJob(targetSrc)) })
    else
        TriggerClientEvent(Events.OwnedWagonData, fromSrc,   { owned = Wagons.listOwned(o.fromChar), cap = k.cap(Bridge.getJob(fromSrc)) })
        TriggerClientEvent(Events.OwnedWagonData, targetSrc, { owned = Wagons.listOwned(targetChar), cap = k.cap(Bridge.getJob(targetSrc)) })
    end

    Util.log(('%s #%s moved char %s -> char %s (%s)'):format(
        o.kind, o.assetId, o.fromChar, targetChar, o.reason))
end

--------------------------------------------------------------------------------
-- Net events
--------------------------------------------------------------------------------
RegisterNetEvent(Events.RequestTransfer, function(kind, assetId, targetSrc)
    local src = source
    CreateThread(function()
        local ok, msg = false, 'Something went wrong.'
        local success, err = pcall(function()
            -- Clients may only ever send a plain gift. `reason`/`ignoreCap` are
            -- server-side arguments for Phase 3 custody — never client input.
            ok, msg = Transfer.offer(src, kind, assetId, targetSrc, { reason = 'gift' })
        end)
        if not success then Util.err('transfer offer failed: ' .. tostring(err)) end
        if not ok then
            TriggerClientEvent(Events.TransferResult, src, { ok = false, message = msg })
        else
            Bridge.notify(src, msg)
        end
    end)
end)

RegisterNetEvent(Events.RespondTransfer, function(accept)
    local src = source
    CreateThread(function()
        local success, err = pcall(function() Transfer.respond(src, accept and true or false) end)
        if not success then Util.err('transfer respond failed: ' .. tostring(err)) end
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    -- Drop any offer aimed at them, and release whoever was waiting on them.
    local o = offers[src]
    if o then
        pending[o.from] = nil
        TriggerClientEvent(Events.TransferResult, o.from, { ok = false, message = 'They left.' })
        offers[src] = nil
    end
    for target, off in pairs(offers) do
        if off.from == src then offers[target] = nil end
    end
    pending[src] = nil
end)
