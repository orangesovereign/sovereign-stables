# Milestone 2.1 · Round 9 — The Dirt Native Was Never Real

> **The live checklist is the interactive Round 9 Ledger:**
> **https://claude.ai/code/artifact/314f119e-e06d-4518-85a9-3639c5545948**
> This file is the plain-text mirror kept in the repo for the permanent record.
> R1: [20·2](MILESTONE_2.1_CHECKLIST.md) · R2: [19·4](MILESTONE_2.1_R2_CHECKLIST.md) · R3: [40·3](MILESTONE_2.1_R3_CHECKLIST.md) · R4: [35·1](MILESTONE_2.1_R4_CHECKLIST.md) · R5: [18·17](MILESTONE_2.1_R5_CHECKLIST.md) · R6: [29·3](MILESTONE_2.1_R6_CHECKLIST.md) · R7: [9·5](MILESTONE_2.1_R7_CHECKLIST.md) · R8: [MILESTONE_2.1_R8_CHECKLIST.md](MILESTONE_2.1_R8_CHECKLIST.md)

**Written for:** anyone — no developer knowledge needed.
**What you need:** the current build, a horse, a brush, feed, open country to ride, ~20 minutes.

You said it plainly: **"when we started it was getting too dirty too quick and now its not getting dirty at all."** That was the whole answer, and it sent me to read every dirt native in the RDR2/RedM database.

The finding is stark: **the "set dirt" native we've called for six rounds is a GTA V native that doesn't exist in RedM — every call did nothing.** The horse got dirty from the ENGINE the whole time, and the only real thing in our code was a CLEAN that ran every two seconds and scrubbed the engine's mud straight off. It's all rebuilt on the REAL natives now: the engine dirties the horse, and we just read the level and remember it.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart`, `/stables_diag` | no new problems, no red errors | |
| B2 | Horse out, `/sovcare` | a line `hunger= thirst= dirt= engine=`. The new `engine=` is the game's own reported dirt — its existence is the proof we can READ dirt now | |

## Art. II — The engine dirties the horse *(the whole point)*

| # | Check | Expect | Result |
|---|---|---|---|
| D1 | Brush clean, then **ride hard 3–5 min** through dirt/brush/a ford | it gets visibly DIRTY on its own. **This is the milestone** — the thing broken for six rounds | |
| D2 | `/sovcare` a couple of times while riding | `dirt=` and `engine=` both climb and track within a few points | |
| D3 | Ride through **rain** a couple of minutes | the engine washes it cleaner on its own, `engine=` falls. **Skip if no rain** | |
| D4 | **Judgement call:** is the natural rate right — not the too-fast of the start, not the never since? | note it — it's the engine's own pace | |

## Art. III — The direct proof *(set and read back)*

| # | Check | Expect | Result |
|---|---|---|---|
| S1 | `/sovdirtset 100` | horse goes filthy; F8 prints *set 100% -> engine reads ~100%*. The matching read-back is the proof | |
| S2 | `/sovdirtset 50`, then `/sovdirtset 25` | visibly less dirty each time, read-back follows. A real settable range | |
| S3 | `/sovdirtset 0` | spotless. Clean always worked — it was the only real native we had | |

## Art. IV — Brushing still grooms

| # | Check | Expect | Result |
|---|---|---|---|
| C1 | Dirty a horse (ride or `/sovdirtset 80`), brush from satchel, watch coat | stays dirty through the animation, cleans as it finishes, no chip | |
| C2 | Feed from satchel | hunger up, no chip | |
| C3 | Brush to last use | wear-out chip still shows — that's the ITEM | |

## Art. V — Dirt remembers *(persistence)*

| # | Check | Expect | Result |
|---|---|---|---|
| P1 | Dirty a horse, dismiss it, wait, whistle it back | comes back about as dirty as it left | |
| P2 | Dirty a horse, **store at a stable**, leave a while, take out | stablehand groomed it cleaner | |
| P3 | Dirty a horse, `restart sovereign_stables`, whistle out, `/sovcare` | dirt survived the restart — it's in the database now | |

## Art. VI — The rest still works

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | Lock on, **Give Water** at a trough/river, thirsty horse | drinks, thirst fills — unchanged | |
| G2 | Storefront preview horse | spotless. Uses the same real natives now — most likely to have broken, look closely | |
| G3 | Lead (E), walk, Stop Leading; then teleport away | lead instant, horse despawns on teleport | |
| G4 | F8 console all session | no red Lua errors | |

## Art. VII — The gate

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | **If Art. II passes — the horse gets dirty by itself — 2.1 is essentially done.** The one thing left is the vanilla Brush/Feed entries the engine won't let us remove (R8 Art. V) — cosmetic, not a gate | **your call** | |
| X2 | **Next up:** milestone 2.2, the death rework | note only | |
| X3 | **Parked for Phase 3:** horse BONDING (native 0–4 bond levels) as a trainer-gated service, alongside courage | note only | |
