# Dev Cycle Runbook

## Canonical Artifact Root

All dev team primitives in this runbook are canonical under:

`dcc-pricing-supply/agent-control/primitives-index/agents/dev_team/`

## Scope
This runbook governs contract-driven delivery across this workspace:
- dcc-pricing-supply
- csl-pricing-supply
- pdi-clone-core
- citysv-prices
- citysv-costs
- gravitate-orders
- pers-ops-jvassar

## Required Inputs
- Prior stage artifact attached before starting next stage.
- No stage execution without required approval state from previous gate.
- For project-planning engagements, a `PROJECT_PLANNING_MANIFEST` artifact is required as the final consolidated planning document.
- Operator must provide `TRAINING_OUTPUT_ROOT` when running a training/simulation cycle. If missing, controller asks once, then proceeds.
- For pipelines where PDI is an endpoint, pre-release validation must include SQL-01 sandbox company evidence.

## Skill Awareness And Candidate Loop

- Before stage routing decisions, review current skill-state guidance in:
  - `dcc-pricing-supply/agent-control/primitives-index/skills/README.md`
- During any stage, detect reusable behavior patterns and append a deterministic sidecar block:
  - `Skill Opportunity Review: NO_CANDIDATE | CANDIDATE_RECOMMENDED`
  - if `CANDIDATE_RECOMMENDED`, include: candidate name, rationale, likely inputs/outputs, and confidence
- Candidate recommendation is advisory and must not mutate skill registries unless explicitly requested.

## Planning-Safe Classification
- Classify a task as `PLANNING_SAFE` when the requested work is limited to planning-only activity.
- Planning-only activity includes: reading repo docs, creating or updating `PLAN_REPORT`, creating or updating `PROJECT_PLANNING_MANIFEST`, drafting options, risk identification, scope clarification, performance investigation planning, and non-destructive repo/documentation edits under `docs/`, `agent-control/primitives-index/agents/dev_team/`, or planning folders.
- For `PLANNING_SAFE` work, Planner-stage execution proceeds automatically through agent-owned planning gates.
- `PLANNING_SAFE` does not authorize design, build, validation, UX, review, release, code changes, SQL changes, script changes, job changes, or runtime behavior changes.

## Bootstrap-First Planning Policy
- All `PLAN_REPORT` outputs must begin with a bootstrap approach that targets the lowest-cost valid output.
- Bootstrap approach must define entry criteria, minimum success condition, and explicit criteria for expanding beyond bootstrap.

## Grain, Translation, And Ontology Requirements
- Every stage artifact must include `Grain In` and `Grain Out` declarations.
- Every stage artifact must include translation requirements or an explicit `NO_TRANSLATION_REQUIRED` declaration.
- Every stage artifact must include an ontological assumptions block and confidence note.
- Reviewer must classify ontology/deontology failures as `NONE`, `MINOR`, or `BLOCKING`.

## Execution Order
1. Planner -> `PLAN_REPORT` -> Business Manager approval.
2. Architect -> `DESIGN_REPORT` -> Planner + Business Manager approval.
3. Builder -> `BUILD_REPORT`.
4. Validator -> `VALIDATION_REPORT`.
5. End User -> `UX_REPORT`.
6. Reviewer -> structured risk assessment summary.
7. Ops -> `RELEASE_REPORT` + `VERSION_RELEASE_SCHEDULE_REPORT` -> Business Manager final GO/NO-GO.

## Gate Ownership Model

### Approval Is Agent-Executed
Each stage approval gate is executed by the designated approving agent, not the human owner.
- `business_manager` issues APPROVED / REJECTED / GO / NO-GO on all gates within their authority.
- `planner` issues APPROVED / REJECTED on DESIGN_REPORT before it advances.
- `end_user` issues APPROVED / REJECTED / NO-GO on UX_REPORT before Reviewer proceeds.
- Agents must emit a deterministic gate decision. Deferral to human is not a valid outcome unless an explicit escalation state is triggered.

### Allowed Escalation States
An agent MAY surface to the human only under these conditions:

| State | Meaning |
|---|---|
| `BLOCKED_FOR_OWNER` | Agent cannot proceed without human action (credentials, access, external system) |
| `HUMAN_APPROVAL_REQUIRED` | Destructive, irreversible, or production-impacting action is in scope |

Outside these states, the agent must issue a decision and continue or reject.

### Human (Jason) Involvement
Jason is ONLY engaged when:
- Any agent returns `BLOCKED_FOR_OWNER`
- Any agent returns `HUMAN_APPROVAL_REQUIRED`
- A destructive or production-impacting action is proposed
- Credentials, access grants, or external system changes are required
- Code, SQL, scripts, jobs, or production runtime behavior will be changed
- Cost, security, compliance, or ownership risk is introduced

Normal stage-to-stage approvals are agent-executed only. Human operator approval is requested once at the final project package handoff.

### Orchestration Behavior
After each stage artifact is produced:
1. Route automatically to the required approving agent(s).
2. Wait for their deterministic decision.
3. If APPROVED / GO → advance to next stage.
4. If REJECTED / NO-GO → route back to owning stage (rework loop).
5. If BLOCKED_FOR_OWNER or HUMAN_APPROVAL_REQUIRED → stop and surface to user.

No default assumption that user approval is required between stages.

For `PLANNING_SAFE` routines:
1. Run Planner work and Business Manager approval automatically.
2. If `PLAN_REPORT` is APPROVED and the engagement is project-planning, align and emit `PROJECT_PLANNING_MANIFEST` before surfacing the result.
3. Do not stop after normal planning steps to ask Jason whether to continue.

For autonomous full-cycle routines:
1. Execute all stages in order using agent-owned gates.
2. Do not pause for human gate approval between stages.
3. At completion, surface one final package for human operator approval.

## Re-Runnable Training Project

Use `examples/rerunnable_training_project.md` as the canonical micro-project for repeatability testing and agent optimization.
- This project is intentionally small and deterministic.
- Artifacts from each run are written to `TRAINING_OUTPUT_ROOT` supplied by the operator.
- Training runs should preserve stage order and produce comparable evidence over time.

## Gate Rules
- No stage skipped.
- No self-approval.
- No undefined artifacts.
- Each stage output must match its template contract.
- Each stage output must include grain, translation, and ontology declarations.
- Business Manager and End User have enforceable veto points.
- Approval gates are executed by agents; human involvement only on explicit escalation.
- Project plans must include `PROJECT_PLANNING_MANIFEST` and keep it aligned to the latest approved stage artifacts.

## Rework Loop
- If any gate returns REJECTED/NO-GO/BLOCKED:
  - Route to owning prior stage for rework.
  - Reissue the same stage artifact name with version increment.
  - Re-run all downstream gates affected by the change.

## Completion Criteria
- All required artifacts are present and approved where required.
- For project-planning work, `PROJECT_PLANNING_MANIFEST` is present and references the active planning artifact set.
- Final manager decision is GO.
- `VERSION_RELEASE_SCHEDULE_REPORT` is present and aligned with the release verdict.
- For PDI endpoint pipelines, SQL-01 sandbox company validation evidence is present.
- Deployment, rollback, monitoring, and ownership are explicit in RELEASE_REPORT.
- Final project package is surfaced for one human operator approval.
