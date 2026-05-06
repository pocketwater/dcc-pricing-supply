# CURRENT_STATE_XREF_INVENTORY

## Purpose
Provide the planning-stage baseline inventory of legacy translation/canonical surfaces (xref, CITT, bridge) to classify migration scope, identify conflicts, and support remediation sequencing.

## Inventory Status
- Status: DISCOVERY_CAPTURED
- Completeness: MEDIUM
- Last updated: 2026-05-05
- Next required action: finalize classification/disposition ownership for discovered SQL-02 objects and confirm in-scope subset for migration.

## Grain Contract
- Grain In: Scoping brief and known current-state narrative.
- Grain Out: Classified inventory table with migration disposition and confidence markers.

## Translation Requirements
- Every object must be classified as exactly one:
  - EDGE_NORMALIZATION
  - CANONICAL_IDENTITY
  - BRIDGE_PROJECTION
  - LEGACY_UNCLEAR
  - CITT_VARIANT
- CITT variants must include explicit dependency-safe disposition.
- Guardrail: no freeze/deprecate/retire action is allowed for shared translation surfaces until all consuming repo references are updated and validated (including OPIS/DTN and CitySV-dependent paths).
- For PDI-target mappings, note whether `_Key` anchor exists and whether `_ID` is cached.

## Ontological Assumptions
- Existing objects may contain mixed responsibilities and require decomposition by behavior rather than table name.
- Source/target/channel intent can be inferred for most objects from current pipeline usage and naming.
- Confidence note: medium-low (6/10) pending full SQL object extraction.

## Classification Table (Discovered)
| Object Name | Location | Object Type | Domain Guess | Current Role | Classification | `_Key` Anchor Present | `_ID` Cached | Target Channel Aware | Migration Disposition | Conflict Risk | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| CitySV_OrdersUpload_GravitateProduct_XREF | PDI-SQL-02 / PDI_PricingLink | Table | Product | Legacy product translation surface | EDGE_NORMALIZATION | No | Yes (`PDI_Prod_ID`) | No | Keep writable/active until cross-repo consumer migration is validated; then move to controlled read-only phase by approval | Medium | 92 rows observed |
| CitySV_OrdersUpload_GravitateTerminal_XREF | PDI-SQL-02 / PDI_PricingLink | Table | Terminal | Legacy terminal translation surface | EDGE_NORMALIZATION | No | Yes (`PDI_Trmnl_ID`) | No | Migrate semantics to Terminal domain registry/view | Medium | 49 rows observed |
| CitySV_OrdersUpload_GravitateVendor_XREF | PDI-SQL-02 / PDI_PricingLink | Table | Contract/Vendor | Legacy contract/vendor translation | LEGACY_UNCLEAR | Partial (`PDI_FuelCont_ID`) | Yes | Partial (`Contract_Type`) | Decompose into Contract (canonical) + Vendor edge normalization | High | 184 rows; includes `Contract_Type` with 3 distinct values |
| Gravitate_PDI_Master_XREF | PDI-SQL-02 / PDI_PricingLink | Table | Contract | Legacy multi-key mapping bridge | BRIDGE_PROJECTION | Yes (PDI keys) | Mixed | Unknown | Replace with governed contract view contracts; retain only as temporary parity source | High | 199 rows observed |
| PDI_Carbon_Contract_XREF | PDI-SQL-02 / PDI_PricingLink | Table | Contract | Source-target contract xref surface | LEGACY_UNCLEAR | Yes | Unknown | Unknown | Classify in carve-out scope; likely separate carbon domain handling | Medium | 8 rows observed |
| PDI_CITT_Axxis_Grav_PDI_Products_Clone | PDI-SQL-02 / PDI_PricingLink | Table | Product | CITT variant cache | CITT_VARIANT | Unknown | Yes (`PDI_Prod_ID`) | Unknown | Keep active for parity and downstream compatibility; do not freeze/retire until all consumer repos are migrated and signed off | High | 58 rows observed |
| PDI_CITT_Axxis_Grav_PDI_Terminals_Clone | PDI-SQL-02 / PDI_PricingLink | Table | Terminal | CITT variant cache | CITT_VARIANT | Unknown | Yes (`PDI_Trmnl_ID`) | Unknown | Keep active for parity and downstream compatibility; do not freeze/retire until all consumer repos are migrated and signed off | High | 90 rows observed |
| PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone | PDI-SQL-02 / PDI_PricingLink | Table | Contract/Vendor | CITT variant cache | CITT_VARIANT | Partial (`PDI_FuelCont_ID`) | Yes | Unknown | Keep active for parity and downstream compatibility; do not freeze/retire until all consumer repos are migrated and signed off | High | 53 rows observed |

## Discovery Evidence (Executed)
- SQL-02 scope executed against `PDI_PricingLink` with trusted certificate.
- SQL-01 `PDI_PricingLink` is not present/accessible for this login; discovery executed across online SQL-01 databases instead.
- SQL-01 discovery found only generic `Import_Mapping`/archive xref objects in `PDICompany_*` databases and no direct `PDI_CITT_*` surfaces.

## Discovery Backlog
1. Map each discovered object to consuming pipelines, views, or jobs.
2. Identify duplicate semantic surfaces by domain/source/target/channel.
3. Flag contradictions where active mappings disagree for same logical identity.
4. Confirm whether any additional CITT surfaces exist outside current SQL-02 scope.

## Reconciliation Rules (Planning)
- If two active mappings resolve the same composite identity differently for same domain/source/target/channel, mark as CONFLICT_BLOCKER.
- If an object caches `_ID` for PDI target without live derivation, mark as DRIFT_RISK.
- If object role is unclear after discovery pass, mark as LEGACY_UNCLEAR and require steward decision.

## Exit Criteria For Inventory Artifact
- 100 percent of discovered translation/canonical objects are classified.
- Conflict list is explicit and owner-assigned.
- CITT_VARIANT set is complete and tied to dependency-safe migration sequence.
- Inputs are sufficient for Seed & Remediation Workbook.

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Inventory planning output is domain-program specific and not a reusable skill-pattern request.
