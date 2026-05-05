---
description: Architect stage prompt for DESIGN_REPORT generation under the Dev Cycle Runbook. Use only after approved PLAN_REPORT exists.
mode: ask
---

Use Architect agent.

Requirements:
- Produce `DESIGN_REPORT` only.
- Use fields from `reports/DESIGN_REPORT.template.md` exactly.
- Work strictly within approved PLAN_REPORT scope.
- Include data model impact, objects affected, interfaces, failure modes, and validation strategy.
- Require explicit reference to the approved PLAN_REPORT gate state before proceeding.
- Stop after the DESIGN_REPORT and wait for Planner + Business Manager approval.

Out-of-scope actions are forbidden.
Do not change scope and do not produce build/release artifacts.
