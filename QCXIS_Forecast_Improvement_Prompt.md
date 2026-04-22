# Prompt: Improve QCXIS Forecast Model — Board-Readiness Upgrade

## Context

You are editing `QCXIS_Roadmap_Forecast.html` — a single-file HTML + vanilla JS board-facing financial forecast for QCXIS Sdn Bhd (IT subsidiary of QC Group, a Malaysian education franchise). The file uses Chart.js 4.4.1 (loaded from CDN), DM Sans + Playfair Display fonts, and has no build step — everything is inline.

The file currently has:
- 3 scenario modes (Conservative / Optimum / Aggressive) toggled via `setS()`
- Revenue filter (All / Fee Only / HR & Portrait) toggled via `setR()`
- Collapsible sections for revenue breakdown, cost breakdown, journey timeline, modules, staffing, MD Status, dependencies, and appendix
- Monthly granularity in the appendix with per-year accordions

A board review has identified 5 critical weaknesses in the model that must be fixed. Each is detailed below with the exact current code, what's wrong, and what to build.

**Design rules:**
- Keep the existing visual language: CSS variables from `:root`, card/callout/table patterns, DM Sans body + Playfair Display headings, eyebrow labels, collapsible sections via `tgl()`.
- All new sections should be collapsible (use the existing `cs` / `cs-toggle` / `cs-body` pattern).
- New toggles/buttons should use the existing `.s-toggle` / `.s-btn` pattern.
- All monetary values formatted via existing `fR()` helper (returns `'RM ' + formatted number`).
- No external dependencies beyond what's already loaded (Chart.js 4.4.1).
- No breaking changes to existing functionality — all current features must still work.
- Malaysian context: currency is RM (Ringgit Malaysia), months use Malay abbreviations (`MO` array: Jan, Feb, Mac, Apr, Mei, Jun, Jul, Ogos, Sep, Okt, Nov, Dis).

---

## Change 1: Replace hardcoded HR Module customer targets with a funnel model

### Current code (lines 563–581)

```javascript
const HR_SUB = 40, HR_HEAD_N = 5, HR_HEAD_P = 2, HR_AVG_EMP = 25;
const HR_MO_N = HR_SUB + HR_HEAD_N * HR_AVG_EMP; // RM165/mo
const HR_MO_P = HR_SUB + HR_HEAD_P * HR_AVG_EMP; // RM90/mo (promo)
const HR_CUST = {2027:5, 2028:15, 2029:35, 2030:65, 2031:105};
const HR_CHURN = 0.15;

function hrRevByYear() {
  const r = {}; let active = 0;
  for (let y = 2027; y <= 2031; y++) {
    const churned = Math.round(active * HR_CHURN); active -= churned;
    const target = HR_CUST[y] || 0, newC = Math.max(0, target - active);
    const mo = y <= 2028 ? HR_MO_P : HR_MO_N;
    const recur = Math.round(active * mo * 12 + newC * mo * 6);
    r[y] = {cust: target, newC, recur, total: recur}; active = target;
  }
  r[2026] = {cust:0, newC:0, recur:0, total:0}; return r;
}
const HR_REV = hrRevByYear();
```

### What's wrong

- `HR_CUST` is a manually chosen lookup table with no underlying logic. A board member will ask "why 35 in 2029?" and there's no defensible answer.
- Churn is flat 15% applied uniformly. In reality, first-year churn is higher (customers trying the product, poor fit) and retained-customer churn is lower.
- There's no acquisition cost modelled. The forecast implies zero cost to acquire 105 customers.
- The model can't answer "what if we only convert half as many?" without manually editing `HR_CUST`.

### What to build

Replace `HR_CUST` with a funnel-based model. New constants:

