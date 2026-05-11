# Agent-First GitHub, ADR, Commit, and PR Operating Brief

Date: 2026-05-10
Owner: Jason
Audience: Native agent-first developer (non-specialist Git user)
Status: Active working brief
Version: v0.2

## Executive Summary

You do not need to become a GitHub expert to stop production breakage.
You need a small number of hard rules applied every time.

This brief gives a minimum operating system for:
- GitHub flow
- ADRs (Architecture Decision Records)
- Commits
- Pull Requests
- Pipeline and release safety

Primary goal:
- Ship faster with fewer production incidents while pipeline work is changing.

Secondary goal:
- Remove dependence on memory and discipline alone by turning rules into enforceable controls.

## 1) The One-Screen Mental Model

Use this model for every change:
1. Decide what is changing and why (ADR-lite if needed).
2. Isolate change in a branch.
3. Make small, testable commits.
4. Open PR with explicit risk and rollback.
5. Merge only when checks pass.
6. Release with a gate and watch telemetry.
7. If unstable, rollback fast.

If any step is skipped, risk goes up sharply.

## 1A) What Changes in v0.2

This version turns guidance into an operating contract with three enforcement layers:
1. Workspace contract (policy and required artifacts)
2. GitHub controls (branch protection and required checks)
3. Agent behavior contract (required planning and risk outputs before merge readiness)

Design intent:
- If human discipline fails, GitHub checks block unsafe merges.
- If checks are incomplete, agent output still requires explicit risk/evidence/rollback.

## 2) Minimum GitHub Workflow (No SME Required)

Default branch policy:
- main is always releasable.
- No direct pushes to main.
- All changes go through PR.

Branch naming (keep simple):
- feat/<short-description>
- fix/<short-description>
- docs/<short-description>
- hotfix/<short-description>

Branch lifespan:
- Keep branches short-lived (hours to a few days).
- Rebase or sync frequently to avoid giant merge conflicts.

Rule:
- Small PRs merged often are safer than large PRs merged rarely.

Required branch hygiene:
- Branch objective must be explicit before first meaningful commit.
- Branch must stay single-concern (do not mix unrelated fixes).
- If a branch exceeds a reviewable PR size, split before merge.

## 3) Commits: What Good Looks Like

Commit purpose:
- A commit should represent one coherent intent.

Good commit traits:
- Small enough to review quickly.
- Passes local checks.
- Message explains intent, not only files changed.

Suggested format:
- First line: imperative summary.
- Body: why, risk, and operational note if relevant.

Example pattern:
- Add deterministic gate for stage-2 upload validation
- Why: prevent false PASS before upload completes
- Risk: low, validation path only

Commit anti-patterns:
- "misc updates"
- One commit changing many unrelated concerns
- Mixing refactor + behavior change + config change in one commit

Commit quality gate:
- If commit intent cannot be summarized in one sentence with a clear why, it is not ready.

## 4) PRs: Your Main Safety Barrier

A PR is not paperwork. It is a production safety device.

PR must include:
- What changed
- Why it changed
- Risk level (low/medium/high)
- Test evidence
- Rollback plan
- Release notes impact (yes/no)

PR size guideline:
- Target reviewable PRs (roughly 50-400 lines changed depending on complexity).
- If too large, split by concern.

Required checks before merge:
- CI pipeline passes
- Required tests pass
- At least one reviewer approval
- No unresolved comments

For high-risk changes:
- Require two reviewers or one domain owner + one implementer review.

Mandatory PR artifacts:
- Risk statement (low/medium/high + one sentence rationale)
- Validation evidence (commands, logs, screenshots, or query output references)
- Rollback path (exact command/procedure or documented reversal steps)
- Release impact (yes/no + short note)
- ADR reference (required when behavior, contract, architecture, or rollback strategy changes)

## 5) ADRs: Use Them Lightly But Consistently

You do not need heavyweight architecture documentation for every change.
Use ADRs for decisions that affect future behavior.

