# _recalc.ps1 — Master recompute for QCXIS forecast CSVs (v6)
#
# Scenario parameter: -Scenario Optimum | Delayed | WorstCase
#   • Optimum   : Devs hired Aug-2026 (col 2); 226→500 outlet ramp ends Dec-28 (col 30); OHXEM 50 by Dec-28
#   • Delayed   : Devs hired Jan-2027 (col 7); 226→500 outlet ramp ends Dec-29 (col 42); OHXEM 50 by Dec-29
#   • WorstCase : Devs hired Apr-2027 (col 10); 226→400 outlet ramp ends Dec-30 (col 54); OHXEM 30 by Dec-30;
#                 70% realisation; HR + Portrait module rev x0.70 (slower module adoption)
#
# v6 board-aligned model (Apr-2026 refresh):
#   * Vision (presentation only): "To create a unified ecosystem where organizations can run
#     their business and stay connected."
#   * Roles renamed: IT Transfer -> Dev Transfer (Akmal, RM 2,300 base);
#     IT New Hire -> Dev New Hire (Iffat, RM 2,100 base);
#     Admin -> IT Operations (start Jan-2027 = col 7, RM 1,900 base).
#   * Annual +5% uplift is PROFIT-GATED (not calendar-automatic):
#       - CEO/DCEO + IT Ops: first +5% Jan-2028, thereafter every Jan iff
#         prior calendar year had positive pre-tax Net.
#       - Devs (Akmal/Iffat): first +5% Feb-2028 (one-month lag — Jan-2028
#         stays at hire anchor), thereafter every Jan iff prior year > 0.
#       - A skipped (loss) year does NOT advance the cumulative multiplier;
#         the next profitable year resumes +5% on top of the last applied.
#     Tier escalation (RM3k -> 3.9k -> 5k MD-Status) remains REVENUE-gated.
#   • Recurring AI usage & research line: RM 1,200/mo flat from Jun-2026.
#   • Mgmt fee: FLAT RM 1,500/mo Jun-26→Dec-31 (all cols) — covers Phase 1–2
#     supplier pass-through (≈RM 990.05/mo) with modest margin; re-scoped as
#     flat advisory/backup-DC retainer from Jul-2028 after direct takeover.
#   • Hardware repayment: RM 14,499.99 starts Jan-28 (deferred to fully protect
#     Jun-26 → Dec-27 salary runway), scaled tiers (RM1k→1.5k→2k). Under Optimum
#     (OHXEM folded in) Tier 2 typically fires from start of 2028 → clears ~Aug-28.
#   • Direct recurring suppliers absorbed Jul-2028 (cPanel + Immunify + Colocation).
#   • Paid-up capital RM 100,000 Jun-2026 (equity, not repayable).
#   • Tax engine — Malaysian corporate tax (YA 2024+):
#       SME graduated rates apply (paid-up ≤ RM 2.5M, gross ≤ RM 50M, no foreign holding):
#         15% on first RM 150,000 chargeable income
#         17% on next   RM 450,000 (i.e. 150k–600k)
#         24% above     RM 600,000
#       Portrait Module income gets MD Status concessionary 14% from H2-2028
#       (revenue-weighted blend in 2028, full 14% from 2029).
#       Loss carry-forward: 10-year limit (Income Tax Act §44(5F)); applied separately
#       to "Regular" (non-Portrait) and "MD Portrait" income pools.
#   • New CSV rows: Cost_Mgmt_AI_Research, Tax_Annual.
#   • Old rows dropped: Cost_Mgmt_IT_Transfer, Cost_Mgmt_IT_NewHire, Cost_Mgmt_Admin,
#     Capital_Injection.

param(
    [ValidateSet('Optimum','Delayed','WorstCase')]
    [string]$Scenario = 'Optimum'
)

$templatePath = "QCXIS_Forecast_Optimum.csv"
$csvPath      = "QCXIS_Forecast_$Scenario.csv"
$lines = Get-Content $templatePath
$h = $lines[0] -split ','
$cols = $h[1..($h.Count-1)]
$nCols = $cols.Count  # 67 monthly columns: Jun-26 (0) … Dec-31 (66)

# Parse rows into ordered dict (preserves Year/Month meta rows separately)
$r = [ordered]@{}
foreach ($l in $lines[1..($lines.Count-1)]) {
    $f = $l -split ','
    $key = $f[0]
    if ($key -eq 'Year' -or $key -eq 'Month') { continue }
    $r[$key] = [double[]]($f[1..($f.Count-1)] | ForEach-Object { [double]$_ })
}

# CTC formula: base + RM450 allowances → 14.95% statutory → + RM150 insurance.
function ctcMo([double]$base) { [Math]::Round(($base + 450) * 1.1495 + 150, 2) }

