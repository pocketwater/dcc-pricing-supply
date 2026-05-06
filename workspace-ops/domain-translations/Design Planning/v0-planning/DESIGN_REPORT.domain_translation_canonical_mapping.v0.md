# DESIGN_REPORT

## Objective
Translate the approved planning package into implementation-ready architecture: object definitions, interface contracts, failure modes, validation strategy, and design decisions necessary for the Build stage without requiring additional clarification.

## Prior Approved Artifact
PLAN_REPORT approved by business_manager on 2026-05-05. All design work is scoped within the approved plan boundaries.

## Grain Contract
- Grain In: Approved PLAN_REPORT, planning artifacts 1–14 (Physical Architecture Memo, Domain Contract Specs, Pipeline Consumption Contracts, Build Specification, Validation Plan).
- Grain Out: Architecture-ready specification sufficient for Builder stage entry without schema guessing.

## Translation Requirements
- Design enforces ADR separation rules exactly. All object definitions must map 1:1 to ADR decisions D1–D10.
- Edge normalization, canonical identity, and projection responsibilities remain strictly separated in all designs.

## Ontological Assumptions
- Design is working at the data model, view contract, and interface level — not at code/SQL detail level.
- Builder will handle exact SQL syntax and clone join path confirmation.
- Design assumes PDI_PricingLink is the deployment target and PDI clone surfaces are accessible for live-join pipelines.
- Confidence note: high (9/10) for registry model and separation strategy; medium (7/10) for edge cases pending Contracts slot-4 closure and inventory completion.

---

## Design Decisions

### D-1: Registry Table Schema — Finalized
**Canonical table:** `dbo.Xref_Registry` in PDI_PricingLink.

**Core columns:**
- Governance: Domain_Name, Source_System, Target_System, Target_Channel, Workgroup, Owning_Pipeline (all governed enums).
- Source identity: Source_Key_1–4, Composite_Hash (SHA2_256 persisted).
- Target resolution: Target_Key (PDI surrogates), Target_Code (non-PDI strings).
- Lifecycle: Resolution_Status, Is_Active, Effective_From/To, Consuming_Views (JSON).
- Audit: Created_By, Created_Dtm, Updated_By, Updated_Dtm, Notes.

**Uniqueness constraint:** One active mapping per (Domain, Source_System, Target_System, Target_Channel, Composite_Hash) tuple where Is_Active = 1.

**Check constraint:** Is_Active = 1 ↔ Resolution_Status = 'ACTIVE' (bidirectional enforcement).

**Input normalization trigger:** Source_Key_1–4 must be pre-trimmed (LTRIM/RTRIM) before insert to prevent invisible whitespace collisions in hash.

---

### D-2: Governed Dimension Tables — Finalized
Six lookup tables (one per governed dimension):
- `dbo.Xref_DomainNames` (Product, Terminal, Contract, Destination, Customer, Vendor, Location, Site)
- `dbo.Xref_SourceSystems` (Gravitate, Axxis, OPIS, PDI, Manual)
- `dbo.Xref_TargetSystems` (PDI, Gravitate, Axxis)
- `dbo.Xref_TargetChannels` (FTP, API, Manual; NULL handling in app layer)
- `dbo.Xref_Workgroups` (COIL-Pricing-Supply)
- `dbo.Xref_ResolutionStatuses` (UNRESOLVED, ACTIVE, REVIEW_REQUIRED, RETIRED)

**Foreign key enforcement:** Registry table references all six dimensions via explicit FK constraints. Violation is a data quality defect.

---

### D-3: Pipeline Contract Views — Finalized Pattern
**Design principle:** One view per domain/source/target/channel combination. Views are stable contracts; internal refactoring does not change column names or order.

**PDI-target view template:**
```
vw_Xref_<Domain>_<Source>_To_PDI

Columns:
  - Source_Key_1 (labeled by domain slot semantic)
  - Target_Key (PDI surrogate from registry)
  - PDI_<Entity>_ID (live-derived from clone via inner join)
  - Xref_ID (registry row anchor)

Filter: Where Is_Active = 1 AND Resolution_Status = 'ACTIVE'
Join: Inner join to PDI clone surface for live _ID derivation (never cached)
```

**Non-PDI target view template:**
```
vw_Xref_<Domain>_<Source>_To_<Target>_<Channel>

Columns:
  - Source_Key_1 (or composite if domain requires it)
  - Target_Code (string code from registry)
  - Xref_ID

Filter: Where Is_Active = 1 AND Resolution_Status = 'ACTIVE'
```

**All views:**
- Never expose UNRESOLVED or RETIRED rows.
- Never use SELECT * (explicit column list).
- Never use GROUP BY, aggregate functions, or subqueries (keep views simple for agent safety).
- Column order is frozen; changes are breaking changes.

---

### D-4: Stewardship Lifecycle — Finalized State Machine
**States:** UNRESOLVED → REVIEW_REQUIRED → ACTIVE → RETIRED (no reactivation).

**Transition rules:**
| From | To | Who | Condition |
|---|---|---|---|
| new | UNRESOLVED | system | default |
| UNRESOLVED | REVIEW_REQUIRED | steward | Target assigned, slot semantics confirmed |
| REVIEW_REQUIRED | ACTIVE | senior steward | explicit approval |
| REVIEW_REQUIRED | UNRESOLVED | steward | rejection |
| ACTIVE | REVIEW_REQUIRED | system/steward | conflict detected, source change, or manual flag |
| ACTIVE | RETIRED | senior steward | explicit retire action |

**Non-negotiable rule:** No row may enter ACTIVE state in the same operation as creation. Bulk seed operations produce only UNRESOLVED rows.

---

### D-5: Index Strategy — Finalized
**Primary key:** Clustered on Xref_ID (identity anchor).

