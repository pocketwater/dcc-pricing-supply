# Pete Instruction Load Audit
**Date:** 2026-05-07
**Scope:** Multi-root workspace — all seven repos
**Purpose:** Verify what instruction sources are actually always-on vs. conditionally loaded, identify gaps, and establish a repeatable audit procedure for future sessions.

---

## 1. Current Instruction Source Inventory

### 1a. Always-On Files Found

| File | Type | Auto-Load Trigger | Status |
|------|------|-------------------|--------|
| `pers-ops-jvassar/.github/copilot-instructions.md` | `copilot-instructions.md` | Auto-loaded by VS Code for `pers-ops-jvassar` work tree | **Active** |
| `csl-pricing-supply/semantic-index/ontology.md` | Referenced mandatory source | Declared binding in `copilot-instructions.md` — Pete must read it | **Active (read-on-demand)** |
| `csl-pricing-supply/semantic-index/deontology.md` | Referenced mandatory source | Declared binding in `copilot-instructions.md` — Pete must read it | **Active (read-on-demand)** |

### 1b. Always-On Files Missing / Not Present

| Expected File | Type | Gap |
|---------------|------|-----|
| `AGENTS.md` in any repo root | Always-on multi-agent instructions | **Not found in any root** |
| `CLAUDE.md` in any repo root | Claude-compatible always-on instructions | **Not found in any root** |
| `.github/copilot-instructions.md` in `dcc-pricing-supply`, `csl-pricing-supply`, `pdi-clone-core`, `citysv-prices`, `citysv-costs`, `gravitate-orders` | Per-root always-on instructions | **Not found — only `pers-ops-jvassar` has one** |

> **Key finding:** VS Code loads `.github/copilot-instructions.md` per workspace folder root. The single file in `pers-ops-jvassar` only guarantees auto-load when that folder is in active context. The other six repos have no auto-loaded instruction files. All governance coverage for those repos currently depends on Pete reading `ontology.md` and `deontology.md` on demand — which relies on Pete following the obligation declared in `copilot-instructions.md`, not on platform auto-loading.

### 1c. Conditionally-Loaded Files Found

| File | Type | Load Condition |
|------|------|---------------|
| `dcc-pricing-supply/agent-control/primitives-index/agents/dev_team/agents/*.agent.md` (8 files) | Custom agents (`.agent.md`) | Invoked when user selects the named agent from Chat dropdown |
| `dcc-pricing-supply/agent-control/primitives-index/agents/dev_team/prompts/*.prompt.md` (8 files) | Prompt files (`.prompt.md`) | Invoked explicitly via slash command or direct prompt reference |

### 1d. `.instructions.md` Files

None found in the workspace. File-based conditional instructions (the `.github/instructions/` pattern) are not currently used.

---

## 2. VS Code Settings Audit

### 2a. Workspace Settings
No `.vscode/settings.json` files found in any workspace folder. All instruction behavior governed by user-level settings and VS Code defaults.

### 2b. User Settings — Relevant Keys
From `%APPDATA%\Code\User\settings.json` (inspected 2026-05-07):

| Setting | Value | Impact |
|---------|-------|--------|
| `chat.useAgentsMdFile` | *(not set — default: `true`)* | AGENTS.md would auto-load if the file existed |
| `chat.useClaudeMdFile` | *(not set — default: `true`)* | CLAUDE.md would auto-load if the file existed |
| `chat.includeApplyingInstructions` | *(not set — default: `true`)* | Pattern-based `.instructions.md` auto-apply is on |
| `chat.includeReferencedInstructions` | *(not set — default: `true`)* | Instructions referenced via Markdown links are followed |
| `github.copilot.chat.organizationInstructions.enabled` | *(not set — default: `false`)* | Organization-level instructions are **not** being loaded |
| `github.copilot.chat.agentDebugLog.fileLogging.enabled` | *(not set — default: `false`)* | **Agent Debug Logs panel is off** — no discovery/tool logs |
| `github.copilot.chat.otel.enabled` | *(not set — default: `false`)* | OTel tracing is off |
| `github.copilot.chat.otel.dbSpanExporter.enabled` | *(not set — default: `false`)* | SQLite span persistence is off |
| `github.copilot.chat.fileLogging.enabled` | *(not set — default: `false`)* | `/troubleshoot` slash command is unavailable |

**No audit-relevant settings are currently enabled.** This means there is currently no persistent instrumentation on Pete's behavior during sessions.

---

## 3. Instruction Priority (Platform-Level)

Per VS Code documentation (confirmed in 1.119.0 era):

```
Priority (highest to lowest):
  1. Personal / user-level instructions (user profile .instructions.md, ~/.copilot/instructions)
  2. Repository instructions (.github/copilot-instructions.md or AGENTS.md in workspace root)
  3. Organization-level instructions (GitHub org config, disabled here)
```

No user-profile instructions or `~/.copilot/instructions` files were audited in this pass. If any exist at the user level, they outrank `copilot-instructions.md`.

---

## 4. Gap Analysis

