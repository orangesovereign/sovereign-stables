# 07 · The Horse Trainer Job & Training

> Design session, 2026-07-15. Rulings by the owner; analysis and open questions by Claude.

## The job

**Training is trainer-exclusive.** No player can train their own horse. The owner's reasoning, which holds up: **a horse is good enough untrained** — the 10–20 point gap is an *upgrade path*, not a handicap. So there's no "no trainer online = my horse is broken" failure, and a trained horse is something to **work toward**.

That makes the trainer a **service business** rather than a gatekeeper — the healthy version.

### Grades — ⚠️ REVISED 2026-07-15: FOUR grades, and they are ROLES, not ranks

> **This supersedes the earlier "exactly three grades" ruling.** The owner added a
> **Wagon Maker**: *"Wagon makers don't get horse training perms. Their only job is
> Wagon Making, wagon customization and wagon repair and storefronts."*

| Grade | Title | Train horses | Wagons (make · customise · repair) | Storefronts |
|---|---|---|---|---|
| **0** | Horse Trainer | ✅ | ❌ | ❌ |
| **1** | Senior Horse Trainer | ✅ | ❌ | ✅ |
| **2** | **Wagon Maker** | ❌ | ✅ | ✅ |
| **3** | Stable Owner *(boss — admin-granted only)* | ✅ | ✅ | ✅ |

#### 🔑 The rule that makes this work: permissions are PER-GRADE AND EXPLICIT. Nothing is inherited.

This is the important part, and it is a real change of model.

**VORP grades are integers, and every framework convention treats them as a
ladder** — grade 2 outranks 1 outranks 0, and perks accumulate upward. That
cannot express what was just ruled. Read the table again: a **Wagon Maker (2) has
storefronts but cannot train**, while a **Horse Trainer (0) can train but has no
storefronts**. Neither role contains the other. They are **peers with different
trades**, and no linear order ranks peers.

So we stop pretending. **A grade is a role slot, not a rung.** `Perms` resolves a
grade to an *explicit set* of permissions and never rolls up from the grades
below it. The numbers are identifiers — 2 is not "more than" 1.

The one place hierarchy survives is **Stable Owner (3)**, which is the boss, gets
everything, and is only ever set by an admin. That's a policy, not an inheritance
rule.

**Why this matters beyond tidiness:** if grades inherited, a Wagon Maker would
silently gain horse training the moment anyone re-ordered the list — the exact
bug the owner's ruling exists to prevent. Explicit sets make "who may do what" a
thing you read, not a thing you compute.

### 🔧 The Wagon Maker's trade — ruled 2026-07-15

> *"Everyone can repair their wagon to the lowest wagon health to get your wagon
> going. **Wagon makers are the only people who can repair a wagon to 100%.**"*

| | Who | To what |
|---|---|---|
| **Field repair** | **anyone** | `fieldRepairTo` (150) — enough to move, not enough to enjoy |
| **Full repair** | **Wagon Maker (2) + boss** | `proRepairTo` (1000) — whole |

#### 📐 This is the training ruling again, word for word

Put them side by side:

> *"A horse is **good enough untrained** — the 10–20 point gap is an **upgrade
> path**, not a handicap."*
>
> *"A wagon is **good enough field-repaired** — the gap to 100% is an **upgrade
> path**, not a handicap."*

Same sentence, different trade. And it produces the same three things it did for
the trainer:

1. **No dead-server failure.** You are never stranded because no Wagon Maker is
   online — you patch it up and limp home. The service is never a gate.
2. **The last stretch is the biggest, and it's the product.** 150 → 1000 is the
   whole of the difference, and only one grade can close it. Exactly like tier 4
   being the largest single jump and trainer-only.
3. **It makes a business, not a bottleneck.** The Wagon Maker sells something
   real that you genuinely want and can genuinely live without.

**Permissions:** `wagonRepair` (field, default true for everyone) and
`wagonFullRepair` (Wagon-Maker-only). Both are asserted in `tests/perms_spec.py`
— the gap between the two numbers *is* the trade, so the spec checks that
`fieldRepairTo < proRepairTo` and that the floor is above zero.

