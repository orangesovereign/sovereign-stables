# Sovereign Stables — Redesign Spec (React-safe)

Authoritative build spec for the delivered redesign (17 screens). The design is
**flat and token-based**: near-black chrome (top bar + left rail) around
**parchment content panels** with thin gold hairline frames, corner filigree,
medallion stat-cards, stat bars, status pills, and engraved line icons. No 9-slice
PNG kit, no leather-book skeuomorphism. Everything below is CSS variables + SVG +
webfonts + at most one small texture PNG.

> Hex values are read off the mockups and may be nudged ±a few points once real
> assets land. They live in ONE tokens file so a nudge is global.

---

## 1. Design tokens

```css
:root {
  /* chrome (top bar, left rail) */
  --sc-chrome-900: #14100a;   /* rail / bar base */
  --sc-chrome-800: #1c150d;   /* raised chrome */
  --sc-chrome-line: #3a2f1c;  /* hairline on dark */

  /* parchment (content panels) */
  --sc-parchment:   #efe6cf;  /* panel base */
  --sc-parchment-2: #e7dcc0;  /* table header / inset track */
  --sc-parchment-3: #ddd0ad;  /* deeper tan (bar tracks) */

  /* ink (text on parchment) */
  --sc-ink:      #2c2013;
  --sc-ink-soft: #5c4a30;
  --sc-ink-faint:#8a7550;

  /* brand accents */
  --sc-gold:     #c19a3a;     /* borders, wordmark, brass text */
  --sc-gold-dim: #8a6a2f;
  --sc-oxblood:  #7c2a24;     /* primary / active / danger */
  --sc-oxblood-hi:#93332b;
  --sc-green:    #4f6138;     /* success / good / "on duty" */
  --sc-amber:    #b0822f;     /* warn / pending / review / restricted */
  --sc-blue:     #3f6b82;     /* info / "in training" dot */

  /* medallion fills (stat-card circles) */
  --sc-med-gold:   #b8932f;
  --sc-med-green:  #4f6138;
  --sc-med-oxblood:#7c2a24;
  --sc-med-dark:   #241c11;

  /* frame */
  --sc-frame:      rgba(193,154,58,.55);   /* gold hairline */
  --sc-frame-soft: rgba(193,154,58,.28);

  /* radii / spacing */
  --sc-r-sm: 4px; --sc-r-md: 6px; --sc-r-lg: 10px; --sc-r-pill: 999px;
  --sc-space: 4px; /* multiply: 8/12/16/20/24 */

  /* type */
  --sc-font-display: "Playfair Display", Georgia, serif; /* big titles, horse names */
  --sc-font-caps:    "Cinzel", Georgia, serif;           /* wordmark, eyebrows, labels, buttons */
  --sc-font-body:    "EB Garamond", Georgia, serif;      /* body, tables, descriptions */
}
```

**Type scale** (px): display 40/32/26 · title 22 · body 16/15 · label 12 (caps,
letter-spacing .08em) · micro 10.5 (caps). Numbers use `font-variant-numeric:
tabular-nums`.

**Frame treatment:** panels & cards use a 1px `--sc-frame` border + a 1px inner
`--sc-frame-soft` line (2–3px inset) + a small SVG **corner filigree** absolutely
placed at each corner. This double-line-plus-corner look is the whole "framed
parchment" identity — build it once as `<FramedPanel>`.

---

## 2. Fonts (all OSS, bundle via @fontsource — no CDN)

| Role | Font | @fontsource pkg |
|---|---|---|
| Big titles, horse/wagon names | **Playfair Display** (600/700) | `@fontsource/playfair-display` |
| Wordmark, eyebrows, small-caps labels, buttons | **Cinzel** (500/600) | `@fontsource/cinzel` |
| Body, table cells, descriptions | **EB Garamond** (400/500/italic) | `@fontsource/eb-garamond` |

These are the closest open-source matches to the mockups — **confirm before mass
use**; swapping is a one-line token change. Bundle the woff2 subsets (latin) only.

---

## 3. Shared shell (every screen)

- **Top bar** (`--sc-chrome-900`, ~64px): crest · `SOVEREIGN STABLES` (Cinzel gold
  caps) [+ `Stables & Carriage Co.` on storefront] · center **location pill**
  (map-pin + name + chevron, gold hairline outline) · right group: user + name·role,
  `$` + cash, gold + gold, **EXIT** (gold-outline button + log-out icon).
- **Left rail** (`--sc-chrome-900`, storefront ~96px / admin·book ~112px): stacked
  nav items = icon + caps label; **active = oxblood block**. Bottom slot = context
  seal (`1896 / SOVEREIGN COUNTY` on book; `CONTEXT: ADMINISTRATION` +
  `SWITCH TO STABLE OFFICE` on admin; gear + help on storefront).