**Uniqueness index:** Filtered unique on (Domain_Name, Source_System, Target_System, Target_Channel, Composite_Hash) WHERE Is_Active = 1.

**Supporting indexes:**
- (Domain_Name, Owning_Pipeline, Is_Active) for stewardship context.
- (Resolution_Status, Is_Active, Domain_Name) for work queue queries.

**Candidate for Build evaluation:** (Source_System, Target_System, Is_Active) if cross-domain cross-system queries become common post-deployment.

---

### D-6: Seeding and Key Resolution — Design Pattern
**Phase 1 — Classification seed:** Legacy CITT/xref rows classified (CANONICAL_IDENTITY, EDGE_NORMALIZATION, etc.) and loaded as UNRESOLVED candidates.

**Phase 2 — Key resolution pass:** For each UNRESOLVED row targeting PDI, perform left join to appropriate PDI clone surface. If Key found: update Target_Key and move to REVIEW_REQUIRED. If not found: leave Target_Key NULL and add note explaining gap.

**Phase 3 — Steward activation:** Steward reviews REVIEW_REQUIRED rows, confirms Target_Key and slot semantics, and approves (sets ACTIVE, Is_Active = 1).

**Outcome:** All active rows have verified Target_Key values; no CITT-era stale data propagates.

---

### D-7: Validation Architecture — Finalized
**Blocking model:** Pipeline must perform 1:1 lookup and count matching rows. Outcomes:
- 0 matches → BLOCK (source unresolved; queue for steward).
- 1 match → PASS (safe to proceed).
- >1 matches → BLOCK (uniqueness violation; escalate).
- Inactive match → excluded by view (treated as 0 matches → BLOCK).

**No default fallback.** No guessing. No silent partial resolution.

**Parity validation:** Side-by-side comparison of new views vs frozen CITT outputs for all in-scope domains. Zero unexplained mismatches required before cutover.

**Constraint validation:** Unique index prevents duplicate active rows; FK constraints prevent invalid dimension references.

---

### D-8: Drift Detection — Finalized
**Scheduled process:** Daily check of all ACTIVE rows against current PDI clone data. If `_Key` is no longer found in clone: automatically set row to REVIEW_REQUIRED with note "key not found in current clone [date/time]".

**Steward response:** Investigate cause (re-key, rename, retire in PDI). Update Target_Key if re-keyed; retire row if removed; mark false positive with notes if clone was temporarily stale.

---

### D-9: Consuming_Views JSON Format — Finalized
**Format:**
```json
[
  {"repo": "gravitate-orders", "view": "vw_Xref_Product_Gravitate_To_PDI"},
  {"repo": "citysv-prices", "view": "vw_Xref_Product_Axxis_To_PDI"}
]
```

**Registration:** Stewards/engineers manually populate this field during seed or when a new consumer pipeline is onboarded.

**Parsing:** Application layer (stewardship UI, audit tools) parses JSON and renders as readable list. NULL is valid (no registered consumers yet).

---

### D-10: Soft Delete Policy — Finalized
**Hard deletes:** Prohibited. No DROP, TRUNCATE, or physical delete operations on active registry rows.

**Retirement pattern:** Set Is_Active = 0, Resolution_Status = RETIRED, record retirement date and reason in Notes.

**Audit trail:** RETIRED rows remain queryable for audit; excluded from all pipeline contract views via Is_Active = 1 filter.

---

## Objects To Build (In Order)

### Objects List
1. Governed dimension tables (6 tables, seed data included).
2. `dbo.Xref_Registry` with all constraints, FKs, and computed columns.
3. Input normalization trigger.
4. Indexes (1 unique, 2 supporting).
5. Pipeline contract views (one per domain/source/target/channel; ~10–15 views minimum, expandable).
6. Stewardship view (`vw_Xref_Stewardship_All`).

---

## Failure Modes and Responses

| Failure Mode | Detection | Response |
|---|---|---|
| Duplicate active mappings | Unique index violation | Build error; data must be corrected before deploy |
| Invalid dimension reference | FK constraint violation | Build error; governed value must exist before use |
| Pipeline BLOCK rate spike post-cutover | Monitoring alert | Investigate: unresolved mappings OR clone join path broken? |
| Drift detected (key not in clone) | Daily drift job | Steward investigates and updates/retires mapping |
| CITT parity mismatch | Validation phase | Do not proceed to cutover; treat as defect and fix |
| Null `_ID` from PDI view join | Pipeline error log | Clone join path broken; escalate to engineering |

---

## Validation Strategy

**Build-stage validation queries included in Build Specification.**

**Pre-deploy checklist:**
- Governed dimension tables populated with seed data.
- Registry table built; all constraints active.
- Unique index deployed and tested (verify uniqueness enforced).
- FK constraints confirmed deployed.
- Input trigger confirmed deployed and tested (trim enforcement).
- All pipeline views deployed and query-tested.
- Clone join paths confirmed for all PDI-target views.
- Stewardship view deployed.

**Sandbox company validation (required for PDI endpoint per runbook):** Collect evidence before release GO.

---

## Design-to-Build Handoff Checklist
- [ ] All governed dimensions finalized (no pending additions).
- [ ] Contracts Source_Key_4 semantic resolved (completes Contract domain design).
- [ ] Current-state xref inventory completed (seed workbook populated).
- [ ] Physical Architecture Memo reviewed and accepted.
- [ ] Pipeline Consumption Contracts reviewed and accepted.
- [ ] Build Specification reviewed and accepted.
- [ ] Stewardship UX requirements accepted by stakeholders.

---

## Approval: [Planner + Manager]
- Planner approval: PENDING
- Business Manager approval: PENDING
- Date: 2026-05-05

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Design report production is a stage-gate governance artifact; not a reusable execution skill pattern.
