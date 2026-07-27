# Milestone 2.1 · Round 5 — One Menu, Real Dirt, and Leaving

> **The live checklist is the interactive Round 5 Ledger:**
> **https://claude.ai/code/artifact/f5170d40-4a09-43ec-b0e8-fb8871335aa1**
> This file is the plain-text mirror kept in the repo for the permanent record.
> R1: [20/2](MILESTONE_2.1_CHECKLIST.md) · R2: [19/4](MILESTONE_2.1_R2_CHECKLIST.md) · R3: [40/3](MILESTONE_2.1_R3_CHECKLIST.md) · R4: [35/1](MILESTONE_2.1_R4_CHECKLIST.md)

**Written for:** anyone — no developer knowledge needed.
**What you need:** the current build, a horse, a brush, feed, a river or trough, rain if it obliges, ~30 minutes. **Art. V needs a second player**; everything else is solo.
**Setup:** nothing to install. No SQL.

Round 4 went **35 pass · 1 fail**, and that one fail was worth more than the number suggests.

**You were looking at RDR2's own menu.** Brush, Feed, Pat and Flee are vanilla lock-on prompts, permanently greyed on a RedM server because nothing implements them — so our live prompts sat beside a dead native menu and Lead read as being outside it. Ours now replaces it.

**The dirt complaint was my own fix biting.** Until the dirt guard landed, horses looked dirty because the *engine* painted grime on them and our number barely mattered. The guard stopped that — which is what keeps a brushed horse brushed — and left one config value carrying a job it was never tuned for.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart sovereign_stables`, `/stables_diag` | no new problems. A thirst warning is still correct if you have no water item — horses drink from rivers, so an item is optional | |
| B2 | Horse out, `/sovcare` | `hunger= thirst= dirt= shows=`. `shows=` tells "brush failed" apart from "brush worked, dirt below the visible threshold" | |

## Art. II — One menu *(L1 — was FAIL)*

| # | Check | Expect | Result |
|---|---|---|---|
| M1 | Near the horse, **don't** right-click | **name only**, and **no Lead prompt** — the specific complaint | |
| M2 | Within **2m**, hold right-click | ONE list: **G** Lead, **H** Brush, **R** Feed, **E** Pat, **F** Send It Home, plus Hunger/Thirst | |
| M3 | **H** — Brush It, carrying a brush | animation, horse cleans, label reads **Brush It (Horse Brush)** so you know what it spends | |
| M4 | Use up / drop the brush, reopen | **no Brush prompt at all.** An option not offered is one you genuinely can't do — the greyed mystery was the complaint | |
| M5 | **R** — Feed It, away from water, carrying food | animation, hunger up, label names the item | |
| M6 | Stand the horse **at water**, reopen | same R key reads **Let It Drink**. Free water beats spending an item — it won't burn an apple beside a river | |
| M7 | **E** — Pat It | notification + settled horse. ⚠️ **the animation may not play** — no documented patting interaction exists; the name is the one unverified guess in the file. **Say which happened** | |
| M8 | **F** — Send It Home | walks off and goes home, same as `/sovflee` | |
| M9 | Start leading (G), look at the menu | **Pat disappears, Stop Leading appears** — they share E and are never both shown. Stop Leading stays visible with the menu closed | |
| M10 | **Judgement:** is the native greyed menu still there beside ours? | **Note honestly.** I have *not* claimed this is fixed — see Art. VI. If it's already gone, Art. VI is unnecessary | |

## Art. III — Dirt, retuned *(your note)*

Was 1.5/min behind a 25-point invisible band — a 17-minute blackout. Now 6.0/min behind 15.

| # | Check | Expect | Result |
|---|---|---|---|
| D1 | Brush spotless, ride normally **~3 min** | dirt starting to show (~2½ min to threshold) | |
| D2 | Ride on to **~15 min** | properly dirty. **Judgement — does the pace feel right?** Both numbers are one-line config | |
| D3 | Brush spotless, ride out of town **1 min** | **still looks freshly brushed** — your original ruling, and it has to survive the faster rate | |
| D4 | `/sovdirty` | instantly filthy. No more 15-minute rides to test the brush | |
| D5 | `/sovdirty 30` on a horse already at 100 | **refused**, pointing at the brush. Increase-only — a test command that cleans is a free brush anyone can type | |
| D6 | **THE OPEN QUESTION.** `/sovdirty 25`, look. Then 40, 60, 80, 100, looking between each | **I don't know, and this settles it.** Our number is continuous; whether RDR3 *renders* it that way we've never measured. The Phase 1 spike found `TF_HORSE_DIRTY`/`TF_HORSE_FILTHY`, hinting at **two visible tiers**. **Does it change at every step, or jump once or twice?** | |

## Art. IV — The brush, three doors *(refactor risk)*

The menu path would have consumed a whole brush where the satchel path counts uses down — the same action wearing out at two rates depending on where you clicked. All three routes now share one routine.

| # | Check | Expect | Result |
|---|---|---|---|
| U1 | Note remaining uses, brush **from the menu** (H) | down by **one**, not consumed | |
| U2 | Brush **from the satchel** | down by one — same rate | |
| U3 | `/sovfeed <brush item>` | down by one. Three doors, one rate | |
| U4 | Run a brush to **zero** | "wore out" and leaves the satchel, whichever door you used last | |
| U5 | Feed a one-shot item, satchel and menu | consumed once each, hunger up | |

## Art. V — Leaving takes your horse *(NEEDS TWO PLAYERS)*

⚠️ **Cannot be tested alone.** Horses are client-created; when you disconnect your own entities go with you regardless. The bug only appears when someone *else* is nearby — RedM migrates ownership to another player and the horse stays in the world riderless.

| # | Check | Expect | Result |
|---|---|---|---|
| P1 | You bring a horse out; a second player stands within sight | setup — close enough that it renders on their machine | |
| P2 | **You disconnect** (quit to desktop). They watch the horse | **vanishes** within a couple of seconds | |
| P3 | Reconnect and whistle | comes out normally, care values intact — cleanup removes the animal, not the record | |
| P4 | Second player brings THEIR horse out near yours; you dismiss yours | **only yours goes.** Net ids are recycled, so the server verifies the entity is still your horse first — deleting someone else's is far worse than leaving a stray | |
| P5 | **Skip-if-alone** | mark SKIP. **Do not mark PASS from a solo test** — it passes whether or not the fix works, which is worse than no test | |

## Art. VI — The prompt probe *(skip if M10 says the native menu is gone)*

Killing RDR2's greyed prompts needs a prompt-TYPE number, and no public table exists. This finds it by experiment — the way your health probe settled the wagon natives after I guessed wrong three times.

| # | Check | Expect | Result |
|---|---|---|---|
| V1 | `/sovpromptprobe 12`, lock on to your horse | something disappears, or nothing. **Report which** — 12 is the one number a forum thread suggested | |
| V2 | Try `3`, `5`, `8`, `14`, `17` | **note any that kill the greyed horse prompts** — and any that break something you need | |
| V3 | `/sovpromptprobe 0` | probing stops, everything normal | |
| V4 | **Give me the number(s)** | they go into `Config.UI.horseMenu.suppressPromptTypes` and the greyed menu is gone for good | |

## Art. VII — Regression

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | `/sovdirty`, then **rain** a couple of minutes | washes clean, coat shines. Rain must still beat the faster dirt rate | |
| G2 | `/sovdirty`, stand in a **river** a minute | rinses to the water floor, no further | |
| G3 | Low-thirst horse at a **trough**, wait, **don't** touch the menu | drinks by itself, thirst climbs. ⚠️ **silently dead until 2026-07-27** — a background thread called a function I'd renamed | |
| G4 | Store a dirty horse several minutes, bring it back | stablehand groomed it | |
| G5 | Storefront **preview** horse | still spotless — shares the cleaning code, most likely thing broken | |
| G6 | Storefront → Stock Horses | button reads **Purchase**, not "Request Purchase" | |
| G7 | `restart sovereign_stables`, whistle, `/sovcare` | values persisted | |

## Art. VIII — Cleanup & the gate

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console all session | no red Lua errors. Paste anything red | |
| X2 | **Phase 1 is signed off** — the transfer caveat carried across four ledgers is retired | Note only. Off the list for good | |
| X3 | **If this passes, 2.1 closes.** Next is the **death rework** — the 1.3 cumulative-toll model is still live, still docking 25 HP a death | Note only. It lands as a swap; two death systems can't coexist | |
