# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

R&D engineers, Wood Manufacturing specialists, and SAP Material Master Governance teams staging wood part specifications and Bill of Materials (BOM) for SAP creation and multi-level approval.

## Product Purpose

Provide an intuitive SAP BSP web-based staging platform for searching SAP MARA material references, staging wood part specifications, validating master data, and managing multi-tier approval workflows prior to committing records to SAP.

## Positioning

A specialized SAP BSP staging interface tailored specifically for wood and furniture manufacturing BOMs, seamlessly connecting SAP MARA database queries with lightweight, glassmorphic UI components while adhering strictly to SAP SE80 runtime constraints.

## Operating Context

Operates within the SAP BSP (Business Server Pages) framework, accessed via desktop browsers by engineers submitting requests (`Request/request_form.htm`), staging BOM parts (`BOM/index4`), approving/rejecting requests (`Approval`, `APPROVE`, `REJECT`), and updating master data (`MaterialCode`, `UPDATE`).

## Capabilities and Constraints

- **Technical Constraints (SAP SE80 Rules):**
  - **Line Length:** Maximum 255 characters per line in HTML and JavaScript templates.
  - **JavaScript Engine:** Strict ES5 Vanilla JS (`var`, `function`, no ES6 arrow functions or `let`/`const`).
  - **Popups & Dialogs:** Native JS dialogs limited to `confirm()` and `prompt()`.
  - **Encoding & Output:** ASCII only in layout files (no raw Unicode/Emoji in HTML source).
  - **ABAP Integration:** Precise handling of ABAP BSP tags `<% IF ... %>` and explicit `sy-subrc` checks before internal table mutations in `OnInputprocessing.abap`.
- **Core Capabilities:**
  - SAP MARA reference search with wildcard parameter matching and alpha conversion.
  - Multi-column BOM staging with dynamic row creation and editable pre-population.
  - Real-time status tracking and history logs across approval cycles.

## Brand Commitments

- **Design Language:** Glassmorphic Emerald Design System (`.glass-panel`, `.glass-subpanel`, Tailwind CSS emerald palette, Google Font Inter).
- **UI Components:** Pill buttons, top navigation bar with gradient logo mark `MM`, summary card badges, tab switchers, and subtle backdrop blurs.

## Evidence on Hand

- `BOM/index4/index4.htm` (Staging UI layout and client-side logic)
- `BOM/index4/OnInputprocessing.abap` (BSP event handler and database queries)
- `Request/request_form.htm` (Material request form)
- `bsp-structure.md` & `bsp-workflow-rules.md` (KMI standard architectural guidelines)
- `Memory.md` (Project changelogs, technical decisions, and database mapping)

## Product Principles

1. **Strict SE80 Compliance First:** Ensure all code adheres to the 255-character line length limit and ES5 JavaScript rules to guarantee error-free SAP compilation.
2. **Defensive Database & ABAP State Management:** Save `sy-subrc` explicitly into local variables immediately following database operations before mutating internal tables.
3. **Cohesive Emerald Glassmorphism:** Maintain visual parity across all BSP pages using the established emerald theme and glassmorphic container tokens.
4. **Efficient SAP Reference Staging:** Facilitate rapid material staging through searchable MARA references while keeping imported fields 100% editable.

## Accessibility & Inclusion

- Keyboard-navigable form fields and accessible focus rings.
- High-contrast visual badges and clear status indicators (Pending, Hold, Approved, Rejected) for all approval states.
- Clean responsive layout grid supporting high-resolution desktop and tablet viewports.
