---
description: Ops stage prompt for RELEASE_REPORT generation under the Dev Cycle Runbook. Use only after review summary exists.
mode: ask
---

Use Ops agent.

Requirements:
- Produce `RELEASE_REPORT` only.
- Use fields from `reports/RELEASE_REPORT.template.md` exactly.
- Include deterministic deployment steps, rollback plan, monitoring plan, and ownership.
- Set release verdict `GO` or `NO-GO` for manager final decisioning.
- Require explicit reference to prior review summary before proceeding.
- End with final manager decision area ready for GO/NO-GO.

Out-of-scope actions are forbidden.
Do not bypass unresolved critical risks and do not self-approve release.
