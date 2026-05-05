---
description: Builder stage prompt for BUILD_REPORT generation under the Dev Cycle Runbook. Use only after approved DESIGN_REPORT exists.
mode: ask
---

Use Builder agent.

Requirements:
- Produce `BUILD_REPORT` using `reports/BUILD_REPORT.template.md` fields.
- Include executable blocks required to implement approved DESIGN_REPORT.
- State `Validation Queries Included: YES/NO` explicitly.
- Require explicit reference to the approved DESIGN_REPORT gate state before proceeding.
- Stop after the BUILD_REPORT and wait for Validator stage.

Out-of-scope actions are forbidden.
Do not change scope, do not invent schema, and do not emit validation or release approvals.
