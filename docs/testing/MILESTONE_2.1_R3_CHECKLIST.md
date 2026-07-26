# Milestone 2.1 · Round 3 — Animations, Water & the Full Roster

> **The live checklist is the interactive Round 3 Ledger:**
> **https://claude.ai/code/artifact/4a6ecd19-68fe-497f-9c05-debf2b9ecb82**
> This file is the plain-text mirror kept in the repo for the permanent record.
> Round 1: [20 pass · 2 fail](MILESTONE_2.1_CHECKLIST.md) · Round 2: [19 pass · 4 fail](MILESTONE_2.1_R2_CHECKLIST.md)

**Written for:** anyone — no developer knowledge needed.
**What you need:** the current build, a horse, a brush + feed items, rain (or wait for it), a river or trough, ~30 minutes.
**Setup:** nothing to install. No SQL, no new items required.

Round 2 went **19 pass · 4 fail**. All four are addressed, plus five rulings made since.

**The contorted rider was my fault twice over** — I hand-played animation clips that our own `PHASE1_SPIKE_FINDINGS` says must never be hand-played, after writing that warning into the same file. The engine's interaction system picks the right animation for where you're stood; it now does the choosing.

**And I had water backwards.** My first pass made rain and rivers *dirty* a horse. You corrected it — water washes.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart sovereign_stables`, `/stables_diag` | clean. **Note:** the old thirst warning is gone on purpose — horses drink from rivers now, so a water item is optional. Disable `drinking` in config and it comes back | |
| B2 | Open a storefront, let the catalog load | normal speed with ~100 horses — no hitch | |

## Art. II — The animations *(R3 · A1 · A2 — were FAIL)*

| # | Check | Expect | Result |
|---|---|---|---|
| A1 | Mounted on a dirty horse: `/sovanim brush` | a sane brushing motion, **or none**. Not the twisted 90° pose. If mounted has no animation, that's acceptable — say so. Contorted is not | |
| A2 | Mounted: `/sovanim feed` | plausible feeding motion, or none. Not the twisted pose | |
| A3 | On foot: `/sovanim feed` | still perfect — worked last round, must not regress | |
| A4 | On foot: `/sovanim brush` | the proper grooming animation | |

## Art. III — The brush, both ways (H5)

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | Brush **on foot** beside a dirty horse | it cleans | |
| R2 | Brush **mounted** | it cleans (animation quality is Art. II's question) | |
| R3 | Check the brush after a few uses, then wear one out | not consumed per use — counts down, says uses left, breaks at zero | |
| R4 | Try feeding a food item to a **dirty** horse | feeds but does not clean. The brush is the only cleaner | |

## Art. IV — Water washes *(the correction)*

*I had this backwards — my first pass treated water and rain as things that made a horse dirtier. This article replaces the old Mud one entirely.*

| # | Check | Expect | Result |
|---|---|---|---|
| M1 | Get a horse filthy, ride into a river and sit a minute | it gets **cleaner** — but stops at a floor (20% default). Water is not a bath | |
| M2 | Get a horse filthy and sit out in the **rain** a couple of minutes | washes all the way to **spotless** | |
| M3 | Once rain has it clean, look at the coat | a **shine** on it [M3] | |
| M4 | Ride the shiny horse until dirty again | the shine fades as dirt climbs — not permanent | |
| M5 | Gallop hard across dry ground | dirties **faster** than walking | |

## Art. V — Horses drink (H2)

| # | Check | Expect | Result |
|---|---|---|---|
| D1 | Let thirst drop, stand the horse **still** in a river. Watch `/sovcare` | thirst climbs on its own, fairly quickly | |
| D2 | Same at a **horse trough** in a town | the same. **If not, tell me which town** — that trough's prop name may differ, one-line fix | |
| D3 | Ride **through** water at a gallop without stopping | does **not** drink — can't gulp at a gallop | |
| D4 | While drinking, watch for notification spam | none — it updates quietly | |

## Art. VI — The info panel

| # | Check | Expect | Result |
|---|---|---|---|
| I1 | Stand near your horse, **hold right-click** | a panel: **Hunger**, **Thirst**, **Stamina** | |
| I2 | Same while **mounted** | the same panel | |
| I3 | Release right-click | disappears cleanly | |
| I4 | Walk well away, hold right-click | nothing — it's for the horse in front of you | |
| I5 | Gallop until winded, then open it | **Stamina** is the LIVE core and drops — not the trained stat | |
| I6 | Golden horse, open the panel | golden state reads on it | |
| I7 | Aim at someone **else's** horse, hold right-click | nothing. A horse's condition is its owner's business | |

## Art. VII — Every breed (M1)

| # | Check | Expect | Result |
|---|---|---|---|
| C1 | Storefront → **Stock Horses** | a long list, dozens of coats across many breeds | |
| C2 | **Specialty Horses** | the racers — Arabians, Thoroughbreds, Turkomans — at premium prices | |
| C3 | Click through several, watch the preview | each spawns. **If any coat fails to appear, note WHICH** — that model isn't installed on your server | |
| C4 | Compare a draft (Shire, Ardennes) to a racer | draft slower with more health; racer fast and dear | |
| C5 | Buy a generated (non-showcase) horse | buys, names and stores like the original four | |

## Art. VIII — The breed filter (N1)

| # | Check | Expect | Result |
|---|---|---|---|
| N1 | Stock tab → open the **Breed** dropdown | every breed on that tab, each with a count — e.g. *Mustang (8)* | |
| N2 | Pick one breed | list narrows; preview jumps to its first horse | |
| N3 | With a Stock-only breed selected, switch to **Specialty** | falls back to *All breeds*, not an empty list | |
| N4 | Switch to My Horses / Wagons / Components | the filter is hidden — it filters nothing there | |
| N5 | Close and reopen the storefront | back to *All breeds* | |

## Art. IX — Regression

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | `/sovflee`, and in-game Flee (lock on, F) | both send it home | |
| G2 | Core critical → ride → feed back | sluggish while critical, normal after | |
| G3 | Store a dirty horse a few minutes | the stable groomed it cleaner [H10] | |
| G4 | `restart sovereign_stables`, whistle out, `/sovcare` | values persisted, not reset | |
| G5 | Storefront preview horse | still spotless [L9] | |

## Art. X — Cleanup

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console all session | no red Lua errors. Paste anything red | |
| X2 | **Still carried:** the two-player transfer tests (`/sovgive`, `/sovgivewagon` + guards) from Phase 1 have never been run in a duo session | note only — Phase 1 can't be fully signed off until someone else is online with you | |