Create an ADR when:
- Choosing between multiple architecture options
- Changing data contracts or pipeline gating behavior
- Introducing a new dependency or runtime pattern
- Changing rollback or release strategy

ADR minimum template:
1. Context
2. Decision
3. Alternatives considered
4. Consequences
5. Rollback/exit path

ADR rule:
- If the team keeps re-debating the same decision, you needed an ADR.

ADR trigger test:
- If this change alters future decisions by anyone besides the current implementer, write an ADR.

## 6) Pipeline Safety Rules (Most Important for Your Current Pain)

Non-negotiable pipeline controls:
- No pipeline changes merged without evidence of dry-run or sandbox validation.
- Stage gates must be explicit and machine-checkable.
- Blocking reasons must be deterministic and named.
- Warning budgets must be defined before release.

Progressive release strategy:
1. Dev/sandbox pass
2. Limited scope run (small data window)
3. Full run with monitoring
4. Promote only if gates pass and warning budget is within threshold

Never do:
- "Looks fine" merges on pipeline code without run evidence
- Hidden gate logic in ad-hoc scripts with no contract note
- Memory-only ops decisions not written in artifact/runbook

Pipeline risk escalation:
- Any production-adjacent pipeline change defaults to medium risk unless proven low.
- Any gate logic change defaults to high risk until dry-run evidence is attached.

## 7) Environments and Release Discipline

Keep three mental environments:
- Dev: break allowed
- Staging/Test: break expected but contained
- Production: break not acceptable

Release checklist (minimum):
- Migration/config impact identified
- Backward compatibility checked
- Monitoring query ready before deploy
- Rollback command/path tested or documented

If rollback is unclear, release is not ready.

Operational rule:
- Monitoring query (or dashboard link) must be prepared before release, not after.

## 8) Incident Prevention and Recovery

When prod misbehaves:
1. Stabilize first (pause/rollback/disable risky path)
2. Capture evidence (logs, IDs, timestamps, gate states)
3. Open incident note
4. Patch safely via PR
5. Add prevention control (test, gate, alert, or ADR)

Avoid blame-first posture:
- Classify whether issue came from data, logic, config, release process, or observability gap.

Prevention closure rule:
- Incident is not complete until one preventive control is added (test, check, alert, gate, or ADR update).

## 9) Practical Defaults for an Agent-First Developer

Daily defaults:
- Start with branch + explicit objective.
- Make small commits every meaningful step.
- Run local checks before push.
- Open draft PR early for visibility.
- Convert to ready only with evidence + rollback note.

Weekly hygiene:
- Close stale branches.
- Review failed deployments and add one preventive control each week.
- Consolidate repeated lessons into runbook/ADR.

Agent collaboration default:
- Ask agent to produce:
  - commit plan
  - PR summary
  - risk assessment
  - rollback steps
- You approve before merge.

Agent output minimum before "ready to merge":
- Proposed commit set (small, reviewable, intent-labeled)
- PR summary in business language
- Risk level with rationale
- Validation evidence checklist
- Rollback procedure and trigger condition

## 10) Starter Conventions You Can Adopt Immediately

Use these now:
- Protect main from direct push
- Require PR approval + CI pass
- Require PR template fields: risk/test/rollback
- Require commit messages with intent
- Use ADR-lite for pipeline behavior changes
- Keep hotfixes small and follow-up with hardening PR

Add now:
- Require conversation resolution before merge (no unresolved comments)
- Require deterministic blocker names for pipeline validation failures

## 11) 80/20 Rule for You Right Now

To get most of the benefit quickly, do only these five things every time:
1. No direct push to main.
2. Small branch + small PR.
3. PR includes risk, evidence, rollback.
4. Pipeline changes require dry-run proof.
5. Write ADR-lite when a decision changes system behavior.

If you do these five consistently, production breakage drops materially even without deep GitHub expertise.

## 11A) Enforcement Model (Contract + Platform + Agent)

