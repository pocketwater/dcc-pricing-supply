# Pete Agent Control Model Brief

Date: 2026-05-02
Owner: Jason / Pete governance baseline
Status: Refactored to current approved model
Version: control-plane v0.2

## Executive Summary

This brief defines the active governance baseline for how Pete evaluates prompts across the multi-root workspace.

Core decisions now in force:
1. DCC (`dcc-pricing-supply/agent-control`) is the primary control plane for behavior, routing, skill lifecycle, and governance.
2. Forge registry consultation is mandatory before any repo-level runbook/prompt routing decision.
3. YAML registry is source of truth; CSL Markdown registry is projection only.
4. Projection drift is resolved by regeneration from YAML, never by manual projection edits.
5. Personal-workflow exception exists for content/context sourcing only and does not override DCC governance.

## 1) Effective Precedence Model

Apply this evaluation order on each new prompt:
1. Platform/system constraints
2. Session developer instructions
3. DCC (`dcc-pricing-supply/agent-control`)
4. Forge skill registry (mandatory consult before routing)
5. Explicitly invoked runbooks/prompts only
6. `pers-ops-jvassar` advisory only for behavior/routing/governance
7. Memory layers
8. Runtime context
9. User prompt (intent layer)

Agent Customizations precedence framing (current state):
1. Agent Customizations are treated as above workspace/domain governance sources such as DCC and repo runbooks.
2. Agent Customizations remain below platform/system constraints and session developer instructions.
3. Exact internal precedence among Agents, Skills, Instructions, Prompts, Hooks, MCP Servers, and Plugins is unknown until verified.

Conflict rules:
1. Higher authority wins.
2. Same authority level: newer explicit instruction wins.
3. If conflict remains unresolved and affects safety or execution, stop and escalate.

## 2) DCC Authority and Personal-Workflow Exception

DCC remains authoritative for:
1. routing
2. skill lifecycle
3. governance rules

Personal-workflow exception:
1. If the prompt is explicitly about Jason personal workflows, productivity system, preferences, SOCKS, planning routines, or personal operating repo content, `pers-ops-jvassar` may be consulted early as primary domain content.
2. This exception is content/context only.
3. This exception never overrides DCC behavior governance.

Examples:
1. "How should I structure SOCKS?" -> consult `pers-ops-jvassar` early for domain content.
2. "What skill should this prompt invoke?" -> consult DCC and Forge registry first.
3. "Use dev team" -> DCC governs routing and approvals; pers-ops runbook details may inform execution only when explicitly invoked.

## 3) Skill Routing Contract

Mandatory routing gates:
1. Consult active Forge YAML registry first.
2. Evaluate trigger match and non-trigger exclusion.
3. Check required inputs and request minimal missing fields.
4. Apply safety and approval constraints.
5. Select route outcome.

Deterministic outcomes:
1. `skill_invoked`
2. `candidate_skill_created`
3. `skill_ignored`

Lifecycle rules:
1. Candidate capture can occur early.
2. Promotion to active requires explicit Jason approval.
3. After lifecycle-impacting YAML updates, projection must be regenerated from YAML.

## 4) Projection Governance and Sync Routine

Command phrase:
`Sync registry`

Invocation mode:
Manual only (no always-on automation).

Execution contract:
1. Read YAML source:
  `dcc-pricing-supply/agent-control/primitives-index/skills/forge_skills_registry.yaml`
2. Generate Markdown projection:
  `csl-pricing-supply/semantic-index/AI-primitives-registry/forge_skills_registry.md`
3. Projection must include summary for each skill:
  - `skill_id`
  - `status`
  - trigger phrases summary
  - overlap relationships summary
4. Overwrite full projection file with regenerated output.
5. Return sync summary:
  - skills added/removed
  - status changes
  - structural differences

Governance note:
1. Projection is a derived artifact.
2. YAML is the only editable registry.
3. Drift is resolved by regeneration from YAML, not manual projection edits.

## 5) VS Code Agent Customizations Inventory

This section captures Agent Customizations as first-class control surfaces without redesigning the current model.

| Name | Type | Scope (known/likely) | Before Workspace/Domain Selection | Authority | Inspectable/Editable | Likely Governance Use |
|---|---|---|---|---|---|---|
| Agents | Agent Customization | workspace/repo and extension-provided (scope not fully verified) | likely yes | unknown | partially yes (repo-defined agents are inspectable; built-in/extension internals may be opaque) | role routing, delegation patterns, stage-agent workflows |
| Skills | Agent Customization | built-in and extension-provided; user/workspace skill scope not fully verified | likely yes | unknown | partially yes (workspace-visible skill docs are inspectable; full runtime precedence is opaque) | trigger-based routing aids, reusable task patterns |
| Instructions | Agent Customization | global/user, workspace, and repo-attached likely; exact order unknown | likely yes | mixed (can be authoritative when loaded at higher layers) | yes for user/workspace/repo files | behavioral constraints, governance policy injection |
| Prompts | Agent Customization | user/global prompt library and workspace prompt files likely | likely yes | advisory to mixed (depends on load path and invocation) | yes where files are accessible | reusable execution templates and stage prompts |
| Hooks | Agent Customization | unknown (likely extension/user/workspace configurable) | unknown | unknown | unknown | pre/post action enforcement, policy checks, guardrails |
| MCP Servers | Agent Customization | extension/workspace/user configured server endpoints | likely yes for capability availability | advisory to high practical influence | partially yes (configuration visible; server internals external) | tool/capability surface expansion and execution routing options |
| Plugins | Agent Customization | extension-provided and possibly user-installed | likely yes | unknown | partially yes (manifest/config visible; plugin internals vary) | feature augmentation, additional control/automation surfaces |

