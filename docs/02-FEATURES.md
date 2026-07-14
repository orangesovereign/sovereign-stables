# 02 · Feature Master List (living document)

> The single source of truth for scope. Every feature is tagged with a **Bar**, a **Feasibility** verdict (tech-prepped against RedM natives + VORP), its **Dependencies**, and a target **Phase**. This doc is maintained continuously — nothing gets coded that isn't listed and marked feasible here.

## Legend

**Bar** — `MATCH` = parity with vorp_stables · `EXCEED` = beyond baseline (our differentiators) · `NEW` = Sovereign-original idea.

**Feasibility** (RedM/RDR3 + VORP):
- ✅ **Confirmed** — known-supported natives/exports; standard implementation.
- ⚠️ **Needs prep** — feasible in principle; exact native(s)/approach must be verified in a spike before coding.
- 🧪 **Hard/Risky** — achievable but heavy, fragile, or dependent on RDR3 native quirks; prototype first, may be cut.
- ❓ **Unknown** — must research before committing to v1.

**Status** — `⬜ planned · 🔬 tech-prep · 🧱 building · ✅ done · ⏸ deferred`.

---

## A. Stable System

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| S1 | Multiple stable locations (blip, prompt, ambient NPC) | MATCH | ✅ | core | 1 | ⬜ |
| S2 | Per-stable settings fully independent (own catalog, prices, cams, options) | EXCEED | ✅ | core | 1 | ⬜ |
| S3 | Job restrictions per stable | EXCEED | ✅ | vorp jobs | 1 | ⬜ |
| S4 | Buy horses — cash **and gold** pricing | MATCH+ | ✅ | vorp money | 1 | ⬜ |
| S5 | Store / retrieve horses at a stable | MATCH | ✅ | db | 1 | ⬜ |
| S6 | Whistle-summon vs stable-only toggle (per horse and/or per server) | EXCEED | ✅ | — | 1 | ⬜ |
| S7 | Horses tied to storing-stable **or** accessible from every stable (config) | EXCEED | ✅ | db | 1 | ⬜ |
| S8 | Enable/disable selling old (aged) horses | EXCEED | ⚠️ | ageing (H23) | 3 | ⬜ |
| S9 | Configurable horse XP loss on server restart | EXCEED | ✅ | db | 2 | ⬜ |
| S10 | Black-market horse sales with per-sale cooldown | EXCEED | ⚠️ | wild (W*), db | 4 | ⬜ |
| S11 | Heal horses via items or paid stable service (configurable price) | EXCEED | ✅ | inventory, money | 2 | ⬜ |
| S12 | Horseshoe system — configurable, max upgrade level | EXCEED | ⚠️ | tack, stats | 3 | ⬜ |
| S13 | Flaming horseshoe support | EXCEED | 🧪 | S12, particles | 4 | ⬜ |
| S14 | Customize components: body size, colors, manes, tails | EXCEED | ⚠️ | native ped comp | 2 | ⬜ |
| S15 | Component control UI: circular controls **or** arrow keys (config) | EXCEED | ⚠️ | sovereign_menus | 2 | ⬜ |
| S16 | Faction stables — same-job players share a horse pool | EXCEED | ✅ | vorp jobs, db | 3 | ⬜ |
| S17 | Three taming minigames, selectable: number-sequence / pull / basic | EXCEED | ⚠️ | wild horses | 4 | ⬜ |
| S18 | Simulated spawn nodes — define horse spawns where the game has none | EXCEED | 🧪 | wild horses | 4 | ⬜ |

## B. Wild Horse System

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| W1 | Configurable spawn frequency & locations | EXCEED | ✅ | — | 4 | ⬜ |
| W2 | Capturing wild horses (via taming minigame) | EXCEED | ⚠️ | S17 | 4 | ⬜ |
| W3 | Store captured wild horses in stable | EXCEED | ✅ | db | 4 | ⬜ |
| W4 | Sell wild horses (normal + black market pricing) | EXCEED | ✅ | money | 4 | ⬜ |
| W5 | Black-market prices & cooldown for wild horses | EXCEED | ⚠️ | S10, db | 4 | ⬜ |
| W6 | Per-model wild capture/storage/black-market settings | EXCEED | ✅ | horse catalog | 4 | ⬜ |

