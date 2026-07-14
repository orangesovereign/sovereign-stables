# Phase 1 Spike Checklist — Horse Appearance & Orbital Camera

> **The live checklist is the interactive Spike Ledger (Sovereign Exit-Gate Ledger format — tickable, progress bar, ticks persist):**
> **https://claude.ai/code/artifact/944cf025-acfa-4828-8ca1-329b87c9f153**
> This file is the plain-text mirror kept in the repo for the permanent record.

**Written for:** anyone — no developer knowledge needed.
**What you need:** the dev server with `vorp_core` running, admin rights, and ~10 minutes. The throwaway `sovereign_spikes` resource (in `spikes/sovereign_spikes/`).
**What to send back to Claude:** in the interactive ledger, mark each line Pass/Fail/Skip, add notes, then press **Build the Report** and paste the block back (plus any F8 console lines). A "fail" is information, not a blocker.

## 1. Raise the resource

| # | Command / step | Expect | Result |
|---|---|---|---|
| SET1 | Copy `spikes/sovereign_spikes/` into the server's `resources` directory | files in place | |
| SET2 | Add `ensure sovereign_spikes` to `server.cfg` (anywhere — no dependencies), restart, join | F8 shows a `[spike] loaded.` line listing every command | |
| SET3 | Open the F8 console and keep it visible | results print there in plain words | |

## 2. Coat is the model (S14 · F1)

Each RDR2 coat is its own horse model, not a swappable texture. If this holds, our catalog stays model-agnostic and community coats "just work."

| # | Command | What should happen | Result |
|---|---|---|---|
| A1 | `/spike_horse` | a grey Kentucky Saddler spawns ~3m ahead, frozen, facing you | |
| A2 | `/spike_coat A_C_Horse_Turkoman_Gold` | the horse respawns as a gold Turkoman (coat = model) | |

## 3. Mane, tail & tack (F1 · F5)

Metaped components applied at runtime — the raw material of the customizer and stored tack.

| # | Command | What should happen | Result |
|---|---|---|---|
| A3 | `/spike_mane 1` | mane changes to the short preset | |
| A4 | `/spike_mane 3` | mane changes to the long preset (different from A3) | |
| A5 | `/spike_tail 1` | tail changes to the short preset | |
| A6 | `/spike_tail 3` | tail changes to the long preset | |
| A7 | `/spike_saddle` | a saddle appears on the horse | |

## 4. The cross-breed question (S15 — the deciding line)

The single most important observation. It decides whether the customizer offers components **per-breed** or as one **universal** list.

| # | Command | What should happen | Result |
|---|---|---|---|
| A8 | after the A2 coat swap, `/spike_mane 3` again | **does a mane preset that changed the grey horse still change the Turkoman?** Note which breed ignored it, if any. | |

## 5. The orbital camera (L5 · N7)

| # | Command | What should happen | Result |
|---|---|---|---|
| C1 | `/spike_cam` | scripted camera orbits the horse smoothly, always centred | |
| C2 | `/spike_cam 6 40` | wider, faster orbit — still smooth, no jitter/clipping | |
| C3 | (judge the motion) | no stutter, no camera stuck inside the horse, no failure to activate | |
| C4 | `/spike_camstop` | camera restores to normal; player unfreezes | |

## 6. Strike the set

| # | Command | What should happen | Result |
|---|---|---|---|
| Z1 | `/spike_clear` | preview horse removed cleanly | |
| Z2 | remove `ensure sovereign_spikes` from `server.cfg` | throwaway scaffolding gone — it never ships with the real resource | |

## 7. What the results decide

- **A1–A7 pass** → the storefront preview, customizer (S14/S15) and tack apply/store (F1/F5) all build on the confirmed `0xD3A7B003ED343FD9` apply + `UpdatePedVariation` pipeline.
- **A8 applies across breeds** → the customizer offers a **universal** component list. **A8 does nothing on the new breed** → components are offered **per-breed** (more config, but correct). Either way we proceed — this just picks the design.
- **C1–C4 pass** → the storefront orbital camera (L5) + zoom (N7) are locked as prototyped.
- **Body size** and **shiny coat** (M3) are deliberately NOT in this spike — separate follow-up investigations, not Phase 1 blockers.

## 8. Sign-off

Phase 1 spikes pass when: R1 boots clean, every A/C line has a recorded result (pass OR fail), and A8 has a clear verdict. Then the confirmed approach is written into `client/` and Phase 1 (Core Parity MVP) begins.

---

## Test log

_(Rounds recorded here as they happen — date, who tested, what was confirmed or found. Owner convention: a ledger line ticked without notes = confirmed working.)_

### Round 1 — 2026-07-14 (owner)

- **Orbital camera (C1–C4): PASS.** Smooth orbit, auto-centre, stop/restore all confirmed. Approach locked as prototyped (`0x40C23491CE83708E` + per-frame `SetCamCoord`/`PointCamAtCoord`).
- **Spawn (A1/A2): FAIL — horse invisible + airborne.** Console reported the horse spawned; entity existed (owner could mount it) but was not visible and sat above the ground. A3–A8 skipped (couldn't judge an invisible horse). Same class of bug as sovereign_storyworks Phase 0 "peds spawned airborne."
- **Root cause:** the spike created the ped without (a) ground-snap and (b) metaped variation init. A raw RDR3 horse renders invisible until `0x283978A15512B2FE` (variation init) is called, and spawns airborne without `GetGroundZAndNormalFor_3dCoord`.
- **Fix (spike rev 2):** ground-snap Z + variation init + `SetEntityVisible`, mirroring the proven vorp_utils / vorp_stables patterns. **Awaiting retest of A1–A8** (camera already passed — no need to re-run C).

### Round 2 — 2026-07-14 (owner)

- **All 17 PASS.** With rev 2 the horse spawns visible and on the ground.
- **A1/A2 — coat = model:** confirmed. Swapping to the Turkoman produced a gold Turkoman. Catalog stays model-agnostic.
- **A3–A7 — mane/tail/tack:** confirmed applying at runtime via `0xD3A7B003ED343FD9` + `UpdatePedVariation`.
- **A8 — cross-breed: PASS (the deciding answer).** A mane preset that changed the grey Kentucky Saddler ALSO changed the gold Turkoman → components are **not** breed-locked. **Decision: the customizer offers ONE universal component list**, not per-breed lists.

### GATE RULING — 2026-07-14

**PASSED.** Both proofs stand: horse-appearance pipeline (spawn + coat=model + mane/tail/tack apply, universal components) and orbital camera. Confirmed approach recorded in `docs/PHASE1_SPIKE_FINDINGS.md`. `sovereign_spikes` retired (owner removed it from server.cfg). Phase 1 (Core Parity MVP) may begin.
