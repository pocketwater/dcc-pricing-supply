# Dev Team Prompt Usage

Use this guide when you want the pinned shared agent organization to follow the Dev Cycle Runbook cleanly.

## Core Rule

Start with the exact phrase:

`Use the dev team.`

Then declare:

1. current stage
2. allowed artifact for that turn
3. prior approved artifact, if required
4. whether the request is `PLANNING_SAFE`
5. whether the routine stops after that artifact or auto-continues through agent-owned planning gates
6. `TRAINING_OUTPUT_ROOT` when running a training/simulation routine
7. whether PDI is an endpoint (requires SQL-01 sandbox evidence before release)

## Planner Example

```text
Use the dev team.

Current stage: Planner.
Classification: PLANNING_SAFE.
Allowed artifact: PLAN_REPORT only.
TRAINING_OUTPUT_ROOT: <operator supplied path>

Produce a PLAN_REPORT for _Orders_Upload Phase 1 (S1-S5 spine + visibility).
Use the PLAN_REPORT template exactly.
Start with bootstrap approach for the lowest-cost valid output.
Include Grain In/Out, translation requirements, and ontological assumptions.
Do not produce SQL, build packets, design details, or downstream-stage content.
Route the completed PLAN_REPORT to Business Manager automatically.
If APPROVED, align and emit the PROJECT_PLANNING_MANIFEST.
Do not ask Jason whether to continue unless an escalation state is triggered.
Append Skill Opportunity Review with NO_CANDIDATE or CANDIDATE_RECOMMENDED.
```

## Architect Example

```text
Use the dev team.

Current stage: Architect.
Prior approved artifact: PLAN_REPORT approved by Business Manager on 2026-04-13.
Allowed artifact: DESIGN_REPORT only.

Produce the DESIGN_REPORT within approved PLAN_REPORT scope only.
Include Grain In/Out, translation requirements, and ontological assumptions.
Do not change scope.
Do not produce BUILD_REPORT content.
Stop after the DESIGN_REPORT and wait for Planner + Business Manager approval.
```

## Builder Example

```text
Use the dev team.

Current stage: Builder.
Prior approved artifact: DESIGN_REPORT approved by Planner and Business Manager on 2026-04-13.
Allowed artifact: BUILD_REPORT only.

Produce the BUILD_REPORT only.
Implement exactly what the approved DESIGN_REPORT authorizes.
Include Grain In/Out, translation implementation notes, and ontological assumptions.
State whether validation queries are included.
Stop after the BUILD_REPORT and wait for Validator stage.
```

## Validator Example

```text
Use the dev team.

Current stage: Validator.
Prior approved artifact: BUILD_REPORT completed for the approved DESIGN_REPORT.
Allowed artifact: VALIDATION_REPORT only.

Produce the VALIDATION_REPORT only.
Include reproducible evidence, pass/fail summary, and blocking issues.
Include Grain In/Out, translation validation, ontological assumptions check, and deontological failure check.
If PDI is an endpoint, include SQL-01 sandbox validation evidence.
Do not rewrite implementation.
Stop after the VALIDATION_REPORT and wait for End User review.
```

## End User Example

```text
Use the dev team.

Current stage: End User.
Prior approved artifact: VALIDATION_REPORT completed.
Allowed artifact: UX_REPORT only.

Produce the UX_REPORT only.
Evaluate click path, friction, failure clarity, and training burden.
Include Grain In/Out, translation impacts, and user-facing ontological assumptions.
Stop after the UX_REPORT and wait for Reviewer stage.
```

## Reviewer Example

```text
Use the dev team.

Current stage: Reviewer.
Prior approved artifacts:
- VALIDATION_REPORT completed
- UX_REPORT completed
Allowed artifact: structured review summary only.

Produce the review summary only.
Include risks, regression concerns, required remediations, and recommendation.
Stop after the review summary and wait for Ops stage.
```

## Ops Example

```text
Use the dev team.

Current stage: Ops.
Prior approved artifact: review summary completed.
Allowed artifact: RELEASE_REPORT + VERSION_RELEASE_SCHEDULE_REPORT only.

Produce RELEASE_REPORT and VERSION_RELEASE_SCHEDULE_REPORT.
Include deployment, rollback, monitoring, ownership, release verdict, versioning strategy, and release calendar.
Stop after both artifacts and wait for final Business Manager GO/NO-GO.
```

## Recovery Prompt

Use this when the agent drifts out of stage:

```text
Use the dev team.

Runbook mode is mandatory.
You are out of stage.
Current stage is: <stage name>.
Allowed artifact is: <artifact name> only.
Do not produce SQL, implementation steps, or downstream-stage content.
If the request is out of stage, respond with:
BLOCKED: out-of-stage request.
Then state the required prior artifact and approval.
```

## Notes

1. One stage artifact per turn.
2. Do not ask for Builder output during Planner stage.
3. Keep approvals explicit in the prompt whenever a prior gate is required.
4. For project-planning work, keep `PROJECT_PLANNING_MANIFEST` aligned after planning artifacts change.
5. For `PLANNING_SAFE` routines, planner and business_manager gates run automatically without human approval prompts.
6. For autonomous full-cycle routines, stage gates remain agent-owned and only the final package is surfaced for human operator approval.
7. Consult `dcc-pricing-supply/agent-control/primitives-index/skills/README.md` before proposing skill candidates.
8. Every stage artifact must include grain, translation, and ontology declarations.