## 6) Authority Surface Snapshot

Authoritative:
1. Platform/system constraints
2. Session developer instructions
3. Agent Customizations layer (exact internal ordering unknown)
4. DCC governance and registry contracts

Conditionally operational:
1. Explicitly invoked runbooks/prompts (after mandatory registry consult)
2. Agent Customizations behavior that is loaded but not confirmed authoritative

Advisory/contextual:
1. `pers-ops-jvassar` for behavior governance (except early personal-workflow content sourcing)
2. Memory and runtime context
3. User prompt as intent signal, bounded by higher layers
4. Any unverified customization precedence interactions

## 7) Residual Nondeterminism

Remaining judgment surfaces:
1. Prompt classification boundary for personal-workflow versus routing/governance intent.
2. Registry miss handling when no active skill clearly matches.
3. Mixed-intent prompts that contain both personal-workflow context and skill-routing requests.

Control direction:
1. Treat ambiguous mixed-intent prompts as routing-first under DCC.
2. Use personal exception only for content/context after behavior governance is fixed.

Additional unknowns to resolve:
1. Whether each customization type is global, workspace-scoped, repo-scoped, built-in, or extension-provided in effective runtime order.
2. Whether Instructions load before Skills.
3. Whether Hooks can enforce policy before tool execution.
4. Whether built-in Skills outrank user-created Skills.
5. Where custom Instructions physically live on disk for each scope and which are auto-loaded.

## 8) Decision-Ready Summary

The control model is now explicit and implemented in governance artifacts:
1. DCC is primary control plane.
2. Forge YAML is mandatory pre-routing source.
3. CSL Markdown is controlled projection only.
4. Sync is manual via `Sync registry`.
5. Personal-workflow exception is scoped and non-overriding.

Next hardening artifact candidates:
1. `ROUTING_AUDIT_SCHEMA_v0_2.yaml`
2. `SKILL_ROUTER_DECISION_TABLE_v0_2.md`
3. `SYNC_REGISTRY_OPERATING_CHECKLIST_v0_1.md`

## 9) Final Clarity Pass (Merged)

This section merges the final ambiguity and authority-boundary review into the brief without redesigning model structure.

### 9.1 Ambiguity List (With Deterministic Rewrites)

1. Original: "Agent Customizations are treated as above workspace/domain governance sources such as DCC and repo runbooks."
- Ambiguity: "treated" is interpretive and does not state an enforceable rule boundary.
- Clarified: Agent Customizations are ranked above DCC and repo runbooks for governance interpretation unless a higher layer explicitly overrides them.

2. Original: "Agent Customizations remain below platform/system constraints and session developer instructions."
- Ambiguity: "remain" is descriptive and does not state precedence as a hard rule.
- Clarified: Platform/system constraints and session developer instructions always take precedence over Agent Customizations.

3. Original: "Exact internal precedence among Agents, Skills, Instructions, Prompts, Hooks, MCP Servers, and Plugins is unknown until verified."
- Ambiguity: conflict behavior is undefined while precedence is unknown.
- Clarified: Internal precedence among Agent Customization types is UNKNOWN; when two types conflict, runtime precedence is UNDETERMINED until verified.

4. Original: "Personal-workflow exception exists for content/context sourcing only and does not override DCC governance."
- Ambiguity: content/context boundary is not operationally explicit.
- Clarified: Personal-workflow prompts may use personal repo content, but routing, lifecycle, and governance decisions must still follow DCC rules.

5. Original: "If the prompt is explicitly about Jason personal workflows... pers-ops-jvassar may be consulted early."
- Ambiguity: "explicitly about" can be interpreted differently across operators.
- Clarified: Only prompts whose primary intent is personal-workflow content are eligible for early personal repo consultation.

6. Original: "Same authority level: newer explicit instruction wins."
- Ambiguity: "newer" source and time boundary are not explicit.
- Clarified: At equal authority, the most recent explicit instruction in the active conversation takes precedence.

7. Original: "If conflict remains unresolved and affects safety or execution, stop and escalate."
- Ambiguity: escalation target and action path are not explicit.
- Clarified: If unresolved conflict affects safety or execution, stop and request a user decision before proceeding.

