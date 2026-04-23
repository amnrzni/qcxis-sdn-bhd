$base = "c:\Users\ADMIN\Desktop\Workspace\qcxis-sdn-bhd"
$v = Get-Content "$base\QCXIS_Forecast_Optimum.csv" -Encoding UTF8

# New arrays
$mgmtFee   = ,1000 * 67
$repay     = (,0 * 7) + (,1000 * 14) + @(499.99) + (,0 * 45)
$infraTotal = for ($i = 0; $i -lt 67; $i++) { [math]::Round($mgmtFee[$i] + $repay[$i], 2) }

$oldCT  = ($v[18] -split ",")[1..67] | ForEach-Object { [double]$_ }
$newCT  = for ($i = 0; $i -lt 67; $i++) { [math]::Round($oldCT[$i] - 3000 + $infraTotal[$i], 2) }

$rev    = ($v[6] -split ",")[1..67] | ForEach-Object { [double]$_ }
$newNet = for ($i = 0; $i -lt 67; $i++) { [math]::Round($rev[$i] - $newCT[$i], 2) }

$cum = 0.0
$newCum = for ($i = 0; $i -lt 67; $i++) { $cum = [math]::Round($cum + $newNet[$i], 2); $cum }

# Build row strings
$row_MgmtFee = "Cost_Infra_ManagementFee," + ($mgmtFee -join ",")
$row_Repay   = "Cost_Infra_Repayment,"     + ($repay   -join ",")
$row_InfraT  = "Cost_Infra_Total,"         + ($infraTotal -join ",")
$row_CostT   = "Cost_Total,"               + ($newCT  -join ",")
$row_Net     = "Net_Profit_Loss,"          + ($newNet -join ",")
$row_Cum     = "Cumulative_Net,"           + ($newCum -join ",")

# Rebuild 22-row file
$out = @(
    $v[0],  $v[1],  $v[2],  $v[3],  $v[4],  $v[5],  $v[6],
    $row_MgmtFee,
    $row_Repay,
    $row_InfraT,
    $v[9],  $v[10], $v[11], $v[12], $v[13], $v[14],
    $v[15], $v[16], $v[17],
    $row_CostT,
    $row_Net,
    $row_Cum
)

$joined = $out -join "`r`n"
# Write to new file (avoids lock on original)
$outPath = "$base\QCXIS_Forecast_Optimum_new.csv"
[System.IO.File]::WriteAllText($outPath, $joined, [System.Text.Encoding]::UTF8)

# Also save individual rows for replace_string_in_file
$rows = @{
    MgmtFee   = $row_MgmtFee
    Repay     = $row_Repay
    InfraT    = $row_InfraT
    CostT     = $row_CostT
    Net       = $row_Net
    Cum       = $row_Cum
}
$rows | ConvertTo-Json | Set-Content "$base\_rows.json" -Encoding UTF8

# Verify
$chk = Get-Content $outPath -Encoding UTF8
Write-Host "Rows: $($chk.Count)"
for ($i = 7; $i -le 10; $i++) { Write-Host "Row $i`: $(($chk[$i] -split ',')[0])" }
Write-Host "MgmtFee[Jun-26]    : $(($chk[7]  -split ',')[1])"
Write-Host "Repay[Jan-27]      : $(($chk[8]  -split ',')[8])"
Write-Host "Repay[Feb-28]      : $(($chk[8]  -split ',')[21])"
Write-Host "Repay[Mar-28]      : $(($chk[8]  -split ',')[22])"
Write-Host "InfraTotal[Jun-26] : $(($chk[9]  -split ',')[1])"
Write-Host "InfraTotal[Jan-27] : $(($chk[9]  -split ',')[8])"
Write-Host "CostTotal[Jun-26]  : $(($chk[19] -split ',')[1])"
Write-Host "Net[Jun-26]        : $(($chk[20] -split ',')[1])"
Write-Host "Net[Jan-27]        : $(($chk[20] -split ',')[8])"
Write-Host "Cum[Dec-31]        : $(($chk[21] -split ',')[67])"
