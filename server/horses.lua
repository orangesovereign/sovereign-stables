--[[=====================================================================
  SOVEREIGN STABLES · HORSE OWNERSHIP  (server, authoritative)
  ---------------------------------------------------------------------
  Buying and owning horses. The client never decides price, permission or
  funds — it only asks. Every money-moving action is written to the ledger
  (X2) so the economy is auditable and dupes are traceable.
=====================================================================]]--

Horses = Horses or {}

local busy = {}   -- [src] = true while a purchase is in flight (anti-spam/dupe)

--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------
local HCOLS = 'id, name, sex, model, is_default, stable_origin, xp, age'

-- FACTION POOLS [S16]. A stable with faction.enabled shows a SHARED inventory
-- (e.g. the government pool) instead of the player's personal horses. The horse
-- row's `faction` column holds the pool key; personal horses are NULL.
--
-- Per-department pools: `faction.pools = { job = poolKey }` lets ONE stable serve
-- several branches with SEPARATE inventories (e.g. sheriff/marshal share 'gov_law',
-- doctor uses 'gov_medical'). A legacy single `faction.key` still works (one pool
-- shared by everyone in jobs.allowed). Point several jobs at the same key to share.
function Horses.factionKeyFor(stableId, job)
    local s = Config.Stables[stableId]
    local f = s and s.faction
    if not (f and f.enabled) then return nil end
    if f.pools then return (job and f.pools[job]) or nil end
    return f.key
end

-- Pool keys this player may access, by their VORP job (a doctor → { gov_medical },
-- a sheriff → { gov_law }). Used by the summon path to authorize pool horses.
function Horses.playerFactions(src)
    local job = Bridge.getJob(src)
    local out = {}
    if not job then return out end
    for _, s in pairs(Config.Stables or {}) do
        local f = s.faction
        if f and f.enabled then
            if f.pools then
                if f.pools[job] then out[f.pools[job]] = true end
            elseif f.key and s.jobs then
                for _, j in ipairs(s.jobs.allowed or {}) do
                    if j == job then out[f.key] = true break end
                end
            end
        end
    end
    return out
end

-- Personal horses only (faction pool horses never leak into personal lists/caps).
function Horses.listOwned(charid)
    return Db.awaitQuery('SELECT ' .. HCOLS .. ' FROM sovereign_horses WHERE charid = ? AND faction IS NULL ORDER BY id', { charid }) or {}
end
function Horses.countOwned(charid)
    local rows = Db.awaitQuery('SELECT COUNT(*) AS n FROM sovereign_horses WHERE charid = ? AND faction IS NULL', { charid })
    return (rows and rows[1] and rows[1].n) or 0
end

-- What to show at a given stable: the faction pool if it's a faction stable,
-- else the player's personal horses.
function Horses.listOwnedAt(charid, stableId, job)
    local fk = Horses.factionKeyFor(stableId, job)
    if fk then
        return Db.awaitQuery('SELECT ' .. HCOLS .. ' FROM sovereign_horses WHERE faction = ? ORDER BY id', { fk }) or {}
    end
    return Horses.listOwned(charid)
end
function Horses.countInPool(fk)
    local rows = Db.awaitQuery('SELECT COUNT(*) AS n FROM sovereign_horses WHERE faction = ?', { fk })
    return (rows and rows[1] and rows[1].n) or 0
end

local function logLedger(charid, action, subject, cash, gold, meta)
    if not (Config.Economy and Config.Economy.transactionLog) then return end
    Db.execute('INSERT INTO sovereign_ledger (charid, action, subject, cash, gold, meta) VALUES (?, ?, ?, ?, ?, ?)',
        { charid, action, subject, cash or 0, gold or 0, meta and json.encode(meta) or nil })
end

