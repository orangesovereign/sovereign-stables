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

## Horse brushing / grooming (discovered 2026-07-14, from rdr3_discoveries)

Used for the ambient stablehand vignette now, and feature **H5 (clean/brush your horse)** later.

- **Directed brush:** `TaskAnimalInteraction(ped, horse, GetHashKey('Interaction_Brush'), GetHashKey('p_brushHorse02x'), false)` → fires anim event `GetHashKey('INTERACT')` when a stroke completes (`HasAnimEventFired(ped, INTERACT)`). Loop to keep brushing.
- **Ambient scenario:** `WORLD_HUMAN_HORSE_TEND_BRUSH_LINK` (`_MALE_A`) — a paired/"link" scenario; needs a horse ped placed to pair with.
- **Raw anim dict:** `mech_animal_interaction@horse@right@brushing` (clip `brushing_horse`).
- **Brush props:** `p_brushHorse01x` / `p_brushHorse02x`. **Control:** `INPUT_INTERACT_HORSE_BRUSH` (`0x63A38F2C`).

Ambient grooming ped is implemented via the directed-brush loop in `client/stables.lua` (per-stable `ped.grooming` config; breed re-rolls on entry).

## RDR2's own horse controls — use these, don't invent keys

From `_reference/rdr3_discoveries/Controls/README.md`. **The game already binds everything we were trying to build**, which means `RegisterKeyMapping` (unreliable until a client restart) is unnecessary — just poll the native control.

| Control | Hash | Key | Context |
|---|---|---|---|
| `INPUT_WHISTLE` | `0x24978A28` | **H** | OnFoot |
| `INPUT_WHISTLE_HORSEBACK` | `0xE7EB9185` | **H** | OnMount |
| `INPUT_HORSE_COMMAND_FOLLOW` | `0x763E4D27` | E | HorseCommands / InteractionLockOn |
| `INPUT_HORSE_COMMAND_FLEE` | `0x4216AF06` | **F** | HorseCommands / InteractionLockOn |
| `INPUT_INTERACT_HORSE_BRUSH` | `0x63A38F2C` | B | InteractionLockOn |
| `INPUT_HORSE_STOP` | `0xE16B9AAD` | Ctrl | OnMount |
| `INPUT_OPEN_SATCHEL_HORSE_MENU` | `0x5966D52A` | B | OnFoot |

Notes:
- **H is already the whistle key.** Short/long whistle (D11) = tap vs hold on `INPUT_WHISTLE` / `INPUT_WHISTLE_HORSEBACK` (we use a 350ms threshold). Works immediately.
- **E is the mount key** (`INPUT_HORSE_EXIT`) — never bind it. `INPUT_HORSE_COMMAND_FOLLOW` shares E but only inside the HorseCommands context.
- **`INPUT_HORSE_COMMAND_FLEE` (F, lock-on context) is exactly D13** — look at the horse, focus, F: it bolts and despawns. The baseline vorp_stables uses the same interaction.
- Controls are **context-scoped**: an OnMount control cannot be read OnFoot. Pick the control for the context the player is actually in.

## Notification policy (owner ruling 2026-07-15)

**The parchment `Objective` slip is reserved for Storyworks MISSIONS.** Sovereign Stables must never send one. Routine feedback = `Tick` (slim chip); big moments = `Card`. `Bridge.notify()` is wired to `Tick`, so use it freely.

## Hard-won gotchas (milestone 1.1 — apply to every future stable/ped work)

1. **Ambient world entities MUST be proximity-streamed.** Spawning a ped/horse at world-load while the player is far away means the area's collision isn't loaded, so `GetGroundZAndNormalFor_3dCoord` fails and the entity hangs at the raw config Z (which reads ~1m high off a player-position tool). Indoors, a snap can also grab the terrain *under* the building and sink it. Stream in near the player (we use 35m in / 55m out) and snap then — the coords/heading are almost never the culprit.
2. **`RegisterKeyMapping` only binds its default key after a full CLIENT restart**, not a resource restart. For interactions that must work immediately, use the RDR3 **UiPrompt** system (`UiPromptRegisterBegin` + control `0x760A9C6F` + `UiPromptSetStandardMode` + `UiPromptSetActiveGroupThisFrame` + `UiPromptHasStandardModeCompleted`). Keep `RegisterKeyMapping` only as a rebindable convenience.
3. **`sovereign_notify` renders plain text** — RDR3 colour codes (`~o~`, `~q~`) print literally. Never send game markup to it.
4. **`mech_*` / `mech_animal_interaction@…` clips are synced-interaction anims**, not standalone loops — playing them raw with `TaskPlayAnim` contorts the ped. For ambient activity use a **scenario** (`TaskStartScenarioInPlace`), which handles pose, prop and looping.
5. **Never gate UI on a server round-trip.** Open the NUI first and fill data in when it arrives; and never leave an `isOpen` flag set on an early-abort path or every retry silently no-ops.

## Deferred (not Phase 1 blockers)

- **Body size** and **shiny/gloss coat (M3)** — not covered by this spike; separate follow-up investigations before their phases.
