# QCXIS Business Forecast & MD Status Roadmap

## What This Is

A single-file HTML business forecast and roadmap presentation for **QCXIS Sdn Bhd**, an IT subsidiary of QC Group — a private education franchise network in Malaysia. The document is designed to be presented to the Chief/board and serves as the financial planning backbone for the company's path to **Malaysia Digital (MD) Status** by 2028.

The file is self-contained: HTML + CSS + JavaScript with Chart.js for visualisations. No build step, no dependencies beyond the CDN-loaded Chart.js.

---

## Company Context

### QC Group / QCXIS Structure
- **QC Group** is a private tuition/education franchise with **226 outlets** (as of Feb 2026) and **19,144 active clients** (students)
- **QCXIS Sdn Bhd** is the IT arm, responsible for the platform that franchisees use to manage operations
- QCXIS has 2 executives (CTO and CEO), no other staff yet. The CTO (Zen) is also Head of Unit, IT Ops & Management at QC Group — cross-functional role
- QCXIS operates from QC Group HQ (shared office), has its own server room there, and plans to deploy production servers at an external data centre

### Business Model
- **Revenue Stream 1 — Fee Collection:** RM1 per active client per month, invoiced monthly to each franchisee outlet. Agreed with the Chief. Collection starts June 2026.
- **Revenue Stream 2 — HR Module (Open Market SaaS):** A payroll/HR management SaaS product targeting Malaysian SMEs. Franchise network gets it bundled in the RM1 fee. External customers pay RM500 setup + RM8/employee/month (5 employees free). Planned launch H2 2027.
- The 500-outlet target by 2031 is per the Chief's strategic directive

### MD Status Goal
QCXIS is targeting Malaysia Digital (MD) Status application in Q1–Q2 2028. Key requirements:
1. Carrying out qualifying digital activities (SaaS, AI)
2. ≥2 knowledge workers at ≥RM5,000/month base salary
3. ≥RM50,000/year operating expenditure on MD activities
4. ≥RM1,000 paid-up capital (RM250,000 for future Expansion Incentive)

---

## Current State (v6)

The latest version is `QCXIS_Business_Forecast_v6.html`. It contains:

### Sections
1. **Executive Snapshot** — KPIs + 3-scenario comparison table (Conservative/Optimum/Aggressive) with scenario toggle
2. **Revenue** — Client growth chart, Fee Collection table, HR Module projection table, Combined Revenue table with YoY growth
3. **OPEX & P&L** — Revenue vs OPEX chart, full P&L breakdown with OPEX/CAPEX separation and YoY net growth
4. **Staffing** — 3 staffing scenarios (Phased/Moderate/Ambitious) modelled against baseline net, with chart
5. **Roadmap** — Visual timeline for 2026→2027→2028 milestones toward MD Status
6. **Appendix** — Monthly detail accordion + model assumptions (collapsed by default)

### Three Scenarios
| Parameter | Conservative | Optimum | Aggressive |
|---|---|---|---|
| Outlets by 2031 | 400 | 500 | 600 |
| Capacity/outlet | 100 | 120 | 140 |
| Net realisation | 80% | 88% | 93% |
| Ramp-up period | 18 months | 15 months | 12 months |
| Seasonal dip multiplier | 1.2× | 1.0× | 0.8× |

### Revenue Model
- **Fee Collection:** Active clients × RM1/month. Clients projected from outlet growth model with seasonal adjustment (Nov–Dec dip from exam cycle exits)
- **HR Module:** Bottom-up from customer acquisition (5 in 2027 → 105 by 2031), 20% annual churn, avg 15 employees/customer, RM80/month recurring per customer + RM500 setup per new customer

### Cost Model (as of v6)

**OPEX (recurring/operational):**
| Item | Amount | Timing |
|---|---|---|
| Payroll (CTO+CEO) | RM5,000/mo each | From Jan 2027 |
| EPF/SOCSO/EIS | ~15% on gross payroll | On all payroll |
| AWS Rekognition | Usage-based (scales with clients) | From Jun 2026 |
| AWS S3 | ~$75/mo | Ongoing |
| DC/Colocation hosting | RM530/mo (colo) → RM800/mo (DC) | Colo from Jun 2026, DC from mid-2027 |
| Server Ops | RM410/mo (cPanel 150, AV 100, SSL 30, monitoring 50, backup 80) | From Jun 2026 |
| Server Room utilities | ~RM350/mo (aircon + electricity) | From Mar 2026 |
| Server Room debt repayment | ~RM1,705/mo (RM40,919 over 24 months) | Mar 2026 – Feb 2028 |
| Domains | RM220/yr | Ongoing |
| Cloudflare | $200/mo | From mid-2027 |
| Contingency | 5% of OPEX subtotal | Ongoing |

**CAPEX (one-time assets):**
| Item | Amount | When |
|---|---|---|
| Secondhand server (colocation) | RM15,000 | 2026 |
| New server (data centre) | RM40,000 | 2027 |