### Layer 1: Workspace Contract (Policy)
- This brief is the behavioral policy baseline.
- Deviations are allowed only with explicit exception note in PR.
- Exception note must include reason, risk, and expiration date.

### Layer 2: GitHub Platform Controls (Hard Gate)
- Protected `main` branch.
- No direct push.
- Required PR review(s).
- Required status checks.
- Dismiss stale approvals on new commits.
- Block merge when required PR fields are missing.

### Layer 3: Agent Behavior Contract (Pre-Merge Discipline)
- Agent must not recommend merge readiness without risk/evidence/rollback.
- Agent must flag ADR-required changes when applicable.
- Agent must propose smallest viable PR split if scope is too broad.

## 11B) Ownership Matrix

- Jason (operator): final merge decision, exception approval, release go/no-go.
- Agent (implementation copilot): pre-merge planning package and risk discipline.
- GitHub policies: enforce non-bypassable merge controls.
- Reviewer(s): validate correctness, risk, and rollback realism.

## 11C) Merge Readiness Definition

A PR is merge-ready only when all are true:
1. Required checks pass.
2. Required review approvals are present.
3. Risk, evidence, rollback, and release impact are explicitly filled.
4. ADR link exists when ADR-trigger conditions are met.
5. No unresolved review comments remain.

If any item is false, PR remains draft or blocked.

## 11D) Exception Path (When You Must Move Fast)

Use only for urgent production stabilization.

Required minimum:
1. Mark PR as exception/hotfix.
2. Include explicit residual risk.
3. Include immediate rollback path.
4. Open follow-up hardening task before merge.
5. Complete hardening PR within agreed timebox.

No exception may skip rollback documentation.

## 12) Implementation Plan (30-Day Rollout)

### Phase 1 (Day 1-3): Baseline Controls
- Enable branch protection for `main`.
- Require PR approval and CI pass.
- Publish PR template with mandatory fields.
- Start using this brief as required review criteria.

Success signal:
- Zero direct pushes to `main`.
- 100% of merged PRs include risk/evidence/rollback.

### Phase 2 (Day 4-14): Enforcement Tightening
- Add status check that fails when required PR sections are empty.
- Add high-risk reviewer rule (second reviewer or domain owner).
- Normalize commit intent format across active repos.

Success signal:
- High-risk PRs show elevated review depth.
- Fewer review cycles caused by missing operational details.

### Phase 3 (Day 15-30): Agent + Process Hardening
- Add explicit agent pre-merge contract to workspace instructions.
- Require ADR links for architecture/contract/gate/rollback strategy changes.
- Run weekly review of incidents and control gaps.

Success signal:
- Fewer production regressions from process misses.
- Faster, cleaner PR reviews with predictable artifacts.

## 13) Scorecard (Simple Weekly Metrics)

Track weekly:
- PR compliance rate (% with full required fields)
- Avg PR size (lines changed)
- High-risk PR reviewer compliance (% meeting rule)
- Incidents caused by release/process gaps (count)
- Rollback readiness compliance (% PRs with executable rollback)

Target trend:
- Compliance up, process-caused incidents down.

## 14) Immediate Action Checklist

Execute now:
1. Protect `main` and disable direct push.
2. Add required PR template fields.
3. Define high-risk label/rule.
4. Add exception/hotfix path language.
5. Add agent pre-merge output contract in instructions.

This sequence creates immediate safety with minimal overhead.

## 15) Suggested Next Step

Create and enforce a repository-level PR template + required checks package that operationalizes this brief.

Minimum template fields:
- change summary
- risk level
- validation evidence
- rollback plan
- ADR link (if applicable)

That one artifact will prevent a large share of avoidable mistakes.

## 16) Recommended Next Artifact Set

1. PR template (required fields + merge checklist)
2. ADR-lite template (5-section minimum)
3. Hotfix exception template (risk + rollback + hardening follow-up)
4. Agent instruction update (pre-merge required outputs)

These artifacts convert policy into repeatable behavior.
