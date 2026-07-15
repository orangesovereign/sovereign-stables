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
