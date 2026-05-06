# CANONICAL_MAPPING_ADR
## Architecture Decision Record: Domain Translation and Canonical Mapping Standard

## Status
DRAFT — Pending Design-stage validation

## Grain Contract
- Grain In: Approved PLAN_REPORT, scoping brief, Contracts stress-test brief.
- Grain Out: Durable, citable architecture decision record suitable for committing as baseline reference.

## Translation Requirements
- This ADR governs translation boundary rules. No implementation artifact may deviate from the separation-of-responsibility rules defined here.

## Ontological Assumptions
- Business entities are stable enough to support governed enumeration constants.
- Confidence note: high (9/10) for canonical authority and separation decisions; medium (7/10) for edge-case date-window behavior pending Design refinement.

---

## Context
COIL-Pricing-Supply operates multiple pipelines that cross system boundaries (PDI, Gravitate, Axxis, OPIS). Over time, translation and canonical identity surfaces accumulated organically, split across PDI_PricingLink and PDI-SQL-01, with no consistent ownership or refresh strategy.

Key failure modes discovered:
- CITT clone tables cache `_ID` translations with no refresh mechanism, creating state drift.
- Multiple semantic surfaces serve overlapping purposes with conflicting canonical authority.
- Agents and pipelines selecting the wrong mapping layer is a documented risk.
- Channel migration (FTP to API) cannot proceed safely without concurrent coexistence support.

---

## Decisions

### D1 — Single Canonical Registry
**Decision:** All cross-system business identity resolution occurs in one physical table (`dbo.Xref_Registry`) located in PDI_PricingLink.

**Rationale:** One authority eliminates semantic drift. Distributed canonical state is the root cause of the current failure mode.

**Consequence:** No other system, database, or table may redefine enterprise identity. Other systems project or consume identity; they do not define it.

---

### D2 — No `_ID` Caching
**Decision:** PDI `_ID` values are never stored in the registry. Registry stores `Target_Key` (PDI surrogate `_Key`). Pipeline contract views derive `_ID` live from PDI clone tables at query time.

**Rationale:** Caching `_ID` is the root cause of CITT table maintenance burden and state drift. Live derivation eliminates that maintenance class entirely.

**Consequence:** All pipeline views that resolve to PDI must join to PDI clone surfaces for `_ID` projection. This is the only sanctioned pattern. Views requiring `_ID` cannot rely on the registry column for it.

---

### D3 — Separation of Responsibilities
**Decision:** Translation and canonical identity are separated by explicit classification. No single object may serve both roles.

**Rationale:** Mixed-responsibility tables are the source of cognitive overhead and agent risk.

**Consequence:** Every existing xref/CITT object must be classified as one of:
- EDGE_NORMALIZATION (makes source data usable; domain-specific; may duplicate)
- CANONICAL_IDENTITY (defines what things are; centralized; stable keys)
- BRIDGE_PROJECTION (shapes already-resolved data for output)
- LEGACY_UNCLEAR (requires steward decision before migration)
- CITT_VARIANT (cached-ID pattern; scheduled for retirement)

---

### D4 — Views as Pipeline Contracts
**Decision:** Pipelines and agents never query `dbo.Xref_Registry` directly. All pipeline consumption occurs through named, domain-specific, channel-aware views.

**Rationale:** Direct registry access creates tight coupling and prevents safe refactoring. Views provide a stable contract surface.

**Consequence:** Every pipeline must be updated to reference the appropriate contract view. Agents that discover `dbo.Xref_Registry` directly must be treated as misconfigured. View naming standard is: `vw_Xref_<Domain>_<Source>_To_<Target>[_<Channel>]`.

---

### D5 — Composite Source Identity and Hash Anchoring
**Decision:** Source identity uses up to four key slots (`Source_Key_1` through `Source_Key_4`) with a deterministic SHA2_256 composite hash as the uniqueness anchor.

**Rationale:** Multi-dimensional domains (Contracts) require composite identity. A deterministic hash prevents ambiguous joins and enforces consistent input semantics across all consumers.

