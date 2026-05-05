# Re-Runnable Training Project: Agent Cycle Micro Harness

## Purpose

Provide a deterministic, small-scope project that can be repeated to tune stage prompts, gate quality, and skill-candidate detection without touching production runtime behavior.

## Operator Inputs

- `TRAINING_OUTPUT_ROOT` (required): destination directory where every stage artifact from the run is written.
- Optional run label (recommended): `run_YYYYMMDD_HHMM`.

## Training Scenario

Project name: `Micro Pipeline Health Brief`

Target outcome:
- Produce a complete dev cycle package that designs and documents a synthetic pipeline health brief workflow.
- Keep implementation scope non-destructive and test-data only.

Scope constraints:
- No production SQL execution.
- No production script/job changes.
- No external credential requirements.
- Any code or SQL examples are simulation-only and marked clearly as non-production.

## Canonical Prompt

```text
Use the dev team.

Mode: autonomous full-cycle training.
Project: Micro Pipeline Health Brief.
TRAINING_OUTPUT_ROOT: <operator supplied path>

Objective:
Create a repeatable package that demonstrates Plan -> Design -> Build -> Validate -> UX -> Review -> Release with agent-owned gates.

Constraints:
- Non-production simulation only.
- No destructive operations.
- No runtime behavior changes.
- Use deterministic artifacts and explicit pass/fail checks.

At each stage:
- follow runbook and template contracts exactly
- route to required approving agents automatically
- append Skill Opportunity Review: NO_CANDIDATE or CANDIDATE_RECOMMENDED

At completion:
- provide final package for one human operator approval
- include a short optimization note on what could improve in next run
```

## Expected Outputs

- `PLAN_REPORT`
- `DESIGN_REPORT`
- `BUILD_REPORT`
- `VALIDATION_REPORT`
- `UX_REPORT`
- structured review summary
- `RELEASE_REPORT`
- final Business Manager decision
- final operator approval request
- per-stage `Skill Opportunity Review`

## Repeatability Checks

- Stage order preserved exactly.
- No stage skip.
- No self-approval.
- No human handoff approval requested between stages.
- Exactly one final operator approval request.
- Artifacts are written under `TRAINING_OUTPUT_ROOT` with deterministic names.

## Suggested Output Naming

Use:
- `<TRAINING_OUTPUT_ROOT>/<run_label>/01_PLAN_REPORT.md`
- `<TRAINING_OUTPUT_ROOT>/<run_label>/02_DESIGN_REPORT.md`
- `<TRAINING_OUTPUT_ROOT>/<run_label>/03_BUILD_REPORT.md`
- `<TRAINING_OUTPUT_ROOT>/<run_label>/04_VALIDATION_REPORT.md`
- `<TRAINING_OUTPUT_ROOT>/<run_label>/05_UX_REPORT.md`
- `<TRAINING_OUTPUT_ROOT>/<run_label>/06_REVIEW_SUMMARY.md`
- `<TRAINING_OUTPUT_ROOT>/<run_label>/07_RELEASE_REPORT.md`
- `<TRAINING_OUTPUT_ROOT>/<run_label>/08_FINAL_PACKAGE_SUMMARY.md`
