# SOCKS v0 Design Draft

**Status:** Review draft
**Source basis:** SOCKS_project_exploration_cleaned_transcript_2026-04-27.md
**Purpose:** Define the smallest credible v0 for review before implementation.

---

## 1. Product Statement

SOCKS v0 is a local-first attention scheduler. It turns captured inventory into two durable execution outputs:

- a daily pack with one protected primary objective and exactly five latency-safe tasks
- a guided weekly review that re-tiers work and generates the next week’s structure

v0 is not a general task manager, and it is not an autonomous assistant.

---

## 2. Design Principles

- Keep the core append-only and rebuildable.
- Use explicit triggers and human judgment instead of silent capture.
- Separate inventory from active WIP.
- Keep latency work low-load, already-scoped, and emotionally neutral.
- Favor proposal-first behavior over automatic mutation.

---

## 3. v0 Scope

### Included

- Workspace-local JSONL storage for captured items and events.
- A canonical item/event model with stable metadata.
- A daily pack generator.
- A weekly review generator.
- A thin VS Code review/capture surface.

### Excluded

- Microsoft Graph integrations.
- Mobile, CLI, or daemon surfaces.
- Autonomous write actions.
- Broad semantic parsing of arbitrary prose.
- Anything that turns v0 into a full task-management suite.

---

## 4. Canonical Data Model

The core unit is an append-only item/event record. Projections are derived from stored events.

### Required metadata

- createdAt
- updatedAt
- source surface
- workspace / repo / file / line when available
- git branch when available
- tags / context
- classification state
- closeout notes when completed

### Required states

- Inbox
- Clarify
- Next
- Waiting
- Scheduled
- Blocked
- Someday
- Reference
- Done

---

## 5. Classification Rules

The transcript converged on three classifier dimensions:

- clarity
- motivation / resistance
- cognitive load

These dimensions determine whether an item belongs in inventory, backlog, active WIP, or the latency pack.

### Latency eligibility

Latency tasks must be:

- already understood
- already scoped
- emotionally neutral
- low enough load to stop and resume quickly

Latency tasks must not:

- require clarification
- introduce new projects
- carry ambiguity
- depend on motivation priming

---

## 6. Daily Pack

The daily pack is the primary user-facing v0 output.

### Contents

1. Calendar commitments
2. One primary objective
3. Protected block intent
4. Exactly five latency tasks

### Behavioral rules

- The primary block is protected, not opportunistic.
- Latency tasks persist until completed.
- Refill happens only when a latency task is completed or invalidated.
- The pack must remain finite.

---

## 7. Weekly Review

The weekly review is a guided ritual, not a blank page.

### Review questions

1. What changed?
2. What demand state are we in?
3. What is active?
4. What is due?
5. What is blocked?
6. What deserves deep work?
7. What gets ignored on purpose?
8. What blocks get generated next?

### Review output

- Re-tiered work inventory
- Next-week block structure
- Updated daily-pack inputs

---

## 8. First Implementation Surface

The first visible surface should be a thin VS Code loop backed by workspace-local JSONL.

Rationale:

- It makes capture immediate.
- It keeps the system close to the editor where the work already happens.
- It avoids premature investment in broader surfaces before the core loop is stable.

The extension should be a surface, not the brain.

---

## 9. v0 Build Order

1. Canonical data model and projections.
2. Daily pack generator.
3. Weekly review generator.
4. Minimal capture and review loop in VS Code.

Integration work comes after the local loop proves stable.

---

## 10. Success Criteria

v0 is useful if it can do all of the following:

- Generate a daily pack in under 60 seconds from existing inventory.
- Keep exactly five latency tasks available.
- Protect the primary block from accidental dilution.
- Re-tier next week in one guided review pass.
- Rebuild projections from the append-only log.

---

## 11. Open Decisions for Review

- Should the first visible UI be a VS Code panel, a markdown-driven flow, or both?
- Should capture begin with explicit triggers like `//todo` and `//wait`, or with a broader inbox?
- Should calendar blocks be proposed only, or also written back with confirmation?

---

## 12. Source Notes

- Canonical concept transcript: `SOCKS_project_exploration_cleaned_transcript_2026-04-27.md`
- Business rules and ontology: `csl-pricing-supply/semantic-index/ontology.md`
- Behavioral constraints: `csl-pricing-supply/semantic-index/deontology.md`