# Calendar year of column index (Jun-26 = 0).
function yearOf([int]$c) {
    if ($c -le 6)  { return 2026 }
    if ($c -le 18) { return 2027 }
    if ($c -le 30) { return 2028 }
    if ($c -le 42) { return 2029 }
    if ($c -le 54) { return 2030 }
    return 2031
}

# Column ranges per fiscal year (start, end) inclusive.
$YEAR_RANGES = @{
    2026 = @(0,  6)
    2027 = @(7,  18)
    2028 = @(19, 30)
    2029 = @(31, 42)
    2030 = @(43, 54)
    2031 = @(55, 66)
}

$corp   = $r['Cost_Mgmt_CorporateOneoffs']
$revHR  = $r['Rev_HR_Module']
$revPor = $r['Rev_Portrait_Module']

# ─── Scenario parameters ──────────────────────────────────────────────────────
# Optimum  : Devs Aug-26, IT Ops Jan-27, ramps Dec-28, full module rev, 88% realisation, 500 outlets, OHXEM 50.
# Delayed  : Devs Jan-27, IT Ops Jan-27, ramps Dec-29, full module rev, 88% realisation, 500 outlets, OHXEM 50.
# WorstCase: Devs Apr-27, IT Ops Apr-27, ramps Dec-30, module rev x0.70, 70% realisation, 400 outlets, OHXEM 30.
switch ($Scenario) {
    'Optimum' {
        $DEV_HIRE_MO     = 2     # Aug-2026
        $OPS_HIRE_MO     = 7     # Jan-2027
        $FRANCH_RAMP_END = 30    # Dec-2028
        $OHXEM_RAMP_END  = 30    # Dec-2028
        $FRANCH_PEAK_OUTLETS = 500
        $FRANCH_REALISATION  = 0.88
        $OHXEM_PEAK_OUTLETS  = 50.0
        $MODULE_SCALE        = 1.00   # HR + Portrait module rev multiplier
    }
    'Delayed' {
        $DEV_HIRE_MO     = 7     # Jan-2027
        $OPS_HIRE_MO     = 7     # Jan-2027
        $FRANCH_RAMP_END = 42    # Dec-2029
        $OHXEM_RAMP_END  = 42    # Dec-2029
        $FRANCH_PEAK_OUTLETS = 500
        $FRANCH_REALISATION  = 0.88
        $OHXEM_PEAK_OUTLETS  = 50.0
        $MODULE_SCALE        = 1.00
    }
    'WorstCase' {
        $DEV_HIRE_MO     = 10    # Apr-2027
        $OPS_HIRE_MO     = 10    # Apr-2027
        $FRANCH_RAMP_END = 54    # Dec-2030
        $OHXEM_RAMP_END  = 54    # Dec-2030
        $FRANCH_PEAK_OUTLETS = 400
        $FRANCH_REALISATION  = 0.70
        $OHXEM_PEAK_OUTLETS  = 30.0
        $MODULE_SCALE        = 0.70
    }
}

# ─── Module-revenue scaling (WorstCase: slower module adoption) ──────────────
if ($MODULE_SCALE -ne 1.0) {
    for ($c = 0; $c -lt $nCols; $c++) {
        $revHR[$c]  = [Math]::Round($revHR[$c]  * $MODULE_SCALE, 2)
        $revPor[$c] = [Math]::Round($revPor[$c] * $MODULE_SCALE, 2)
    }
}

# ─── Portrait IP revenue-share ───────────────────────────────────────────────
# The Portrait module uses a psychometric tool whose IP is owned by Protrait
# Sdn Bhd. Per licensing arrangement, QCXIS retains 70% of Portrait module
# revenue; the remaining 30% is paid to the IP owner as a royalty / revenue
# share. Booked as a direct cost of revenue (NOT pro-rated like OPEX) and
# attributed wholly to the Portrait pool in the tax engine.
$PORTRAIT_IP_SHARE = 0.30
$ipPortrait = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $ipPortrait[$c] = [Math]::Round($revPor[$c] * $PORTRAIT_IP_SHARE, 2)
}

# ─── 0 · REVENUE — Franchise Fee Collection (parameterised ramp) ────────────
$FRANCH_ANCHOR  = 20178.0   # Jun-26 baseline (existing clients × RM1)
# Peak = outlets × 120 cap × realisation factor (scenario-driven).
$FRANCH_PEAK    = $FRANCH_PEAK_OUTLETS * 120.0 * $FRANCH_REALISATION

# Seasonal multipliers (Jan..Dec) — Malaysian school cycle (Mar dip, Nov-Dec dip).
$seasonal = @(1.016, 1.010, 0.930, 1.034, 1.033, 1.012, 1.003, 1.024, 1.005, 1.016, 0.972, 0.945)

function monthIdxOf([int]$c) { return (($c + 5) % 12) }

