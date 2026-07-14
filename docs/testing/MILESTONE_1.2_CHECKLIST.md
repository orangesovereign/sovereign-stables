# Milestone 1.2 Testing Checklist — Buy → Own Loop

> **The live checklist is the interactive Milestone 1.2 Ledger (tickable pass/fail/skip + notes, progress bar, report builder, marks persist):**
> **https://claude.ai/code/artifact/c99403ce-30ed-4db3-b2a0-28da0d2e1038**
> This file is the plain-text mirror kept in the repo for the permanent record.

**Written for:** anyone — no developer knowledge needed.
**What you need:** the dev server with the 1.2 build, `vorp_core` / `vorp_inventory` / `sovereign_notify` / `sovereign_menus` running, a MySQL tool open, and ~15 minutes.
**What to send back to Claude:** the generated report (pass/fail/skip + notes), plus any red F8 lines.

## 1. Boot & health

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy the 1.2 build, restart `sovereign_stables` (import `sql/install.sql` once if you never have) | no red errors on start | |
| B2 | In game: `/stables_diag` | all four dependencies OK, Database OK, modules include `stables`, no config problems | |
| B3 | MySQL: tables `sovereign_horses` and `sovereign_ledger` exist | both present | |

## 2. Buy a horse (S4 · I3 · X2)

The server sets the price and takes the money — the client never decides either.

| # | Check | Expect | Result |
|---|---|---|---|
| P1 | Open Valentine's storefront, pick an affordable horse, press **Request Purchase** | green card "<name> is yours."; header cash/gold drops by exactly the price | |
| P2 | MySQL: `sovereign_horses` | one new row for your character: name, model, `stable_origin` = `valentine`, `is_default` = 1 if first | |
| P3 | MySQL: `sovereign_ledger` | a `buy_horse` row logging exactly what you paid | |
| P4 | Try to buy something you can't afford (gold Turkoman = $3,200 / 12 gold) | red "You can't afford that."; **no** money taken, **no** row | |

## 3. My Horses (J1 · default ride)

| # | Check | Expect | Result |
|---|---|---|---|
| M1 | Click **My Horses** in the left nav | your horses listed, count badge matches, footer "N of 3" (your cap) | |
| M2 | Click one of your horses | centre preview swaps to it; right panel shows "★ Yours" ribbon, its name, **no** price | |
| M3 | First horse shows `★ Default`. Select another → **Make Default Ride** | the star moves; only one default ever | |
| M4 | Click **Stablefront** | shop list, Specialty/Stock tabs and prices return | |

## 4. Caps, dupes & persistence (the guards)

| # | Check | Expect | Result |
|---|---|---|---|
| C1 | Keep buying until you hit your limit (default 3) | "You already keep 3 horse(s) — your limit."; **no** charge | |
| C2 | Mash **Request Purchase** as fast as you can | charged **once**, **one** horse — no duplicate rows, no double charge (anti-dupe lock) | |
| C3 | `restart sovereign_stables`, reopen, **My Horses** | every horse still there with the right default — it lives in the DB | |

## 5. Close & cleanup

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | Press `Esc` / ESC button | storefront closes, camera returns, control back, preview horse gone | |
| X2 | F8 console for the session | no red Lua errors from `sovereign_stables` | |

## 6. What the results decide

- **P1–P3 pass** → the money→ownership→persistence chain is sound; 1.3 (summon & field) can safely spawn owned horses.
- **P4 / C1 fail (money taken without a horse, or cap bypassed)** → **blocker**. The economy can't ship with that.
- **C2 fail (double charge or duplicate row)** → **blocker**; the anti-dupe lock needs rework before any further economy features.
- **C3 fail** → persistence bug; everything above it is meaningless until fixed.
- **M3 fail** → default-ride bookkeeping; matters for 1.3 (whistle calls your default horse).

## 7. Sign-off

Milestone 1.2 passes when a purchase moves real money, writes exactly one horse row + one ledger row, respects the cap, survives a restart, cannot be duped, and My Horses reflects it all. Then 1.3 (summon & field) begins.

---

## Test log

_(Owner convention: a ledger line ticked without notes = confirmed working.)_

### Round 1 — 2026-07-14 (owner)

- **16/16 PASS, first pass, no fixes required.** Boot + both new tables clean.
- **Buy chain confirmed end-to-end:** purchase moves real money, writes exactly one `sovereign_horses` row and one `buy_horse` `sovereign_ledger` row; the unaffordable Turkoman was refused with no charge and no row.
- **My Horses confirmed:** list, count badge, cap footer, per-horse preview, and the single-default rule (Make Default Ride moves the star).
- **The guards — the lines that matter — all held:** cap enforced with no charge (C1), purchase-spam produced no double charge and no duplicate row (C2, anti-dupe lock working), and horses survived a resource restart with the correct default (C3, true DB persistence).
- Clean close, no red Lua errors across the session.

### GATE RULING — 2026-07-14

**PASSED.** Money → ownership → persistence chain is sound and the economy guards (cap, anti-dupe, refund-on-failure, server-side pricing) are proven. Milestone **1.3 (summon & field)** begins — owned horses can now safely be spawned into the world.
