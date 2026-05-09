# SOCKS Project Exploration

Date: 2026-04-27
Location: personal-ops/someday
Source: Edited from attached brainstorming transcript

## Why This Document Exists

This is an edited transcript, not a summary. The goal is to keep the original thought progression, emotional turning points, and design pivots intact while improving readability and reducing repetition/noise.

## Cleaned Transcript (Thinking Patterns Preserved)

### 1. Initial Concept: VS Code Extension As Capture Surface

Jason: I want to build a custom extension in VS Code called SOCKS (Stream of Consciousness Kanban System). I want keystroke patterns to capture ideas/tasks/appointments/priorities from anywhere I am typing. Agent collects those signals, records metadata, and keeps a kanban view refreshed.

Sam: Strong concept. Main recommendation: do not build this as a keylogger. Build intentional signal capture with trigger patterns.

Suggested capture syntax examples:
- //todo reconcile Profile69 blocker view
- //idea infer repo/workspace context automatically
- //appt call Pete Friday 10am
- //wait waiting on billing team confirmation

Flow:
Typed trigger -> parser -> context enricher -> inbox store -> classifier -> kanban projection.

Key metadata:
- createdAt/updatedAt
- workspace/repo/file/line
- languageId
- git branch
- tags/context
- source location linkability

Kanban lanes suggested:
- Inbox
- Clarify
- Next
- Waiting
- Scheduled
- Blocked
- Someday
- Reference
- Done

Sam: For storage, start with workspace-local JSONL files, not extension state as source of truth:
- .socks/socks.items.jsonl
- .socks/socks.settings.json

Sam: Agent behavior should begin as suggestive only, not silent mutation.

### 2. Strategic Reframe: Extension Is Not The Whole Product

Jason: I used extension framing to start the conversation. I do not care if extension is the final home. Is extension actually best?

Sam: Extension is useful but should be one surface, not the brain.

Proposed architecture:
Capture Layer (many surfaces) -> SOCKS Core (brain) -> Views (VS Code/web/mobile/CLI)

Options considered:
1. VS Code only (fast v0, weak long-term)
2. Local-first core + thin clients (recommended)
3. Always-on daemon (endgame)

Sam recommended implementation path:
- Phase 1: quick VS Code loop (capture + basic board)
- Phase 2: extract core/storage
- Phase 3: everywhere capture (CLI/hotkey/API)
- Phase 4: add agent assist

Critical design call:
- Event-based model preferred over pure state model
- Captured -> Clarified -> Moved -> Completed
- Keep append-only event log for auditability and rebuildability

### 3. M365 Integration Question

Jason: Can this collaborate with Outlook calendar, email, Teams?

Sam: Yes, through Microsoft Graph API, but with strict trust boundaries.

Principle:
SOCKS should be decision engine + orchestrator, not uncontrolled executor.

Use Graph for:
- Calendar
- Mail
- Teams
- Tasks
- Files

Operational guidance:
- Start read-only scopes first
- Require explicit user confirmation before write actions
- Do not auto-send emails or auto-create meetings silently

Potential high-value behavior:
- Cross-surface stitching (email + Teams + code + notes -> one thread)
- Commitment tracking ("you said you would")
- Context-aware scheduling suggestions

### 4. Shift To Attention Scheduling (Major Pivot)

Jason: I want structural blocks tied to states: Project Focus, Review Backlog, Training, Version Development. At block start, give goals calibrated to available time and work type. Weekly review should allocate next week by production demand state.

Sam: This is the right direction. SOCKS becomes attention scheduler, not task list.

Loop:
Kanban state -> calendar block -> session briefing -> capture during work -> review -> next-week allocation

Block intent contract idea:
- blockType
- defaultDuration
- allowedStates
- excludedStates
- energy level
- expected output
- closeout required

Demand state concept:
- Green/Yellow/Red/Blue modes to rebalance week structure

