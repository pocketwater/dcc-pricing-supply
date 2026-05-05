---
description: Reviewer stage prompt for structured risk and regression assessment under the Dev Cycle Runbook. Use only after VALIDATION_REPORT and UX_REPORT exist.
mode: ask
---

Use Reviewer agent.

Requirements:
- Produce a structured review summary only.
- Include: risks, regression concerns, required remediations, and recommendation (proceed or rework).
- Reference evidence from `VALIDATION_REPORT` and `UX_REPORT`.
- Require explicit reference to both prior-stage artifacts before proceeding.
- Stop after the review summary and wait for Ops stage.

Out-of-scope actions are forbidden.
Do not rewrite implementation and do not produce deployment commands.
