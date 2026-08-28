---
timestamp: 2026-08-28T00-34-57Z
slug: bom-part-stagging2-part-stagging2-htm
---
#### Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Toast notifications and animated pulse status indicators active |
| 2 | Match System / Real World | 3 | SAP domain terminology (MARA, MATNR, MAKTX, MTART, WERKS) well aligned |
| 3 | User Control and Freedom | 2 | Missing column visibility toggles and undo mechanism for batch operations |
| 4 | Consistency and Standards | 2 | Inconsistent header color palettes (sky, emerald, slate) and dark toast contrast |
| 5 | Error Prevention | 2 | Native `confirm()` used for batch rejection; missing pre-export field validation |
| 6 | Recognition Rather Than Recall | 2 | 140 technical SAP columns lack tooltips or contextual field descriptions |
| 7 | Flexibility and Efficiency | 2 | Lacks keyboard navigation, row selection checkboxes, and column pinning |
| 8 | Aesthetic and Minimalist Design | 2 | Visual noise from 18,000px wide table and low contrast `text-slate-800 on bg-sky-200` |
| 9 | Error Recovery | 2 | Basic toasts shown on connection error, but lacks actionable recovery steps |
| 10 | Help and Documentation | 1 | Minimal 1-line header subtext; no inline field guidance or SAP mapping help |
| **Total** | | **21/40** | **[Acceptable]** |

#### Design Specificity Verdict

**LLM Assessment**: The page is functionally grounded in SAP BSP Material Governance workflows (BOM staging, auto binding, MARA reference creation, and 140-column SAP template export). However, its visual execution suffers from generic Tailwind styling choices, unpinned ultra-wide tables (18,000px width), low contrast colored table headers, non-standard custom dropdown divs lacking ARIA roles, and dated toast styling (`border-l-4`).

**Deterministic Scan**: Found 6 automated design antipatterns in `BOM/part_stagging2/part_stagging2.htm`:
- **Side-tab accent border (warning)**: Line 1096 (`border-l-4 border-brand-500` on toast notification).
- **Gray text on colored background (warning)**: Lines 621 (`text-slate-800` on `bg-sky-200`), 646 (`text-slate-800` on `bg-sky-100`), 826 (`text-slate-900` on `bg-sky-50`), 830 (`text-slate-900` on `bg-sky-50`).
- **Flat type hierarchy (warning)**: Line 51 (`Font sizes: 12px, 14px, 18px` with low ratio).

#### Overall Impression

`part_stagging2.htm` provides strong functional coverage for SAP material staging and Excel export, but the user experience is hampered by an ultra-wide, unpinned 140-column table that causes horizontal scroll disorientation. Improving color contrast, pinning primary key columns (`Pos`, `MATNR`, `MAKTX`), and adding ARIA accessibility to custom dropdowns will significantly elevate usability.

#### What's Working

- **Clear 3-Step Functional Breakdown**: Section headers (1: Auto Generator, 2: Preview & Review, 3: Upload History) clearly convey the staging workflow.
- **Robust View Mode Switcher**: Toggling between Excel SAP Main Template view and 34-column BOM Detail view works smoothly.
- **Comprehensive SAP Export Integration**: Full SheetJS integration generating compliant 134-field SAP Excel import files directly client-side.

#### Priority Issues

- **[P1] Low contrast text on colored table headers**: `text-slate-800` on `bg-sky-200` and `text-slate-900` on `bg-sky-50` reduce readability for complex numerical dimensions.
  - **Why it matters**: Operators reviewing hundreds of rough/finish dimension cells experience eye strain and increased error rates.
  - **Fix**: Replace slate text on sky backgrounds with deep indigo/navy (`text-sky-950` on `bg-sky-100`) or high-contrast dark tones.
  - **Suggested command**: `$impeccable colorize`

- **[P1] Unpinned key columns in 18,000px wide table**: Scrolling right across 140 SAP columns moves `Pos`, `Material Code`, and `Part Name` off-screen.
  - **Why it matters**: Users lose track of which material record they are evaluating when looking at columns 50–130.
  - **Fix**: Apply `sticky left-0` CSS positioning to the first 3 columns (`Pos`, `Code Num`, `MATNR`, `MAKTX`) with elevation shadow.
  - **Suggested command**: `$impeccable layout`

- **[P2] Inaccessible custom search dropdowns**: Search select boxes use `<div>` tags without ARIA `role="combobox"`, `aria-expanded`, or keyboard navigation (ArrowUp/ArrowDown/Enter).
  - **Why it matters**: Keyboard-only users and screen readers cannot navigate or select Material Type, Group, or Plant.
  - **Fix**: Refactor dropdown markup to include standard ARIA attributes and full keyboard listener support.
  - **Suggested command**: `$impeccable harden`

- **[P2] Dated side-tab toast borders**: Toast notifications use `border-l-4` side borders on dark slate backgrounds.
  - **Why it matters**: Creates visual noise and inconsistent aesthetic compared to modern pill-style UI elements on the rest of the page.
  - **Fix**: Use clean rounded pills (`rounded-xl` or `rounded-full`) with subtle ring borders.
  - **Suggested command**: `$impeccable polish`

#### Persona Red Flags

- **Alex (Power User)**:
  - No keyboard shortcuts (e.g. `Alt+G` to Generate, `Alt+E` to Export).
  - Cannot multi-select staging rows via checkboxes for batch operations.
- **Jordan (First-Timer)**:
  - Overwhelmed by 140 raw technical column titles (`BKLAS`, `LGPRO`, `DISGR`, `Col_78`) without inline tooltips.
- **Sam (Accessibility User)**:
  - Custom dropdowns (`mtart_select_box`) cannot be opened or navigated via `Tab` + `Arrow` keys.

#### Minor Observations

- The empty table placeholder spans `colspan="106"` in HTML while `renderStagingTable` uses `140` dynamically, creating potential layout shifts before data loads.
- Native `confirm()` is used in `rejectStagingBatch()` instead of a styled glassmorphic modal matching the rest of the application.

#### Questions to Consider

- "What if we grouped the 140 SAP columns into collapsible tabbed sections (Basic Data, Plant Data, Sales, MRP, QM, Costing) rather than an 18,000px horizontal table?"
- "Should key material identification columns (`Pos`, `MATNR`, `MAKTX`) be pinned to the left edge during horizontal scrolling?"
