# Prompt: QCXIS Forecast v3 — Full Restructure + Tax Integration

## Context

You are restructuring `QCXIS_Roadmap_Forecast_v2.html` — a single-file HTML + vanilla JS board-facing financial forecast for QCXIS Sdn Bhd (IT subsidiary of QC Group, a Malaysian education franchise). The file uses Chart.js 4.4.1 (loaded from CDN), DM Sans + Playfair Display fonts (Google Fonts CDN), and has no build step — everything is inline.

The primary audience is **board members skimming during a meeting**. Every structural decision should optimise for: "Can a board member understand the headline in under 60 seconds without clicking anything?"

This prompt covers two categories of changes:
- **Part A**: Full restructure of information architecture, section ordering, default open/collapsed states, toggle placement, and code organisation
- **Part B**: Integration of corporate tax into the P&L, cost breakdown, cash flow, and summary tables

Both parts must be implemented together in a single output file.

**Design rules (unchanged from v2):**
- Keep the existing visual language: CSS variables from `:root`, card/callout/table patterns, DM Sans body + Playfair Display headings, eyebrow labels, collapsible sections via `tgl()`.
- All monetary values formatted via `fR()` helper.
- No external dependencies beyond Chart.js 4.4.1 and Google Fonts.
- Malaysian context: RM currency, Malay month abbreviations (`MO` array).
- Single self-contained HTML file.

---

## Part A: Structural Restructure

### A1. New section ordering

The current v2 ordering is:

```
Header
① Financial Overview (scenario + revenue toggles, P&L chart, KPIs, summary table,
   revenue breakdown [collapsed], cost breakdown [collapsed])
①b Cash Flow [collapsed]
② Journey Timeline
③ Module Roadmap [open]
④ Staffing [open]
④b Capacity [collapsed]
⑤ MD Status [open]
⑥ Dependencies [collapsed]
⑦ Appendix [collapsed]
```

Change it to:

```
Header
Scenario toggle (global — not inside any section)
Executive Summary (always visible, no toggle)
① What & Why (journey timeline + module grid; Gantt collapsed inside)  [open]
② The Team (staffing table + capacity chart + key-person callout)      [open]
③ MD Status & ROI (requirements tracker + tax ROI table + MD toggle)   [open]
④ Financial Forecast (P&L chart, summary table, revenue/cost drilldowns) [collapsed]
⑤ Cash Flow (monthly engine, chart, KPIs, accordion tables)           [open]
⑥ Risk & Dependencies                                                 [open]
⑦ Appendix (monthly detail + assumptions)                             [collapsed]
Footer
```

### A2. Executive Summary (new section)

Create a new section immediately after the header and scenario toggle. This section has **no collapsible toggle** — it is always visible. It contains:

1. **One-sentence context line** — static HTML:
   ```
   "QCXIS Sdn Bhd is QC Group's IT subsidiary — this document presents the 6-year
   financial forecast, roadmap, and resource plan for board review."
   ```

2. **Primary KPI cards (3, larger)** — these are the "should I approve this?" numbers:
   - **Net Contribution (post-tax)**: cumulative net after tax for 2026–2031 (see Part B for tax calculation)
   - **QC Group Funding Needed**: absolute value of lowest cumulative cash point (from cash flow engine)
   - **Cash-Positive From**: month/year of permanent breakeven

3. **Secondary KPI cards (3, smaller)** — context numbers:
   - **Total Revenue**: 5yr cumulative
   - **Outlets by 2031**: from scenario config (`SC[k].p2`)
   - **HR Customers 2031**: from HR funnel result

Use the existing `.kpi` / `.kpi-strip` CSS classes. Differentiate primary vs secondary by making primary cards slightly taller with a larger `.kpi-value` font (e.g., 22px vs the current 19px) and secondary cards at standard size.

**Important:** The executive summary KPIs must update when:
- The scenario toggle changes
- The MD delayed toggle changes (affects post-tax net)
- The starting cash input changes (affects funding needed / cash-positive-from)
- The contingency hire toggle changes (affects costs → net → cash flow)
- The Portrait mix or QC-Internal toggles change

Create a single `renderExecSummary()` function that reads from `D[s()]` and the cash flow / tax results. Call it from `renderFinancials()`.

4. **Verdict line** — a single sentence below the KPIs, dynamically generated:
   ```
   "Under the [scenario] scenario, QCXIS generates RM [net post-tax] cumulative
   net contribution and becomes cash-positive from [month year]. QC Group's
   maximum funding exposure is RM [funding needed]."
   ```
   Style this as a `.callout` with `.callout-good` if net is positive, `.callout-warn` if negative.

