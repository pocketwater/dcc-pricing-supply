---
puppeteer:
  landscape: true
  format: "A4"
  margin:
    top: "1cm"
    bottom: "1cm"
    left: "1cm"
    right: "1cm"
---

# Domain Translations

This folder is the source-of-truth structure for translation governance artifacts in DCC.

## Structure

```text
domain-translations/
  Design Planning/
    <iteration-folder>/
      ...planning docs only...

  operational-artifacts/
    <version>/
      deployment/
      validation/
      evidence/
```

## Contract

- Planning documents live only under `Design Planning/<iteration-folder>/`.
- Executable/live artifacts (SQL packs, run scripts, evidence bundles) live only under `operational-artifacts/<version>/`.
- Every major product iteration gets exactly one planning folder (for example `v0-planning`, `v1-planning`).
- Every release execution version gets exactly one operational folder (for example `v0`, `v0.1`, `v1`).

## Current Iterations

- Planning: `Design Planning/v0-planning`
- Operational: `operational-artifacts/v0`, `operational-artifacts/v1`

## Naming Standards

- Planning folder: `<major>-planning` (example: `v1-planning`)
- Operational version folder: semantic version token (example: `v0`, `v0.1`, `v1`)
- Pack files: `<purpose>.<project>.v<version>.<ext>` when practical

## Operational Xref Inventory

This table covers every translation surface currently active or in active migration within the domain-translation system. It answers: what business relationship is covered, what keys drive the source match, and what the target resolution shape looks like.

Status key: **LEGACY** = pre-registry, still in active pipeline use | **REGISTRY** = seeded into `Xref_Registry`, consumed via contract view | **PARTIAL** = mixed — registry rows exist alongside legacy surface | **FROZEN** = renamed to `_Freeze`, replaced by shim or contract view

**Identity and mapping:**

| Surface | Domain | Source System | Source Key Shape | Target System | Target Resolution Shape |
|---|---|---|---|---|---|
| `CitySV_OrdersUpload_GravitateProduct_XREF` | Product | Gravitate | `Gravitate_Product_Name` (single) | PDI | `PDI_Prod_ID` (cached `_ID`) |
| `CitySV_OrdersUpload_GravitateTerminal_XREF` | Terminal | Gravitate | `Gravitate_Origin_Terminal` (single) | PDI | `PDI_Trmnl_ID` (cached `_ID`) |
| `CitySV_OrdersUpload_GravitateVendor_XREF_Stage` | Contract / Vendor | Gravitate | `Gravitate_Supplier` + `Contract_Type` + `Supply_Owner` (composite 3-key) | PDI | `PDI_Vend_ID` + `PDI_FuelCont_ID` (dual cached `_ID`) |
| `Gravitate_Destination_Resolver` | Destination | Gravitate | `Destination_ID` (single Gravitate dest code) | PDI | `Cust_ID` + `CustLoc_ID` + `Destination_Type` (customer or site per type) |
| `Gravitate_PDI_Master_XREF` | Contract | Gravitate / PDI | Multi-key composite (supplier + terminal + product + contract context) | PDI | PDI surrogate keys (mixed `_Key` + `_ID`) |
| `PDI_CITT_Axxis_Grav_PDI_Products_Clone` | Product | Axxis | Axxis product code (single) | PDI | `PDI_Prod_ID` (cached `_ID`) |
| `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone` | Terminal | Axxis | Axxis terminal code (single) | PDI | `PDI_Trmnl_ID` (cached `_ID`) |
| `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone` | Contract / Vendor | Axxis | Axxis vendor/FIVC code (single or partial composite) | PDI | `PDI_FuelCont_ID` partial (cached `_ID`) |
| `PDI_Carbon_Contract_XREF` | Contract (Carbon) | PDI | PDI contract key (single) | PDI | PDI target contract identifiers |
| `vw_PDI_Gravitate_FullName_Carrier_XREF` _(now `_Freeze`)_ | Vendor (Carrier) | Gravitate | `Long_Name` + `SCAC` (composite 2-key) | PDI | `Vend_ID` (via shim; registry rows now authoritative) |
| `dbo.Xref_Registry` (Vendor domain rows) | Vendor (Carrier) | Gravitate | `Source_Key_1 = Long_Name`, `Source_Key_2 = SCAC` | PDI | `Target_Key` (PDI `Vend_Key`); `Target_Code` = `Vend_ID` live-derived |

**Governance and status:**

