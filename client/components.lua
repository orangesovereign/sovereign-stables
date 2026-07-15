--[[=====================================================================
  SOVEREIGN STABLES · COMPONENT APPLY  (client)
  ---------------------------------------------------------------------
  One place that knows how to put tack on a horse. Used by every spawn
  path — summoned horses, the storefront preview, and (Phase 2) the
  customizer — so a saddle looks the same everywhere.

  The pipeline is the one the Phase 1 spike proved
  (docs/PHASE1_SPIKE_FINDINGS.md):

      0xD3A7B003ED343FD9  apply metaped component
      0xCC8CA3E88256E58F  UpdatePedVariation  (refresh, or nothing shows)

  Spike result A8: components are NOT breed-locked — a mane hash that
  changed the grey Kentucky Saddler also changed the gold Turkoman. So one
  universal list serves every horse and there are no per-breed tables.
=====================================================================]]--

Components = Components or {}

-- Apply a single component hash to a ped. Safe to call on a dead/absent entity.
function Components.applyHash(ped, hash)
    if not (ped and DoesEntityExist(ped)) then return false end
    if not hash then return false end
    if type(hash) == 'string' then hash = tonumber(hash) or GetHashKey(hash) end
    Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, hash, true, true, true)
    return true
end

-- Refresh the ped so applied components actually render. Batch your applies
-- and call this ONCE at the end — it is the expensive half.
function Components.refresh(ped)
    if not (ped and DoesEntityExist(ped)) then return end
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, 0)
end

-- Apply a whole components table to a ped: { [slot] = itemId }, as stored on
-- sovereign_horses.components. Unknown items and items with no verified hash
-- are skipped rather than guessed at — a bad hash silently does nothing, and a
-- silent no-op is the worst kind of bug to chase.
-- Returns the number of pieces actually applied.
function Components.applySet(ped, comps)
    if not (ped and DoesEntityExist(ped)) then return 0 end
    if type(comps) == 'string' then
        local ok, decoded = pcall(json.decode, comps)
        comps = (ok and type(decoded) == 'table') and decoded or nil
    end
    if type(comps) ~= 'table' then return 0 end

    local n = 0
    for slot, itemId in pairs(comps) do
        local card = Catalog.tack(itemId)
        if card and card.hash then
            if Components.applyHash(ped, card.hash) then n = n + 1 end
        elseif Config.Debug then
            Util.log(('component skipped — no verified hash for "%s" (slot %s)')
                :format(tostring(itemId), tostring(slot)))
        end
    end
    if n > 0 then Components.refresh(ped) end
    return n
end
