# STEWARDSHIP_LIFECYCLE_SPEC

## Purpose
Define the full lifecycle model for mapping rows in Xref_Registry: how they are created, reviewed, activated, monitored, flagged for review, and retired. This spec governs human steward and agent behavior in the canonical registry.

## Grain Contract
- Grain In: Approved ADR, Seed & Remediation Workbook, governed dimension list.
- Grain Out: Actionable stewardship workflow model sufficient for UX Requirements and Build Specification input.

## Translation Requirements
- Lifecycle transitions must map 1:1 to Resolution_Status values and Is_Active states.
- No lifecycle action may change a row to ACTIVE without an explicit steward approval event recorded.

## Ontological Assumptions
- Stewards are humans or approved automation agents with domain-scoped access.
- Lifecycle events are auditable; all transitions are logged with who and when.
- Confidence note: high (8/10) for core lifecycle; medium for date-window edge cases.

---

## Lifecycle State Diagram

```
[New Row]
    |
    v
UNRESOLVED
    |-- Steward assigns Target + approves --> REVIEW_REQUIRED
    |-- Auto-seed with conflict -----------> REVIEW_REQUIRED (with conflict flag)
    |
REVIEW_REQUIRED
    |-- Jason / senior steward approves --> ACTIVE
    |-- Steward rejects / re-routes ------> UNRESOLVED (with notes)
    |
ACTIVE (Is_Active = 1)
    |-- Source system change or conflict -> REVIEW_REQUIRED
    |-- Explicit retire action -----------> RETIRED
    |
RETIRED (Is_Active = 0)
    |-- No reactivation without new row
```

---

## Transition Rules

| From | To | Who Can Trigger | Required Condition |
|---|---|---|---|
| (new) | UNRESOLVED | System / seed process | Row created via seed or steward entry |
| UNRESOLVED | REVIEW_REQUIRED | Steward | Target assigned, slot semantics confirmed |
| REVIEW_REQUIRED | ACTIVE | Senior steward or Jason | Explicit approval; uniqueness constraint confirmed |
| ACTIVE | REVIEW_REQUIRED | System or steward | Conflict detected, source system change, or manual flag |
| ACTIVE | RETIRED | Senior steward or Jason | Explicit retire action; replacement row active or not needed |
| REVIEW_REQUIRED | UNRESOLVED | Steward | Rejection; further investigation needed |

---

## Entry Creation Rules
- All new rows default: Resolution_Status = UNRESOLVED, Is_Active = 0.
- Created_By and Created_Dtm must always be populated.
- No row may enter ACTIVE state in the same operation as creation.
- Bulk seed operations must produce only UNRESOLVED rows.

---

## Approval Protocol
- REVIEW_REQUIRED rows are surfaced in the stewardship work queue.
- Steward reviews source/target/slot semantics and confirms the mapping is correct.
- If the row targets PDI, steward confirms Target_Key is valid against current PDI clone data.
- On approval: Resolution_Status = ACTIVE, Is_Active = 1, Updated_By and Updated_Dtm are set.
- On rejection: Resolution_Status = UNRESOLVED, notes updated with rejection reason.

---

## Monitoring and Drift Detection
- Scheduled process checks ACTIVE rows against current PDI clone data for stale `_Key` values.
- If `_Key` is no longer found in clone: flag row to REVIEW_REQUIRED with note "key not found in current clone".
- Source system changes (upstream value changes) trigger re-validation of all ACTIVE rows for affected domain/source pair.

---

## Retirement Protocol
- When a source system retires a value: set ACTIVE mapping to RETIRED, Is_Active = 0.
- Retired row is preserved for audit trail; no hard delete.
- If a replacement mapping exists, it must be ACTIVE before retirement proceeds.
- Retirement event recorded in Notes with date and reason.

---

## Soft Delete Policy
- Hard deletes are prohibited.
- All removals are expressed as RETIRED state transitions.
- RETIRED rows remain visible to stewardship query surfaces but are excluded from all pipeline contract views.

---

## Agent Interaction Rules
- Agents may read from ACTIVE rows via pipeline contract views only.
- Agents may not write to Xref_Registry directly.
- Agents may queue UNRESOLVED flag events for steward review when a pipeline encounters a no-match condition.
- Automated drift-detection processes may set REVIEW_REQUIRED but may not set ACTIVE.

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Lifecycle spec is a domain-governance design document, not a reusable execution skill pattern.
