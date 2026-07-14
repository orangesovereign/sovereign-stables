# 03 · Coding Plan (phased)

> How we build it. Each phase ends in something testable in-game. Feature IDs reference `02-FEATURES.md`. Phases are gated: we don't start a phase until its prerequisite tech-prep spikes pass.

## Design principles (apply to every phase)

1. **Data-driven.** Behavior lives in `config/`, not code. A non-dev owner edits configs; code reads them. Every config file is heavily commented and validated at boot (K6, K7).
2. **Bridge everything external.** Core, money, inventory, notify, menu are reached only through `shared/bridge.lua`. Swapping a dependency = editing one adapter (K3). Notify → `sovereign_notify`, menus → `sovereign_menus` from day one (K1, K2).
3. **Module registry.** Features register into a central registry with lifecycle hooks (`onInit`, `onPlayerLoaded`, `onHorseSpawned`, `onTick`, exports). New feature packs drop in without touching the core (K4).
4. **Public API.** A stable exports/events surface so other Sovereign scripts (ranching, medical, jobs) can query/mutate horse state (K5).
5. **Persistence-first.** Any stat that matters survives restart/crash. Server is authoritative; client never decides money, ownership, or stats.
6. **Prototype the risky.** Every 🧪/❓ feature gets a throwaway spike proving the natives work before it enters a build phase.
7. **Model/coat-agnostic catalog.** Code never hardcodes the stock breed roster; the catalog references any installed model/coat (stock or community add-on) by name/hash. See Assets & coats policy in `00-README.md`.

## Proposed resource layout

```
sovereign_stables/
  fxmanifest.lua
  config/
    config.lua            # global options (caps, keys, toggles)
    stables.lua           # per-stable definitions (S1–S3, S6–S7, S16)
    horses.lua            # per-model catalog (I1–I12)
    wagons.lua            # per-model wagon catalog (H-series)
    tack.lua              # components catalog (F-series)
    metabolism.lua        # hunger/thirst/status tuning (C-series)
    progression.lua       # leveling/bonding/courage/ageing (E-series)
    breeding.lua          # genetics + breeding (G-series)
    wild.lua              # wild spawns + capture + black market (B-series)
    jobs.lua              # per-job permissions (J-series)
    locales/en.lua
  shared/
    bridge.lua            # adapters: core/money/inventory/notify/menu
    registry.lua          # module registration + lifecycle bus
    util.lua              # math/coords/validation helpers
    events.lua            # event-name constants
  client/
    core.lua              # prompts, stable entry, camera/preview
    whistle.lua           # summon/follow/recall (D-series)
    interactions.lua      # brush/clean/tether/mounted cmds
    components.lua        # appearance apply + component UI (S14/S15/F)
    minigames.lua         # taming minigames (S17)
    metabolism.lua        # client-side status FX/penalties
  server/
    core.lua              # ownership, purchases, transfers
    db.lua                # schema access layer (oxmysql)
    persistence.lua       # save/load horse state, crash recovery
    economy.lua           # cash/gold, black market, cooldowns
    breeding.lua          # genetics resolution
    wild.lua              # wild lifecycle
  modules/                # optional/expansion feature packs
  ui/                     # custom branded NUI (storefront, customizer, codex, horse creator)
    src/                  #   built with a bundler; ships dist/ in fxmanifest
    dist/
  sql/
    install.sql
  docs/                   # ← planning docs live here during dev
```

## UI architecture (decided 2026-07-14)

Hybrid, not one-size-fits-all:
- **Custom branded NUI** (`ui/`) for the rich, visual screens — stable storefront/catalog with live horse preview + orbital camera, appearance/painting customizer, horse codex/journal, and the Horse Creator. Sovereign County visual identity but deliberately its own look, distinct from the other sovereign_scripts (which use the shared `sovereign_menus`/`sovereign_notify` chrome).
- **`sovereign_menus`** for lightweight lists, confirmations, and quick prompts (buy confirm, transfer accept, yes/no gates).
- **`sovereign_notify`** for all objective slips / ticks / status cards.
Both sovereign resources are still reached through `bridge.lua`; the custom NUI is a first-class part of this resource.

## DB schema direction

Extend the baseline `stables` table rather than fight it; add columns/tables for new state so migration (K8) stays simple:
- `stables` (baseline) + new: `stable_origin`, `age`, `birth_ts`, `genetics` (json), `personality` (json), `metabolism` (json), `shoes` (json), `bonding`, `courage`, `faction`.
- `horse_lineage` (breeding parentage), `wild_cooldowns` (black-market timers), `foals` (in-progress growth). Design so unused features cost nothing.

---

## Phase 0 — Foundation *(no gameplay yet; everything rests on this)*
Resource skeleton, `fxmanifest`, `bridge.lua` (wired to vorp_core + vorp_inventory + sovereign_notify + sovereign_menus), `registry.lua` lifecycle bus, config loader + validator (K6, K7), `db.lua` + `install.sql`, custom NUI shell + branding baseline (L1), empty public API stubs (K5). **Exit test:** resource starts clean, `/stables_diag` prints loaded config + dependency health, NUI shell opens/closes with focus handling.

