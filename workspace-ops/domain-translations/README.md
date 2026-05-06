# Domain Translations

This folder is the source-of-truth structure for translation governance artifacts in DCC.

## Structure

```text
domain-translations/
  Design Planning/
    <iteration-folder>/
      ...planning docs only...

  operational-artifacts/
    <version>/
      deployment/
      validation/
      evidence/
```

## Contract

- Planning documents live only under `Design Planning/<iteration-folder>/`.
- Executable/live artifacts (SQL packs, run scripts, evidence bundles) live only under `operational-artifacts/<version>/`.
- Every major product iteration gets exactly one planning folder (for example `v0-planning`, `v1-planning`).
- Every release execution version gets exactly one operational folder (for example `v0`, `v0.1`, `v1`).

## Current Iterations

- Planning: `Design Planning/v0-planning`
- Operational: `operational-artifacts/v0`

## Naming Standards

- Planning folder: `<major>-planning` (example: `v1-planning`)
- Operational version folder: semantic version token (example: `v0`, `v0.1`, `v1`)
- Pack files: `<purpose>.<project>.v<version>.<ext>` when practical

## Release Schedule Integration

The artifact lifecycle and versioning cadence are governed by:

- `workspace-ops/release-schedule/DOMAIN_TRANSLATION_VERSIONING_SCHEDULE.md`
- `workspace-ops/release-schedule/RELEASE_SCHEDULE_ARCHITECTURE.md`

## Decision Rule

If a file can be run, deployed, or executed, it belongs in `operational-artifacts`.
If a file explains design, decisions, plans, or governance, it belongs in `Design Planning`.
