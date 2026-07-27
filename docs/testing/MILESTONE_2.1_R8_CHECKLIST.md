# Milestone 2.1 · Round 8 — Give Water Works, and Two Honest Walls

> **The live checklist is the interactive Round 8 Ledger:**
> **https://claude.ai/code/artifact/8b2df66f-7ee6-428d-8a14-d2c3f0fd5b53**
> This file is the plain-text mirror kept in the repo for the permanent record.
> R1: [20·2](MILESTONE_2.1_CHECKLIST.md) · R2: [19·4](MILESTONE_2.1_R2_CHECKLIST.md) · R3: [40·3](MILESTONE_2.1_R3_CHECKLIST.md) · R4: [35·1](MILESTONE_2.1_R4_CHECKLIST.md) · R5: [18·17](MILESTONE_2.1_R5_CHECKLIST.md) · R6: [29·3](MILESTONE_2.1_R6_CHECKLIST.md) · R7: [9·5](MILESTONE_2.1_R7_CHECKLIST.md)

**Written for:** anyone — no developer knowledge needed.
**What you need:** the current build, a horse, a brush, feed, a trough/river, ~15 minutes.

Round 7 was **9 pass · 5 fail**, and the big miss was mine and simple: **Give Water never showed because I put it on the same key the vanilla Feed prompt already owns.** Two prompts, one key, one menu — the game keeps the native and drops ours. Moved to a free key; it should appear now. Brushing waits for its animation before the coat cleans, and feeding is silent.

**Two of last round's failures were the game saying no, clearly, twice** — the dirt native won't paint mud even unopposed, and the prompt-disable sweep removed nothing. Those aren't bugs; they're walls, and this round asks you to decide what we do at them.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart`, `/stables_diag` | no new problems | |

## Art. II — Give Water appears now *(A1·A2 — were FAIL)*

Control collision: it was on INTERACT_HORSE_FEED, the same control the vanilla Feed entry owns. Now on a free control (H), and shown whenever locked on — the water check moved to the press.

| # | Check | Expect | Result |
|---|---|---|---|
| A1 | Lock on, look for **Give Water** | there now, every time. **The fix** | |
| A2 | At a trough/river, Give Water on a thirsty horse | thirst fills, chip "takes a long drink" | |
| A3 | Give Water **away from water** | chip: "There is no water here for [name]." The option was still there; it told you why | |
| A4 | Water a **full** horse | "[name] is not thirsty." | |
| A5 | Stand at water, touch nothing | thirst doesn't move — only ever your choice | |
| A6 | **Judgement call:** is the **H key** right, or does it clash? | note it — one config line | |

## Art. III — Brush waits for the animation *(Q1·Q2 — your rulings)*

| # | Check | Expect | Result |
|---|---|---|---|
| C1 | Brush a dirty horse; **watch the coat during the animation** | stays dirty THROUGH it, cleans as it finishes. Not an instant snap | |
| C2 | Feed from the satchel | hunger climbs, **no chip** — silent like brushing | |
| C3 | **Judgement call:** is 4 seconds about right for the coat to clean? | note it — `brushAnimSeconds` | |

## Art. IV — The dirt wall *(D2·D3 — the engine says no)*

⚠️ **A decision, not a test.** With our cleaner off and the value held 6s, none of the five natives made a horse look dirty. The dirt native is one-way — it cleans (proven) but won't paint mud. The dirt NUMBER works (climbs, persists, brush lowers it; coat shows clean when brushed). Only the DIRTY look is unreachable.

| # | Check | Expect | Result |
|---|---|---|---|
| D1 | Ride a while, `/sovcare`, read `dirt=` | number climbed — bookkeeping whole, only the visual is denied | |
| D2 | **THE DECISION:** (a) ship the working number + clean-on-brush, track the dirty VISUAL separately; or (b) hold 2.1 open while I hunt a horse-specific mud native, no guarantee it exists | **tell me a or b.** Recommendation: **(a)** | |

## Art. V — The vanilla Brush/Feed wall *(P2 — the engine says no)*

⚠️ **Also a decision.** A per-frame sweep of every prompt type 0-40 removed nothing, so the prompt-disable native doesn't govern these. They can likely only be suppressed by a ped config flag I don't have a confirmed number for. They aren't harmful, only redundant beside item-based care.

| # | Check | Expect | Result |
|---|---|---|---|
| E1 | Lock on, confirm native **Brush**/**Feed** still appear | they will — baseline | |
| E2 | **THE DECISION:** (a) leave them (harmless); or (b) I add a config-flag probe next round to sweep for the flag that hides them, knowing it may not exist | **tell me a or b.** Recommendation: **(a)** unless they bother you in play | |

## Art. VI — Regression

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | Lead (E), walk, Stop Leading | instant, silent | |
| G2 | Storefront preview horse | spotless | |
| G3 | Feed; `restart`; whistle; `/sovcare` | persisted | |
| G4 | Brush to last use | wear-out chip still shows — that's the ITEM | |
| G5 | Teleport away from your out horse | despawns | |

## Art. VII — The gate

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console all session | no red Lua errors | |
| X2 | **If II and III pass and you chose (a) on both walls, 2.1 CLOSES.** The care loop — hunger, thirst, watering, brushing, drinking, persistence, teleport/disconnect cleanup — is done. Visible-dirt and native-prompt-removal become tracked items | **your call** | |
| X3 | **Next up:** milestone 2.2, the death rework | note only | |
