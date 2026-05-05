# Validation Checklist (Pete Before Commit)

## Structure
- [ ] All required folders exist:
  - [ ] `agent-control/primitives-index/agents/dev_team/agents/`
  - [ ] `agent-control/primitives-index/agents/dev_team/reports/`
  - [ ] `agent-control/primitives-index/agents/dev_team/prompts/`
  - [ ] `agent-control/primitives-index/agents/dev_team/runbooks/`
  - [ ] `agent-control/primitives-index/agents/dev_team/examples/`

## Agent Definitions
- [ ] Exactly 8 agents are defined:
  - [ ] planner
  - [ ] architect
  - [ ] builder
  - [ ] validator
  - [ ] reviewer
  - [ ] ops
  - [ ] business_manager
  - [ ] end_user
- [ ] Each agent includes mission.
- [ ] Each agent includes authority boundaries.
- [ ] Each agent includes output contract.

## Report Contracts
- [ ] PLAN_REPORT template complete.
- [ ] DESIGN_REPORT template complete.
- [ ] BUILD_REPORT template complete.
- [ ] VALIDATION_REPORT template complete.
- [ ] UX_REPORT template complete.
- [ ] RELEASE_REPORT template complete.
- [ ] VERSION_RELEASE_SCHEDULE_REPORT template complete.

## Runbook Integrity
- [ ] `dev_cycle.md` references correct file names.
- [ ] Stage order is exactly Plan -> Design -> Build -> Validate -> UX -> Review -> Release.
- [ ] No stage-skipping path exists.
- [ ] No self-approval path exists.
- [ ] Bootstrap-first planning policy is explicit.
- [ ] Grain and translation declarations are required for each stage artifact.
- [ ] Ontological assumptions are required for each stage artifact.
- [ ] PDI endpoint pipelines require SQL-01 sandbox evidence before release.

## Gate Ownership
- [ ] All approval gates are mapped to agent roles (business_manager, planner, end_user).
- [ ] No gate defaults to human approval outside defined escalation states.
- [ ] `BLOCKED_FOR_OWNER` escalation state is explicitly handled in runbook and agents.
- [ ] `HUMAN_APPROVAL_REQUIRED` escalation state is explicitly handled in runbook and agents.
- [ ] Each approving agent emits a deterministic decision: APPROVED / REJECTED / GO / NO-GO / BLOCKED_FOR_OWNER.
- [ ] Orchestration routes APPROVED/GO to next stage, REJECTED/NO-GO to rework loop, escalation states to human.
- [ ] `PLANNING_SAFE` routines auto-advance through planner and business_manager gates without human approval prompts.
- [ ] `PLANNING_SAFE` routines surface final planning artifacts and decisions when complete.
- [ ] `PLANNING_SAFE` classification does not permit code, SQL, scripts, jobs, or runtime behavior changes.
- [ ] Full-cycle routines do not request human handoff approvals between stages.
- [ ] Full-cycle routines surface one final package for human operator approval.
- [ ] Training runs require `TRAINING_OUTPUT_ROOT` from operator.

## Skill Candidate Hygiene
- [ ] Skill-state guidance is referenced from `agent-control/primitives-index/skills/README.md`.
- [ ] Stage outputs include deterministic `Skill Opportunity Review` sidecar blocks.
- [ ] Candidate recommendations are advisory only unless explicitly approved for registry mutation.

## Contract Integrity
- [ ] No undefined artifacts are referenced.
- [ ] No mixed responsibilities across roles.
- [ ] Business Manager veto authority is explicit.
- [ ] End User veto authority is explicit.
- [ ] RELEASE_REPORT and VERSION_RELEASE_SCHEDULE_REPORT are both produced in Ops stage.

## Scope Boundary
- [ ] No UI/app build work defined.
- [ ] No DB object changes defined by this framework.
