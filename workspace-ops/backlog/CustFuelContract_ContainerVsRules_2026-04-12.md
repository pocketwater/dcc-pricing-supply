# Contract Container vs Rule-Driven Pricing — Strategy Memo

**Date:** 2026-04-12
**Phase:** 7b — Container vs Proliferation Strategy
**Verdict:** **VIABLE** — Few containers, many rules is the correct model

---

## Objective

Determine whether Customer Fuel Contracts should be:
- **Thin containers** (few contracts + many pricing rules) — OR —
- **High-volume operational objects** (one contract per customer)

---

## 1. Contract Group Viability

### Groups Exist, Are Unused, But Fully Wired

| Asset | State |
|-------|-------|
| `Customer_Contract_Groups` table | 2 groups exist: "Shell Branded" (Key=1), "Oregon Rack Lifters" (Key=2) |
| `Customer_Sales_Info.CustSls_CustContGrp_Key` | The membership column — **zero customers assigned to any group** |
| Contract 11 ("Shell Branded") | Type=1, bound to group Key=1, has active detail (Key=17, eff 2024-05-15) with pricing rule (Key=3767) |
| Resolution proc | `OD_CalcPrices_ResolveFuelPricingRules_SP` has a dedicated UNION path for `ODPC_Cust_Contract_Group_Key = CustFuelCont_CustContGrp_Key` |

### How Group Membership Works

```
Customer_Sales_Info (per customer + optional per location, per Sales_Type)
  └─ CustSls_CustContGrp_Key → Customer_Contract_Groups.CustContGrp_Key
                                   └─ Customer_Fuel_Contracts.CustFuelCont_CustContGrp_Key
```

- Groups are defined in `Customer_Contract_Groups` (simple: Key, Sales_Type, Description)
- Customers are linked via `Customer_Sales_Info` rows where `CustSls_CustContGrp_Key` is populated
- Sales_Type=1 (Fuel) is required — contract groups have `CustContGrp_Sales_Type=1`
- **Location-level assignment is supported**: `CustSls_CustLoc_Key` can be set, meaning different locations for the same customer can be in different groups

### Resolution Behavior: Groups vs Direct

The pricing engine resolves contracts in this order within `OD_CalcPrices_ResolveFuelPricingRules_SP`:

| Step | Match | Condition |
|------|-------|-----------|
| 1 | **Override/Dispatched** | `ODPC_CustFuelContDtl_Key` already set on order line |
| 2 | **Direct customer** | `ODPC_Cust_Key = CustFuelCont_Cust_Key` |
| 3 | **Contract group** | `ODPC_Cust_Contract_Group_Key = CustFuelCont_CustContGrp_Key` |

Step 2 and 3 are a **UNION** — both contribute candidate rules. Direct customer contracts and group contracts both feed into the ranking engine.

### Verdict on Groups

**Groups are fully functional infrastructure — just dormant in this tenant.** The Shell Branded contract + group proves the schema end-to-end. Assigning `CustSls_CustContGrp_Key` to customers would immediately bring them under group contract pricing.

However: **groups are not required to achieve "few containers."** Direct customer binding already supports multiple rules per contract. Groups add a sharing layer on top.

---

## 2. Rule Scoping Power

### What One Contract Can Differentiate

Each contract detail (effective date period) can hold **multiple pricing rules**, each independently scoped:

| Dimension | Scoped By | Mechanism |
|-----------|-----------|-----------|
| **Product** | `OD_Fuel_Pricing_Products` child rows | Each rule lists which products it applies to |
| **Customer Location** | `OD_Fuel_Pricing_Locations` child rows | When `Selected_CustLocs=1`, rule only applies to listed locations |
| **Vendor** | `OD_Fuel_Pricing_Origins` (Type=0) | When `Selected_Vendors=1`, rule only applies to listed vendors |
| **Terminal** | `OD_Fuel_Pricing_Origins` (Type=1) | When `Selected_Terminals=1`, rule only applies to listed terminals |
| **Fuel Contract** | `OD_Fuel_Pricing_Origins` (Type=2) | When `Selected_Contracts=1`, rule only applies to listed supply contracts |
| **Pricing basis** | `Price_Basis` + `Adj_Method` + `Amount` on the rule | Each rule can have different pricing logic |

### Live Example: Contract 10 (City of Sumas)

One contract, one detail, one rule — but the rule covers 2 products:

