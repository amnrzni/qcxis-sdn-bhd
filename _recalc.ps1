# _recalc.ps1 — Master recompute for QCXIS forecast CSVs (v6)
#
# Scenario parameter: -Scenario Optimum | Extended
#   • Optimum  : Devs hired Aug-2026 (col 2); 226→500 outlet ramp ends Dec-28 (col 30); OHXEM 50 by Dec-28
#   • Extended : Devs hired Jan-2027 (col 7); 226→500 outlet ramp ends Dec-29 (col 42); OHXEM 50 by Dec-29
#
# v6 board-aligned model (Apr-2026 refresh):
#   • Vision (presentation only): "To create a unified ecosystem where organizations can run
#     their business and stay connected."
#   • Roles renamed: IT Transfer → Dev Transfer (Akmal); IT New Hire → Dev New Hire (Iffat);
#     Admin → IT Operations (start Jan-2027 = col 7, was Jun-27).
#   • Recurring AI usage & research line: RM 1,500/mo flat from Jun-2026.
#   • Mgmt fee step: RM 1,000/mo Jun-26→Jun-28 (cols 0–24), RM 3,000/mo Jul-28→Dec-31
#     (cols 25–66) — covers payroll uplift buffer + advisory + vendor uplift after takeover.
#   • Hardware repayment unchanged: RM 14,499.99 starts Jan-27, scaled tiers (RM1k→1.5k→2k).
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
    [ValidateSet('Optimum','Extended')]
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
switch ($Scenario) {
    'Optimum' {
        $DEV_HIRE_MO     = 2     # Aug-2026
        $OPS_HIRE_MO     = 7     # Jan-2027
        $FRANCH_RAMP_END = 30    # Dec-2028
        $OHXEM_RAMP_END  = 30    # Dec-2028
    }
    'Extended' {
        $DEV_HIRE_MO     = 7     # Jan-2027
        $OPS_HIRE_MO     = 7     # Jan-2027
        $FRANCH_RAMP_END = 42    # Dec-2029
        $OHXEM_RAMP_END  = 42    # Dec-2029
    }
}

# ─── 0 · REVENUE — Franchise Fee Collection (parameterised ramp) ────────────
$FRANCH_ANCHOR  = 20178.0   # Jun-26 baseline (existing clients × RM1)
$FRANCH_PEAK    = 52800.0   # 500 outlets × 120 cap × 88% realisation

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

# Anchor points scale with scenario ramp end.
function ohxemOutlets([int]$c) {
    # Optimum: (0,2) (6,3) (18,15) (30,50)  flat after.
    # Extended: same pilot (0,2)(6,3) but slower mid/peak — slip ~12 mo to (24,15)(42,50).
    if ($script:Scenario -eq 'Extended') {
        $pts = @(@(0, 2), @(6, 3), @(24, 15), @(42, 50))
        if ($c -ge 42) { return 50.0 }
    } else {
        $pts = @(@(0, 2), @(6, 3), @(18, 15), @(30, 50))
        if ($c -ge 30) { return 50.0 }
    }
    for ($i = 0; $i -lt $pts.Count - 1; $i++) {
        $a = $pts[$i]; $b = $pts[$i+1]
        if ($c -ge $a[0] -and $c -le $b[0]) {
            $t = [double]($c - $a[0]) / [double]($b[0] - $a[0])
            return $a[1] + ($b[1] - $a[1]) * $t
        }
    }
    return 2.0
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

# ─── 1 · CEO & DCEO milestone-driven salary ─────────────────────────────────
$T1 = 27000.0   # RM3,900 trigger
$T2 = 40000.0   # RM5,000 trigger (MD knowledge-worker requirement)
$idxT1 = -1
$idxT2 = -1
for ($c = 2; $c -lt $nCols; $c++) {
    if ($idxT1 -lt 0 -and $revTot[$c-1] -gt $T1 -and $revTot[$c-2] -gt $T1) { $idxT1 = $c }
    if ($idxT2 -lt 0 -and $revTot[$c-1] -gt $T2 -and $revTot[$c-2] -gt $T2) { $idxT2 = $c }
}

$ceoBase = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $base = 3000.0
    if ($idxT1 -ge 0 -and $c -ge $idxT1) { $base = 3900.0 }
    if ($idxT2 -ge 0 -and $c -ge $idxT2) {
        $milestoneYr = yearOf $idxT2
        $thisYr      = yearOf $c
        $base        = if ($thisYr -le $milestoneYr) { 5000.0 }
                       else { [Math]::Round(5000.0 * [Math]::Pow(1.05, $thisYr - $milestoneYr), 6) }
    }
    $ceoBase[$c] = $base
}

