# 04 · UI Design — Storefront Spec (from concept art)

> Derived from the owner's approved concept image (2026-07-14). This is the **build target** for the custom branded NUI storefront (feature L1). Drop the source image at `docs/ui/concept-storefront.png` for reference.

## Art direction

A dark, cinematic **leather-and-wood** panel over a blurred, vignetted game view — the premium RDR2-menu feel, unmistakably Sovereign County but its own world, distinct from the lighter `sovereign_notify` / `sovereign_menus` chrome.

| Token | Value (approx — tune in build) | Use |
|---|---|---|
| `--bg-panel` | near-black warm brown `#1a1310` w/ leather texture | main panel fill |
| `--bg-raised` | `#241a15` | cards, list rows |
| `--oxblood` | `#5a1a1a` → `#3e1212` | active nav, primary buttons, ribbons |
| `--brass` | `#b08d4c` / `#c8a866` | dividers, icons, stat fills, hairline frames |
| `--parchment` | `#efe4cf` / `#d9cbb0` | primary/secondary text |
| `--ink-dim` | `#8a7career` muted | small caps labels, meta |
| frame | thin double **brass** border w/ corner flourishes + outer drop shadow + vignette | panel edge |

Type: high-contrast **serif** throughout — large letter-spaced serif for headers/names, small-caps serif for labels, italic serif for flavor/description. (Pick a self-hosted serif; embed as base64 in the NUI to satisfy no-external-assets.)

Layout: fixed 16:9 framed panel, centered, ~92% viewport, resolution-dynamic scaling. Four vertical regions: **left nav · catalog list · center stage · detail**, under a full-width **header**.

## Regions

### Header (full width)
- **Brand:** "SC" diamond emblem + `SOVEREIGN STABLES` / `STABLES & CARRIAGE CO.`
- **Location switcher:** 📍 `BLACKWATER STABLES ▾` — dropdown of stables the player may access (drives which catalog/collection shows).
- **Identity:** 👤 `TATE LOVE — STABLE HAND` (character name + job).
- **Wallet:** 💰 `$8,472` · 🪙 `24.6 GOLD` (live cash + gold).
- **Close:** `ESC ✕`.

### Left nav — "STABLE SERVICES"
Vertical items, active = oxblood fill + brass left-marker:
- `STABLEFRONT` (buy) — active
- `MY HORSES` + count badge (owned; badge = current/cap)
- `COMPONENTS` (tack & appearance)
- `WAGONS`
- Bottom: shield emblem `STABLE MANAGEMENT` / `TRAINER • GRADE 3` — the player's stables permission tier (job+grade). Gates management actions (locked catalog items, Horse Creator, etc.). *Note: concept shows job "Stable Hand" in header and "Trainer · Grade 3" here; we treat the header as the RP job label and this panel as the stables-permission tier resolved from config/jobs.lua.*

### Catalog column — "STABLE CATALOG"
- Headline (serif) `Find your better half.` + subtext flavor line. (Copy is per-stable configurable.)
- Ornate divider: `‹collection name› COLLECTION` (e.g. BLACKWATER COLLECTION).
- **Category tabs:** `SPECIALTY HORSES` | `STOCK HORSES` (see new feature N1).
- **Breed filter:** `ALL BREEDS ▾` dropdown + funnel icon (advanced filters).
- **List rows:** circular portrait · name (serif) · breed (small caps) · `$price or N GOLD`. Active = oxblood border/fill. Locked rows show a 🔒 (job/grade/other gate) and hide price.
- Footer: `4 / 12 HORSES` count + carousel context.

### Center stage — live preview
- The horse rendered in the stable environment (the real ped + orbital camera, not an image).
- Top hint: `⤢ DRAG TO ORBIT • SCROLL TO ZOOM` (L5 + zoom).
- `‹ ›` arrows cycle the catalog selection.
- Bottom: location pill + carousel dot indicator.

### Detail column — selected horse
- Optional promo ribbon: `★ TRAINER SALE ★` (see N5).
- Breed small-caps → large serif **name** (`VESPER`).
- Attribute row w/ icons: **sex** (Stallion), **age** (`6 YEARS`), **height** (`16.2 HH`).
- Italic **description / lore** paragraph.
- **Trait cards** (2+): icon · name · one-line · optional level badge — e.g. `STEADFAST` (lvl 1), `ENDURANCE`. Surfaces the personality/courage/bonding systems (E3–E5).
- **Stat bars** (segmented, brass fill): `HEALTH / STAMINA / SPEED / ACCELERATION` with numeric values. Map to RDR2 horse core stats.
- **Price** (large): `$3,200 or 🪙 12 GOLD`.
- **`REQUEST PURCHASE`** primary button (ornate oxblood).
- Footer: `INCLUDES OWNERSHIP PAPERS • STABLE SLOT REQUIRED` (registry X3 + slot cap).

## Data bindings (NUI ← Lua)
Each region binds to server-authoritative data pushed via NUI message:
`header{ stableLabel, stableList, charName, job, cash, gold }` ·
`nav{ owned, cap, permTier }` ·
`catalog{ collection, category, breeds[], rows[]={id,name,breed,portrait,cash,gold,locked,lockReason} }` ·
`detail{ name,breed,sex,age,heightHands,lore,traits[]={id,name,desc,level},stats={health,stamina,speed,accel},cash,gold,promo,ownershipPapers,slotRequired }`.
Portraits: pre-rendered per model (or a generated headshot) — decide in build; must respect no-external-assets (base64/local).

## Interactions
- Drag = orbit, scroll = zoom, arrows/list click = change selection, tabs/dropdown filter the list, `REQUEST PURCHASE` → server validates funds/slot/permission → `sovereign_notify` card result. Esc / ✕ closes with focus release.

## Features revealed by the concept (fold into 02-FEATURES §N)
- **N1 Specialty vs Stock split** — Stock = base-game breeds, standard pricing; Specialty = named, lore-rich, premium/curated/bred/community-coat horses with traits + unique stats.
- **N2 Named lore horses** — specialty entries carry a name, description, and flavor.
- **N3 Height / "hands" stat** — cosmetic breed stat (e.g. 16.2 HH).
- **N4 Point-of-sale detail** — sex, age, trait cards, stat bars, ownership-papers/slot notices shown before purchase.
- **N5 Promotions / sales** — per-stable or per-horse sale ribbons & temporary price changes.
- **N6 Stablefront copy per stable** — configurable headline/subtext/collection name.
