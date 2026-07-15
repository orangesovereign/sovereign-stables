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
7. **A foal is the same horse, scaled down, and unmountable.** At 5 it auto-scales to the breed's default size. No special foal ped — one model, two sizes.
8. **Foals may be trained, fed and watered.** The *only* thing they can't do is **fear/courage training** (E4).
9. **Decline is speed + stamina, and it starts at 27** — **25 for the faster breeds**. Not before.
10. **Stables only sell horses aged 5–7.** Anything older exists **only in the wild**. Stock horses are **moderately priced**.

## Stages

| Stage | Age | Mountable | Breedable | Notes |
|---|---|---|---|---|
| **Foal** | **3 → 5** | **no** | **no** (assumed) | Bred (G) or bought by a Horse Trainer only (N10/J23). A *green youngster*, not a newborn. Rendered as the **same model, scaled down**. May be trained, fed and watered — **but not fear-trained** (E4). |
| **Adult** | **5 → 27** | yes | yes | Auto-scales to full size at 5. The long working prime: ride, train, tack, haul. **Stables only sell horses in the 5–7 window.** |
| **Aged** | **27 → 31** | yes | **?** | Speed + stamina quietly declining (E8). *Faster breeds start declining at **25**.* Sell it on while it still has value (S8). |
| **Dead** | **31** | — | — | Permanent. The only other permanent death is downed-too-long (H11). |

**Older than 7? Only in the wild.** The stable trade is young horses; an 11-year-old is something you catch, not something you buy.

## The timeline this produces

At **2.3 real days per horse-year**:

| Span | Horse-years | Real time |
|---|---|---|
| Ages ~**3 years** per real **week** | 3 | 7 days |
| **Foal (3) → adult (5)** — scaled down, unmountable | 2 | **~4.6 days** |
| **Foal (4) → adult (5)** | 1 | **~2.3 days** |
| **Prime: bought at 5 → decline at 27** | 22 | **~50 days** |
| **Twilight: 27 → death 31** | 4 | **~9 days** |
| *Fast breeds — prime 5 → 25* | 20 | *~46 days* |
| *Fast breeds — twilight 25 → 31* | 6 | *~14 days* |
| **Adult (5) → death (31)** | 26 | **~60 days** |
| **Full arc: 3 → 31** | 28 | **~64 days** (~9 weeks) |
| Owner's calibration: 4 → 31 | 27 | **62 days** ✔ |

**A horse spends ~85% of its life in its prime** (~50 of ~60 days), then fades over a visible ~9-day twilight. That's a far gentler shape than the "decline from 15" I proposed — the horse is *good* for almost all the time you own it, and old age is a short, poignant ending rather than a long tax.

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

**Settled:** ~~time scale~~ (wall time, 2.3 days/year) · ~~stage boundaries~~ (foal 3–4, adult 5, dead 31) · ~~does age cost anything~~ (yes, E8) · ~~where decline starts~~ (27; 25 fast breeds) · ~~which stats~~ (speed + stamina) · ~~are foals rideable~~ (no — unmountable) · ~~foal representation~~ (same model, scaled down) · ~~purchased adult ages~~ (5–7 only; older is wild-only).

1. **Which breeds are "faster breeds"** (decline at 25 instead of 27)? Needs a per-breed flag in `config/horses.lua` — Arabian/Turkoman/Thoroughbred are the obvious candidates, but it's your call which ones pay for their speed with a shorter prime.
2. **Is there a floor to the decline?** A 31-year-old is about to die anyway, but should speed/stamina bottom out at, say, 60% rather than trending toward zero? An ancient horse should be *clearly past it*, not unusable.
3. **Do foals have weaker stats** that grow into their adult numbers, or full stats from the start (just unmountable)?
4. **Can an aged horse still breed?** (Decides whether old horses have a second career — and whether declining stats get inherited.)
5. **Age-reset items (E6).** They rewind age — do they make a horse immortal? Cap uses per horse, or make them rare/costly? This is the pressure valve for the wall-clock ruling, so it matters.
6. **What happens to a dead horse's tack and inventory?** Lost, or returned to the stable?
7. **"Moderately priced" stock** — needs a number when the 60+ breed catalog (M1) gets filled. Current placeholders: Kentucky $130, Ardennes $180, Mule $60, vs the Vesper specialty at $3,200.

## Spikes this pillar needs

| Spike | Why | Before |
|---|---|---|
| **Ped scaling** — can we scale a horse ped down and back up at runtime? | The foal ruling depends on it entirely. **Not present in the local `rdr3_discoveries` reference**, so it must be confirmed, not assumed. If scaling proves impossible we need a fallback (a genuinely smaller model, or foals stay full-size and are simply unmountable). | Phase 3 |
| **Horse blip modifiers** — `BLIP_MODIFIER_PLAYER_HORSE_IN_RANGE_WHISTLE`, `BLIP_MODIFIER_HORSE_REVIVE`, `BLIP_MODIFIER_MP_DOWNED` / `BLIP_AMBIENT_PED_DOWNED` | Found in the RPF reference — the base game **already has** a horse blip that pulses in whistle range, a horse-revive blip, and downed-state blips. These map directly onto D10/D11 (blip + whistle) and H11/H12 (downed + reviver). Use Rockstar's, don't invent ours. | 1.3 / Phase 2 |

## Why it's worth doing properly

The lifecycle is what turns a horse shop into an **ecosystem**. Horses die, so the county needs breeders; breeding needs mares and stallions (N9 — chosen at purchase); trainers raise foals (N10/J23); old horses get sold on (S8). Every one of those is already on the feature list — the lifecycle is the thing that makes them *one system* instead of eight unrelated toggles.

**Sequencing:** the arc's *end* (downed/death, H11–H13) lands in Phase 2. Its *middle* (ageing, E6) lands in Phase 3. Its *beginning* (foals, breeding — G/G6/N10) lands in Phase 3–5. So the lifecycle is assembled across phases and must be designed **once, up front**, or the pieces won't meet.