```javascript
// HR Funnel parameters — per scenario
const HR_FUNNEL = {
  conservative: {
    leadsPerMonth: {2027: 8, 2028: 15, 2029: 22, 2030: 30, 2031: 35},
    trialConvRate: 0.25,   // 25% of leads start a trial
    paidConvRate: 0.35,    // 35% of trials convert to paid
    y1Churn: 0.25,         // 25% churn in first 12 months
    retainedChurn: 0.08,   // 8% annual churn for customers past year 1
    cacPerCustomer: 500,   // RM500 per acquired customer (content, demos, onboarding)
  },
  optimum: {
    leadsPerMonth: {2027: 12, 2028: 20, 2029: 30, 2030: 40, 2031: 45},
    trialConvRate: 0.30,
    paidConvRate: 0.40,
    y1Churn: 0.22,
    retainedChurn: 0.07,
    cacPerCustomer: 400,
  },
  aggressive: {
    leadsPerMonth: {2027: 18, 2028: 28, 2029: 40, 2030: 55, 2031: 60},
    trialConvRate: 0.35,
    paidConvRate: 0.45,
    y1Churn: 0.18,
    retainedChurn: 0.06,
    cacPerCustomer: 350,
  }
};
```

Rewrite `hrRevByYear()` to accept a scenario key and compute customers from the funnel:

```
function hrRevByYear(scenarioKey) {
  // For each year:
  //   newCustomers = leadsPerMonth[y] * 12 * trialConvRate * paidConvRate
  //   (new customers contribute 6 months revenue in joining year — keep this logic)
  //   churned = (firstYearCohort * y1Churn) + (retainedCohort * retainedChurn)
  //   Track cohorts: customers acquired in each year, so you can apply y1Churn
  //   to the current year's new adds and retainedChurn to all prior cohorts.
  //   Also compute: totalCAC = newCustomers * cacPerCustomer (added to cost side)
  //   Return per-year: {cust, newC, churned, recur, total, cac}
}
```

The existing `HR_REV` constant must become scenario-aware. Currently `buildProj(k)` reads `HR_REV[y]?.total` — after this change it should read from a scenario-specific result: `HR_REV[k][y]?.total`.

**Also update `buildProj(k)`:**
- Add `cac` from the HR funnel to the cost side (either as a new line in `yrCost()` or as a separate field in the annual summary `as[y]`).
- Make sure `renderCostTable()` shows the new CAC line.

**UI addition — HR Sensitivity callout:**
Add a callout (`.callout-warn` style) inside the HR revenue breakdown section that shows:
- "If trial→paid conversion drops to [X]%, customer count in 2031 falls to [Y] and HR revenue drops by [Z]%"
- Compute this inline using the funnel at 50% of the `paidConvRate` for the current scenario.

**Update the HR table** (`renderHRTable()`):
- Add rows for: Leads/year, Trial conversions, Paid conversions, First-year churned, Retained churned, CAC total
- These make the funnel transparent to the board reader.

---

## Change 2: Fix Portrait Module's compounding dependency on HR + add tier sensitivity

### Current code (lines 583–627)

```javascript
const PORT_TIERS = {
  starter:    {price: 299,  seats:  50, wt: 0.70},
  pro:        {price: 699,  seats: 150, wt: 0.25},
  enterprise: {price: 1199, seats: 300, wt: 0.05},
};
const PORT_BUNDLE_DISC = 0.15;
const PORT_ADOPT       = 0.30;  // 30% of HR customers also take Portrait (bundled)
const PORT_STANDALONE  = {2027:5, 2028:10, 2029:20, 2030:30, 2031:40};
const PORT_CHURN       = 0.10;
```

### What's wrong

- Bundled customers are computed from `HR_CUST[y]` which is now being replaced by the funnel. The Portrait model must read from the new HR funnel output, not a hardcoded table.
- The tier distribution (70/25/5) is a guess with no sensitivity analysis. If the real mix is 85/12/3, ARPU drops ~20%.
- Standalone Portrait growth is hardcoded with the same problem as old HR — no underlying logic.
- The correlation between HR underperformance and Portrait revenue loss is invisible to the reader.

### What to build

**Make Portrait bundled customers read from the HR funnel output**, not from `HR_CUST`. After Change 1, the HR funnel produces per-year customer counts per scenario. Portrait should use those.

