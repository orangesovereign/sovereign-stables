# Sovereign Stables — Planning Docs

Replacement for `vorp_stables` on the Sovereign County RP RedM server (VorpCore). Match it, then exceed it. Built to integrate with `sovereign_notify` + `sovereign_menus` and designed for future expansion.

| Doc | Purpose |
|---|---|
| [01-BASELINE-vorp_stables.md](01-BASELINE-vorp_stables.md) | What vorp_stables does — the parity floor |
| [02-FEATURES.md](02-FEATURES.md) | **Living** master feature list w/ feasibility + phases |
| [03-CODING-PLAN.md](03-CODING-PLAN.md) | Phased build plan + architecture + resource layout |
| [04-UI-DESIGN.md](04-UI-DESIGN.md) | Storefront visual + IA spec (from approved concept art) |

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

**Status:** Phase 0 ✅ · Phase 1 spike gate ✅ PASSED · **Milestone 1.1 ✅ PASSED** 2026-07-14 ([ledger](https://claude.ai/code/artifact/07b8240a-3920-4d62-aa86-6fbef652450e) / `testing/MILESTONE_1.1_CHECKLIST.md`) — Valentine stable spine: blip, proximity-streamed stablehand grooming a re-rolling random horse, on-ped interact prompt, branded storefront with live orbital preview + browse. **Next: milestone 1.2 — buy → own loop** (server-authoritative purchase, DB persistence, caps, store/retrieve). Confirmed natives + gotchas: `PHASE1_SPIKE_FINDINGS.md`.
