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

## ⚖️ Rulings — owner, 2026-07-15

1. **The clock runs on WALL TIME.** A horse ages whether you are logged in or not. This is what keeps the loop alive: horses turn over, so breeders have a market. The tax on casual players is deliberate and is answered by **age-reset items** (E6) and **selling on** (S8), not by freezing the clock.
2. **Rate: ~2.3 real days per horse-year** — calibrated from the owner's number, 4 → 31 in **62 real days** (27 years). Store the *rate*, not the 62.
3. **Foals are 3–4 years old** when bought or bred — never younger than 3, never older than 4.
4. **A foal becomes an adult at 5.**
5. **Death at 31** — or downed too long (H11). Nothing else.
6. **Stats quietly decline with age.** Horses get old; horses slow down. No announcement — the numbers just drift.

## Stages

| Stage | Age | Rideable | Breedable | Notes |
|---|---|---|---|---|
| **Foal** | **3 → 5** | **?** | **no** (assumed) | Bred (G) or bought by a Horse Trainer only (N10/J23). Enters life at 3–4, so it is a *green youngster*, not a newborn. |
| **Adult** | **5 → ?** | yes | yes | The working life: ride, train (E1–E4), tack, haul. Peak condition. |
| **Aged** | **? → 31** | yes | **?** | Stats quietly declining (E8). Sell it on while it still has value (S8). |
| **Dead** | **31** | — | — | Permanent. The only other permanent death is downed-too-long (H11). |

## The timeline this produces

At **2.3 real days per horse-year**:

| Span | Horse-years | Real time |
|---|---|---|
| Ages ~**3 years** per real **week** | 3 | 7 days |
| **Foal (3) → adult (5)** | 2 | **~4.6 days** |
| **Foal (4) → adult (5)** | 1 | **~2.3 days** |
| **Adult (5) → death (31)** | 26 | **~60 days** |
| **Full arc: 3 → 31** | 28 | **~64 days** (~9 weeks) |
| Owner's calibration: 4 → 31 | 27 | **62 days** ✔ |

**~3 years a week is perceptible** — a player watches the number move in the codex. That was the risk with ageing (an invisible stat); this clears it.

**The trainer's business is short and fast:** a foal is only **2.3–4.6 real days** off being a rideable adult. That's a quick turn — buy green, hold a few days, sell broken. Fast enough to run several at once, which suits a job rather than a hobby.

## How every feature maps onto the arc

| Phase of life | Features |
|---|---|
| **Born** | G1–G6 breeding + genetics (inherits from sire/dam) · N10/J23 buy a foal (Horse Trainer only) |
| **Grows** | G6 foal → adult growth |
| **Works** | E1/E2 activity levelling · E3/E4 bonding & courage · E5 personality · C-series metabolism (hunger/thirst/clean) · F-series tack · S12 horseshoes |
| **Suffers** | H11 downed (headshot = instant) · H12 Horse Reviver items · H13 max health 150 · *future: illness, disease, treatment* |
| **Ages** | E6 ageing speed · age-reset items · S8 selling old horses |
| **Ends** | Age 31, or downed past the timer. Nothing else. |

## Open decisions — still to settle

**Settled:** ~~time scale~~ (wall time, 2.3 days/year) · ~~stage boundaries~~ (foal 3–4, adult at 5, dead at 31) · ~~does age cost anything~~ (yes — stats quietly decline, E8).

1. **Where does the decline start, and how steep?** (E8) "Horses slow down" needs a curve. A horse bought at 5 has ~60 real days of life; if decline begins at 15 it spends **60% of its life declining**, which reads as punishing. Starting around **20** gives roughly 34 days at peak and 25 declining — a long prime, then a visible twilight. **Proposed: peak 5–20, decline 20 → 31.** Needs a ruling.
2. **Which stats decline, and is there a floor?** "Horses slow down" points at **speed / acceleration / stamina**. Does **health** drop too (making old horses fragile), and does everything bottom out at some floor, or trend toward zero? A 30-year-old shouldn't be unusable — just clearly past it.
3. **Are foals rideable at 3–4?** Since a "foal" here is a green 3–4-year-old rather than a newborn, this is genuinely open — a 3yo *can* be backed in reality. If yes, the trainer's job is "green but rideable"; if no, it's "hold it a few days, then it's usable."
4. **Do foals have weaker stats** that grow into their adult numbers, or full stats from the start?
5. **Do purchased adults start at their catalog age?** The catalog currently sells Vesper at 6, the Ardennes at 7, the Mule at 8 — which would give them **different remaining lifespans** (57, 55, 53 days). Characterful, but then **an older horse should cost less** than a younger one of the same breed. Or: all adults start at 5 and the catalog ages become pure flavour.
6. **Can an aged horse still breed?** (Decides whether old horses have a second career, and whether declining stats are inherited.)
7. **Age-reset items (E6).** They rewind age — do they make a horse immortal? Cap the uses per horse, or make them rare/costly? This is the pressure valve for the wall-clock ruling, so it matters.
8. **What happens to a dead horse's tack and inventory?** Lost, or returned to the stable?
9. **Foal representation** — [open question 12](02-FEATURES.md#open-feasibility-questions-drive-tech-prep-spikes). Now *much less scary*: a "foal" is a 3–4-year-old, so it may simply be a normal horse model (possibly scaled), not a special foal ped. Still needs the spike before Phase 3 — but the ruling has likely de-risked the whole front of the arc.

## Why it's worth doing properly

The lifecycle is what turns a horse shop into an **ecosystem**. Horses die, so the county needs breeders; breeding needs mares and stallions (N9 — chosen at purchase); trainers raise foals (N10/J23); old horses get sold on (S8). Every one of those is already on the feature list — the lifecycle is the thing that makes them *one system* instead of eight unrelated toggles.

**Sequencing:** the arc's *end* (downed/death, H11–H13) lands in Phase 2. Its *middle* (ageing, E6) lands in Phase 3. Its *beginning* (foals, breeding — G/G6/N10) lands in Phase 3–5. So the lifecycle is assembled across phases and must be designed **once, up front**, or the pieces won't meet.
