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
    local n, worn = 0, {}
    for slot, itemId in pairs(comps) do
        if slot ~= '__tints' then
            local card = Catalog.tack(itemId)
            if card and card.hash then
                if Components.applyHash(ped, card.hash) then
                    n = n + 1
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
    if type(tints) == 'table' and #worn > 0 then
        local function paintAll()
            for _, w in ipairs(worn) do
                local t = tints[w.item]
                local cat = Components.CATEGORY and Components.CATEGORY[w.slot]
                if t and cat and t.palette then
                    Components.tintCategory(ped, cat, t.palette, t.t0, t.t1, t.t2)
                end
            end
        end
        paintAll()
        -- ⚠️ A FRESHLY-SPAWNED ped often refuses the tint on the first frame — the
        -- component is there but the texture isn't streamed yet, so the colour
        -- silently doesn't take (owner: "saved colours did not apply on bring-out").
        -- /sovsettint worked because the horse was already streamed. So re-apply a
        -- couple of times as the ped settles.
        CreateThread(function()
            for _, d in ipairs({ 300, 900, 2000 }) do
                Wait(d)
                if ped and DoesEntityExist(ped) then paintAll() end
            end
        end)
    end
    return n
end