```
Contract 10 → Detail 15 → Rule 18 "Clear/Gas"
  ├─ Product 1 (2010087)
  └─ Product 7 (2100200)
  Price_Basis=4, Adj_Method=1, Amount=0.45  →  Cost + $0.45
  Selected_CustLocs=False  →  applies to ALL locations
  Selected_Vendors=False   →  applies to ALL vendors
  Selected_Terminals=False →  applies to ALL terminals
```

### Live Example: Contract 6 (Bel Lyn)

One contract, one detail, **two rules** with different products and pricing:

```
Contract 6 → Detail 10
  ├─ Rule 12 "Bel Lyn 200"    → Product 9 (2101200)  → Cost + $0.35
  └─ Rule 13 "Bel Lyn Clear"  → Product 7 (2100200)  → Cost + $0.18
```

This proves a single contract can express different pricing per product.

### Can Rules Fully Replace Contract Proliferation?

**Yes, in most cases.** The scoping dimensions (product × location × vendor × terminal) are multiplicative:

| Scenario | Contracts Needed | Rules Needed |
|----------|-----------------|--------------|
| 50 customers, same cost+markup per product | 1 group contract | 1 rule per product |
| 50 customers, different markup per product | 1 group contract | 1 rule per product (covers all customers via group) |
| 50 customers, different markup per customer per product | 50 direct contracts OR segmented groups | 1 rule per product per contract |
| 10 customers, location-specific pricing | 1 contract per customer | Multiple rules, each with `Selected_CustLocs=1` |

**The only case requiring per-customer contracts is when the same product at the same origin needs different pricing per customer.** That's because rules don't have a customer-key discriminator inside a single contract — the contract itself is the customer discriminator.

---

## 3. Minimum Container Strategy

### Pattern A: One Contract Per Customer (Current Pattern)

```
Contract "867665" → Customer 12843 (City of Sumas)
  └─ Rule "Clear/Gas" → Products [1, 7] → Cost + $0.45
```

| Aspect | Assessment |
|--------|------------|
| Contracts at scale | 1 per customer = hundreds |
| Rule management | Simple — each contract is self-contained |
| Overlap risk | None — each customer has exactly one contract |
| Import complexity | One CSV per customer change |
| **Best for** | Customers with unique pricing that doesn't match any group |

### Pattern B: Contract Groups (Shared Contracts)

```
Group "WA Rack Customers"
  └─ Contract "CITYSV-WA-RACK" → CustContGrp_Key
       └─ Rule "Clear Cost+45" → Products [1, 7] → Cost + $0.45
       └─ Rule "Dyed Cost+25"  → Products [9]     → Cost + $0.25

Customer_Sales_Info assignments:
  Customer 12843 (City of Sumas)  → CustSls_CustContGrp_Key = WA Rack
  Customer 13108 (Jackson)        → CustSls_CustContGrp_Key = WA Rack
  Customer 5239  (Fred Meyer)     → CustSls_CustContGrp_Key = WA Rack
```

| Aspect | Assessment |
|--------|------------|
| Contracts at scale | 1 per pricing tier, not per customer |
| Rule management | Rules are shared — change once, affects all group members |
| Overlap risk | **Medium** — if a customer also has a direct contract, both contribute candidates |
| Import complexity | One CSV updates pricing for the entire group |
| Customer assignment | Requires `Customer_Sales_Info` updates (DML, not import) |
| **Best for** | Customers with identical pricing terms |

### Pattern C: Hybrid (Recommended)

```
Tier 1: Group contracts for common pricing tiers
  └─ "CITYSV-RACK-PLUS-45"  → group of customers at cost+$0.45
  └─ "CITYSV-RACK-PLUS-25"  → group of customers at cost+$0.25

Tier 2: Direct contracts for exceptions
  └─ "CITYSV-867665-CUSTOM" → City of Sumas custom pricing (if differs from group)
```

| Aspect | Assessment |
|--------|------------|
| Contracts at scale | ~5-10 group contracts + outlier direct contracts |
| Rule management | Group rules for the norm, direct rules for exceptions |
| Overlap risk | **Must be managed** — never put a customer in a group AND have a direct contract with overlapping products |
| Import complexity | Moderate — mostly group-level CSV updates, occasionally per-customer |
| **Best for** | The real world — most customers fit tiers, some are special |

---

## 4. Overlap + Conflict Behavior (Critical Finding)

### The Ranking Engine

`OD_CalcPrices_ResolveFuelPricingRules_GetRules_SP` collects **all** candidate rules from all matching contracts/strategies, then ranks them:

