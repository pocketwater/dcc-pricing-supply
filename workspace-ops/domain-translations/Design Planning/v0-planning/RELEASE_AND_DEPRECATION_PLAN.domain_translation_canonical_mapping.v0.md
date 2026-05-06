# RELEASE_AND_DEPRECATION_PLAN

## Purpose
Define the rollout order, cutover checkpoints, CITT legacy freeze/retirement sequencing, rollback path, monitoring plan, and ownership for the canonical mapping system release.

## Grain Contract
- Grain In: Validation & Reconciliation Plan, Build Specification, Operations Runbook, Pipeline Consumption Contracts.
- Grain Out: Release-stage planning artifact sufficient for Ops stage and final GO/NO-GO decision.

## Translation Requirements
- Release planning must enforce dependency-safe sequencing: no freeze/deprecate/retire on shared translation surfaces until all consuming repo references are updated and validated.
- CitySV-named translation surfaces are protected during migration and remain operational until explicit cross-repo sign-off (including OPIS/DTN consumers).
- Cross-repo dependency evidence source: `CROSS_REPO_DEPENDENCY_AUDIT_CHECKLIST.domain_translation_canonical_mapping.v0.md`.

## Ontological Assumptions
- Release is phased; no big-bang cutover.
- CITT tables remain readable and available during the parallel window.
- Confidence note: high (8/10) for phase structure; medium for specific release dates (set at Build completion).

---

## Release Phases

### Phase 0 — Pre-Release (Planning completion)
- [ ] All planning artifacts complete and approved.
- [ ] Contracts domain stress-test accepted.
- [ ] Governed dimension list finalized.
- [ ] Stewardship UX requirements accepted.
- [ ] Physical architecture memo accepted.

### Phase 1 — Seed and Build
- [ ] Governed dimension tables built and seeded in sandbox.
- [ ] Xref_Registry table built with all constraints.
- [ ] All pipeline contract views built.
- [ ] Stewardship view built.
- [ ] Stewardship command-app page deployed (internal/sandbox).
- [ ] Seed process executed: legacy CITT rows loaded as UNRESOLVED candidates.
- [ ] Key resolution pass completed (REVIEW_REQUIRED rows ready for steward).

### Phase 2 — Steward Review and Activation
- [ ] Stewardship work queue worked; all in-scope CANONICAL rows promoted to ACTIVE.
- [ ] Zero UNRESOLVED rows remaining for domains in this release cycle.
- [ ] Seed conflicts resolved and documented.

### Phase 3 — Parallel Validation Window
- [ ] Pipeline contract views deployed alongside CITT tables (CITT still active, no writes frozen yet).
- [ ] All pipeline consumers run in parallel: both old CITT path and new view path.
- [ ] CITT parity validation executed per Validation & Reconciliation Plan.
- [ ] Zero unexplained mismatches required before proceeding.
- [ ] Sandbox company evidence collected (PDI endpoint requirement per runbook).

### Phase 4 — Cutover
- [ ] All validation checks pass.
- [ ] Business Manager issues GO.
- [ ] Pipeline consumers switched to contract views.
- [ ] Dependency audit confirms no remaining active consumers outside migrated paths.
- [ ] If dependency audit is clean, CITT freeze may be proposed (not automatic).

### Phase 5 — Stability Window
- Duration: minimum 2 release cycles.
- CITT/legacy translation tables remain operational per dependency policy (read-only only if approved in Phase 4).
- Monitoring: compare new view outputs vs frozen CITT rows daily during stability window.
- No write restriction is imposed unless explicit freeze approval has been granted.

### Phase 6 — CITT Retirement
- [ ] 2 release cycles of stable parallel operation confirmed.
- [ ] No active consumer dependencies on CITT tables confirmed (pipeline audit).
- [ ] Jason approval required for hard retirement (DROP TABLE operations are irreversible).
- [ ] Cross-workspace reference audit complete: dcc-pricing-supply, gravitate-orders, citysv-prices, citysv-costs, pdi-clone-core, csl-pricing-supply.
- [ ] Archive CITT table definitions and last-state data snapshot before drop.
- [ ] Execute drops in controlled maintenance window.
- [ ] Remove any surviving pipeline references.

---

## Cutover Gate Checklist (Must All Be Green)
| Gate | Owner | Status |
|---|---|---|
| Parity validation passed (zero unexplained mismatches) | Validator | PENDING |
| Uniqueness checks passed (no duplicate active rows) | Validator | PENDING |
| All pipeline contract views deployed and tested | Builder | PENDING |
| Stewardship UX deployed and accessible | Builder | PENDING |
| Zero UNRESOLVED rows for release-cycle domains | Steward | PENDING |
| Rollback path documented and tested | Ops | PENDING |
| Sandbox company evidence collected | Validator | PENDING |
| Business Manager GO | Business Manager | PENDING |

---

## Rollback Plan

### If Issues Detected Before Cutover (Phase 3)
- No rollback required; CITT tables are still active.
- Address issues in seed/activation phase; re-run parity validation.

### If Issues Detected After Cutover (Phase 4)
- Re-enable CITT consumers in pipeline configuration.
- Set registry ACTIVE rows to REVIEW_REQUIRED to prevent new pipeline use.
- Freeze CITT tables remain but become re-readable.
- Investigate and fix issue in registry/views.
- Re-run parity validation before re-cutover.
- NOTE: pipeline configuration rollback must be executable within one business day.

### If Critical Data Error Found During Stability Window (Phase 5)
- Same as post-cutover rollback.
- Extend stability window accordingly.
- CITT retirement (Phase 6) cannot proceed until stability window restarts cleanly.

---

## Monitoring Plan

### Active Monitoring (Ongoing)
- Pipeline BLOCK rate by domain/source (alert if BLOCK rate rises unexpectedly post-cutover).
- REVIEW_REQUIRED queue depth (alert if queue grows beyond threshold without steward activity).
- PDI clone join health: alert if any contract view returns NULL `_ID` for a previously valid Key.

### Stability Window Monitoring (Phase 5)
- Daily parity check: frozen CITT vs contract view outputs for all migrated domains.
- Alert on any divergence.

### Post-Retirement Monitoring (Phase 6+)
- Remove CITT parity checks after retirement confirmed.
- Maintain BLOCK rate monitoring indefinitely.
- Quarterly governance review of Resolution_Status distribution (UNRESOLVED queue should not grow unchecked).

---

## Ownership
| Area | Owner |
|---|---|
| Registry stewardship | Pipeline Operations / Domain Stewards |
| Contract view maintenance | Engineering |
| Governance dimension updates | Jason (senior steward approval) |
| CITT retirement authorization | Jason |
| Monitoring and alerting | Pipeline Operations |

---

## Version and Release Schedule
- v0: Planning package complete.
- v1: Build + Seed + Activation (Phase 1–2).
- v2: Parallel validation and cutover (Phase 3–4).
- v3: Stability window completion + CITT retirement (Phase 5–6).

**Exact release dates:** Set at Build stage completion.
**Minimum stability window duration:** 2 release cycles from cutover.

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Release and deprecation planning is a program-specific operations artifact, not a reusable execution skill.