| Gap | Risk | Recommended Fix |
|-----|------|----------------|
| Ontology and deontology are referenced but not auto-loaded | Pete may skip them if he does not read instructions carefully at session start | Promote key invariants from both files into `copilot-instructions.md` directly, or add `.github/copilot-instructions.md` to the other six repo roots |
| No Agent Debug Logging enabled | Cannot audit what Pete actually loaded or which tools fired | Enable `github.copilot.chat.agentDebugLog.fileLogging.enabled` (see Profile A below) |
| No OTel tracing enabled | No cross-session observability of token use, tool call sequences, or subagent behavior | Enable OTel with SQLite export for offline inspection (see Profile B below) |
| No `.instructions.md` files | Cannot apply targeted, file-scoped rules (e.g., SQL-only rules for `.sql` files) | Consider adding per-language `.instructions.md` files under `.github/instructions/` |
| `copilot-instructions.md` exists only in `pers-ops-jvassar` | Six other repos get no guaranteed auto-load | Add matching instruction stubs to each repo's `.github/` folder, or use an AGENTS.md at workspace root |

---

## 5. Settings Profiles

### Profile A — Standard Auditing (Low Noise)
**Purpose:** See what Pete loaded and called in Agent Logs without writing OTel telemetry.
**Add to `%APPDATA%\Code\User\settings.json`:**

```json
// Pete Instruction Audit — Profile A: Standard
"github.copilot.chat.agentDebugLog.fileLogging.enabled": true,
"github.copilot.chat.fileLogging.enabled": true
```

**What this enables:**
- Agent Debug Logs panel (Chat view overflow → Show Agent Debug Logs)
- Discovery events: which instruction/prompt files were loaded, skipped, or failed
- Tool call log: which tools fired and in what order
- `/troubleshoot list all paths you tried to load customizations` slash command
- `/troubleshoot how many tokens did you use in #session`

**Verification after enabling:**
1. Send any prompt to Pete.
2. Open Agent Debug Logs → Logs view.
3. Filter for `Discovery` events. Confirm `copilot-instructions.md` appears as loaded.
4. Confirm `ontology.md` and `deontology.md` appear as context reads (they will show as tool calls, not discovery events).

---

### Profile B — Deep Forensic (Full OTel + Content)
**Purpose:** Cross-session, durable trace capture including full prompt and system prompt content. Use for debugging unexpected behavior or preparing for a Sam architecture review.
**Add to `%APPDATA%\Code\User\settings.json`:**

```json
// Pete Instruction Audit — Profile B: Deep Forensic
"github.copilot.chat.agentDebugLog.fileLogging.enabled": true,
"github.copilot.chat.fileLogging.enabled": true,
"github.copilot.chat.otel.enabled": true,
"github.copilot.chat.otel.dbSpanExporter.enabled": true,
"github.copilot.chat.otel.captureContent": true
```

**What this adds over Profile A:**
- Full span tree: `invoke_agent` → `chat` → `execute_tool` → `execute_hook` hierarchy
- Token counts per span (input, output, cache read, cache creation)
- Full system prompt content captured in spans (includes Pete's injected instructions — this is how you verify what Pete actually received)
- SQLite local database persisted to disk; exportable via `Chat: Export Agent Traces DB`
- Agent Flow Chart view: visual orchestration map of subagent calls

> **Caution:** `captureContent: true` logs full prompt and response content to the local SQLite database. Do not commit the `.db` file to source control. Add `*.db` to `.gitignore` if you enable this on a machine where the DB path lands inside a repo.

**Trace interpretation quick reference:**
```
invoke_agent GitHub Copilot Chat        ← full Pete session
  ├── chat claude-sonnet-4.6            ← LLM call, token counts here
  ├── execute_tool readFile             ← Pete reading ontology.md
  ├── execute_tool readFile             ← Pete reading deontology.md
  ├── execute_tool grep_search          ← any search
  ├── chat claude-sonnet-4.6            ← follow-up LLM call
  └── ...
```

If `readFile` for `ontology.md` and `deontology.md` do not appear early in the span tree for a domain-relevant session, Pete is not following the read-on-demand obligation.

---

## 6. Repeatable Audit Procedure

Use this checklist at the start of any session where compliance with governance sources matters.

```
[ ] 1. Chat response → expand References section.
        Confirm: copilot-instructions.md appears.

[ ] 2. Agent Debug Logs → Discovery events.
        Confirm: copilot-instructions.md loaded (not skipped/failed).
        Confirm: No instruction files show parse errors.

[ ] 3. Chat Debug View → System prompt section.
        Confirm: Ontology and deontology rules appear verbatim or by reference.
        (If not, Pete is not reading them — escalate to Jason for manual context injection.)

[ ] 4. Chat Debug View → Tool responses.
        Confirm: readFile calls for ontology.md and deontology.md appear for domain-relevant sessions.

[ ] 5. (Profile B only) Export Agent Traces DB.
        Confirm: invoke_agent span duration and turn count are reasonable.
        Confirm: captureContent system prompt contains governance rules.
```

---

## 7. Recommended Next Actions

| Priority | Action | Owner |
|----------|--------|-------|
| High | Enable Profile A settings to activate Agent Debug Logs | Jason (user settings) |
| High | Verify whether user-profile instructions exist at `~/.copilot/instructions` (not audited) | Pete (next session) |
| Medium | Add `.github/copilot-instructions.md` stubs to the other six repo roots, referencing the same ontology/deontology | Jason + Pete |
| Medium | Evaluate AGENTS.md at workspace root as a cross-tool fallback for non-Copilot agents | Jason + Sam |
| Low | Enable Profile B for one forensic session, export DB, review system prompt content, then disable `captureContent` | Jason |
| Low | Add `*.db` to workspace root `.gitignore` files before enabling Profile B | Pete |

---

*Audit performed by Pete (GitHub Copilot, Claude Sonnet 4.6) | 2026-05-07 | dcc-pricing-supply/agent-control/audits | Sources: ontology.md ✓ | deontology.md ✓ | VS Code 1.119.0 release notes ✓*
