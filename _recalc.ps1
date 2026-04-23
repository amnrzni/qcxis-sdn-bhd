# _recalc.ps1 — Master recompute for QCXIS_Forecast_Optimum.csv
#
# v5 board-aligned model (Apr-2026 refresh):
#   • Revenue — Franchise fee (RM1/client/mo) computed from accelerated outlet ramp:
#       226 outlets (Jun-26) → 500 outlets (Dec-28), flat 500 thereafter (Optimum scenario).
#     capacity 120 clients/outlet, realisation 88%, seasonal factors preserved.
#   • Revenue — OHXEM international (USD 2/student/mo @ FX 4.40 = RM 8.80):
#       2 outlets (Jun-26) → 3 (Dec-26) → 15 (Dec-27) → 50 (Dec-28), flat 50 thereafter.
#     capacity 90 students/outlet, realisation 70%, seasonal factors preserved.
#   • HR & Portrait module revenue read as-is from CSV (independent customer acquisition).
#   • Rev_Total = Fee + OHXEM + HR + Portrait (recomputed; drives all downstream triggers).
#   • CEO/DCEO salary tied to revenue milestones (RM27k → RM3,900 ; RM40k → RM5,000)
#     with 5% p.a. increment from the January following the RM5k milestone.
#   • Contingency = 10% of (payroll + infra mgmt fee + infra direct recurring + corporate one-offs).
#   • Infra management fee: flat RM1,000/mo retainer through 2031 (flexible, board-revisable).
#   • Hardware repayment (RM14,499.99) starts Jan-2027 (tightened from Jul-27; RM100k paid-up
#     removes the cash-flow reason to defer). Scaled tiers unchanged:
#       RM1,000 base → RM1,500 when Rev_Total > RM35k ×2 consec mo
#                    → RM2,000 when Rev_Total > RM45k ×2 consec mo.
#     OHXEM revenue is included in Rev_Total and therefore tightens tier-triggers.
#   • Direct recurring suppliers (cPanel + Immunify + Colocation = RM990.05/mo) absorbed
#     by QCXIS from Jul-2028 onwards, with 3% annual escalation from Jan-2030.
#   • Infra upgrade CAPEX (QCXIS-funded, post-takeover): Jul-2029 RM10k, Jul-2030 RM15k, Jul-2031 RM20k.
#   • Paid-up capital of RM100,000 booked Jun-2026 (replaces the prior RM50k 'injection'
#     framing — this is actual share capital already on the balance sheet).
#
# Output: writes back to QCXIS_Forecast_Optimum.csv in place.
# Re-runnable: idempotent if Cost_Mgmt_CorporateOneoffs / Rev_HR_Module / Rev_Portrait_Module
# are unchanged (Rev_FeeCollection, Rev_OHXEM, Rev_Total are always recomputed).

$csvPath = "QCXIS_Forecast_Optimum.csv"
$lines = Get-Content $csvPath
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

$corp   = $r['Cost_Mgmt_CorporateOneoffs']
$revHR  = $r['Rev_HR_Module']
$revPor = $r['Rev_Portrait_Module']

# ─── 0 · REVENUE — Franchise Fee Collection (accelerated ramp) ──────────────
# Optimum scenario: 226 outlets (Jun-26) → 500 (Dec-28), flat 500 thereafter.
# Model: clients = outlets × capacity × realisation × seasonal_factor
# Anchor Jun-26 at historical baseline (RM 20,178 = ~20k active clients on
# 226 outlets at sub-capacity utilisation). Ramp grows outlets AND utilisation
# toward full-capacity saturation (500 × 120 × 88% = 52,800 clients) by Dec-28.
$FRANCH_ANCHOR  = 20178.0   # Jun-26 baseline (existing clients × RM1)
$FRANCH_PEAK    = 52800.0   # 500 outlets × 120 cap × 88% realisation
$FRANCH_RAMP_END = 30       # col index for Dec-28 (peak reached)

# Seasonal multipliers (Jan..Dec) derived from existing 2030 pattern:
# Malaysian school cycle — strong Mar dip, mild Nov-Dec dip (SPM/PT3 exits).
$seasonal = @(1.016, 1.010, 0.930, 1.034, 1.033, 1.012, 1.003, 1.024, 1.005, 1.016, 0.972, 0.945)

# Column → calendar month (Jun-26 = col 0 = month index 5, i.e. June = idx 5 zero-based)
function monthIdxOf([int]$c) {
    # Jun-26 is c=0 → month index 5 (June)
    return (($c + 5) % 12)
}