- **Content**:
  - *Storefront* screens: transparent **stage** (game renders horse/wagon) on the
    left, full-height **papers panel** (parchment) on the right, **catalog strip**
    (tabs + filter + search + cards) along the bottom-left.
  - *Admin / Owner-book* screens: one **framed parchment page** filling the content
    area — title + subtitle + right-aligned action button, a row of **4 stat
    cards**, then a two-column body (main table/list left, detail/summary panel
    right). The outer page has the gold double-frame + corner filigree.

---

## 4. Icon set

### 4a. From Lucide (install `lucide-react`; do NOT redraw these)
Map (design → lucide):

- map-pin→`MapPin` · chevron→`ChevronDown` · user→`User`/`UserRound` · cash→`CircleDollarSign` · gold→`Coins` · exit→`LogOut`
- settings→`Settings` · help→`CircleHelp` · directory→`Users` · stable→`Home`/`Warehouse` · activity-log→`ScrollText` · employee-audit→`UserSearch` · ledger→`NotebookText`/`BookOpen`
- scales→`Scale` · flag→`Flag` · calendar→`Calendar` · shield-star→`BadgeCheck`/`ShieldCheck` · archive→`Archive` · list→`List` · person-check→`UserCheck` · alert→`TriangleAlert`
- check→`Check` · x→`X` · lock→`Lock` · star→`Star` · search→`Search` · edit→`Pencil` · mail→`Mail` · phone→`Phone` · copy→`Copy` · export→`Download` · external→`ExternalLink` · plus→`Plus` · minus→`Minus`
- bell→`Bell` · tag→`Tag` · wrench→`Wrench` · clock→`Clock` · info→`Info` · lighting→`Sun` · rotate-left→`RotateCcw` · rotate-right→`RotateCw` · reset→`RefreshCw` · ellipsis→`MoreHorizontal` · capacity→`Package`/`Box` · seat→`Armchair` · note→`FileText`
- male→`Mars` · female→`Venus` · age→`Hourglass` · height→`Ruler` · cart→`ShoppingCart` · trophy→`Award` · gear-col→`Settings2`

Progress donut (Training) & horizontal stat bars are **CSS/SVG components**, not icons.

### 4b. Custom SVG marks — **ChatGPT authors these** (county style)
| # | name | viewBox | fill? | used |
|---|---|---|---|---|
| 1 | `crest-diamond` | 0 0 64 64 | solid | storefront header crest (SC + crown in diamond) |
| 2 | `crest-laurel` | 0 0 64 64 | solid | admin/book header crest (SC + crown in laurel) |
| 3 | `seal-1896` | 0 0 96 96 | solid | book rail bottom seal (1896 · Sovereign County, laurel) |
| 4 | `horseshoe` | 0 0 24 24 | line | recurring motif: nav, bullets, breeding, stat medallion |
| 5 | `horse-head` | 0 0 24 24 | line | header eyebrow, My Horses nav, stat medallions |
| 6 | `horse-run` | 0 0 24 24 | line | Training nav (galloping variant) |
| 7 | `saddle` | 0 0 24 24 | line | Tack & Care nav + saddle eyebrow/category |
| 8 | `bridle` | 0 0 24 24 | line | tack category |
| 9 | `stirrup` | 0 0 24 24 | line | tack category |
| 10 | `saddlebag` | 0 0 24 24 | line | tack category |
| 11 | `blanket` | 0 0 24 24 | line | tack category |
| 12 | `horn` | 0 0 24 24 | line | tack category |
| 13 | `wagon` | 0 0 24 24 | line | wagon eyebrow / stat |
| 14 | `wagon-wheel` | 0 0 24 24 | line | Wagons nav |
| 15 | `breeding-mark` | 0 0 24 24 | line | breeding stat (two horseshoes/gender interlocked) |
| 16 | `store` | 0 0 24 24 | line | Storefront nav (shopfront) |

### 4c. Ornaments — **ChatGPT authors** (SVG)
| name | viewBox | notes |
|---|---|---|
| `corner-filigree` | 0 0 48 48 | one top-left corner; CSS rotates for the other 3. Thin gold flourish. |
| `divider-title` | 0 0 240 12 | long hairline rule ending in a small diamond/arrow — sits right of page titles ("STABLE DIRECTORY ——◆—→"). |
| `divider-eyebrow` | 0 0 120 12 | short centered flourish `·—◆—·` — wraps papers eyebrow labels ("· STOCK HORSE ·"). |

