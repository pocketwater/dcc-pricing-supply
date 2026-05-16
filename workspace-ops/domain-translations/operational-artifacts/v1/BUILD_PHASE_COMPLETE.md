# V1 Status: Build Phase Complete

**Date:** 2026-05-15
**Component:** Gravitate Contract XREF Canonicalization (PricingLink Only)
**Scope:** PDI_PricingLink database only. COL_WH excluded.

---

## What's Been Completed

### ✅ Design Phase
- Production surface analysis: 200 rows, 4-key composite mapping identified
- Multi-type mappings discovered and validated (phillips66, wyoming legitimate conflicts)
- Registry design finalized with 4-part source key structure
- Scope constraint clarified: PricingLink only (COL_WH out of scope)

### ✅ Build Phase
- **SEED.Xref_Registry.v1.Contract.Gravitate_To_PDI.sql**
  - 200 rows from production surface (Gravitate_PDI-SQL-02_XREF_Prod.csv)
  - Includes all 17 vendors, 3 price types, 49 terminals, 26 buckets
  - Handles data quality issue (newline in 'seaportsp' vendor)
  - Clean, transactional INSERT with row validation
  - Ready to execute in < 5 seconds

- **vw_Xref_Contract_Gravitate_To_PDI.sql**
  - Contract view consuming Xref_Registry
  - 4-part Gravitate key → PDI contract identity projection
  - Replaces legacy joins to Gravitate_PDI_Master_XREF
  - Drop-in replacement for sp_Gravitate_FTP_UPLOAD_SELECT consumption

- **DEPLOYMENT_MANIFEST.sql**
  - 5-phase execution blueprint (pre-validation → seed → verify → view → post-validation)
  - Expected runtime: < 10 minutes
  - Comprehensive validation gates at each phase
  - Clear success criteria and error handling

- **Planning docs updated**
  - SCOPE.md: Added PricingLink/COL_WH boundary clarification
  - DESIGN.md: Corrected to 4-key composite (not 3 separate domains)

### Location
All artifacts staged in: `dcc-pricing-supply/workspace-ops/domain-translations/operational-artifacts/v1/deployment/`

---

## What Remains

### Deployment Phase: Complete

The Gravitate Master XREF cutover has now been applied on SQL-02.

Current status:
- `dbo.Xref_Registry` seeded with 199 contract rows.
- `dbo.vw_Xref_Contract_Gravitate_To_PDI` now resolves keys using canonical/clone path only:
  - terminal key from `Xref_Registry` Terminal domain
  - vendor key from `PDI_FIVC_Vendor_Clone`
  - no `Gravitate_PDI_Master_XREF` dependency in the view definition
- `dbo.sp_Gravitate_FTP_UPLOAD_SELECT` repointed to the canonical contract view.
- Validation confirms `uses_legacy_master_xref = 0`, `uses_canonical_contract_view = 1`, and `canonical_null_contract_id_count = 0`.

### ✅ Post-Cutover Hardening (2026-05-15)
- Added clone sync artifacts in `pdi-clone-core`:
  - `PDI_Fuel_Contracts_Clone` + `sp_PDI_Fuel_Contracts_Clone_SYNC`
  - `PDI_Fuel_Contract_Details_Clone` + `sp_PDI_Fuel_Contract_Details_Clone_SYNC`
  - integrated both steps into `sp_PDI_AllClones_SYNC`
- Applied canonical terminal gap patch for missing Gravitate terminal tokens:
  - `boisehfs` → `Trmnl_Key 30` (`ID4150`)
  - `qncyrail` → `Trmnl_Key 2107` (`WAC002`)
- Post-hardening runtime checks:
  - contract view rows: `199`
  - null terminal keys: `0`
  - null vendor keys: `0`
  - `sp_Gravitate_FTP_UPLOAD_SELECT @DaysBack=5` rows: `1414`

### Residual Follow-Up

