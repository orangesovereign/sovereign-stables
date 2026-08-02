# ChatGPT asset generation — copy-paste (detailed engraved emblems)

The icons in these designs are **detailed 19th-century engraved emblems**, not thin
line icons. Generate them as **high-detail raster PNGs on transparent backgrounds**,
one consistent hand across the whole set, then they get downscaled small and
optimized on my end. Use an **image model** (GPT-image / DALL·E-class). Generate
**one emblem per run**, re-pasting the MASTER STYLE block each time so the set stays
consistent.

Everything that is *chrome* (frames, stat bars, status pills, toggles, tables,
buttons, corner rules) is built in CSS from tokens — those are NOT generated. Only
the emblem art + crests + ornaments + the parchment texture are generated.

---

## MASTER STYLE block (prepend to EVERY emblem generation)

> A single emblem icon for **Sovereign Stables**, a premium Red Dead Redemption 2
> (1899 American West) stable-management game UI. Style: **detailed antique steel-
> engraving / bank-note emblem** — refined, ornate, hand-tooled, with fine internal
> detail and depth, in the spirit of saloon signage, cattle brands, and government
> ledger crests. Rendered as a **solid ivory/cream (#efe6cf) emblem on a fully
> transparent background** — monochrome, no color, no drop shadow, no background
> shapes, no circle/badge behind it unless specified. **Centered, filling ~80% of a
> square canvas, generous even margin.** Crisp, high-contrast, print-quality
> engraving detail — NOT flat minimalist line art, NOT a thin outline, NOT clip-art,
> NOT childish. Consistent stroke thickness and detail density so it matches a set.
> 1024×1024, transparent PNG. The emblem is:

Then append ONE subject line from the list below.

### Emblem subjects (run each with the MASTER STYLE block)
Nav / header:
1. `store` — an ornate western storefront with awning and signboard.
2. `horse-head` — a noble horse head in left profile, finely engraved mane.
3. `horse-run` — a galloping horse in full stride, engraved.
4. `saddle` — a tooled western stock saddle, three-quarter side view, horn + stirrup.
5. `wagon` — a four-wheel frontier work wagon, side profile, engraved woodwork.
6. `wagon-wheel` — a spoked wooden wagon wheel with iron hub.
7. `horseshoe` — a classic iron horseshoe with seven nail holes, opening down.
8. `ledger-book` — a bound ledger book with a horseshoe or $ on the cover.
9. `settings-gear` — an ornate cog with engraved teeth.

Stat-card medallion glyphs (same style; these sit centered inside colored circles):
10. `coin-dollar` — a stamped silver-dollar coin with $ and laurel edge.
11. `scales` — balance scales of justice/accounting.
12. `flag` — a small pennant flag on a staff.
13. `calendar` — an engraved page-a-day calendar.
14. `people` — two figures / a crowd bust motif.
15. `shield-badge` — a lawman's engraved shield with a star.
16. `archive-box` — a filing/records box.
17. `alert` — a warning triangle with an exclamation, engraved.
18. `person-detective` — a figure in a period hat (staff/employee motif).
19. `cart` — a small hand cart / delivery cart (ready-for-pickup motif).
20. `training-crop` — a horse mid-stride with motion (training) OR a riding crop.
21. `breeding-mark` — two horseshoes interlocked as a heraldic pairing mark.

Tack categories (same style):
22. `bridle` — a horse bridle/headstall.
23. `stirrup` — a single engraved stirrup.
24. `saddlebag` — a buckled leather saddlebag.
25. `blanket` — a folded patterned saddle blanket.
26. `horn` — a saddle horn detail.

Crests & seals (these MAY use gold instead of ivory — say so in the run):
27. `crest-diamond` — SC monogram + small crown inside a **diamond** heraldic frame;
    ornate engraving; **antique gold (#c19a3a)** on transparent. 1024².
28. `crest-laurel` — SC monogram + crown enclosed by a **laurel wreath**; antique gold
    on transparent. 1024².
29. `seal-1896` — a round county seal: double ring reading "SOVEREIGN COUNTY · 1896",
    laurel, SC center; antique gold on transparent. 1024².

Ornaments (ivory or gold, stroke-y but still refined — NOT crude):
30. `corner-filigree` — a single ornate **top-left** corner flourish of engraved
    scrollwork, to frame a panel corner (will be mirrored/rotated in CSS). Antique gold.
31. `divider-title` — a long slim horizontal engraved rule ending on the right in a
    small solid diamond and short arrowhead. Antique gold, wide aspect (e.g. 1024×64).
32. `divider-eyebrow` — a short symmetric flourish: hairline rules meeting a small
    center diamond (`—◆—`). Antique gold, wide aspect.

---

## Parchment texture (image model)

> Seamless tileable **aged cream parchment** texture, subtle natural fiber grain and
> faint even mottling, warm ivory (#efe6cf), **very low contrast** — a clean antique
> ledger page, NOT distressed. **No** stains, tears, burnt edges, folds, vignette,
> text, or shadow. Tiles seamlessly (no visible seam). Flat top-down scan. 512×512 PNG.

Deliver as `parchment-tile.png`. Verify the tile (offset 50%, check the seam).

---

## Delivery (how to send them to me)
- **Transparent PNGs**, 1024² (crests/emblems) — I downscale to the sizes each spot
  needs (emblems ~128px, crests ~256px) and run them through compression, so the
  final in-game set is small. Don't pre-shrink; send the crisp originals.
- **Monochrome ivory** for emblems/medallion glyphs (so I can tint them per medallion
  color via CSS mask); **antique gold** for crests + ornaments.
- Name each file exactly as its kebab-case id above (`horse-head.png`, `crest-laurel.png`).
- Consistent framing/margin so the set aligns; same engraving weight across all.

## What I still need from you
1. The emblem/crest/ornament PNGs above.
2. `parchment-tile.png`.
3. Font confirmation (Playfair Display / Cinzel / EB Garamond) or your swaps.
4. Catalog thumbnail decision (realistic horse/saddle/wagon card images) — generate
   per item, reuse portraits, or placeholder.

Tiny functional controls only (dropdown chevron, search magnifier, close ×, pager
arrows, checkbox tick, +/− steppers, the ••• menu) I'll render inline from tokens —
they're plain UI affordances the mockups also draw minimally, so they won't read as
"line-art icons." Everything decorative/emblematic comes from the engraved set above.
