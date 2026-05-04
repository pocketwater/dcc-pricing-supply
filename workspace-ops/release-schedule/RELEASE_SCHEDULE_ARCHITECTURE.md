# Release Schedule Architecture Runbook
Version: 1.0
Updated: 2026-05-04
Owner: Jason

## Overview
This runbook defines how release planning and versioning are split between **operational repositories** (workspace repos) and the **control repository** (DCC) to maintain clear governance boundaries while preserving operational autonomy.

## Architecture Pattern

### Layer 1: Operational Repos (Execution)
Each operational repository maintains its own **release-schedule** folder at the root level:

```
gravitate-orders/
  release-schedule/
    PROJECT_PLANNING_MANIFEST.md
    Phase3_Session_YYYYMMDD.ics
    Phase4_Session_YYYYMMDD.ics
    ...
    README.md (repo-specific release notes & runbooks)

citysv-prices/
  release-schedule/
    PROJECT_PLANNING_MANIFEST.md
    Phase3_Session_YYYYMMDD.ics
    ...

citysv-costs/
  release-schedule/
    PROJECT_PLANNING_MANIFEST.md
    ...
```

**Contents of operational repo `release-schedule/`:**
- **PROJECT_PLANNING_MANIFEST.md**: execution plan with stage objectives, deliverables, exit criteria
- **Phase_N_Session_*.ics**: calendar events for working sessions (iCalendar format)
- **README.md**: repo-specific runbook for release execution, rollback procedures, monitoring

**Ownership:** Each operational repo team owns their release-schedule folder. This remains the source of truth for that repo's execution cadence, planning, and release procedures.

**Why here:** Cloning or accessing a repo gives you immediate context about its release plan and operational procedures.

---

### Layer 2: Control Repo (Governance & Aggregation)
DCC maintains **release-schedule** folder for cross-repo coordination and governance:

```
dcc-pricing-supply/
  release-schedule/
    README.md (this runbook)
    SCHEDULE_ARCHITECTURE.md

    gravitate-orders/
      timeline_summary.md (aggregate view + reference)

    citysv-prices/
      timeline_summary.md

    citysv-costs/
      timeline_summary.md

    MASTER_RELEASE_CALENDAR.ics (all repos merged)
    DEPENDENCY_MATRIX.md (cross-repo sequencing)
```

**Contents of DCC `release-schedule/`:**
- **This runbook** (ARCHITECTURE.md or README.md)
- **Per-repo timeline summaries**: links to operational repo plans + rolled-up status
- **MASTER_RELEASE_CALENDAR.ics**: consolidated calendar of all operational releases (for stakeholder overview)
- **DEPENDENCY_MATRIX.md**: cross-repo sequencing, gates, and coordination points
- **Governance templates**: standardized structures for new repos to follow

**Ownership:** Control team maintains these aggregations. Updated when operational repos finalize their release-schedules.

**Why here:** Executive/governance view of the entire release portfolio without cloning each repo. Dependencies and sequencing visible in one place.

---

## Governance Boundary

| Concern | Operational Repo | DCC Control |
|---------|------------------|-------------|
| **Execution plans** | ✓ Authoritative | - Reference only |
| **Stage gates** | ✓ Define locally | ✓ Enforce sequence |
| **Performance baselines** | ✓ Measure & own | - Aggregate only |
| **Runbooks** | ✓ Operational detail | - High-level reference |
| **Calendar events** | ✓ Local working sessions | ✓ Master aggregation |
| **Version history** | ✓ In-repo release notes | - Governance timeline |
| **Dependency sequencing** | - Consulted | ✓ Authoritative |
| **Release approval** | - Requested | ✓ Gate authority |

---

## New Repo Onboarding

When adding a new operational repo (e.g., `pdi-clone-core`):

1. **Create `release-schedule/` folder at repo root**
   ```
   pdi-clone-core/release-schedule/
   ```

2. **Populate with mandatory files:**
   - `PROJECT_PLANNING_MANIFEST.md` (copy template from gravitate-orders)
   - `Phase_N_Session_*.ics` files (one per stage-gate session)
   - `README.md` (operational runbook)

3. **Register in DCC:**
   - Add `dcc-pricing-supply/release-schedule/pdi-clone-core/timeline_summary.md`
   - Update `DEPENDENCY_MATRIX.md` to reflect new repo's sequencing
   - Regenerate `MASTER_RELEASE_CALENDAR.ics`

---

## Timeline Aggregation (Example)

**File:** `dcc-pricing-supply/release-schedule/gravitate-orders/timeline_summary.md`

```markdown
# CitySV Gravitate -> PDI ODE Hardening
Project: Gravitate Orders Pipeline Hardening
Status: Phase 3 (In Progress)
Repo Link: [gravitate-orders](../../../gravitate-orders)

## Release Schedule
- Phase 3 (Week 1): May 4, 2026 — Release planning baseline and integration scope lock
- Phase 4 (Week 2): May 11, 2026 — Gate and observability hardening
- Phase 5 (Week 3): May 18, 2026 — Performance and integration reliability
- Phase 6 (Week 4): May 25, 2026 — Release readiness and handoff

**Canonical source:** [PROJECT_PLANNING_MANIFEST.md](../../../gravitate-orders/release-schedule/PROJECT_PLANNING_MANIFEST.md)

## Dependencies
- Upstream: None (Phase 1-2 complete)
- Downstream: citysv-prices Phase 5 depends on Gravitate Phase 6 release

## Key Milestones
- May 25: release decision package complete
- June 1: post-import integration monitoring live
```

---

## Updating the Aggregation

**When to update DCC roll-ups:**
1. Operational repo finalizes a new phase manifest → add 1-line status to timeline_summary
2. Operational repo changes release date → update MASTER_RELEASE_CALENDAR.ics + timeline_summary
3. New dependency discovered → update DEPENDENCY_MATRIX.md
4. Repo reaches Phase 6 (release) → update governance record

**How (process):**
- No real-time sync required
- Update DCC roll-ups at end of each operational phase
- Treat DCC aggregation as a "weekly digest" not a live feed

---

## Links & References

- **Operational Repo Template:** [gravitate-orders/release-schedule](../../../gravitate-orders/release-schedule)
- **Workspace Repos Covered:** gravitate-orders, citysv-prices, citysv-costs, pdi-clone-core, csl-pricing-supply
- **Stage-Gate Contract:** See [dcc-pricing-supply/.github/runbooks/dev_cycle.md](../../.github/runbooks/dev_cycle.md)

---

## FAQ

**Q: Why not keep everything in DCC?**
A: Operational autonomy. Cloning gravitate-orders should give you everything needed to understand and execute the release. No external repo dependencies.

**Q: Why not keep everything in each operational repo?**
A: Governance visibility. Leadership needs cross-repo sequencing and dependency management without cloning 7 repos.

**Q: What if a repo isn't part of this workspace yet?**
A: Add the repo to Workspace Coverage in `.github/copilot-instructions.md`, then create its release-schedule folder and register in DCC.

**Q: Can release timelines change after approval?**
A: Yes, but must be re-gated. Update the manifest in the operational repo, then sync DCC aggregations and re-run DEPENDENCY_MATRIX analysis.
