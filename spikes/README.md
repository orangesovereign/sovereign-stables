# Tech-prep spikes (throwaway)

Small, dependency-free RedM test resources that prove a native approach works **before** we build a phase on it. Delete once signed off; findings get recorded in `docs/02-FEATURES.md`.

## `sovereign_spikes` — Phase 1 gate (horse appearance + orbital camera)

**Run it with the checklist, not this file:**
- **Interactive ledger:** https://claude.ai/code/artifact/944cf025-acfa-4828-8ca1-329b87c9f153
- **Plain-text mirror:** [`docs/testing/PHASE1_SPIKE_CHECKLIST.md`](../docs/testing/PHASE1_SPIKE_CHECKLIST.md)

Quick start: copy `sovereign_spikes/` into `resources/`, add `ensure sovereign_spikes` to `server.cfg` (no dependencies), restart, join, open F8, then follow the ledger. Commands: `/spike_horse`, `/spike_coat <model>`, `/spike_mane [1-5]`, `/spike_tail [1-5]`, `/spike_saddle`, `/spike_clear`, `/spike_cam [radius] [deg/s]`, `/spike_camstop`.
