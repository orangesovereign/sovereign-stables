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
3. **Appraisal** — J17 stats visibility. Because the gap is invisible, someone who can *read* a horse has value even when they're not training one.
4. **Breeding & wild stock** — breed 5→28; tame wild horses (the only source of anything over 7).

## Training — the tier system (ruled)

**Training is a tiered service, paid for and served over real days.**

- Training level is a **tier**. **Stock horses sell at level 1 or 2**; the faster, more sought-after (expensive) breeds are the exception.
- **Caps at level 3.**
- **Tier 1 training is largely pointless** — most horses are already level 1.
- **Each tier = one real-life day of training.** Buy tier N → N days. **Even if the trainer's actual session takes 30 minutes.**

> **Why the delay matters (owner):** *"This gives the illusion that the money they are paying is worth something."* The wait is the product. A 30-second transaction that instantly upgrades a horse feels cheap; a horse that's **away at training for three days** feels like an investment — and it stops trainers from farming instant upgrades.

### How tiers map onto the stat model

This lines up almost perfectly with the 10–20 point untrained gap:

| Level | Stat position | Who has it |
|---|---|---|
| **1** | ceiling **− 20** | most stock horses off the shelf |
| **2** | ceiling **− 10** | better stock; sought-after breeds |
| **3** | **ceiling** (fully trained) | only via a trainer |

So the "10–20 below ceiling" ruling *is* the tier ladder: level 1 = −20, level 2 = −10, level 3 = ceiling. Two tiers of headroom, one real day each. **Proposed — needs confirming.**

## Open questions

1. **Cap 3 vs "Tier 4".** The ruling says *caps at level 3*, but also *"if you purchase Tier 4 training it's automatically 4 days"*. Is tier 4 just arithmetic illustration, or can some horses (fast/specialty breeds?) train beyond 3?
2. **Is the horse usable while in training?** N real days is a long time to lose your mount. Options: (a) the horse is **at the stable, unavailable** — training is a real sacrifice; (b) it's rideable and the timer just runs. **Recommend (a)** — it gives the wait teeth and creates natural demand for a second horse.
3. **What does the trainer actually *do* in their 30 minutes?** Lunging, obstacle courses, riding (E1)? Or is it a menu action + timer?
4. **Where do fast/sought-after breeds start?** "The exception" — do they sell *higher* (level 2–3, justifying the price) or *lower* (green, needing work)?
5. **Payment** — pure player-to-player, or NPC contracts as a floor when no customers are online?

## Tack (ruling, 2026-07-15)

**Tack belongs to the player, not the horse.**

- Buy a piece of tack **once** — use it on **any** horse you own.
- A **dead horse's tack returns to the stable** (you own the saddle; losing a costly rig to a stray bullet is punitive). **Cargo is not tack** — see the lifecycle doc.
- **Never re-buy what you own.** If you *adjust* a piece of tack, you **pay the difference** only.

This turns tack into a **player-level locker** rather than per-horse equipment, and makes F3 (transfer components between horses) the default behaviour rather than a feature.

## Architecture note — the storefront module

Grades 1–2 manage **stable storefronts**, which don't exist yet. The owner asked whether to build them into this script or as a separate, reusable one. **See the recommendation in the session notes: build it separately** (`sovereign_storefronts`) and let stables integrate through the existing bridge/exports, so every player-run store on the server shares one system.
