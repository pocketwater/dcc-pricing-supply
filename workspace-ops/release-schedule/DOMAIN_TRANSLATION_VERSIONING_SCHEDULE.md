# Domain Translation Versioning Schedule
Version: 1.0
Updated: 2026-05-05
Owner: Jason

## Purpose

Define how `workspace-ops/domain-translations` evolves from current v0 baseline to a production-grade operational model with clean planning/operational separation.

## Version Taxonomy

- Planning iterations: `vN-planning` (major concept cycles)
- Operational artifact versions: `vN` / `vN.M` (deployable execution packs)

## Current State

- Planning iteration active: `v0-planning`
- Operational artifact baseline: `operational-artifacts/v0`
- Canonical cutover status: completed for gravitate-orders product/terminal joins

## Release Cadence (Recommended)

- Minor versions (`vN.M`): every 2 weeks or when one deployable change bundle is ready
- Major versions (`vN`): when domain contract or lifecycle model changes materially

## Planned Roadmap

### v0.1 (Hardening)
Target window: next 1-2 weeks

Scope:
- Add repeatable drift checks for canonical views/table contracts
- Create artifact manifest per version (`MANIFEST.json` or markdown) with checksums and ownership
- Add rollback SQL pack for each deployment pack
- Normalize evidence capture locations under `operational-artifacts/v0.1/evidence`

Exit criteria:
- Drift check pack passes in SQL-02
- Rollback pack tested once in sandbox
- Version manifest published

### v0.2 (Cross-Repo Migration Completion)
Target window: following 2-4 weeks

Scope:
- Migrate citysv-prices view dependencies from CITT clone joins to canonical views
- Validate citysv-costs dependency path and migrate where appropriate
- Re-run cross-repo dependency audit and close blockers

Exit criteria:
- No remaining runtime dependencies on legacy product/terminal xref in active paths
- Dependency matrix updated and approved

### v1.0 (Production Stewardship Grade)
Target window: next major iteration

Scope:
- Introduce stewardship UX implementation handoff package
- Add automated CI gate for schema/view contract verification
- Freeze legacy translation surfaces per approved deprecation plan

Exit criteria:
- Stewardship workflow documented and runnable
- CI contract gate required for release
- Legacy surface freeze approved by business manager and validated across repos

## Procedure Integration

For each new domain-translation version:

1. Create `operational-artifacts/<version>/` subfolders (`deployment`, `validation`, `evidence`).
2. Keep planning updates in current major planning folder (or start next `vN-planning` for major change).
3. Update `release-schedule/DEPENDENCY_MATRIX.md` with dependency impact.
4. Update `release-schedule/README.md` status dashboard entry.
5. Record gate decision in repo timeline summary where applicable.

## Governance Gates

- No legacy table freeze/deprecation without completed cross-repo consumer migration.
- No release approval without validation pack evidence attached for current version.
- No major planning iteration closure without updated root `domain-translations/README.md` map.