$revFee = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $frac = if ($c -ge $FRANCH_RAMP_END) { 1.0 } else { [double]$c / [double]$FRANCH_RAMP_END }
    $base = $FRANCH_ANCHOR + ($FRANCH_PEAK - $FRANCH_ANCHOR) * $frac
    $revFee[$c] = [Math]::Round($base * $seasonal[(monthIdxOf $c)], 2)
}

# ─── 0b · REVENUE — OHXEM international (USD 2/student @ FX 4.40) ───────────
# Outlet ramp (Optimum): 2 (Jun-26) → 3 (Dec-26) → 15 (Dec-27) → 50 (Dec-28), flat after.
# Piecewise linear between anchor points.
$OHXEM_RATE_USD  = 2.0
$OHXEM_FX        = 4.40
$OHXEM_CAP       = 90.0
$OHXEM_REAL      = 0.70
$ohxemRatePerStudent = $OHXEM_RATE_USD * $OHXEM_FX   # RM 8.80

# Anchor points: (col_index, outlet_count)
# Jun-26 = c0 : 2  |  Dec-26 = c6 : 3  |  Dec-27 = c18 : 15  |  Dec-28 = c30 : 50  |  after : 50
function ohxemOutlets([int]$c) {
    $pts = @(@(0, 2), @(6, 3), @(18, 15), @(30, 50))
    if ($c -ge 30) { return 50.0 }
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
    $outlets = ohxemOutlets $c
    $students = $outlets * $OHXEM_CAP * $OHXEM_REAL
    $rev = $students * $ohxemRatePerStudent * $seasonal[(monthIdxOf $c)]
    $revOhx[$c] = [Math]::Round($rev, 2)
}

# ─── 0c · Rev_Total = Fee + OHXEM + HR + Portrait ──────────────────────────
$revTot = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $revTot[$c] = [Math]::Round($revFee[$c] + $revOhx[$c] + $revHR[$c] + $revPor[$c], 2)
}

# ─── 1 · CEO & DCEO milestone-driven salary ──────────────────────────────────
# RM3,000 baseline. Bump applies in month c if Rev_Total[c-1] AND Rev_Total[c-2]
# both clear the threshold (i.e. 2 consecutive prior months sustained the level).
$T1 = 27000.0   # RM3,900 trigger
$T2 = 40000.0   # RM5,000 trigger
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

# ─── 2 · IT Transfer (joins Jan-27, +5% p.a. from Jan-2028) ───────────────────
$itT = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    if ($c -lt 7) { $itT[$c] = 0; continue }
    $yr = yearOf $c
    $base = if ($yr -le 2027) { 2200.0 }
            else { [Math]::Round(2200.0 * [Math]::Pow(1.05, $yr - 2027), 6) }
    $itT[$c] = ctcMo $base
}

# ─── 3 · IT New Hire (joins Jan-27, +5% p.a. from Jan-2028) ───────────────────
$itN = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    if ($c -lt 7) { $itN[$c] = 0; continue }
    $yr = yearOf $c
    $base = if ($yr -le 2027) { 2000.0 }
            else { [Math]::Round(2000.0 * [Math]::Pow(1.05, $yr - 2027), 6) }
    $itN[$c] = ctcMo $base
}

# ─── 4 · Admin (joins Jun-27 = col 12, +5% p.a. from Jan-2028) ────────────────
$adm = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    if ($c -lt 12) { $adm[$c] = 0; continue }
    $yr = yearOf $c
    $base = if ($yr -le 2027) { 1900.0 }
            else { [Math]::Round(1900.0 * [Math]::Pow(1.05, $yr - 2027), 6) }
    $adm[$c] = ctcMo $base
}

# ─── 5 · Payroll Total ────────────────────────────────────────────────────────
$pay = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $pay[$c] = [Math]::Round($ceo[$c] + $dceo[$c] + $itT[$c] + $itN[$c] + $adm[$c], 2)
}

# ─── 6 · Infra Management Fee (flat RM1,000/mo retainer through 2031) ────────
# v4: flexible inter-company retainer covering advisory, backup infra, and any
# minor services not itemised in direct suppliers. Board-revisable.
$mgmtFee = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) { $mgmtFee[$c] = 1000.0 }

# ─── 7 · Infra Repayment — scaled tiers (Jan-27 start, tightened from Jul-27) ─
# Total obligation: RM14,499.99. Accelerates with QCXIS revenue performance:
#   Tier 0 (base): RM1,000/mo
#   Tier 1:        RM1,500/mo when Rev_Total[c-1] AND Rev_Total[c-2] > RM35,000
#   Tier 2:        RM2,000/mo when Rev_Total[c-1] AND Rev_Total[c-2] > RM45,000
# v5: start shifted to Jan-27 (col 7) now that RM100k paid-up provides runway.
# OHXEM revenue is folded into Rev_Total → tighter tier triggers.
# Final payment truncates to remaining balance.
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

