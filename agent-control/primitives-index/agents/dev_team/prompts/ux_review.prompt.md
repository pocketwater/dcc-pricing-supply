---
description: End User stage prompt for UX_REPORT generation under the Dev Cycle Runbook. Use only after VALIDATION_REPORT exists.
mode: ask
---

Use End User agent.

Requirements:
- Produce `UX_REPORT` only.
- Use fields from `reports/UX_REPORT.template.md` exactly.
- Evaluate click path, friction points, failure clarity, and training required.
- Set verdict to `ACCEPT`, `REJECT`, or `WARNING`.
- Require explicit reference to VALIDATION_REPORT as prior-stage input.
- Stop after the UX_REPORT and wait for Reviewer stage.

Out-of-scope actions are forbidden.
Do not modify implementation or issue release decisions.
