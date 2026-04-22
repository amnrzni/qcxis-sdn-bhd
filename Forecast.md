# QCXIS Sdn Bhd — Financial Forecast (2026–2031)

> Source of truth: `QCXIS_Forecast_Optimum.csv`. HTML presentation and this document reflect that data. Optimum scenario baseline.
> All amounts in RM unless stated otherwise. USD/MYR = 4.40.

---

## Revenue Streams

QCXIS has three income sources. All are tied to milestones in the [Roadmap](Roadmap.md).

### Stream 1 — Fee Collection (RM1/client/month)

**Starts:** June 2026 (see Roadmap → 2026 Q2)

Each franchisee outlet pays RM1 per active client per month. Invoiced monthly, verified via platform data. 30-day payment terms.

- **Current base:** 19,144 active clients across 226 outlets (Feb 2026)
- **Growth driver:** Outlet expansion — 226 outlets today → 500 by 2031 (Chief's directive)
- **Capacity per outlet (optimum):** 120 clients
- **Realisation rate:** 88%
- **Seasonal pattern:** Growth Jan–Oct, dip Nov–Dec (exam cycle exits — SPM/PT3 completers)

### Stream 2 — HR Module (Open Market SaaS)

**Starts:** 2027 (see Roadmap → 2027)

A payroll/HR management product for Malaysian SMEs. Franchise network gets it bundled; external customers pay separately.

- **Pricing:** RM40/mo subscription + RM5/employee/month (normal) · RM2/employee/month (promo, 2027–2028 closed events)
- **Avg customer profile:** 25 employees → RM165/mo normal, RM90/mo promo
- **No setup fee**
- **Market:** ~307,000 small enterprises in Malaysia (DOSM 2024)
- **Acquisition target:** Conservative — starting with 5 customers in 2027
- **Annual churn:** 15%

**HR Module Revenue Projection:**

| Year | Customers | New | Churned | Rate/mo | Annual Rev |
|------|-----------|-----|---------|---------|------------|
| 2026 | — | — | — | — | — |
| 2027 | 5 | 5 | 0 | RM 90/mo (promo) | **RM 2,700** |
| 2028 | 15 | 11 | 1 | RM 90/mo (promo) | **RM 10,260** |
| 2029 | 35 | 22 | 2 | RM 165/mo (normal) | **RM 47,520** |
| 2030 | 65 | 35 | 5 | RM 165/mo (normal) | **RM 94,050** |
| 2031 | 105 | 50 | 10 | RM 165/mo (normal) | **RM 158,400** |
| **Total** | | | | | **RM 312,930** |

> New customers contribute 6 months in their first year; existing customers contribute 12 months.

### Stream 3 — Portrait Module (Psychometric Assessments)

**Starts:** 2027 (same as HR Module — see Roadmap → 2027)

Psychometric assessment tool for HR customers (bundled) and the open market (standalone). Uses an active-seat quota model — an organisation subscribes to a tier and manages who fills their allocated seats.

**Tiers (per organisation/month):**

| Tier | Price/mo | Seat Quota | Market Mix |
|------|----------|------------|------------|
| Starter | RM 299 | 50 seats | 70% |
| Pro | RM 699 | 150 seats | 25% |
| Enterprise | RM 1,199 | 300 seats | 5% |

- **Weighted avg price:** RM 444/mo (standalone) · RM 377/mo (bundled with HR — 15% off)
- **Bundle adoption:** 30% of HR customers also take Portrait (bundled price)
- **Standalone market:** independent customers beyond HR base
- **Annual churn:** 10% (seat-quota model is sticky)

**Portrait Module Revenue Projection:**

| Year | Bundle Cust | Standalone Cust | Bundle Rev | Standalone Rev | Annual Rev |
|------|-------------|-----------------|------------|----------------|------------|
| 2026 | — | — | — | — | — |
| 2027 | 2 | 5 | RM 4,524 | RM 13,320 | **RM 17,844** |
| 2028 | 4 | 10 | RM 13,572 | RM 39,960 | **RM 53,532** |
| 2029 | 10 | 20 | RM 31,668 | RM 77,256 | **RM 108,924** |
| 2030 | 20 | 30 | RM 65,598 | RM 127,872 | **RM 193,470** |
| 2031 | 32 | 40 | RM 113,100 | RM 178,488 | **RM 291,588** |
| **Total** | | | | | **RM 665,358** |

> New customers contribute 6 months in their first year; existing customers contribute 12 months.

### Bundle Pricing (HR + Portrait)

Customers taking both modules receive **15% off** the Portrait subscription. HR pricing is unchanged.

| | Portrait Subscription |
|--|----------------------|
| **Standalone** | RM 444/mo (weighted avg across tiers) |
| **Bundled with HR** | RM 377/mo (15% off) |

### SaaS Revenue Summary

| Source | 5-Year Total |
|--------|-------------|
| HR Module | RM 312,930 |
| Portrait Module | RM 665,358 |
| **Total SaaS** | **RM 978,288** |

---

## Cost Breakdown

All infrastructure costs (hosting, servers, server room, utilities, AWS, Cloudflare, domains) are covered by a **management fee** paid to QC Group. QCXIS's cost model has four components: **payroll**, **management fee**, **corporate one-offs**, and **contingency**.

### People — Payroll Tiers

Staff cost-to-company (CTC) = base salary + RM450 allowances + 14.95% statutory + RM150 insurance.

**Allowances breakdown:** RM50 parking + RM200 travel + RM200 housing = RM450/mo
**Statutory:** EPF 13% + SOCSO 1.75% + EIS 0.2% = 14.95% employer contribution (on base + allowances)

| Tier | Base | Allowances | Statutory (14.95%) | Insurance | CTC/mo | CTC/yr |
|------|------|------------|-------------------|-----------|--------|--------|
| Executive (mature, from 2028) | RM 5,000 | RM 450 | RM 815 | RM 150 | **RM 6,415** | RM 76,980 |
| IT (Transfer) | RM 2,200 | RM 450 | RM 386 | RM 150 | **RM 3,196** | RM 38,352 |
| IT (New Hire) | RM 2,000 | RM 450 | RM 366 | RM 150 | **RM 2,966** | RM 35,592 |
| Admin | RM 1,900 | RM 450 | RM 351 | RM 150 | **RM 2,851** | RM 34,212 |

**Salary plan — discrete annual increments every January:**

| Role | 2026 (Jun) | 2027 (Jan) | 2028 (Jan) | 2029+ |
|------|-----------|-----------|-----------|-------|
| CEO | RM 3,000 | RM 3,900 (+30%) | RM 5,000 (+28%) | 5% p.a. |
| DCEO | RM 3,000 | RM 3,900 (+30%) | RM 5,000 (+28%) | 5% p.a. |
| IT (Transfer) | — | RM 2,200 (Jan 2027) | RM 2,310 (+5%) | 5% p.a. |
| IT (New Hire) | — | RM 2,000 (Jan 2027) | RM 2,100 (+5%) | 5% p.a. |
| Admin | — | RM 1,900 (Jun 2027) | RM 1,995 (+5%) | 5% p.a. |

> Both CEO & DCEO step to RM5,000 in Jan 2028 — satisfies MD Status knowledge worker requirement (≥2 staff at ≥RM5k).

**Payroll by year (verified):**

| Year | Payroll | Notes |
|------|---------|-------|
| 2026 | RM 57,621 | CEO + DCEO × 7 months (Jun–Dec) |
| 2027 | RM 217,516 | CEO/DCEO full year @ RM3,900 + IT×2 × 12 months + Admin × 7 months (Jun–Dec) |
| 2028 | RM 266,327 | All 5 full year; CEO/DCEO @ RM5,000; IT/Admin first 5% increment (Jan 2028) |
| 2029 | RM 277,642 | All 5 full year; 5% increment |
| 2030 | RM 289,522 | All 5 full year; 5% increment |
| 2031 | RM 301,996 | All 5 full year; 5% increment |

### Management Fee

**RM 1,000/mo (RM 12,000/yr)** inter-company service fee paid to QC Group. Covers server and hosting services.

**Hardware Repayment (separate):** RM 14,499.99 hardware cost repaid at RM1,000/mo from Jan 2027–Feb 2028 (14 months) + RM 499.99 final payment (Mar 2028), per the inter-company Service Agreement.

### Corporate One-offs

| Item | Amount | Year | Roadmap Link |
|------|--------|------|--------------|
| Trademark (design, search, MyIPO) | RM 3,500 | 2026 | 2026 Q4 |
| GPU test (AI R&D pilot) | RM 5,000 | 2027 | 2027 Q4 |
| MDEC application fee | RM 1,080 | 2028 | 2028 Q1–Q2 |

### Contingency
- 5% applied on (payroll + management fee + corporate one-offs) monthly. Infra repayment is tracked separately and excluded from the contingency base.

---

## Annual OPEX Summary

| Cost Item | 2026 | 2027 | 2028 | 2029 | 2030 | 2031 |
|-----------|------|------|------|------|------|------|
| Payroll | 57,621 | 217,516 | 266,327 | 277,642 | 289,522 | 301,996 |
| Management Fee | 7,000 | 12,000 | 12,000 | 12,000 | 12,000 | 12,000 |
| Infra Repayment | — | 12,000 | 2,500 | — | — | — |
| Corporate One-offs | 3,500 | 5,000 | 1,080 | — | — | — |
| Contingency (5%) | 3,406 | 11,726 | 13,970 | 14,482 | 15,076 | 15,700 |
| **Total OPEX** | **71,527** | **258,242** | **295,877** | **304,124** | **316,598** | **329,696** |

**6-Year Total OPEX: RM 1,576,064**

---

## Staffing Scenarios (6th Hire from 2029)

The baseline model includes 5 staff from mid-2027. The optional **6th hire from 2029** is modelled at three pay tiers below. These are **additional** costs on top of the 5-person baseline payroll. All include RM450 allowances + 14.95% statutory + RM150 insurance.

| Tier | Base | CTC/mo | Annual Cost | Description |
|------|------|--------|-------------|-------------|
| **IT Tier** | RM 2,000 | RM 2,966 | RM 35,592 | IT developer or DevOps |
| **Mid Tier** | RM 3,000 | RM 4,116 | RM 49,392 | Experienced dev or BD |
| **Senior Tier** | RM 4,000 | RM 5,265 | RM 63,180 | Senior dev or specialist |

> Each scenario adds the above cost from 2029 through 2031 (3 years). The staffing chart in the HTML presentation shows net impact against the baseline.

---

## Key Assumptions

| Parameter | Value |
|-----------|-------|
| Outlets by 2031 | 500 (Chief's directive) |
| Scenarios | Cons 400 / Opt 500 / Aggr 600 |
| Optimum capacity/outlet | 120 clients |
| Optimum realisation | 88% |
| Fee rate | RM1/client/month |
| USD/MYR | 4.40 (fixed) |
| Collection rate | 100% (no bad debt modelled) |
| HR Module | RM40/mo sub + RM5/head (normal) or RM2/head (promo 2027–28). 25 avg emp. 15% churn. |
| Portrait Module | Starter RM299 / Pro RM699 / Enterprise RM1,199 per org/mo. WA RM444, bundled RM377. |
| Bundle | 15% off Portrait sub when taken with HR. HR pricing unchanged. |
| HR Market | ~307k small enterprises (DOSM 2024) |
| Exec CTC (2026) | RM3k base + RM450 allow + 14.95% stat + RM150 ins = ~RM4,116/mo |
| Exec CTC (2027) | RM3.9k base + RM450 allow + 14.95% stat + RM150 ins = ~RM5,150/mo |
| Exec CTC (2028+) | RM5k base + RM450 allow + 14.95% stat + RM150 ins = ~RM6,415/mo |
| IT Transfer CTC | RM2.2k base + RM450 allow + 14.95% stat + RM150 ins = ~RM3,196/mo |
| IT New Hire CTC | RM2k base + RM450 allow + 14.95% stat + RM150 ins = ~RM2,966/mo |
| Admin Tier CTC | RM1.9k base + RM450 allow + 14.95% stat + RM150 ins = ~RM2,851/mo |
| Statutory | EPF 13% + SOCSO 1.75% + EIS 0.2% = 14.95% employer |
| Management Fee | RM1,000/mo inter-company fee (server & hosting) |
| Infra Repayment | RM1,000/mo Jan 2027–Feb 2028 + RM499.99 (Mar 2028); total hardware RM14,499.99 |
| Corporate | TM RM3.5k (2026), GPU RM5k (2027), MDEC RM1,080 (2028) |
| Contingency | 5% of OPEX |
