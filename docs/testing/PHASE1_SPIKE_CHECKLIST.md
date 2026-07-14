# Phase 1 Spike Checklist — Horse Appearance & Orbital Camera

> **The live checklist is the interactive Spike Ledger (Sovereign Exit-Gate Ledger format — tickable, progress bar, ticks persist):**
> **https://claude.ai/code/artifact/944cf025-acfa-4828-8ca1-329b87c9f153**
> This file is the plain-text mirror kept in the repo for the permanent record.

**Written for:** anyone — no developer knowledge needed.
**What you need:** the dev server with `vorp_core` running, admin rights, and ~10 minutes. The throwaway `sovereign_spikes` resource (in `spikes/sovereign_spikes/`).
**What to send back to Claude:** the F8 console lines each command prints, plus a PASS/FAIL/WEIRD note per item below. A "fail" is information, not a blocker.

## 1. Raise the resource

1. Copy `spikes/sovereign_spikes/` into the server's `resources` directory.
2. Add to `server.cfg` (anywhere — it has no dependencies): `ensure sovereign_spikes`
3. Restart the resource (or `refresh` + `ensure sovereign_spikes`), join, and open the F8 console.

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | F8 console after start | a `[spike] loaded.` line listing every command | |

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

### Round 1 — (pending owner test)