# ─── 7b · Direct Recurring Suppliers (QCXIS absorbs from Jul-28, col 25) ─────
#   cPanel Premier     RM 300.00/mo
#   Immunify360        RM 200.00/mo
#   Server Colocation  RM 490.05/mo  (RM5,880.60/yr)
#   Subtotal           RM 990.05/mo
# 3% annual escalation from Jan-2030 onwards (flat through 2029).
$directBase = 990.05
$directRec = [double[]]::new($nCols)
for ($c = 25; $c -lt $nCols; $c++) {
    $yr = yearOf $c
    $rate = if ($yr -le 2029) { $directBase }
            else { [Math]::Round($directBase * [Math]::Pow(1.03, $yr - 2029), 2) }
    $directRec[$c] = $rate
}

# ─── 7c · Infra Upgrade CAPEX — QCXIS-funded post-takeover (Jul lump sums) ───
# Aggressive capacity build-out: 2029 RM10k · 2030 RM15k · 2031 RM20k.
$upgradeCapex = [double[]]::new($nCols)
$upgradeCapex[37] = 10000.0   # Jul-29
$upgradeCapex[49] = 15000.0   # Jul-30
$upgradeCapex[61] = 20000.0   # Jul-31

# ─── 8 · Cost_Infra_Total = mgmtFee + repay + directRec + upgradeCapex ───────
$infraTot = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $infraTot[$c] = [Math]::Round($mgmtFee[$c] + $repay[$c] + $directRec[$c] + $upgradeCapex[$c], 2)
}

# ─── 9 · Contingency = 10% × (payroll + mgmtFee + directRec + corp) ──────────
# Excludes hardware repayment (known balance-sheet paydown) and upgrade CAPEX
# (planned capital, not operational risk). Direct recurring IS included as
# vendor-invoice volatility that can drift.
$cont = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $cont[$c] = [Math]::Round(($pay[$c] + $mgmtFee[$c] + $directRec[$c] + $corp[$c]) * 0.10, 2)
}

# ─── 10 · Cost_Mgmt_Total ─────────────────────────────────────────────────────
$mgmtTot = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $mgmtTot[$c] = [Math]::Round($pay[$c] + $corp[$c] + $cont[$c], 2)
}

# ─── 11 · Cost_Total = Cost_Mgmt_Total + Cost_Infra_Total ─────────────────────
$costTot = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $costTot[$c] = [Math]::Round($mgmtTot[$c] + $infraTot[$c], 2)
}

# ─── 12 · Net & Cumulative ────────────────────────────────────────────────────
$net    = [double[]]::new($nCols)
$cumul  = [double[]]::new($nCols)
$running = 0.0
for ($c = 0; $c -lt $nCols; $c++) {
    $net[$c]    = [Math]::Round($revTot[$c] - $costTot[$c], 2)
    $running   += $net[$c]
    $cumul[$c]  = [Math]::Round($running, 2)
}

# ─── 13 · Paid-Up Capital & Cash Balance ──────────────────────────────────────
# RM100,000 paid-up share capital booked Jun-26 (actual equity on balance sheet,
# not a working-capital advance from QC Group). Justifies a buffer that survives
# the Extended scenario AND an HR/Portrait launch delay simultaneously.
# Cash balance = paid-up capital + Σ net.
$paidUp = [double[]]::new($nCols)
$paidUp[0] = 100000.0
$cashBal = [double[]]::new($nCols)
$acc = 0.0
for ($c = 0; $c -lt $nCols; $c++) {
    $acc += $paidUp[$c] + $net[$c]
    $cashBal[$c] = [Math]::Round($acc, 2)
}

# ─── Verification prints ──────────────────────────────────────────────────────
Write-Host "=== MILESTONES ==="
if ($idxT1 -ge 0) { Write-Host ("RM3,900 trigger   : col {0,2}  ({1})" -f $idxT1, $cols[$idxT1]) }
else              { Write-Host "RM3,900 trigger   : NOT REACHED in horizon" }
if ($idxT2 -ge 0) { Write-Host ("RM5,000 trigger   : col {0,2}  ({1})" -f $idxT2, $cols[$idxT2]) }
else              { Write-Host "RM5,000 trigger   : NOT REACHED in horizon" }

