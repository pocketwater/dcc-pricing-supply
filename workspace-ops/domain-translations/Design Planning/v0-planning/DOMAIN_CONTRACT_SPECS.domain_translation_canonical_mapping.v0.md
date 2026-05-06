# DOMAIN_CONTRACT_SPECS

## Purpose
Define per-domain specifications for uniqueness rules, resolution outcomes, steward page behavior, and pipeline view schema. One section per domain in scope.

## Status
STARTER_BASELINE — Sections for Product, Terminal, Contract, and Destination are drafted. Additional domains (Customer, Vendor, Location, Site) require inventory evidence before full specification.

## Grain Contract
- Grain In: ADR governed dimension list, Contracts stress-test brief, physical architecture memo.
- Grain Out: Domain-by-domain contract specifications sufficient for pipeline view design and stewardship UX slot configuration.

## Translation Requirements
- Edge normalization and canonical identity remain separated per ADR D3. Each domain section must declare which responsibility its pipeline view serves.

## Ontological Assumptions
- Domain scopes are stable and enumerable within current pipeline landscape.
- Confidence note: high (8/10) for Product and Terminal; medium (6/10) for Contract pending stress-test resolution; low-medium for undiscovered domains.

---

## Domain: Product

### Resolution Purpose
Canonical: maps source-system product codes to PDI FuelProd_Key (Target_Key) for identity resolution.

### Source Slot Semantics
| Slot | Semantic |
|---|---|
| Source_Key_1 | Product code from source system |
| Source_Key_2–4 | NULL |

### Uniqueness Rule
One active mapping per (Domain=Product, Source_System, Target_System, Target_Channel, Source_Key_1 hash).

### Resolution Outcome
Single active match → PASS; expose PDI FuelProd_Key + live-derived FuelProd_ID via view join.

### Pipeline View Set
| View Name | Source → Target | Channel | Description |
|---|---|---|---|
| `vw_Xref_Product_Gravitate_To_PDI` | Gravitate → PDI | NULL | Gravitate product code → PDI FuelProd_Key (+ live _ID) |
| `vw_Xref_Product_PDI_To_Gravitate_API` | PDI → Gravitate | API | PDI product → Gravitate API product code |
| `vw_Xref_Product_PDI_To_Gravitate_FTP` | PDI → Gravitate | FTP | PDI product → Gravitate FTP product code (deprecated at API cutover) |
| `vw_Xref_Product_Axxis_To_PDI` | Axxis → PDI | NULL | Axxis product code → PDI FuelProd_Key |

### Steward Page Behavior
- Slot 1 label: "Product Code (Source)"
- PDI target: Key lookup against FuelProducts clone.
- No composite identity needed for simple product mappings.

---

## Domain: Terminal

### Resolution Purpose
Canonical: maps source-system terminal codes to PDI terminal surrogate key.

### Source Slot Semantics
| Slot | Semantic |
|---|---|
| Source_Key_1 | Terminal code from source system |
| Source_Key_2–4 | NULL |

### Uniqueness Rule
One active mapping per (Domain=Terminal, Source_System, Target_System, Target_Channel, Source_Key_1 hash).

### Resolution Outcome
Single active match → PASS; expose PDI terminal Key + live-derived terminal _ID via view join.

### Pipeline View Set
| View Name | Source → Target | Channel | Description |
|---|---|---|---|
| `vw_Xref_Terminal_Gravitate_To_PDI` | Gravitate → PDI | NULL | Gravitate terminal code → PDI terminal Key |
| `vw_Xref_Terminal_Axxis_To_PDI` | Axxis → PDI | NULL | Axxis terminal → PDI terminal Key |

### Steward Page Behavior
- Slot 1 label: "Terminal Code (Source)"
- PDI target: Key lookup against terminal clone.

---

## Domain: Contract (STP Context)

### Resolution Purpose
Canonical: maps multi-key contract identity (supplier + terminal + product + contract type) to PDI FuelCont_Key for identity resolution.

### Source Slot Semantics
| Slot | Semantic |
|---|---|
| Source_Key_1 | Supplier anchor (supplier code or identifier) |
| Source_Key_2 | Terminal anchor |
| Source_Key_3 | Product anchor |
| Source_Key_4 | Contract type anchor (`Contract`, `Branded`, `Rack`) |

### Uniqueness Rule
One active mapping per (Domain=Contract, Source_System, Target_System, Target_Channel, composite hash of all four slots).

### Resolution Outcome
Single active match → PASS; expose PDI FuelCont_Key + live-derived FuelCont_ID via view join.
Multi-dimensional identity means any partial slot match that returns multiple rows → BLOCK.

### Open Issues (Design Dependency)
- Date-window behavior: determine if effective dates require view-level parameterization or static current-date filtering.

### Resolved Slot-4 Decision (2026-05-05)
- Source_Key_4 is standardized to `Contract_Type` for current Axxis/Gravitate STP contract flows.
- Evidence from SQL-02 (`PDI_PricingLink`): `Contract_Type` is fully populated in both raw and legacy xref surfaces and has three stable values: `Contract`, `Branded`, `Rack`.
- Stewardship UX label remains `Contract Type` and must enforce controlled value validation.

### Pipeline View Set
| View Name | Source → Target | Channel | Description |
|---|---|---|---|
| `vw_Xref_Contract_Axxis_To_PDI` | Axxis → PDI | NULL | STP-context contract → PDI FuelCont_Key |

### Steward Page Behavior
- Slot labels: Supplier / Terminal / Product / Contract Type
- All four slots visible for contract domain rows.
- PDI target: Key lookup against FuelContracts clone.

---

## Domain: Destination

### Resolution Purpose
Canonical: maps source-system destination codes to PDI destination Key.

### Source Slot Semantics
| Slot | Semantic |
|---|---|
| Source_Key_1 | Destination code from source system |
| Source_Key_2–4 | NULL |

### Uniqueness Rule
One active mapping per (Domain=Destination, Source_System, Target_System, Target_Channel, Source_Key_1 hash).

### Resolution Outcome
Single active match → PASS.

### Pipeline View Set
| View Name | Source → Target | Channel | Description |
|---|---|---|---|
| `vw_Xref_Destination_Gravitate_To_PDI` | Gravitate → PDI | NULL | Gravitate destination → PDI destination Key |

### Steward Page Behavior
- Slot 1 label: "Destination Code (Source)"

---

## Domains: Customer, Vendor, Location, Site

### Status
PENDING — Requires current-state inventory evidence before domain contract specs can be drafted. Placeholder sections reserved.

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Domain contract specification is planning-stage design output, not a reusable execution skill.