$revFee = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $frac = if ($c -ge $FRANCH_RAMP_END) { 1.0 } else { [double]$c / [double]$FRANCH_RAMP_END }
    $base = $FRANCH_ANCHOR + ($FRANCH_PEAK - $FRANCH_ANCHOR) * $frac
    $revFee[$c] = [Math]::Round($base * $seasonal[(monthIdxOf $c)], 2)
}

# ─── 0b · REVENUE — OHXEM international (USD 2/student @ FX 4.40) ───────────
$OHXEM_RATE_USD = 2.0
$OHXEM_FX       = 4.40
$OHXEM_CAP      = 90.0
$OHXEM_REAL     = 0.70
$ohxemRatePerStudent = $OHXEM_RATE_USD * $OHXEM_FX   # RM 8.80

# Anchor points scale with scenario ramp end & peak outlets.
$OHXEM_ANCHORS = switch ($Scenario) {
    'Optimum'   { @(@(0, 2), @(6, 3), @(18, 15), @(30, $OHXEM_PEAK_OUTLETS)) }
    'Delayed'   { @(@(0, 2), @(6, 3), @(24, 15), @(42, $OHXEM_PEAK_OUTLETS)) }
    'WorstCase' { @(@(0, 2), @(6, 3), @(36, 10), @(54, $OHXEM_PEAK_OUTLETS)) }
}
$OHXEM_RAMP_LAST_COL = $OHXEM_ANCHORS[-1][0]

function ohxemOutlets([int]$c) {
    $pts = $script:OHXEM_ANCHORS
    if ($c -ge $script:OHXEM_RAMP_LAST_COL) { return [double]$pts[-1][1] }
    for ($i = 0; $i -lt $pts.Count - 1; $i++) {
        $a = $pts[$i]; $b = $pts[$i+1]
        if ($c -ge $a[0] -and $c -le $b[0]) {
            $t = [double]($c - $a[0]) / [double]($b[0] - $a[0])
            return $a[1] + ($b[1] - $a[1]) * $t
        }
    }
    return [double]$pts[0][1]
}

$revOhx = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $outlets  = ohxemOutlets $c
    $students = $outlets * $OHXEM_CAP * $OHXEM_REAL
    $rev      = $students * $ohxemRatePerStudent * $seasonal[(monthIdxOf $c)]
    $revOhx[$c] = [Math]::Round($rev, 2)
}

# ─── 0c · Rev_Total = Fee + OHXEM + HR + Portrait ───────────────────────────
$revTot = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $revTot[$c] = [Math]::Round($revFee[$c] + $revOhx[$c] + $revHR[$c] + $revPor[$c], 2)
}

# ─── 1 · CEO & DCEO tier escalation indices (revenue-based) ─────────────────
# Tier transitions (RM3,000 → 3,900 → 5,000) remain revenue-gated because the
# Tier-3 RM5,000 floor satisfies the MSC MD-Status knowledge-worker rule which
# is itself a revenue/operations criterion. Annual +5% UPLIFT is profit-gated
# (see Section 1b below).
$T1 = 27000.0   # RM3,900 trigger
$T2 = 40000.0   # RM5,000 trigger (MD knowledge-worker requirement)
$idxT1 = -1
$idxT2 = -1
for ($c = 2; $c -lt $nCols; $c++) {
    if ($idxT1 -lt 0 -and $revTot[$c-1] -gt $T1 -and $revTot[$c-2] -gt $T1) { $idxT1 = $c }
    if ($idxT2 -lt 0 -and $revTot[$c-1] -gt $T2 -and $revTot[$c-2] -gt $T2) { $idxT2 = $c }
}

# ─── 1b · Pre-payroll OPEX components (independent of salaries) ─────────────
# AI/R&D, Mgmt Fee, Infra repayment, Direct recurring suppliers, Upgrade CAPEX
# all run independent of payroll → compute up-front so the year-sequential
# salary loop can compute monthly OPEX in one pass.
$AI_MO = 1200.0
$aiRes = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) { $aiRes[$c] = $AI_MO }

$mgmtFee = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) { $mgmtFee[$c] = 1500.0 }

# Repayment uses revenue-gated tiers (covers same period regardless of payroll).
$repay = [double[]]::new($nCols)
$hwBalance = 14499.99
$R1 = 35000.0
$R2 = 45000.0
for ($c = 19; $c -lt $nCols; $c++) {
    if ($hwBalance -le 0) { break }
    $tier = 1000.0
    if ($c -ge 2 -and $revTot[$c-1] -gt $R1 -and $revTot[$c-2] -gt $R1) { $tier = 1500.0 }
    if ($c -ge 2 -and $revTot[$c-1] -gt $R2 -and $revTot[$c-2] -gt $R2) { $tier = 2000.0 }
    $pay2 = [Math]::Min($tier, $hwBalance)
    $repay[$c] = [Math]::Round($pay2, 2)
    $hwBalance = [Math]::Round($hwBalance - $pay2, 2)
}