**Add a tier mix toggle** — a new button group (use `.s-toggle` / `.s-btn` pattern) with two options:
- **Base case** (current 70/25/5)
- **Conservative mix** (85/12/3)

This toggle should recalculate `PORT_WA_MO` and `PORT_WA_BUNDLE` dynamically and re-render the Portrait table and the P&L chart. Store the tier mix configs:

```javascript
const PORT_MIX = {
  base:         {starter: 0.70, pro: 0.25, enterprise: 0.05}, // current
  conservative: {starter: 0.85, pro: 0.12, enterprise: 0.03}, // early-stage realistic
};
```

Compute weighted-average price from the active mix rather than hardcoding `PORT_WA_MO`.

**Apply the same funnel approach to standalone Portrait** as was done for HR:
- Leads → trial → paid, with scenario-specific parameters.
- Or, if keeping it simpler: at minimum make `PORT_STANDALONE` scenario-aware (different growth rates per scenario) rather than one fixed table.

**Add a correlation callout** — inside the Portrait revenue breakdown section, add a callout (`.callout-warn`) that says:
- "Portrait bundled revenue depends on HR customer volume. If HR reaches only [X] customers by 2031 (vs [Y] target), Portrait bundled revenue drops by [Z]%."
- Compute this dynamically from the current scenario's HR funnel at 50% conversion.

**Add a "QC Group internal only" scenario** — a checkbox or toggle that sets all external Portrait revenue (both bundled and standalone) to zero, showing only fee collection revenue. This gives the board a floor. Display this as a KPI note or a callout: "Floor scenario (no external SaaS): cumulative net = RM [X]".

---

## Change 3: Add capacity utilisation layer to staffing

### Current code (lines 496–562 — payroll functions)

The model computes payroll cost precisely but has zero connection between headcount and workload. Staffing is purely a cost line.

### What to build

**Add a new collapsible section** (after the existing ④ Staffing section or merged into it) titled "④b Team Capacity & Workload".

**Define workload categories and estimates** (person-months per year):

```javascript
const WORKLOAD = {
  2026: {
    moduleDev: 8,     // Franchise + Cashbook + Helpdesk (2 people × ~4mo each = shared)
    maintenance: 2,    // Bug fixes, patches
    helpdesk: 1,       // Internal support
    compliance: 1,     // DPO, DPA, governance docs
    custAcquisition: 0,
    infraOps: 2,       // Server management, DC planning
  },
  2027: {
    moduleDev: 24,     // OMNI + HR + Portrait + MEET start (heavy dev year)
    maintenance: 6,
    helpdesk: 4,
    compliance: 2,
    custAcquisition: 3, // HR module sales, demos
    infraOps: 4,        // DC migration
  },
  2028: {
    moduleDev: 14,     // MEET + ICARUS
    maintenance: 10,
    helpdesk: 6,
    compliance: 4,     // MD Status prep, ISO scoping
    custAcquisition: 6,
    infraOps: 4,
  },
  2029: {
    moduleDev: 10,     // Finance+ expansion
    maintenance: 12,
    helpdesk: 8,
    compliance: 4,
    custAcquisition: 8,
    infraOps: 4,
  },
  2030: {
    moduleDev: 6,
    maintenance: 14,
    helpdesk: 10,
    compliance: 6,     // ISO 27001 certification
    custAcquisition: 10,
    infraOps: 4,
  },
  2031: {
    moduleDev: 8,      // Platform v2
    maintenance: 14,
    helpdesk: 12,
    compliance: 4,
    custAcquisition: 10,
    infraOps: 4,
  },
};
```

**Available capacity** per year:
- 2026: 2 staff × 7 months (Jun–Dec) = 14 person-months
- 2027: 2 staff × 12 + 2 IT × 12 + 1 admin × 7 = 55 person-months
- 2028–2031: 5 staff × 12 = 60 person-months each

**Render a stacked bar chart** (horizontal, one bar per year) showing workload categories against a capacity line. Use distinct colours per category. Show utilisation percentage as a label.

