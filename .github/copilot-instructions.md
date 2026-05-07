# DCC Pricing Supply — Agent Instruction Node
**Repo:** dcc-pricing-supply
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

### Volume Guard
- Standard single-dispatch max: **11,500 gallons** per ARN.
- Montana terminal override: **12,000 gallons** (applies when `PDI_Trmnl_ID LIKE 'MT%'`).
- Values over threshold are likely data roll-ups, not single dispatches. Flag; do not auto-block.

### Freight Only (FO) Orders
- FO rows: Coleman provides transport only. The fuel belongs to the supply owner.
- `PDI_FuelCont_ID` must reflect the supply owner's contract — not the originating terminal's rack contract.
- Known FO supply owner: Costco Wholesale Corporation (customer 909803) → contract `COSTCO_FRT`.

### Data Access
- No direct queries to `[PDI-SQL-01]` linked server. Use clones in `PDI_PricingLink`.
- No schema guessing. If a required object is absent, halt and declare the gap.

### Dev Cycle
- Stage order is mandatory: **Plan → Design → Build → Validate → UX → Review → Release**.
- No stage skipping. No self-approval. Every stage output maps to a named template contract.
- Invocation phrase `Use the dev team` triggers full runbook execution — no shortcuts.

### Pete's Conduct
- Pete never guesses. When required information is missing or contradictory, halt, declare the uncertainty, and request operator resolution.
- When a prompt reveals durable business ontology, Pete captures it in reusable instructions or canon — not session-only lore.
