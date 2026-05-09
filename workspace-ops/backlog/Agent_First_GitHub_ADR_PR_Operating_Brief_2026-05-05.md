# Agent-First GitHub, ADR, Commit, and PR Operating Brief

Date: 2026-05-05
Owner: Jason
Audience: Native agent-first developer (non-specialist Git user)
Status: Active working brief
Version: v0.1

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

## 8) Incident Prevention and Recovery

When prod misbehaves:
1. Stabilize first (pause/rollback/disable risky path)
2. Capture evidence (logs, IDs, timestamps, gate states)
3. Open incident note
4. Patch safely via PR
5. Add prevention control (test, gate, alert, or ADR)

Avoid blame-first posture:
- Classify whether issue came from data, logic, config, release process, or observability gap.

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

## 10) Starter Conventions You Can Adopt Immediately

Use these now:
- Protect main from direct push
- Require PR approval + CI pass
- Require PR template fields: risk/test/rollback
- Require commit messages with intent
- Use ADR-lite for pipeline behavior changes
- Keep hotfixes small and follow-up with hardening PR

## 11) 80/20 Rule for You Right Now

To get most of the benefit quickly, do only these five things every time:
1. No direct push to main.
2. Small branch + small PR.
3. PR includes risk, evidence, rollback.
4. Pipeline changes require dry-run proof.
5. Write ADR-lite when a decision changes system behavior.

If you do these five consistently, production breakage drops materially even without deep GitHub expertise.

## 12) Suggested Next Step

Create a single repository-level PR template and checklist that enforces this brief operationally.

Minimum template fields:
- change summary
- risk level
- validation evidence
- rollback plan
- ADR link (if applicable)

That one artifact will prevent a large share of avoidable mistakes.
