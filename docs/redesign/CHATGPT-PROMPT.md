# ChatGPT asset generation — copy-paste

Two batches. **Batch A** = the county-specific SVG marks + ornaments (ChatGPT
returns SVG *code*, not images). **Batch B** = the one parchment texture (image).
Everything else in the design uses the Lucide icon library — do NOT ask ChatGPT to
draw those.

Use a capable text model (GPT-5 / GPT-4.1-class) for Batch A. Paste the **MASTER
PROMPT**, then the **ASSET LIST**, in one message. For Batch B use an image model.

---

## BATCH A — MASTER PROMPT (paste verbatim)

> You are producing a set of **SVG icon/emblem code** for a Red Dead Redemption 2
> (1899 American West) stable-management UI called **Sovereign Stables**. The style
> is **engraved heraldic line-work** — think saloon signage, cattle brands, and
> government-ledger engravings: confident, refined, geometric-but-organic, NOT
> cartoonish, NOT thin-and-generic, NOT clip-art.
>
> **Output rules — follow EXACTLY for every asset:**
> - Return **raw SVG code only**, each asset in its own ```svg fenced block, with a
>   line above it stating its `name`. No prose between blocks.
> - Root `<svg>` must have `viewBox` (as specified per asset) and **NO `width`,
>   `height`, `id`, `class`, `style`, `<title>`, or comments**.
> - **Line marks:** `fill="none"` `stroke="currentColor"` `stroke-width="1.75"`
>   `stroke-linecap="round"` `stroke-linejoin="round"`. Draw on the given grid with
>   ~2 units of padding. One coherent optical weight across the whole set.
> - **Solid emblems** (crests/seals): `fill="currentColor"`. If a crest truly needs
>   more than one tone, use at most 3 flat `fill` values and list them under the
>   block; otherwise keep it single-color so it tints via `currentColor`.
> - Geometry only — **no gradients, no filters, no raster `<image>`, no embedded
>   fonts**. If a mark contains letters (SC monogram), draw them as `<path>` outlines,
>   not `<text>`.
> - Keep paths clean and minimal (merge where sensible); it must read clearly at
>   **20px** and still hold at 64px.
> - Consistent motifs across the set: the same horseshoe opening, the same stroke
>   terminals, the same corner-radius language, so all 19 assets look like one hand.
>
> Confirm you understand the output format, then produce every asset in the ASSET
> LIST below, in order.

### ASSET LIST (paste after the master prompt)

**Line marks — `viewBox="0 0 24 24"`, stroke style:**
1. `horseshoe` — classic U horseshoe, 7 nail holes, opening downward.
2. `horse-head` — noble horse head in left side profile (bridle-free), from the neck up.
3. `horse-run` — a galloping horse silhouette reduced to clean line form.
4. `store` — a western shopfront/storefront (awning + door + sign board).
5. `saddle` — a western stock saddle, side view, with horn and stirrup.
6. `bridle` — a horse bridle/headstall with reins loop.
7. `stirrup` — a single stirrup.
8. `saddlebag` — a leather saddlebag with buckle flap.
9. `blanket` — a folded saddle blanket.
10. `horn` — a saddle horn detail (or a cattle horn — pick the saddle horn, western).
11. `wagon` — a four-wheel work wagon, side profile.
12. `wagon-wheel` — a spoked wagon wheel (8 spokes).
13. `breeding-mark` — two horseshoes interlocked (heraldic pairing mark).

**Emblems — solid fill:**
14. `crest-diamond` — `viewBox="0 0 64 64"` — a diamond (rotated square) frame with a
    small crown on top and an **SC** monogram centered inside; engraved/heraldic; the
    Sovereign County storefront crest.
15. `crest-laurel` — `viewBox="0 0 64 64"` — the same **SC** monogram + crown enclosed
    by a **laurel wreath** (two curved olive branches); the administration crest.
16. `seal-1896` — `viewBox="0 0 96 96"` — a circular county seal: laurel ring, **SC**
    center, `1896` and `SOVEREIGN COUNTY` implied by an outer double ring (draw the
    ring + laurel + monogram; text arcs may be omitted or drawn as simple tick marks).

**Ornaments — stroke style:**
17. `corner-filigree` — `viewBox="0 0 48 48"` — a single **top-left** corner flourish
    (thin engraved scrollwork hugging the corner); it will be rotated by CSS for the
    other three corners, so keep it anchored to the top-left.
18. `divider-title` — `viewBox="0 0 240 12"` — a long thin horizontal rule that ends on
    the right in a small solid diamond then a short arrowhead (`———◆—▸`); left end fades
    to nothing (just start the stroke).
19. `divider-eyebrow` — `viewBox="0 0 120 12"` — a short symmetric flourish: a hairline
    from each side meeting a small center diamond (`—◆—`), for wrapping small-caps
    eyebrow labels.

---

## BATCH B — parchment texture (image model)

> Seamless tileable texture of **aged cream parchment paper**, subtle natural fiber
> grain and faint mottling, warm ivory tone (#efe6cf), **very low contrast and even**
> — a clean antique ledger page, NOT distressed. Absolutely **no** stains, tears,
> burnt edges, folds, vignette, text, or drop shadow. Must tile seamlessly with no
> visible seam. Flat top-down scan look. 512×512, PNG.

After generating, verify it tiles (offset by 50% and check the seam). Deliver as
`parchment-tile.png`, under ~200 KB.

---

## What I need back from you (the owner), in order of usefulness
1. The 19 SVG blocks from Batch A (in-chat is fine; I'll paste them straight in).
2. `parchment-tile.png` from Batch B.
3. Confirmation of the **three fonts** (Playfair Display / Cinzel / EB Garamond) or
   your preferred swaps — I bundle whatever you name.
4. A decision on **catalog thumbnails** (realistic horse/saddle/wagon card images):
   generate per-item, reuse existing portraits, or placeholder for now.

With those, I build the token file + `<Icon>` set + `<FramedPanel>` and reskin the
existing React app screen-by-screen against these mockups — no visual guesswork,
because the marks, texture, tokens, and fonts are all pinned.
```
