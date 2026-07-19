# Milestone 2.1 Testing Checklist — The Care Loop

> **The live checklist is the interactive Milestone 2.1 Ledger (pass/fail/skip + notes, progress bar, report builder, marks persist):**
> **https://claude.ai/code/artifact/865820ad-0f0e-4dcb-8329-51772b3779a1**
> This file is the plain-text mirror kept in the repo for the permanent record.

**Written for:** anyone — no developer knowledge needed.
**What you need:** the 2.1 build, a horse you own, some feed/water/brush items in your satchel, a MySQL tool, ~20 minutes.
**What to send back to Claude:** the generated report + any red F8 lines.

**First milestone of Phase 2.** A horse now gets hungry, thirsty and dirty as you ride, and you feed/water/clean it back. Time is *lazy* — nothing ticks every second; values recompute from elapsed wall-clock time when a horse comes out.

**Two setup notes:**
1. The feed items in `config/metabolism.lua` are **placeholder names** — rename them to items that exist in your vorp_inventory, or add those items.
2. To watch drain without waiting hours, temporarily raise `drainPerMinute` (and lower `stableAutoCleanMinutes` / `goldenAfterMinutes`) in the config.

## Art. I — Boot & health

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy 2.1, `restart sovereign_stables` | no red errors; F8 shows *metabolism: usable feed/clean items registered* | |
| B2 | `/stables_diag` | dependencies OK, Database OK, no config problems | |
| B3 | **Setup:** set the six `items` names in `config/metabolism.lua` to feeds you have (or add them). Restart | those items exist in your satchel; note which names you used | |

## Art. II — It comes out fed & clean (C · L9)

| # | Check | Expect | Result |
|---|---|---|---|
| S1 | Whistle horse out → `/sovcare` | card: Hunger/Thirst ~100%, Dirt near 0 (F8 prints exact) | |
| S2 | Storefront → look at the preview horse | spotless always, even if your real horse is filthy [L9] | |

## Art. III — Feed, water, clean (H3 · H5)

| # | Check | Expect | Result |
|---|---|---|---|
| F1 | Ride a while (or raise drainPerMinute) → `/sovcare` | hunger/thirst dropped, dirt risen | |
| F2 | Use a feed item from the satchel (or `/sovfeed <item>`) | "… given.", item consumed, `/sovcare` shows hunger up | |
| F3 | Try to feed an item you don't have | "You have no …", nothing changes | |
| F4 | Use a water item, then a grooming brush | thirst rises; dirt → 0, coat visibly cleans | |
| F5 | MySQL: `metabolism` column on that horse | small JSON blob with current hunger/thirst/dirt — what persists | |

## Art. IV — A neglected horse (H1 penalties)

| # | Check | Expect | Result |
|---|---|---|---|
| P1 | Let a core fall below warn (35%) | Tick: "Your horse is getting hungry/thirsty." | |
| P2 | Below critical (15%) and ride | noticeably slower (move-rate throttle). **Not frozen** | |
| P3 | Feed/water back above critical | normal speed returns immediately | |

## Art. V — The stable grooms it (H10 · L6)

| # | Check | Expect | Result |
|---|---|---|---|
| C1 | Get it dirty, store it a few minutes (lower `stableAutoCleanMinutes` to test fast) | bring it out cleaner — groomed while stored [H10] | |
| C2 | Ride a clean horse a while | slowly gets dirtier [L6] — visible on coat + `/sovcare` | |

## Art. VI — Golden condition (C)

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | Keep hunger AND thirst above 80% for the golden timer (lower `goldenAfterMinutes` to test) | `/sovcare` shows **GOLDEN** + a gold card | |
| G2 | While golden, watch drain | hunger/thirst fall ~half as fast | |
| G3 | Let a core drop below 80% | golden lost | |

## Art. VII — It persists

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | Note values → `restart sovereign_stables` → whistle out → `/sovcare` | same values (+ a little stored drift), **not reset to full** | |
| R2 | Leave a dirty horse stored across the restart | keeps cleaning on the stable timer across restart — wall-clock, not uptime | |

## Art. VIII — Cleanup

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console for the whole session | no red Lua errors; paste anything red | |
| X2 | **Carried from Phase 1 (reminder, not a 2.1 test):** two-player transfer (`/sovgive`, `/sovgivewagon` + guards) never run in a duo session | note only — flag for the next duo session | |