```sql
UPDATE #candidateRules
SET crRank =
    CASE WHEN crOrdCustLocKey = crRuleCustLocKey THEN 3000 ELSE 0 END +   -- location match
    CASE WHEN crOrdCustKey = crRuleCustKey THEN 2000 ELSE 0 END +         -- customer match
    CASE WHEN crOrdGrpKey = crRuleGrpKey THEN 1000 ELSE 0 END +           -- group match
    CASE WHEN crOrdProdKey = crRuleProdKey THEN 200 ELSE 0 END +          -- product match
    CASE WHEN crOrdPPGKey = crRulePPGKey THEN 100 ELSE 0 END +            -- product price group
    CASE WHEN crOrdVendKey = crRuleVendKey THEN 50 ELSE 0 END +           -- vendor match
    CASE WHEN crOrdTrmnlKey = crRuleTrmnlKey THEN 10 ELSE 0 END +        -- terminal match
    CASE WHEN crOrdFuelContKey = crRuleFuelContKey THEN 20 ELSE 0 END +   -- fuel contract match
    CASE WHEN crOrdBulkPlantKey = crRuleBulkPlantKey THEN 50 ELSE 0 END   -- bulk plant match
```

Then selects `MAX(crRank)` per order line:

```sql
;WITH maxRank (mrOrdFuelKey, mrMaxRank) AS
    (SELECT crOrdfuelKey, MAX(crRank) FROM #candidateRules GROUP BY crOrdFuelKey)
UPDATE tempdb..Order_Desk_Price_Calculation
SET ODPC_Strategy_Rule_Key = crRuleKey ...
FROM ... INNER JOIN maxRank ON crRank = mrMaxRank
```

### What This Means

| Behavior | Rule |
|----------|------|
| **Deterministic** | Yes — highest rank wins |
| **Additive** | No — one rule per order line, per product |
| **Precedence hierarchy** | Location (3000) > Customer (2000) > Group (1000) > Product (200) > Vendor (50) > Terminal (10) |

### Overlap Scenarios

**Scenario 1: Group contract + Direct contract for same customer**
- Customer in group → group contract contributes rules with `crRuleGrpKey` match (+1000)
- Customer also has direct contract → contributes rules with `crRuleCustKey` match (+2000)
- **Result: Direct contract wins** (2000 > 1000). Safe — more specific always wins.

**Scenario 2: Two rules in same contract, different products**
- Rule A covers Product 7, Rule B covers Product 9
- Order line for Product 7 → only Rule A is a candidate (product join filters)
- **Result: No conflict.** Product scoping prevents overlap entirely.

**Scenario 3: Two rules in same contract, same product, different locations**
- Rule A covers Product 7 at Location X, Rule B covers Product 7 at all locations
- Order for Location X → both are candidates
- Rule A gets +3000 (location match), Rule B gets 0
- **Result: Location-specific rule wins.** Safe.

**Scenario 4: Two rules in same contract, same product, same scope**
- Both match → both get same rank → `MAX(crRank)` picks one **non-deterministically** (whichever row SQL returns first)
- **Result: AMBIGUOUS.** This is the only dangerous scenario. Avoid via import validation.

### Safety Rules

1. **Never have two rules with identical product × location × vendor × terminal scope** in the same contract
2. **The import's `ValidateDuplicateRules_SP` catches this** — it builds a coverage matrix (product × location × vendor × terminal × bulk plant) and flags overlapping new rules
3. **Direct customer always beats group** — so having a direct contract as an override for a group customer is safe

---

## 5. Import Implications

### Updating Rules Within Existing Contracts

The `Post_SP` handles both:

| Action | How It Works |
|--------|-------------|
| **UPDATE existing rule** | Matched by `Contract_ID + Effective_DateTime + Description` → full field overwrite |
| **INSERT new rule** | When `Imp_ODFuelPrcRule_Key IS NULL` (no existing match) → creates new rule in the contract |
| **Products/Locations/Origins** | Child records follow the same pattern — matched by parent rule + ID, updated or inserted |

### Adding Rules to Existing Contracts

ODFPCI import supports adding new rules without touching existing ones:
- Import CSV with: existing `Contract_ID`, existing `Effective_DateTime`, **new** `Rule_Description`
- `ResolveKeys_SP` won't find a match → `Imp_ODFuelPrcRule_Key` stays NULL → `Post_SP` INSERTs
- Existing rules in the same contract are untouched (no cascade delete)

### Removing Rules

**ODFPCI does NOT support rule deletion.** There is no "remove rule" record type.

To deactivate a rule, import it with `Status=1` (if `ODFuelPrcRule_ContractQtyRuleDetails=1` enables rule-level status checking) or remove its product assignments.

In practice: **set the rule's amount to 0** or change its scope to cover no products.

