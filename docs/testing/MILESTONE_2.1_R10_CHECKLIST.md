# Milestone 2.1 · Round 10 — One Question About Two Layers

> **The live checklist is the interactive Round 10 Ledger:**
> **https://claude.ai/code/artifact/98191c5a-e06e-4362-b8cd-4354ac8692b0**
> This file is the plain-text mirror kept in the repo for the permanent record.
> R5: [18·17](MILESTONE_2.1_R5_CHECKLIST.md) · R6: [29·3](MILESTONE_2.1_R6_CHECKLIST.md) · R7: [9·5](MILESTONE_2.1_R7_CHECKLIST.md) · R8: [MILESTONE_2.1_R8_CHECKLIST.md](MILESTONE_2.1_R8_CHECKLIST.md) · R9: [18·4](MILESTONE_2.1_R9_CHECKLIST.md)

**Written for:** anyone — no developer knowledge needed.
**What you need:** the current build, a horse, a brush, a trough or river, ~10 minutes.

Round 9 went **18 pass · 4 fail**, and the headline WON: **the horse gets dirty on its own again.** Dirt accumulates, brushing cleans, and it all survives a restart. Of the four fails, one was a chip (removed) and three were the `/sovdirtset` readout — which told me something real: the clean moved the COAT, but the number I read never budged off 45. RDR3 keeps dirt in **two separate layers**, and I was reading the wrong one.

This round is short: confirm the two fixes, then run one probe and tell me a single thing — **which number matches what the horse actually looks like.** That one answer decides whether I can make dirt build faster the way you asked.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart`, `/stables_diag` | clean, no red errors | |

## Art. II — THE ONE QUESTION *(this is the whole round)*

R9 S1–S3: `/sovdirtset` cleaned the horse but the number read 45 no matter what. That's because RDR3 stores dirt in two layers and I was reading one while the coat shows the other. The probe now prints BOTH.

| # | Check | Expect | Result |
|---|---|---|---|
| Q1 | Clean horse out (brush first), then `/sovdirtset 100` | **LOOK AT THE HORSE.** Does it go visibly FILTHY? Yes/no. F8 prints *composite=__ base=__* | |
| Q2 | Read the F8 line | **Write down BOTH numbers** — composite and base — as printed | |
| Q3 | `/sovdirtset 0`, look again | does it go CLEAN? What does F8 print now? | |
| Q4 | **The answer I need in one line:** when the horse LOOKED filthy at 100, which number was high — composite, base, both, or neither? | that single fact tells me which layer is the coat, and whether I can push dirt up to accumulate faster | |

## Art. III — The drink chip is gone *(G1 — was FAIL)*

| # | Check | Expect | Result |
|---|---|---|---|
| W1 | Lock on to a thirsty horse at water, take **Give Water** | drinks, thirst fills, **NO chip** — just the animation | |
| W2 | Do it again immediately, or on a full horse | the 'not thirsty' / 'had enough' chip DOES still show — those are the no-op cases | |

## Art. IV — Still good from R9 *(quick regression)*

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | Ride hard a few minutes on a clean horse | gets dirty on its own — R9 headline, still true | |
| R2 | Brush from the satchel | cleans after the animation, no chip | |
| R3 | Dirty a horse, `restart`, whistle out | comes back dirty — persistence held | |

## Art. V — The gate

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | **2.1's care loop is done** — dirty/brush/feed/water/persist all pass. The only open thread is the dirt RATE (your 10–15%-faster + mud note), which Art. II decides. If writing the coat up works, I'll add the speed-up and mud bonus; if not, the engine's rate is what we have | **your call** whether to hold 2.1 open for the rate or close it and track the rate separately | |
| X2 | **Next:** milestone 2.2, the death rework | note only | |
