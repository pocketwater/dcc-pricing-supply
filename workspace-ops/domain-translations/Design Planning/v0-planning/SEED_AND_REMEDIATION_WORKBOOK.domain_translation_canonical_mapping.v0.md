# SEED_AND_REMEDIATION_WORKBOOK

## Purpose
Define the process for classifying, seeding, and remediating legacy xref/CITT mappings into the canonical Xref_Registry, including conflict resolution rules and per-domain slot-semantic assignments.

## Status
STARTER_BASELINE — Requires current-state inventory completion and physical object discovery before full population.

## Grain Contract
- Grain In: Current-state xref inventory (classified objects), Contracts stress-test slot semantics, approved ADR.
- Grain Out: Registry-ready seed rows with explicit conflict dispositions and `_Key` anchor assignments.

## Translation Requirements
- Every legacy row classified as CANONICAL_IDENTITY or CITT_VARIANT must produce a seed row in Xref_Registry.
- EDGE_NORMALIZATION objects are not seeded into the registry (they remain pipeline-local).
- Seed rows default to Resolution_Status = UNRESOLVED and Is_Active = 0 until explicitly resolved and approved.
- `_ID` values from CITT source rows must be cross-referenced to PDI clone tables to derive the correct `_Key` anchor. The `_ID` itself is not stored.

## Ontological Assumptions
- Legacy rows with no identifiable domain or source system anchor require manual steward triage before seeding.
- Confidence note: medium (7/10) pending full physical inventory.

---

## Slot Semantic Assignments By Domain

### Product
| Slot | Semantic |
|---|---|
| Source_Key_1 | Product code or alias from source system |
| Source_Key_2 | NULL (not used for simple product) |
| Source_Key_3 | NULL |
| Source_Key_4 | NULL |

### Terminal
| Slot | Semantic |
|---|---|
| Source_Key_1 | Terminal code from source system |
| Source_Key_2 | NULL |
| Source_Key_3 | NULL |
| Source_Key_4 | NULL |

### Contract (STP context)
| Slot | Semantic |
|---|---|
| Source_Key_1 | Supplier anchor |
| Source_Key_2 | Terminal anchor |
| Source_Key_3 | Product anchor |
| Source_Key_4 | Contract context / type |

### Destination
| Slot | Semantic |
|---|---|
| Source_Key_1 | Destination code from source system |
| Source_Key_2 | NULL |
| Source_Key_3 | NULL |
| Source_Key_4 | NULL |

### Vendor
| Slot | Semantic |
|---|---|
| Source_Key_1 | Vendor code from source system |
| Source_Key_2 | NULL |
| Source_Key_3 | NULL |
| Source_Key_4 | NULL |

---

## Conflict Resolution Rules

| Conflict Type | Rule |
|---|---|
| Two legacy rows map same composite identity to different targets | Mark both as REVIEW_REQUIRED. Steward must choose canonical target. Do not auto-resolve. |
| Legacy `_ID` has no matching PDI clone row | Mark as UNRESOLVED. Do not populate Target_Key. Queue for steward. |
| Legacy row has no identifiable Source_System | Mark as LEGACY_UNCLEAR. Do not seed until domain and source are confirmed. |
| Duplicate composite identities in legacy that map to same target | Deduplicate. Keep one seed row with notes listing the duplicate source objects. |
| CITT row `_ID` cross-references to a retired PDI record | Mark as RETIRED. Include notes referencing source row. |

---

## Seed Phases

### Phase 1 — Classification Seed
- For each classified legacy row: assign Domain_Name, Source_System, Target_System, Target_Channel, slot values, and Resolution_Status = UNRESOLVED.
- Do not activate any row.
- Do not assign Target_Key until PDI clone cross-reference is confirmed.
- Deliverable: raw candidate table with all rows loaded and status = UNRESOLVED.

### Phase 2 — Key Resolution Pass
- For each seeded UNRESOLVED row targeting PDI: join to appropriate PDI clone surface to confirm `_Key`.
- Assign Target_Key where confirmed.
- Update Resolution_Status to REVIEW_REQUIRED for rows with confirmed `_Key` awaiting steward sign-off.
- Flag rows with no confirmed `_Key` with notes explaining the gap.
- Deliverable: REVIEW_REQUIRED rows ready for steward queue.

### Phase 3 — Steward Review and Activation
- Steward reviews REVIEW_REQUIRED rows via command-app stewardship surface.
- Steward approves canonical mapping and sets Resolution_Status = ACTIVE, Is_Active = 1.
- Rows with unresolvable conflicts remain REVIEW_REQUIRED with notes.
- Deliverable: ACTIVE rows ready for parallel validation against CITT outputs.

---

## Seed Workbook Template (Tabular)
| Seed_Row_ID | Source_Object | Domain_Name | Source_System | Target_System | Target_Channel | Source_Key_1 | Source_Key_2 | Source_Key_3 | Source_Key_4 | Target_Key_Confirmed | Resolution_Status | Conflict_Flag | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (auto) | PDI_CITT_Axxis_Grav_PDI_Products_Clone | Product | Gravitate | PDI | NULL | (enumerate) | NULL | NULL | NULL | (derive from clone) | UNRESOLVED | N | Starter row; requires key resolution |

---

## Exit Criteria
- All CANONICAL_IDENTITY and CITT_VARIANT objects from inventory have seed rows.
- Conflict list is exhausted (all conflicts have dispositions).
- REVIEW_REQUIRED rows are in stewardship queue.
- Zero LEGACY_UNCLEAR rows remain without steward triage note.

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Workbook process is program-specific remediation planning, not a reusable execution skill.