### Risk: Rule Duplication

`ValidateDuplicateRules_SP` builds coverage matrices for:
- New rules in the import (checks against each other)
- New rules vs existing rules (checks for overlap)

It flags duplicate coverage as validation errors — the import will **block** if two rules would cover the same product × location × origin combination.

### Risk: Orphaned Rules

Not possible through import. Rules are always parented to a `CustFuelContDtl_Key`. The import requires `Contract_ID + Effective_DateTime` on every rule record, and `ResolveKeys_SP` resolves the parent key.

### Risk: Unintended Overwrites

**Medium risk.** If you import a rule with the same `Contract_ID + Effective_DateTime + Description` as an existing rule, ALL fields are overwritten (not just the ones you changed). The `CopyExistingContractDetails_SP` pre-populates blank import fields from existing data, but if you explicitly set a field, it overwrites.

**Mitigation:** Always import the full rule payload, never partial. The `SetDefaults_SP` fills blanks with zeros, so omitted fields don't stay NULL — they become zero, which may not be what you want.

---

## Verdict: VIABLE — Few Containers, Many Rules

### Recommended Strategy: Hybrid (Pattern C)

```
┌─────────────────────────────────────┐
│  Contract Group: "CITYSV-STANDARD"  │  ← most customers
│  ├─ Rule: "Clear Cost+45"          │
│  │   └─ Products: [2100200, 2010087]│
│  └─ Rule: "Dyed Cost+25"           │
│      └─ Products: [2101200]         │
└─────────────────────────────────────┘
         ↑ shared by N customers via
           Customer_Sales_Info.CustSls_CustContGrp_Key

┌─────────────────────────────────────┐
│  Direct Contract: "CITYSV-867665"   │  ← exception customers
│  └─ Rule: "Sumas Special"          │
│      └─ Products: [2100200]         │
│      └─ Price_Basis=4, Amount=0.30  │
└─────────────────────────────────────┘
         ↑ direct customer binding (overrides group at rank 2000 > 1000)
```

### Decision Matrix

| Question | Answer |
|----------|--------|
| Can contracts be minimized? | **Yes** — one group contract covers many customers |
| Can rules differentiate by product? | **Yes** — `OD_Fuel_Pricing_Products` scoping |
| Can rules differentiate by terminal/vendor? | **Yes** — `OD_Fuel_Pricing_Origins` scoping |
| Can rules differentiate by customer location? | **Yes** — `OD_Fuel_Pricing_Locations` scoping |
| Is overlap deterministic? | **Yes** — rank-based, highest specificity wins |
| Does direct customer beat group? | **Yes** — 2000 > 1000 in rank scoring |
| Can rules be added to existing contracts? | **Yes** — new Description = new rule, no impact on existing |
| Can rules be updated without side effects? | **Yes, if full payload is always sent** |
| Can rules be removed? | **Not directly** — deactivate instead |

### Operational Pattern for CitySV

1. **Create 2-4 group contracts** for common pricing tiers (e.g., "Cost+45 Clear/Dyed", "Cost+25 Dyed Only")
2. **Assign customers to groups** via `Customer_Sales_Info.CustSls_CustContGrp_Key`
3. **Create direct contracts** only for customers with unique pricing
4. **Namespace all contracts** with `CITYSV-*` prefix
5. **Daily/weekly rule updates** via ODFPCI CSV — one file can update all rules across all contracts
6. **Pre-import validation:** query `OD_Fuel_Pricing_Rules` joined through contract details to verify no unintended overlap

### What This Means for Proxy Terminal

**Proxy terminal strategy is fully deprecated.** Contract-based pricing with the container model provides:
- Direct pricing authority (no terminal workaround)
- Rule-level granularity (product × location × origin)
- Deterministic resolution (rank-based, direct > group)
- Programmatic management (ODFPCI import)
- Scale efficiency (few containers, many rules)

### Remaining Work

| Item | Status |
|------|--------|
| Customer group assignment mechanism | Needs investigation — `Customer_Sales_Info` is DML, not importable via ODFPCI. May need direct SQL or a separate import program. |
| Rule-level status checking | Needs confirmation — does `ODFuelPrcRule_ContractQtyRuleDetails` enable/disable per-rule status? |
| Price_Basis value inventory | Only values 0 (rack) and 4 (cost+amount) observed. Need full enumeration for flexibility. |
| OnlyWhenLower interaction | When `CustFuelContDtl_OnlyWhenLower=1`, the engine duplicates order lines to compare contract vs standard pricing. Interaction with group contracts needs testing. |
