$csv = "QCXIS_Forecast_Optimum.csv"
$lines = Get-Content $csv
$h = $lines[0] -split ','
$cols = $h[1..($h.Count-1)]
$nCols = $cols.Count  # 67

# Parse all rows (skip Year and Month header rows)
$r = [ordered]@{}
foreach ($l in $lines[1..($lines.Count-1)]) {
    $f = $l -split ','
    $key = $f[0]
    if ($key -eq 'Year' -or $key -eq 'Month') { continue }
    $r[$key] = [double[]]($f[1..($f.Count-1)] | ForEach-Object { [double]$_ })
}

function ctcMo([double]$base) { [Math]::Round(($base + 450) * 1.1495 + 150, 2) }

# ── 1A: IT Transfer ──────────────────────────────────────────────────
# Col 7  = Jan-27 (start, base 2200, no increment yet)
# Col 19 = Jan-28 (+5%), Col 31 = Jan-29, Col 43 = Jan-30, Col 55 = Jan-31
$itT = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    if ($c -lt 7) { $itT[$c] = 0; continue }
    $base = if     ($c -ge 55) { [Math]::Round(2200*[Math]::Pow(1.05,4), 6) }
            elseif ($c -ge 43) { [Math]::Round(2200*[Math]::Pow(1.05,3), 6) }
            elseif ($c -ge 31) { [Math]::Round(2200*[Math]::Pow(1.05,2), 6) }
            elseif ($c -ge 19) { [Math]::Round(2200*1.05, 6) }
            else               { 2200 }
    $itT[$c] = ctcMo($base)
}

# ── 1B: IT New Hire ──────────────────────────────────────────────────
$itN = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    if ($c -lt 7) { $itN[$c] = 0; continue }
    $base = if     ($c -ge 55) { [Math]::Round(2000*[Math]::Pow(1.05,4), 6) }
            elseif ($c -ge 43) { [Math]::Round(2000*[Math]::Pow(1.05,3), 6) }
            elseif ($c -ge 31) { [Math]::Round(2000*[Math]::Pow(1.05,2), 6) }
            elseif ($c -ge 19) { [Math]::Round(2000*1.05, 6) }
            else               { 2000 }
    $itN[$c] = ctcMo($base)
}

# ── 1C: Admin (joins Jun-27 = col 12) ────────────────────────────────
$adm = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    if ($c -lt 12) { $adm[$c] = 0; continue }
    $base = if     ($c -ge 55) { [Math]::Round(1900*[Math]::Pow(1.05,4), 6) }
            elseif ($c -ge 43) { [Math]::Round(1900*[Math]::Pow(1.05,3), 6) }
            elseif ($c -ge 31) { [Math]::Round(1900*[Math]::Pow(1.05,2), 6) }
            elseif ($c -ge 19) { [Math]::Round(1900*1.05, 6) }
            else               { 1900 }
    $adm[$c] = ctcMo($base)
}

# ── 1D: Payroll Total (sum of CEO + DCEO + IT_T + IT_N + Adm) ────────
$ceo  = $r['Cost_Mgmt_CEO']
$dceo = $r['Cost_Mgmt_DCEO']
$pay  = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $pay[$c] = [Math]::Round($ceo[$c] + $dceo[$c] + $itT[$c] + $itN[$c] + $adm[$c], 2)
}

# ── 1E: Contingency (recalculate with MGMT_MO = 1000) ────────────────
$corp = $r['Cost_Mgmt_CorporateOneoffs']
$cont = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $cont[$c] = [Math]::Round(($pay[$c] + 1000 + $corp[$c]) * 0.05, 2)
}

# ── 1F: Cost_Mgmt_Total ───────────────────────────────────────────────
$mgmtTot = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $mgmtTot[$c] = [Math]::Round($pay[$c] + $corp[$c] + $cont[$c], 2)
}

