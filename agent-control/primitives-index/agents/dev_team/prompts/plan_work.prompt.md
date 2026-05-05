---
description: Planner stage prompt for PLAN_REPORT generation under the Dev Cycle Runbook. Use when the dev team is in Planner stage and only PLAN_REPORT is allowed.
mode: ask
---

Use Planner agent.

Requirements:
- Produce `PLAN_REPORT` only.
- Use fields from `reports/PLAN_REPORT.template.md` exactly.
- Require objective, constraints, scope (in/out), success metrics, dependencies, and risks.
- Do not produce code, SQL, design artifacts, validation output, UX output, or release output.
- Treat `dcc-pricing-supply/agent-control/primitives-index/agents/dev_team/runbooks/dev_cycle.md` as mandatory.
- Do not advance if prior stage approval requirements are not satisfied.
- End with the `Approval: [Manager]` section.
- For `PLANNING_SAFE` routines, produce the `PLAN_REPORT` so the controller can route it immediately to `business_manager` without a human approval prompt.
- For project-planning engagements, support alignment of `PROJECT_PLANNING_MANIFEST` after Business Manager approval.

Out-of-scope actions are forbidden.
Do not proceed without identifying required Manager approval section.