$directBase = 990.05
$directRec  = [double[]]::new($nCols)
for ($c = 25; $c -lt $nCols; $c++) {
    $yr   = yearOf $c
    $rate = if ($yr -le 2029) { $directBase }
            else { [Math]::Round($directBase * [Math]::Pow(1.03, $yr - 2029), 2) }
    $directRec[$c] = $rate
}

$upgradeCapex = [double[]]::new($nCols)
$upgradeCapex[37] = 10000.0   # Jul-29
$upgradeCapex[49] = 15000.0   # Jul-30
$upgradeCapex[61] = 20000.0   # Jul-31

$infraTot = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $infraTot[$c] = [Math]::Round($mgmtFee[$c] + $repay[$c] + $directRec[$c] + $upgradeCapex[$c], 2)
}

# ─── 1c · Salary anchors ────────────────────────────────────────────────────
$DEV_T_BASE = 2300.0   # Akmal — Dev Transfer
$DEV_N_BASE = 2100.0   # Iffat — Dev New Hire
$OPS_BASE   = 1900.0   # IT Operations

# ─── 2 · YEAR-SEQUENTIAL SALARY + OPEX (profit-gated uplifts) ───────────────
# Each year y ≥ 2028 may grant +5% uplift, conditional on year y-1's pre-tax
# Net being positive ("affordability" gate). Order:
#   • CEO/DCEO  : first +5% Jan-2028, thereafter every Jan if prior year > 0.
#   • IT Ops    : first +5% Jan-2028, thereafter every Jan if prior year > 0.
#   • Devs      : first +5% Feb-2028 (one-month lag — Jan-2028 still at hire
#                 anchor), thereafter every Jan if prior year > 0.
# A skipped year does not advance the cumulative multiplier; the next
# profitable year resumes +5% on top of the last-applied multiplier.
$ceoBase   = [double[]]::new($nCols)
$dceoBase  = [double[]]::new($nCols)
$devTBase  = [double[]]::new($nCols)
$devNBase  = [double[]]::new($nCols)
$opsBaseA  = [double[]]::new($nCols)
$ceo  = [double[]]::new($nCols)
$dceo = [double[]]::new($nCols)
$devT = [double[]]::new($nCols)
$devN = [double[]]::new($nCols)
$ops  = [double[]]::new($nCols)
$pay  = [double[]]::new($nCols)
$cont = [double[]]::new($nCols)
$mgmtTot = [double[]]::new($nCols)
$opex    = [double[]]::new($nCols)

$ceoMult = 1.0
$opsMult = 1.0
$devMult = 1.0
$annualPretaxNet = @{}
$priorProfitable = $false   # 2026 has no "prior year" → false

foreach ($y in 2026, 2027, 2028, 2029, 2030, 2031) {
    # --- Decide this year's uplift activations (Jan-effective) ---
    if ($y -ge 2028 -and $priorProfitable) {
        $ceoMult *= 1.05
        $opsMult *= 1.05
        # Devs lag by one month (Feb effective) — for Y ≥ 2029 they ride Jan
        # like the rest. The 2028 dev-Feb special case is handled below.
        if ($y -ge 2029) { $devMult *= 1.05 }
    }

    $rng = $YEAR_RANGES[$y]
    $cs  = $rng[0]; $ce = $rng[1]
    $rTotY = 0.0; $opexY = 0.0

    for ($c = $cs; $c -le $ce; $c++) {
        # CEO post-tier base (revenue-gated) × profit-gated uplift multiplier
        $ceoTier = 3000.0
        if ($idxT1 -ge 0 -and $c -ge $idxT1) { $ceoTier = 3900.0 }
        if ($idxT2 -ge 0 -and $c -ge $idxT2) { $ceoTier = 5000.0 }
        $ceoBase[$c]  = [Math]::Round($ceoTier * $ceoMult, 6)
        $dceoBase[$c] = $ceoBase[$c]
        $ceo[$c]  = ctcMo $ceoBase[$c]
        $dceo[$c] = ctcMo $dceoBase[$c]

        # Devs — Feb-2028 special case: one-month lag for first uplift
        $devLocalMult = $devMult
        if ($y -eq 2028 -and (monthIdxOf $c) -ge 1 -and $priorProfitable) {
            $devLocalMult = $devMult * 1.05
        }
        if ($c -ge $DEV_HIRE_MO) {
            $devTBase[$c] = [Math]::Round($DEV_T_BASE * $devLocalMult, 6)
            $devNBase[$c] = [Math]::Round($DEV_N_BASE * $devLocalMult, 6)
            $devT[$c]     = ctcMo $devTBase[$c]
            $devN[$c]     = ctcMo $devNBase[$c]
        }

        # IT Operations
        if ($c -ge $OPS_HIRE_MO) {
            $opsBaseA[$c] = [Math]::Round($OPS_BASE * $opsMult, 6)
            $ops[$c]      = ctcMo $opsBaseA[$c]
        }

        # Payroll & dependent OPEX components
        $pay[$c]  = [Math]::Round($ceo[$c] + $dceo[$c] + $devT[$c] + $devN[$c] + $ops[$c], 2)
        $cont[$c] = [Math]::Round(($pay[$c] + $mgmtFee[$c] + $directRec[$c] + $corp[$c] + $aiRes[$c]) * 0.10, 2)
        $mgmtTot[$c] = [Math]::Round($pay[$c] + $aiRes[$c] + $corp[$c] + $cont[$c], 2)
        $opex[$c]    = [Math]::Round($mgmtTot[$c] + $infraTot[$c] + $ipPortrait[$c], 2)

        $rTotY  += $revTot[$c]
        $opexY  += $opex[$c]
    }

    $netY = [Math]::Round($rTotY - $opexY, 2)
    $annualPretaxNet[$y] = $netY

    # End-of-year bookkeeping for dev mult: if 2028 fired the Feb-uplift,
    # promote that into the persistent multiplier so 2029 starts there.
    if ($y -eq 2028 -and $priorProfitable) { $devMult *= 1.05 }

    $priorProfitable = ($netY -gt 0)
}

