# _update_infra.ps1 — DEPRECATED
#
# Infra logic (mgmt fee growth + hardware repayment schedule) is now part of
# the master recompute script `_recalc.ps1`. Run that instead.

Write-Warning "_update_infra.ps1 is deprecated. Running _recalc.ps1 instead."
& (Join-Path $PSScriptRoot '_recalc.ps1')