$ceo  = [double[]]::new($nCols)
$dceo = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $ceo[$c]  = ctcMo $ceoBase[$c]
    $dceo[$c] = ctcMo $ceoBase[$c]   # DCEO mirrors CEO
}

# ─── 2 · Dev Transfer (Akmal) ────────────────────────────────────────────────
# Optimum: joins Aug-2026 (col 2). Extended: joins Jan-2027 (col 7).
# +5% p.a. from Jan-2028.
$devT = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    if ($c -lt $DEV_HIRE_MO) { $devT[$c] = 0; continue }
    $yr = yearOf $c
    $base = if ($yr -le 2027) { 2200.0 }
            else { [Math]::Round(2200.0 * [Math]::Pow(1.05, $yr - 2027), 6) }
    $devT[$c] = ctcMo $base
}

# ─── 3 · Dev New Hire (Iffat) ────────────────────────────────────────────────
# Same hire month as Dev Transfer.
$devN = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    if ($c -lt $DEV_HIRE_MO) { $devN[$c] = 0; continue }
    $yr = yearOf $c
    $base = if ($yr -le 2027) { 2000.0 }
            else { [Math]::Round(2000.0 * [Math]::Pow(1.05, $yr - 2027), 6) }
    $devN[$c] = ctcMo $base
}

# ─── 4 · IT Operations (was Admin) ───────────────────────────────────────────
# Joins Jan-2027 (col 7) under both scenarios. +5% p.a. from Jan-2028.
$ops = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    if ($c -lt $OPS_HIRE_MO) { $ops[$c] = 0; continue }
    $yr = yearOf $c
    $base = if ($yr -le 2027) { 1900.0 }
            else { [Math]::Round(1900.0 * [Math]::Pow(1.05, $yr - 2027), 6) }
    $ops[$c] = ctcMo $base
}

# ─── 5 · Payroll Total ──────────────────────────────────────────────────────
$pay = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $pay[$c] = [Math]::Round($ceo[$c] + $dceo[$c] + $devT[$c] + $devN[$c] + $ops[$c], 2)
}

# ─── 5b · AI Usage & Research (RM 1,500/mo flat from Jun-26) ────────────────
$AI_MO = 1500.0
$aiRes = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) { $aiRes[$c] = $AI_MO }

# ─── 6 · Infra Management Fee — STEPPED ──────────────────────────────────────
# RM 1,000/mo Jun-26 → Jun-28 (cols 0–24) — covers Phase 1–2 supplier reimbursement.
# RM 3,000/mo Jul-28 → Dec-31 (cols 25–66) — advisory + payroll uplift buffer.
$mgmtFee = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $mgmtFee[$c] = if ($c -lt 25) { 1000.0 } else { 3000.0 }
}

# ─── 7 · Infra Repayment — scaled tiers (Jan-27 start) ──────────────────────
$repay = [double[]]::new($nCols)
$hwBalance = 14499.99
$R1 = 35000.0
$R2 = 45000.0
for ($c = 7; $c -lt $nCols; $c++) {
    if ($hwBalance -le 0) { break }
    $tier = 1000.0
    if ($c -ge 2 -and $revTot[$c-1] -gt $R1 -and $revTot[$c-2] -gt $R1) { $tier = 1500.0 }
    if ($c -ge 2 -and $revTot[$c-1] -gt $R2 -and $revTot[$c-2] -gt $R2) { $tier = 2000.0 }
    $pay2 = [Math]::Min($tier, $hwBalance)
    $repay[$c] = [Math]::Round($pay2, 2)
    $hwBalance = [Math]::Round($hwBalance - $pay2, 2)
}

