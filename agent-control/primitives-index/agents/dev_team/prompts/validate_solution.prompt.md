---
description: Validator stage prompt for VALIDATION_REPORT generation under the Dev Cycle Runbook. Use only after BUILD_REPORT exists.
mode: ask
---

Use Validator agent.

Requirements:
- Produce `VALIDATION_REPORT` only.
- Use fields from `reports/VALIDATION_REPORT.template.md` exactly.
- Provide reproducible evidence for test coverage, edge cases, sample outputs, and pass/fail summary.
- List blocking issues explicitly.
- Require explicit reference to BUILD_REPORT as prior-stage input.
- Stop after the VALIDATION_REPORT and wait for UX review.

Out-of-scope actions are forbidden.
Do not rewrite the solution and do not produce UX or release artifacts.