| Surface | Pipeline(s) | Registry Status | Notes |
|---|---|---|---|
| `CitySV_OrdersUpload_GravitateProduct_XREF` | gravitate-orders | LEGACY | 92 rows; `_ID` cached, no `_Key` anchor; `vw_Xref_Product_Gravitate_To_PDI` planned as replacement |
| `CitySV_OrdersUpload_GravitateTerminal_XREF` | gravitate-orders | LEGACY | 49 rows; `_ID` cached; `vw_Xref_Terminal_Gravitate_To_PDI` planned as replacement |
| `CitySV_OrdersUpload_GravitateVendor_XREF_Stage` | gravitate-orders | LEGACY | 184 rows; `_Stage` suffix suspicious; emits both vendor and fuel contract IDs from one join — mixed responsibilities; high decomposition risk |
| `Gravitate_Destination_Resolver` | gravitate-orders | LEGACY | Active Stage view dependency; rebuild lineage unresolved; cannot freeze until Stage is refactored |
| `Gravitate_PDI_Master_XREF` | citysv-costs | LEGACY | 199 rows; bridge projection role; highest conflict risk — contradictions possible with XREF_Stage for same identity |
| `PDI_CITT_Axxis_Grav_PDI_Products_Clone` | citysv-costs, citysv-prices | LEGACY (CITT) | 58 rows; CITT cache — stale risk when PDI product strings change; no `_Key` anchor; deprecate after registry + live derivation validated |
| `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone` | citysv-costs, citysv-prices | LEGACY (CITT) | 90 rows; same stale-risk pattern as Products CITT; `vw_Xref_Terminal_Axxis_To_PDI` planned |
| `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone` | citysv-costs, citysv-prices | LEGACY (CITT) | 53 rows; partial `_Key` anchor present; `vw_Xref_Contract_Axxis_To_PDI` planned (STP composite grain required) |
| `PDI_Carbon_Contract_XREF` | Unknown | LEGACY_UNCLEAR | 8 rows; carbon-specific carve-out; classification deferred pending domain ownership confirmation |
| `vw_PDI_Gravitate_FullName_Carrier_XREF` _(now `_Freeze`)_ | gravitate-orders | FROZEN | Renamed to `_Freeze`; shim in place; v1 deployment seeded carrier rows into `Xref_Registry` as `ACTIVE`; `_Key` anchor present via `PDI_Vendors_Clone` join |
| `dbo.Xref_Registry` (Vendor domain rows) | gravitate-orders | REGISTRY | v1 deployment; first domain fully seeded; consumed via `vw_Gravitate_Orders_Ready`; `_ID` derived live from `PDI_Vendors_Clone` |

### Contract Views (Planned / In-Progress)

These are the sanctioned pipeline surfaces that will replace direct legacy table joins as registry seeding completes. None of these bypass `Xref_Registry`; they are filtered projections on top of it with live `_ID` derivation for PDI targets.

| View | Domain | Source → Target | Replaces | Status |
|---|---|---|---|---|
| `vw_Xref_Product_Gravitate_To_PDI` | Product | Gravitate → PDI | `CitySV_OrdersUpload_GravitateProduct_XREF` | Planned |
| `vw_Xref_Terminal_Gravitate_To_PDI` | Terminal | Gravitate → PDI | `CitySV_OrdersUpload_GravitateTerminal_XREF` | Planned |
| `vw_Xref_Contract_Axxis_To_PDI` | Contract | Axxis → PDI (STP composite) | `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone` | Planned |
| `vw_Xref_Product_Axxis_To_PDI` | Product | Axxis → PDI | `PDI_CITT_Axxis_Grav_PDI_Products_Clone` | Planned |
| `vw_Xref_Terminal_Axxis_To_PDI` | Terminal | Axxis → PDI | `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone` | Planned |
| `vw_Xref_Destination_Gravitate_To_PDI` | Destination | Gravitate → PDI | `Gravitate_Destination_Resolver` | Planned |

---

## Release Schedule Integration

The artifact lifecycle and versioning cadence are governed by:

- `workspace-ops/release-schedule/DOMAIN_TRANSLATION_VERSIONING_SCHEDULE.md`
- `workspace-ops/release-schedule/RELEASE_SCHEDULE_ARCHITECTURE.md`

## Decision Rule

If a file can be run, deployed, or executed, it belongs in `operational-artifacts`.
If a file explains design, decisions, plans, or governance, it belongs in `Design Planning`.
