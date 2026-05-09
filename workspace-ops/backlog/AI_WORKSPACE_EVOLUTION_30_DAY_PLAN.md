# AI Workspace Evolution Plan (30 Days)

## Objective
Stabilize the AI-enriched workspace control plane first, then add a thin operator CLI on top of stable contracts.

## Guiding Principle
CLI is an interface layer, not the foundation. Build contracts, runtime behavior, telemetry, and evaluation before expanding command surface area.

---

## Week 1 - Canonical Contracts and Governance Gates

### Outcomes
- Canonical primitives and policy contracts are explicit and enforceable.
- Registry drift and duplicate-entry risk are reduced.

### Deliverables
- Primitive contract definitions for:
  - prompt classification triage
  - minimum skill definition gate
  - duplicate-prevention comparison gate
  - promotion/deprecation decision record
- Naming and schema validation rules for skill registry entries.
- Source-of-truth guardrail: YAML canonical, Markdown projection-only.

### Exit Criteria
- Every new candidate entry passes a consistent validation checklist.
- Registry changes can be reviewed with clear rationale fields.

---

## Week 2 - Runtime Control Plane (Thin Orchestration Kernel)

### Outcomes
- Deterministic execution path for core registry operations.
- Agent actions map to repeatable workflows rather than ad hoc edits.

### Deliverables
- Small orchestration layer for core operations:
  - classify prompt (existing/new/one-off)
  - append/update candidate
  - refresh projection
  - lifecycle status change with rationale
- Stable input/output contract for each operation.
- Fail-safe behavior for ambiguous inputs (defer to note/closest skill path).

### Exit Criteria
- Core operations execute the same way every time for the same input.
- Manual edits become exception path, not default path.

---

## Week 3 - Observability and Evaluation Harness

### Outcomes
- Decision quality and drift become measurable.
- Promotion decisions have evidence, not memory.

### Deliverables
- Event log for:
  - classification decisions
  - registry mutations
  - projection refresh operations
  - lifecycle transitions
- Friction log (ambiguity, fallback path, unresolved semantics).
- Golden prompt evaluation set for regression checks:
  - classification correctness
  - duplicate handling
  - conservative bias behavior

### Exit Criteria
- You can answer: what changed, why, and where quality regressed.
- Candidate-to-active decisions have reusable evidence artifacts.

---

## Week 4 - Operator CLI (Thin Shell)

### Outcomes
- Fast operator workflows without bypassing governance.
- CLI drives existing contracts rather than inventing new behavior.

### Deliverables
- Minimal command set:
  - classify
  - harvest
  - promote
  - deprecate
  - diff
  - audit
  - sync-projection
- Command output includes rationale and artifact paths.
- Safety defaults preserve conservative bias and non-destructive behavior.

### Exit Criteria
- CLI reduces manual effort but does not weaken policy gates.
- Operators can run daily workflows with traceable outcomes.

---

## Cross-Cutting Guardrails
- Prefer updating existing skills over creating near-duplicates.
- Do not promote candidate entries without explicit evidence.
- Keep cognitive-friction artifacts separate from operational skill artifacts.
- Keep source-of-truth single and projection deterministic.

## Suggested First Implementation Slice (48-72 hours)
1. Define validation checklist + naming rule enforcement.
2. Implement classify -> update registry -> refresh projection pipeline.
3. Add mutation/event log with concise rationale fields.
4. Build a first golden prompt set from recent real prompts.

## Success Signal at Day 30
You have a reliable control plane with measurable decision quality, and a thin CLI that accelerates operations without introducing semantic drift.
