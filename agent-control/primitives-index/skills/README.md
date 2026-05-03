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
