# Round 11 — Field & Wagon Consolidation

> **The live checklist is the interactive Round 11 Ledger:**
> **https://claude.ai/code/artifact/da643ab0-a715-4130-a4c7-3cac84cec0cc**
> This file is the plain-text mirror kept in the repo for the permanent record.
> R9: [18·4](MILESTONE_2.1_R9_CHECKLIST.md) · R10: [MILESTONE_2.1_R10_CHECKLIST.md](MILESTONE_2.1_R10_CHECKLIST.md) (folded in here)

**Written for:** anyone — no developer knowledge needed.
**What you need:** the current build, a horse, a wagon, a building with an interior, the Strawberry stable, ~30 minutes. **One client restart before you start (see F1).**

A lot landed in quick succession and none of it has been in game yet, so this is one consolidated pass. Headlines: **holding H works from login**, **whistled horses don't spawn indoors**, **you can get IN a wagon after buying it**, **R puts a parked wagon away**. Two natives (interior check, wagon-entry unlock) confirmed against the RDR3 database, never GTA V. The R10 dirt-layer question is carried at the end.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart`, `/stables_diag` | no new problems, no red errors | |

## Art. II — The whistle works from login *(the big one)*

Cause: RDR2's native whistle key is dead until the game has a registered horse (only after a stable fetch). A key mapping isn't gated. ⚠️ A key mapping's default binding sometimes needs one client restart to attach — see F1.

| # | Check | Expect | Result |
|---|---|---|---|
| F1 | ⚠️ ONE TIME: fully restart your **CLIENT** (not just the resource) after deploy, then log in | do this once so the H mapping attaches | |
| F2 | Log in fresh, **don't visit a stable**, stand in the open, **HOLD H** ~1s | your default horse comes out. **The whole point** — no stable trip | |
| F3 | Dismiss (`/sovflee`), hold H again | it comes back | |
| F4 | **Tap** H briefly | short whistle — follow / stop following | |
| F5 | If H does nothing after the restart: Settings → Key Bindings → *'Whistle / recall your horse'* | note only if F2 failed; bind it and tell me | |
| F6 | Change default at a stable, relog, hold H | the NEW default comes — persists across relog | |

## Art. III — Horses don't spawn indoors *(no-spawn zones)*

| # | Check | Expect | Result |
|---|---|---|---|
| N1 | Outside in open country, hold H | horse ~4m in front, 'answers your whistle' — normal case unchanged | |
| N2 | **Inside** a building with an interior, hold H | horse does NOT appear on top of you — comes out outside, 'waits for you outside'. Walk out, it's there | |
| N3 | Within ~15m of a stable, hold H | comes out clear of the stable, not on the stablehand/rail | |
| N4 | **Judgement:** when relocated, is it somewhere sensible and reachable? | note it — the search ring is tunable | |

## Art. IV — You can get in the wagon *(was FAIL)*

Cause: a `CreateVehicle` wagon isn't automatically "considered by the player", so no ride prompt. Three RDR3-verified natives after spawn fix it.

| # | Check | Expect | Result |
|---|---|---|---|
| V1 | Buy/collect a wagon at a stable | appears at the yard, horses hitched | |
| V2 | Walk to the driver's bench, press enter | you **CLIMB IN**. The line that failed | |
| V3 | Drive it | drives, it's yours | |
| V4 | If STILL can't get in: `/sovwagonhp`, paste the *lockStatus=.. hasNetControl=..* line | only if V2 failed — tells me the next native | |

## Art. V — Park it, press R *(new)*

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | Drive the wagon onto its stable's spawn point | a **'Put Away Wagon'** prompt on **R** appears | |
| R2 | Press R | stabled; if seated, you step down first | |
| R3 | Drive well away, check for the prompt | no R prompt in the field — only at the spawn point | |
| R4 | Note: right after buying, the wagon is AT the spawn point, so R shows at once | intended — put it straight back without driving | |

## Art. VI — Strawberry Stables *(your captured coords)*

| # | Check | Expect | Result |
|---|---|---|---|
| S1 | Approach the stablehand at Strawberry | 'Speak with the Stablehand' opens the storefront | |
| S2 | Browse a horse and a wagon | showroom models on clear ground, not clipping buildings/fence | |
| S3 | Collect a WAGON here | arrives at the spawn point on clear ground. **Tell me if it clips anything** | |

## Art. VII — The dirt-layer question *(carried from R10, still open)*

| # | Check | Expect | Result |
|---|---|---|---|
| D1 | Brush clean, `/sovdirtset 100`, LOOK | does it go visibly FILTHY? F8 prints *composite=__ base=__* | |
| D2 | **One line:** when filthy, which number was high — composite, base, both, neither? | decides whether dirt can build faster or the engine's rate is fixed | |
| D3 | `/sovdirtset 0` | clean | |

## Art. VIII — Regression & R10 carry-overs

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | Give Water at water, thirsty horse | drinks, thirst fills, **no chip** (R10). 'Not thirsty' chip still shows on a full horse | |
| G2 | Ride hard a few minutes, clean horse | gets dirty on its own — R9 win | |
| G3 | Brush from satchel | cleans after animation, no chip | |
| G4 | Teleport away from out-horse | despawns (not dragged). Ride 300m instead → recalls near you | |
| G5 | Lead (E), walk, Stop Leading | rope in hand, instant release | |
| G6 | F8 console all session | no red Lua errors | |

## Art. IX — The gate

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | If II, IV, V pass, the field/wagon loop is whole: whistle from login, get in your wagon, put it away | note | |
| X2 | Still open: the dirt RATE (Art. VII), and the un-removable vanilla Brush/Feed entries | note only | |
| X3 | Next: milestone 2.2, the death rework | note only | |
