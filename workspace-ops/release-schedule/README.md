# DCC Release Schedule Hub
Version: 1.0
Updated: 2026-05-04

## Overview
This folder aggregates release timelines, sequencing, and governance status across all operational repositories in the COIL Pricing Supply workspace. It is the **governance and visibility layer** for cross-repo coordination and dependency management.

## Folder Structure

```
dcc-pricing-supply/release-schedule/
├── RELEASE_SCHEDULE_ARCHITECTURE.md       # Governance runbook (read this first)
├── DEPENDENCY_MATRIX.md                   # Cross-repo sequencing and gates [TBD]
├── MASTER_RELEASE_CALENDAR.ics            # Aggregated calendar for all phases [TBD]
│
├── gravitate-orders/
│   └── timeline_summary.md                # Gravitate hardening project digest
│
├── citysv-prices/
│   └── timeline_summary.md                # Pricing system release plan [TBD]
│
├── citysv-costs/
│   └── timeline_summary.md                # Costs system release plan [TBD]
│
├── pdi-clone-core/
│   └── timeline_summary.md                # Clone service release plan [TBD]
│
└── csl-pricing-supply/
    └── timeline_summary.md                # CSL pricing release plan [TBD]
```

## Key Documents

### [RELEASE_SCHEDULE_ARCHITECTURE.md](RELEASE_SCHEDULE_ARCHITECTURE.md)
**Read this first.** Defines:
- Where operational repos store their release plans (release-schedule/ at root)
- What DCC aggregates (timelines, dependencies, master calendar)
- Governance boundaries (operational autonomy vs. control oversight)
- Onboarding template for new repos

### [gravitate-orders/timeline_summary.md](gravitate-orders/timeline_summary.md)
Digest of current project:
- Phase schedule and milestones
- Governance gates and owners
- Upstream/downstream dependencies
- Links to canonical sources in operational repo

### [DOMAIN_TRANSLATION_VERSIONING_SCHEDULE.md](DOMAIN_TRANSLATION_VERSIONING_SCHEDULE.md)
Domain translation versioning and artifact placement policy:
- Planning iterations in `workspace-ops/domain-translations/Design Planning/<major>-planning/`
- Live executable artifacts in `workspace-ops/domain-translations/operational-artifacts/<version>/`
- Version roadmap (`v0.1`, `v0.2`, `v1.0`) and gate criteria

### DEPENDENCY_MATRIX.md *(Coming)*
Cross-repo sequencing logic:
- Phase gates that block other repos
- Approval routing and timing constraints
- Release window conflicts or overlaps
- Escalation triggers

### MASTER_RELEASE_CALENDAR.ics *(Coming)*
Consolidated iCalendar with all operational phase events:
- Single file for executive/stakeholder calendar integration
- Regenerated each time a repo updates its phase schedule

---

## How to Use

**For Phase Planning (Operational Teams):**
1. Work in your repo's `release-schedule/` folder (e.g., `gravitate-orders/release-schedule/`)
2. Update your `PROJECT_PLANNING_MANIFEST.md` with phase objectives and deliverables
3. Notify control team when ready for gate approval
4. Control team updates this digest (timeline_summary.md)

**For Governance (Control/Leadership):**
1. Review [RELEASE_SCHEDULE_ARCHITECTURE.md](RELEASE_SCHEDULE_ARCHITECTURE.md) to understand the split
2. Check individual repo digests (timeline_summary.md files) for phase status
3. Review DEPENDENCY_MATRIX.md to identify cross-repo constraints
4. Use MASTER_RELEASE_CALENDAR.ics for portfolio-level scheduling

**For New Repos:**
1. Read [RELEASE_SCHEDULE_ARCHITECTURE.md](RELEASE_SCHEDULE_ARCHITECTURE.md) section "New Repo Onboarding"
2. Create `your-repo/release-schedule/` folder
3. Use gravitate-orders as a template
4. Register your repo in this DCC folder

---

## Status Dashboard

| Repo | Phase | Status | Last Updated |
|------|-------|--------|--------------|
| [gravitate-orders](gravitate-orders/timeline_summary.md) | 3 of 6 | 🔄 In Progress | 2026-05-04 |
| citysv-prices | - | ⏳ Pending | - |
| citysv-costs | - | ⏳ Pending | - |
| pdi-clone-core | - | ⏳ Pending | - |
| csl-pricing-supply | - | ⏳ Pending | - |

---

## Quick Links

- **Operational Repo Runbooks:** See gravitate-orders/release-schedule/README.md (model for others)
- **Stage-Gate Contract:** [dcc-pricing-supply/.github/runbooks/dev_cycle.md](../../.github/runbooks/dev_cycle.md)
- **Agent Control Model:** [dcc-pricing-supply/agent-control/](../../agent-control/)

---

## Next Steps

- [ ] Populate DEPENDENCY_MATRIX.md with cross-repo sequencing
- [ ] Generate MASTER_RELEASE_CALENDAR.ics from all operational calendars
- [ ] Register remaining operational repos (citysv-prices, citysv-costs, etc.)
- [ ] Create timeline_summary.md for each repo as they define release schedules
- [ ] Execute `DOMAIN_TRANSLATION_VERSIONING_SCHEDULE.md` milestone `v0.1` hardening pack