## C. Horse — Care, Status & Metabolism

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| H1 | Hunger & thirst systems (penalties + recovery), fully configurable | EXCEED | ✅ | db, loop | 2 | ⬜ |
| H2 | Eat from hay bales / drink from troughs (world props affect condition) | EXCEED | ⚠️ | world props | 3 | ⬜ |
| H3 | Feed special items to raise normal or golden status values | EXCEED | ✅ | inventory | 2 | ⬜ |
| H4 | Shared vs individual horse status system (config) | EXCEED | ✅ | db | 2 | ⬜ |
| H5 | Clean horses with cleaning items (remove dirt) | MATCH+ | ✅ | inventory | 2 | ⬜ |
| H6 | Hoof-cleaning system w/ movement penalty when neglected | EXCEED | ⚠️ | stats loop | 3 | ⬜ |
| H7 | Add/remove & store horse furs | EXCEED | ⚠️ | native ped comp | 3 | ⬜ |
| H8 | Rename horse via configurable item | EXCEED | ✅ | inventory | 2 | ⬜ |
| H9 | Tether horse using configurable item | EXCEED | ⚠️ | native rope/anim | 3 | ⬜ |

## D. Horse — Movement, Commands & Recovery

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| D1 | Whistle-call brings horse to player | MATCH | ✅ | — | 1 | ⬜ |
| D2 | Adjustable whistle/arrival distance | EXCEED | ✅ | — | 1 | ⬜ |
| D3 | Horse recall cooldown after dismissal | EXCEED | ✅ | — | 1 | ⬜ |
| D4 | Follow command after calling horse | MATCH+ | ✅ | native tasks | 1 | ⬜ |
| D5 | Auto-recovery after crash / unexpected disconnect | EXCEED | ⚠️ | db, server | 2 | ⬜ |
| D6 | Side-sitting command while mounted | EXCEED | ⚠️ | native anim/scenario | 3 | ⬜ |
| D7 | Weapon head-strike command while mounted | EXCEED | 🧪 | native anim | 3 | ⬜ |
| D8 | Stumble/fall on rail tracks & dangerous terrain (toggle, trait-linked) | EXCEED | 🧪 | personality | 4 | ⬜ |
| D9 | Horse inventory access: everyone vs selected players (config) | MATCH+ | ✅ | inventory | 2 | ⬜ |

## E. Horse — Progression & Behavior

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| E1 | Leveling from activities: riding, leading, commands, obstacles, lunging | EXCEED | ⚠️ | stats loop | 3 | ⬜ |
| E2 | XP modifiers by horse size & activity (config) | EXCEED | ✅ | E1 | 3 | ⬜ |
| E3 | Bonding system that reduces spooking | EXCEED | ⚠️ | native bonding | 3 | ⬜ |
| E4 | Courage training — improves fear resistance | EXCEED | ⚠️ | E3 | 3 | ⬜ |
| E5 | Personality & behavior system (traits) | EXCEED | 🧪 | db | 4 | ⬜ |
| E6 | Ageing: aging speed, max age, death chance when old, age-reset items | EXCEED | ⚠️ | db, loop | 3 | ⬜ |
| E7 | Horse EXP loss on restart (see S9) | EXCEED | ✅ | db | 2 | ⬜ |

## F. Tack & Components

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| F1 | Buy/apply components: saddle, blanket, horn, saddlebags, stirrups, bedroll, lantern, mask, mane, tail | MATCH | ✅ | native ped comp | 1 | ⬜ |
| F2 | Body-size / coat-color customization | EXCEED | ⚠️ | native | 2 | ⬜ |
| F3 | Transfer components between horses | EXCEED | ⚠️ | db | 3 | ⬜ |
| F4 | Transfer components via saddle stands | EXCEED | ⚠️ | world props | 3 | ⬜ |
| F5 | Store bought components in stable, re-apply later | MATCH | ✅ | db | 1 | ⬜ |

## G. Breeding & Genetics

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| G1 | Advanced breeding with full genetics system | EXCEED | 🧪 | db, catalog | 5 | ⬜ |
| G2 | Configurable cost, duration, pairing distance | EXCEED | ✅ | G1 | 5 | ⬜ |
| G3 | Required items + breeding-reset items | EXCEED | ✅ | inventory | 5 | ⬜ |
| G4 | Per-horse breeding permissions | EXCEED | ✅ | catalog | 5 | ⬜ |
| G5 | Neutering | EXCEED | ✅ | db | 5 | ⬜ |
| G6 | Foal → growth into rideable horse | EXCEED | 🧪 | ageing (E6) | 5 | ⬜ |