### A3. Scenario toggle (global)

Move the scenario toggle (Conservative / Optimum / Aggressive) out of the ① Financial Overview section and place it between the header and the executive summary, as a standalone bar. Use the existing `.scenario-bar` / `.s-toggle` / `.s-btn` CSS. This toggle is global — it affects everything below.

The revenue filter toggle (`setR()`) should move into the P&L chart card inside ④ Financial Forecast — it only affects that chart.

The Portrait mix toggle and QC-Internal toggle should move into the Portrait revenue breakdown inside ④ Financial Forecast.

The MD delayed toggle stays inside ③ MD Status & ROI.

The contingency hire toggle and year selector stay inside ② The Team (capacity sub-section).

### A4. Section ① — What & Why

Merge the current ② Journey Timeline and ③ Module Roadmap into a single section.

**Layout:**
- Section label: `① Roadmap — What We're Building`
- The journey timeline (interactive nodes + detail panels) renders first — this is the strongest visual and should be immediately visible.
- Below the journey: the module grid (`.mod-grid` cards). This is always visible (no sub-toggle).
- Below modules: a collapsible sub-section containing the Gantt chart. Use the existing `cs` pattern: `<button class="cs-toggle">` → `<div class="cs-body collapsed">`.

**Open by default.** Journey and module grid visible on load. Gantt collapsed.

### A5. Section ② — The Team

Merge the current ④ Staffing and ④b Capacity into a single section.

**Layout:**
- Section label: `② Team — Scaling & Capacity`
- The staffing callout (team structure summary) renders first.
- Below: the salary table (`#staffTable`) — always visible.
- Below: the market benchmark callout (currently inside ④ Staffing).
- Below: a sub-heading "Capacity & Workload" (not a separate collapsible — just a visual divider).
- Below sub-heading: the capacity chart, legend, utilisation table, key-person callout, and contingency hire toggle. All visible (not collapsed).

**Open by default.** Everything visible on load.

### A6. Section ③ — MD Status & ROI

Keep the current ⑤ content but co-locate the MD ROI analysis (currently rendered by `renderMDRoi()` at the bottom of the section) directly after the milestone table, not after a visual gap. The flow should be:

1. MD Status callout
2. Requirements tracker cards (4 cards)
3. Milestone table
4. Visual divider + "Financial Impact Analysis" sub-heading
5. MD delayed toggle
6. MD ROI comparison table
7. ROI explanation callout

**Open by default.**

### A7. Section ④ — Financial Forecast

This is the current ① Financial Overview content, reorganised and **collapsed by default**. The executive summary at the top already shows the headline numbers, so this section is drill-on-demand.

**Layout:**
- Section label: `④ Financial Forecast — Detailed P&L`
- **Collapsed by default.**
- Revenue filter toggle (All / Fee Only / HR & Portrait) sits inside the P&L chart card.
- P&L chart
- Summary table
- Revenue Breakdown (collapsed sub-section, containing fee table, HR funnel table + sensitivity callout, Portrait table + Portrait mix toggle + QC-Internal toggle + correlation/floor callouts)
- Cost Breakdown (collapsed sub-section, containing cost callouts + cost table — now including tax, see Part B)

### A8. Section ⑤ — Cash Flow

Promote from ①b sub-section to its own top-level section. **Open by default.** This tells the board what QC Group's exposure is — it should be immediately visible.

**Layout:**
- Section label: `⑤ Cash Flow — Monthly View`
- Starting cash input + explanatory callout
- Cash flow KPI strip (Lowest Point, Months Negative, Funding Needed, Cash-Positive From)
- Cumulative cash balance chart
- Explanatory callout
- Monthly accordion tables (per-year)

### A9. Section ⑥ — Risk & Dependencies

Current ⑥ content. **Open by default** (changed from collapsed). Board members should see risk without clicking.

### A10. Section ⑦ — Appendix

Current ⑦ content. **Collapsed by default.** No structural changes.

### A11. Print stylesheet