# ─── 12 · TAX ENGINE — Malaysian SME graduated + Portrait MD carve-out ──────
# Per-year: split annual Net into Portrait-attributable vs Other (pro-rata OPEX
# by revenue share). Apply SME graduated to Other; apply 14% to Portrait-MD share
# (H2-2028 partial blend, full from 2029). Loss carry-forward in two pools.
function smeTax([double]$taxable) {
    if ($taxable -le 0) { return 0.0 }
    $tax = 0.0
    $tier1 = [Math]::Min($taxable, 150000.0)        # 15%
    $tax += $tier1 * 0.15
    $taxable -= $tier1
    if ($taxable -gt 0) {
        $tier2 = [Math]::Min($taxable, 450000.0)    # 17%
        $tax += $tier2 * 0.17
        $taxable -= $tier2
    }
    if ($taxable -gt 0) {
        $tax += $taxable * 0.24                     # 24%
    }
    return [Math]::Round($tax, 2)
}

$MD_PORTRAIT_RATE = 0.14
$MD_START_YEAR    = 2028
$MD_H2_BLEND      = $true   # 2028 = revenue-weighted blend (H1 SME, H2 14%)

$lossPool_other    = 0.0
$lossPool_portrait = 0.0
$annualTax = @{}    # year → tax amount

foreach ($y in 2026, 2027, 2028, 2029, 2030, 2031) {
    $rng = $YEAR_RANGES[$y]
    $cs = $rng[0]; $ce = $rng[1]

    $rTotY = 0.0; $rPorY = 0.0; $opexY = 0.0; $ipPorY = 0.0
    $rPorH2 = 0.0; $rPorH1 = 0.0
    for ($c = $cs; $c -le $ce; $c++) {
        $rTotY  += $revTot[$c]
        $rPorY  += $revPor[$c]
        $opexY  += $opex[$c]
        $ipPorY += $ipPortrait[$c]
        # H2 (Jul–Dec) of the calendar year — for 2028 MD blend.
        # Jul = month index 6 zero-based; col→month index = monthIdxOf($c).
        if ((monthIdxOf $c) -ge 6) { $rPorH2 += $revPor[$c] } else { $rPorH1 += $revPor[$c] }
    }

    if ($rTotY -le 0) { $annualTax[$y] = 0.0; continue }

    # Strip Portrait IP royalty from OPEX before pro-rata allocation —
    # it is a direct Portrait cost, not general overhead.
    $opexGenY    = $opexY - $ipPorY
    $porShare    = $rPorY / $rTotY
    $opexPor     = $opexGenY * $porShare
    $opexOther   = $opexGenY - $opexPor
    $netPortrait = $rPorY - $ipPorY - $opexPor        # may be negative early years
    $netOther    = ($rTotY - $rPorY) - $opexOther     # the rest
    # Sanity: $netPortrait + $netOther === $rTotY - $opexY  (annual net)

    # Determine MD applicability for this year.
    $portraitNetMD    = 0.0
    $portraitNetSME   = 0.0
    if ($y -lt $MD_START_YEAR) {
        $portraitNetSME = $netPortrait
    } elseif ($y -eq $MD_START_YEAR -and $MD_H2_BLEND) {
        # Revenue-weighted split of Portrait Net between H1 (SME) and H2 (MD).
        if ($rPorY -gt 0) {
            $h2Frac = $rPorH2 / $rPorY
            $portraitNetMD  = $netPortrait * $h2Frac
            $portraitNetSME = $netPortrait * (1.0 - $h2Frac)
        } else {
            $portraitNetSME = $netPortrait
        }
    } else {
        $portraitNetMD = $netPortrait
    }

    # OTHER POOL — SME graduated with loss carry-forward.
    $otherPlusPorSME = $netOther + $portraitNetSME
    if ($otherPlusPorSME -le 0) {
        $lossPool_other += [Math]::Abs($otherPlusPorSME)
        $taxOther = 0.0
    } else {
        $taxableOther = [Math]::Max(0.0, $otherPlusPorSME - $lossPool_other)
        $lossPool_other = [Math]::Max(0.0, $lossPool_other - $otherPlusPorSME)
        $taxOther = smeTax $taxableOther
    }

    # PORTRAIT MD POOL — flat 14% with separate loss carry-forward.
    if ($portraitNetMD -le 0) {
        $lossPool_portrait += [Math]::Abs($portraitNetMD)
        $taxPortrait = 0.0
    } else {
        $taxablePortrait = [Math]::Max(0.0, $portraitNetMD - $lossPool_portrait)
        $lossPool_portrait = [Math]::Max(0.0, $lossPool_portrait - $portraitNetMD)
        $taxPortrait = [Math]::Round($taxablePortrait * $MD_PORTRAIT_RATE, 2)
    }

    $annualTax[$y] = [Math]::Round($taxOther + $taxPortrait, 2)
}

