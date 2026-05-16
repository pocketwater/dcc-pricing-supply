# Saturday Execution Run Sheet: CitySV-Costs Runtime Migration (SQL-02)

Execution window
- Date: 2026-05-16 (Saturday)
- Database: PDI_PricingLink on PDI-SQL-02
- Change type: approval-gated production migration
- Objective: migrate citysv-costs runtime translation dependencies from legacy CITT surfaces to canonical/resolved surfaces with rollback-first safety

Operator guardrails
- Do not execute outside approved low-impact window.
- Do not proceed if prechecks fail.
- Stop immediately on first runtime error and execute rollback.
- No legacy freeze/deprecate actions in this window.

Pre-window checklist
1. Confirm on-call and approver availability.
2. Confirm latest backup/snapshot availability for PDI_PricingLink.
3. Confirm no in-progress high-impact jobs for citysv-costs pipeline.
4. Confirm rollback script location and write permissions.
5. Confirm evidence output path is writable.

Step 1: Baseline capture (read-only)
- Run validation/CAPTURE_CITYSV_COSTS_RUNTIME_DEFS_SQL02.domain_translation_hardening.v0.2.sql
- Save output to evidence file:
  evidence/citysv-costs-runtime-defs-prechange-sql02.txt

Step 2: Baseline dependency state (read-only)
- Run validation/VALIDATE_CITYSV_COSTS_RUNTIME_DEPENDENCY_SQL02.domain_translation_hardening.v0.2.sql
- Save output to evidence file:
  evidence/citysv-costs-runtime-deps-prechange-sql02.txt

Step 3: Execute approved migration script pack (change step)
- Execute only the approved citysv-costs migration scripts for this window.
- Record exact execution order and start/end UTC for each script.
- Save output to evidence file:
  evidence/citysv-costs-migration-exec-sql02.txt

Stop conditions (hard)
- Any script error (severity >= 11)
- Any object compile failure
- Any missing object required by migration pack
- Any unexpected dependency expansion beyond approved target objects

Rollback trigger
- Trigger rollback if any stop condition is hit.
- Trigger rollback if postchecks fail on required parity or dependency expectations.

Step 4: Post-change validation (read-only)
- Re-run validation/VALIDATE_CITYSV_COSTS_RUNTIME_DEPENDENCY_SQL02.domain_translation_hardening.v0.2.sql
- Save output to evidence file:
  evidence/citysv-costs-runtime-deps-postchange-sql02.txt

Step 5: Post-change runtime sanity checks
- Execute agreed sanity query set for citysv-costs pipeline.
- Confirm no blocking regression signals.
- Save output to evidence file:
  evidence/citysv-costs-runtime-sanity-postchange-sql02.txt

Success criteria
1. Target runtime objects compile and execute.
2. Dependency profile matches approved migration intent.
3. No critical runtime errors in immediate post-window checks.
4. Evidence pack complete and attached to v0.2 artifacts.

Failure handling
1. Execute rollback immediately.
2. Re-run dependency validation after rollback.
3. Record failure summary and decision notes in evidence.

Required evidence files for window close
- evidence/citysv-costs-runtime-defs-prechange-sql02.txt
- evidence/citysv-costs-runtime-deps-prechange-sql02.txt
- evidence/citysv-costs-migration-exec-sql02.txt
- evidence/citysv-costs-runtime-deps-postchange-sql02.txt
- evidence/citysv-costs-runtime-sanity-postchange-sql02.txt
- evidence/citysv-costs-window-decision-summary-2026-05-16.txt

Decision authority
- Operator approval required to start execution step.
- If uncertainty appears during window, halt and request operator resolution.
