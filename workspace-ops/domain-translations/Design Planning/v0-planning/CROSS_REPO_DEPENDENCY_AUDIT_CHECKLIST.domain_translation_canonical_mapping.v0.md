# CROSS_REPO_DEPENDENCY_AUDIT_CHECKLIST

## Purpose
Track migration of shared CitySV/CITT translation dependencies across all workspace repos before any freeze/deprecate/retire action is allowed.

## Hard Guardrail
- Do not freeze, deprecate, or retire shared translation tables while any active consumer remains.
- CitySV-named surfaces remain safe/operational until cross-repo reference migration is complete and approved.
- OPIS/DTN-adjacent consumers must be included in dependency sign-off.

## In-Scope Legacy Translation Surfaces
- dbo.CitySV_OrdersUpload_GravitateProduct_XREF
- dbo.CitySV_OrdersUpload_GravitateTerminal_XREF
- dbo.CitySV_OrdersUpload_GravitateVendor_XREF
- dbo.PDI_CITT_Axxis_Grav_PDI_Products_Clone
- dbo.PDI_CITT_Axxis_Grav_PDI_Terminals_Clone
- dbo.PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone
- dbo.Gravitate_PDI_Master_XREF
- dbo.PDI_Carbon_Contract_XREF

## Repo Audit Matrix (2026-05-05)

| Repo | Legacy Dependency Evidence | Risk | Migration Status | Freeze Eligible |
|---|---|---|---|---|
| dcc-pricing-supply | Planning/validation artifacts reference CITT and CitySV xref sources for parity and inventory evidence | Medium | TRACKING_ONLY | NO |
| gravitate-orders | Runtime SQL view joins direct CitySV xref tables (product, terminal, vendor-stage) | High | NOT_STARTED | NO |
| citysv-prices | Runtime SQL view joins direct CITT clone tables; additional test view joins CitySV xref tables | High | NOT_STARTED | NO |
| citysv-costs | README documents dependency on Gravitate_PDI_Master_XREF ingest path | Medium | NOT_STARTED | NO |
| csl-pricing-supply | No direct legacy object references found in current scan | Low | N/A | NO (global gate not met) |
| pdi-clone-core | No direct legacy object references found in current scan | Low | N/A | NO (global gate not met) |

## Evidence Anchors

### gravitate-orders
- artifacts/sql/vw_PDI_ODE_Gravitate_Stage.sql joins:
  - dbo.CitySV_OrdersUpload_GravitateVendor_XREF_Stage
  - dbo.CitySV_OrdersUpload_GravitateTerminal_XREF
  - dbo.CitySV_OrdersUpload_GravitateProduct_XREF
- runbook and README also state current terminal resolution via CitySV terminal xref.

### citysv-prices
- sql/views/vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice.sql joins:
  - dbo.PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone
  - dbo.PDI_CITT_Axxis_Grav_PDI_Terminals_Clone
  - dbo.PDI_CITT_Axxis_Grav_PDI_Products_Clone
- sql/views/vw_CitySV_OrderPrice_F_Row_Match_XREF_TEST.sql joins CitySV xref tables.
- OPIS references observed in RUNBOOK and SQL object index context.

### citysv-costs
- README notes sp_Gravitate_PDI_Master_XREF_INGEST dependency in Gravitate_Orders pipeline flow.

### dcc-pricing-supply
- Validation and planning docs intentionally reference CITT/legacy objects for parity and inventory controls.

## Required Migration Actions
1. gravitate-orders
- Replace legacy CitySV xref joins in runtime stage view with canonical contract views.
- Keep legacy tables active during parallel validation window.
- Record parity output and blocker deltas after switch.

2. citysv-prices
- Replace direct CITT clone joins in operational price resolver with canonical contract views.
- Validate OPIS path output parity after migration.
- Keep legacy CITT tables active until parity and sign-off complete.

3. citysv-costs
- Confirm whether Gravitate_PDI_Master_XREF ingest is runtime-critical or historical-only.
- If runtime-critical, add explicit migration path to canonical contract view surface.

4. cross-workspace
- Confirm no remaining active consumer references in all repos listed above.
- Obtain Business Manager + Steward sign-off before any read-only/freeze proposal.

## Exit Criteria For Any Freeze Proposal
- [ ] Runtime consumers in gravitate-orders migrated and validated.
- [ ] Runtime consumers in citysv-prices migrated and validated (including OPIS/DTN-adjacent outputs).
- [ ] citysv-costs dependency status resolved and migrated if needed.
- [ ] No unresolved consumer references in dcc-pricing-supply operational scripts.
- [ ] Signed dependency audit approval captured.
- [ ] Explicit go decision issued by Jason.

## Current Decision
- Freeze/deprecate/retire actions are blocked.
- Shared CitySV/CITT translation surfaces remain operational.
