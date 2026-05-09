# PDI-SQL-02 ETL Copydown Runtime Path

Status: verified on 2026-05-09
Scope: Gravitate Orders SQL Agent job runtime on PDI-SQL-02

## Canonical Runtime Script Root

- Runtime script root on SQL-02: `C:\ETL Copydown\Scripts`
- UNC from operator workstation: `\\PDI-SQL-02\c$\ETL Copydown\Scripts`

This is the path SQL Agent job steps are currently executing from.

## Verification Evidence

Validated from operator workstation using UNC checks:

- `\\PDI-SQL-02\c$\ETL Copydown\Scripts` exists: `True`
- `\\PDI-SQL-02\c$\Users\svc-fuelpriceauto\ETL Copydown\Scripts` exists: `False`
- `\\PDI-SQL-02\c$\Users\svc-fuelpriceauto\Documents\ETL Copydown\Scripts` exists: `False`
- `\\PDI-SQL-02\c$\Users\svc-fuelpriceauto\OneDrive\ETL Copydown\Scripts` exists: `False`

Verified files present in canonical runtime root:

- `Export-OrdersUploadCSV-Profile69.ps1` (legacy)
- `Invoke-PDI_ODE_Gravitate_Export.ps1` (new)
- `Invoke-OrdersUpload_Profile69_DailyDriver.ps1`
- `Invoke-OrdersUpload_Profile69_PostImportPipeline.ps1`

## Operational Rule

- Deploy and update SQL Agent commands against `C:\ETL Copydown\Scripts` unless a new approved runtime root is explicitly validated in SQL Agent step command text.
- Do not infer service-account profile paths without direct on-host or SQL Agent command evidence.

## Quick Validation Commands

```powershell
Test-Path "\\PDI-SQL-02\c$\ETL Copydown\Scripts"
Test-Path "\\PDI-SQL-02\c$\Users\svc-fuelpriceauto\ETL Copydown\Scripts"
Get-ChildItem "\\PDI-SQL-02\c$\ETL Copydown\Scripts" -Filter "*Profile69*.ps1"
Get-ChildItem "\\PDI-SQL-02\c$\ETL Copydown\Scripts" -Filter "*Gravitate*Export*.ps1"
```

## Follow-on Control

If runtime root changes in future, update this file and the deploy artifacts together:

- `gravitate-orders/artifacts/Deploy-GravitateIngestJob.ps1`
- `gravitate-orders/artifacts/Deploy-GravitateExportJob.ps1`
- `gravitate-orders/artifacts/Deploy-GravitatePostImportJob.ps1`
