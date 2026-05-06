# Domain Translation — Canonical Mapping v.0
**What this is, what it does, and what's next.**

---

## The Problem It Solves

Before this work, every pipeline that needed to translate a Gravitate or Axxis/CITT code into a PDI ID had its own private lookup table. There were at least six of them:

| Legacy Table | Used By |
|---|---|
| `CitySV_OrdersUpload_GravitateProduct_XREF` | gravitate-orders pipeline |
| `CitySV_OrdersUpload_GravitateTerminal_XREF` | gravitate-orders pipeline |
| `CitySV_OrdersUpload_GravitateVendor_XREF_Stage` | gravitate-orders pipeline |
| `PDI_CITT_Axxis_Grav_PDI_Products_Clone` | citysv-prices, CITT/Axxis pipelines |
| `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone` | citysv-prices, CITT/Axxis pipelines |
| `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone` | citysv-prices, CITT/Axxis pipelines |

Each table had its own maintenance path, no consistency checks, and no governance. When a mapping was wrong (e.g., `prm-91` pointing to the wrong PDI product), there was no single place to fix it.

---

## What Was Built

A canonical translation registry layer on **PDI-SQL-02 / PDI_PricingLink**:

```
dbo.Xref_Registry          — the single source of truth for all source → PDI translations
dbo.vw_Xref_Product_Gravitate_To_PDI    — pipeline-facing contract view, Product domain
dbo.vw_Xref_Terminal_Gravitate_To_PDI   — pipeline-facing contract view, Terminal domain
dbo.vw_Xref_Contract_Axxis_To_PDI       — contract view, Contract domain (seeded in future cycle)
dbo.vw_Xref_Destination_Gravitate_To_PDI — contract view, Destination domain (seeded in future cycle)
```

Supporting dimension tables govern the allowed values for domain, system, and status fields — so the registry can't drift into inconsistency.

### How the registry works

Every row in `Xref_Registry` says:
> "When a pipeline from **Source_System** presents **Source_Key_1** in **Domain_Name**, resolve it to **Target_Key** in PDI."

A filtered unique index prevents duplicate active mappings for the same source key. A trigger blocks whitespace in key fields. Check constraints enforce valid status values.

The contract views (`vw_Xref_*`) are what pipelines are supposed to join — never the registry table directly. This keeps the surface area stable even if the underlying registry evolves.

---

## What Was Seeded (as of 2026-05-05)

| Domain | Source System | Key Grain | Rows | Notes |
|---|---|---|---|---|
| Product | Gravitate | Short codes (`92e10`, `clruls2rdm`) | 41 | From CITT/Axxis-facing tables |
| Product | Gravitate | Descriptive names (`Clear ULSD2 Roadmaster`) | 92 | From Gravitate pipeline XREF — seeded today |
| Terminal | Gravitate | Short codes (`billingsco`, `BILOPIS`) | 84 | From CITT/Axxis-facing tables |
| Terminal | Gravitate | Descriptive names (`Cenex Glendive`, `BP Cherry Point`) | 45 | From Gravitate pipeline XREF — seeded today |

**Key discovery:** Gravitate and CITT/Axxis use entirely different key grain for the same PDI products and terminals. Short codes serve one consumer family; descriptive names serve the other. Both sets now live in the same registry, both resolve to the same PDI `Target_Key`.

The 4 terminals with no `PDI_Trmnl_ID` (`Lewiston Plant`, `P66 Ethanol Port Of Entry`, `Pacific NW Terminal Inc`, `Quincy Transloading Facility`) are pre-existing gaps in the legacy XREF — unresolvable before and after this work.

---

## What Was Corrected

During seeding, three legacy mapping errors were caught and fixed:

| Source Key | Was Pointing To | Corrected To | Business Meaning |
|---|---|---|---|
| `prm-91` | 2090092 (Gas Non-E 92 Premium) | **2090091** (Gas Non-E 91 Premium) | Wrong octane grade |
| `92e10` | 2010192 | **2010092** (Gas E10 92 Premium) | Wrong PDI ID |
| `pinebend` | no mapping | **MN3407** (Flint Hills Pine Bend, key 2150) | Missing terminal |