**Add a "Key Person Departure" callout** below the chart:
- If utilisation is already >85%, flag it red with: "At [X]% utilisation, loss of one team member would exceed capacity. Recommend contingency hiring budget of RM [Y] (3-month recruitment + onboarding)."
- Add a one-time contingency cost (RM 18,000 — ~3 months of IT salary as recruitment + lost velocity) to the cost model as an optional toggle. When enabled, it adds to the year the user selects (default 2028).

**Important:** The workload numbers above are my best estimates. Present them in the UI with an "(est.)" label and a small note: "Workload estimates are directional — actual allocation will vary." The point is to show the board that capacity has been considered, not to claim precision.

---

## Change 4: Add MD Status ROI analysis to salary section

### Current code (lines 504–508)

```javascript
const CEO_START  = 3000, DCEO_START  = 3000;
const CEO_2027   = 3900, DCEO_2027   = 3900;
// → RM5,000 from 2028, then 5% p.a.
```

### What's wrong

- The salary ramp is reverse-engineered to meet MDEC's RM5,000 knowledge worker requirement but this isn't contextualised.
- There's no quantification of what MD Status is worth financially.
- No scenario for MD Status being delayed.

### What to build

**Add a new sub-section inside or after the ⑤ MD Status section** titled "MD Status — Financial Impact Analysis".

**Model the MD Status tax benefit:**
- Standard corporate tax rate in Malaysia: 24%
- MD Status concessionary rate: assume 5% on qualifying income (this is the typical MSC/MD incentive — note in the UI that the actual rate depends on MDEC approval terms)
- Tax savings per year = (24% - 5%) × net profit for that year (only from the year MD Status is obtained)
- Assume MD Status obtained H2 2028 (optimum) — so partial benefit in 2028 (6 months), full from 2029.

**Build a comparison table:**

| | Without MD Status | With MD Status (H2 2028) | With MD Status (Delayed to H2 2029) |
|---|---|---|---|
| Tax rate | 24% | 5% from H2 2028 | 5% from H2 2029 |
| Cumulative tax 2026–2031 | RM X | RM Y | RM Z |
| Tax savings vs baseline | — | RM A | RM B |
| Incremental salary cost to reach RM5k | — | RM C | RM C |
| Net ROI of MD pursuit | — | RM A - C | RM B - C |

The "incremental salary cost" is the difference between the current salary ramp (3k→3.9k→5k) and a hypothetical slower ramp that doesn't target RM5k by 2028 (e.g., 3k→3.5k→4k→4.5k→5k, reaching RM5k by 2030 instead). Compute the cumulative CTC difference.

**Add a market benchmark note** — a small callout (`.callout-info`) below the staffing salary table:
```
Market context: Malaysian tech startup CEO/CTO median salary range RM4,500–RM7,000/month
(source: industry surveys 2024–2025). The RM5,000 target is within market range and
simultaneously satisfies MD Status requirements.
```

**Add a "MD Delayed" toggle** — a simple button that shifts the MD Status benefit start date from H2 2028 to H2 2029. This should update the ROI table and the KPI strip (if you add a tax-savings KPI).

---

## Change 5: Add monthly cash flow projection

### Current state

The model computes annual P&L (revenue - OPEX = net). Monthly data exists in the appendix but only for client counts and fee revenue — there's no monthly cost breakdown and no cash flow view.

### What to build

**Add a new collapsible section** between ① Financial Overview and ② Roadmap Journey, titled "①b Cash Flow — Monthly View".

**Build a monthly cash flow engine.** You have all the building blocks:

Revenue side (monthly):
- Fee collection: already computed monthly in `buildProj()` — each `proj` entry has `{y, mi, c}` where `c` is active clients. Monthly fee = `c` (since RM1/client). But apply a **1-month collection delay**: revenue collected in month M = fee invoiced in month M-1. This models 30-day payment terms.
- HR Module: distribute annual HR revenue evenly across months the product is active (from month of first customer onward). For 2027, assume customers start arriving from month 6 onward (H2 launch).
- Portrait Module: same approach as HR — distribute evenly across active months.

