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

-- Full metaped refresh after a component or tint change. Anything less and the
-- change may not render (jo_libs refreshPed, confirmed across public RedM scripts).
function Components.refreshFull(ped)
    if not (ped and DoesEntityExist(ped)) then return end
    pcall(function() Citizen.InvokeNative(0xAAB86462966168CE, ped) end)                       -- SetActiveMetaPedComponentsUpdated
    pcall(function() Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false) end) -- UpdatePedVariation
    pcall(function() Citizen.InvokeNative(0x704C908E9C405136, ped) end)                       -- N_0x704C…
end

-- ⚠️ THE REAL RECOLOUR (fixed 2026-07-28). My first attempt used _SET_META_PED_TAG
-- with 0 textures — that native APPLIES a component with a texture set, and 0 = no
-- textures, so it did nothing visible. The correct native for recolouring an
-- already-worn category is _SET_TEXTURE_OUTFIT_TINTS: category + palette + three
-- tint indices, NO texture hashes. Confirmed identical in jo_libs, vorp_character
-- and rsg-appearance.
--
--   category — a metaped category string, e.g. 'horse_saddles' (joaat'd)
--   palette  — a palette string, e.g. 'metaped_tint_combined_leather' (joaat'd)
--   t0/t1/t2 — tint rows 0-254 (Green/Red/Blue channels); 255 disables a channel
function Components.tintCategory(ped, category, palette, t0, t1, t2)
    if not (ped and DoesEntityExist(ped)) then return false end
    local cat = toHash(category)
    local pal = toHash(palette)
    if pal == 0 then return false end
    t0, t1, t2 = tonumber(t0) or 0, tonumber(t1) or 0, tonumber(t2) or 255
    pcall(function()
        Citizen.InvokeNative(0x4EFC1F8FF1AD94DE, ped, cat, pal, t0, t1, t2)  -- _SET_TEXTURE_OUTFIT_TINTS
    end)
    Components.refreshFull(ped)
    return true
end

-- Our tack slot ids -> the game's metaped category strings.
Components.CATEGORY = {
    saddle    = 'horse_saddles',   saddlebags = 'horse_saddlebags',
    horn      = 'saddle_horns',    stirrups   = 'saddle_stirrups',
    blanket   = 'horse_blankets',  bedroll    = 'horse_bedrolls',
    lantern   = 'saddle_lanterns', mask       = 'horse_accessories',
    mane      = 'horse_manes',     tail       = 'horse_tails',
}

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

    -- Colours are remembered PER PIECE (by item id), so a saddle keeps its colour
    -- even after it's removed and re-fitted (owner ruling 2026-07-28).
    local tints = comps.__tints   -- { [itemId] = { palette, t0, t1, t2 } }
    local n, applied, worn = 0, {}, {}
    for slot, itemId in pairs(comps) do
        if slot ~= '__tints' then
            local card = Catalog.tack(itemId)
            if card and card.hash then
                if Components.applyHash(ped, card.hash) then
                    n = n + 1
                    applied[#applied + 1] = toHash(card.hash)
                    worn[#worn + 1] = { item = itemId, slot = card.slot }
                end
            elseif Config.Debug then
                Util.log(('component skipped — no verified hash for "%s" (slot %s)')
                    :format(tostring(itemId), tostring(slot)))
            end
        end
    end
    if n > 0 then Components.refresh(ped) end
    -- Re-apply each worn piece's saved colour to its category.
    if type(tints) == 'table' then
        for _, w in ipairs(worn) do
            local t = tints[w.item]
            local cat = Components.CATEGORY and Components.CATEGORY[w.slot]
            if t and cat and t.palette then
                Components.tintCategory(ped, cat, t.palette, t.t0, t.t1, t.t2)
            end
        end
    end
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

-- ⚠️ TEMPORARY: prove _SET_TEXTURE_OUTFIT_TINTS recolours worn tack (the RIGHT
-- native this time). Recolours a CATEGORY on the horse you have out.
--   /sovtint                                  -> list categories + palettes
--   /sovtint horse_saddles metaped_tint_combined_leather 10 40 255
Components.PALETTES = {
    'metaped_tint_combined_leather', 'metaped_tint_leather', 'metaped_tint_combined',
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
        print('^3[sov_tint]^7 categories: ' .. table.concat({
            'horse_saddles','horse_saddlebags','saddle_horns','saddle_stirrups',
            'horse_blankets','horse_bedrolls' }, ', '))
        print('^3[sov_tint]^7 palettes: ' .. table.concat(Components.PALETTES, ', '))
        print('^3[sov_tint]^7 then: /sovtint <category> <palette> <t0> <t1> <t2>   (tints 0-254, 255=off)')
        return
    end
    local cat, pal = args[1], args[2] or 'metaped_tint_combined_leather'
    local t0, t1, t2 = tonumber(args[3]) or 0, tonumber(args[4]) or 0, tonumber(args[5]) or 255
    Components.tintCategory(a.ent, cat, pal, t0, t1, t2)
    print(('^2[sov_tint]^7 %s / %s  tint %d/%d/%d applied. Colour changed?'):format(cat, pal, t0, t1, t2))
    if Bridge then Bridge.notify(('Tint %s %d/%d/%d'):format(pal, t0, t1, t2)) end
end, false)

-- ⚠️ TEMPORARY: prove the tint PERSISTS. Unlike /sovtint (visual only), this asks
-- the SERVER to save the colour on the fitted slot, so it survives a re-spawn and
-- runs the perms gate. Slot names: saddle, saddlebags, blanket, ...
--   /sovsettint saddle metaped_tint_combined_leather 10 40 255
RegisterCommand('sovsettint', function(_, args)
    args = args or {}
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.id) then
        if Bridge then Bridge.notify('Bring your horse out first.') end
        return
    end
    local slot = args[1]
    if not slot then
        if Bridge then Bridge.notify('Usage: /sovsettint <slot> <palette> <t0> <t1> <t2>') end
        return
    end
    local pal = args[2] or 'metaped_tint_combined_leather'
    local t0, t1, t2 = tonumber(args[3]) or 0, tonumber(args[4]) or 0, tonumber(args[5]) or 255
    -- Apply it NOW so you see it on the horse you have out (this is the live
    -- preview the UI will use), THEN ask the server to persist it.
    if a.ent and DoesEntityExist(a.ent) then
        Components.tintCategory(a.ent, Components.CATEGORY[slot] or slot, pal, t0, t1, t2)
    end
    TriggerServerEvent(Events.RequestTintTack, a.id, slot, pal, t0, t1, t2)
    print(('^2[sov_settint]^7 %s -> %s %d/%d/%d — applied now + saved (survives re-spawn if it takes)')
        :format(slot, pal, t0, t1, t2))
end, false)