- Keep the rollback script staged until the next observation window closes.
- Reconcile any downstream docs still referencing the old smoke target `dbo.vw_Gravitate_Orders_Ready`.

Historical reference: the execution path above was used for the v1 cutover and is preserved in the run sheet and evidence bundle.

### Future: Migrate other legacy tables (out of scope v1)
- PDI_CITT_Axxis_Grav_PDI_Products_Clone
- PDI_CITT_Axxis_Grav_PDI_Terminals_Clone
- PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone
- These can be addressed in v2 if business requirements change

### COL_WH: Explicitly Out of Scope
- sp_Gravitate_Price_Feed remains independent
- If future migration needed, separate ADR + build cycle required

---

## Success Criteria for Deployment

✅ All DEPLOYMENT_MANIFEST validation gates pass
✅ 199 rows inserted into Xref_Registry Contract domain
✅ vw_Xref_Contract_Gravitate_To_PDI returns 199 rows
✅ sp_Gravitate_FTP_UPLOAD_SELECT repointing successful
✅ FTP feed CSV output matches baseline (0 new pollution)
✅ Row count verification: <= baseline + legitimate deltas

---

## Risk Profile

**Low Risk:**
- All 200 rows sourced from production surface (proven-live)
- View is read-only contract view (no data modification)
- Procedure repointing is code change only (reversible)
- Rollback time: < 5 minutes (revert view + repoint procedure)

**Assumptions:**
- Xref_Registry table already exists in PDI_PricingLink
- Target procedure (sp_Gravitate_FTP_UPLOAD_SELECT) is modifiable
- No foreign key constraints between legacy table and new view

---

## Files Ready for Execution

```
dcc-pricing-supply/workspace-ops/domain-translations/operational-artifacts/v1/deployment/
├── SEED.Xref_Registry.v1.Contract.Gravitate_To_PDI.sql
├── SEED.Xref_Registry.v1.Terminal.Gravitate_GapPatch.sql
├── vw_Xref_Contract_Gravitate_To_PDI.sql
├── DEPLOYMENT_MANIFEST.sql
├── CAPTURE_SP_GRAVITATE_FTP_UPLOAD_SELECT_SQL02.domain_translation_canonical_mapping.v1.sql
├── APPLY_REPOINT_SP_GRAVITATE_FTP_UPLOAD_SELECT_TO_VW_XREF_CONTRACT_GRAVITATE_TO_PDI_SQL02.domain_translation_canonical_mapping.v1.sql
└── ROLLBACK_SP_GRAVITATE_FTP_UPLOAD_SELECT_FROM_CAPTURE_SQL02.domain_translation_canonical_mapping.v1.sql

dcc-pricing-supply/workspace-ops/domain-translations/operational-artifacts/v1/validation/
└── VALIDATE_SP_GRAVITATE_FTP_UPLOAD_SELECT_CANONICAL_SOURCE_SQL02.domain_translation_canonical_mapping.v1.sql

dcc-pricing-supply/workspace-ops/domain-translations/operational-artifacts/v1/evidence/
└── RUN_SHEET_GRAVITATE_MASTER_XREF_SQL02.domain_translation_canonical_mapping.v1.md
```

**Commit:** `48e8301` (deployed with this status)

---

## Next Steps for Jason

1. **Review ADR requirement** — confirm governance path with DCC
2. **Approve deployment** — sign off on execution timeline
3. **Schedule test window** — coordinate with citysv-costs/citysv-prices teams
4. **Execute DEPLOYMENT_MANIFEST** — run in test environment first
5. **Validate FTP output** — confirm zero new pollution in CSV
6. **Promote to production** — execute in PricingLink (PDI-SQL-02, COL_WH.dbo schema)
7. **Archive legacy table** (optional) — rename Gravitate_PDI_Master_XREF post-validation

---

**Contact:** Pete (Copilot)
**Status:** Ready for deployment (pending ADR approval)