Weekly review as guided ritual, not blank page:
1. What changed?
2. What demand state are we in?
3. What is active?
4. What is due?
5. What is blocked?
6. What deserves deep work?
7. What gets ignored on purpose?
8. Generate blocks.

### 5. GTD vs Kanban Tension (Forum Input)

Jason supplied a long GTD forum thread and personal context:
- Capture is easy
- Clarify and weekly review are hard
- WIP overload + one-track focus causes neglect of small tasks
- 4 x 15 minute hits daily could prevent multi-month decay

Sam response pattern:
- Keep inventory separate from active WIP
- Add a protected small-work mechanism

Model introduced:
- Inventory = captured universe
- Backlog = reviewed not active
- WIP = active commitments
- Today Board = today's attention map
- Hit List = small time-boxed items

Core rule:
Small work should not compete directly with deep work for selection attention.

### 6. Tier Model Formation

Jason proposed a tier system:
1. Primary project (where focus wants to be)
2. Two to three required-but-resisted projects
3. Next potential big thing
4. Tickler/refresh inventory
5. Learning tracks

Sam validated and suggested mapping each tier to distinct block types.

Jason constraints added:
- Morning 45 minute fixed commitment
- Only two fixed weekly meetings desired
- Mornings usually safe for focus
- 4-5pm often safe due to timezone dynamics
- Three-hour primary blocks are realistic
- Six hours primary target can be normal in real practice
- Day length needs adjustable mode

Sam proposed operating modes:
- Standard Day
- Extended Day

Primary allocation framing:
- Target vs floor distinction
- Keep system honest by protecting minimum viable execution while allowing acceleration on longer days

### 7. Discovery Of A Missing State: Waiting On Agents

Jason: Significant daily time is lost while waiting on Pete/agent run/debug cycles. Avoiding context switching often leads to drift into Outlook/Teams.

Sam: This is a distinct state, not idle noise.

New state introduced:
Latency Window
- primary work paused
- return time unpredictable
- context switch cost constraints

Design response:
- Curated Latency Queue
- strict interruptibility rules
- single-task pull during wait windows
- explicit stop condition (agent returns or timebox hit)

### 8. Today Pack Design (Concrete Operating Mechanism)

Jason: Every day provide calendar + 5 latency tasks. Keep them visible until checked off. Refill only when depleted.

Sam: This is high leverage.

Today Pack:
1. Calendar commitments
2. Exactly five latency tasks

Latency task categories:
- System hygiene
- Validation/review
- Forward prep
- Parallel isolated agent work
- Repo/linter review work

Hard behavioral rule:
Latency tasks persist all day until completion; no infinite stream.

### 9. Critical Boundary: Latency Must Not Smuggle Tier 2

Jason: Latency must not prematurely introduce Tier 2 unless Tier 2 is clearly defined. Tier 2 needs calendar commitment and mental preparation because of emotional resistance.

Sam: Boundary confirmed.

Non-negotiable:
Latency tasks must be:
- already understood
- already scoped
- emotionally neutral

Latency tasks must not:
- require clarification
- require motivation priming
- introduce new projects
- carry ambiguity

Promotion pipeline:
Tier 3 (unclear) -> clarification -> Tier 2 (clear but resisted) -> decomposed fragments -> latency-eligible units

### 10. Grain Discovery: Clarity x Motivation x Cognitive Load

Jason: Add cognitive load. Load must be low enough to pick up and drop safely.

Sam: This completes the classifier.

Classifier dimensions:
- Clarity
- Motivation (resistance profile)
- Cognitive load (start/hold/resume cost)

Placement logic:
- Tier 1: high clarity, high motivation, high load
- Tier 2: high clarity, low motivation, medium-high load
- Tier 3: low clarity, mixed motivation, medium load
- Latency: high clarity, neutral motivation, low load

Latency test:
If interrupted in three minutes, can it be stopped instantly and resumed in under two minutes with no reorientation penalty?