**Corporate one-offs:**
| Item | Amount | When |
|---|---|---|
| Trademark (design, search, application) | RM3,500 | 2026 |
| GPU test (AI R&D pilot) | RM5,000 | 2027 |
| MDEC application fee | RM1,080 | 2028 |

**Server Room Equipment (debt to QC Group + unpaid):**
| Item | Amount | Paid by |
|---|---|---|
| Flooring | RM4,324 | QC Group (owed) |
| Aircond 1.5HP | RM5,000 | QC Group (owed) |
| LNS Switches & Router | RM17,216 | QC Group (owed) |
| Server Rack | RM8,000 | Not yet paid |
| UPS | RM6,379 | Not yet paid |
| **Total** | **RM40,919** | Repaid over 24 months |

### Staffing Scenarios (modelled separately from baseline P&L)
All include 15% statutory contributions on top:
| Plan | 2029 | 2030 | 2031 |
|---|---|---|---|
| **Phased (recommended)** | 3 staff × RM3k | 6 staff × RM3k | 6 staff × RM3.5k |
| **Moderate** | 6 staff × RM3k | 6 staff × RM3.5k | 6 staff × RM4k |
| **Ambitious** | 6 staff × RM3k | 6 staff × RM4k | 6 staff × RM5k + CTO/CEO bump to RM8k |

### AWS Rekognition Pricing Model
- Attendance flow: each user (client + tutor) does face recognition before AND after each session = 2 scans per session per user
- Tutor ratio: 12.45% of client count (derived from 2,331 tutors / 18,722 clients)
- Sessions: 8/month average
- Group 1 API pricing: $0.001/img (first 1M), $0.0008 (next 4M), $0.0006 (next 30M)
- Face storage: $0.0000125/face/month
- USD/MYR: 4.40

---

## Known Issues & Gaps (To Be Addressed)

These were identified through board-perspective analysis but not yet implemented:

### High Priority
1. **Bad debt / collection shortfall** — Model assumes 100% collection. Realistically 5-10% non-collection likely. Need to model a collection rate (90-95%) on fee revenue.
2. **HR Module CAC (Customer Acquisition Cost)** — Revenue modelled but zero marketing/sales spend to acquire those customers. Need at least a modest marketing budget line (RM500-2,000/mo).
3. **SST (Sales & Service Tax)** — Once combined revenue crosses RM500k threshold (~2029-2030), SST registration at 6% becomes mandatory. Not modelled.
4. **Server hardware replacement fund** — No maintenance/repair budget for server failures.

### Medium Priority
5. **Legal/compliance costs** — PDPA audits, contract reviews, disputes. ~RM5-10k/yr.
6. **Company secretary + SSM annual return + audit fees** — Every Sdn Bhd legally requires these. ~RM5-10k/yr combined.
7. **Currency fluctuation risk** — AWS/Cloudflare billed in USD. Model uses fixed 4.40.
8. **Developer tooling scaling** — When IT team grows to 6, paid tool tiers needed.
9. **Franchise churn at outlet level** — Different from client churn. Outlets closing permanently.
10. **Platform downtime / incident costs** — Emergency response labour costs.
11. **Key person risk** — Single point of failure (CTO). Not a cost item but a board-level risk.

### Noted but Deferred
12. Variance tracking / actuals vs forecast mechanism
13. TAM/SAM/SOM analysis for Malaysian tuition market
14. Unit economics (CAC, LTV, LTV:CAC ratio)
15. Cash flow timing model (separate from P&L)
16. Business insurance (professional indemnity, cyber)

---

## Technical Architecture

### File Structure
Single HTML file. All logic is inline JavaScript. Chart.js loaded from CDN.

### Key JavaScript Components

**Constants & Configuration** (top of `<script>`)
- `SC` — Scenario parameters (conservative/optimum/aggressive)
- `SEAS` — Monthly seasonal adjustment factors (derived from historical data)
- Cost constants: `PAY`, `STAT`, `SOM`, `SR_DEBT`, `DCM`, `CFU`, etc.
- HR Module: `HR_SETUP`, `HR_PER`, `HR_AVG`, `HR_CUST`, `HR_CHURN`
- `STAFF` — Three staffing plan definitions with annual costs

**Core Functions:**
- `awsC(scans, faces)` — Calculates AWS Rekognition cost (tiered pricing + storage)
- `yrCost(year)` — Returns all fixed/operational cost components for a year
- `hrRevByYear()` — Calculates HR Module revenue with churn model
- `buildProj(scenarioKey)` — Full projection engine: outlet growth → client growth → revenue → costs → annual stats

**Rendering Functions:**
- `renderSnap()` — Executive snapshot table
- `renderCC()` — Client growth chart (Chart.js line chart with vertical annotation)
- `renderFeeT()` / `renderHRT()` / `renderRevT()` — Revenue tables
- `renderPLC()` — P&L chart (bar + line combo)
- `renderPLT()` — P&L table (full OPEX/CAPEX breakdown)
- `renderStaff()` — Staffing scenario table + comparison chart
- `renderRM()` — Roadmap timeline
- `renderMAcc()` — Monthly detail accordion
- `renderA()` — Assumptions grid