## H. Wagon & Cart System

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| WG1 | Buy/store/summon wagons per vendor catalog & price | MATCH | ✅ | db | 1 | ⬜ |
| WG2 | Configurable wagon spawn delay | EXCEED | ✅ | — | 1 | ⬜ |
| WG3 | Vehicle storage access: everyone vs selected players | MATCH+ | ✅ | inventory | 2 | ⬜ |
| WG4 | Optional default green wagon color | EXCEED | ⚠️ | native livery | 2 | ⬜ |
| WG5 | Auto-recovery after crash | EXCEED | ⚠️ | server | 2 | ⬜ |
| WG6 | Recall & reset | MATCH+ | ✅ | — | 1 | ⬜ |
| WG7 | Rename wagon via item | EXCEED | ✅ | inventory | 2 | ⬜ |
| WG8 | Build wagons via crafting system | EXCEED | ⚠️ | crafting/inventory | 5 | ⬜ |
| WG9 | Persistent wagon health saving | EXCEED | ✅ | db | 2 | ⬜ |
| WG10 | Dirt accumulation at low condition | EXCEED | 🧪 | native decal | 4 | ⬜ |
| WG11 | Wheel-damage system w/ repair items | EXCEED | 🧪 | native veh | 4 | ⬜ |
| WG12 | Wagon destruction & repair mechanics | EXCEED | ⚠️ | db | 4 | ⬜ |
| WG13 | Configurable component pricing at stables | EXCEED | ✅ | — | 2 | ⬜ |
| WG14 | Work wagons w/ dedicated resource storage (wood/stone/water) | EXCEED | ⚠️ | inventory | 5 | ⬜ |

## I. Per-Horse Configuration (catalog-level)

Every horse model configurable individually: I1 purchase availability · I2 allowed stable locations · I3 cash & gold prices · I4 storage capacity · I5 max carried hides · I6 job/group purchase restriction · I7 resale value · I8 breeding permission · I9 body-size options · I10 mane/tail/coat color options · I11 flaming-horseshoe support · I12 wild capture/storage/black-market settings. — **Bar EXCEED · Feasibility ✅ (data-driven config) · Phase 1 scaffolding, filled per feature.**

## J. Job Permissions (per job, some per grade)

Every permission below is a per-job (and where noted per-grade) gate resolved server-side. All are **Feasibility ✅** (config gates over existing features); each gate is wired when its underlying feature lands, scaffolding built in Phase 1.

| ID | Permission | Gates feature |
|----|------------|---------------|
| J1 | Maximum horses | ownership caps |
| J2 | Maximum wagons | ownership caps |
| J3 | Maximum active breedings | G-series |
| J4 | XP gain modifier | E1/E2 |
| J5 | Horse training (general) | E-series |
| J6 | Lunging | E1 |
| J7 | Obstacle courses | E1 |
| J8 | Bonding | E3 |
| J9 | Courage training | E4 |
| J10 | Horse taming | S17, W2 |
| J11 | Breeding | G-series |
| J12 | Horseshoe installation | S12 |
| J13 | Access to other players' horses | D9 |
| J14 | Wagon & wheel repairs | WG11/WG12 |
| J15 | Horse healing | S11 |
| J16 | Horseshoe / hoof cleaning | H6, S12 |
| J17 | Horse statistics visibility | codex (X8) |
| J18 | Horse & wagon recall | D1, WG6 |
| J19 | Horse customization | S14/F |
| J20 | Horse painting (coat) | S14, M3 |
| J21 | Wagon crafting | WG8 |
| J22 | Horse Creator access (job **+ grade** locked) | M2 |

## L. Presentation, NUI & Camera

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| L1 | **Custom branded NUI** — Sovereign County styling, visually distinct from other sovereign_scripts; drives storefront, customizer, codex | NEW | ✅ | — | 1 | ⬜ |
| L2 | Ambient ped per stable for buy / customize / retrieve / switch | MATCH+ | ✅ | core | 1 | ⬜ |
| L3 | Blips individually toggleable | MATCH | ✅ | — | 1 | ⬜ |
| L4 | Horse preview in stable catalog | MATCH | ✅ | native cam | 1 | ⬜ |
| L5 | Orbital camera auto-centering on horse | EXCEED | ⚠️ | native cam | 1 | ⬜ |
| L6 | Horses get dirty (or not) while stored — configurable | EXCEED | ⚠️ | metabolism | 3 | ⬜ |
| L7 | Notifications via `sovereign_notify` (=K1) | NEW | ✅ | sovereign_notify | 1 | ⬜ |
| L8 | Lightweight lists/prompts/confirmations via `sovereign_menus` | NEW | ✅ | sovereign_menus | 1 | ⬜ |

