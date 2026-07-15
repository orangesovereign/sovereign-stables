# Milestone 1.4 Testing Checklist — Wagons, Tack & Transfer

> **The live checklist is the interactive Milestone 1.4 Ledger (pass/fail/skip + notes, progress bar, report builder, marks persist):**
> **https://claude.ai/code/artifact/c5eb610c-fd6f-411a-ab18-e05a117dc001**
> This file is the plain-text mirror kept in the repo for the permanent record.

**Written for:** anyone — no developer knowledge needed.
**What you need:** the 1.4 build, at least one horse owned, a MySQL tool, **a second player for Articles VII–VIII**, ~25 minutes.
**What to send back to Claude:** the generated report + any red F8 lines.

**This closes Phase 1.** When it passes, sovereign_stables has matched vorp_stables and everything after is *exceeding* it.

**Note:** Article II carries the three 1.3 lines that were never verified — including **X1 (the F8 console), which has never once been recorded across three rounds.**

## Art. I — Boot & health

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Deploy 1.4, `restart sovereign_stables` | no red errors | |
| B2 | `/stables_diag` | dependencies OK, Database OK, no config problems | |
| B3 | **Required:** run `sql/upgrades.sql` in MySQL (adds the new `sovereign_tack` table). **Pull the latest first — rewritten 2026-07-15** | no errors, and a final table with **two rows that both say YES**. If you ran the old version and it only mentioned `sex`, the tack table was **never created** — the old first statement threw *Duplicate column name 'sex'* and MySQL stopped the script there. **Both lines must read YES or Articles V/VI cannot work** | |

## Art. II — The 1.3 carry-over (never verified)

| # | Check | Expect | Result |
|---|---|---|---|
| C1 | Away from a stable, whistle (hold `H` / `/sovwhistle`) | horse appears **in front** (~8m), facing you, then trots over. On the ground | |
| C2 | `/sovdismiss` | it **walks away first**, vanishes only once clear (~4.5s). Not instant | |
| C3 | `/sovfollow` ×2, then tap `H` | follows, then holds ground; short tap does the same toggle | |
| X1 | **Open F8 now, leave it open all session.** Copy anything red | no red Lua errors. **Never captured — if nothing else here gets done, do this** | |

## Art. III — Buying a wagon (WG1 · WG13)

| # | Check | Expect | Result |
|---|---|---|---|
| G1 | Storefront → `Wagons` | column splits into **Yours** / **For sale**; badge counts | |
| G2 | Pick one → Request Purchase → name → Confirm | green card, money leaves, appears under Yours. **Name only — no gender** | |
| G3 | Try to buy a second (cap = 1) | refused, "You already keep 1 wagon(s) — your limit." No money moves | |
| G4 | MySQL `sovereign_wagons` | one row, your name, `is_default` = 1 | |
| G5 | MySQL `sovereign_ledger` | a `buy_wagon` row at the real price | |

## Art. IV — The wagon in the field (WG2 · WG9)