These are now correct in the registry. The legacy XREF tables were **not** changed — they remain live as-is.

---

## Current State of the gravitate-orders Pipeline

The stage view (`vw_Gravitate_Orders_Stage`) was updated to run **both** resolution paths in parallel:

- **Legacy joins** (authoritative for production today): `CitySV_OrdersUpload_GravitateProduct_XREF`, `CitySV_OrdersUpload_GravitateTerminal_XREF`
- **Canonical joins** (parallel, for parity verification): `vw_Xref_Product_Gravitate_To_PDI`, `vw_Xref_Terminal_Gravitate_To_PDI`

Six columns were added to the view output:

| Column | Meaning |
|---|---|
| `Canonical_PDI_Prod_ID` | Product ID from the registry |
| `Canonical_PDI_Prod_Key` | Product surrogate key from the registry |
| `Canonical_PDI_Trmnl_ID` | Terminal ID from the registry |
| `Canonical_PDI_Trmnl_Key` | Terminal surrogate key from the registry |
| `Prod_Xref_Parity` | MATCH / MISMATCH / BOTH_NULL / LEGACY_NULL / CANONICAL_NULL |
| `Trmnl_Xref_Parity` | MATCH / MISMATCH / BOTH_NULL / LEGACY_NULL / CANONICAL_NULL |

**Parity result (44,361 live rows):**
- MATCH: 44,051 rows
- BOTH_NULL (both paths null — expected for unresolvable terminals): 310 rows
- MISMATCH / CANONICAL_NULL: **0**
- Gate verdict: **READY_FOR_CUTOVER**

Production behavior is **unchanged**. The eligibility logic still reads from `PDI_Prod_ID` / `PDI_Trmnl_ID` (legacy columns). The canonical columns are observers only, until you say cut over.

---

## What Has Not Been Done Yet

| Item | Status | Notes |
|---|---|---|
| Gravitate-orders cutover | NOT STARTED | Parity passes; awaiting Jason GO |
| citysv-prices migration | NOT STARTED | Joins 3 CITT clone tables; same parallel approach needed |
| citysv-costs migration | NOT STARTED | `sp_Gravitate_PDI_Master_XREF_INGEST` dependency — needs investigation |
| Vendor/FuelCont domain | NOT STARTED | `vw_Xref_Contract_Axxis_To_PDI` has 0 rows; no seed yet |
| Deprecation of legacy tables | BLOCKED | Cannot touch until ALL consuming repos are migrated and Jason approves |

---

## Safety Guardrail

**No legacy table (`CitySV_*` XREF or `PDI_CITT_*` clone) may be frozen, deprecated, or dropped until:**
1. Every consuming repo (gravitate-orders, citysv-prices, citysv-costs, OPIS/DTN adjacent) has migrated its joins to the canonical views.
2. Jason provides explicit GO for deprecation.

This is documented in `CROSS_REPO_DEPENDENCY_AUDIT_CHECKLIST.domain_translation_canonical_mapping.v0.md`.

---

## Planning Artifacts (if you need to go deeper)

| Artifact | What it's for |
|---|---|
| `VALIDATION_REPORT` | Authoritative record of what was tested and approved |
| `CROSS_REPO_DEPENDENCY_AUDIT_CHECKLIST` | Repo-by-repo consumer map; governs deprecation sequencing |
| `RELEASE_AND_DEPRECATION_PLAN` | Phased retirement plan for legacy tables (post-migration) |
| `CURRENT_STATE_XREF_INVENTORY` | Inventory of all legacy translation surfaces and their consumer counts |
| `BUILD_REPORT` | Evidence log of what was deployed to SQL-02 and when |
| `OPERATIONS_RUNBOOK` | How to add/update/retire a mapping going forward |
| `Bootstrap v.0/` | SQL scripts used for initial deployment |

---

## Next Decision Point

> **You own this gate.** When you're ready to cut over gravitate-orders, say the word. The parity is clean, the canonical rows are live, and the view is already wired. Cutover is a targeted edit to the stage view — swap the authoritative columns from legacy join aliases to canonical ones, remove the legacy joins, deploy, done. Reversible if anything goes sideways.
