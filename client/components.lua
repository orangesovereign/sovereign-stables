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
-- This applies the SHAPE only (no colour): _APPLY_SHOP_ITEM_TO_PED.
function Components.applyHash(ped, hash)
    if not (ped and DoesEntityExist(ped)) then return false end
    if not hash then return false end
    if type(hash) == 'string' then hash = tonumber(hash) or GetHashKey(hash) end
    Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, hash, true, true, true)  -- _APPLY_SHOP_ITEM_TO_PED
    return true
end

local function toHash(v)
    if type(v) == 'string' then return tonumber(v) or GetHashKey(v) end
    return tonumber(v) or 0
end

-- Apply a component WITH COLOUR: _SET_META_PED_TAG (RDR3-verified, 0xBC6DF00…).
-- This is the recolour path the customiser (2.3) is built on: same drawable,
-- coloured by a palette hash + three tint indices (0-254). tint0 is the base
-- (green) channel, tint1 red, tint2 blue. albedo/normal/material are 0 = use the
-- drawable's own default texture set (we don't carry per-piece texture hashes).
--
-- ⚠️ palette must be one the piece actually supports, or the colour won't take.
-- Leather tack uses 'metaped_tint_leather' / 'metaped_tint_combined_leather'
-- (PHASE1_SPIKE_FINDINGS). Confirm in game with /sovtint before trusting it.
function Components.applyTinted(ped, hash, palette, t0, t1, t2)
    if not (ped and DoesEntityExist(ped)) then return false end
    if not hash then return false end
    hash    = toHash(hash)
    palette = toHash(palette)
    t0, t1, t2 = tonumber(t0) or 0, tonumber(t1) or 0, tonumber(t2) or 0
    pcall(function()
        Citizen.InvokeNative(0xBC6DF00D7A4A6819, ped, hash, 0, 0, 0, palette, t0, t1, t2)  -- _SET_META_PED_TAG
    end)
    return true
end

-- Read the palette + tint triplet currently on an asset (for populating the UI).
-- GET_META_PED_ASSET_TINT — returns ok, palette, t0, t1, t2.
function Components.readTint(ped, index)
    if not (ped and DoesEntityExist(ped)) then return nil end
    local ok, pal, a, b, c = pcall(function()
        return Citizen.InvokeNative(0xE7998FEC53A33BBE, ped, tonumber(index) or 0,
            Citizen.PointerValueInt(), Citizen.PointerValueInt(),
            Citizen.PointerValueInt(), Citizen.PointerValueInt())
    end)
    if ok then return { palette = pal, t0 = a, t1 = b, t2 = c } end
    return nil
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

    local n, applied = 0, {}
    for slot, itemId in pairs(comps) do
        local card = Catalog.tack(itemId)
        if card and card.hash then
            if Components.applyHash(ped, card.hash) then
                n = n + 1
                applied[#applied + 1] = toHash(card.hash)
            end
        elseif Config.Debug then
            Util.log(('component skipped — no verified hash for "%s" (slot %s)')
                :format(tostring(itemId), tostring(slot)))
        end
    end
    if n > 0 then Components.refresh(ped) end
    Components._lastHashes = applied   -- remembered so /sovtint can recolour them
    return n
end

--------------------------------------------------------------------------------
-- ⚠️ TEMPORARY: prove _SET_META_PED_TAG recolours tack in game. (remove once 2.3
-- is green). Recolours the tack currently on the horse you have out with a chosen
-- palette + tint triplet, so we can SEE which palettes/indices work before the
-- customiser UI is built on them.
--   /sovtint                                   -> list the spike's palette names
--   /sovtint metaped_tint_leather 66 0 0       -> palette + tint0/1/2
Components.PALETTES = {
    'metaped_tint_leather', 'metaped_tint_combined_leather', 'metaped_tint_horse',
    'metaped_tint_horse_leather', 'metaped_tint_generic', 'metaped_tint_metal',
}

RegisterCommand('sovtint', function(_, args)
    args = args or {}
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then
        if Bridge then Bridge.notify('Bring your horse out first.') end
        return
    end
    if not args[1] then
        print('^3[sov_tint]^7 palettes to try (then /sovtint <name> <t0> <t1> <t2>):')
        for _, p in ipairs(Components.PALETTES) do print('   ' .. p) end
        return
    end
    local hashes = Components._lastHashes
    if not (hashes and #hashes > 0) then
        if Bridge then Bridge.notify('This horse has no tack applied to recolour.') end
        return
    end
    local palette = args[1]
    local t0, t1, t2 = tonumber(args[2]) or 0, tonumber(args[3]) or 0, tonumber(args[4]) or 0
    for _, h in ipairs(hashes) do
        Components.applyTinted(a.ent, h, palette, t0, t1, t2)
    end
    Components.refresh(a.ent)
    print(('^2[sov_tint]^7 applied palette=%s tint=%d/%d/%d to %d piece(s). Colour changed?')
        :format(palette, t0, t1, t2, #hashes))
    if Bridge then Bridge.notify(('Tint %s %d/%d/%d'):format(palette, t0, t1, t2)) end
end, false)
