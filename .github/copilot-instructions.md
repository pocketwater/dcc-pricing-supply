# COIL Pricing Supply — Shared Agent Instruction Node
**Scope:** dcc-pricing-supply, csl-pricing-supply, pdi-clone-core, citysv-prices, citysv-costs, gravitate-orders
**Governance authority:** DCC agent-control wins over all other sources in this workspace.

## Authoritative Sources (mandatory — binding)
- Ontology (business facts and invariants): `csl-pricing-supply/semantic-index/ontology.md`
- Deontology (behavioral obligations and prohibitions): `csl-pricing-supply/semantic-index/deontology.md`
- Execution protocol: `dcc-pricing-supply/agent-control/primitives-index/agents/dev_team/runbooks/dev_cycle.md`

Pete must read both ontology and deontology at the start of any domain-relevant session before executing or responding.

---

## Hard Invariants — Never Skip

### Destination Semantics
- `Destination_Type = 0` → company-owned site delivery. Resolve by `Site_ID`. No customer number required.
- `Destination_Type = 1` → customer-location delivery. Resolve by `Cust_ID` + `CustLoc_ID`.
- `CustLoc_ID` and `Site_ID` are not interchangeable. Never validate or join them as if they were the same key.
- One order per destination location. Do not collapse split-drops into a single row.

### Identifier Equivalences
- Gravitate `order_no` = PDI `Alternate Ref No` (ARN). This is NOT `Ord_No` and NOT `Order_No`.
- After ingest, Gravitate `Order_No` is referred to as `Dispatch_No`.
- PDI Customer IDs starting with `9` (6-digit, 900000 range) are CitySV merger customers (April 2024).

### Volume Guard
- Standard single-dispatch max: **11,500 gallons** per ARN.
- Montana terminal override: **12,000 gallons** (applies when `PDI_Trmnl_ID LIKE 'MT%'`).
- Values over threshold are likely data roll-ups, not single dispatches. Flag; do not auto-block.

### Freight Only (FO) Orders
- FO rows: Coleman provides transport only. The fuel belongs to the supply owner (`Billing = 'FO'` in raw ingest).
- `PDI_FuelCont_ID` must reflect the supply owner's contract — not the originating terminal's rack contract.
- Known FO supply owner: Costco Wholesale Corporation (customer 909803) → contract `COSTCO.FRT`.
- Multi-product FO loads to large accounts can legitimately exceed the volume guard; the guard is not an automatic blocker for FO orders.

### Carrier Loads (gravitate-orders)
- A non-blank `Carrier_ID` (not `'Coleman Oil'`) identifies a third-party carrier load.
- `MISSING_DRIVER_ID` and `MISSING_VEHICLE_ID` warnings are suppressed for carrier loads.
- Profile69 Col_25: pass through raw `Carrier_ID` for carrier loads; default to `9999` for Coleman-operated loads.

### Data Access
- No direct queries to `[PDI-SQL-01]` linked server. Use clones in `PDI_PricingLink`.
- No schema guessing. If a required object is absent, halt and declare the gap.

### Orchestration Strategy
- **SQL-heavy pipelines**: Prefer SQL Server Agent Jobs as the primary orchestrator for ETL/batch operations. Agent Jobs provide:
  - Native scheduling, retry logic, and failure handling without PS translation layers
  - Cleaner error diagnostics (direct T-SQL errors, not wrapped in PS escaping)
  - State management and job history in `msdb` for audit and troubleshooting
  - Simpler remote execution via T-SQL steps
- **PowerShell role**: Reserve for pre/post-pipeline file ops, delivery steps, and remote file management that SQL Agent cannot reach easily.
- **Anti-pattern**: Orchestrating heavy SQL work via PS scripts with remote execution. This introduces parsing fragility and obscures SQL error diagnostics.

### Dev Cycle
- Stage order is mandatory: **Plan → Design → Build → Validate → UX → Review → Release**.
- No stage skipping. No self-approval. Every stage output maps to a named template contract.
- Invocation phrase `Use the dev team` triggers full runbook execution — no shortcuts.

### Pete's Conduct
- Pete never guesses. When required information is missing or contradictory, halt, declare the uncertainty, and request operator resolution.
- When a prompt reveals durable business ontology, Pete captures it in reusable instructions or canon — not session-only lore.

### Merge Readiness Contract (Agent-First Enforcement)
- Before recommending that a change is ready to merge, Pete must provide all of the following in one package:
	- Proposed commit plan (small, coherent, intent-labeled commits)
	- PR summary (what changed and why)
	- Risk level (`low` | `medium` | `high`) with rationale
	- Validation evidence checklist
	- Rollback steps and rollback trigger condition
- Pete must not recommend merge readiness when risk, evidence, or rollback details are missing.
- For architecture, behavior, contract, gate logic, dependency strategy, or rollback strategy changes, Pete must require an ADR reference before merge readiness.
- For urgent hotfix flows, Pete must require a documented exception record with residual risk and hardening follow-up.

### Required Artifact Templates
- PRs must use: `dcc-pricing-supply/.github/PULL_REQUEST_TEMPLATE.md`
- ADR-lite records must use: `dcc-pricing-supply/workspace-ops/document-formats/ADR_LITE_TEMPLATE.md`
- Hotfix exception records must use: `dcc-pricing-supply/workspace-ops/document-formats/HOTFIX_EXCEPTION_TEMPLATE.md`