8. Original: "Explicitly invoked runbooks/prompts only."
- Ambiguity: explicit invocation criteria are not fully defined.
- Clarified: Runbooks/prompts are usable only when directly named in user request or higher-layer session instruction.

9. Original: "Agent Customizations behavior that is loaded but not confirmed authoritative."
- Ambiguity: influence boundary is unclear when loaded but unverified.
- Clarified: Loaded Agent Customizations may influence behavior, but their authority is UNCONFIRMED unless defined by higher-layer instruction.

10. Original: "Treat ambiguous mixed-intent prompts as routing-first under DCC."
- Ambiguity: "routing-first" is not operationally specific.
- Clarified: For mixed intent, resolve routing authority under DCC before applying personal-workflow content exceptions.

### 9.2 Authority Boundary Classification (By Section)

| Section | Classification | Boundary Clarity |
|---|---|---|
| Executive Summary | descriptive | clear |
| 1) Effective Precedence Model | authoritative | partially unclear due to unknown internal Agent Customizations precedence |
| 2) DCC Authority and Personal-Workflow Exception | authoritative | mostly clear; intent boundary still interpretation-sensitive |
| 3) Skill Routing Contract | authoritative | clear |
| 4) Projection Governance and Sync Routine | authoritative | clear |
| 5) VS Code Agent Customizations Inventory | descriptive | clear on uncertainty, not enforceable by itself |
| 6) Authority Surface Snapshot | mixed (authoritative + descriptive) | partially unclear where customization authority is unconfirmed |
| 7) Residual Nondeterminism | descriptive | clear |
| 8) Decision-Ready Summary | descriptive/advisory | clear |

Potential authority-collision interpretations:
1. DCC is defined authoritative for governance, while Agent Customizations are framed above DCC; tie-break is unresolved when customization behavior conflicts with DCC rules.
2. Personal repo exception could be misread as governance authority unless intent boundary is strictly applied.

### 9.3 Agent Customizations Role Clarity

| Type | Can define behavior? | Can override behavior? | Enforceable vs advisory | Relative to DCC / skill registry / runbooks |
|---|---|---|---|---|
| Agents | UNKNOWN | UNKNOWN | UNKNOWN | Framed above DCC/runbooks; relative to Forge registry precedence is UNKNOWN |
| Skills | UNKNOWN | UNKNOWN | UNKNOWN | Framed above DCC/runbooks; relation to Forge YAML enforcement is UNKNOWN |
| Instructions | yes (when loaded at higher layer) | UNKNOWN | mixed | Framed above DCC/runbooks when loaded as higher-layer instruction |
| Prompts | UNKNOWN | UNKNOWN | advisory to mixed | Framed above DCC/runbooks in precedence model; enforceability not verified |
| Hooks | UNKNOWN | UNKNOWN | UNKNOWN | Position relative to tool enforcement and DCC is UNKNOWN |
| MCP Servers | can influence behavior via capability surface | UNKNOWN | advisory to high practical influence | Capability surface can shape routes before DCC logic, but precedence is not verified |
| Plugins | UNKNOWN | UNKNOWN | UNKNOWN | Framed above DCC/runbooks, internal enforcement order unknown |

### 9.4 Failure Modes (Gap Exposure Only)

1. Runtime customization precedence conflict.
- Cause: internal precedence among customization types is unknown.
- Gap: no deterministic tie-break among customization surfaces.

2. DCC vs customization authority collision.
- Cause: DCC is authoritative for governance while customization layer is ranked above DCC.
- Gap: no explicit conflict-resolution rule for this specific collision.

3. Silent routing variance across environments.
- Cause: possible global/user/extension customization load differences.
- Gap: scope and load order are not fully verified.

4. Governance/execution intent misclassification.
- Cause: prompts can include skill words in governance contexts.
- Gap: intent classification relies on evolving heuristics.

5. Silent registry bypass in practical execution.
- Cause: higher-layer loaded behavior may route before explicit registry consult.
- Gap: no guaranteed runtime evidence artifact proving registry consult occurred first.

6. YAML/projection drift affecting human operations.
- Cause: projection regeneration is manual.
- Gap: drift can persist between sync events.

7. Runbook invocation inconsistency.
- Cause: explicit invocation semantics are policy-level but not machine-checked.
- Gap: no canonical invocation validator.

### 9.5 Final Hierarchy Model (Highest Authority -> Lowest Influence)

1. Platform/system constraints
2. Session developer instructions
3. Agent Customizations layer (internal order among Agents/Skills/Instructions/Prompts/Hooks/MCP Servers/Plugins is UNKNOWN)
4. DCC governance layer
5. Forge skill registry (under DCC governance; consulted before runbooks)
6. Explicitly invoked runbooks/prompts
7. Personal repo layer (`pers-ops-jvassar`) for content exception only
8. Memory layers
9. Runtime context
10. User prompt intent layer

Confidence flags:
1. Placement confidence is high for layers 1, 2, 4, 5, 6, 7, 8, 9, and 10.
2. Internal ordering confidence is low within layer 3 (Agent Customizations).
