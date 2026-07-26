# Milestone 2.1 · Round 3 — Animations, Mud & the Info Panel

> **The live checklist is the interactive Round 3 Ledger:**
> **https://claude.ai/code/artifact/4a6ecd19-68fe-497f-9c05-debf2b9ecb82**
> This file is the plain-text mirror kept in the repo for the permanent record.
> Round 1: [20 pass · 2 fail](MILESTONE_2.1_CHECKLIST.md) · Round 2: [19 pass · 4 fail](MILESTONE_2.1_R2_CHECKLIST.md)

**The contorted rider was my fault twice over** — I hand-played animation clips that our own notes say must never be hand-played, after writing that warning into the same file. The engine's interaction system picks the right animation for where you're stood; it now does the choosing.

**"Unable to feed" had a real cause:** there is no water item in your config, so thirst was unrecoverable. `/stables_diag` now says so at boot.

Also in this round: **mud**, the **brush usable both ways**, and the **right-click info panel**.

## Art. I — Boot & the water problem (R6 — was FAIL)

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, restart, run `/stables_diag` | it now **reports** the thirst problem — *"the best thirst item restores 10, but thirst drains 1.0/min — only 10 minutes per use"*. That warning is correct | |
| B2 | In `config/metabolism.lua`, set the commented water items to a water item in **your** inventory. Restart | `/stables_diag` stops warning about thirst | |
| B3 | Use that water item on your horse | thirst goes up. **This is the line that failed last round** | |

## Art. II — The animations (R3 · A1 · A2 — were FAIL)

*You saw the rider contort 90° into the horse. I played the clips by hand; they're **synced** interaction clips, and our own PHASE1 notes warn they contort a ped when played raw (it wrecked the stablehand in 1.1). The engine's interaction system exists to pick and sync them, and now does.*

| # | Check | Expect | Result |
|---|---|---|---|
| A1 | **Mounted:** `/sovanim brush` | proper brushing from the saddle. **No contorting, no 90° twist** | |
| A2 | **Mounted:** `/sovanim feed` | proper mounted feeding animation | |
| A3 | **On foot:** `/sovanim brush` and `/sovanim feed` | still perfect — confirming I haven't broken what worked | |
| A4 | Do both for real, mounted and on foot | animation plays as part of the action, values move. **If mounted still looks wrong, say exactly how** — fallback is `careAnimations = false` | |

## Art. III — The brush, both ways (your request)

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | **On foot**, use the brush on a dirty horse | works now (last round correctly refused) | |
| R2 | **Mounted**, use it again | also works — both valid | |
| R3 | Check it still wears out | uses count down, removed at zero | |

## Art. IV — Mud (your request)

> ⚠️ RDR3 gives us **no** way to ask "am I standing in mud" — no ground-material or dirt read, only the write. So dirt speeds up from what we *can* read: water, rain, hard riding. **Judge it on whether it feels right.**

| # | Check | Expect | Result |
|---|---|---|---|
| M1 | Ride through a river/shallows a minute, check the coat | noticeably dirtier than dry ground — water counts **3×** | |
| M2 | Gallop across country a minute | dirtier than walking — **1.5×** | |
| M3 | If you can catch rain, ride in it | dirtier again — **2×**, stacking to a **4× cap**. Skip if weather won't oblige | |
| M4 | **Judgement:** does the rate feel right? | note it — every multiplier is a config number (`cleanliness.mud`) | |

## Art. V — The info panel (your request — NEW)

*Built as **the** horse readout — Phase 3's courage ruling says it's shown this same way, so it drops into this panel later.*

| # | Check | Expect | Result |
|---|---|---|---|
| I1 | Stand within a few metres, **hold RIGHT-CLICK** | panel at screen left: name, then Hunger, Thirst, Stamina, Health, Coat as bars | |
| I2 | Release right-click | disappears. It's a glance, not a screen | |
| I3 | **Mount up**, hold right-click | same panel, readable from the saddle, riding uninterrupted | |
| I4 | Gallop until tired, check Stamina | drops as it tires, recovers as it rests — the **live** core | |
| I5 | Let a core go low; get the horse filthy | low bars amber then oxblood. **Coat reads as cleanliness** (100% = spotless) so fuller is always better | |
| I6 | Walk well away, hold right-click | nothing — must be near (6m) or on it | |
| I7 | **Judgement:** position and size | note it — `Config.UI.horseInfo` has x, y, width | |

## Art. VI — Regression

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | Feed a normal (non-tool) item | consumed, hunger up — unchanged | |
| G2 | Storefront preview horses | still spotless, as fixed in round 2 | |
| G3 | `/sovflee` and the F-key flee | both still send the horse home | |
| G4 | Restart, whistle out, check the panel | values persisted | |

## Art. VII — Cleanup

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console all session | no red Lua errors; paste anything red | |
| X2 | **Noted, not tested:** previewing/customising components on your own horse *before* buying is **milestone 2.3** (the customiser) — written into the coding plan as the required shape, not a browse-then-buy list | note only | |
| X3 | **Still carried:** the two-player transfer tests from Phase 1 | note only | |
