--[[=====================================================================
  SOVEREIGN STABLES · HORSE COAT & MORPH PROBE  (client)
  ---------------------------------------------------------------------
  Groundwork for the Horse Customiser (coat recolour + admin breed creator).
  Before building any UI we confirm, IN GAME, the exact strings/indices the
  engine wants — the same probe-first discipline that cracked tack recolour
  (/sovtint found 'horse_saddles') and the wagon natives.

  All natives here are verified against the alloc8or RDR3 nativedb (PED ns):
    _SET_CHAR_EXPRESSION            0x5653AB26C82938CF  (shape morphs)
    _GET_CHAR_EXPRESSION           0xFD1BA1EEF7985BB8   (read base breed)
    _SET_TEXTURE_OUTFIT_TINTS      0x4EFC1F8FF1AD94DE   (coat colour — via Components.tintCategory)
    _SET_PED_VARIATION_PRESET      0xFFA1594703ED27CA   (whole coat preset)
    _SET_PED_SCALE                 0x25ACFC650B65C538   (uniform size)
    _GET_NUM_COMPONENT_CATEGORIES_IN_PED  0xA622E66EEE92A08D
    _GET_PED_COMPONENT_CATEGORY_BY_INDEX  0xCCB97B51893C662F
    _UPDATE_PED_VARIATION          0xCC8CA3E88256E58F   (commit)

  NONE of this is a GTA V native. NONE of this state is persistent — it is all
  re-applied per spawn, which is exactly the customiser's design.
=====================================================================]]--

Coat = Coat or {}

local function u32(x) return x & 0xFFFFFFFF end

-- The horse to operate on: your brought-out horse, else the mount you're riding.
local function currentHorse()
    local a = Horse and Horse.active and Horse.active()
    if a and a.ent and DoesEntityExist(a.ent) then return a.ent end
    local ok, m = pcall(function() return GetMount(PlayerPedId()) end)
    if ok and m and m ~= 0 and DoesEntityExist(m) then return m end
    return nil
end

local function commit(ped)
    pcall(function() Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false) end) -- _UPDATE_PED_VARIATION
end

-- Candidate category NAMES for the horse BODY coat. We don't yet know which the
-- engine uses (the tack map only has manes/tails), so the probe joaats each and
-- flags any that are actually present on the horse.
local CANDIDATE_CATS = {
    'horse_coats', 'horse_coat', 'horse_body', 'horse_upper_body', 'horse_lower_body',
    'horse_bodies', 'coats', 'body', 'horse_head', 'horse_legs', 'horse_hooves',
    'horse_manes', 'horse_tails', 'horse_accessories', 'horse_eyes',
}