## M. Content & Catalog

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| M1 | 60+ breeds + custom coat presets | EXCEED | ✅ | catalog | 1 (fill ongoing) | ⬜ |
| M2 | **Horse Creator** — build new breeds in-game via custom menu, job+grade locked | NEW | 🧪 | catalog, db, L1 | 5 | ⬜ |
| M3 | Shiny/glossy coats via configurable items | EXCEED | ⚠️ | native coat FX | 3 | ⬜ |

## X. Operator, Integration & QoL additions *(scoped 2026-07-14)*

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| X1 | Admin menu — spawn/give/inspect/heal/delete/reassign/recover any horse | NEW | ✅ | core | 1 | ⬜ **v1** |
| X2 | Economy transaction log + anti-dupe safeguards | NEW | ✅ | db | 1 | ⬜ **v1** |
| X3 | Horse registry / county papers — DB-side brand & papers now, Sovereign County site surfacing deferred | NEW | ⚠️ | db (site API later) | 3 | ⬜ v1 core, surface later |
| X4 | Veterinary hook for Sovereign Medical Suite | NEW | ⚠️ | medical suite | 3 | ⬜ **built, default OFF** (script arrives later) |
| X5 | Ranching feed hook (feed from ranch hay/feed) | NEW | ⚠️ | ranching | 3 | ⬜ **built, default OFF** (script arrives later) |
| ~~X6~~ | ~~Stable boarding / upkeep fees~~ | — | — | — | — | ❌ **cut** |
| ~~X7~~ | ~~Horse insurance / recovery~~ | — | — | — | — | ❌ **cut** |
| X8 | Horse codex/journal — stats, genetics, lineage, bonding, age, achievements | NEW | ✅ | L1 | 2 | ⬜ **v1** |
| X9 | Rebindable keys (all binds player-configurable) | NEW | ✅ | — | 1 | ⬜ **v1** |

## K. Platform / Integration (cross-cutting, Sovereign-specific)

| ID | Feature | Bar | Feasibility | Deps | Phase | Status |
|----|---------|-----|-------------|------|-------|--------|
| K1 | All notifications via `sovereign_notify` | NEW | ✅ | sovereign_notify | 1 | ⬜ |
| K2 | Hybrid UI: **custom branded NUI** for rich screens (storefront/customizer/codex, see L1) + `sovereign_menus` for lightweight lists/prompts (see L8) | NEW | ✅ | both | 1 | ⬜ |
| K3 | `bridge` abstraction (core/inventory/money/notify/menu swappable) | NEW | ✅ | — | 1 | ⬜ |
| K4 | Module registration system for future feature packs | NEW | ✅ | — | 1 | ⬜ |
| K5 | Public exports/events API for other scripts to integrate | NEW | ✅ | — | 1 | ⬜ |
| K6 | Non-dev-friendly config files (heavy comments, grouped, validated) | NEW | ✅ | — | 1 | ⬜ |
| K7 | Config validator + startup diagnostics (catch bad coords/models) | NEW | ✅ | — | 1 | ⬜ |
| K8 | Data migration from `vorp_stables` (keep existing rides/inventories) | MATCH | ⚠️ | db | 6 | ⏸ (greenfield — deferred) |
| K9 | Version checker / update notice | MATCH | ✅ | — | 6 | ⬜ |

---

## Open feasibility questions (drive tech-prep spikes)

1. **Ped/horse appearance at runtime** (S14, F1, F2, H7) — confirm RDR3 natives for setting mane/tail/coat/body components on a spawned horse and persisting them. *(vorp_stables does manes/tails/tack via the `complements` hashes in `data.lua` — proven path; body-size & coat need a spike.)*
2. **Bonding/courage natives** (E3, E4) — is RDR3's built-in horse-bonding stat readable/writable, or do we simulate our own?
3. **Golden vs normal status** (H3) — mapping to RDR3 horse core attributes vs. a custom overlay stat.
4. **Wheel damage / dirt decals** (WG10, WG11) — native support on RDR3 wagons is uncertain; may need visual approximation.
5. **Simulated spawn nodes** (S18) — spawning/persisting wild peds where no game spawn exists; density & cleanup.
6. **Mounted anims** (D6, D7) — availability of side-sit & head-strike anim dicts on horseback.
7. **Genetics model** (G1) — design our own inheritance model (color/size/stat traits) since RDR3 has none natively.
8. **Orbital camera** (L5) — native cam path for a smooth auto-centering orbit around a previewed horse.
9. **Shiny coat FX** (M3) — native means to apply a gloss/shine overlay to a horse coat at runtime.
10. **Horse Creator** (M2) — persisting player-authored breed definitions (component/coat/stat combos) to config or DB and spawning them reliably.

Each ❓/🧪/⚠️ item gets a short spike in `docs/spikes/` before it enters a build phase.
