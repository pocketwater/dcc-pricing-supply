# Open Source Orchestration Brief (Gravitate Orders)

Date: 2026-05-09
Owner: Jason / Pete
Scope: Evaluate safe open source orchestration platforms for complex gravitate-orders pipeline operations.

## Executive Summary
For current pipeline shape (SQL Agent + PowerShell + Python + SQL validation views), the best pilot candidate is Dagster.
Airflow remains the strongest fallback if ecosystem breadth and in-house familiarity become primary requirements.

Recommended path:
1. Pilot with Dagster in shadow mode (no immediate logic rewrite).
2. Keep SQL Agent as rollback path during pilot.
3. Cut over only after deterministic parity and operational SLO targets are met.

## Candidate Shortlist

### 1) Dagster (Apache 2.0)
Why it fits:
- Strong data/asset model maps well to staged pipeline outputs.
- Good observability and lineage for run-by-run reconciliation.
- Practical for Python-first orchestration while wrapping existing SQL and PowerShell.

Tradeoffs:
- Smaller ecosystem than Airflow.
- Team needs light upskilling on assets/jobs/resources model.

### 2) Apache Airflow (Apache 2.0)
Why it fits:
- Most mature and widely adopted OSS orchestrator.
- Very large operator ecosystem.
- Strong scheduling and backfill support.

Tradeoffs:
- Heavier operations footprint.
- More orchestration boilerplate for some use cases.

### 3) Prefect OSS
Why it fits:
- Fast developer onboarding.
- Good task state and retry controls.

Tradeoffs:
- Some enterprise capabilities are outside pure OSS paths.
- Verify long-term feature boundaries before standardizing.

### 4) Temporal (MIT)
Why it fits:
- Excellent for durable long-running workflow state and recovery.

Tradeoffs:
- Better for service/workflow orchestration than traditional data scheduling.
- Higher engineering complexity for initial adoption.

## Safety and Trust Criteria (Must Pass)
1. License and governance review (Apache 2.0 or MIT preferred).
2. Active maintenance and release cadence.
3. Dependency pinning plus vulnerability scanning in CI.
4. Secrets from manager, not plaintext config.
5. Private network deployment, RBAC, least privilege identities.
6. Centralized logs, run audit trail, and alerting hooks.

## Gravitate-Orders Pilot Shape (No Big-Bang Rewrite)
Use orchestrator as a control plane over existing components first.

Pilot stages:
1. Snapshot ingest trigger.
2. Eligibility and blocker classification.
3. Renderer valid F-row checks.
4. Export artifact production.
5. Post-import verification and reconciliation.

Per-stage telemetry:
- Start and end timestamps.
- Duration.
- Input and output row counts.
- Blocker counts by deterministic code.
- Success/failure with retry outcomes.

## 30-Day Pilot Plan
1. Week 1: Foundation
- Deploy orchestrator in non-prod.
- Configure identity, secrets, logging, retries.
- Validate SQL connectivity and PowerShell execution wrapper.

2. Week 2: Stage Wrapping
- Wrap existing SQL/SP/script stages without changing business logic.
- Emit run metadata and quality checks after each stage.

3. Week 3: Shadow Parity
- Run in parallel with existing SQL Agent jobs.
- Compare row counts, blocker counts, and rendered output consistency.

4. Week 4: Controlled Slice + Gate
- Run a low-risk production slice through orchestrator-first path.
- Keep rollback switch to SQL Agent.
- Decide go/no-go using cutover criteria.

## Cutover Criteria (Go/No-Go)
1. Functional parity on critical outputs for 10 consecutive runs.
2. Success rate target >= 99 percent in pilot window.
3. MTTD <= 5 minutes, MTTR <= 30 minutes for known failure classes.
4. Complete run-level audit trail and deterministic failure reasons.
5. On-call runbook validated in at least two incident drills.

## Recommendation
Primary recommendation: Start with Dagster pilot.
Fallback: Move to Airflow only if pilot reveals ecosystem or team-fit blockers that materially affect delivery risk.

## Immediate Next Actions
1. Approve pilot orchestrator choice (Dagster vs Airflow).
2. Select one production date window for shadow run baseline.
3. Approve parity dashboard fields and alert thresholds.
4. Assign owner for pilot runbook and rollback procedure.
