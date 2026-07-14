# Milestone 1.1 Checklist — Stable Spine & Storefront

> **The live checklist is the interactive Ledger (Pass/Fail/Skip + notes + Build the Report):**
> **https://claude.ai/code/artifact/07b8240a-3920-4d62-aa86-6fbef652450e**
> This file is the plain-text mirror kept in the repo for the permanent record.

**Written for:** anyone — no developer knowledge needed.
**What you need:** a dev server with `vorp_core`, `vorp_inventory`, `sovereign_notify`, `sovereign_menus`, and `oxmysql` running; the `sovereign_stables` build deployed; ~10 minutes.
**What to send back:** in the ledger, mark each line Pass/Fail/Skip with notes, press **Build the Report**, and paste it back (plus any red F8 lines).

This is the first playable slice and is **browse-only** — buying, summoning and storing arrive in later milestones.

## 1. Boot & health

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Import `sql/install.sql` once; `ensure sovereign_stables` after its dependencies; restart | no red errors on start | |
| B2 | `/stables_diag` | all 4 dependencies OK, Database OK, module list includes `stables`, no config problems | |
| B3 | Open the map | a blip "Valentine Stables" at the configured spot | |
| B4 | Travel to the stable | an ambient stablehand ped, visible and on the ground (not invisible/airborne/T-posing) | |

## 2. Open the storefront

| # | Check | Expect | Result |
|---|---|---|---|
| O1 | Stand near the stablehand | on-screen prompt appears: key + "Speak with the Stablehand" | |
| O2 | Tap the prompt key (or `/sovstable`; `/sovstableforce` ignores range) | branded storefront opens (dark leather, brass, Sovereign lettering) | |
| O3 | Read the header | your name + job, and real cash + gold | |
| O4 | Look at the centre | a horse stands there, visible, on the ground, slowly orbiting | |

## 3. Browse the catalog

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | Read the list | horses with name, breed, $ + gold price; locked horse shows a padlock | |
| R2 | Click a different horse | centre horse swaps model; right panel updates (name, sex/age/hands, lore, stats, price) | |
| R3 | Click Specialty / Stock tabs | list swaps groups; first of the tab auto-selects | |
| R4 | Use the ‹ › arrows | selection steps through the current tab, previewing each | |
| R5 | Drag on the centre, then scroll | drag orbits the camera; scroll zooms; releasing drifts again | |
| R6 | Framing check | horse sits in the open centre, not hidden behind side panels (note if off) | |
| R7 | `Request Purchase` | notification "Purchasing opens in the next update." (intentional — 1.2) | |

## 4. Close & cleanup

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | Press `Esc` / ESC button | storefront closes, camera returns, control back, preview horse vanishes | |
| X2 | Review F8 for the session | no red Lua errors from `sovereign_stables` | |

## 5. What the results decide

- **B1–B4 / O1–O4 fail** → a wiring or dependency problem; paste the F8/diag output and I fix before 1.2.
- **R6 (framing)** → if the horse isn't centred in the open area, I add a camera lateral offset (tuning, not a redesign).
- **All pass** → milestone 1.1 signed off; 1.2 (server-authoritative buy → own loop, DB persistence) begins.

## 6. Sign-off

Milestone 1.1 passes when boot is clean, the storefront opens over a visible orbiting horse, browsing/tabs/arrows/detail all work, and close is clean. Then 1.2 begins.

---

## Test log

### Round 1 — (pending owner test)
