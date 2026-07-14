# Phase 1 Spike Findings — Confirmed Approach

> In-game verified 2026-07-14 (gate PASSED — see `testing/PHASE1_SPIKE_CHECKLIST.md`). These are the proven native patterns Phase 1 builds on. All natives are public RedM API; verified against the open-source `vorp_stables` + `vorp_utils`.

## Horse spawn (preview & world)

A raw RDR3 horse spawns **invisible and airborne** unless you ground-snap and initialize its variation. Confirmed working sequence:

```lua
RequestModel(hash); -- wait until HasModelLoaded
local x, y, z = <target>
local found, groundZ = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
if found then z = groundZ end                                  -- fixes AIRBORNE
local horse = CreatePed(hash, x, y, z, heading, false, true, false, false)
-- wait for DoesEntityExist(horse)
Citizen.InvokeNative(0x283978A15512B2FE, horse, true)          -- variation init → fixes INVISIBLE
SetEntityVisible(horse, true, false)
SetEntityInvincible(horse, true); FreezeEntityPosition(horse, true)  -- preview only
SetModelAsNoLongerNeeded(hash)
```

- `CreatePed(model, x, y, z, heading, isNetwork=false, bScriptHostPed=true, false, false)`.
- The variation-init native `0x283978A15512B2FE` is **mandatory** for the model to render.
- For a real (rideable) horse, skip the freeze/invincible and set ownership/relationship as vorp_stables does.

## Coat = model

Each RDR2 coat is its own `A_C_Horse_*` model. "Changing coat" = respawn with a different model. **Implication:** the catalog stays fully model-agnostic — stock and community coats are just model ids. No texture handling anywhere.

## Mane / tail / tack (components) at runtime

```lua
Citizen.InvokeNative(0xD3A7B003ED343FD9, horse, componentHash, true, true, true) -- apply metaped component
Citizen.InvokeNative(0xCC8CA3E88256E58F, horse, 0, 1, 1, 1, 0)                   -- UpdatePedVariation (refresh)
```

Confirmed applying manes, tails, and a saddle live. This is the pipeline for the customizer (S14/S15) and stored tack (F1/F5).

## Components are NOT breed-locked → universal component list

**A8 result:** a mane hash that changed the grey Kentucky Saddler also changed the gold Turkoman. **Decision:** the customizer presents ONE universal list of component options, not per-breed lists. (Revisit only if a specific future component proves breed-specific — handle as an exception, not the default.)

## Orbital preview camera (L5) — PASSED

```lua
local cam = Citizen.InvokeNative(0x40C23491CE83708E, 'DEFAULT_SCRIPTED_CAMERA', x, y, z, 0.0, 0.0, 0.0, fov, false, 0)
SetCamActive(cam, true); RenderScriptCams(true, true, 800, true, true, 0)
-- per frame: SetCamCoord(cam, orbitX, orbitY, orbitZ); PointCamAtCoord(cam, horseX, horseY, centreZ)
-- stop: RenderScriptCams(false, ...); DestroyCam(cam, true)
```

Smooth orbit + auto-centre confirmed at multiple radii/speeds. Locked for the storefront; zoom (N7) layers on the same cam via fov / radius.

## Deferred (not Phase 1 blockers)

- **Body size** and **shiny/gloss coat (M3)** — not covered by this spike; separate follow-up investigations before their phases.
