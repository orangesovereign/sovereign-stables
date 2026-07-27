# Milestone 2.1 · Round 6 — Undoing the Second Menu

> **The live checklist is the interactive Round 6 Ledger:**
> **https://claude.ai/code/artifact/ca511cc1-7f98-42ac-be10-64db7c47309e**
> This file is the plain-text mirror kept in the repo for the permanent record.
> R1: [20·2](MILESTONE_2.1_CHECKLIST.md) · R2: [19·4](MILESTONE_2.1_R2_CHECKLIST.md) · R3: [40·3](MILESTONE_2.1_R3_CHECKLIST.md) · R4: [35·1](MILESTONE_2.1_R4_CHECKLIST.md) · R5: [18·17](MILESTONE_2.1_R5_CHECKLIST.md)

**Written for:** anyone — no developer knowledge needed.
**What you need:** the current build, a horse, a brush, feed, the Blackwater stable, a way to teleport, ~30 minutes.
**Setup:** nothing to install. No SQL.

Round 5 went **18 pass · 17 fail** — the worst round so far, and both headline failures were me building instead of looking.

**You said "in the same menu as Brush, Feed, Pat, Flee" and I built a menu containing those four things.** You meant the vanilla lock-on menu, which was live on your server the whole time. That is now torn out.

**Then I attached our Lead prompt to the horse's entity handle** and reasoned that "attached to the entity" meant "in the entity's list". It doesn't — an entity's prompt group has its own id and a native to fetch it. A group *numbered after* the entity is exactly what a second floating menu looks like.

**And dirt is invisible because I asserted it.** The guard that made brushing stick also stopped the engine painting its own grime, and the native I assumed replaces it does not appear to. Art. IV asks the game instead of me.

## Art. I — Boot

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy, `restart sovereign_stables`, `/stables_diag` | no new problems | |
| B2 | Horse out, `/sovcare` | still reads `hunger= thirst= dirt=`. `shows=` is gone — it described a coat level we no longer assert | |

## Art. II — One menu, and it's the game's *(M2·M3·M5·M7·M8·M10 — were FAIL)*

| # | Check | Expect | Result |
|---|---|---|---|
| M1 | Walk to your horse, **hold right-click** to lock on | the vanilla list — Show Info, Brush, Feed, Pat — with **Lead Horse INSIDE it**, not beside it. **Failed twice now** | |
| M2 | Count the menus on screen | exactly one | |
| M3 | Vanilla entries still work: **Show Info**, **Pat** (G), **Flee** (F) | all three. We no longer touch any of them — **Flee should be back**, which was M8 | |
| M4 | Take **Lead Horse**, walk, stop leading | rope in hand as R4; letting go leaves you standing normally | |
| M5 | Lead, walk out of range, look at the menu | Stop Leading still reachable | |
| M6 | **Judgement call:** is Lead in the right place in the list? | note it — its position is one number | |

## Art. III — Brush and feed are items again *(your ruling)*

| # | Check | Expect | Result |
|---|---|---|---|
| F1 | Lock on and read the list | **no Brush It, no Feed It**. Vanilla's are there; ours are gone | |
| F2 | Brush **from the satchel** | works as before — animation, uses count down | |
| F3 | Feed **from the satchel** | works, hunger climbs, item consumed | |
| F4 | Run a brush to its last use | still removed at zero | |

## Art. IV — Dirt: the question I can't answer *(D1–D6·G1·G2 — were FAIL)*

⚠️ **Read before testing.** The clean direction was proven by the Phase 1 spike. The **dirty** direction I never proved — I assumed one native ran both ways. Then the guard that fixed brushing held the coat at our number twice a second, which also stopped the engine painting grime. So the only thing that ever made horses look dirty got switched off, and the thing I assumed replaced it doesn't work. The guard is gone: we assert clean when you brush, and otherwise leave the coat alone.

| # | Check | Expect | Result |
|---|---|---|---|
| D1 | Brush spotless, **ride hard 5 minutes** | it gets visibly dirty on its own, from the engine. **If this works the probe may be unnecessary** — say so and skip to D6 | |
| D2 | `/sovdirtprobe` with no number | F8 lists five numbered candidates; nothing happens to the horse | |
| D3 | `/sovdirtprobe 1`, then 2, 3, 4, 5 — looking after each | **THE QUESTION: which number, if any, makes the horse visibly dirty?** If none, write "none" — that's just as useful | |
| D4 | Brush afterwards, for whichever number worked | it cleans off. A dirt native we can't undo is no use. Skip if none worked | |
| D5 | `/sovcare` while riding | the **number** climbs even if the coat doesn't. Bookkeeping and rendering are separate; only one is broken | |
| D6 | **Judgement call:** if D1 worked, is the engine's own rate about right? | if the engine dirties horses sensibly on its own, the honest answer may be to let it and keep our number purely for the brush | |

## Art. V — Troughs *(M6·G3 — were FAIL)*

The list was five prop names I guessed, and most don't exist. Rivers worked the whole time, which disguised a list problem as a drinking problem.

| # | Check | Expect | Result |
|---|---|---|---|
| W1 | Thirsty horse at the **Blackwater** trough, wait | drinks by itself, thirst climbs. **The line that failed** | |
| W2 | Troughs at **two other stables** | same. **Tell me any that don't work** — a failing trough just needs its prop name added | |
| W3 | Horse in a **river** | still drinks, as R5 | |
| W4 | Walk away mid-drink | stops; thirst keeps what it gained | |

## Art. VI — Teleporting leaves the horse *(your request — NEW)*

⚠️ Not a one-liner: the watchdog already had a distance check doing the **opposite** — past 200m it respawns the horse beside you. Right for straying, wrong for a teleport. They're told apart by watching *your* movement: nobody covers 100m in two seconds.

| # | Check | Expect | Result |
|---|---|---|---|
| T1 | Horse out, leave it, **teleport across the map** | gone within ~2s, with a note | |
| T2 | Whistle after teleporting | comes normally. Despawning isn't losing it | |
| T3 | **Ride** through a teleport | comes WITH you, not despawned — mounted is excluded. Skip if not possible | |
| T4 | Leave the horse and go **300m without teleporting** | old behaviour — quietly respawned near you | |
| T5 | `restart sovereign_stables` with a horse out | **not** despawned as a phantom teleport. Getting this wrong eats a horse that never moved | |

## Art. VII — Regression

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | Storefront **preview** horse | still spotless — it used the cleaning code the guard was built around, so most likely casualty | |
| G2 | Store a dirty horse, bring it back | groomed | |
| G3 | Sit out in the **rain** | the dirt **number** falls (`/sovcare`). Visible change depends on Art. IV | |
| G4 | A player disconnects with a horse out | horse vanishes (passed R5) | |
| G5 | `restart`, whistle, `/sovcare` | values persisted | |
| G6 | Buy a stock horse; button says **Purchase** | both true | |

## Art. VIII — Cleanup & the gate

| # | Check | Expect | Result |
|---|---|---|---|
| X1 | F8 console all session | no red Lua errors | |
| X2 | **If Art. II and Art. V pass, 2.1 closes** even with Art. IV unresolved — dirt *rendering* becomes its own tracked item rather than a gate | **your call** | |
| X3 | **Next up:** milestone 2.2, the death rework. The 1.3 cumulative-toll model is still live and docking 25 HP per death, which your downed-and-revivable ruling replaces | note only | |
