# Dev Team Planner Smoke Test

Use this to verify that `Use the dev team` stays in Planner stage, classifies planning-only work as `PLANNING_SAFE`, and does not ask Jason for permission.

## Prompt To Paste

```text
Use the dev team.

Current stage: Planner.
Classification: PLANNING_SAFE.
Allowed artifact: PLAN_REPORT only.
TRAINING_OUTPUT_ROOT: <operator supplied path>

Produce a PLAN_REPORT for _Orders_Upload Phase 1 (S1-S5 spine + visibility).
Use the PLAN_REPORT template exactly.
Do not produce SQL, build packets, implementation guidance, design artifacts, validation artifacts, UX artifacts, or release artifacts.
Route the PLAN_REPORT to Business Manager automatically.
If APPROVED, align and emit the PROJECT_PLANNING_MANIFEST.
Do not prompt Jason to continue unless an escalation state is returned.
Append Skill Opportunity Review with NO_CANDIDATE or CANDIDATE_RECOMMENDED.
```

## Expected Result

The response should:

1. Start with `# PLAN_REPORT`.
2. Contain only the template sections from `dcc-pricing-supply/agent-control/primitives-index/agents/dev_team/reports/PLAN_REPORT.template.md`.
3. End with the `Approval: [Manager]` section.
4. Not contain SQL.
5. Not contain build packets.
6. Not contain `DESIGN_REPORT`, `BUILD_REPORT`, `VALIDATION_REPORT`, `UX_REPORT`, review summary, or `RELEASE_REPORT` content.
7. Not continue into Architect or Builder work.
8. Not ask Jason for approval or continuation.

## Fail Conditions

The prompt failed if the response includes any of the following:

1. executable SQL
2. table/view/procedure implementation blocks
3. staged builder instructions
4. multiple stage artifacts in one response
5. any approval claim beyond the Business Manager decision actually issued
6. any prompt asking Jason to approve routine planning work

## Follow-On Gate

If the smoke test passes:

1. submit the PLAN_REPORT for Business Manager approval automatically
2. if approved, align the PROJECT_PLANNING_MANIFEST automatically for project-planning work
3. only after the planning package is complete, surface it to Jason