## Phase 1 — Core Parity MVP *(matches vorp_stables)*
S1–S5, S6, S7, D1–D4, F1, F5, WG1, WG2, WG6, WG13, I1–I3 (catalog scaffold), J-scaffold (J1/J2/J18), L1–L5/L7/L8 (branded storefront, ambient ped, toggleable blips, preview + orbital camera), M1 (breed catalog scaffold), hard death + respawn cooldown, ride transfer, default ride, name tags. Storefront/preview in custom NUI; confirmations via sovereign_menus; notifications via sovereign_notify. Optional-but-cheap: X1/X2/X9 if approved. **Exit test:** buy → store → summon → follow → equip tack → transfer a horse and a wagon in the branded UI, fully persisted. *At this point we have already matched vorp_stables.*

## Phase 2 — Care, Status & Persistence Depth
H1 (hunger/thirst), H3 (feed items), H4 (shared/individual status), H5 (clean), **H10 (stabled horses auto-clean after a configurable timer)**, **L9 (storefront preview horses always render clean)**, H8 (rename), C-golden status, S9/E7 (XP-loss-on-restart), S11 (healing service/items), D5 (crash recovery), D9/WG3 (inventory access control), WG4/WG5/WG7/WG9/WG12-basic (wagon color/recovery/rename/health), S14/F2/S15 (component & appearance customization + control UI). Gated on the **dirt/cleanliness native spike** (open question 11). **Exit test:** a horse gets hungry, is fed/healed, survives a server restart with correct stats, a wagon's health persists, a dirty horse left stabled comes back clean after the configured minutes, and the storefront never shows a dirty horse.

## Phase 3 — Progression, Faction & Advanced Care
E1/E2 (activity leveling), E3/E4 (bonding/courage), E6 (ageing), S8 (sell aged), S16 (faction stables), S12 (horseshoes), H6 (hoof care), H7 (furs), H9 (tether), F3/F4 (component transfer + saddle stands), D6/D7 (mounted commands), H2 (hay/trough). **Exit test:** a horse levels through use, ages over time, bonds with its owner, and a faction shares its pool.

## Phase 4 — Wild Horses, Minigames & Economy
W1–W6 (wild lifecycle), S17 (three taming minigames), S18 (simulated spawn nodes), S10 (black-market horses + cooldown), S13 (flaming horseshoe), E5 (personality traits), D8 (terrain stumble), WG10/WG11 (dirt/wheel damage). **Exit test:** find → tame → store → sell a wild horse; black-market cooldown enforced.

## Phase 5 — Breeding, Genetics, Horse Creator & Work Wagons
G1–G6 (breeding + genetics + foals + neutering), M2 (Horse Creator — job+grade-locked breed authoring), WG8 (wagon crafting), WG14 (work wagons). **Exit test:** breed two horses → genetics resolve → foal grows into a rideable horse with inherited traits; a permitted job creates a new custom breed that others can then buy.

## Phase 6 — Migration, Hardening & Release Candidate
K8 (vorp_stables data migration), K9 (version check), full locale pass, load/stress test, config documentation, README + install guide, v1 RC tag. **Exit test:** a live vorp_stables DB migrates cleanly; owner can install from README alone.

---

## Tech-prep spikes to run before their phase (from 02-FEATURES open questions)

| Spike | Blocks | Phase gate |
|---|---|---|
| Horse appearance natives (mane/tail/coat/body/furs at runtime + persist) | S14, F1, F2, H7 | 1→2 |
| Golden vs normal core-attribute mapping | H1, H3 | 2 |
| Crash/disconnect recovery pattern | D5, WG5 | 2 |
| Native bonding/courage read/write vs simulate | E3, E4 | 3 |
| Mounted anim dicts (side-sit, head-strike) | D6, D7 | 3 |
| Wild ped spawn/persist at custom nodes + cleanup | S18, W1 | 4 |
| Horse dirt/cleanliness native — read + force clean | H5, H10, L9, L6 | 2 |
| Wagon wheel-damage / dirt decal native support | WG10, WG11 | 4 |
| Orbital preview camera (smooth auto-center orbit) | L5 | 1 |
| Shiny/gloss coat FX at runtime | M3 | 3 |
| Genetics/inheritance model design | G1 | 5 |
| Horse Creator — persist & spawn player-authored breeds | M2 | 5 |

## What could get cut from v1 RC (if scope pressure hits)
🧪 items are the cut candidates in priority order: WG10/WG11 (dirt/wheel visuals), D7 (head-strike), D8 (terrain stumble), S13 (flaming shoe), S18 (simulated nodes). These become v1.1. Everything MATCH-tagged is non-negotiable for v1.