Write-Host ""
Write-Host "=== KEY VALUES ==="
Write-Host ("CEO base    : Jun26={0}  Jan27={1}  Mar27={2}  Jan28={3}  Mar28={4}  Jan29={5}  Jan31={6}" -f `
    $ceoBase[0], $ceoBase[7], $ceoBase[9], $ceoBase[19], $ceoBase[21], $ceoBase[31], $ceoBase[55])
Write-Host ("Payroll mo  : Jun26={0}  Jan27={1}  Mar27={2}  Jun27={3}  Mar28={4}  Apr28={5}" -f `
    $pay[0], $pay[7], $pay[9], $pay[12], $pay[21], $pay[22])
Write-Host ("MgmtFee mo  : Jun26={0}  Mar28={1}  Apr28={2}  Jan31={3}  Dec31={4}" -f `
    $mgmtFee[0], $mgmtFee[21], $mgmtFee[22], $mgmtFee[55], $mgmtFee[66])
Write-Host ("Repay mo    : Jan27={0}  Jul27={1}  Feb28={2}  Mar28={3}  Jun28={4}  Jul28={5}  Aug28={6}" -f `
    $repay[7], $repay[13], $repay[20], $repay[21], $repay[24], $repay[25], $repay[26])
$repaySum = ($repay | Measure-Object -Sum).Sum
Write-Host ("Repay total : {0}  (expected 14499.99)" -f $repaySum)
Write-Host ("DirectRec mo: Jun28={0}  Jul28={1}  Dec29={2}  Jan30={3}  Jan31={4}  Dec31={5}" -f `
    $directRec[24], $directRec[25], $directRec[42], $directRec[43], $directRec[55], $directRec[66])
Write-Host ("Upgrade mo  : Jul29={0}  Jul30={1}  Jul31={2}" -f `
    $upgradeCapex[37], $upgradeCapex[49], $upgradeCapex[61])
Write-Host ("Conting mo  : Jun26={0}  Jun27={1}  Jan28={2}" -f $cont[0], $cont[12], $cont[19])
Write-Host ("Net mo      : Jun26={0}  Jul27={1}  Sep28={2}" -f $net[0], $net[13], $net[27])
Write-Host ("Cumulative  : Dec26={0}  Dec27={1}  Dec28={2}  Dec31={3}" -f `
    $cumul[6], $cumul[18], $cumul[30], $cumul[66])
Write-Host ("CashBal     : Jun26={0}  Dec26={1}  Dec27={2}  Dec31={3}" -f `
    $cashBal[0], $cashBal[6], $cashBal[18], $cashBal[66])

# ─── Write CSV ────────────────────────────────────────────────────────────────
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

$overrides = @{
    'Rev_FeeCollection'        = $revFee
    'Rev_OHXEM'                = $revOhx
    'Rev_Total'                = $revTot
    'Cost_Mgmt_CEO'            = $ceo
    'Cost_Mgmt_DCEO'           = $dceo
    'Cost_Mgmt_IT_Transfer'    = $itT
    'Cost_Mgmt_IT_NewHire'     = $itN
    'Cost_Mgmt_Admin'          = $adm
    'Cost_Mgmt_Payroll_Total'  = $pay
    'Cost_Mgmt_Contingency'    = $cont
    'Cost_Mgmt_Total'          = $mgmtTot
    'Cost_Infra_ManagementFee'       = $mgmtFee
    'Cost_Infra_Repayment'           = $repay
    'Cost_Infra_Direct_Recurring'    = $directRec
    'Cost_Infra_Upgrade_CAPEX'       = $upgradeCapex
    'Cost_Infra_Total'               = $infraTot
    'Cost_Total'               = $costTot
    'Net_Profit_Loss'          = $net
    'Cumulative_Net'           = $cumul
    'PaidUpCapital'            = $paidUp
    'Cash_Balance'             = $cashBal
}

$newLines = @($lines[0], $origMap['Year'], $origMap['Month'])
# Legacy row names to drop (renamed/superseded in v5):
$drop = @('Capital_Injection')
foreach ($key in $r.Keys) {
    if ($drop -contains $key)         { continue }
    if ($overrides.ContainsKey($key)) { $newLines += fmtRow $key $overrides[$key] }
    else                              { $newLines += $origMap[$key] }
}
# Append override keys not present in source (Rev_OHXEM, PaidUpCapital, Cash_Balance on first run).
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
        if ($try -eq 0) { Write-Host "CSV file locked (open in editor?) \u2014 retrying for 8s..." -ForegroundColor Yellow }
        Start-Sleep -Seconds 1
    }
}
if (-not $written) {
    Write-Host "ERROR: Could not write $csvPath after 8 retries. Close the file and re-run." -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "=== Written: $csvPath ($($newLines.Count) rows) ==="