**Consequence:** Slot semantics must be documented per domain before any data can be loaded. Hash input format is fixed: `ISNULL(Key1,'') + '|' + ISNULL(Key2,'') + '|' + ISNULL(Key3,'') + '|' + ISNULL(Key4,'')`. Deviation from this format is prohibited.

---

### D6 — Governed Dimensions
**Decision:** Domain_Name, Source_System, Target_System, Target_Channel, Workgroup, and Resolution_Status are all governed enumeration constants enforced as lookup tables or application-layer validations. Free-text entry is not permitted.

**Rationale:** Free-text classification dimensions allow semantic drift and undermine agent discoverability. Governed constants guarantee unambiguous routing.

**Consequence:** New values for any governed dimension require explicit steward approval and registry update before use.

Baseline enumerated values:
- **Domain_Name:** Product, Terminal, Vendor, Contract, Destination, Customer, Location, Site
- **Source_System:** Gravitate, Axxis, OPIS, PDI, Manual
- **Target_System:** PDI, Gravitate, Axxis
- **Target_Channel:** FTP, API, Manual (NULL where channel is not applicable)
- **Workgroup:** COIL-Pricing-Supply
- **Resolution_Status:** UNRESOLVED, ACTIVE, REVIEW_REQUIRED, RETIRED

---

### D7 — Non-Interpretive Validation
**Decision:** Resolution validation produces exactly one of four outcomes: PASS (single active match) or BLOCK (no match, multiple matches, inactive match). No other outcome is defined.

**Rationale:** Interpretive validation (guessing, fuzzy matching, partial resolution) introduces silent data corruption. Non-interpretive blocking guarantees correctness at the cost of visibility into unresolved rows.

**Consequence:** Pipelines must handle BLOCK outcomes explicitly and surface them as unresolved work items. No default fallback resolution is permitted.

---

### D8 — CITT Deprecation
**Decision:** All CITT clone tables that cache `_ID` translations will be frozen (read-only) upon registry cutover and retired after two release cycles of validated parallel operation.

**Rationale:** CITT tables have no function once live `_ID` derivation from PDI clone tables is operational. Parallel operation provides safety margin; hard retirement enforces the new standard.

**Consequence:** CITT tables cannot receive new data after freeze date. All consumers must be migrated to contract views before retirement. Retirement date is set at design-stage cutover planning.

---

### D9 — Channel-Aware Coexistence
**Decision:** Target_Channel disambiguates mappings for the same domain/source/target where different output formats exist concurrently (for example Gravitate FTP and Gravitate API).

**Rationale:** FTP-to-API channel migration requires both mapping sets to coexist safely without collision during the transition window.

**Consequence:** Uniqueness enforcement is on the composite (Domain, Source_System, Target_System, Target_Channel, Composite_Hash) tuple where Is_Active = 1. Two active mappings for same source identity but different channels are valid and expected during migration.

---

### D10 — Stewardship Centralization
**Decision:** All stewardship workflow for the registry is conducted through one central command-app surface with domain-scoped views and filters. No direct table editing by non-technical stewards.

**Rationale:** Direct table editing introduces constraint bypass risk and audit gaps. Centralized stewardship ensures approval trails and prevents unauthorized resolution activation.

**Consequence:** Stewardship UX must exist before any production mapping goes ACTIVE. The command app must expose domain-specific filtered work queues before cutover.

---

## Alternatives Considered

| Option | Rejected Reason |
|---|---|
| Keep multiple domain-specific canonical tables | Semantic spread; agents and pipelines cannot determine authority |
| Allow free-text classification dimensions | Prevents reliable routing and discoverability |
| Cache `_ID` in registry for convenience | Root cause of CITT state drift; rejected unconditionally |
| Direct registry queries by pipelines | Tight coupling; safe refactoring not possible |
| Single-key source identity only | Insufficient for Contracts domain; composite is required |

---

## One-Sentence Rule
> All cross-system business identity is resolved in the PricingLink canonical mapping layer. No other system defines enterprise identity. Pipeline views derive `_ID` values live from PDI clone tables; no `_ID` is ever cached in the registry. CITT clone tables will be deprecated upon cutover.

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: ADR authoring is a planning-governance artifact; not a reusable execution skill pattern.
