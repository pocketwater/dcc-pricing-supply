# Operational Artifacts

This area contains executable/live artifacts by release version.

## Version Layout

```text
operational-artifacts/
  v0/
    deployment/
    validation/
    evidence/
```

## Rules

- Place executable SQL packs, runner scripts, and generated run evidence here.
- Keep each version self-contained.
- Do not store planning narratives in this area.

## Current Versions

- `v0`
  - `deployment/`
  - `validation/`

## Promotion Rule

When a version is production-approved:

1. Mark status in release schedule docs.
2. Freeze that version folder (no in-place edits except critical fixes with change note).
3. Start next version folder (`v0.1` or `v1`) for new changes.
