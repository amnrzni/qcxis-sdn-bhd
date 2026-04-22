$lines = Get-Content QCXIS_Forecast_Optimum.csv
function rowsum($key, $s, $e) {
    $line = $lines | Where-Object { ($_ -split ',')[0] -eq $key }
    $f = $line -split ','
    $sum = 0
    for ($i = $s+1; $i -le $e+1; $i++) { $sum += [double]$f[$i] }
    [Math]::Round($sum, 2)
}
$ranges = @{ 2026=@(0,6); 2027=@(7,18); 2028=@(19,30); 2029=@(31,42); 2030=@(43,54); 2031=@(55,66) }
foreach ($k in 'Cost_Mgmt_Payroll_Total','Cost_Mgmt_Contingency','Cost_Mgmt_Total','Cost_Infra_ManagementFee','Cost_Infra_Repayment','Cost_Infra_Total','Cost_Total','Rev_Total','Net_Profit_Loss','Cost_Mgmt_CorporateOneoffs') {
    $out = $k + " :"
    foreach ($yr in 2026,2027,2028,2029,2030,2031) { $r=$ranges[$yr]; $out += " $yr=$(rowsum $k $r[0] $r[1])" }
    Write-Host $out
}
# Cumulative at year end
$cumLine = $lines | Where-Object { ($_ -split ',')[0] -eq 'Cumulative_Net' }
$cf = $cumLine -split ','
Write-Host "Cumulative_Net year-end: 2026=$($cf[7]) 2027=$($cf[19]) 2028=$($cf[31]) 2029=$($cf[43]) 2030=$($cf[55]) 2031=$($cf[67])"
