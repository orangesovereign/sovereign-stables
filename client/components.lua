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

-- ⚠️ DEAD END (proved in game 2026-07-28): _SET_META_PED_TAG with albedo/normal/
-- material = 0 does NOT tint tack — /sovtint changed nothing with any palette or
-- index. The native needs each piece's REAL texture-set hashes, which are
-- asset-specific metadata we don't carry. So runtime tinting is PARKED. The
-- customiser recolours by swapping baked colourway VARIANTS instead (each is its
-- own drawable, applied through the proven _APPLY_SHOP_ITEM_TO_PED) — see
-- Catalog variants and applyVariant below. Kept here in case the texture-set
-- hashes ever get sourced.
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
-- RECOLOUR BY VARIANT — the confirmed path. Each colourway is its own drawable in
-- a piece's `variants` list; applying one via _APPLY_SHOP_ITEM_TO_PED (proven in
-- the Phase 1 spike) recolours the piece. No palette data, no texture hashes.
--------------------------------------------------------------------------------
-- Apply a specific colourway of an owned tack item to a ped.
function Components.applyVariant(ped, itemId, variantIndex)
    local card = Catalog and Catalog.tack and Catalog.tack(itemId)
    if not card then return false end
    local variants = card.variants or { card.hash }
    local hash = variants[tonumber(variantIndex) or 1] or card.hash
    local ok = Components.applyHash(ped, hash)
    if ok then Components.refresh(ped) end
    return ok
end

-- ⚠️ TEMPORARY confirm command (remove once the customiser UI ships). Cycles the
-- worn saddle through its colourways so the owner can SEE variant-swapping
-- recolour a live horse before the swatch UI is built.
--   /sovvariant <tack_item_id> <n>   apply colourway n of that piece to your horse
RegisterCommand('sovvariant', function(_, args)
    args = args or {}
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then
        if Bridge then Bridge.notify('Bring your horse out first.') end
        return
    end
    local itemId = args[1]
    local n = tonumber(args[2]) or 1
    if not itemId then
        if Bridge then Bridge.notify('Usage: /sovvariant <tack_item_id> <colourway#>') end
        return
    end
    local card = Catalog and Catalog.tack and Catalog.tack(itemId)
    local count = card and card.variants and #card.variants or (card and 1 or 0)
    if count == 0 then
        if Bridge then Bridge.notify('No such tack item: ' .. tostring(itemId)) end
        return
    end
    Components.applyVariant(a.ent, itemId, n)
    print(('^2[sov_variant]^7 %s colourway %d/%d applied. Colour changed?'):format(itemId, n, count))
    if Bridge then Bridge.notify(('%s colourway %d/%d'):format(card.label or itemId, n, count)) end
end, false)