Cost side (monthly):
- Payroll: use `ctcMo()` for each active staff member in each month. You already have start dates (CEO/DCEO Jun 2026, IT×2 Jan 2027, Admin Jun 2027) and salary schedules. Compute CTC per person per month.
- Management fee: RM1,000/month flat, every month from Jun 2026.
- Hardware repayment: RM1,000/month Jan 2027–Feb 2028, RM499.99 Mar 2028, zero after.
- Corporate one-offs: place them in specific months: trademark RM3,500 in Oct 2026, GPU RM5,000 in Jun 2027, MDEC RM1,080 in Mar 2028.
- Contingency: 5% of monthly OPEX (or apply annually, divided by 12).

**Cash flow calculation per month:**
```
cashIn[m]  = feeCollected[m] + hrRev[m] + portRev[m]
cashOut[m] = payroll[m] + mgmtFee[m] + repayment[m] + corpOneOff[m] + contingency[m]
netCash[m] = cashIn[m] - cashOut[m]
cumCash[m] = cumCash[m-1] + netCash[m]
```

**Starting cash:** Add a constant `INITIAL_CASH = 0` (QCXIS starts with RM0 cash — this is realistic and forces the question). Make it editable via a small input field in the section header.

**Render:**
1. A line chart showing cumulative cash balance over all months (Jun 2026 – Dec 2031). Use the accent green colour when positive, cost-red when negative. Add a horizontal dashed line at RM0 (breakeven) and optionally at a RM10,000 "minimum buffer" target.
2. A summary strip (KPI cards):
   - "Lowest cash point": the month with the minimum cumulative balance, and the RM amount
   - "Months cash-negative": count of months where cumulative balance < 0
   - "QC Group funding needed": the absolute value of the lowest negative point (= how much QC Group needs to front)
   - "Cash-positive from": the first month where cumulative balance stays permanently positive
3. A collapsible monthly table (use the accordion pattern from the appendix) showing: Month | Fee In | SaaS In | Total In | Payroll | Mgmt Fee | Repayment | Other | Total Out | Net | Cumulative

**The 1-month collection delay is important.** It means June 2026 has zero fee income (first invoice goes out in June, collected in July) but full payroll cost. This will show the board exactly what the early-month cash gap looks like.

**Connect to scenario toggle.** The cash flow must update when the user switches between Conservative / Optimum / Aggressive, since fee revenue changes per scenario.

---

## Integration checklist

After implementing all 5 changes, verify:

1. **Scenario toggle still works** — switching Conservative / Optimum / Aggressive updates ALL sections including the new ones (HR funnel, Portrait correlation, cash flow, MD ROI).
2. **Revenue filter still works** — All / Fee Only / HR & Portrait filter on the main P&L chart.
3. **Existing KPI strip** — update the "5yr Total Revenue" and "5yr Total Cost" KPIs to reflect the new CAC costs from the HR funnel.
4. **Summary table** — the annual P&L summary table should include CAC as a cost line.
5. **Dependencies table** — update the HR Module row's mitigation text from "Start small (5 customers), validate before scaling" to something reflecting the funnel approach, e.g., "Funnel model with validated conversion rates; 50% underperformance scenario modelled".
6. **Assumptions section** (`renderAssumptions()`) — add entries for: HR funnel parameters (leads, conversion rates, CAC), Portrait tier mix options, collection delay (30 days), MD Status tax rate assumptions, capacity workload estimates.
7. **No breaking changes** — the journey timeline, module grid, Gantt chart, and all other existing sections render correctly.
8. **Mobile responsive** — new sections should follow the existing `@media (max-width: 800px)` and `@media (max-width: 500px)` breakpoint patterns. Grid layouts collapse to fewer columns on narrow screens.

---

## Output

Produce the complete updated `QCXIS_Roadmap_Forecast_v2.html` file with all 5 changes implemented. The file must be a single self-contained HTML file (inline CSS + JS, external CDN for Chart.js and Google Fonts only). Do not split into multiple files.
