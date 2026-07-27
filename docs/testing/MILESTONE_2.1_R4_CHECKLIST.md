# Milestone 2.1 · Round 4 — Leading, the Brush & the Gated Menu

> **The live checklist is the interactive Round 4 Ledger:**
> **https://claude.ai/code/artifact/8cabbdf5-e77c-4df8-810d-e844f7cc7074**
> This file is the plain-text mirror kept in the repo for the permanent record.
> Round 1: [20 pass · 2 fail](MILESTONE_2.1_CHECKLIST.md) · Round 2: [19 pass · 4 fail](MILESTONE_2.1_R2_CHECKLIST.md) · Round 3: [40 pass · 3 fail](MILESTONE_2.1_R3_CHECKLIST.md)

**Written for:** anyone — no developer knowledge needed.
**What you need:** the current build, a horse, a brush, feed, a river or trough, rain if it obliges, ~25 minutes. A second player for Art. III L3 and the carried transfer tests.
**Setup:** nothing to install. No SQL.

Round 3 went **40 pass · 3 fail**.

**The brush is the headline.** R1/R2 have now failed three rounds running, and every time I checked the chain it was correct — item taken, server cleans the horse, card returns, coat set. The bug was never the logic: it was **how long we held the result**. Each fix re-asserted the clean coat for ~800ms while the brushing animation runs for *several seconds*, so the engine repainted environmental grime after our burst ended. The horse was genuinely clean for a moment nobody ever saw. Chasing that with a longer burst is the same bug with a bigger number, so the coat is now held continuously.

**And you were right about leading.** It was a horse following you, because that is literally what I built — I looked for a start-leading native, didn't find one, and settled. `TASK_LEAD_HORSE` exists; it is tasked on the **player**, not the horse, which is why searching horse tasks never turned it up.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart sovereign_stables`, `/stables_diag` | no new problems. A thirst warning is correct if you still have no water item | |
| B2 | Horse out, `/sovcare` | F8 reads `hunger= thirst= dirt= shows=` — **no golden**. `shows=` is the coat's rendered level vs the stored number: how you tell "brush failed" from "brush worked, dirt is below the visible threshold" | |

## Art. II — The brush *(R1 · R2 — FAILED THREE ROUNDS)*

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | Filthy horse, brush it **on foot**. Watch it *after* the animation ends | clean, and it **stays** clean. The staying is the point | |
| R2 | Filthy again, brush **mounted** | same — clean and stays clean | |
| R3 | `/sovcare` immediately after brushing | `dirt=0` and `shows=0.00`. **If the coat looks dirty but this reads 0.00, tell me** — that's a different bug from the one I fixed | |
| R4 | Brush a lightly dirty horse, then ride a few minutes | stays looking clean a good while. Engine grime can no longer add dirt behind our back — this is also the fix for "ride out of Valentine and see dirt" | |
| R5 | Brush wears out | uses count down, removed at zero (passed last round) | |

## Art. III — Leading a horse *(your correction — REBUILT)*

| # | Check | Expect | Result |
|---|---|---|---|
| L1 | At the horse, hold right-click, take **Lead Horse** (G) | the real thing — **rope in hand**, horse at your shoulder | |
| L2 | Walk around while leading | keeps station, lead holds. Note what breaks it | |
| L3 | **Have someone else watch you** lead past them | they see you leading it. **The line that matters** — the whole complaint was that leading was invisible to others. Skip if nobody else is on | |
| L4 | Press **E** (Stop Leading) | you let go, horse stops trailing, **you're standing normally** — not stuck in an animation | |
| L5 | Lead, then **mount up** without stopping first | no wedged state | |
| L6 | Lead to water, take **Let It Drink** (R) | drinking animation, thirst climbs, **reins go back in your hand** afterwards | |

## Art. IV — The gated menu *(I3 — was FAIL)*

| # | Check | Expect | Result |
|---|---|---|---|
| I1 | Walk near the horse, **don't** right-click | **name only**. No stats, **no Lead prompt**, no Drink prompt | |
| I2 | Within **2m**, hold right-click | menu opens beside the horse — Hunger, Thirst, and the actions | |
| I3 | Read the readout | Hunger and Thirst **only**. No Stamina, no GOLDEN | |
| I4 | Release and wait ~5s | closes itself. A tap latches ~5s; holding also works | |
| I5 | Stand **3–4m** away and hold right-click | **nothing**. 2m means 2m. This failed last round | |
| I6 | Open it, then walk away | closes immediately | |
| I7 | Mounted, hold right-click | nothing — as intended | |
| I8 | Start leading, close the menu | **Stop Leading stays visible.** Deliberate, the one exception — a state you can enter must be one you can leave | |

## Art. V — Golden, retired *(your ruling)*

Turned off, not deleted, so it can come back intact. ⚠️ Simply *skipping* the golden bookkeeping would have left every already-golden horse holding its 0.5× slower drain forever — a perk only players golden that week could ever have. Turning a feature off has to retire the state it created.

| # | Check | Expect | Result |
|---|---|---|---|
| C1 | Open the menu on a horse that **was** golden before this update | no GOLDEN anywhere. Skip if you can't identify one | |
| C2 | Keep a horse well fed and watered a long while | **never** turns golden. Background observation, not a sit-and-wait | |
| C3 | `/sovcare` on any horse | no golden in F8, none on the card | |

## Art. VI — Specialty stock *(C2 — carried note)*

Fixed in the build *after* the one you tested, so this is a confirm.

| # | Check | Expect | Result |
|---|---|---|---|
| S1 | Storefront → **Specialty Horses**, click one | **no purchase button at all** — a card saying *"Not sold over the counter — speak to the stable's trainer."* A button that always refuses is worse than no button | |
| S2 | **Stock Horses**, click one | normal purchase form. Only specialty is brokered | |
| S3 | If you can set yourself Horse Trainer (grade 0/1): open Specialty | a trainer *can* buy it — that's the point of brokering. Skip if the job is slow to set | |

## Art. VII — Regression

Dirt is now driven by a continuous guard, and that path is shared by rain, water, the stable groom and the storefront preview.

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | Filthy horse, sit in **rain** a couple of minutes | still washes clean, coat still shines. The guard must not fight the rain | |
| G2 | Filthy horse, stand in a **river** a minute | still rinses to the water floor and no further | |
| G3 | Store a dirty horse several minutes, bring it back | stablehand groomed it | |
| G4 | Storefront **preview** horse | still spotless — shares the cleaning code, most likely thing to have broken | |
| G5 | Feed an item; `restart sovereign_stables`, whistle out, `/sovcare` | values persisted | |
| G6 | `/sovflee` and in-game Flee | both still send the horse home | |

## Art. VIII — Cleanup & the gate

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console all session | no red Lua errors. Paste anything red | |
| X2 | **Still carried:** two-player transfer tests (`/sovgive`, `/sovgivewagon`, the guards) from Phase 1 have **never** run in a duo session | Note only. **Now the last thing blocking Phase 1 sign-off** | |
| X3 | **Noted, not tested:** previewing/customising components on your own horse *before* purchase is **milestone 2.3** | Note only | |
