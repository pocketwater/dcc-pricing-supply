# CONTRACTS_STRESS_TEST_BRIEF

## Objective
Stress-test the canonical mapping model against the highest-complexity Contracts domain (supplier + terminal + product + contract context) to confirm the model safely resolves identity without ambiguity across channel transitions.

## Why Contracts Is The Hardest Domain
- Contract resolution is multi-dimensional and context-sensitive.
- Source identity can require up to four coordinated keys, not one code.
- Effective dates and contract lifecycle states can alter valid resolution outcomes.
- Migration phases may require concurrent channel mappings (for example FTP and API).

## Stress-Test Scope
In:
- Contract identity slot semantics for composite source keys.
- Hash determinism and uniqueness enforcement patterns.
- ACTIVE/UNRESOLVED/REVIEW_REQUIRED/RETIRED state behavior in edge cases.
- Validation outcomes for no match, multiple match, inactive match, and single active match.
- PDI target handling via Target_Key with live-derived `_ID` projection.

Out:
- Final DDL implementation.
- Production data mutation.
- Runtime cutover execution.

## Grain Contract
- Grain In: Approved PLAN_REPORT + scoping brief contract/domain assumptions.
- Grain Out: Design-ready stress-test acceptance criteria and edge-case matrix for Contracts domain.

## Translation Requirements
- Edge normalization and canonical resolve responsibilities remain separated.
- Contract source identity must map to explicit slot semantics:
  - Source_Key_1: Supplier anchor
  - Source_Key_2: Terminal anchor
  - Source_Key_3: Product anchor
  - Source_Key_4: Contract context/type anchor
- Composite_Hash must be generated identically across all consuming views/pipelines.
- PDI `_ID` must not be cached in registry; view-time derivation is mandatory.

## Ontological Assumptions
- Contract identity is definable from deterministic source context and can be represented by governed dimensions plus slot semantics.
- Channel differences represent projection differences, not identity redefinition.
- Confidence note: medium (7/10) until current-state inventory confirms all legacy contract variants.

## Test Matrix (Design-Time)
1. Single active mapping exists for one composite identity -> PASS expected.
2. No mapping exists for a composite identity -> BLOCK expected.
3. Two active mappings for same domain/source/target/channel/hash -> BLOCK expected.
4. Only inactive mapping exists -> BLOCK expected.
5. Same domain/source/target with different Target_Channel and distinct targets -> both valid where channel is explicit.
6. Effective date out of range for otherwise matching mapping -> BLOCK expected.
7. Slot-order variation with same values but reordered keys -> treated as different identities; requires documented slot discipline.
8. Null optional slots (2-4) in valid simple contract case -> deterministic hash and uniqueness still valid.

## Acceptance Criteria
- Slot semantics are explicitly documented and agreed for Contracts domain. (Met on 2026-05-05 for Slot-4)
- Validation outcomes are deterministic and non-interpretive for all matrix cases.
- Target channel coexistence logic is unambiguous.
- Live `_ID` derivation path for PDI targets is proven feasible in contract views.
- No unresolved ontology gaps remain for Design stage entry.

## Open Questions
- Do effective-date rules require view-level parameterization or static filtering contracts?
- Are there legacy aliases that should remain edge-normalization only and never enter canonical resolution?

## Resolved Decision (2026-05-05)
- Source_Key_4 anchor is `Contract_Type` for current upstream contract flows.
- Discovery evidence from SQL-02 (`PDI_PricingLink`) shows `Contract_Type` is present and non-null in both:
  - `dbo.CitySV_Gravitate_Orders_Ingest_Raw` (44,296 rows)
  - `dbo.CitySV_OrdersUpload_GravitateVendor_XREF` (184 rows)
- Observed controlled values: `Contract`, `Branded`, `Rack`.
- Implementation requirement: enforce these values in stewardship validation and treat unknown values as `REVIEW_REQUIRED`.

## Risks
- Drift in `Contract_Type` vocabulary could create false duplicates or false misses if uncontrolled values are introduced.
- Incomplete legacy inventory may hide channel-specific contract variations.
- Date-window behavior could drift if not centralized in view contracts.

## Deliverables Produced By This Brief
- Contracts-domain edge-case matrix for Design artifact inclusion.
- Canonical slot-semantics baseline for contract identity.
- Validation behavior expectations for validator-stage parity tests.

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: This is planning-governance design hardening, not a reusable execution routine.