# Tax row: paid as annual lump in December of each year.
$tax = [double[]]::new($nCols)
foreach ($y in 2026, 2027, 2028, 2029, 2030, 2031) {
    $decCol = $YEAR_RANGES[$y][1]
    $tax[$decCol] = $annualTax[$y]
}

# ─── 13 · Cost_Total = OPEX + Tax  ;  Net_Profit_Loss is post-tax ───────────
$costTot = [double[]]::new($nCols)
$net     = [double[]]::new($nCols)
$cumul   = [double[]]::new($nCols)
$running = 0.0
for ($c = 0; $c -lt $nCols; $c++) {
    $costTot[$c] = [Math]::Round($opex[$c] + $tax[$c], 2)
    $net[$c]     = [Math]::Round($revTot[$c] - $costTot[$c], 2)
    $running    += $net[$c]
    $cumul[$c]   = [Math]::Round($running, 2)
}

# ─── 14 · Paid-Up Capital & Cash Balance ────────────────────────────────────
$paidUp = [double[]]::new($nCols)
$paidUp[0] = 100000.0
$cashBal = [double[]]::new($nCols)
$acc = 0.0
for ($c = 0; $c -lt $nCols; $c++) {
    $acc += $paidUp[$c] + $net[$c]
    $cashBal[$c] = [Math]::Round($acc, 2)
}

# ─── Verification prints ────────────────────────────────────────────────────
Write-Host ""
Write-Host "===== SCENARIO: $Scenario  (Dev hire = col $DEV_HIRE_MO ; OHXEM peak = col $OHXEM_RAMP_END) ====="
Write-Host ""
Write-Host "=== MILESTONES ==="
if ($idxT1 -ge 0) { Write-Host ("RM3,900 trigger : col {0,2}  ({1})" -f $idxT1, $cols[$idxT1]) }
else              { Write-Host "RM3,900 trigger : NOT REACHED" }
if ($idxT2 -ge 0) { Write-Host ("RM5,000 trigger : col {0,2}  ({1})" -f $idxT2, $cols[$idxT2]) }
else              { Write-Host "RM5,000 trigger : NOT REACHED" }

Write-Host ""
Write-Host "=== UPLIFT GATING (profit-gated +5%) ==="
Write-Host ("Final mults  : CEO/DCEO={0:N4}  Devs={1:N4}  IT-Ops={2:N4}" -f $ceoMult, $devMult, $opsMult)
foreach ($y in 2026, 2027, 2028, 2029, 2030, 2031) {
    $flag = if ($annualPretaxNet[$y] -gt 0) { 'PROFIT' } else { 'LOSS  ' }
    Write-Host ("  {0} : Pre-tax Net = {1,12:N0}   [{2}]" -f $y, $annualPretaxNet[$y], $flag)
}

Write-Host ""
Write-Host "=== KEY MONTHLY ==="
Write-Host ("CEO base  : Jun26={0}  Jan27={1}  Jan28={2}  Jan29={3}  Jan31={4}" -f `
    $ceoBase[0], $ceoBase[7], $ceoBase[19], $ceoBase[31], $ceoBase[55])
Write-Host ("Payroll   : Jun26={0}  Aug26={1}  Jan27={2}  Jun27={3}  Jan28={4}" -f `
    $pay[0], $pay[2], $pay[7], $pay[12], $pay[19])
