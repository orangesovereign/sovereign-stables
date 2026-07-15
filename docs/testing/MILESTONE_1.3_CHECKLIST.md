# Milestone 1.3 Testing Checklist — Summon & Field

> **The live checklist is the interactive Milestone 1.3 Ledger (pass/fail/skip + notes, progress bar, report builder, marks persist):**
> **https://claude.ai/code/artifact/0bedc535-d67c-4bde-aca2-837f6fe5d767**
> This file is the plain-text mirror kept in the repo for the permanent record.

**Written for:** anyone — no developer knowledge needed.
**What you need:** the 1.3 build, at least one horse owned (from 1.2), a MySQL tool, ~15 minutes, and a willingness to kill a horse for science.
**What to send back to Claude:** the generated report + any red F8 lines.

**Note:** the `H` / `E` key defaults only bind after a full **client** restart (a RedM quirk). The commands work immediately regardless.

## 1. Boot & health

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy 1.3, `restart sovereign_stables` | no red errors | |
| B2 | `/stables_diag` | dependencies OK, Database OK, no config problems | |
| B3 | **Required:** run `sql/upgrades.sql` in MySQL (adds the new `sex` column) | runs clean; "Duplicate column name 'sex'" = you already have it, ignore | |

## 1b. Name & gender at purchase (N8 · N9 — the 1.2b addendum)

| # | Check | Expect | Result |
|---|---|---|---|
| N1 | Storefront → pick a horse → **Request Purchase** | a form: **Name** (pre-filled with the breed's name) + **Gender** (Stallion/Mare, pre-picked from the catalog card) | |
| N2 | Clear the name → **Confirm Purchase** | refused; box outlines red; nothing bought, no money moves | |
| N3 | Type your own name, pick a gender → **Confirm Purchase** | green card using **your** name | |
| N4 | MySQL: `sovereign_horses` | the `name` and `sex` you chose — not the catalog's | |
| N5 | My Horses → select that horse | your name + the gender **you** picked in the right panel | |
| N6 | Try a silly name (tags, symbols, 60 chars) | cleaned and cut to 24 chars — never stored raw | |

## 2. Whistle her up (D1 · D2 · S6)

| # | Check | Expect | Result |
|---|---|---|---|
| W1 | Away from a stable: `/sovwhistle` (or `H`) | your **default** horse appears behind you, trots over, name above it, visible and on the ground | |
| W2 | Mount and ride | rides normally — it's your mount, not a wild ped | |
| W3 | Whistle again while it's already out | it comes to you; does **not** spawn a second horse | |
| W4 | Whistle owning no horse | "You keep no horse."; nothing spawns | |

## 3. Follow, stay, dismiss (D4 · D3)

| # | Check | Expect | Result |
|---|---|---|---|
| F1 | `/sovfollow` (or `E`) on foot | "Your horse will follow you."; it walks after you | |
| F2 | `/sovfollow` again | "Your horse holds its ground."; stops following | |
| F3 | `/sovdismiss` | "Your horse wanders off."; it disappears | |
| F4 | Whistle immediately after | "Give it a moment — Ns." (30s recall cooldown); works after it lapses | |
| F5 | `/sovdismiss` while mounted | "Step down first." — it won't vanish from under you | |

## 4. Bring out at the stable (S7)

| # | Check | Expect | Result |
|---|---|---|---|
| S1 | Valentine → storefront → My Horses → pick → **Bring Out** | shop closes; that horse (not necessarily your default) comes out | |

## 5. Stray & death (auto-recall · hard death)

| # | Check | Expect | Result |
|---|---|---|---|
| D1 | Leave the horse, go past ~200m on foot | it quietly reappears near you rather than being stranded | |
| D2 | Kill your horse | red card "<name> is badly hurt (75%)."; horse despawns | |
| D3 | MySQL: `long_term_hp` on that horse | dropped by 25 (100 → 75) — the hard-death toll | |
| D4 | Whistle right after the death | "Give it a moment — Ns." (120s dead cooldown) | |
| D5 | **Optional/destructive:** kill it until `long_term_hp` = 0 | "<name> is gone for good."; row **deleted** from `sovereign_horses`; `horse_lost` row in `sovereign_ledger` | |

## 6. Cleanup

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console for the session | no red Lua errors from `sovereign_stables` | |

## 7. What the results decide

- **W1–W3 pass** → the summon path is sound; 1.4 (wagons) reuses it wholesale.
- **W1 fails with an invisible/airborne horse** → the spawn pattern regressed (see `PHASE1_SPIKE_FINDINGS.md` — ground-snap + variation-init).
- **F4 / D4 fail (no cooldown)** → whistle-spam is possible; blocker for a live server.
- **D2/D3 fail** → hard-death bookkeeping is wrong. **D5 is the serious one**: a horse must be permanently lost at 0 and never leave an orphan row.
- **D1 fail** → horses get stranded across the map; annoying but not a blocker.

## 8. Sign-off

Milestone 1.3 passes when your default horse answers a whistle, rides, follows/stays, dismisses with a cooldown that actually holds, can be collected at a stable, recovers when strayed, and death costs it long-term health (permanently at 0). Then **1.4 (wagons · tack · transfer)** — the last milestone to vorp_stables parity.

---

## Test log

_(Owner convention: a ledger line ticked without notes = confirmed working.)_

### Round 1 — (pending owner test)
