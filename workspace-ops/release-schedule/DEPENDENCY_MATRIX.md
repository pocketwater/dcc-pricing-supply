# Cross-Repo Release Dependency Matrix
Updated: 2026-05-04
Version: 1.0

## Purpose
Maps phase gates, sequencing constraints, and approval dependencies across all operational repositories. Updated when a repo finalizes a phase gate or changes its release schedule.

---

## Current Dependencies

### Gravitate-Orders → CitySV Prices
**Gate:** Gravitate Phase 6 Exit (Release Readiness and Integration Handoff)
**Blocks:** CitySV Prices Phase 5-6 gates
**Reason:** Post-import integration must be live and monitored in Gravitate before Prices can finalize SLO envelope and release
**Status:** Gravitate Phase 3 in progress; Prices Phase 5 gates blocked until Phase 6 (May 25)

### Gravitate-Orders → CitySV Costs
**Gate:** Gravitate Phase 6 Exit
**Blocks:** CitySV Costs Phase 5-6 gates
**Reason:** Shared downstream dependency; Costs SLO envelope depends on integration reliability demonstrated in Gravitate
**Status:** Gravitate Phase 3 in progress; Costs Phase 5 gates blocked until Phase 6 (May 25)

---

## Phase Gate Approval Routing

| Repo | Phase | Owner | Approver(s) | Dependency Check |
|------|-------|-------|-------------|------------------|
| Gravitate | 3 | Planner | Business Manager | None |
| Gravitate | 4 | Validator | Reviewer | Phase 3 exit signed |
| Gravitate | 5 | Perf Lead | Ops | Phase 4 exit signed |
| Gravitate | 6 | Release Mgr | Business Manager | Phase 5 exit signed; notify downstream (Prices, Costs) |
| Prices | 5 | Perf Lead | Ops | **Gravitate Phase 6 exit** |
| Prices | 6 | Release Mgr | Business Manager | Phase 5 exit + **Gravitate Phase 6 exit** |
| Costs | 5 | Perf Lead | Ops | **Gravitate Phase 6 exit** |
| Costs | 6 | Release Mgr | Business Manager | Phase 5 exit + **Gravitate Phase 6 exit** |

---

## Release Window Calendar

| Repo | Phase 3 | Phase 4 | Phase 5 | Phase 6 | Release Date |
|------|---------|---------|---------|---------|--------------|
| **Gravitate** | May 4 | May 11 | May 18 | May 25 | Jun 1 |
| **Prices** | - | - | Jun 1* | Jun 8* | Jun 15 |
| **Costs** | - | - | Jun 1* | Jun 8* | Jun 15 |

*Blocked until Gravitate Phase 6 (May 25). Starts May 26 pending sign-off.

---

## Escalation Triggers

**If Gravitate Phase 6 misses May 25:**
- Prices and Costs Phase 5 gates automatically defer 1 week
- Notify Business Manager; assess portfolio-level impact
- Reevaluate Phase 4 gates for any acceleration opportunity

**If any repo misses Phase exit gate:**
- Submitter notifies Approver + dependent downstream repos
- Dependent repos update internal schedules and notify their approvers

---

## Template: Adding a New Dependency

When a new operational repo is onboarded or a cross-repo dependency emerges:

```
### [Upstream Repo] → [Downstream Repo]
**Gate:** [Upstream Phase X Exit]
**Blocks:** [Downstream Phase Y Gate(s)]
**Reason:** [Business/technical constraint]
**Status:** [Current state]
```

---

## Notes

- Dependencies are unidirectional: downstream repos cannot release until upstream gates are signed.
- Parallel execution is allowed (e.g., Prices Phase 3 can happen while Gravitate Phase 4 runs) as long as final gates don't conflict.
- Cross-repo gates are marked **bold** in the approval routing table.

---

## Future Expansions

- [ ] Populate dependencies for pdi-clone-core and csl-pricing-supply as they define release schedules
- [ ] Add performance SLA cross-checks (if Gravitate integration overhead > threshold, adjust Prices/Costs budget)
- [ ] Automated dependency graph visualization (if needed for large portfolio)
