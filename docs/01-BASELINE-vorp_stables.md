# 01 · Baseline Analysis — `vorp_stables-lua`

> The bar we must **match** before we can exceed. Source: `VORPCORE/vorp_stables-lua` (canonical current VORP stables, author CrimsonFreak). This is the feature floor for Sovereign Stables v1.

## What it is

A VorpCore stables resource: buy horses & wagons from stable vendors, store them, call them with a whistle, manage tack/equipment, and transfer rides to other players. React (Vite) UI, Lua client/server, MySQL persistence, horse & wagon inventories backed by `vorp_inventory`.

## File structure

| Path | Role |
|---|---|
| `config.lua` | Global options + per-stable vendor definitions |
| `data.lua` | Static catalogs: tack components (blankets, horns, saddlebags, tails, manes, saddles, stirrups, bedrolls, lanterns, masks), cart prices, horse prices |
| `languages.lua` | Locale strings (En, Fr) |
| `keys.lua` | Key hash constants |
| `events.lua` | Shared event-name constants |
| `deathReasons.lua` | Per-death-reason long-term-health damage table (hard death) |
| `Client/main.lua` | Core client loop, prompts, whistle, spawning |
| `Client/PlayerStable.lua` | Stable menu flow |
| `Client/horseinfo.lua` | Horse status/info |
| `Client/interactions.lua` | Focus interactions (brush, flee, follow, prance) |
| `Client/uiCallbacks.lua` | NUI callback routing |
| `Server/main.lua` | DB, purchases, persistence, transfers |
| `UI/` | React app (MainMenu, BuyRideMenu, BuyCompsMenu, MyRidesMenu, TransferMenu, TransferRecieve) |
| `Migration/` | Node script migrating old inventories into vorp_inventory |
| `stables.sql` | DB schema |

## Global config surface (must match or supersede)

- `MaxHorses`, `MaxCarts`, `StableSlots` — ownership caps
- `CallHorseKey`, `CallCartKey`, `FollowKey` — keybinds (H / J / E)
- `DisableBuyOption` — turn off buying entirely
- `JobRequired` + `JobForHorseDealer` / `JobForCartDealer` / `JobForAllDealer` — job-gated dealers
- `SecondsToRespawn` — dead-horse recall cooldown
- `HardDeath` + `LongTermHealth` (+ `deathReasons.lua`) — permanent death after cumulative damage
- `ShowTagsOnHorses` — floating name tags
- `HorseSkillPullUpFailPercent` — prance/rear fail chance
- `DistanceToTeleport` — auto-recall a stray ride that's too far
- `ShareInv` `{horse, cart}` — whether non-owners can open the inventory
- `StackInvIgnore` `{horse, cart}` — ignore stack limits in ride inventory
- `DefaultMaxWeight` + `CustomMaxWeight[model]` — per-model inventory capacity

## Per-stable (vendor) config surface

Each stable entry: `Name`, `BlipIcon`, `EnterStable` (x,y,z,radius), `StableNPC`, `SpawnHorse`, `SpawnCart`, `CamHorse`, `CamCart`, and per-vendor `horses = {}` / `carts = {}` catalogs. Vendor catalog accepts either `"MODEL"` (uses `data.lua` price) or `MODEL = price` (vendor-specific price). Empty catalog = sells everything.

## Feature floor (the "match" checklist)

1. Multiple stable locations, each a blip + prompt + ambient NPC.
2. Buy horses (cash) with per-vendor catalogs & pricing.
3. Buy wagons/carts with per-vendor catalogs & pricing.
4. Per-stable & global ownership caps (horses / carts / total slots).
5. Optional job requirement to buy (dealer jobs).
6. Store & retrieve horses/wagons at a stable.
7. Whistle/call default horse (H) and default wagon (J).
8. Set a default horse/cart.
9. Horse status persistence (`status` longtext), XP (`xp`), injury (`injured`).
10. Horse & wagon **inventories** via vorp_inventory, per-model weight caps, optional shared access, optional stack-limit bypass.
11. Tack / equipment: buy components (saddle, blanket, horn, saddlebags, stirrups, bedroll, lantern, mask, mane, tail) → stored in stable → "change equipment" menu applies them.
12. Horse component/appearance application (manes, tails, coats via complements table).
13. Focus interactions: brush (remove dirt), flee & despawn (F), follow (E), prance (Ctrl+Space).
14. Hard death / long-term health with per-reason damage; dead-horse respawn cooldown.
15. Auto-teleport/recall a ride that strays too far.
16. **Ride transfer** to another player (optional price); recipient accepts at a vendor.
17. Floating name tags toggle.
18. Multi-language locale system.
19. MySQL persistence: `stables` (id, identifier, charidentifier, name, modelname, type, status, xp, injured, gear, isDefault, inventory) + `horse_complements` (identifier, charidentifier, complements).

## Gaps vs. our vision (what "exceed" means)

vorp_stables has **no**: breeding/genetics, wild horses, taming minigames, hunger/thirst/metabolism, personality/behavior, ageing/death-by-age, bonding/courage, activity-based leveling detail, tethering/cleaning/hoof care, faction/shared stables, black-market economy, horseshoe upgrades, tack transfer between horses, follow/crash-recovery robustness, whistle vs stable-only summoning, wagon crafting/wheel-damage/dirt/work-wagons, or simulated spawn nodes. Those are the whole "exceed" surface — see `02-FEATURES.md`.

## Technical baseline decisions inherited (unless we choose otherwise)

- **DB:** MySQL via oxmysql-style queries (VORP standard).
- **Inventory:** `vorp_inventory` exports for horse/wagon storage & tack items.
- **Core:** `vorp_core` for character identity, money, jobs, notifications (we swap notify→`sovereign_notify`).
- **UI:** React NUI in baseline → **we replace with `sovereign_menus`** for menus; camera/preview stays native.
