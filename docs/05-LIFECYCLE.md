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
7. **A foal is the same horse, scaled down, and unmountable.** At 5 it auto-scales to the breed's default size. No special foal ped — one model, grown in stages.
   - **✅ Feasibility CONFIRMED** (owner, 2026-07-15): ped scaling is proven — the owner runs servers that scale horses, and the owned `sirevlc_horses` config does exactly this (`BREEDING_SCALE_MULTIPLIER_PHASE_1/2/3 = 0.75 / 0.80 / 0.90`, described as *"Ped scale multiplier applied when the foal is in phase 1"*, plus a per-breed `SCALE` of `0.90`–`1.0`). No spike needed; only the exact native remains to be named at build time.
   - **Grow in phases, not one jump** — the foal visibly steps up in size over its 2.3–4.6 days rather than popping to full size at 5.
   - **Scale is a MULTIPLIER of the breed's base scale, never absolute.** A mule's base is `0.90`; a flat foal scale would be wrong for every breed that isn't `1.0`. → `foal size = breed.scale × phase multiplier`. Our catalog therefore needs a per-breed `scale` field.
8. **Foals may be trained, fed and watered.** The *only* thing they can't do is **fear/courage training** (E4).
9. **Decline is speed + stamina, and it starts at 27** — **25 for the faster breeds**. Not before.
10. **Stables only sell horses aged 5–7.** Anything older exists **only in the wild**. Stock horses are **moderately priced**.
11. **Age-reset items: once per horse, per lifetime.** Hard to obtain by design. So a horse can be rewound *once* — it is a reprieve, not immortality.
12. **Breeding window: 5 → 28.** A horse can breed from the day it's an adult until three years before it dies.
13. **Stats are predetermined from birth to death** — **Acceleration, Speed, Stamina, Turn**. A foal is *not* statistically weaker than its adult self; the numbers are set at birth and don't grow with age. (Late-life decline at 27/25 is the one exception, and only touches speed + stamina.)
14. **The configured stat is the FULLY TRAINED value.** A stock horse reading `6` is a 6 *when trained*. **Untrained it sits 1.5–2 lower** (~4–4.5), and training closes the gap up to its ceiling. The ceiling never moves.

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

**Also settled:** ~~foal stats~~ (full from birth, #13) · ~~aged breeding~~ (5→28, #12) · ~~age-reset immortality~~ (once per lifetime, #11).

1. **Which breeds are "faster breeds"** (decline at 25)? → **[06-BREEDS](06-BREEDS.md) recommends Arabian, Thoroughbred, Turkoman** — the only speed-9 breeds, with a three-point gap to the next tier. Awaiting ruling.
2. **Is there a floor to the decline?** A 31-year-old is about to die anyway, but should speed/stamina bottom out at, say, 60% rather than trending toward zero? An ancient horse should be *clearly past it*, not unusable.
3. **What happens to a dead horse's tack and inventory?** Lost, or returned to the stable?
4. **"Moderately priced" stock** — needs a number when the 60+ breed catalog (M1) gets filled. Current placeholders: Kentucky $130, Ardennes $180, Mule $60, vs the Vesper specialty at $3,200.
5. **Training curve** — how long does closing the 1.5–2 untrained gap take, and via which activities (E1)?

## The stat model (rulings #13–14, revised 2026-07-15)

| | |
|---|---|
| **The five stats** | **Health · Stamina · Speed · Acceleration · Turn** — predetermined at birth, fixed for life |
| **Scale** | **0–100** (kept) |
| **Max health** | **100** — *revised down from 150* |
| **Courage** | *Separate*, trainable (E4) — and the one thing a foal may **not** train |
| **Configured value** | the **fully trained ceiling** |
| **At birth/purchase** | ceiling **− the untrained gap** (see the open question below) |
| **Training** | closes the gap up to the ceiling; never past it |
| **Age** | only late decline (27 / 25 fast), **speed + stamina only** |

✅ Keeping 0–100 means **the storefront stat bars need no rescaling** — they already render 0–100. The only config change is **adding `turn`**.

### ❓ Open: how big is the untrained gap on a 0–100 scale?

The ruling was *"a stock horse may read as a 6 — that's the fully trained stat; untrained it's lowered by 1.5 to 2."* That was said while we were looking at a **1–10** scale (sirevlc's), where 6 → ~4–4.5 is a **25–33% haircut** — a big, meaningful gap that training visibly closes.

On a **0–100** scale, taken literally, "−1.5 to 2" means a trained **60 → untrained 58**. That's invisible, and training would be pointless.

**Almost certainly the intent is the proportional equivalent: −15 to −20 points** (trained 60 → untrained 40–45). Needs confirming before the catalog fill — get it wrong and 60 breeds carry the wrong numbers.

## Damage model (ruling, 2026-07-15)

| | |
|---|---|
| **Max health** | 100 |
| **Headshot** | **instant down** (H11) — same as players |
| **Limb / arm / backside** | must **not** bottom out health — peripheral hits do proportionally little damage |
| **Vitals** | do a lot |

**"A shot in the arm or backside shouldn't bottom out a horse."** So damage is **locational**, not a flat pool (H14): where you're hit matters as much as how often. This is what makes the downed state (H11) a *tactical* system rather than a health bar — you can wing a horse without killing it, and a clean headshot ends it.

## Spikes this pillar needs

| Spike | Why | Before |
|---|---|---|
| ~~**Ped scaling**~~ — **CLOSED ✅, no spike needed.** Proven by the owner's own servers and the owned `sirevlc_horses` config (foal phase scale multipliers + per-breed base `SCALE`). Only the exact native needs naming at build time; it is no longer a design risk. | — | — |
| **Horse blip modifiers** — `BLIP_MODIFIER_PLAYER_HORSE_IN_RANGE_WHISTLE`, `BLIP_MODIFIER_HORSE_REVIVE`, `BLIP_MODIFIER_MP_DOWNED` / `BLIP_AMBIENT_PED_DOWNED` | Found in the RPF reference — the base game **already has** a horse blip that pulses in whistle range, a horse-revive blip, and downed-state blips. These map directly onto D10/D11 (blip + whistle) and H11/H12 (downed + reviver). Use Rockstar's, don't invent ours. | 1.3 / Phase 2 |

## Why it's worth doing properly

The lifecycle is what turns a horse shop into an **ecosystem**. Horses die, so the county needs breeders; breeding needs mares and stallions (N9 — chosen at purchase); trainers raise foals (N10/J23); old horses get sold on (S8). Every one of those is already on the feature list — the lifecycle is the thing that makes them *one system* instead of eight unrelated toggles.

**Sequencing:** the arc's *end* (downed/death, H11–H13) lands in Phase 2. Its *middle* (ageing, E6) lands in Phase 3. Its *beginning* (foals, breeding — G/G6/N10) lands in Phase 3–5. So the lifecycle is assembled across phases and must be designed **once, up front**, or the pieces won't meet.
