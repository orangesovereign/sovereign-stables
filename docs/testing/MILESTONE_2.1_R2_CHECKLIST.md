# Milestone 2.1 · Round 2 — Care Loop Retest

> **The live checklist is the interactive Round 2 Ledger (pass/fail/skip + notes, progress bar, report builder, marks persist):**
> **https://claude.ai/code/artifact/66f49026-628f-4f07-9215-b05cafaeae26**
> This file is the plain-text mirror kept in the repo for the permanent record.
> Round 1: [MILESTONE_2.1_CHECKLIST.md](MILESTONE_2.1_CHECKLIST.md) — **20 pass · 2 fail**.

**A focused retest, not a re-run of all 22 lines.** It covers the two failures (S2 preview dirt, F4 the brush), your notes (brush respec, care animations), the flee bug, and a short regression pass.

**Two things worth knowing:**
1. The brush is now **horseback-only with 20 uses** — a tool, not a consumable.
2. **I was wrong last round** when I said RDR2 had no mounted brushing animation. It does — so you get both the saddle rule *and* the animation.

`/sovanim brush` plays an animation without spending a brush use.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart sovereign_stables` | no red errors; F8 shows *metabolism: usable feed/clean items registered* | |
| B2 | **Read, don't test:** brush is now a **20-use tool**, **horseback-only**. Each brush tracks its own uses in its own metadata | note only — confirm you have a `horsebrush` before Art. III | |

## Art. II — The preview is clean now (S2 — was FAIL)

*Round 1: "Horses still showing dirt." The clean was a one-shot, and RDR3 re-applies grime over the next few frames. It now re-runs the clear 8× over ~800ms, the way coal_stables does.*

| # | Check | Expect | Result |
|---|---|---|---|
| S1 | Get a horse filthy, then open the storefront and look at the preview | **spotless and stays spotless** — watch a few seconds, must not dirty back up [L9] | |
| S2 | Look at the stablehand's groomed horse | also clean — it's part of the showroom | |
| S3 | Cycle through several horses in the storefront | every one renders clean, no flicker of dirt on swap | |

## Art. III — The brush, respecced (F4 — was FAIL)

*Your spec: brush only (no water), 20 uses, horseback only, right animation. All four are in.*

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | **On foot**, try to use the horsebrush | refused — "You must be on the horse…" and **no use is spent** | |
| R2 | **Mounted**, use the brush on a dirty horse | works — horse visibly cleans, dirt reads 0 in `/sovcare` | |
| R3 | Watch the animation while brushing from the saddle | you lean over and brush — upper body only, ride uninterrupted. **If the rider contorts or T-poses, say so** and I'll flip `mountedAnimations` off | |
| R4 | Check the brush in your satchel after use | **still there**, *19 uses left* in its description | |
| R5 | **Wear one out** — use the same brush 20 times | exactly 20 uses, then "wore out" and it's **removed** — no dead 0-use brush | |
| R6 | Try a water/feed item on a dirty horse | hunger/thirst change, **dirt does not**. Brush is the only cleaner | |

## Art. IV — Care animations (F2 — your note)

*You asked for the appropriate animation both horseback and standing. RDR2 has both.*

| # | Check | Expect | Result |
|---|---|---|---|
| A1 | **Mounted:** `/sovanim brush` | mounted brushing animation; upper body, you keep riding | |
| A2 | **Mounted:** `/sovanim feed` | mounted feeding — and the **horse plays its half too** (paired animation) | |
| A3 | **On foot, near the horse:** `/sovanim feed` | character walks in and feeds — the engine's own interaction, positioning handled | |
| A4 | Feed for real (mounted, then on foot) | same animation plays as part of feeding; hunger goes up | |

## Art. V — Flee (D13 — reported broken)

*We build no horse menu, so "the flee option in the horse menu" is RDR2's own Flee command. It was never wired to anything.*

| # | Check | Expect | Result |
|---|---|---|---|
| D1 | With the horse out: `/sovflee` | turns, **walks** away, despawns once clear (~4s) — same as `/sovdismiss` | |
| D2 | In-game Flee: lock onto the horse, press **F** | same result. **If F does nothing, say so** — the control only reads inside the game's horse-command context, and I'll move it onto the interaction prompt | |
| D3 | Whistle for the horse again after fleeing | recall cooldown applies, then it returns normally | |

## Art. VI — Regression

*The care loop's guts are unchanged, but the item path was rewritten.*

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | `/sovcare` on the horse you have out | hunger/thirst/dirt still read correctly | |
| G2 | Feed a normal (non-tool) feed item | consumed as before, hunger up — durability changes must not have broken plain consumables | |
| G3 | Let a core go critical, then feed it back | sluggish while critical, normal after — unchanged | |
| G4 | Store a dirty horse a few minutes, bring it back | stable still grooms it [H10] | |
| G5 | `restart sovereign_stables`, whistle out, `/sovcare` | values persist, as in round 1 | |

## Art. VII — Cleanup

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console for the whole session | no red Lua errors; paste anything red | |
| X2 | **Still carried:** the two-player transfer tests (`/sovgive`, `/sovgivewagon` + guards) from Phase 1 have never been run in a duo session | note only — Phase 1 closed with this caveat outstanding | |
