# Business Infra Sandtraps and Workspace Evidence Map

This document defines recurring infra/data-pattern risks and anchors each one to at least one concrete workspace example.

## Schema Drift
When data structure changes in one system are not synchronized across others, pipelines break and outputs drift.

Smell:
"A field changed upstream and downstream logic started failing."

Workspace example:
- Export failed on missing clone object: `Invalid object name 'dbo.PDI_Site_Tank_Dates_Clone'` in run evidence.
- `ontology.md` also tracks remaining clone debt as active "pipeline gremlins".

Evidence:
- `pers-ops-jvassar/inbox/concepts/chat.from-run-5-7-orders.json` (line ~315)
- `csl-pricing-supply/semantic-index/ontology.md` (line ~139)

---

## Tech Debt
Short-term engineering decisions accumulate into long-term fragility and slower delivery.

Smell:
"We keep patching around the same weak spot."

Workspace example:
- Workspace ontology explicitly codifies `DTBG` (Duct Tape and Bubble Gum) as tech debt.

Evidence:
- `csl-pricing-supply/semantic-index/ontology.md` (line ~165)

---

## State Spread
Multiple systems hold competing versions of truth, making reasoning and reconciliation hard.

Smell:
"Which system is right this time?"

Workspace example:
- Explicit callout: "state spread and truth puddles all over the place" in architecture notes.

Evidence:
- `pers-ops-jvassar/inbox/system_architecture_chat_insights.md` (line ~233)

---

## Hidden Logic
Critical rules are embedded in ad-hoc scripts or scattered implementation surfaces rather than governed contracts.

Smell:
"Nobody can point to the canonical rule location."

Workspace example:
- Explicit anti-pattern in ops brief: hidden gate logic in ad-hoc scripts with no contract note.

Evidence:
- `dcc-pricing-supply/workspace-ops/backlog/Agent_First_GitHub_ADR_PR_Operating_Brief_2026-05-05.md` (line ~143)

---

## Orphaned Pipelines
Records or process artifacts continue without successful lifecycle completion.

Smell:
"It ran, but a chunk is now stranded."

Workspace example:
- ORPHAN CHECK warns that 37 unmatched ARNs have no PDI order and remain orphaned unless re-imported.

Evidence:
- `pers-ops-jvassar/inbox/concepts/chat.from-run-5-7-orders.json` (line ~702)

---

## Silent Failures
Data drops or partial failures do not surface as deterministic blockers.

Smell:
"No error was raised, but rows are missing."

Workspace example:
- Missing map entries can silently exclude rows from publish/coverage instead of explicit BLOCK output.

Evidence:
- `csl-pricing-supply/playbooks/WORKSPACE_GRAIN_MAP.md` (lines ~60, ~145, ~163)

---

## Duplicate Logic
Same rule/transformation is defined in multiple places, creating drift and inconsistent fixes.

Smell:
"We fixed one copy, not the others."

Workspace example:
- Architecture insights explicitly call out duplicate artifacts and exploratory drift diluting canonical guidance.

Evidence:
- `pers-ops-jvassar/inbox/system_architecture_chat_insights.md` (line ~144)

---

## Grain Misalignment
Rows are joined or compared at incompatible granularity.

Smell:
"Totals look fine, row truth does not."

Workspace example:
- Gravitate grain is explicitly locked to one row per Dispatch + Customer + Location + Delivery hour window.

Evidence:
- `csl-pricing-supply/playbooks/WORKSPACE_GRAIN_MAP.md` (line ~109)

---

## Overloaded Tables
A single table/surface is expected to satisfy too many roles, often reflected by dead/null-heavy columns and brittle ownership.

Smell:
"This object does everything and nobody wants to touch it."

Workspace example:
- Backlog item for a schema scrubber to identify null-heavy columns in large tables and prune dead logic.

Evidence:
- `pers-ops-jvassar/inbox/# sqwibbles.md` (line ~14)

---

## Leaky Abstractions
Implementation artifacts leak into business-facing logic (composite strings, proxy identifiers, transport-specific encodings).

Smell:
"Users see system internals instead of domain fields."

Workspace example:
- ODE notes call out `Customer_ID` as concatenated vendor text requiring split/cleanup to derive true `Cust_ID`.

Evidence:
- `pers-ops-jvassar/inbox/systems/_proposed/ODE.md` (line ~28)

---

## Versionless Changes
Logic/schema/output mutations happen without durable version trace or canonical source discipline.

Smell:
"When did this change, and why?"

Workspace example:
- Discussion calls out "unversioned excel sheets" and fragmented reasoning.
- Governance brief introduces YAML-as-source-of-truth to prevent projection drift edits.

Evidence:
- `pers-ops-jvassar/inbox/System Architecture Chat records/Tranche 2/sys68` (lines ~632, ~863)
- `pers-ops-jvassar/inbox/briefs/Pete_Agent_Control_Model_Brief_2026-05-02.md` (line ~16)

---

## Human Dependency
Critical process continuity depends on specific operators and manual confirmations.

Smell:
"If one person is out, the pipeline stalls."

Workspace example:
- Runbook explicitly includes detailed procedures for human operators.
- Post-import gate cannot be bypassed by automation.

Evidence:
- `csl-pricing-supply/playbooks/gravitate-orders-toc.md` (line ~7)
- `gravitate-orders/OPERATOR_ONBOARDING_PLAYBOOK.md` (line ~162)

---

## Backfill Blindness
Forward flow works, but historical recompute requires special handling or hacks.

Smell:
"Current month works; historical rebuild is painful."

Workspace example:
- Coverage snap procedure explicitly documents a backfill path (`@AsOfDate`) for prior month recompute.

Evidence:
- `gravitate-orders/artifacts/sql/sp_Gravitate_Coverage_SNAP.sql` (line ~19)

---

## Validation Gaps
Quality checks are absent, delayed, or not instrumented enough to catch risk early.

Smell:
"We found out only after downstream impact."

Workspace example:
- Architecture notes call out lagging validation/evaluation cadence.
- Audit notes report no audit-relevant settings enabled (no persistent instrumentation at that time).

Evidence:
- `pers-ops-jvassar/inbox/system_architecture_chat_insights.md` (line ~145)
- `dcc-pricing-supply/agent-control/audits/pete-instruction-audit-2026-05-07.md` (line ~61)

---

## Over-Automation
Automation is introduced without sufficient observability, control gates, or human-safe checkpoints.

Smell:
"It is automated, but trust is low and rollback is unclear."

Workspace example:
- Governance brief requires manual-only registry sync (no always-on automation).
- Operator onboarding states gate cannot be bypassed by automation while also tracking planned unattended automation rollout.

Evidence:
- `pers-ops-jvassar/inbox/briefs/Pete_Agent_Control_Model_Brief_2026-05-02.md` (line ~84)
- `gravitate-orders/OPERATOR_ONBOARDING_PLAYBOOK.md` (lines ~162, ~391)
