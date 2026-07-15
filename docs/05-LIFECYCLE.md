# 05 · The Horse Lifecycle — design pillar

> **Owner, 2026-07-15: "A horse has a complete lifecycle — Foal to Death."**

This is a **pillar**, not a feature. A horse is not a static asset you buy and keep forever — it is **born, grows, works, ages, and dies**. Every horse system hangs off this arc, and the arc closes on itself: breeding makes foals, foals become adults, adults age out, and the county needs new horses.

Nothing in this file overrides the [death rules](02-FEATURES.md#️-death-rules--owner-ruling-2026-07-15). It explains the arc they sit at the end of.

## The arc

```
        ┌─────────────────────── breeding (G) ───────────────────────┐
        │                                                            │
        ▼                                                            │
     FOAL  ──grow (G6)──▶  ADULT  ──age (E6)──▶  AGED  ──age 31──▶ DEAD
   born or bought          ride, work,           decline?          permanently
   (N10, trainer only)     breed, train                            │
        ▲                     │                                    │
        │                     └── downed too long (H11) ───────────┘
        │                         (the other permanent death)
        └── the loop: the county's horses come from its horses
```

## Stages — **PROPOSED, needs an owner ruling**

I've filled nothing in that the owner hasn't said. Everything marked **?** is a decision for the lifecycle design session.

| Stage | Age | Rideable | Breedable | Notes |
|---|---|---|---|---|
| **Foal** | 0 → **?** | **no** (assumed) | **no** (assumed) | Born from breeding (G) or bought by a Horse Trainer only (N10/J23). Must grow up (G6). |
| **Adult** | **?** → **?** | yes | yes | The working life: ride, train (E1–E4), tack, haul. Peak condition. |
| **Aged** | **?** → 31 | yes | **?** | Sellable while it still has value (S8). Does it decline? |
| **Dead** | **31** | — | — | Permanent. The only other permanent death is downed-too-long (H11). |

## How every feature maps onto the arc

| Phase of life | Features |
|---|---|
| **Born** | G1–G6 breeding + genetics (inherits from sire/dam) · N10/J23 buy a foal (Horse Trainer only) |
| **Grows** | G6 foal → adult growth |
| **Works** | E1/E2 activity levelling · E3/E4 bonding & courage · E5 personality · C-series metabolism (hunger/thirst/clean) · F-series tack · S12 horseshoes |
| **Suffers** | H11 downed (headshot = instant) · H12 Horse Reviver items · H13 max health 150 · *future: illness, disease, treatment* |
| **Ages** | E6 ageing speed · age-reset items · S8 selling old horses |
| **Ends** | Age 31, or downed past the timer. Nothing else. |

## Open decisions — for the lifecycle design session

1. **⏳ Time scale — the big one.** How long is a horse-year? Real-world hours? In-game days? Server-uptime? This single number decides whether the lifecycle is a *feature* players actually experience or a number they never see. A horse that takes 300 real hours to reach 31 is functionally immortal; one that ages out in a weekend is a treadmill.
2. **Stage boundaries.** At what age is a foal rideable? When is it "adult"? When "aged"?
3. **Does age cost anything before 31?** Declining stats/stamina, more spooking — or is 31 simply a cliff?
4. **Can an aged horse still breed?** (Decides whether old horses have a second career.)
5. **Age-reset items (E6).** These rewind age — do they make a horse immortal? Cap the number of uses, or make them rare/expensive?
6. **What happens to a dead horse's tack and inventory?** Lost, or returned to the stable?
7. **Foal representation** — [open question 12](02-FEATURES.md#open-feasibility-questions-drive-tech-prep-spikes). Does RDR2 even have foal peds? **This blocks the entire front of the arc** (N10 and G6). Needs the spike before Phase 3.

## Why it's worth doing properly

The lifecycle is what turns a horse shop into an **ecosystem**. Horses die, so the county needs breeders; breeding needs mares and stallions (N9 — chosen at purchase); trainers raise foals (N10/J23); old horses get sold on (S8). Every one of those is already on the feature list — the lifecycle is the thing that makes them *one system* instead of eight unrelated toggles.

**Sequencing:** the arc's *end* (downed/death, H11–H13) lands in Phase 2. Its *middle* (ageing, E6) lands in Phase 3. Its *beginning* (foals, breeding — G/G6/N10) lands in Phase 3–5. So the lifecycle is assembled across phases and must be designed **once, up front**, or the pieces won't meet.
