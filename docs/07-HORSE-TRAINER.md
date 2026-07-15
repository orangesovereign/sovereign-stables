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

### Trainer caps (ruled)

Trainers get a **higher horse cap** (per-job, already supported by `Perms.maxHorses` over `config/jobs.lua`). Additionally `Config.Training.heldHorsesIgnoreCap = true` — horses held **in custody for training** don't consume the trainer's own slots, so a busy trainer can't be locked out of taking work.

## Open questions

**Settled:** ~~cap 3 vs tier 4~~ (3 = store cap; max training tier = **4**) · ~~horse usable while training~~ (no — custody transfers) · ~~"Tier N = N days"~~ (target tier's number = days, wherever it started) · ~~trainer caps~~ (higher cap + held horses don't count) · ~~where fast breeds generate~~ (middle/high stat stock rolls 2–3).

1. **What does the trainer actually *do* in their 30 minutes?** Lunging, obstacle courses, riding (E1)? Or a menu action that starts the timer? *(This decides whether training is a minigame or an errand.)*
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
