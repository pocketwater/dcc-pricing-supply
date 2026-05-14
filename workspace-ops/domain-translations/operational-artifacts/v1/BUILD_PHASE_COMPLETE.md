# V1 Status: Build Phase Complete

**Date:** 2026-05-13
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

### Next: Deployment Phase (Requires ADR Decision)

**Blocker:** Before executing the seed and repointing sp_Gravitate_FTP_UPLOAD_SELECT to consume the new view, an ADR decision is required per dcc-pricing-supply governance.

**Execution Path:**
1. Create ADR record with:
   - Current state: `sp_Gravitate_FTP_UPLOAD_SELECT` consumes `Gravitate_PDI_Master_XREF` directly
   - Proposed state: Consume `vw_Xref_Contract_Gravitate_To_PDI` (registry-sourced)
   - Rationale: Centralized mapping, eliminates multi-source risks, improves auditability
   - Rollback: Revert to legacy view (procedure modification is reversible within ~ 2 minutes)

2. Execute DEPLOYMENT_MANIFEST.sql in sequence:
   - Phase 1: Pre-deployment validation
   - Phase 2: Run SEED script (batch mode)
   - Phase 3: Verify seed (checks row count, multi-type mappings)
   - Phase 4: Create view (batch mode)
   - Phase 5: Post-deployment validation (join test, view row count)

3. Execute procedure repointing:
   - Modify sp_Gravitate_FTP_UPLOAD_SELECT to consume `vw_Xref_Contract_Gravitate_To_PDI`
   - Test FTP feed: confirm 0 pollution in output CSV
   - Compare row counts to baseline (should match or increase only if legacy data was incomplete)

4. Freeze legacy table (optional, post-validation):
   - Rename Gravitate_PDI_Master_XREF to `_Legacy` suffix
   - Create compatibility shim if other code depends on it

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
✅ 200 rows inserted into Xref_Registry
✅ vw_Xref_Contract_Gravitate_To_PDI returns 200 rows
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
├── vw_Xref_Contract_Gravitate_To_PDI.sql
├── DEPLOYMENT_MANIFEST.sql
└── (README placeholder for execution instructions)
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
