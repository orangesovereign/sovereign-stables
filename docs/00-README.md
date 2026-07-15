# Sovereign Stables — Planning Docs

Replacement for `vorp_stables` on the Sovereign County RP RedM server (VorpCore). Match it, then exceed it. Built to integrate with `sovereign_notify` + `sovereign_menus` and designed for future expansion.

| Doc | Purpose |
|---|---|
| [01-BASELINE-vorp_stables.md](01-BASELINE-vorp_stables.md) | What vorp_stables does — the parity floor |
| [02-FEATURES.md](02-FEATURES.md) | **Living** master feature list w/ feasibility + phases |
| [03-CODING-PLAN.md](03-CODING-PLAN.md) | Phased build plan + architecture + resource layout |
| [04-UI-DESIGN.md](04-UI-DESIGN.md) | Storefront visual + IA spec (from approved concept art) |
| [05-LIFECYCLE.md](05-LIFECYCLE.md) | **Design pillar** — the horse arc, Foal → Death, and how every feature hangs off it |
| [06-BREEDS.md](06-BREEDS.md) | Breed roster + speed tiers — the data behind the "faster breeds" ruling |
| [07-HORSE-TRAINER.md](07-HORSE-TRAINER.md) | The Horse Trainer job, grades, and the tiered training system |

**Ground rules:** original code only (the owned `sirevlc_horses` pack is escrow-locked — its open config files are a *reference* only). Server-authoritative. Config-driven so a non-dev owner can tune everything.

**Language:** all game logic is **Lua** (`lua54`) — `client/`, `server/`, `shared/`, `config/`. No TypeScript/React/C#. The only non-Lua is the NUI paint layer in `ui/`, which *must* be HTML/CSS/JS (RedM renders NUI as a web page); it is kept minimal vanilla — no framework, no build step. Lua drives it via NUI messages/callbacks.

## Assets & coats policy

- **No asset extraction.** We never rip or ship RDR2's copyrighted files, nor crack another creator's protected/escrow pack. RedM streams stock assets from each player's own legal RDR2 install.
- **Catalog is model/coat-agnostic (design rule).** Nothing in the code hardcodes the stock breed roster. The config catalog can reference *any* horse model/coat installed on the server — stock RDR2 breeds **or** legitimately-obtained community add-on coats (which ship as their own `stream` resource). Our script references by model name/hash; it never contains the asset.
- **Community coats:** install the creator's resource → list its model in `config/horses.lua`. Respect each pack's license (server-use / redistribution terms); escrow-locked coats may be *referenced* but not copied into our resource. The Horse Creator (M2) can register installed community coats into buyable breeds at runtime.

## Locked decisions (2026-07-14)

1. **v1 scope = Everything (Phases 1–6)** — full premium framework incl. breeding/genetics, work wagons, crafting.
2. **Greenfield** — no existing vorp_stables player data to migrate. DB schema designed freely; migration (K8) is **optional/deferred**, not a v1 gate.
3. **Cadence = gate spikes + phases** — Claude checks in for approval before committing an approach on each risky tech-prep spike, and before starting each new phase.

**Status:** Phase 0 ✅ · Phase 1 spike gate ✅ · **Milestone 1.1 ✅ PASSED** ([ledger](https://claude.ai/code/artifact/07b8240a-3920-4d62-aa86-6fbef652450e)) — stable spine, grooming stablehand, branded storefront + live orbital preview · **Milestone 1.2 ✅ PASSED 16/16** 2026-07-14 ([ledger](https://claude.ai/code/artifact/c99403ce-30ed-4db3-b2a0-28da0d2e1038)) — server-authoritative buy→own, DB persistence, caps, anti-dupe, ledger, My Horses + default ride. · **Milestone 1.3 — summon & field ⚠️ BUILT, NOT GATE-PASSED** ([ledger](docs/testing/MILESTONE_1.3_CHECKLIST.md)) — whistle (native `INPUT_WHISTLE` tap/hold), follow, recall cooldown, dismiss, name tags, hard death. **Two changes remain unverified** (front-spawn 8m ahead; walk-off-then-despawn dismiss) and **X1 (F8 console) has never been captured across 3 rounds** — owner ruling 2026-07-15: *"skip the redeploy, add it to the next phase test."* **→ Milestone 1.4's ledger must absorb those lines.** **Next: milestone 1.4 — wagons · tack · transfer** (closes Phase 1 parity; the ride-transfer built here is what the trainer's custody transfer reuses in Phase 3). Confirmed natives + gotchas: `PHASE1_SPIKE_FINDINGS.md`.

> **Design status 2026-07-15:** design now runs **well ahead of the build**. Phases 2 and 3 are ruled in depth (death rework, dirt, lifecycle foal→death, the trainer job, the tier ladder, the training session, the repertoire, courage 0–9). **Milestone 1.4 needs no new design** — it's parity work ruled long ago. Two non-design gaps to clear inside 1.4: **`Config.Tack` is still empty** (a *content* fill — the spike proved the pipeline and 11 hashes: 5 manes, 5 tails, 1 saddle; a full catalog needs sourcing; sirevlc's open `CONFIG/TACK.lua` is a legit **schema** reference — 9 categories, per-stable availability, dollars+gold, tints, role/player locks) and **prices are placeholders pending the economy pass**.