### 4d. Texture — **ChatGPT (raster)**
| name | size | notes |
|---|---|---|
| `parchment-tile.png` | 512×512, seamless | subtle aged-cream fiber/grain, low contrast, NO stains/tears/edges; overlaid on `--sc-parchment` at ~8–12% opacity. |

### 4e. Content thumbnails — **separate track, confirm approach**
Catalog cards show realistic **horse / saddle / wagon** thumbnails. These are
photographic, not chrome, and consistency-sensitive. Options (pick per class):
(a) pre-render one image per catalog entry on a consistent dark vignette (transparent
PNG, ~256²); (b) for horses, reuse existing per-coat portraits; (c) defer and show a
neutral placeholder. **Not part of the ChatGPT chrome batch** — flagged for a decision.

---

## 5. Component inventory (React build surface)

Shell: `AppShell` · `TopBar` · `LocationPill` · `WalletGroup` · `NavRail` · `NavItem` · `ContextSeal`.
Framing: `FramedPanel` (double border + corner filigree) · `PanelTitle` (title + subtitle + `divider-title` + action slot) · `SectionHead`.
Data: `StatCard` (medallion + label + value + sub) · `StatBar` (label + track/fill + value) · `ProgressDonut` · `DataTable` (sortable head, gear col, `···` menu, row-select) · `StatusPill` (green/amber/oxblood/neutral) · `Toggle` · `Stepper` · `Segmented` (OWNER/TRAINER…, MARE/STALLION) · `PermissionMatrix` (view/edit/delete checkboxes) · `Timeline` (numbered steps) · `Wizard` (Identity/Appearance/Attributes/Availability) · `Dropdown`/`Select` · `SwatchPicker` (tack colours) · `KeyValueList`.
Storefront: `Stage` (orbit/zoom/cycle) · `PapersPanel` (eyebrow + title + attrs + desc + bars/rows + price + actions + footer) · `CatalogStrip` (tabs + filter + search + `CatalogCard` w/ status dot).
Buttons: `Button` variants `primary`(oxblood) · `secondary`(outline) · `danger`(oxblood outline) · `ghost`.

Each is data-driven (props only). They bind to the existing NUI payloads
(`manage:open` panel, storefront `open`/`detail`, training/tack data, etc.).

---

## 6. Delivery format (how assets must arrive)

**SVG marks & ornaments** — one file each, or one code block each in a batch reply:
- `viewBox` set, **no `width`/`height`**, no `id`/`class`, no inline `style`, no
  `<title>`, no comments.
- Line icons: `fill="none"`, `stroke="currentColor"`, `stroke-width="1.75"`,
  `stroke-linecap="round"`, `stroke-linejoin="round"`. Solid marks (crests/seals):
  `fill="currentColor"` (multi-tone crests may use 2–3 flat `fill` values — list them).
- Optically consistent weight across the whole set; drawn on a 24-unit grid with
  ~2u padding (icons), 64/96 for crests.
- **Naming:** kebab-case exactly as the tables above (`horse-head.svg`, etc.).
- Deliver as: (1) individual `.svg` files in a zip **and** (2) a single combined
  message with each SVG in its own fenced ```svg block labeled with its name — so I
  can paste straight into an icon module.

**Texture** — `parchment-tile.png`, 512×512, verified seamless (no visible seam when
tiled), transparent-agnostic (it's a flat cream tile), < 200 KB.

I convert the SVGs into a single React icon component set (`<Icon name=…/>`,
currentColor) and wire tokens — no other processing needed on your end.

---

## 7. Screen → asset checklist (coverage, no deviations)

- **Storefront/My Horses/Tack/Wagons:** shell, `store`/`horse-head`/`saddle`/`wagon-wheel` nav, papers eyebrow (`horse-head`/`saddle`/`wagon` + `divider-eyebrow`), stat **bars**, status dots, tack category icons (`saddle/saddlebag/bridle/blanket/horn/stirrup`), swatch picker, dropdowns.
- **Operations/Training/Clients/Breeding/Staff/Ledger/Settings (owner book):** framed page, `crest-laurel`, `seal-1896`, book nav icons (`horse-run`/users/`horseshoe`/user/ledger/settings), 4 medallion stat cards, tables + pills, permission matrix (Staff), timeline + donut (Training detail), category bars (Ledger), sub-nav (Settings), toggles/steppers.
- **Directory/Stable Profile/Activity Log/Employee Audit/Ledger Audit/Horse Creator (admin):** framed page, `crest-laurel`, admin nav icons, 4 medallion stat cards, wide tables + trace/detail side panel, JSON before/after (Activity), wizard + validation checklist + 3D preview controls (`sun`/`rotate`/`reset`) + summary stat tiles (Horse Creator), county-summary table (Directory).

See `CHATGPT-PROMPT.md` for the copy-paste generation instructions.
