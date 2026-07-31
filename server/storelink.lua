--[[=====================================================================
  SOVEREIGN STABLES · STORE LINK  (server)
  ---------------------------------------------------------------------
  The stable "store" is NOT reimplemented here — sovereign_stores already does
  player-owned storefronts (ownership, employees, till/ledger, buy orders,
  stock, taxes, panels). This file just CHARTERS a sovereign_stores player-store
  at a stable's counter and hands it to the stable's owner, via the
  sovereign_stores `CreateStore` + `AssignOwner` exports. sovereign_stores then
  renders the ped/blip/prompts/panels itself.

  Idempotent: the created store id is remembered per stable in resource KVP, so
  re-charter (or a reboot) reuses the same store instead of duplicating it.

  Requires a store coord on the stable: Config.Stables[id].store = { x, y, z, h }
  (a SEPARATE spot from the stablehand). Optional Config.Stables[id].storeModel.
=====================================================================]]--

StoreLink = StoreLink or {}

local KVP = 'sovstore:'   -- KVP key prefix; sovstore:<stableId> -> sovereign_stores store id

local function storesReady()
    return GetResourceState('sovereign_stores') == 'started'
end

-- Charter (or re-sync) a stable's store. `ownerCharid` optional: when given, the
-- store is assigned to that owner and opened. Returns storeId or nil,err.
function StoreLink.ensure(stableId, ownerCharid)
    local stable = Config.Stables[stableId]
    if not stable then return nil, 'unknown stable' end
    local s = stable.store
    if not s then return nil, ('stable "%s" has no store coord — set Config.Stables.%s.store = { x, y, z, h }'):format(stableId, stableId) end
    if not storesReady() then return nil, 'sovereign_stores is not started' end

    local key = KVP .. stableId
    local existing = GetResourceKvpInt(key)
    if existing and existing > 0 then
        local info = exports.sovereign_stores:GetStoreInfo(existing)
        if info then
            if ownerCharid then
                exports.sovereign_stores:AssignOwner(existing, ownerCharid)
            end
            return existing
        end
        -- stale mapping (store was deleted upstream) — fall through and recreate
    end

    local id, err = exports.sovereign_stores:CreateStore({
        name     = (stable.label or stableId) .. ' Store',
        coords   = { x = s[1] + 0.0, y = s[2] + 0.0, z = s[3] + 0.0, h = (s[4] or 0.0) + 0.0 },
        category = 'general',
        npcModel = stable.storeModel or 'u_m_m_rhdgenstoreowner_01',
        owner    = ownerCharid,
        open     = ownerCharid ~= nil,
    })
    if not id then return nil, err or 'create failed' end
    SetResourceKvpInt(key, id)
    Util.log(('stable "%s" store chartered in sovereign_stores as #%s'):format(stableId, tostring(id)))
    return id
end

-- Admin/console: charter (or re-sync) a stable's store, optionally setting its owner.
--   sovstorecharter <stableId> [charid]      ([charid] defaults to you, in-game)
RegisterCommand('sovstorecharter', function(src, args)
    if src ~= 0 then
        local job, grade = Bridge.getJob(src)
        if not (Perms and Perms.can and Perms.can(job, grade, 'horseCreator')) then
            Bridge.notify(src, 'Admins only.'); return
        end
    end
    local stableId = args and args[1]
    if not (stableId and Config.Stables[stableId]) then
        print('^3usage:^7 sovstorecharter <stableId> [charid]'); return
    end
    local charid = tonumber(args and args[2]) or (src ~= 0 and Bridge.getCharId(src)) or nil
    CreateThread(function()
        local id, err = StoreLink.ensure(stableId, charid)
        if id then
            print(('^2[sov_store]^7 %s store = sovereign_stores #%s%s')
                :format(stableId, tostring(id), charid and (' (owner charid '..charid..')') or ''))
            if src ~= 0 then Bridge.notify(src, ('%s store ready (#%s).'):format(stableId, tostring(id))) end
        else
            print(('^3[sov_store]^7 could not charter %s store: %s'):format(stableId, tostring(err)))
            if src ~= 0 then Bridge.notify(src, 'Store charter failed: ' .. tostring(err)) end
        end
    end)
end, true)
