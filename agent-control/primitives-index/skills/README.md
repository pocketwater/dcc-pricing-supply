# Skills — Forge Skill Capture Registry

## What This Is

This folder is the **machine-readable source of truth** for the Forge Skill Capture system.

It contains a YAML registry of reusable operational prompt patterns ("skills") harvested from real Jason prompts during live operational work.

This is **not** a CLI, database, workflow engine, or framework. It is prompt harvesting and intent stabilization — pre-execution skill modeling only.

---

## Files

| File | Purpose |
|---|---|
| `forge_skills_registry.yaml` | **Source of truth.** All skill definitions live here. Edit this, not the Markdown. |

---

## Paired Human Projection

A derived Markdown view of this registry is maintained at:

```
csl-pricing-supply/
└─ semantic-index/
   └─ AI-primitives-registry/
      └─ forge_skills_registry.md
```

That file is intentionally lossy. If it disagrees with the YAML, **YAML wins**.

---

## Skill ID Format

```
<Domain>.<verbObject>
```

Examples: `Orders.auditDay`, `Orders.showBlockers`, `Orders.runDaily`

Use concise, human-guessable verbs. Avoid technical or implementation-specific names.

---

## Skill Lifecycle

```
candidate → active → deprecated
```

A skill stays `candidate` until it has multiple real evidence prompts or Jason explicitly blesses it.

---

## Key Rules

- **Do not increment `reuse_count`** due to agent recall or suggestion — only on independent Jason prompts.
- **Create candidate entries early** when a prompt shape appears reusable. Capture as much metadata as can be inferred quickly from the live prompt and nearby context without exhaustively mining the full chat session.
- **Do not promote a candidate to `active`** until Jason explicitly approves it.
- **If a candidate is still fuzzy, write the uncertainty down** rather than blocking capture. Use `notes` to mark open questions, missing metadata, or boundaries that still need review.
- **Do not create a duplicate** just because wording differs. Compare domain, intent, inputs, outputs, execution surface, and safety profile first.
- **YAML owns the truth.** The Markdown projection is derived and secondary.

---

## Precedence And Control Plane Governance

The DCC agent-control repository is the **primary control plane** for agent behavior, routing, skill lifecycle, and governance.

Effective precedence model:

1. Platform/system constraints
2. Session developer instructions
3. DCC (`dcc-pricing-supply/agent-control`)
4. Forge skill registry (consultation mandatory before any routing decision)
5. Explicitly invoked runbooks/prompts only
6. Personal repo (`pers-ops-jvassar`) advisory only, never first-read for routing/governance
7. Memory layers
8. Runtime context
9. User prompt (intent layer)

Behavior rules:

- Always consult `forge_skills_registry.yaml` before using any repo-level runbook or prompt.
- YAML registry is the source of truth; the CSL Markdown registry is projection only.
- If YAML and projection differ, Pete must update the projection from YAML, never the reverse.
- Explicit exception for personal-workflow tasks: when the user prompt is explicitly about Jason personal workflows, productivity system, preferences, SOCKS, planning routines, or personal operating repo content, `pers-ops-jvassar` may be consulted early as the primary content source.
- The personal-workflow exception does not override DCC governance. DCC still controls behavior, routing, skill lifecycle, and governance.

---

## Mandatory Routing Rule (Per Prompt)

On every prompt:

- `forge_skills_registry.yaml` must be consulted before any runbook, prompt, or ad-hoc reasoning is used.
- Silent bypass of the registry is not allowed.

If no skill clearly matches, classify explicitly as one of:

- `NO_MATCH`
- `PARTIAL_MATCH`
- `CANDIDATE_PATTERN`

Classification semantics:

- `NO_MATCH` means no active skill applies.
- `PARTIAL_MATCH` means an active skill may apply, but required inputs or intent boundaries are incomplete.
- `CANDIDATE_PATTERN` means repeated novel intent may deserve candidate hardening, but no candidate is created until threshold/evidence rules are met.

---

## Operational Routine: Sync registry

Command phrase: `Sync registry`

Manual invocation only. Do not run automatically on every YAML edit.

Execution contract:

1. Read YAML source of truth:
   - `dcc-pricing-supply/agent-control/primitives-index/skills/forge_skills_registry.yaml`
2. Generate Markdown projection:
   - `csl-pricing-supply/semantic-index/AI-primitives-registry/forge_skills_registry.md`
3. Projection rules:
   - Markdown is a pure projection of YAML (no projection-only logic).
   - No manual edits are allowed in the projection file.
   - Projection must summarize, at minimum, for every skill:
     - `skill_id`
     - `status`
     - trigger phrases (summary form)
     - overlap relationships (summary form)