--------------------------------------------------------------------------------
-- /sovcoatcats — list the component categories the engine reports on this horse,
-- then flag which of our candidate NAMES match (that's the body-coat category).
--------------------------------------------------------------------------------
RegisterCommand('sovcoatcats', function()
    local h = currentHorse()
    if not h then print('^3[sov_coat]^7 no horse — bring out or mount your horse first'); return end
    local num = Citizen.InvokeNative(0xA622E66EEE92A08D, h, Citizen.ResultAsInteger()) or 0  -- _GET_NUM_COMPONENT_CATEGORIES_IN_PED
    print(('^2[sov_coat]^7 %d component categories on this horse:'):format(num))
    local present = {}
    for i = 0, num - 1 do
        local cat = Citizen.InvokeNative(0xCCB97B51893C662F, h, i, Citizen.ResultAsInteger())  -- _GET_PED_COMPONENT_CATEGORY_BY_INDEX
        if cat then present[u32(cat)] = true; print(('    [%d] categoryHash=%s'):format(i, tostring(u32(cat)))) end
    end
    print('^2[sov_coat]^7 candidate name matches (✓ = present on this horse):')
    for _, name in ipairs(CANDIDATE_CATS) do
        local mark = present[u32(GetHashKey(name))] and '^2✓^7' or ' '
        print(('    %s %-18s (%s)'):format(mark, name, tostring(u32(GetHashKey(name)))))
    end
end, false)

--------------------------------------------------------------------------------
-- /sovcoattint <category> <palette> <t0> <t1> <t2> — live-recolour the horse to
-- find the working body-coat category+palette (mirrors how /sovtint found tack).
--------------------------------------------------------------------------------
RegisterCommand('sovcoattint', function(_, args)
    local h = currentHorse()
    if not h then print('^3[sov_coat]^7 no horse'); return end
    local cat, pal = args[1], args[2]
    if not (cat and pal) then
        print('^3usage:^7 /sovcoattint <category> <palette> <t0 0-255> <t1> <t2>')
        print('  try categories from /sovcoatcats; palettes e.g. metaped_tint_horse, metaped_tint_combined_leather')
        return
    end
    local t0 = tonumber(args[3]) or 0
    local t1 = tonumber(args[4]) or 0
    local t2 = tonumber(args[5]) or 255
    Components.tintCategory(h, cat, pal, t0, t1, t2)
    print(('^2[sov_coat]^7 tint applied  cat=%s  pal=%s  %d/%d/%d'):format(cat, pal, t0, t1, t2))
end, false)

--------------------------------------------------------------------------------
-- /sovcoatpreset <n> — apply a whole predefined coat/appearance preset, to see
-- the breed's built-in coat variations (_SET_PED_VARIATION_PRESET).
--------------------------------------------------------------------------------
RegisterCommand('sovcoatpreset', function(_, args)
    local h = currentHorse()
    if not h then print('^3[sov_coat]^7 no horse'); return end
    local idx = tonumber(args[1]) or 0
    pcall(function() Citizen.InvokeNative(0xFFA1594703ED27CA, h, idx) end)  -- _SET_PED_VARIATION_PRESET
    commit(h)
    print(('^2[sov_coat]^7 variation preset %d applied'):format(idx))
end, false)

--------------------------------------------------------------------------------
-- /sovexpr <index> <value -1..1> — apply a MetaPedExpression morph. This is the
-- tier-2 (breed creator) shape system: ears, eyes, legs, body, etc. Expression
-- id list: pastebin Ld76cAn7. e.g. 19780 ears-forward, 8420 front-legs, 10726
-- body-size, 41611 gender(0/1).
--------------------------------------------------------------------------------
RegisterCommand('sovexpr', function(_, args)
    local h = currentHorse()
    if not h then print('^3[sov_coat]^7 no horse'); return end
    local idx = tonumber(args[1])
    local val = tonumber(args[2])
    if not (idx and val) then print('^3usage:^7 /sovexpr <expressionIndex> <value -1..1>'); return end
    pcall(function() Citizen.InvokeNative(0x5653AB26C82938CF, h, idx, val + 0.0) end)  -- _SET_CHAR_EXPRESSION
    commit(h)
    print(('^2[sov_coat]^7 expression idx=%d val=%.2f applied'):format(idx, val))
end, false)

--------------------------------------------------------------------------------
-- /sovexprget <index> — read the current value (for "start from this breed").
--------------------------------------------------------------------------------
RegisterCommand('sovexprget', function(_, args)
    local h = currentHorse()
    if not h then print('^3[sov_coat]^7 no horse'); return end
    local idx = tonumber(args[1])
    if not idx then print('^3usage:^7 /sovexprget <expressionIndex>'); return end
    local v = Citizen.InvokeNative(0xFD1BA1EEF7985BB8, h, idx, Citizen.ResultAsFloat())  -- _GET_CHAR_EXPRESSION
    print(('^2[sov_coat]^7 expression idx=%d current value=%s'):format(idx, tostring(v)))
end, false)

--------------------------------------------------------------------------------
-- /sovscale <f> — uniform body scale (_SET_PED_SCALE), e.g. 1.0 default, 1.1 big.
--------------------------------------------------------------------------------
RegisterCommand('sovscale', function(_, args)
    local h = currentHorse()
    if not h then print('^3[sov_coat]^7 no horse'); return end
    local f = tonumber(args[1]) or 1.0
    pcall(function() Citizen.InvokeNative(0x25ACFC650B65C538, h, f + 0.0) end)  -- _SET_PED_SCALE
    print(('^2[sov_coat]^7 scale set to %.3f'):format(f))
end, false)
