# 07 · The Horse Trainer Job & Training

> Design session, 2026-07-15. Rulings by the owner; analysis and open questions by Claude.

## The job

**Training is trainer-exclusive.** No player can train their own horse. The owner's reasoning, which holds up: **a horse is good enough untrained** — the 10–20 point gap is an *upgrade path*, not a handicap. So there's no "no trainer online = my horse is broken" failure, and a trained horse is something to **work toward**.

That makes the trainer a **service business** rather than a gatekeeper — the healthy version.

### Grades (ruled — exactly three)

| Grade | Title | Tend & train | Manage stable storefronts |
|---|---|---|---|
| **0** | Horse Trainer | ✅ fully | ❌ |
| **1** | Senior Horse Trainer | ✅ fully | ✅ |
| **2** | Stable Owner *(boss — admin-granted only)* | ✅ fully | ✅ |

Every grade can tend horses and **train them fully** — grade is not a training ladder. What grade buys is **commercial control**: 1 and 2 manage the stables' **storefronts** (not yet built — see the architecture note below). Grade 2 is the boss and is only ever given by an admin.

### Revenue lines (emergent from rulings already made)

1. **Finishing** — every horse sells below its ceiling, and a buyer can't tell by looking. Only a trainer can close it.
2. **Raising foals** — buy at 3–4, hold ~2.3–4.6 real days, sell a 5-year-old adult.
3. **Remediation** — a half-taught horse goes to a *better* trainer to learn the gaps it never got. *(Replaces "appraisal", which Claude overclaimed — the repertoire is never displayed, so there's no readout to sell. A good trainer's **opinion** is worth having, but that's reputation, not a mechanic.)*
4. **Breeding & wild stock** — breed 5→28; tame wild horses (the only source of anything over 7).

## Training — the tier system (ruled)

**Training is a tiered service, paid for and served over real days.**

- Training level is a **tier**.
- **The STORE caps at level 3.** ⚠️ *This is a cap on what the shop can generate — **not** a cap on training.* Stock horses are generated at **level 1 or 2**; the faster, sought-after (expensive) breeds are the exception and may generate up to **3**. The store never sells above 3.
- **Training goes beyond 3.** Tier 4+ exists and is trainer-only — it is the thing you cannot buy.
- **Tier 1 training is largely pointless** — most horses are already level 1.
- **Each tier = one real-life day of training.** Buy tier N → N days. **Even if the trainer's actual session takes 30 minutes.**

> **Why the delay matters (owner):** *"This gives the illusion that the money they are paying is worth something."* The wait is the product. A 30-second transaction that instantly upgrades a horse feels cheap; a horse that's **away at training for four days** feels like an investment — and it stops one trainer from servicing the whole server in an evening.

### The transfer mechanic — training has custody (ruled)

**A horse in training is not yours. It is the trainer's.**

1. The owner **transfers the horse to the trainer** using their **server session ID** — *"hat size"*, in RP terms.
2. The horse **becomes the trainer's property** for the duration. The owner cannot ride it; it isn't in their string.
3. When training completes, **the trainer transfers it back**.

This is why the horse is unusable during training — not a lockout flag, but genuine change of ownership. It reuses the **ride-transfer** system already planned for milestone 1.4.

**And it makes training a relationship, not a transaction.** Nothing mechanically stops a trainer keeping the horse. That's a deliberate trust/reputation economy — the RP *is* the safeguard. (Worth confirming this is intended rather than incidental.)

### The ladder — SETTLED (owner, 2026-07-15)

**Max training tier = 4.** The shop generates 1–3; **only a trainer reaches 4**.

| Tier | Stat vs ceiling | Days to train | Who can produce it |
|---|---|---|---|
| **1** | **−20** | 1 | shop (low-stat stock) |
| **2** | **−15** | 2 | shop (low-stat stock tops out here) |
| **3** | **−10** | 3 | shop (middle & high-stat stock only) |
| **4** | **ceiling** | 4 | **trainer only** |

- **Low-stat stock** rolls **1–2**. **Middle and high-stat stock** rolls **2–3**.
- Every shop horse therefore lands **10–20 points below its ceiling** — exactly the owner's earlier ruling. The two systems are the same system.
- **Tier 4 is the biggest single jump (−10 → 0).** That's deliberate: the trainer's exclusive rung is also the most valuable one. It's what they sell.
- **The tier's number IS the day count, wherever the horse started** (ruled): a level-2 horse going to tier 4 costs **4 days**, not 2. Each rung is progressively dearer.

Config: `Config.Training.tierOffset` / `.daysForTier` in `config/config.lua`; per-horse `storeLevel = { min, max }` in `config/horses.lua`.

## The training session (ruled, 2026-07-15)

Training is **an activity, not a menu click**. This answers the open question outright: it's a craft.

### Getting in
1. The trainer **leads the horse**.
2. **Right-Click Hold + ENTER** → the Training option.
3. The trainer **automatically stops leading**, and the horse enters **training mode**.

### In training mode
The moves are listed **bottom-right of the screen**:

| Move | Key |
|---|---|
| Mirror | **L-ALT** |
| Dance | **Up** |
| Jump | **Down** |
| Rear | **Left** |
| Foot Scratch | **Right** |
| Longeing | **ENTER** |
| **End Training** | **ESC** |

### XP rates by move (ruled)

| Move | Rate | Notes |
|---|---|---|
| **Mirroring** | **highest** | The horse mirrors you, so **you can walk while you train** — it's how you bring an **unmountable foal** home. Widely regarded as *the lazy way out*. Tate uses it only to top off the last ~200 XP on the way back to the stable. |
| **Longeing** | **middle** | Working the horse on the circle. **Pressing Jump mid-longe gives an extra XP boost.** |
| Dance · Foot Scratch · Jump · Rear | **lowest** | The flourishes. All have native animations. |

### The longeing sub-menu

Selecting **Longeing** opens its **own panel, bottom-right**:

| Option | Behaviour |
|---|---|
| **Switch Direction** | reverse the circle |
| **Adjust Speed Up** | steps up through the gaits; **past the fastest it wraps back to the slowest** |
| **Change Radius** | **±10 m** per press |
| **Jump** | the horse jumps — **bonus XP** |

### XP ceilings — by stat tier (ruled)

| Horse | XP to level 4 | Which |
|---|---|---|
| **Low / mid-tier stats** | **1,450 XP** | everything else |
| **High-tier stats** | **2,460 XP** | **the fast breeds** — Arabian, Thoroughbred, Turkoman |

**A better horse takes ~70% longer to finish.** The expensive breeds cost more to buy **and** more to make good, so a finished Turkoman is genuinely rare and a trainer prices accordingly.

Set **per breed** via `xpTier = 'lowMid' | 'high'` in `config/horses.lua` — the fast breeds are `'high'` by default, but it's a flag, not a formula, so any breed can be moved.

### Session length

**Not capped at 30 minutes** — that was an illustration, not a target. Training shouldn't eat a trainer's whole evening; they have a game to play. First-pass rates (`Config.Training.xpPerSecond`, all tunable):

| Method | Low/mid (1,450) | High (2,460) |
|---|---|---|
| Mirroring @ 3/s | **~8 min** | ~14 min |
| Longeing @ 2/s | ~12 min | ~20 min |
| Flourishes @ 1/s | ~24 min | ~41 min |

**These are a starting guess and need real sessions to calibrate.** ⚠️ See the balance note below.

### ⚖️ Mirroring stays dominant — ruled, deliberately

Claude flagged that mirroring is the highest XP **and** grants travel, so it mechanically dominates every other move — only culture ("the lazy way out") restrains it, and the longeing sub-menu is strictly the *worse* choice.

**Owner ruling: leave it.**

> *"It's all about choices. If a trainer wants to be a lazy, sleazy trainer, that's on them. Those who enjoy the RP and interacting with the horses will enjoy the other options."*

**Do not "fix" this.** No XP nerf, no cap on mirroring's share. The optimal path is allowed to be the boring one — the reward for longeing *is* the longeing. A lazy trainer is a **character**, not a bug, and the county can form its own opinion of them.

**This is a project-wide principle, not a one-off** — see the design principle below.

## 🎓 The repertoire — a horse only knows what you taught it (ruled, 2026-07-15)

> *"Yeah my horse might be good and following me better and comes to me quicker and listens… but because I didn't do any of the other things, the horse won't be able to dance while horseback, won't clear obstacles on the ground very well, won't be able to rear."*

**Training moves don't just pour XP into a bucket — each one teaches the horse that specific ability.** A move must be worked **a number of times during training** before the horse actually learns it. Skip a move, and the horse simply never learns it.

So mirroring keeps its XP crown *and* acquires a real cost: a mirrored horse is **statistically excellent and behaviourally illiterate**.

### Move → what it teaches

| Move | What the owner gets |
|---|---|
| **Mirroring** | Responsiveness — follows better, comes quicker, listens. *(Which is exactly, and only, what mirroring is.)* |
| **Dance** | Dance under saddle (hold **SPACE**) |
| **Jump** | Clears ground obstacles cleanly |
| **Rear** | Rears on command |
| **Foot Scratch** | **Nothing — the horse just foot-scratches *less*.** The reward is the absence of a nuisance: an untrained horse fidgets. |
| **Longeing** | **STAMINA** — the only move that touches a stat. Skip it and the horse never finishes its wind, whatever its tier. |

### ⚖️ RULED: the repertoire is **per trick** — and Longeing is the **one stat exception**

> *"Per trick. Longeing could be the only stat one… because in reality, in the wild west, stamina matters more than any fast horse."*

| | |
|---|---|
| **Mirroring · Dance · Jump · Rear · Foot Scratch** | teach **tricks / behaviours** |
| **Longeing** | the **only** move that touches a **stat** — **stamina** |

**So a mirror-only horse is fast, handsome, obedient — and cannot go the distance.**

This is the whole design landing in one place:

- **The mirroring ruling stands untouched.** No nerf, no cap. Mirroring is *still* the fastest XP. It just produces a horse that's no good on a long ride.
- **The craft option owns the most valuable stat.** In the West, stamina beats speed — a horse that goes all day beats a horse that goes fast for ten minutes. So the one move that requires patience and a sub-menu rewards the one stat that actually matters out there.
- **It's a consequence, not a punishment.** Nobody took anything from the lazy trainer. They simply never built the horse's wind, because you can't shortcut fitness. That's true of real horses too.
- **It's discoverable exactly where it hurts.** Not at the paddock — twenty miles out, when the horse is blown and the buyer starts wondering who trained it.

**Mechanism:** the tier ladder closes the gap on the other stats as normal; **stamina additionally requires longeing reps.** A tier-4 horse that was never longed still has stamina short of its ceiling — the only stat the trainer can't fake.

### Foot Scratch — a joke with a point

It teaches nothing, and that's the *joke*: the reward for training it is that the horse **stops doing it**. An untrained horse fidgets and scratches; a worked one stands quiet. It costs a trainer time for no capability — which is precisely why a lazy trainer skips it, and precisely how you'd spot one.

### Why this is the right shape

- **It keeps the ruling intact.** No XP nerf, no cap. Mirroring is still the fastest. The choice stands — it just *costs* something.
- **It's a consequence, not a punishment.** Nothing is taken away. The horse is fine. It's simply *ignorant*, because its trainer was.
- **It's quiet.** Nothing announces it. The owner finds out the first time they hold SPACE and the horse does nothing.
- **Reputation becomes mechanical without a stat.** "Who trained this?" is now a question with a discoverable answer. A trainer known for mirroring everything will be known for it — because their horses can't do anything.
- **It makes the longeing sub-menu worth building.** It teaches something no other move does.
- **It creates a remediation market.** A half-trained horse can be sent back to a *better* trainer to learn the gaps — another revenue line, and a second chance for the horse.
- **It rewards actual horsemanship.** Repertoire is never displayed anywhere (see below) — so knowing how to read a horse is *player* skill, earned at the paddock, not a stat someone hands you.

### 🎲 Chance, not on/off — and RDR2 may already do most of this

**Owner (2026-07-15):** *"I believe those things actually work on chance natively — like the chance of the horse falling on train tracks."*

That reframes E10. These behaviours are **probabilistic in the base game** (the track-stumble chance is already on our list as **D8**). So the repertoire probably shouldn't be a hard *can/can't* — it should move the **odds**:

- An untaught horse still *tries* to rear — it just does it **rarely, or badly**.
- An untaught horse doesn't refuse a log — it **stumbles over it more often**.
- A well-taught horse does it cleanly, first time.

That's softer, more natural, and almost certainly easier to implement (nudge an existing chance rather than intercept an input). It also *reads* better: your horse isn't broken, it's **green**.

#### The native bond ladder — a big find

`rdr3_discoveries` shows RDR2 already gates horse abilities behind a **1–4 bond ladder**:

| Flag | Hash |
|---|---|
| `TF_HORSE_BONDLVL_2_PERKS` | `0x151A0091` |
| `TF_HORSE_BONDLVL_3_PERKS` | `0x916DC0D8` |
| `TF_HORSE_BONDLVL_4_PERKS` | `0x54B66C3C` |
| `TF_HORSE_BOND_LOCK_ACTION` | `0x1101AD0C` |

Perks unlock at bond **2/3/4**, and there is a flag literally named **"bond lock action"**. The game already does *"this horse can't do that yet."* **And our training tiers are also 1–4** — the ladders line up.

#### The design question this creates

| Approach | Gets us | Costs us |
|---|---|---|
| **(a) Drive the native bond level from our training level** | RDR2's own perks unlock for free — rear, dance, skid, drift — with no ability system to build | Bond is **one scalar**: it can't express "mirrored-only", so the repertoire's whole point is lost |
| **(b) Gate every ability ourselves, per move** | Full granularity | Fighting the game; re-implementing what it already does |
| **(c) Hybrid — native bond level from training tier, our per-move record on top as a *chance modifier*** | Native perks unlock by tier **and** an untaught move stays clumsy | Most design work, but it's the only one that keeps both halves |

**Leaning (c)**, and it fits the owner's instinct exactly: the tier opens the door, the reps decide how well the horse walks through it.

**Needs a spike before Phase 3:** can bond level be read/written from script, do the perk flags fire off it, and are the underlying success chances (rear, obstacle, stumble) reachable? This also touches **E3** (bonding reduces spooking) and **D8** (track stumble) — they may all be the same native system.

### Open

**Settled:** ~~what Foot Scratch teaches~~ (nothing — it just scratches *less*) · ~~is the repertoire visible~~ (**no — never**, see below).

1. **Longeing: stamina or recall?** Recommend **stamina** (recall overlaps Mirroring). And if stamina — mechanism **(a)** extra progress toward the stamina gap, or **(b)** a per-stat repertoire?
2. **Reps per move.** How many times must a move be worked before it sticks? First pass in `Config.Training.repertoire.repsToLearn`, tunable.
3. **Schema:** Phase 3 needs a `training` JSON blob on `sovereign_horses` — level, xp, per-move rep counts, and learned abilities/odds.
4. **Native vs ours** — see the table above. Decide (a)/(b)/(c) after the bonding spike.

## 🔒 The repertoire is never shown. Anywhere. (ruled, 2026-07-15)

> *"No. You discover it by being a good trainer and learning horses and RPing."*

**No UI. No readout. No appraisal panel. No codex entry.** The horse's repertoire is never surfaced to anyone, ever — not to the owner, not to a trainer, not by any job permission.

You learn what a horse can do by **working with it**. A good trainer knows because they've handled a hundred horses and can tell. That knowledge lives in the **player**, not the interface.

> ⚠️ **This corrects an overclaim by Claude.** I had pitched "appraisal" as a trainer revenue line — a trainer reading a horse's hidden repertoire for a buyer. **That was wrong.** There is no appraisal readout to sell. A trainer may still *offer an opinion* on a horse, and a good one's opinion will be worth having — but that's roleplay and reputation, not a mechanic, and it can't be built. J17 (stats visibility) remains a separate question about **stats**; it has nothing to do with repertoire.

**The trainer's real revenue lines are therefore: finishing, raising foals, breeding/wild stock, and remediation** — all of which are actual work, not information brokerage.

### 📐 Design principle: mechanical dominance of a *playstyle* is not a problem

Sovereign County doesn't force optimal play or punish suboptimal-but-enjoyable play. When one option is mathematically better than another, that is **only** worth fixing if it damages something real — the economy (dupes, infinite money), server health, or another player's experience. **A player choosing the dull-but-efficient route harms nobody but their own evening.**

So: don't balance away choices. Balance away *exploits*.

### How the session and the day-timer fit together

They're separate, and both matter:

- The **session** is the work — the trainer earns the horse's XP in ~30 minutes.
- The **days** are the delivery — the horse stays in the trainer's custody for N real days regardless.

So a trainer can do the work in one evening but still can't hand back a tier-4 horse for four days. The session is the craft; the wait is the product.

### Trainer caps (ruled)

Trainers get a **higher horse cap** (per-job, already supported by `Perms.maxHorses` over `config/jobs.lua`). Additionally `Config.Training.heldHorsesIgnoreCap = true` — horses held **in custody for training** don't consume the trainer's own slots, so a busy trainer can't be locked out of taking work.

## Open questions

**Settled:** ~~cap 3 vs tier 4~~ (3 = store cap; max training tier = **4**) · ~~horse usable while training~~ (no — custody transfers) · ~~"Tier N = N days"~~ (target tier's number = days, wherever it started) · ~~trainer caps~~ (higher cap + held horses don't count) · ~~where fast breeds generate~~ (middle/high stat stock rolls 2–3).

1. ~~What does the trainer do in their 30 minutes?~~ **RESOLVED — see The training session above.** It's an activity: lead → Right-Click Hold + ENTER → perform moves for XP.
2. **Payment** — pure player-to-player, or NPC contracts as a floor when no customers are online?
3. **Is trainer theft intended?** Custody transfer means a trainer can simply keep the horse. Assumed deliberate (a reputation economy), but worth stating out loud.
4. **What does a trainer charge per tier?** Needs the economy pass — it's the number that decides whether the job pays.

## Economy anchor

**$2–7.50/hour is the wage of an *employed* player** — and employment is only one of many routes (hunting, fishing, crime, missions, digging, selling, mining, crafting…). So it is a **floor, not the ceiling**: it tells us a wage job is deliberately not the fast road, which is realistic.

**We cannot price the catalog from it alone.** To set horse prices (and what a trainer charges per tier) we need the realistic earnings of a *good* earner across those other activities. **Pricing waits on the economy pass** — otherwise the 60+ breed fill (M1) gets entered twice.

## Tack (ruling, 2026-07-15)

**Tack belongs to the player, not the horse.**

- Buy a piece of tack **once** — use it on **any** horse you own.
- A **dead horse's tack returns to the stable** (you own the saddle; losing a costly rig to a stray bullet is punitive). **Cargo is not tack** — see the lifecycle doc.
- **Never re-buy what you own.** If you *adjust* a piece of tack, you **pay the difference** only.

This turns tack into a **player-level locker** rather than per-horse equipment, and makes F3 (transfer components between horses) the default behaviour rather than a feature.

## Architecture note — the storefront module

Grades 1–2 manage **stable storefronts**, which don't exist yet. The owner asked whether to build them into this script or as a separate, reusable one. **See the recommendation in the session notes: build it separately** (`sovereign_storefronts`) and let stables integrate through the existing bridge/exports, so every player-run store on the server shares one system.
