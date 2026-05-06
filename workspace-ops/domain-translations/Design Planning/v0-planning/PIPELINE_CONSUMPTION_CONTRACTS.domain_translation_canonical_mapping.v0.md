# PIPELINE_CONSUMPTION_CONTRACTS

## Purpose
Define the read-only contract surfaces that pipelines and agents consume. Each contract declares the view name, guarantee, blocking behavior, and usage rules. Pipelines must never deviate from these contracts.

## Status
DRAFT — View bodies are patterns; exact clone join surfaces require Build-stage confirmation.

## Grain Contract
- Grain In: Domain Contract Specs, Physical Architecture Memo, ADR D4.
- Grain Out: Stable pipeline-facing contract definitions sufficient for pipeline authors and agents to build against without ever touching the raw registry.

## Translation Requirements
- All pipeline consumption via views only (ADR D4 is non-negotiable).
- No pipeline may join directly to `dbo.Xref_Registry`.

## Ontological Assumptions
- View names are stable contracts. Internal view body may change; name and output column set are versioned.
- Confidence note: high (9/10) for contract surface model; medium for exact clone join paths pending Build discovery.

---

## Contract Guarantee Model

Every pipeline contract view provides these guarantees:

| Guarantee | Detail |
|---|---|
| Domain-scoped | Returns rows for exactly one Domain/Source/Target/Channel combination |
| Active-only | Returns only Is_Active = 1, Resolution_Status = ACTIVE rows |
| Deterministic | Same registry state always returns same output for same input |
| Non-blocking by default | View returns all eligible active rows; pipeline validation is caller's responsibility |
| `_ID` live-derived | For PDI targets: `_ID` is always joined from clone surface, never from registry |
| No schema guessing | View column names are explicit; no * selects |

---

## Blocking Behavior (Caller Responsibility)

Blocking is not enforced by the view itself — it is enforced by the pipeline consumer. The pipeline must:
1. Join source row to the view on the appropriate key(s).
2. Count matching rows.
3. Apply validation: 0 rows → BLOCK; >1 rows → BLOCK; exactly 1 row → PASS.
4. Route BLOCK outcomes to the unresolved work queue.

No default fallback resolution. No guessing. Pipelines must handle BLOCK explicitly.

---

## Defined Contract Views

### Product Domain

#### `vw_Xref_Product_Gravitate_To_PDI`
| Field | Description |
|---|---|
| Source_Key_1 | Gravitate product code |
| Target_Key | PDI FuelProd_Key (surrogate) |
| PDI_FuelProd_ID | Live-derived from FuelProducts clone |
| Xref_ID | Registry row anchor |

Usage: Gravitate ingest pipeline; resolve Gravitate product code → PDI identity before staging.

#### `vw_Xref_Product_PDI_To_Gravitate_API`
| Field | Description |
|---|---|
| Source_Key_1 | PDI FuelProd_Key (or code depending on source side design) |
| Target_Code | Gravitate API product code |
| Xref_ID | Registry row anchor |

Usage: PDI→Gravitate API export pipeline.

#### `vw_Xref_Product_PDI_To_Gravitate_FTP`
| Field | Description |
|---|---|
| Source_Key_1 | PDI FuelProd_Key (or code) |
| Target_Code | Gravitate FTP product code |
| Xref_ID | Registry row anchor |

Usage: PDI→Gravitate FTP pipeline. DEPRECATED upon API channel cutover. Freeze date to be set in Release & Deprecation Plan.

#### `vw_Xref_Product_Axxis_To_PDI`
| Field | Description |
|---|---|
| Source_Key_1 | Axxis product code |
| Target_Key | PDI FuelProd_Key |
| PDI_FuelProd_ID | Live-derived |
| Xref_ID | Registry row anchor |

Usage: Axxis upload pipeline (citysv-prices / citysv-costs context).

---

### Terminal Domain

#### `vw_Xref_Terminal_Gravitate_To_PDI`
| Field | Description |
|---|---|
| Source_Key_1 | Gravitate terminal code |
| Target_Key | PDI terminal Key |
| PDI_Terminal_ID | Live-derived |
| Xref_ID | Registry row anchor |

Usage: Gravitate ingest; terminal resolution stage.

#### `vw_Xref_Terminal_Axxis_To_PDI`
| Field | Description |
|---|---|
| Source_Key_1 | Axxis terminal code |
| Target_Key | PDI terminal Key |
| PDI_Terminal_ID | Live-derived |
| Xref_ID | Registry row anchor |

Usage: Axxis upload pipeline.

---

### Contract Domain

#### `vw_Xref_Contract_Axxis_To_PDI`
| Field | Description |
|---|---|
| Source_Key_1 | Supplier anchor |
| Source_Key_2 | Terminal anchor |
| Source_Key_3 | Product anchor |
| Source_Key_4 | Contract context / type |
| Composite_Hash | Deterministic composite hash |
| Target_Key | PDI FuelCont_Key |
| PDI_FuelCont_ID | Live-derived |
| Xref_ID | Registry row anchor |

Usage: Axxis STP contract resolution pipeline.

---

### Destination Domain

#### `vw_Xref_Destination_Gravitate_To_PDI`
| Field | Description |
|---|---|
| Source_Key_1 | Gravitate destination code |
| Target_Key | PDI destination Key |
| PDI_Destination_ID | Live-derived |
| Xref_ID | Registry row anchor |

Usage: Gravitate destination resolution stage.

---

## View Versioning Policy
- View names are the contract. Name changes are breaking changes.
- View output column set changes are breaking changes.
- View internal body changes (for example clone join path update) are non-breaking if column set is preserved.
- Breaking changes require: pipeline author notification, parallel deployment with old view kept active until migration confirmed.

---

## Consuming_Views Registration
Each row in Xref_Registry may carry a `Consuming_Views` JSON field listing which repo and view names consume it. This is metadata only — it does not enforce consumption. Registering consuming views improves cross-repo discoverability.

Format:
```json
[
  {"repo": "gravitate-orders", "view": "vw_Xref_Product_Gravitate_To_PDI"},
  {"repo": "citysv-prices",    "view": "vw_Xref_Product_Axxis_To_PDI"}
]
```

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Pipeline contract documentation is planning-stage design output, not a reusable execution skill.