-- Clean up a player-supplied horse name [N8]. Never trust it: strip control
-- characters and markup, collapse whitespace, cap the length, fall back to the
-- catalog name if they left it blank.
local function sanitizeName(raw, fallback)
    if type(raw) ~= 'string' then return fallback end
    local s = raw:gsub('[%c]', ' '):gsub('[<>~\\]', ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then return fallback end
    if #s > 24 then s = s:sub(1, 24) end
    return s
end

-- Gender is chosen at purchase [N9]. Only these are valid — a Gelding is made
-- by neutering (G5), never bought.
local VALID_SEX = { Stallion = true, Mare = true }
local function sanitizeSex(raw, fallback)
    return VALID_SEX[raw] and raw or (fallback or 'Stallion')
end

-- Does this stable actually sell this model? (Stops a spoofed model id.)
local function stableSells(stableId, model)
    for _, h in ipairs(Catalog.horsesFor(stableId)) do
        if h.model == model then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- Purchase
--------------------------------------------------------------------------------
-- Returns ok:boolean, message:string
-- `wanted` = { name, sex } chosen by the buyer at purchase (N8/N9).
function Horses.buy(src, stableId, model, wanted)
    if not (Config.Economy and Config.Economy.enableBuying) then
        return false, 'The stables are not selling today.'
    end

    local charid = Bridge.getCharId(src)
    if not charid then return false, 'No active character.' end

    if not Config.Stables[stableId] then return false, 'Unknown stable.' end
    if not stableSells(stableId, model) then return false, 'This stable does not sell that horse.' end

    local card = Catalog.horse(model)
    if not card or card.buyable == false then return false, 'That horse is not for sale.' end

    -- Job / stable permission
    local job, grade = Bridge.getJob(src)
    local allowed, why = Catalog.canBuy(card, stableId, job)
    if not allowed then return false, why or 'You may not buy that here.' end

    -- TRAINER-BROKERED TIERS [owner ruling 2026-07-26]. Specialty horses are not
    -- counter stock — they go through the stable's trainer. Checked HERE and not
    -- only in the UI: hiding a button is presentation, not a rule, and a crafted
    -- event would otherwise buy one anyway.
    local brokered = (Config.Economy.trainerBrokeredTiers or {})[card.tier or '']
    if brokered and not Perms.can(job, grade, 'brokerSpecialty') then
        return false, ('%s is not sold over the counter — speak to the stable\'s trainer.')
            :format(card.name or card.label or 'That horse')
    end

    -- Ownership cap. A faction stable buys INTO its shared pool (pool cap); a
    -- normal stable buys into the player's personal stable (personal cap).
    local fk = Horses.factionKeyFor(stableId, job)
    local cap, owned
    if fk then
        cap   = (Config.Stables[stableId].faction and Config.Stables[stableId].faction.cap) or 30
        owned = Horses.countInPool(fk)
        if owned >= cap then return false, ('This pool is full (%d horses).'):format(cap) end
    else
        cap   = Perms.maxHorses(job, grade)
        owned = Horses.countOwned(charid)
        if owned >= cap then return false, ('You already keep %d horse(s) — your limit.'):format(cap) end
    end

    -- Price + funds (server-side price, never the client's)
    local cash = (card.price and card.price.cash) or 0.0
    local gold = (card.price and card.price.gold) or 0.0
    if not (Config.Economy.enableGold) then gold = 0.0 end
    if not Bridge.canAfford(src, cash, gold) then
        return false, "You can't afford that."
    end
    if not Bridge.charge(src, cash, gold) then
        return false, 'Payment failed.'
    end

    -- The buyer names it and picks its gender (N8/N9); both sanitized here.
    wanted = wanted or {}
    local name = sanitizeName(wanted.name, card.name or card.label or model)
    local sex  = sanitizeSex(wanted.sex, card.sex)

    -- Record it. First horse in the scope becomes the default. `fk` (nil for a
    -- normal stable) marks a faction-pool horse.
    local isDefault = (owned == 0) and 1 or 0
    local id = Db.awaitInsert(
        'INSERT INTO sovereign_horses (identifier, charid, name, sex, model, stable_origin, is_default, faction) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        { Bridge.getIdentifier(src), charid, name, sex, model, stableId, isDefault, fk })

    if not id then
        Bridge.pay(src, cash, gold)   -- refund: never take money without a horse
        return false, 'The paperwork failed — you were not charged.'
    end

    logLedger(charid, 'buy_horse', model, cash, gold, { stable = stableId, horseId = id, name = name, sex = sex })
    Util.log(('char %s bought %s (%s, %s) at %s for %s/%s (horse #%s)'):format(charid, model, name, sex, stableId, cash, gold, id))
    return true, ('%s is yours.'):format(name)
end

--------------------------------------------------------------------------------
-- Net events
--------------------------------------------------------------------------------
-- Push the horse list for the stable being browsed: the faction pool at a
-- faction stable, else the player's personal horses.
local function pushOwned(src, charid, stableId)
    local job, grade = Bridge.getJob(src)
    local fk = Horses.factionKeyFor(stableId, job)
    local cap
    if fk then
        cap = (Config.Stables[stableId].faction and Config.Stables[stableId].faction.cap) or 30
    else
        cap = Perms.maxHorses(job, grade)
    end
    TriggerClientEvent(Events.OwnedData, src, {
        owned   = Horses.listOwnedAt(charid, stableId, job),
        cap     = cap,
        faction = fk or nil,   -- lets the NUI label the shared pool if it wants
    })
end

RegisterNetEvent(Events.RequestPurchase, function(stableId, model, wanted)
    local src = source
    if busy[src] then return end
    busy[src] = true
    CreateThread(function()
        local ok, msg = false, 'Something went wrong.'
        local success, err = pcall(function() ok, msg = Horses.buy(src, stableId, model, wanted) end)
        if not success then Util.err('purchase failed: ' .. tostring(err)) end

        local cash, gold = Bridge.getBalance(src)
        TriggerClientEvent(Events.PurchaseResult, src, { ok = ok, message = msg, cash = cash, gold = gold })
        local charid = Bridge.getCharId(src)
        if ok and charid then pushOwned(src, charid, stableId) end
        busy[src] = nil
    end)
end)

RegisterNetEvent(Events.RequestOwned, function(stableId)
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if charid then pushOwned(src, charid, stableId) end
    end)
end)

RegisterNetEvent(Events.RequestSetDefault, function(horseId, stableId)
    local src = source
    CreateThread(function()
        local charid = Bridge.getCharId(src)
        if not charid then return end
        local fk = Horses.factionKeyFor(stableId, Bridge.getJob(src))
        if fk and Horses.playerFactions(src)[fk] then
            -- Faction pool: scope the default to the pool (any member may set it).
            Db.execute('UPDATE sovereign_horses SET is_default = 0 WHERE faction = ?', { fk })
            Db.execute('UPDATE sovereign_horses SET is_default = 1 WHERE id = ? AND faction = ?', { horseId, fk })
        else
            -- Personal: only ever touch this character's own (non-faction) rows.
            Db.execute('UPDATE sovereign_horses SET is_default = 0 WHERE charid = ? AND faction IS NULL', { charid })
            Db.execute('UPDATE sovereign_horses SET is_default = 1 WHERE id = ? AND charid = ? AND faction IS NULL', { horseId, charid })
        end
        pushOwned(src, charid, stableId)
    end)
end)

--------------------------------------------------------------------------------
-- A PLAYER WHO LEAVES TAKES THEIR HORSE WITH THEM  (owner ruling 2026-07-27)
--------------------------------------------------------------------------------
-- Horses are created by the client, so every other tidy-up path we have is
-- client-side — and a dropped player runs no client code at all. Left alone the
-- horse doesn't vanish: RedM migrates ownership of a networked entity to another
-- nearby player, so it stays in the world, riderless and unowned, for as long as
-- someone is stood near it. Hence the cleanup lives here, on the one machine
-- still running when a player disconnects.
--
-- The client reports its horse's NET ID (the id every machine agrees on) when it
-- spawns one, and retracts it whenever the horse goes away by any other route.
local outHorse = {}   -- [src] = { netId, model }

RegisterNetEvent(Events.ReportHorseEntity, function(netId, model)
    local src = source
    netId = tonumber(netId)
    if not netId or netId == 0 then outHorse[src] = nil; return end
    outHorse[src] = { netId = netId, model = tonumber(model) }
end)

AddEventHandler('playerDropped', function()
    local src  = source
    local held = outHorse[src]
    busy[src], outHorse[src] = nil, nil
    if not held then return end

    -- Net ids are RECYCLED. By the time we look, this one may belong to a
    -- completely different entity — so check it is still a ped of the model we
    -- were told about before deleting anything. Getting this wrong deletes some
    -- other player's horse, which is far worse than leaving a stray one.
    local function tryDelete()
        local ent = NetworkGetEntityFromNetworkId(held.netId)
        if not (ent and ent ~= 0 and DoesEntityExist(ent)) then return false end
        if held.model and GetEntityModel(ent) ~= held.model then
            Util.log(('drop cleanup: net id %d no longer the horse we were given — left alone')
                :format(held.netId))
            return true   -- resolved, but not ours: stop looking
        end
        DeleteEntity(ent)
        Util.log(('drop cleanup: removed horse (net id %d) for departed player %s'):format(held.netId, src))
        return true
    end

    -- The entity may not be resolvable the instant the player drops, so give it
    -- a few tries over a couple of seconds rather than one hopeful attempt.
    if tryDelete() then return end
    local tries = 0
    local function retry()
        tries = tries + 1
        if tryDelete() or tries >= 4 then return end
        SetTimeout(500, retry)
    end
    SetTimeout(500, retry)
end)