# ─── 7b · Direct Recurring Suppliers (Jul-28 takeover) ──────────────────────
$directBase = 990.05
$directRec = [double[]]::new($nCols)
for ($c = 25; $c -lt $nCols; $c++) {
    $yr = yearOf $c
    $rate = if ($yr -le 2029) { $directBase }
            else { [Math]::Round($directBase * [Math]::Pow(1.03, $yr - 2029), 2) }
    $directRec[$c] = $rate
}

# ─── 7c · Infra Upgrade CAPEX ───────────────────────────────────────────────
$upgradeCapex = [double[]]::new($nCols)
$upgradeCapex[37] = 10000.0   # Jul-29
$upgradeCapex[49] = 15000.0   # Jul-30
$upgradeCapex[61] = 20000.0   # Jul-31

# ─── 8 · Cost_Infra_Total = mgmtFee + repay + directRec + upgradeCapex ──────
$infraTot = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $infraTot[$c] = [Math]::Round($mgmtFee[$c] + $repay[$c] + $directRec[$c] + $upgradeCapex[$c], 2)
}

# ─── 9 · Contingency = 10% × (payroll + mgmtFee + directRec + corp + AI) ────
$cont = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $cont[$c] = [Math]::Round(($pay[$c] + $mgmtFee[$c] + $directRec[$c] + $corp[$c] + $aiRes[$c]) * 0.10, 2)
}

# ─── 10 · Cost_Mgmt_Total (now includes AI Research) ────────────────────────
$mgmtTot = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $mgmtTot[$c] = [Math]::Round($pay[$c] + $aiRes[$c] + $corp[$c] + $cont[$c], 2)
}

# ─── 11 · Cost_OPEX = Cost_Mgmt_Total + Cost_Infra_Total (pre-tax) ──────────
$opex = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $opex[$c] = [Math]::Round($mgmtTot[$c] + $infraTot[$c], 2)
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

    $rTotY = 0.0; $rPorY = 0.0; $opexY = 0.0
    $rPorH2 = 0.0; $rPorH1 = 0.0
    for ($c = $cs; $c -le $ce; $c++) {
        $rTotY += $revTot[$c]
        $rPorY += $revPor[$c]
        $opexY += $opex[$c]
        # H2 (Jul–Dec) of the calendar year — for 2028 MD blend.
        # Jul = month index 6 zero-based; col→month index = monthIdxOf($c).
        if ((monthIdxOf $c) -ge 6) { $rPorH2 += $revPor[$c] } else { $rPorH1 += $revPor[$c] }
    }

    if ($rTotY -le 0) { $annualTax[$y] = 0.0; continue }

    # Pro-rata OPEX allocation to Portrait by revenue share.
    $porShare    = $rPorY / $rTotY
    $opexPor     = $opexY * $porShare
    $opexOther   = $opexY - $opexPor
    $netPortrait = $rPorY - $opexPor                  # may be negative early years
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
Write-Host "=== KEY MONTHLY ==="
Write-Host ("CEO base  : Jun26={0}  Jan27={1}  Jan28={2}  Jan29={3}  Jan31={4}" -f `
    $ceoBase[0], $ceoBase[7], $ceoBase[19], $ceoBase[31], $ceoBase[55])
Write-Host ("Payroll   : Jun26={0}  Aug26={1}  Jan27={2}  Jun27={3}  Jan28={4}" -f `
    $pay[0], $pay[2], $pay[7], $pay[12], $pay[19])
Write-Host ("AI/R&D    : Jun26={0}  Dec31={1}" -f $aiRes[0], $aiRes[66])
Write-Host ("MgmtFee   : Jun26={0}  Jun28={1}  Jul28={2}  Dec31={3}" -f `
    $mgmtFee[0], $mgmtFee[24], $mgmtFee[25], $mgmtFee[66])
Write-Host ("Repay     : Jan27={0}  Oct27={1}  Nov27={2}  Dec27={3}" -f `
    $repay[7], $repay[16], $repay[17], $repay[18])
$repaySum = ($repay | Measure-Object -Sum).Sum
Write-Host ("Repay sum : {0}  (expected 14499.99)" -f $repaySum)
Write-Host ("DirectRec : Jun28={0}  Jul28={1}  Jan30={2}  Dec31={3}" -f `
    $directRec[24], $directRec[25], $directRec[43], $directRec[66])

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
