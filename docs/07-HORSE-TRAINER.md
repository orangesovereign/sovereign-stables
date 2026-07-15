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

### How tiers map onto the stat model — **needs re-confirming**

My earlier mapping assumed level 3 = fully trained. **The store-cap clarification breaks that**: if the shop can already sell a level 3, and the configured stat is the *fully trained ceiling*, then the ceiling must sit **above** level 3 — otherwise the best breeds would arrive already finished and trainers would have nothing to sell them.

So the ladder likely runs: store generates 1–3 → **training climbs past it to a maximum tier that equals the ceiling**. The open question is simply **what that maximum tier is** (5? 6?), and how the 10–20 point gap distributes across the rungs.

## Open questions

1. ~~Cap 3 vs Tier 4~~ **RESOLVED: 3 is the STORE's generation cap; training goes beyond it.** Remaining: **what is the maximum training tier** (= the stat ceiling)?
2. ~~Is the horse usable while training?~~ **RESOLVED: no — ownership transfers to the trainer.**
3. **Does "Tier N = N days" mean the TARGET level, or the number of levels gained?** Read literally — *"purchase Tier 4 training, it's automatically 4 days"* — the **target tier's number is the day count**, regardless of where the horse starts. So a level-2 horse going to level 4 costs **4 days**, not 2. That makes each rung progressively dearer, which is good design. **Confirm.**
4. **Do customer horses count against a trainer's own horse cap (J1)?** If yes, a Senior Trainer with three clients is full and can't take work. **Recommend: horses held for training don't count** — or trainers get a much larger cap.
5. **What does the trainer actually *do* in their 30 minutes?** Lunging, obstacle courses, riding (E1)? Or a menu action that starts the timer?
6. **Where do fast/sought-after breeds generate?** Higher (2–3, justifying the price) or greener (1, so you pay for potential)?
7. **Payment** — pure player-to-player, or NPC contracts as a floor when no customers are online?
8. **Is trainer theft intended?** Custody transfer means a trainer can simply keep the horse. Assumed deliberate (reputation economy), but worth stating out loud.

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
