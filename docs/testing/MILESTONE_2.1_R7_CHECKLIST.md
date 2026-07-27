# Milestone 2.1 · Round 7 — Watering by Choice & Two Honest Probes

> **The live checklist is the interactive Round 7 Ledger:**
> **https://claude.ai/code/artifact/8069d5ab-8b35-4583-9622-ff8ec2dab0e2**
> This file is the plain-text mirror kept in the repo for the permanent record.
> R1: [20·2](MILESTONE_2.1_CHECKLIST.md) · R2: [19·4](MILESTONE_2.1_R2_CHECKLIST.md) · R3: [40·3](MILESTONE_2.1_R3_CHECKLIST.md) · R4: [35·1](MILESTONE_2.1_R4_CHECKLIST.md) · R5: [18·17](MILESTONE_2.1_R5_CHECKLIST.md) · R6: [29·3](MILESTONE_2.1_R6_CHECKLIST.md)

**Written for:** anyone — no developer knowledge needed.
**What you need:** the current build, a horse, a brush, feed, a trough and a river, ~20 minutes.

Round 6 went **29 pass · 3 fail** and the menu finally sits where it belongs. This round is small on purpose.

**Watering is now a choice** — Give Water is in the lock-on menu, and a full horse tells you so by name. **Brushing is silent** and **Stop Leading is instant**. The honest headline is the dirt probe: R6 said "none of the five natives work," and **that test was rigged against itself** — our own coat guard was scrubbing the horse clean twice a second while you probed, so every candidate dirtied the horse and was wiped before you could look. The probe now switches the guard off first.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart`, `/stables_diag` | no new problems | |
| B2 | Horse out, `/sovcare` | reads `hunger= thirst= dirt=` | |

## Art. II — Watering is a choice now *(W1 — your ruling)*

The automatic sip-every-few-seconds is deleted — **that** was the drinking-by-itself.

| # | Check | Expect | Result |
|---|---|---|---|
| A1 | **Thirsty** horse at a trough/river, lock on, look for **Give Water** | there. Take it — thirst fills in one go | |
| A2 | Thirsty horse **away from water**, lock on | **no Give Water** — offered only where a drink is possible | |
| A3 | Water a horse that's **already full** | the chip: *"[name] is not thirsty."* Nothing else | |
| A4 | Water, then immediately try again | short cooldown: *"[name] has had enough for now."* A normal drink is never blocked | |
| A5 | Stand at water and **don't touch the menu** | thirst does NOT climb by itself. **The behaviour you asked to remove** | |
| A6 | **Judgement call:** should watering play a drinking animation? | none now (you said self-drinking anim would be a fail). Want a SHORT one on the deliberate press? Say so | |

## Art. III — Quieter *(F4·M5 — your rulings)*

| # | Check | Expect | Result |
|---|---|---|---|
| Q1 | Brush from the satchel | coat cleans, **no chip** | |
| Q2 | Feed from the satchel | STILL a chip — a fed horse looks no different, so confirmation stays. Only brushing went silent | |
| Q3 | Lead (G), then **Stop Leading** | rope drops instantly, standing normally, no message | |
| Q4 | Lead, walk out of range, Stop Leading from a distance | same — instant | |

## Art. IV — The dirt probe, done right *(D1–D6 — the R6 test was RIGGED)*

⚠️ R6 D3's "none" was worthless and it was my fault: the coat guard scrubs the horse spotless twice a second, so every candidate dirtied the horse and was wiped within half a second. The probe now **switches the guard off** and holds the dirty value ~6s.

| # | Check | Expect | Result |
|---|---|---|---|
| D1 | `/sovdirtprobe` no number | F8 lists five candidates, notes guard suspended while probing | |
| D2 | `/sovdirtprobe 3` — **SET_PED_DIRT_LEVEL 100.0**, watch 6s | **THE KEY LINE.** The proven clean-native run the other way. **Does it look filthy now?** I expect yes with the guard out of the way | |
| D3 | If 3 did nothing, try 1, 2, 4, 5 the same way | which number, if any, makes it visibly dirty? "Still none even with the guard off" is now a REAL answer | |
| D4 | `/sovdirtprobe off`, then brush | guard back, brush cleans it. Confirms nothing stuck on | |
| D5 | For whichever worked: does `/sovcare` `dirt=` still climb as you ride? | it always did (R6 D5). If the coat now MATCHES the number, dirt is done and I wire this native into the guard | |

## Art. V — The prompt probe, per frame this time *(M1·F1 — vanilla Brush/Feed)*

The only tool — `UiPromptDisablePromptTypeThisFrame` — must be called **every frame**; R5 called it once and saw nothing. ⚠️ Type 12 is the mount prompt, so the sweep will briefly kill mounting as it passes 12 — that's the probe working.

| # | Check | Expect | Result |
|---|---|---|---|
| P1 | Lock on, note entries: Show Info, Brush, Feed, Pat | baseline | |
| P2 | `/sovpromptprobe sweep`, lock on, watch the list as numbers climb (F8 prints each) | **watch for the frame Brush vanishes, and Feed vanishes.** Note the number in F8 | |
| P3 | Give me those two numbers, then `/sovpromptprobe off` | I pin the disable to exactly Brush and Feed, every frame — gone for good | |
| P4 | If the sweep removes nothing at any number | say so — also a real answer, means I find another route | |

## Art. VI — Regression

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | Horse in a river, take Give Water | thirst fills. Rivers and troughs both count | |
| G2 | Storefront preview horse | still spotless | |
| G3 | Feed from satchel; `restart`; whistle; `/sovcare` | values persisted | |
| G4 | Lead a horse, then teleport away | horse despawns (R6 T1), leading ends cleanly | |
| G5 | Brush to last use | wear-out chip still shows — that's about the ITEM, not brushing | |

## Art. VII — Cleanup & the gate

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console all session | no red Lua errors | |
| X2 | **The close question:** if Art. IV finds a working native, dirt rendering is DONE and 2.1 closes clean. If none even with the guard off, I'll propose closing 2.1 anyway and tracking visible-dirt separately, since the care loop all works | **your call after Art. IV** | |
| X3 | **Next up:** milestone 2.2, the death rework | note only | |
