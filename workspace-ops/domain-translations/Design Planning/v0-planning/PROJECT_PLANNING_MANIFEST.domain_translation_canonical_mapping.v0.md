# PROJECT_PLANNING_MANIFEST

## Project
Domain Translation and Canonical Mapping Standardization (CITT Deprecation Program)

## Purpose
Provide the consolidated planning baseline to move from fragmented xref/CITT patterns to one canonical, agent-safe mapping authority with live-derived PDI `_ID` projection and controlled CITT retirement.

## Bootstrap Approach Summary
Lowest-cost valid path:
1. Lock planning decisions and governance dimensions first.
2. Stress-test hardest domain (Contracts/STP context) before physical design hardening.
3. Prepare side-by-side validation design to prove parity against current CITT outputs.
4. Enter Design stage only after planning artifact set is complete and approved.

## Scope (in/out)
In:
- Planning artifact production and decision checkpoints.
- Canonical authority and resolve-surface rules.
- Migration/deprecation sequencing and validation planning.

Out:
- SQL deployment, pipeline changes, and production release actions.
- Runtime behavior modifications.

## Canonical Design Decisions
- Canonical identity authority: PDI_PricingLink.
- Registry model: one centralized Xref_Registry with governed dimensions and deterministic composite identity hashing.
- Consumption model: pipelines/agents read domain/channel-specific views only.
- PDI convention: store `Target_Key` in registry; derive `_ID` live in views.
- CITT policy: freeze then retire after validated parallel window (2 release cycles).

## Lifecycle and State Model
Planned lifecycle:
1. Seed: classify and ingest legacy mappings as candidates.
2. Resolve: reconcile conflicts and anchor to canonical `_Key` truth.
3. Activate: enable unique active mappings by domain/source/target/channel/hash.
4. Validate: side-by-side parity checks vs CITT outputs.
5. Cutover: freeze CITT writes, redirect consumers to contract views.
6. Deprecate: retire/drop CITT tables after stability window.

Planned mapping states:
- UNRESOLVED
- ACTIVE
- REVIEW_REQUIRED
- RETIRED

## Control Model
- Classification dimensions are governed constants, not free text.
- Validation behavior is non-interpretive:
  - no match -> BLOCK
  - multiple matches -> BLOCK
  - inactive match -> BLOCK
  - single active match -> PASS
- Agent safety guardrail: one sanctioned resolve surface per pipeline context.
- Stewardship governance: central command surface with scoped filters and audit trail.

## Dependencies and Risks
Dependencies:
- Current-state xref/CITT inventory completion.
- Contracts-domain stress-test brief.
- Governed dimension finalization and stewardship UX requirements.

Top risks:
- Legacy conflict density may be higher than expected.
- Missing slot-semantic documentation may create inconsistent hash inputs.
- Under-specified consuming view metadata may reduce discoverability.

## Versioning and Release Schedule Inputs
- Planning baseline version: v0.
- Parallel run requirement: minimum 2 release cycles before CITT retirement.
- Cutover gate inputs:
  - parity validation pass
  - ambiguity/duplicate checks pass
  - rollback path documented
  - ownership + monitoring assigned

## Required Planning Artifacts
1. Problem & Scope Brief (source baseline): **AVAILABLE** — `domain_translation_scoping_brief.md`
2. Contracts Stress-Test Brief: **DRAFT AVAILABLE** — `CONTRACTS_STRESS_TEST_BRIEF.domain_translation_canonical_mapping.v0.md`
3. Canonical Mapping ADR: **DRAFT AVAILABLE** — `CANONICAL_MAPPING_ADR.domain_translation_canonical_mapping.v0.md`
4. Current-State Xref Inventory: **STARTER BASELINE** — `CURRENT_STATE_XREF_INVENTORY.domain_translation_canonical_mapping.v0.md` (requires physical object discovery to complete)
5. Seed & Remediation Workbook: **DRAFT AVAILABLE** — `SEED_AND_REMEDIATION_WORKBOOK.domain_translation_canonical_mapping.v0.md`
6. Stewardship Lifecycle Spec: **DRAFT AVAILABLE** — `STEWARDSHIP_LIFECYCLE_SPEC.domain_translation_canonical_mapping.v0.md`
7. Stewardship UX Requirements: **DRAFT AVAILABLE** — `STEWARDSHIP_UX_REQUIREMENTS.domain_translation_canonical_mapping.v0.md`
8. Physical Architecture Memo: **DRAFT AVAILABLE** — `PHYSICAL_ARCHITECTURE_MEMO.domain_translation_canonical_mapping.v0.md`
9. Domain Contract Specs: **DRAFT AVAILABLE** — `DOMAIN_CONTRACT_SPECS.domain_translation_canonical_mapping.v0.md` (Customer/Vendor/Location/Site sections pending inventory)
10. Pipeline Consumption Contracts: **DRAFT AVAILABLE** — `PIPELINE_CONSUMPTION_CONTRACTS.domain_translation_canonical_mapping.v0.md`
11. Build Specification: **DRAFT AVAILABLE** — `BUILD_SPECIFICATION.domain_translation_canonical_mapping.v0.md`
12. Validation & Reconciliation Plan: **DRAFT AVAILABLE** — `VALIDATION_AND_RECONCILIATION_PLAN.domain_translation_canonical_mapping.v0.md`
13. Operations Runbook: **DRAFT AVAILABLE** — `OPERATIONS_RUNBOOK.domain_translation_canonical_mapping.v0.md`
14. Release & Deprecation Plan: **DRAFT AVAILABLE** — `RELEASE_AND_DEPRECATION_PLAN.domain_translation_canonical_mapping.v0.md`

## Next Action
Run Validator gate closure using `VALIDATION_REPORT.domain_translation_canonical_mapping.v0.md`, attach query execution evidence, and resolve parity blockers before Release-stage authorization.

## Stage Status
- Planning status: COMPLETE
- Design status: COMPLETE
- Build status: COMPLETE
- Validation status: COMPLETE (PASS_WITH_ACCEPTED_EXCEPTIONS)
- Production release status: READY_FOR_RELEASE_REVIEW
- Decision owner: business_manager (release authorization)
- Date updated: 2026-05-05

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Planning-governance orchestration does not represent a new reusable execution skill pattern.