4. Overwrite projection:
   - Replace the entire Markdown file with regenerated content.
5. Return sync output summary:
   - skills added/removed
   - status changes
   - structural differences in projection format/content shape

Governance note:

- Projection is a derived artifact.
- YAML is the only editable registry.
- Any drift must be resolved by regenerating projection, never editing projection directly.

---

## Test Protocol: Test routing against transcript

Command phrase: `Test routing against transcript`

Behavior:

1. Read a VS Code exported chat transcript.
2. Extract Jason prompts only.
3. For each prompt, classify intent first as one of:
   - `EXECUTION_INTENT`
   - `GOVERNANCE_INTENT`
   - `CONTROL_INTENT`
   - `OTHER_INTENT`
4. Apply routing eligibility by intent:
   - `EXECUTION_INTENT` is eligible for skill routing.
   - `GOVERNANCE_INTENT` -> always `NO_MATCH`.
   - `CONTROL_INTENT` -> always `NO_MATCH`.
   - `OTHER_INTENT` -> `NO_MATCH` unless future domains are explicitly defined.
5. For `EXECUTION_INTENT` prompts, consult `forge_skills_registry.yaml`.
6. Classify each prompt as one of:
   - `skill_invoked: <skill_id>`
   - `NO_MATCH`
   - `PARTIAL_MATCH: <skill_id>`
   - `CANDIDATE_PATTERN`
7. For each row, include:
   - prompt number
   - short prompt
   - intent class
   - routing outcome
   - considered skill
   - exclusion or selection reason
8. Summarize:
   - total prompts
   - intent-class counts
   - count by active skill
   - `NO_MATCH` count
   - `PARTIAL_MATCH` count
   - `CANDIDATE_PATTERN` count
   - candidate clusters, if any

Rules:

- Do not create new skills during the test.
- Do not promote skills during the test.
- Do not mutate registry during the test.
- The test is observability only.
- Classify the user's actual intent, not trigger phrases embedded in governance/spec text.
- Do not route from trigger phrases that appear inside quoted text, YAML/spec blocks, governance instructions, examples, or correction instructions about a skill.
- Control/status phrases (for example: approved, promote to active, execute, do it, proceed, next one) are never `CANDIDATE_PATTERN`.
- If a prompt is about editing, approving, promoting, reviewing, syncing, or testing the skill registry itself, classify as `NO_MATCH` unless a future `Governance.*` skill is explicitly defined.
- Critical distinction: a prompt that mentions a skill name but requests editing/approving that skill is `GOVERNANCE_INTENT`; a prompt that requests behavior execution without skill-editing intent is `EXECUTION_INTENT`.
- If a prompt names a skill and asks to review, edit, harden, promote, fix, route, classify, or update the skill/spec/registry, classify as `GOVERNANCE_INTENT` even if it contains operational words such as audit, blockers, missing, or trace.

---

## Working Instructions (Agents)

After every non-trivial Jason prompt:

1. Answer the prompt normally.
2. Classify: existing skill match / new candidate / one-off.
3. **Existing match** → increment `reuse_count`, append to `evidence_prompts` if useful, update `last_seen`, regenerate Markdown projection.
4. **New candidate** → append to YAML with `status: candidate`, capture as much metadata as is quickly available, mark any gaps in `notes`, regenerate Markdown projection.
5. **One-off** → do nothing unless the same shape reappears.
6. Do not interrupt Jason with registry bookkeeping unless it materially changes the answer.

---

## Candidate Capture Standard

When creating a `candidate`, capture as much of the following as is reasonably available from the prompt and local context:

- `skill_id`
- `domain`
- `intent`
- `human_phrases`
- `evidence_prompts`
- likely `inputs`
- likely `outputs` or required proof shape
- duplicate-check summary against existing skills
- safety boundaries
- open questions or missing metadata in `notes`

Do not stall candidate capture just because some metadata is incomplete.

Do not go full forensic on the entire chat session unless Jason explicitly asks for that level of review.

---

## Review And Promotion

- New entries are written as `candidate` and await Jason review.
- Jason approval is the gate to change `status` from `candidate` to `active`.
- Pre-promotion sync gate: before any `candidate` can be promoted to `active`, regenerate the Markdown projection and confirm it matches YAML for skill status, merge/deprecation state, and routing semantics.
- Until approved, prefer refinement of the candidate metadata over aggressive promotion or restructuring.

---

## Full System Design

See the attached design document (opened as `Untitled-2` in the session that created this registry) for full field semantics, lifecycle rules, cognitive friction tracking, and tone guidelines.