Add a `@media print` block that:
- Expands all collapsed sections (`.cs-body { max-height: none !important; overflow: visible !important; }`)
- Hides toggle buttons (`.cs-toggle { display: none; }`) and their arrows
- Hides interactive controls (scenario toggles, revenue filters, input fields, select dropdowns)
- Hides Chart.js canvases (they don't print well) — add `@media print { canvas { display: none; } }`
- Shows all tables and callouts
- Sets `body { overflow: visible; }` and removes any `overflow: hidden`
- Adds page breaks before major sections: `@media print { .cs { page-break-inside: avoid; } }`

---

## Part B: Tax Integration

### B1. Tax computation model

The existing `computeTaxImpact(as, mdStart)` function is correct and should be kept. It computes tax per year based on:
- Standard rate: 24% on positive net
- MD rate: 5% on positive net (from the MD start year onward, with H2 partial-year handling)
- Loss years: zero tax

**New addition — loss carry-forward (simplified):**

Malaysian tax law allows businesses to carry forward unabsorbed losses for up to 10 consecutive years. Implement a simplified version:

```javascript
function computeTaxImpact(as, mdStart) {
  let cum = 0, lossPool = 0;
  const byYr = {};
  for (const y of YRS) {
    const net = as[y].net;
    if (net <= 0) {
      lossPool += Math.abs(net);  // accumulate loss
      byYr[y] = 0;
      continue;
    }
    // Apply loss carry-forward: reduce taxable income by available losses
    const taxableIncome = Math.max(0, net - lossPool);
    lossPool = Math.max(0, lossPool - net);  // reduce pool by amount used

    let rate;
    if (!mdStart) rate = TAX_STD;
    else if (y < mdStart.year) rate = TAX_STD;
    else if (y === mdStart.year && mdStart.h2) rate = (TAX_STD + TAX_MD) / 2; // H2 blend
    else rate = TAX_MD;

    const tax = Math.round(taxableIncome * rate);
    byYr[y] = tax;
    cum += tax;
  }
  return { cum: Math.round(cum), byYr, lossPool };
}
```

### B2. Integrate tax into the annual summary (`buildProj`)

Currently `buildProj` computes `as[y].net = yTotRev - yOpex` (pre-tax). After this change, each annual summary should also include:

```javascript
as[y].tax = taxResult.byYr[y];          // tax for that year
as[y].netPostTax = as[y].net - as[y].tax; // net after tax
```

To compute this, `buildProj` needs to determine which MD scenario to use. Add a parameter or use the global `mdDelayed` state:

```javascript
function buildProj(k, opts = {}) {
  // ... existing code ...

  // After computing all as[y].net values:
  const mdStart = opts.mdDelayed ? {year:2029, h2:true} : {year:2028, h2:true};
  const taxResult = computeTaxImpact(as, mdStart);
  for (const y of YRS) {
    as[y].tax = taxResult.byYr[y];
    as[y].netPostTax = as[y].net - as[y].tax;
  }

  // Update totals:
  const gTax = Object.values(taxResult.byYr).reduce((a,b) => a+b, 0);
  const gNetPostTax = gTotRev - gCost - gTax; // where gTotRev and gCost already exist

  return { ...existingReturn, gTax, gNetPostTax, taxResult };
}
```

Also pass `mdDelayed` through the `opts` object in `rebuildD()`:

```javascript
function rebuildD() {
  const opts = {portMix, qcInternalOnly, contingencyHireEnabled, contingencyHireYear, mdDelayed};
  for (const k of Object.keys(SC)) D[k] = buildProj(k, opts);
}
```

And make sure `setMDDelayed()` calls `rebuildD(); renderFinancials();` (currently it only calls `renderMDRoi(); renderKPIs();`).

### B3. Update the summary table (`renderSummaryTable`)

Add a tax row and a post-tax net row. The current structure:

```
Total Revenue
Total OPEX
Net Contribution       ← currently pre-tax
YoY Net Growth
```

Change to:

```
Total Revenue
Total OPEX
Net Contribution (pre-tax)
Corporate Tax            ← NEW (use class 'pl-sub', show tax amount per year)
Net Contribution (post-tax) ← NEW (use class 'pl-net' or 'pl-net-neg', replaces the old Net row as the "bottom line")
YoY Net Growth           ← compute from post-tax net
```

### B4. Update the cost table (`renderCostTable`)

Add a tax row after the "Total OPEX" row. The cost table should now show:

```
Payroll (5 staff)
Management Fee → QC Group
Infra Repayment
Corporate One-offs
HR Customer Acquisition (CAC)
Contingency Hire (one-off)     ← conditional
Contingency (5%)
────────────────────────
Total OPEX                     ← existing total (pre-tax costs)
Corporate Tax (24% / MD 5%)    ← NEW row, styled differently from OPEX items
────────────────────────
Total Cost incl. Tax           ← NEW bottom line
```

For the tax row, use a new CSS class or the existing `.pl-sub` with a note showing the effective rate:
```javascript
{k:'tax', l:'Corporate Tax', cls:'pl-sub',
 n: mdDelayed ? '24% std → 5% MD from H2 2029' : '24% std → 5% MD from H2 2028'}
```

For the total-cost-incl-tax row, create a new derived value:
```javascript
as[y].totalInclTax = as[y].cost + as[y].tax;
```

### B5. Update cash flow engine (`buildCashFlow`)

Tax is a cash outflow. Model it as an **annual lump payment in the last month of each financial year** (December). This simplifies the implementation while being directionally correct.

In the `buildCashFlow` function, inside the monthly loop:

```javascript
// Tax payment — annual lump in December (mi === 11)
let taxPayment = 0;
if (mi === 11) {
  // Get tax for this year from the projection's tax result
  taxPayment = d.taxResult?.byYr[y] || 0;
}
const cashOut = baseOpex + contingency + taxPayment;
```

Update the cash flow monthly table to include a "Tax" column, and update the `rows.push(...)` to include `taxPayment`.

Also update the cash flow accordion table header to add the Tax column:
```html
<th>Month</th><th>Fee In</th><th>SaaS In</th><th>Total In</th>
<th>Payroll</th><th>Mgmt</th><th>Repay</th><th>Other</th><th>Cont.</th>
<th>Tax</th>  <!-- NEW -->
<th>Total Out</th><th>Net</th><th>Cumul.</th>
```

### B6. Update KPIs

In the executive summary (new section from Part A):
- "Net Contribution (post-tax)" should use `d.gNetPostTax`
- The verdict line should reference post-tax net

In the existing KPI strip inside ④ Financial Forecast:
- Change `'5yr Net (pre-tax)'` label to `'5yr Net (pre-tax)'` and add a second KPI for `'5yr Net (post-tax)'`
- Or replace the pre-tax KPI with post-tax and add a note showing pre-tax for reference

The tax savings KPI can remain as-is (it already shows the MD benefit correctly).

### B7. Update the MD ROI table (`renderMDRoi`)

The existing ROI table shows:
```
Tax rate | Cumul. tax | Tax savings | Incremental salary cost | Net ROI
```

Keep this structure. The values will now be slightly different because `computeTaxImpact` uses loss carry-forward (B1). No structural change needed — just ensure `renderMDRoi` uses the updated `computeTaxImpact` function.

### B8. Update assumptions

In `renderAssumptions()`, update or add:

```javascript
['Corporate Tax', 'Standard 24% · MD concessionary 5% (from approval year) · Loss carry-forward applied (simplified, 10yr max) · Tax paid annually in Dec · No provisional instalments modelled'],
```

Remove or update the existing `['MD Tax', ...]` entry to avoid duplication.

---

## Part C: Code Organisation

### C1. Group the JavaScript into clear sections

Reorganise the `<script>` block into this order:

```javascript
// ══ 1. CONSTANTS (never change at runtime) ══
// MO, YRS, YR_COLORS, HIST, ANC, P1S, SEAS
// Payroll rates: EPF_R, SOCSO_R, EIS_R, EMPLOYER_STAT, ALLOW_TOTAL, INS
// Salary constants: CEO_START, DCEO_START, CEO_2027, DCEO_2027, IT_TRANSFER, IT_NEW, TIER_*
// Module list: MODULES
// Timeline data: TIMELINE, CAT_META
// Dependencies: DEPENDENCIES
// Workload: WORKLOAD, CAPACITY, WL_CATS
// Tax rates: TAX_STD, TAX_MD
// Cash flow: CASH_BUFFER

// ══ 2. SCENARIO CONFIG ══
// SC, HR_FUNNEL, PORT_TIERS, PORT_MIX, PORT_BUNDLE_DISC, PORT_ADOPT, PORT_CHURN
// PORT_STAND_FUNNEL, SLOW_RAMP

// ══ 3. COMPUTATION ENGINE (pure functions — no DOM access) ══
// ctcMo, execBase, itSal, payrollYr, yrCost
// hrRevByYear, portRevByYear, portWA
// computeTaxImpact, incrementalSalaryCost
// buildProj, buildCashFlow
// staffCtcMonthly, corpOneOff, repaymentMo, hrMonthly, portMonthly, cacMonthly

// ══ 4. RUNTIME STATE ══
// cur, revFilter, portMix, qcInternalOnly, mdDelayed
// contingencyHireEnabled, contingencyHireYear
// INITIAL_CASH
// D (memoised projections), rebuildD()
// Chart instances: plChartInstance, cashChartInstance, capChartInstance

// ══ 5. STATE MUTATORS (toggle handlers — modify state, call rebuild + render) ══
// setS, setR, setPortMix, setQCInternal, setMDDelayed, setContingencyHire, setContingencyYear
// tgl, tglA

// ══ 6. RENDER FUNCTIONS (DOM only — read from D, never compute) ══
// renderFinancials (orchestrator — calls all sub-renders)
// renderExecSummary      ← NEW
// renderPLChart
// renderKPIs
// renderSummaryTable
// renderFeeTable
// renderHRTable
// renderPortTable
// renderCostTable
// renderJourney, toggleDetail
// renderModuleGrid, renderGanttChart
// renderStaff
// renderCapacity
// renderMDRoi
// renderDeps
// renderCashFlow
// renderMonthlyAcc
// renderAssumptions

// ══ 7. INIT ══
// rebuildD()
// renderFinancials()
// renderJourney()
// renderModuleGrid()
// renderGanttChart()
// renderStaff()
// renderDeps()
// renderAssumptions()
```

### C2. Consolidate buildProj return shape

`buildProj` should return a single rich object with all computed data:

```javascript
return {
  proj,       // monthly projection [{y, mi, mo, o, c}, ...]
  as,         // annual summary {2026: {fee, hr, port, totRev, payroll, ..., tax, netPostTax}, ...}
  HR_RES,     // HR funnel results per year
  PORT_RES,   // Portrait results per year
  taxResult,  // {cum, byYr, lossPool} from computeTaxImpact

  // Aggregates
  gFee, gHR, gPort, gSaaS, gTotRev, gCost, gCAC, gTax, gNet, gNetPostTax
};
```

`buildCashFlow` should remain a separate function (called by render, not by buildProj) because it depends on `INITIAL_CASH` which can change independently of scenario. But it should read tax data from `D[k].taxResult`.

### C3. Make setMDDelayed trigger a full rebuild

Currently `setMDDelayed(v)` only calls `renderMDRoi(); renderKPIs();`. After the tax integration, MD timing affects the tax line in the annual summary, which affects the P&L, cost table, cash flow, and executive summary. Change it to:

```javascript
function setMDDelayed(v) {
  mdDelayed = !!v;
  document.querySelectorAll('.md-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.md === (mdDelayed ? 'delayed' : 'base')));
  rebuildD();          // ← now rebuilds projections with new tax scenario
  renderFinancials();  // ← re-renders everything including cash flow
}
```

---

## Integration checklist

After implementing all changes, verify:

1. **Scenario toggle** at the top of the page updates ALL sections (exec summary, journey, financials, cash flow, capacity, MD ROI).
2. **Executive summary** shows post-tax net, funding needed, and cash-positive-from — all three update on any toggle change.
3. **Summary table** shows: Revenue → OPEX → Pre-tax net → Tax → Post-tax net → YoY growth (on post-tax).
4. **Cost table** shows: [all OPEX lines] → Total OPEX → Tax → Total incl. Tax.
5. **Cash flow** includes tax as a December lump payment per year. The cumulative cash chart reflects this (expect a dip each December).
6. **Cash flow KPIs** reflect the post-tax cash position (funding needed may increase due to tax outflows).
7. **MD ROI table** uses the updated `computeTaxImpact` with loss carry-forward.
8. **MD delayed toggle** triggers `rebuildD()` + full re-render (not just ROI table).
9. **All existing toggles** still work: Revenue filter, Portrait mix, QC-Internal, Contingency hire.
10. **Section open/collapsed defaults** match the specification:
    - Always visible: Executive summary
    - Open: ① What & Why, ② The Team, ③ MD Status, ⑤ Cash Flow, ⑥ Risk
    - Collapsed: ④ Financial Forecast, ⑦ Appendix
11. **Assumptions** updated with corporate tax details and loss carry-forward note.
12. **Print stylesheet** expands all sections, hides canvases, hides interactive controls.
13. **Mobile responsive** — new sections follow existing breakpoint patterns (`@media (max-width: 800px)` and `@media (max-width: 500px)`).
14. **No breaking changes** — journey timeline interactions (click to expand year), monthly accordion tables, Gantt chart, staffing table, MD requirements tracker all render correctly.

---

## Output

Produce the complete updated `QCXIS_Roadmap_Forecast_v3.html` file with all changes from Parts A, B, and C implemented. The file must be a single self-contained HTML file (inline CSS + JS, external CDN for Chart.js 4.4.1 and Google Fonts only). Do not split into multiple files. Do not omit any existing functionality — this is a restructure and enhancement, not a rewrite from scratch.