| # | Check | Expect | Result |
|---|---|---|---|
| V1 | `Bring It Round` *(no `/sovwagon` any more — stable only, your ruling)* | shop closes; wagon appears **in the stable yard** (Valentine -361.88, 805.78), on the ground. **Fixed round 1** — recheck | |
| V8 | **NEW — the wagon blip.** Wagon out → look at minimap. Then drive it | a blip that **follows it**, named after your wagon; **hides while driving**, returns when you step off (R★'s own `blip_mp_player_wagon`). ⚠️ entity-blip native unverified here — if no blip, check F8 for "BlipAddForEntity failed" | |
| V2 | Drive it | drives normally, is yours | |
| V3 | `/sovwagonaway` | "*<name>* is put away." | |
| V4 | Call it back immediately | "Give it a moment — Ns." (30s recall cooldown) | |
| V5 | **The real one:** call out → **damage it** → put away → call back. **Watch F8 while damaging** | comes back **still damaged**. ⚠️ **The F8 line matters more than pass/fail.** Round 1 read `GetEntityHealth` (a *ped* native) on a vehicle → constant → every save wrote full health. Nobody persists wagon health (vorp/bcc/coal), so no reference exists: this probes **all three** natives and logs `wagon health probe -> body=… engine=… entity=…` every 3s. **Paste one line undamaged + one wrecked** — whichever number MOVES is the right native | |
| V6 | MySQL `health` on that wagon; also F8 `wagon #N health <- …` | dropped; list shows e.g. "64% sound". The F8 line proves whether the **server** was told at all — 1000 every time = client still reading wrong; real number but MySQL disagrees = the write. Two different bugs | |
| V7 | *Optional/destructive:* destroy it outright, then call it back | "Your wagon is wrecked.", despawns, `health` = 0 — and it returns **battered at 150hp, not fresh**. Not deleted; repair is a later phase. **See Q3** | |

## Art. V — The tack room, owning (F1 · F5)

*Ruling under test: tack belongs to the **player**, not the horse.*

| # | Check | Expect | Result |
|---|---|---|---|
| T1 | Storefront → `Components` | category strip: **Saddles, Manes, Tails** — and only those three (see X3) | |
| T2 | Buy the Lumley McClelland saddle | money leaves; row becomes "**Yours — fit it to any horse** / Owned" | |
| T3 | Try to buy that same saddle again | refused — "You already own that…" **No money moves** | |
| T4 | MySQL `sovereign_tack` | one row keyed to your `charid` — **not** to a horse id | |
| T5 | Buy a mane and a tail | both land, each charged once; badge counts up | |

## Art. VI — The tack room, fitting (F1 · F5)

| # | Check | Expect | Result |
|---|---|---|---|
| A1 | `My Horses` → click a horse. `Components` → click your saddle | "fitted"; row reads **✓ Fitted** | |
| A2 | Watch the preview horse as you fit it | saddle appears **immediately**, no reopening | |
| A3 | Close shop, whistle that horse | comes out **wearing the saddle** | |
| A4 | **The real one:** `restart sovereign_stables`, whistle again | still wearing it | |
| A5 | **The ruling, tested:** fit that **same** saddle to a **different** horse you own | just works — **no second purchase, no charge** | |
| A6 | Click the fitted saddle again | "Removed."; comes off; **you still own it** | |
| A7 | MySQL `components` on that horse | JSON like `{"saddle":"saddle_mcclelland"}` = what it's *wearing*. Ownership stays in `sovereign_tack`. Two questions, two places | |

## Art. VII — Handing over a horse (transfer · "hat size")

*Phase 3's trainer custody transfer reuses this exact machinery.* **Needs two players.**

| # | Check | Expect | Result |
|---|---|---|---|
| R1 | A and B **standing together**. A whistles a horse, then `/sovgive <B's server id>` | A: "Offered *<name>* to *<B>*." | |
| R2 | Look at B's screen | a **sovereign_menus** panel: "A hand over / *<A>* wants to give you *<name>*" + Take it / Decline | |
| R3 | B presses **Take it** | both get a green card; the horse is B's | |
| R4 | Watch A's horse | it walks off and despawns from A's world | |
| R5 | Both open `My Horses` | in B's list, gone from A's; counts update | |
| R6 | MySQL `charid` + `sovereign_ledger` | `charid` now B's, `is_default` reset to 0, and **two** rows: `transfer_horse_out` (A) + `transfer_horse_in` (B) | |
| R7 | Hand a **wagon** over: `/sovgivewagon <id>` | identical; `transfer_wagon_out`/`_in` in the ledger | |

## Art. VIII — The guards (anti-abuse)

*All server-side — a modified client cannot argue with any of them.*

| # | Check | Expect | Result |
|---|---|---|---|
| Z1 | B presses **Decline** (or Esc) | "They said no."; **nothing moves**. Walking away is a no | |
| Z2 | Offer, then **walk far apart** before B answers | refused — "They walked off." / "Too far away." | |
| Z3 | `/sovgive 9999` | "Nobody is wearing that hat size." | |
| Z4 | `/sovgive <your own id>` | "You already own it." | |
| Z5 | Fill B's stable to cap, then offer | refused — "They have no room…". Checked on offer **and** again on accept | |
| Z6 | Offer, B ignores it 30s | lapses — "They never answered." — and A can offer again (not stuck) | |

## Art. IX — Two rulings needed

| # | Question | Result |
|---|---|---|
| Q1 | **Tack trade-in.** You said *"never re-buy what you own — adjust a tack and you pay only the difference."* I read that as a **trade-in** and built it: one piece per slot, a $60 saddle while owning a $40 one costs **$20** and the $40 one is gone. The alternative is a **collection**: every piece bought outright and kept, so you could keep a work saddle *and* a good one for different horses. Trade-in matches your words; collection matches owning a stable of different horses. **Which?** Config: `Config.TackRules.tradeInWithinSlot` | |
| Q3 | **NEW — what is a wrecked wagon?** You destroyed one and the stable handed you a fresh one — obviously wrong. The fix has two shapes and only you pick. **(a) Battered but yours** — comes back at 150hp, ugly, still yours. **(b) Wrecked means wrecked** — it can't leave the stable until repaired. (b) is the honest rule and probably where this belongs, **but there's no repair system yet**, so switching it on today permanently bricks any destroyed wagon with no way back. Shipping (a) until repair exists. **Rule:** (a) or (b)? And if (b), does repair go in Phase 2 with the care/health work? Config: `Config.WagonDamage.wreckedNeedsRepair` / `wreckedHealth` | |
| Q2 | **The wagon key.** RDR2 gives us `INPUT_WHISTLE` for horses — there is **no native equivalent for wagons**. So a wagon is called by `/sovwagon` or from the stable (what vorp_stables does), and `Config.Keys.callWagon = 'J'` is **not bound**. Leave it a command, or bind `J` anyway (accepting it only takes effect after a full *client* restart)? | |

## Art. X — Cleanup

| # | Check | Expect | Result |
|---|---|---|---|
| X2 | Look back at the F8 console | no red Lua errors all session. **Paste anything red, even if it looked harmless** | |
| X3 | *Note, not a test:* the tack room stocks 3 of 9 categories because only **11 component hashes are verified** — the ones the Phase 1 spike applied to a live horse and watched change. Saddlebags/horns/stirrups/blankets/bedrolls/lanterns/masks are empty **on purpose**: an unverified hash silently does nothing. Filling them is a content job. **Before Phase 2, or parked?** | |
