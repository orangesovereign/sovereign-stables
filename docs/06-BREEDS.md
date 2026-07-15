# 06 · Breed Roster & Speed Tiers

> Built for one decision: **which breeds are "faster breeds"** and so begin their decline at **25** instead of **27** (E8, see [05-LIFECYCLE](05-LIFECYCLE.md)).
>
> **Source:** the **153 unique horse models** in the owned `sirevlc_horses` `CONFIG/BREEDS.lua` (an open config, reference only — no protected code touched), reduced to breed families. Stats below are **sirevlc's** numbers on a 1–10 scale, *not* RDR2's published figures — treat them as a well-informed proxy, not gospel. They track the canon closely (the race breeds top out, the drafts bottom out), which is why they're good enough to decide on.

## The roster — ranked by speed

| Breed | Speed | Accel | Stamina | Turn | Character |
|---|---|---|---|---|---|
| **Arabian** | **9** | 7 | 8 | 8 | Elite racer |
| **Thoroughbred** | **9** | **8** | **9** | 7 | Pure racer — fastest overall |
| **Turkoman** | **9** | **8** | 8 | 8 | Elite war/race |
| Kentucky Saddler | 6 | 5 | 5 | 5 | Standard riding |
| Tennessee Walker | 6 | 5 | 5 | 5 | Standard riding |
| American Standardbred | 6 | 5 | 5 | 6 | Standard riding |
| Andalusian | 6 | 5 | 6 | 7 | Standard / war |
| Nokota | 6 | 5 | 6 | 6 | Standard |
| Missouri Fox Trotter | 6 | 6 | 7 | 6 | Superior all-rounder |
| Mustang | 6 | 5 | 8 | 8 | Hardy, brave (courage 9) |
| Kladruber | 6 | 4 | 5 | 3 | Standard |
| Morgan | 6 | 2 | 5 | 5 | Quick but no launch |
| American Paint | 5 | 7 | 5 | 7 | Nimble, punchy |
| Appaloosa | 5 | 5 | 6 | 6 | Standard |
| Criollo | 5 | 3 | 5 | 5 | Modest work |
| Norfolk Roadster | 5 | 2 | 4 | 5 | Standard |
| Gypsy Cob | 4 | 2 | 5 | 4 | Work |
| Suffolk Punch | 4 | 2 | 6 | 4 | Draft |
| Belgian | 3 | 2 | 6 | 3 | Draft |
| Dutch Warmblood | 3 | 4 | 5 | 4 | Work |
| Hungarian Halfbred | 3 | 4 | 5 | 4 | Work |
| **Ardennes** | 2 | 2 | 6 | 3 | Heavy draft |
| **Breton** | 2 | 2 | 4 | 3 | Heavy draft |
| **Shire** | 2 | 2 | 5 | 2 | Heaviest draft |
| Mule | — | — | — | — | Pack animal (base scale **0.90**) |

*Story/special models also exist in the roster (Buell, Eagle Flies, John's horse, the gang horses, Murfree Brood mange, MP mangy). They are not stable stock and are excluded.*

## The tiers this produces

The data cuts itself into three clean bands with **no argument at the edges**:

| Tier | Speed | Breeds |
|---|---|---|
| 🏇 **Race / Fast** | **9** | **Arabian · Thoroughbred · Turkoman** |
| 🐎 **Standard riding** | 5–6 | Kentucky Saddler · Tennessee Walker · American Standardbred · Andalusian · Nokota · Missouri Fox Trotter · Mustang · Kladruber · Morgan · American Paint · Appaloosa · Criollo · Norfolk Roadster |
| 🐴 **Work / Draft** | 2–4 | Gypsy Cob · Suffolk Punch · Belgian · Dutch Warmblood · Hungarian Halfbred · Ardennes · Breton · Shire · (Mule) |

## ⚖️ RULED — the "faster breeds" (owner, 2026-07-15)

### **Arabian · Thoroughbred · Turkoman** — decline begins at **25** instead of 27.

They are the only breeds at speed **9**, with a **three-point gap** down to the next tier. That makes the rule self-evident to players — *the racehorses burn brighter and shorter* — and keeps the exception rare enough to read as a trait rather than a tax.

**Config:** `declineAge` on each horse — `27` by default (in `Config.HorseDefaults`), overridden to `25` on these three breeds. Death is always 31 regardless.

*Considered and rejected: Missouri Fox Trotter (best all-rounder, but "superior" ≠ fast), American Paint (sprinter's accel/turn, only speed 5), Mustang (hardy, not fast).*

## Caveats worth knowing

1. **These are sirevlc's stats, not RDR2's.** They're a proxy. If you want the decision made on the game's published figures, that's a separate pass — but the race/draft extremes are so pronounced that the top tier won't change.
2. **A few look off against RDR2 canon.** Dutch Warmblood and Hungarian Halfbred sit at speed 3 here, which reads low for what the game treats as war horses; the Morgan's accel of 2 with speed 6 is odd. None of it affects the speed-9 tier.
3. **Our own stats are the ones that matter.** This roster informs the decision; the numbers we ship live in `config/horses.lua` and are ours to set.
