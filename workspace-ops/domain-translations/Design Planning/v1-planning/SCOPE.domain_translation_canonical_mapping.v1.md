# V1 Scope: Gravitate Product/Terminal/Vendor Domain Migration

**Iteration:** v1 (citysv-costs/citysv-prices CITT table canonicalization)
**Status:** Planning
**Date:** 2026-05-13
**Owner:** Jason Vassar
**Sponsor:** COIL Pricing Supply Team

## Scope Constraint (Critical)

**Database/Pipeline Boundary:**
- **IN SCOPE (v1):** PDI_PricingLink — Gravitate FTP pricing feed (`sp_Gravitate_FTP_UPLOAD_SELECT` and dependent procedures)
- **OUT OF SCOPE (v1):** COL_WH — `sp_Gravitate_Price_Feed` remains independent; separate migration if/when needed

This v1 iteration migrates only the Gravitate vendor/terminal/contract mappings used by the citysv-prices cost-push pipeline in PricingLink. COL_WH is explicitly excluded.

---

## Executive Summary

Migrate four legacy XREF/CITT tables from citysv-costs and citysv-prices into the canonical `Xref_Registry` system:
1. `PDI_CITT_Axxis_Grav_PDI_Products_Clone` (58 rows, product mappings)
2. `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone` (90 rows, terminal mappings)
3. `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone` (53 rows, vendor/contract mappings)
4. `Gravitate_PDI_Master_XREF` (199 rows, composite bridge for FTP upload)

Replace direct table joins with three contract views:
- `vw_Xref_Product_Gravitate_To_PDI`
- `vw_Xref_Terminal_Gravitate_To_PDI`
- `vw_Xref_Contract_Axxis_To_PDI` (new STP grain)

---

## Current State

### Consuming View
- **Primary:** `vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice` (citysv-prices)
  - Joins all three CITT tables (Products, Terminals, Vend_FIVC)
  - Used by cost-resolution pipeline
  - No direct downstream SQL dependencies identified

### Secondary (Database-level)
- **sp_Gravitate_FTP_UPLOAD_SELECT** (PDI_PricingLink)
  - Consumes `Gravitate_PDI_Master_XREF` directly
  - Bridge table linking costs to Gravitate vendors/terminals/products
  - Recently patched to exclude unresolved product xrefs

### Risk Profile
- **Stale data risk:** CITT tables are cached clones of PDI product/terminal strings. Changes to PDI product names may not propagate immediately.
- **No `_Key` anchor (Products/Terminals):** Only `_ID` cached; increases row-identity drift risk.
- **Mixed responsibilities (Master XREF):** Bridges four different business domains in one join; high conflict risk.

---

## Migration Objectives

1. **Eliminate CITT caching risk** by moving to registry-seeded entries with `_Key` anchors where possible.
2. **Establish contract views** as the sanctioned pipeline interface, replacing direct CITT joins.
3. **Preserve operational semantics** — no change to cost-resolution logic or FTP output.
4. **Document lineage** — every registry entry must show which legacy table it was seeded from and which contract view consumes it.

---

## Out of Scope (v1)

- Refactoring `Gravitate_PDI_Master_XREF` decomposition (high risk; deferred to v1.1)
- Live derivation of product/terminal `_ID` values (registry rows store cached `_ID` for now)
- Migration of `PDI_Carbon_Contract_XREF` (domain ownership unclear; deferred)
- Changes to `vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice` business logic

---

## Deliverables

1. **Design Specification** — Registry entry schema and contract view definitions
2. **Seed Script** — SQL to populate registry from frozen legacy tables
3. **Contract Views** — Three replacement views (Product, Terminal, Contract)
4. **Compatibility Shims** — Optional redirects to _Freeze tables during transition
5. **Validation Plan** — Row-count reconciliation, join cardinality tests, lineage proof
6. **Deprecation Roadmap** — Timeline for freezing and removing legacy tables

---

## Success Criteria

- [ ] All registry entries created with correct source/target keys and `_Key` anchors
- [ ] Contract views match legacy join output (byte-for-byte on key columns)
- [ ] No new dependencies added to frozen legacy tables
- [ ] `vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice` joins contract views instead of CITT clones
- [ ] FTP upload output unchanged (row count, schema, lineage)
- [ ] Legacy tables marked `_Freeze` with compatibility shims in place
