# Tech-prep spikes (throwaway)

Small, dependency-free RedM test resources that prove a native approach works **before** we build a phase on it. Delete once signed off; findings get recorded in `docs/02-FEATURES.md`.

## `sovereign_spikes` — Phase 1 gate (horse appearance + orbital camera)

### Install & run
1. Copy `spikes/sovereign_spikes/` into your server's `resources/`.
2. Add `ensure sovereign_spikes` to `server.cfg` (put it anywhere; it has no dependencies).
3. Start the server / restart the resource, join, and **open the F8 console** (all results print there).

### Test A — horse appearance
| Command | What it tests | What to look for |
|---|---|---|
| `/spike_horse` | spawns a frozen preview horse ~3m ahead | a grey Kentucky Saddler appears |
| `/spike_coat A_C_Horse_Turkoman_Gold` | coat = model swap | horse respawns as a gold Turkoman (proves coat is model-bound) |
| `/spike_mane 1` … `/spike_mane 5` | apply mane component at runtime | mane visibly changes (short/regular/long/braid/dreadlocks) |
| `/spike_tail 1` … `/spike_tail 5` | apply tail component | tail visibly changes |
| `/spike_saddle` | apply tack component | a saddle appears on the horse |
| `/spike_clear` | cleanup | preview horse removed |

**Report for each:** did it visibly change? Try mane/tail on the default grey horse first, then run `/spike_coat` to a different breed and retry — tell me if a preset that worked on one breed does nothing on another (that tells us how breed-specific components are).

### Test B — orbital camera
| Command | What it tests | What to look for |
|---|---|---|
| `/spike_cam` | orbit at radius 4, 25°/sec | smooth camera circling the horse, always centered on it |
| `/spike_cam 6 40` | wider, faster orbit | still smooth, no jitter/clipping |
| `/spike_camstop` | restore | camera returns to normal, player unfreezes |

**Report:** is the orbit smooth? Does it stay centered? Any stutter, clipping through the horse, or the camera failing to activate?

### After you report
I lock the confirmed approach into `client/` for Phase 1 and note anything that needs a workaround (e.g. body-size and shiny-coat, which are separate follow-up investigations — this spike deliberately covers only the coat/mane/tail/tack pipeline the storefront needs first). Then delete `sovereign_spikes`.