# ── 1G: Cost_Total = Cost_Mgmt_Total + Cost_Infra_Total ──────────────
$infraTot = $r['Cost_Infra_Total']
$costTot  = [double[]]::new($nCols)
for ($c = 0; $c -lt $nCols; $c++) {
    $costTot[$c] = [Math]::Round($mgmtTot[$c] + $infraTot[$c], 2)
}

# ── 1H: Net & Cumulative ──────────────────────────────────────────────
$revTot = $r['Rev_Total']
$net    = [double[]]::new($nCols)
$cumul  = [double[]]::new($nCols)
$running = 0
for ($c = 0; $c -lt $nCols; $c++) {
    $net[$c]   = [Math]::Round($revTot[$c] - $costTot[$c], 2)
    $running  += $net[$c]
    $cumul[$c] = [Math]::Round($running, 2)
}

# ── Verification prints ────────────────────────────────────────────────
Write-Host "=== VERIFICATION ==="
Write-Host "IT_Transfer:   Jun26=$($itT[0])  Jan27=$($itT[7])  Jan28=$($itT[19])  Jan29=$($itT[31])  Jan30=$($itT[43])  Jan31=$($itT[55])"
Write-Host "IT_NewHire:    Jun26=$($itN[0])  Jan27=$($itN[7])  Jan28=$($itN[19])  Jan29=$($itN[31])  Jan30=$($itN[43])  Jan31=$($itN[55])"
Write-Host "Admin:         Jun26=$($adm[0])  Jun27=$($adm[12])  Jan28=$($adm[19])  Jan29=$($adm[31])  Jan30=$($adm[43])  Jan31=$($adm[55])"
Write-Host "Payroll:       Jun26=$($pay[0])  Jun27=$($pay[12]) Jan27=$($pay[7])  Jan28=$($pay[19])  Jan29=$($pay[31])"
Write-Host "Contingency:   Jun26=$($cont[0])  Oct26=$($cont[4])  Jun27=$($cont[12])  Jan28=$($cont[19])"
Write-Host "Cost_Mgmt_Tot: Jun26=$($mgmtTot[0])  Jun27=$($mgmtTot[12])"
Write-Host "Cost_Total:    Jun26=$($costTot[0])  Jun27=$($costTot[12])"
Write-Host "Net:           Jun26=$($net[0])  Jan27=$($net[7])  Jun27=$($net[12])"
Write-Host "Cumulative:    Jun26=$($cumul[0])  Dec26=$($cumul[6])  Dec27=$($cumul[18])  Dec31=$($cumul[66])"

# ── Write new CSV ─────────────────────────────────────────────────────
function fmtRow($key, [double[]]$vals) {
    $v = $vals | ForEach-Object { 
        if ($_ -eq [Math]::Truncate($_)) { "$([int64]$_)" } else { "$_" }
    }
    return "$key," + ($v -join ',')
}

# Build lookup for original lines by key
$origMap = @{}
foreach ($l in $lines) {
    $f = $l -split ','
    $origMap[$f[0]] = $l
}

$overrides = @{
    'Cost_Mgmt_IT_Transfer'   = $itT
    'Cost_Mgmt_IT_NewHire'    = $itN
    'Cost_Mgmt_Admin'         = $adm
    'Cost_Mgmt_Payroll_Total' = $pay
    'Cost_Mgmt_Contingency'   = $cont
    'Cost_Mgmt_Total'         = $mgmtTot
    'Cost_Total'              = $costTot
    'Net_Profit_Loss'         = $net
    'Cumulative_Net'          = $cumul
}

$newLines = @($lines[0], $origMap['Year'], $origMap['Month'])
foreach ($key in $r.Keys) {
    if ($overrides.ContainsKey($key)) {
        $newLines += fmtRow $key $overrides[$key]
    } else {
        $newLines += $origMap[$key]
    }
}

$newLines | Set-Content "_recalc_output.csv" -Encoding UTF8
Write-Host "=== Written to _recalc_output.csv ==="