**State Management:**
- `cur` — Current scenario selection ('conservative'/'optimum'/'aggressive'/'overlay')
- `setS(scenario)` — Updates toggle state and re-renders detail sections
- `tgl(button)` — Collapsible section toggle

### Data Flow
```
Historical Data (14 months)
    ↓
Scenario Parameters (outlets, capacity, realisation, ramp, seasonal)
    ↓
buildProj() → outlet projection → client projection → fee revenue
    ↓
yrCost() → all operational + capital costs per year
    ↓
hrRevByYear() → HR Module revenue with churn
    ↓
Annual Stats (fee, hr, totRev, opex, capex, cost, net, all breakdowns)
    ↓
Rendering functions → Charts + Tables + Roadmap
```

### Historical Data
14 months of actual client data embedded:
- Jan 2025: 11,244
- ...through...
- Feb 2026: 19,144

### Seasonal Model
Monthly growth/contraction rates derived from historical data:
```
Jan: +10.9%, Feb: +9.2%, Mar: -0.4%, Apr: +9.7%
May: +8.6%, Jun: +5.4%, Jul: +3.5%, Aug: +4.8%
Sep: +1.9%, Oct: +2.1%, Nov: -3.1%, Dec: -6.6%
```
Nov–Dec dip reflects exam-cycle exits (SPM/PT3 completers). Scaled by scenario's `seasonMul`.

---

## Design Decisions & Constraints

- **Single HTML file** — Must remain a single file for easy sharing and presentation. No build tools.
- **Chart.js from CDN** — Only external dependency. `https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js`
- **Font: DM Sans + Playfair Display** — Loaded from Google Fonts CDN
- **Collapsible sections** — Board members should see Snapshot first, then drill into detail. Appendix collapsed by default.
- **OPEX/CAPEX clearly separated** in P&L table
- **Scenario toggle** affects all detail sections (charts, P&L, monthly detail) but NOT the snapshot comparison table (which always shows all 3)
- **Staffing section uses Optimum baseline only** — Known limitation; ideally should show against all scenarios
- **Cost and Net cells use high-contrast colours** — Cost: dark red (#991b1b) on light red (#fef2f2). Net: dark green (#065f46) on light green (#ecfdf5). This was a specific design fix for readability.
- **Word salad minimised** — Explanatory text kept to compact callout boxes. Data tables should speak for themselves.
- **Collection mechanism documented** — Amber callout box in Snapshot section explains invoicing process and risk.

---

## Roadmap Timeline (Current State)

### 2026 — Revenue & Foundation
- H2: Franchise Module + Cashbook + Helpdesk launch
- H2: Fee collection begins
- Q2: Colocation migration (secondhand server + hosting)
- Q3: Trademark application filed (MyIPO, 12–18mo processing)

### 2027 — Scale & Infrastructure
- Q1: CTO + CEO payroll begins
- Early 2027: OMNI Module launch (Stock & Inventory, eCommerce, Warehouse)
- 2027: HR Module + Portrait (Psychometric) Module launch
- Q1: Cloudflare subscription
- Q2: Data centre migration (new server)
- Late 2027 / Early 2028: MEET Module launch
- Q4: AI R&D pilot (GPU test) + MDEC pre-consultation

### 2028 — MD Application
- Q1: Trademark completion expected + paid-up capital review
- Q1–Q2: MD Status application submitted
- Q2–Q4: Review & approval period

---

## Version History

| Version | Key Changes |
|---|---|
| v1 | Initial single-scenario fee collection forecast |
| v2 | 3 scenarios, cost model (Laravel Cloud + AWS), guided reading flow |
| v3 | Expanded costs (infra, payroll, trademark), MD Status roadmap |
| v4 | Payroll moved to 2027, Laravel Cloud removed (replaced with self-hosted), P&L restructured per year with YoY growth, staffing projection section added |
| v5 | Restructured flow (Clients → Revenue → OPEX → Staffing → Roadmap), stripped word salad, HR Module revenue model with DOSM market data, collection mechanism note |
| v6 | Complete cost model: server room debt repayment (RM40,919/24mo), utilities, EPF/SOCSO/EIS 15% on payroll, domains, OPEX/CAPEX separation, 5% contingency buffer, software subscriptions removed |

---

## How to Continue Development

When making changes:
1. The cost model is centralised in `yrCost(year)` — all fixed costs flow through here
2. AWS costs are calculated dynamically in `buildProj()` based on client projections
3. HR Module revenue is in `hrRevByYear()` — customer acquisition numbers are in `HR_CUST`
4. Staffing plans are in `STAFF` object — costs include 15% statutory on top
5. The P&L table rows are defined in `renderPLT()` — add new cost lines by adding keys to the `rows` array and corresponding fields in `yrCost()` return object and `as[y]` in `buildProj()`
6. Roadmap items are hardcoded in `renderRM()` — structured as year → items with quarter, title, description, cost, milestone flag

When adding new cost items: update `yrCost()` return → update `buildProj()` total calculation → update `renderPLT()` rows array → update `renderA()` assumptions.

### File Location
All versions are in the repo root. The latest is always the highest version number.