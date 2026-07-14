# sovereign_stables

Stables, horses & wagons for the **Sovereign County RP** RedM server (VorpCore framework). A from-scratch replacement for `vorp_stables` — built to match it, then far exceed it, and designed for future expansion and cross-script integration.

> **Status:** Phase 0 (foundation) — not yet playable. See [`docs/`](docs/00-README.md) for the full plan.

## Highlights (target v1)

- Multiple independent stables with job restrictions, custom branded NUI storefront, live horse preview + orbital camera.
- Deep horse systems: metabolism (hunger/thirst), progression (leveling, bonding, courage), ageing, personality, tack, horseshoes.
- Wild horses, three taming minigames, black-market economy.
- Full breeding + genetics with foals, plus a job-locked **Horse Creator**.
- Wagons & carts: storage, health, wheel/dirt damage, crafting, work wagons.
- Model/coat-agnostic catalog — list any stock or community add-on breed/coat by name.

## Dependencies

`vorp_core`, `vorp_inventory`, [`sovereign_notify`](https://github.com/orangesovereign/sovereign-notify), [`sovereign_menus`](https://github.com/orangesovereign/sovereign-menus).

## Install

1. Ensure the dependencies above are started first.
2. Import `sql/install.sql` into your database.
3. Drop `sovereign_stables` into `resources/` and `ensure sovereign_stables` in `server.cfg`.
4. Configure everything in `config/` (heavily commented). Run `/stables_diag` in-game to check config + dependency health.

## Documentation

Planning & design docs live in [`docs/`](docs/00-README.md): baseline analysis, the living feature list, and the phased coding plan.

## Credits

Original work by Sovereign County RP. `sirevlc_horses` and `vorp_stables` were studied as feature/UX references only — no protected code or copyrighted assets are included.