Write-Host ("AI/R&D    : Jun26={0}  Dec31={1}" -f $aiRes[0], $aiRes[66])
Write-Host ("MgmtFee   : Jun26={0}  Jun28={1}  Jul28={2}  Dec31={3}" -f `
    $mgmtFee[0], $mgmtFee[24], $mgmtFee[25], $mgmtFee[66])
Write-Host ("Repay     : Dec27={0}  Jan28={1}  Jul28={2}  Aug28={3}  Sep28={4}" -f `
    $repay[18], $repay[19], $repay[25], $repay[26], $repay[27])
$repaySum = ($repay | Measure-Object -Sum).Sum
Write-Host ("Repay sum : {0}  (expected 14499.99)" -f $repaySum)
Write-Host ("DirectRec : Jun28={0}  Jul28={1}  Jan30={2}  Dec31={3}" -f `
    $directRec[24], $directRec[25], $directRec[43], $directRec[66])

Write-Host ""
Write-Host "=== PORTRAIT IP REV-SHARE (30% to IP owner) ==="
foreach ($y in 2026, 2027, 2028, 2029, 2030, 2031) {
    $rng = $YEAR_RANGES[$y]
    $rpY=0.0;$ipY=0.0
    for ($c=$rng[0];$c -le $rng[1];$c++) { $rpY += $revPor[$c]; $ipY += $ipPortrait[$c] }
    Write-Host ("  {0} : PortraitRev={1,9:N0}  IPShare30%={2,8:N0}  QCXISKept70%={3,9:N0}" -f `
        $y, $rpY, $ipY, ($rpY - $ipY))
}

