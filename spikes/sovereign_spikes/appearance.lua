--[[=====================================================================
  SOVEREIGN SPIKES · HORSE APPEARANCE  (throwaway)
  ---------------------------------------------------------------------
  Proves the runtime appearance pipeline the storefront/customizer needs:
    · COAT   = the horse MODEL (each coat is its own A_C_Horse_* model)
    · MANE / TAIL / TACK = metaped component hashes applied at runtime
  Apply native : 0xD3A7B003ED343FD9  (apply metaped component to ped)
  Refresh native: 0xCC8CA3E88256E58F (UpdatePedVariation)

  WATCH: manes/tails are somewhat breed-specific — a hash from one breed may
  not visibly apply to another. That is exactly what we are here to learn, so
  test a mane preset against the DEFAULT grey Kentucky first, then try others.
=====================================================================]]--

-- Apply one metaped component hash and refresh the ped's variation.
local function applyComponent(ped, hash)
    Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, hash, true, true, true)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, 0) -- UpdatePedVariation
end

-- Real component hashes pulled from the public vorp_stables data catalog.
local MANES = { 0x18199F48, 0x130E341A, 0x0235DBF1, 0x25627B98, 0x1FDC6D0F } -- short, regular, long, braid, dreadlocks
local TAILS = { 0x1BB5EAA1, 0x383E86F3, 0x1F7A99EA, 0x17EB79D3, 0x12DBBBAF } -- short, regular, long, braid, dreadlocks
local SADDLE = 0x106961A8 -- Lumley McClelland saddle

RegisterCommand('spike_coat', function(_, args)
    if not args[1] then print('^3[spike]^7 usage: /spike_coat A_C_Horse_Turkoman_Gold') return end
    -- Coat swap = respawn with a different model. Proves coat is model-bound.
    Spike.spawnPreview(args[1])
end, false)

RegisterCommand('spike_mane', function(_, args)
    local horse = Spike.getOrSpawn()
    if not horse then return end
    local i = tonumber(args[1] or '2') or 2
    local hash = MANES[i] or MANES[2]
    applyComponent(horse, hash)
    print(('^2[spike]^7 applied MANE preset %d (0x%08X) to %s — did it change?'):format(i, hash, Spike.currentModel))
end, false)

RegisterCommand('spike_tail', function(_, args)
    local horse = Spike.getOrSpawn()
    if not horse then return end
    local i = tonumber(args[1] or '3') or 3
    local hash = TAILS[i] or TAILS[3]
    applyComponent(horse, hash)
    print(('^2[spike]^7 applied TAIL preset %d (0x%08X) to %s — did it change?'):format(i, hash, Spike.currentModel))
end, false)

RegisterCommand('spike_saddle', function()
    local horse = Spike.getOrSpawn()
    if not horse then return end
    applyComponent(horse, SADDLE)
    print(('^2[spike]^7 applied SADDLE (0x%08X) — saddle visible on the horse?'):format(SADDLE))
end, false)