### 11. Feasibility Check On Semantic Determinism

Jason: We are trying to force deterministic parsing on emotionally rich human language; that is not simple.

Sam: Agreed. Do not over-automate early.

Practical loop:
- Agent proposes candidates
- User snap-judges accept/reject quickly
- System learns rejection patterns over time

Key shift:
Optimize for fast human filtering, not perfect autonomous interpretation.

## Design Throughline Captured From The Conversation

This conversation repeatedly converges on one throughline:

SOCKS should produce a trustworthy daily execution surface, not a large management interface.

During the week, the desired output is:
- Calendar blocks with intent
- Primary focus objective
- A finite, curated latency pack

Everything else belongs behind the scenes and is processed during structured review.

---

## Addendum: My Assessment And Recommendations

### A. Thoughts On The Chat Itself

What is strong:
- The thread progressively narrowed from broad productivity idea to concrete operating mechanics.
- You consistently introduced real constraints (meetings, timezones, dinner boundary, agent wait windows), which turns theory into schedulable behavior.
- You drew explicit behavioral boundaries (especially around latency misuse), which is exactly what makes systems trustworthy.
- You identified emotional resistance and cognitive load as separate variables. That is a high-quality modeling move.

Where the chat stretched too far:
- The assistant over-generated at times and mixed architecture, product strategy, investor framing, and personal execution mechanics in one stream.
- Some recommendations implied sophistication before proving the daily loop.
- Semantic classification expectations were occasionally stated as if directly solvable, then later corrected.

Net: The conversation is highly valuable because it discovered the right execution grain, even though it traveled through several abstraction layers first.

### B. Thoughts On The Substance Of The Project

My view: this is a legitimate project with real differentiation if scoped correctly.

Most defensible core:
- Scheduler of attention, not list manager
- Deterministic daily package generation
- Human-in-the-loop acceptance of ambiguity-heavy classification

The highest-value v1 outcome is not a board. It is:
- one daily plan view
- one finite latency pack
- one weekly runbook flow

If v1 achieves those three outputs reliably, this is already useful regardless of advanced AI semantics.

### C. Proposed Project Definition (Practical)

Project statement:
SOCKS converts captured operational inventory into a constrained daily execution plan that protects deep work and guarantees small-work throughput under real interruption conditions.

Success criteria for first usable version:
1. Daily plan generated in under 60 seconds from existing inventory.
2. Primary block protection works (calendar-respect behavior).
3. Exactly 5 latency tasks are always available and interruption-safe.
4. Weekly review can re-tier and regenerate the next week in one guided run.

### D. Recommended Build Sequence

1. Canonical data model and event log
- Keep append-only events
- Derive state projections for views

2. Weekly review runbook generator
- Demand state
- Tier selection limits
- Calendar allocation template

3. Daily pack generator
- Primary objective
- Time blocks
- Five latency tasks with eligibility checks

4. Minimal interaction loop
- Accept/reject latency candidates quickly
- Mark completion and capture closeout notes

5. Optional integrations later
- Outlook/Teams/Email adapters after local loop is stable

### E. Risk Register (Important)

Top risks:
- Over-automation too early
- Latency queue contamination by resisted/unclear work
- Capture growth without clarify throughput
- Extended-day mode silently becoming required baseline
- Drift from execution surface back to management overhead

Primary controls:
- Hard eligibility checks for latency
- Daily finite task pack
- Forced weekly re-tiering
- Visible floor/target distinction for primary work
- Confirmation gates for all external system writes

### F. Final Strategic Take

You are not building another productivity app. You are defining a personal operations scheduler that models how your work actually behaves under deep-focus bias, interruption, and agent latency.

If you keep the product output narrow (daily plan + 5 latency tasks + weekly runbook), this can become a durable system quickly.

If you broaden too early into full autonomous semantics or broad integrations, it will likely become fragile and heavy.