Write-Host ""
Write-Host "=== ANNUAL TAX (Malaysian SME + Portrait MD 14% from H2-28) ==="
foreach ($y in 2026, 2027, 2028, 2029, 2030, 2031) {
    $rng = $YEAR_RANGES[$y]
    $rY=0.0;$opY=0.0;$rpY=0.0
    for ($c=$rng[0];$c -le $rng[1];$c++) { $rY += $revTot[$c]; $opY += $opex[$c]; $rpY += $revPor[$c] }
    $netY = $rY - $opY
    Write-Host ("  {0} : Rev={1,10:N0}  OPEX={2,10:N0}  PreTaxNet={3,10:N0}  PortraitRev={4,8:N0}  Tax={5,8:N0}" -f `
        $y, $rY, $opY, $netY, $rpY, $annualTax[$y])
}

Write-Host ""
Write-Host "=== ANNUAL ROLL-UP ==="
foreach ($y in 2026, 2027, 2028, 2029, 2030, 2031) {
    $rng = $YEAR_RANGES[$y]
    $rY=0.0;$cY=0.0;$nY=0.0
    for ($c=$rng[0];$c -le $rng[1];$c++) { $rY += $revTot[$c]; $cY += $costTot[$c]; $nY += $net[$c] }
    Write-Host ("  {0} : Rev={1,10:N0}  Cost={2,10:N0}  Net={3,10:N0}" -f $y, $rY, $cY, $nY)
}

Write-Host ""
Write-Host "=== CASH ==="
Write-Host ("Jun26 floor : {0:N2}" -f $cashBal[0])
Write-Host ("Min in horiz: {0:N2}  (col {1} = {2})" -f `
    (($cashBal | Measure-Object -Minimum).Minimum), `
    [array]::IndexOf($cashBal, ($cashBal | Measure-Object -Minimum).Minimum), `
    $cols[[array]::IndexOf($cashBal, ($cashBal | Measure-Object -Minimum).Minimum)])
Write-Host ("Dec31 close : {0:N2}" -f $cashBal[66])

# ─── Write CSV ──────────────────────────────────────────────────────────────
function fmtRow($key, [double[]]$vals) {
    $v = $vals | ForEach-Object {
        if ($_ -eq [Math]::Truncate($_)) { "$([int64]$_)" } else { "$_" }
    }
    return "$key," + ($v -join ',')
}

# Lookup of original lines by row key (for any row we don't override).
$origMap = @{}
foreach ($l in $lines) {
    $f = $l -split ','
    $origMap[$f[0]] = $l
}

$overrides = [ordered]@{
    'Rev_FeeCollection'              = $revFee
    'Rev_OHXEM'                      = $revOhx
    'Rev_HR_Module'                  = $revHR
    'Rev_Portrait_Module'            = $revPor
    'Rev_Total'                      = $revTot
    'Cost_Mgmt_CEO'                  = $ceo
    'Cost_Mgmt_DCEO'                 = $dceo
    'Cost_Mgmt_Dev_Transfer'         = $devT
    'Cost_Mgmt_Dev_NewHire'          = $devN
    'Cost_Mgmt_Operations'           = $ops
    'Cost_Mgmt_Payroll_Total'        = $pay
    'Cost_Mgmt_AI_Research'          = $aiRes
    'Cost_Mgmt_Contingency'          = $cont
    'Cost_Mgmt_Total'                = $mgmtTot
    'Cost_Infra_ManagementFee'       = $mgmtFee
    'Cost_Infra_Repayment'           = $repay
    'Cost_Infra_Direct_Recurring'    = $directRec
    'Cost_Infra_Upgrade_CAPEX'       = $upgradeCapex
    'Cost_Infra_Total'               = $infraTot
    'Cost_Portrait_IP_RevShare'      = $ipPortrait
    'Cost_OPEX_Total'                = $opex
    'Tax_Annual'                     = $tax
    'Cost_Total'                     = $costTot
    'Net_Profit_Loss'                = $net
    'Cumulative_Net'                 = $cumul
    'PaidUpCapital'                  = $paidUp
    'Cash_Balance'                   = $cashBal
}

# Old row names to drop (renamed/superseded in v6).
$drop = @(
    'Capital_Injection',
    'Cost_Mgmt_IT_Transfer',
    'Cost_Mgmt_IT_NewHire',
    'Cost_Mgmt_Admin'
)

$newLines = @($lines[0], $origMap['Year'], $origMap['Month'])
foreach ($key in $r.Keys) {
    if ($drop -contains $key)         { continue }
    if ($overrides.Contains($key))    { $newLines += fmtRow $key $overrides[$key] }
    else                              { $newLines += $origMap[$key] }
}
# Append override keys not present in source.
foreach ($key in $overrides.Keys) {
    if (-not $r.Contains($key)) { $newLines += fmtRow $key $overrides[$key] }
}

$target = Join-Path $PWD $csvPath
$written = $false
for ($try = 0; $try -lt 8 -and -not $written; $try++) {
    try {
        [System.IO.File]::WriteAllLines($target, $newLines, [System.Text.UTF8Encoding]::new($false))
        $written = $true
    } catch {
        if ($try -eq 0) { Write-Host "CSV file locked (open in editor?) - retrying for 8s..." -ForegroundColor Yellow }
        Start-Sleep -Seconds 1
    }
}
if (-not $written) {
    Write-Host "ERROR: Could not write $csvPath after 8 retries. Close the file and re-run." -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "=== Written: $csvPath ($($newLines.Count) rows) ==="

# ─────────────────────────────────────────────────────────────────
# XLSX EXPORT — mirror CSV to .xlsx for presentation/audit backing.
# Requires ImportExcel module (Install-Module ImportExcel -Scope CurrentUser)
# ─────────────────────────────────────────────────────────────────
$xlsxPath = [System.IO.Path]::ChangeExtension($csvPath, '.xlsx')
$xlsxTarget = Join-Path $PWD $xlsxPath
if (Get-Module -ListAvailable -Name ImportExcel) {
    Import-Module ImportExcel -ErrorAction SilentlyContinue
    # Build object rows from $newLines so headers come from row 0.
    $headers = $newLines[0] -split ','
    $records = @()
    for ($i = 1; $i -lt $newLines.Count; $i++) {
        $cells = $newLines[$i] -split ','
        $obj = [ordered]@{}
        for ($c = 0; $c -lt $headers.Count; $c++) {
            $val = if ($c -lt $cells.Count) { $cells[$c] } else { '' }
            # Coerce numeric cells (skip header column 0 which holds Metric name)
            if ($c -gt 0 -and $val -match '^-?\d+(\.\d+)?$') { $val = [double]$val }
            $obj[$headers[$c]] = $val
        }
        $records += [pscustomobject]$obj
    }
    $xlsxWritten = $false
    for ($try = 0; $try -lt 8 -and -not $xlsxWritten; $try++) {
        try {
            if (Test-Path $xlsxTarget) { Remove-Item $xlsxTarget -Force }
            $records | Export-Excel -Path $xlsxTarget -WorksheetName $Scenario -AutoSize -FreezeTopRowFirstColumn -BoldTopRow -TableName "Forecast_$Scenario" -ErrorAction Stop
            $xlsxWritten = $true
        } catch {
            if ($try -eq 0) { Write-Host "XLSX file locked - retrying for 8s..." -ForegroundColor Yellow }
            Start-Sleep -Seconds 1
        }
    }
    if ($xlsxWritten) {
        Write-Host "=== Written: $xlsxPath (worksheet '$Scenario') ==="
    } else {
        Write-Host "WARN: Could not write $xlsxPath (file locked). CSV is authoritative." -ForegroundColor Yellow
    }
} else {
    Write-Host "WARN: ImportExcel module not installed - skipping xlsx export." -ForegroundColor Yellow
    Write-Host "      Install with: Install-Module ImportExcel -Scope CurrentUser" -ForegroundColor Yellow
}
