# Credits & Third-Party Notices

Sovereign Stables is original code. These are the outside works it draws on, and
what we owe each of them.

---

## vorp_stables (VORPCORE/vorp_stables-lua) — MIT

**Used for:** the horse **component hash tables** in `config/tack.lua` — saddles,
saddlebags, saddle horns, stirrups, blankets, bedrolls, lanterns, masks, manes
and tails (479 hashes across 66 families), together with the relative price
multipliers those families ship with.

**Why this is the right source rather than a guess:** these are RDR2's own metaped
component ids — facts about the game, not authored content — and they are
independently corroborated. Every one of the **eleven** hashes our Phase 1 spike
applied to a live horse and watched change appears in that table as the first
variant of its family (`0x106961A8` = Lumley McClelland; our five manes and five
tails likewise). Two sources agreeing is why the table is trusted rather than
merely copied. Guessing a component hash is worse than useless: a wrong one
applies silently and looks like nothing happened.

**Scope:** data only. No vorp_stables code, structure or UI is used —
`sovereign_stables` is a from-scratch replacement, and its own catalog schema,
ownership model (tack belongs to the player, not the horse) and apply pipeline
are ours.

vorp_stables is also the documented **parity baseline** for this project; see
[`01-BASELINE-vorp_stables.md`](01-BASELINE-vorp_stables.md).

```
MIT License

Copyright (c) 2023 CrimsonFreak

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## coal_stables — Santa Tollimus

**Permission:** the project owner confirms (2026-07-15) that coal_stables is
**free for developers to use** — its author wrote and shared it for other devs
while learning to develop himself.

> ⚠️ **Recorded because there is no licence file.** The distribution
> (`Coal_Stables demo-…`, `fxmanifest` author *"Santa Tollimus & ChatGPT 5.1"*)
> ships **no LICENSE, no README and no terms**, so the permission above rests on
> the owner's word rather than a written grant. That is enough for us to proceed,
> and it is written down here so a later session doesn't re-open the question —
> or wrongly assume a licence exists. If coal is ever published with explicit
> terms, replace this note with them.

**Used for:** **reference only — no code or data is copied.** Reading it settled
three natives we had scheduled as future spikes (see
[`PHASE1_SPIKE_FINDINGS.md`](PHASE1_SPIKE_FINDINGS.md)):

- `_SET_META_PED_TAG` (`0xBC6DF00D7A4A6819`) — the **tint pipeline** behind the
  owner's "colour changes" ruling, plus RDR2's 13 metaped palette names.
- `_SET_PED_SCALE` (`0x25ACFC650B65C538`) — **foal scaling**, clamped 0.70–1.50
  in coal, which corroborates sirevlc's 0.75–0.90 breeding multipliers.
- `SET_PED_DIRT_LEVEL` (`0x7A56D66C78D1AAB7`) and its clear-pass companions —
  which **answered open question 11**, a gate on Phase 2.

It also **independently corroborates our Phase 1 approach**: coal applies tack
with the same `0xD3A7B003ED343FD9` + `0xCC8CA3E88256E58F` + `0x283978A15512B2FE`
sequence our spike proved on a live horse.

Native ids and palette names are **facts about RDR2**, not authored content —
the same facts appear in any script that touches this system. Our implementation
of them is our own.

**Credit is given here regardless of licence, because it's owed.** Naming three
natives saved this project two spikes and a phase gate.

---

## bcc-stables (BryceCanyonCounty) — GPL-3.0 🚫 RULED OUT

> ### ⚖️ OWNER RULING, 2026-07-15: **"I don't want it GPL at the moment."**
>
> **Nothing from bcc-stables may be copied into this resource — not code, not
> config, not data tables.** This is settled, not pending. If a future session
> finds a hash or a category it wants and notices bcc has it: **the answer is
> still no** unless the owner reverses this in writing.

**Why it matters:** GPL-3.0 is **copyleft**. Copying its code *or its data tables*
would oblige sovereign_stables to be released **entirely under GPL-3.0** — full
source published, and anyone free to take, modify and redistribute it, competing
servers included. This project is the owner's competitive edge; that is a
business decision, and it has been made.

**What the ruling costs us, stated honestly** — 910 component hashes, of which
**478 are already covered** by our MIT table, so **~432 are foregone**, plus four
categories we do not have:

| Category | Where it hurts |
|---|---|
| **Horseshoes** | **S12 is on our own roadmap (Phase 3)** — needs an independent source |
| **Bridles** | a real tack slot we simply lack |
| Holsters | **coal_stables has these** (free-for-devs) — coverable |
| Mustaches | cosmetic; no source yet |

**Status:** read for ideas only. Ideas are not copyrighted, and reading a GPL
project to understand *how* something is done — then writing our own — is
legitimate and unrestricted. Only copying is barred.

**The gaps get sourced elsewhere:** `coal_stables` (permitted, see above) covers
holsters and adds cantles/genitals; horseshoes and bridles need a permissive
source or our own extraction before S12.

---

## femga/rdr3_discoveries

**Used for:** reference only — native ids, control hashes, tutorial-flag and
event tables, animal tuning params, blackboard values, animation and scenario
names. Nothing is copied into this resource; it is read the way documentation is
read. Findings we rely on are recorded in
[`PHASE1_SPIKE_FINDINGS.md`](PHASE1_SPIKE_FINDINGS.md).

---

## sirevlc_horses (owned, escrow-locked)

**Used for:** its **open `CONFIG/*.lua` files only**, as a feature and schema
reference — the breed roster behind [`06-BREEDS.md`](06-BREEDS.md), the foal
scale multipliers behind [`05-LIFECYCLE.md`](05-LIFECYCLE.md), and the tack
category shape (tint slots + a customisable flag per item).

**Its FXAP-protected Lua is never read or copied**, and nothing here is derived
from it. Its tack config references components by an internal `TYPE` index whose
mapping lives inside that protected code — which is precisely why the component
hashes above come from an MIT-licensed source instead.

---

## Assets

**No RDR2 assets are extracted, redistributed or shipped.** The catalog is
model-agnostic: it references models and components **by id only** and never
contains the asset itself. Community coat packs install as their own stream
resources under their own licences; see the Assets & coats policy in
[`00-README.md`](00-README.md).