**This also re-opens Q3 in a good way.** "A wrecked wagon can't leave the stable
until repaired" was unviable when no repair system existed — it would have
bricked wagons forever. Now there is one: field-repair the wreck at the stable to
limp it home, or hand it to a Wagon Maker to be made whole. That's a real loop,
so the harsher rule is now genuinely available. *(Owner's call — see the ledger.)*

**Still open:** where a field repair happens (a kit item? a prompt at the wagon?
at a stable only?), and whether it costs anything.

#### ⚠️ Grades are configured but NOT ENFORCED (as of 2026-07-15)

`Perms.get(job)` takes **only the job**. There is no grade parameter anywhere in
the codebase; every `Bridge.getJob()` caller discards the grade it returns, and
`horseCreatorMinGrade = 2` sits in `config/jobs.lua` read by **nothing**.

**Today a Grade 0 Horse Trainer can do everything a Stable Owner can.** That is a
security hole wearing a config option's clothes, and it must be closed before any
of the above means anything.

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

#### ❌ CORRECTION: the "native bond ladder" was a misread (2026-07-15)

An earlier draft of this doc claimed RDR2 gates horse abilities behind a readable **1–4 bond ladder**, citing `TF_HORSE_BONDLVL_2_PERKS` (`0x151A0091`), `_3_` (`0x916DC0D8`), `_4_` (`0x54B66C3C`) and `TF_HORSE_BOND_LOCK_ACTION` (`0x1101AD0C`).

**That was wrong.** Those live in [`AI/EVENTS/tutorial_flags.lua`](../../_reference/rdr3_discoveries/AI/EVENTS/tutorial_flags.lua) — **`TF_` means *tutorial flag***. They control **hint popups**, nothing else. `TF_HORSE_BOND_LOCK_ACTION` is the *tooltip* that says an action is bond-locked; it is not the lock. A full search of `rdr3_discoveries` finds **no bond read/write native at all**.

So the option "drive the native bond level from our training tier and get R★'s perks for free" **never existed**. Do not resurrect it.

**Still useful:** `tutorial_flags.lua` is an *inventory of every state RDR2's horse system tracks*, because there's a hint for each — `TF_HORSE_DIRTY`/`FILTHY` (**two dirt tiers** — feeds the Phase 2 dirt spike, H5/H10/L9), `HUNGRY`/`STARVING`, `CORE_HEALTH_50`/`EMPTY`, `SPOOKED`, `BUCK_OVERSPURRED`, and the full taming state machine. Read it as a map, never as an API.

#### ✅ What's actually there — the animal tuning surface

RDR2 exposes a **per-ped, get/set tuning surface** on any animal. Not one scalar — dozens of named knobs:

```lua
Citizen.InvokeNative(0xCBDA22C87977244F, horse, paramId, value)  -- SET_ANIMAL_TUNING_FLOAT_PARAM
Citizen.InvokeNative(0x4BC3ECFDA0297E27, horse, paramId)         -- GET_ANIMAL_TUNING_FLOAT_PARAM
Citizen.InvokeNative(0x9FF1E042FA597187, horse, paramId, bool)   -- SET_ANIMAL_TUNING_BOOL_PARAM
Citizen.InvokeNative(0x1C1993824A396603, horse, paramId)         -- GET_ANIMAL_TUNING_BOOL_PARAM
```

| Param | Id | Why we care |
|---|---|---|
| `ATF_BraveryMin` / `ATF_BraveryMax` | 6 / 5 | **Courage, literally** — E4 |
| `ATF_SpookedRangeOverride` | 146 | **Spooking, literally** — E3 |
| `ATF_FearRange` | 10 | How far out fear triggers |
| `ATF_ThreatResponseNoise{Small,Medium,Big}CaliberFleeOrCombatRange` | 115 / 117 / 119 | Spook radius **per gun caliber** |
| `ATF_ThreatResponsePlayerAlertRange` | 87 | Spook distance from people |
| `ATB_RagdollEasily` | 71 | **Moves stumble odds** — D8 *(owner-confirmed)* |
| `ATB_EnableFleeOwner` | 67 | Whether it bolts from its own owner |

This is **better than the bond ladder would have been**. The reason (a) was tempting was free perks; the reason it was flawed was that one scalar can't express "mirrored-only". The tuning surface has no such problem — it's multi-dimensional and per-horse, which is exactly what the repertoire needed.

It also delivers the owner's instinct directly: these are **ranges and probabilities**, so the repertoire nudges odds rather than intercepting inputs. A green horse gets a wide `SpookedRangeOverride` and low `Bravery`; a worked one gets tightened.

**Blackboards** expose readable state — `Spooked` (bool), `Fear`, `Agitation`, `Fatigue`, `SurfaceIncline` (floats). Reference warns writes only visibly land on `script`-section blackboards and these sit outside it, so **treat them as read-only sensors**. That's what we want anyway: detect a spook, don't cause one. **Owner confirms `Spooked` reads on demand.**

#### The design question, revised

Option (a) is dead — see above. The live choice is between **(b)** gating every ability ourselves and **(c)** the hybrid. **Still (c)**, and the tuning surface makes it cheaper than when it was written: *the tier opens the door, the reps decide how well the horse walks through it* — where "how well" is now a **tuning param**, not an ability flag we invent.

### Open

**Settled:** ~~what Foot Scratch teaches~~ (nothing — it just scratches *less*) · ~~is the repertoire visible~~ (**no — never**) · ~~Longeing: stamina or recall~~ (**stamina**, per trick otherwise) · ~~native vs ours~~ (**(c)**; (a) was a misread).

1. **Reps per move.** How many times must a move be worked before it sticks? First pass in `Config.Training.repertoire.repsToLearn`, tunable.
2. **Schema:** Phase 3 needs a `training` JSON blob on `sovereign_horses` — level, xp, per-move rep counts, learned abilities/odds, **and courage level + courage XP**.
3. **Ladder tuning:** what `BraveryMin/Max`, `SpookedRangeOverride` and `FearRange` read at each courage rung. Measured in the spike, not guessed.

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

---

## 🐊 Courage training (E3/E4) — ruled 2026-07-15

**This is not the Training Menu.** Courage is its own system, its own ladder, its own place in the world. The tier system (1–4) is done in a paddock with a menu. Courage is done by **walking a horse at something that wants to eat it.**

### The rules (all owner-ruled)

| | |
|---|---|
| **Scale** | **0–9**, a **leveled number** — XP accrues, levels tick over |
| **Who may train it** | **Horse Trainers only** (J9). Not the owner, not a friend. |
| **Foals** | **Cannot.** *(Already ruled in [05-LIFECYCLE](05-LIFECYCLE.md) — the one training a foal may not do.)* |
| **Visibility** | **Visible — to the owner only.** Stand at the horse, **right-click → horse info**. Courage is a real, readable number. |
| **Persistence** | **For the horse's life.** Once earned, never lost. |
| **At 9** | Considerably less spooked by everything · higher tolerance for close range · **won't throw the rider** at the sign of fear or danger |
| **Starting value** | Set by **breed + personality** (E5) — a low floor, not a head start |

> ⚠️ **Courage is the deliberate opposite of the repertoire.** The repertoire is *never shown, anywhere*. Courage is *shown, to the owner, on demand.* That is not an inconsistency — the repertoire is knowledge the trainer owes you and can lie about; courage is a number you paid for and can verify. One is reputation, the other is receipt.

### The loop

**Owner, describing how it actually plays:** *"I typically take my horses to the swamp and do the Courage Training with gators… they don't really move unless you get too close. I've seen it where people have trapped cougars and bears in pens on their property."*

1. The trainer brings the horse within the **fear animal's training radius**.
2. The horse **spooks** — read live off the `Spooked` blackboard.
3. The trainer **pats** it (on foot) or **calms** it (mounted) to stop it bolting.
4. **XP accrues per second the horse stays in radius.** Time in the radius is the whole product; the pat is only how you buy that time.
5. At 9, the tuning params are written and the horse is done. For good.

### 🎁 The engine hands us this loop

`EVENT_CALM_PED` — fully documented, 4-element payload:

| Idx | Field |
|---|---|
| 0 | calmer ped id → **the trainer** |
| 1 | mount ped id → **the horse** |
| 2 | `CalmTypeId` → **how** they did it |
| 3 | `isFullyCalmed` → **whether it landed** |

…and the calm types are the owner's mechanic verbatim: `CT_CALM` (0, the mounted calm) · `CT_SHORT_PAT` (1) / `_START` (2) · `CT_LONG_PAT` (3) / `_START` (4) · `CT_VERBAL_AFFIRMATION_ONLY` (5).

**We do not build the pat.** The game fires an event naming who calmed which horse, how, and whether it worked. On-foot pat and mounted calm arrive through **one event**, told apart by the type id — so both halves of the design are one code path. `PP_HORSE_CALM` (prompt priority 27) confirms R★'s own Calm prompt; anims are `mood_calmhorse` and `horse_patting_neck_loop_left` / `horse_patting_crouch_loop_left`.

*Free for Phase 4:* `EVENT_HORSE_BROKEN` carries `HBET_STARTED/FAILED/SUCCESS/CANCELLED` — the taming minigame (S17) delivered the same way.

### Risk is the balancing lever — and it balanced itself

The owner's swamp technique tells us the design is **already self-balancing**, and we should not touch it:

| Animal | Danger | XP/sec | Why |
|---|---|---|---|
| 🐊 **Gator** | Low — static unless you close | **Lowest** | The swamp method. Safe, slow, boring, *reliable*. |
| 🐍 Snake | Low | Low | Small, near-static |
| 🐺 Wolf | High — packs | High | You will be fighting |
| 🐆 Cougar | High — fast, ambushes | High | It picks the moment |
| 🐻 **Bear** | Highest | **Highest** | Fastest courage in the game, if you live |

**Nobody had to design this trade.** The gator is safe *because gators are lazy*, and the bear is fast *because bears are bears* — the world already priced it. We just pay XP proportional to what the animal already does. Nothing is nerfed; the patient trainer takes the swamp, the bold one takes the bear, and both are playing correctly.

### 📐 Penned animals are a feature, not an exploit

*"I've seen it where people have trapped cougars and bears in pens on their property."*

**Do not add an anti-pen check.** A trapped bear is not a loophole — it is a player who **caught a bear**, which is a harder day than any training session. It is exactly [design principle #8](03-CODING-PLAN.md): *don't balance away choices — balance away exploits.* It costs the economy nothing, costs the server nothing, and costs no other player anything.

It also *builds* something: a courage pen is **player infrastructure**, a reason to own land, and a service a trainer can sell access to. It should fold naturally into Sovereign Ranching (X5) later. This falls out for free — if we detect "fear animal within radius," a penned gator satisfies it with **zero extra code**.

### Implementation shape

- **Fear animals are world animals.** We spawn nothing. The trainer finds, leads to, or pens their own. We only ask *"is a fear-animal model within radius of this horse?"*
- **Radius is per-animal** (config) — a gator you may stand nearer than a bear.
- **XP is per-second-in-radius**, per-animal rate. `isFullyCalmed` pays a small one-off bonus — the pat is the tool, not the wage.
- **Courage → params is a config ladder.** Each rung 0–9 maps to `ATF_BraveryMin/Max`, `ATF_SpookedRangeOverride`, `ATF_FearRange`. Rung 9 additionally sets the won't-throw-the-rider behavior.
- **Persistence is ours, not the engine's.** Store `courage` + `courage_xp` in the DB and **re-apply the params on every spawn**. The owner's rule ("persists for life") then holds through despawn, restart and crash *regardless* of whether the ped retains them — which we have not measured and now don't need to.

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
