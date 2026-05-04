# Gravitate-Orders Release Timeline (Control Aggregate)
Workspace: COIL Pricing Supply
Project: CitySV Gravitate -> PDI ODE Hardening
Status: Phase 3 (In Progress)
Updated: 2026-05-04
Canonical Source: [gravitate-orders/release-schedule/PROJECT_PLANNING_MANIFEST.md](../../../gravitate-orders/release-schedule/PROJECT_PLANNING_MANIFEST.md)

---

## Release Phase Schedule

| Phase | Window | Objective | Status |
|-------|--------|-----------|--------|
| **Phase 3** | May 4, 2026 | Release planning baseline and integration scope lock | 🔄 In Progress |
| **Phase 4** | May 11, 2026 | Gate and observability hardening | ⏳ Scheduled |
| **Phase 5** | May 18, 2026 | Performance and integration reliability | ⏳ Scheduled |
| **Phase 6** | May 25, 2026 | Release readiness and handoff | ⏳ Scheduled |

---

## Key Milestones

- **2026-05-04 (Phase 3):** Risk register, dependency matrix, baseline performance measurement, release gates, post-import integration contract finalized
- **2026-05-11 (Phase 4):** Post-import gate definitions, trigger handshake controls, warning budget thresholds finalized
- **2026-05-18 (Phase 5):** Integration overhead benchmarked, SLO envelope confirmed with warning/failure handling
- **2026-05-25 (Phase 6):** Release decision package complete, integration controls live, monitoring ownership assigned

---

## Dependencies

### Upstream
- Phase 1-2 complete (baseline hardening)

### Downstream
- **citysv-prices:** Phase 5-6 gates dependent on Gravitate Phase 6 release (post-import integration live in Gravitate)
- **citysv-costs:** Phase 5-6 gates dependent on Gravitate Phase 6 release

---

## Governance & Controls

| Gate | Owner | Approval | Status |
|------|-------|----------|--------|
| Phase 3 Exit | Planner + Architecture | Business Manager | 🔄 In Progress |
| Phase 4 Exit | Validator | Reviewer | ⏳ Pending |
| Phase 5 Exit | Performance Lead | Ops | ⏳ Pending |
| Phase 6 Exit | Release Manager | Business Manager | ⏳ Pending |

---

## Stage-Gate Sequence (Mandatory)
Per [COIL Pricing Supply Operating Model](..)

1. **Plan** → Design
2. **Design** → Build
3. **Build** → Validate
4. **Validate** → UX Review
5. **UX Review** → Release Review
6. **Release Review** → Release

No stage skipping. No self-approval.

---

## Local Artifacts

**Working documents** (in gravitate-orders/release-schedule/):
- `PROJECT_PLANNING_MANIFEST.md` — Execution plan with deliverables and exit criteria
- `Phase3_Session_20260504.ics` — Working session calendar (iCalendar format)
- `Phase4_Session_20260511.ics` — Phase 4 session
- `Phase5_Session_20260518.ics` — Phase 5 session
- `Phase6_Session_20260525.ics` — Phase 6 session
- `README.md` — Operational runbook (triage, rollback, monitoring setup)

**Findings & Brief** (in gravitate-orders/../inbox/briefs/):
- `PDI_SQL01_Post_Import_Integration_Findings_2026-05-04.md` — Read-only research findings on post-import integration feasibility

---

## Cross-Repo Sequencing Notes

**Why post-import integration is in-scope for Phases 3-6:**
- Feasible to integrate without schedule extension
- Gate-controlled step after import completion
- Warning/failure capture is dual-path (persisted + runtime)
- Must be locked in Phase 3 contract to enable Phase 4-6 controls

**Integration dependencies on downstream repos:**
- citysv-prices cannot finalize Phase 5 SLO envelope until Gravitate Phase 5 benchmarks are available
- citysv-costs Phase 6 release gate requires Gravitate Phase 6 sign-off (integration controls live)

---

## Historical Record

| Date | Update | Phase |
|------|--------|-------|
| 2026-05-04 | Project launched; Phase 3 scope locked with post-import integration | Phase 3 |
| (TBD) | Phase 3 exit review and approvals | Phase 3 |
| (TBD) | Phase 4 gate controls finalized | Phase 4 |
| (TBD) | Phase 5 performance envelope approved | Phase 5 |
| (TBD) | Phase 6 release package and handoff | Phase 6 |

---

## How to Use This Document

**For decision-makers:**
- See milestones and governance gate owners for approval routing
- Check dependencies for cross-repo sequencing constraints

**For operational teams:**
- Follow canonical source (gravitate-orders/release-schedule/PROJECT_PLANNING_MANIFEST.md) for working instructions
- This document is a digest for visibility only

**For control/governance:**
- Use milestones to track portfolio-level progress
- Monitor phase exits against stage-gate contract
- Update this digest at end of each phase
