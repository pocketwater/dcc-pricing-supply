# PDI Fuel_Formulas Deep Dive

**Date:** 2026-05-10 (Preliminary)
**Status:** Ontology capture in progress — requires live table validation on SQL-01
**Phase:** 9 — Custom Price Notice & Quote System

---

## Objective

Understand PDI's fuel_formulas semantics: how pricing basis, cost tiers, and adjustments interact to produce final prices. Build reusable ontology for custom pricing engine.

---

## 1. Fuel_Formulas Conceptual Model

### What Is a Formula?

A **fuel formula** is PDI's way of defining a pricing rule: **Cost Basis + Adjustment = Final Price**

```
Price = Cost_Basis + Adjustment
```

Where:
- **Cost_Basis**: The reference cost (e.g., rack cost, terminal cost, cost per grade)
- **Adjustment**: A modifier applied to the cost (e.g., + $0.45, + 10%, fixed amount, percentage)

### Price Basis Codes (Inferred from Briefs)

From the CustFuelContract briefs, we know:

| Price_Basis | Semantics | Example |
|-------------|-----------|---------|
| 0 | Rack cost (default reference) | Use terminal's published rack cost for product |
| 4 | Cost + fixed amount | Rack + $0.45/gal |
| ? | Cost + percentage | Rack + 5% |
| ? | Fixed price (ignore cost) | $2.15/gal flat |
| ? | Vendor/supplier cost | Cost from fuel supplier contract |

### Adjustment Methods (Inferred from Briefs)

| Adj_Method | Semantics |
|------------|-----------|
| 0 | No adjustment (baseline only) |
| 1 | Add fixed amount to basis |
| ? | Apply percentage markup to basis |
| ? | Subtract fixed amount (discount) |
| ? | Apply tiered discounts (volume-based) |

---

## 2. Schema Exploration (To Be Validated)

### Expected Tables (Hypothesis)

| Table | Purpose | Key Columns | Notes |
|-------|---------|-------------|-------|
| `Fuel_Formulas` | Formula header (if exists) | `Formula_Key`, `Formula_ID`, `Description`, `Price_Basis`, `Adj_Method` | **TBD: Does this table exist?** |
| `Fuel_Formulas_Lines` | Formula detail rows (if exists) | `FormulaLine_Key`, `Formula_Key`, `Product_Key`, `Amount` | **TBD** |
| `Fuel_Costs` | Terminal/vendor published costs (confirmed in briefs) | `Fuel_Cost_Key`, `Trmnl_Key`, `Prod_Key`, `Cost_Amount`, `Cost_Date` | **Confirmed active with 3.4M+ rows** |
| `Fuel_Cost_Basis_Types` | Reference table for cost basis codes | `Cost_Basis_Code`, `Cost_Basis_Description` | **TBD** |
| `OD_Fuel_Pricing_Rules` | Pricing rule (confirmed) | `ODFuelPrcRule_Key`, `Price_Basis`, `Adj_Method`, `Amount` | **Confirmed** |

### Data Access Pattern

```
Order Line (Product, Customer, Terminal, Date)
  → Resolve Cost_Basis (e.g., Rack = Fuel_Costs lookup)
  → Apply OD_Fuel_Pricing_Rule (Adj_Method + Amount)
  → Calculate Final Price
```

---

## 3. Ontology: Pricing Formula Semantics

### Pricing Decision Tree

```
Order arrives with: {Customer, Product, Terminal, Date, Volume}

Step 1: Resolve applicable Customer Fuel Contract
  ├─ Priority 1: Direct customer contract
  ├─ Priority 2: Contract group assignment
  └─ Result: Contract_Key (or NULL if none)

Step 2: Resolve applicable OD_Fuel_Pricing_Rule
  ├─ Product filter: Is order product covered by rule?
  ├─ Origin filter: Is terminal/vendor in rule's origin list?
  ├─ Customer location filter: Is location in rule's scope?
  └─ Result: Rule_Key + [Price_Basis, Adj_Method, Amount]

Step 3: Resolve Cost_Basis
  ├─ If Price_Basis = 0 (Rack):     Fuel_Costs[Terminal, Product, Date]
  ├─ If Price_Basis = 4 (Cost+amt): Fuel_Costs[Terminal, Product, Date]
  ├─ If Price_Basis = ? (Fixed):    Use rule's Amount directly (no lookup)
  └─ Result: Base_Cost

Step 4: Apply Adjustment
  ├─ If Adj_Method = 0 (None):      Price = Base_Cost
  ├─ If Adj_Method = 1 (Add):       Price = Base_Cost + Amount
  ├─ If Adj_Method = ? (Pct):       Price = Base_Cost * (1 + Amount%)
  └─ Result: Final_Price

Step 5: Apply Volume Tiers (if applicable)
  ├─ Query OD_Fuel_Pricing_Volumes for rule + volume bucket
  ├─ If tier found, override Final_Price with tier price
  └─ Result: Tiered_Price OR Final_Price
```

### Key Definitions

**Cost Basis:**
- The "reference point" for pricing calculations
- Examples: Rack cost, terminal published cost, vendor invoice cost, competitor index
- Basis is **not the final price**; it's a starting point

**Adjustment:**
- A modification applied to the cost basis
- Can be absolute ($/gallon) or relative (%)
- Captured as {method, amount} tuple

**Pricing Rule:**
- Binds a customer (direct or via group) to a formula
- Specifies product, origin, and location scopes
- Contains Price_Basis, Adj_Method, and Amount

**Volume Tiers:**
- Optional: override price based on order volume
- Example: Orders < 1,000 gal @ +$0.50; Orders >= 1,000 gal @ +$0.40

---

## 4. Existing References in Briefs

### From 01_CustFuelContract_Domain_Qualification_2026-04-15.md

**POC Example: Contract 10 (City of Sumas)**
```
Contract 10 → Detail 15 → Rule 18 "Clear/Gas"
  ├─ Price_Basis: 4 (Cost + amount)
  ├─ Adj_Method: 1 (Add amount to basis)
  ├─ Amount: 0.45 ($ 0.45/gal)
  ├─ Products: [1, 7] (two product IDs)
  └─ Result: Terminal Rack Cost + $0.45
```

### From 02_Wholesale_Fuel_Customer_Pricing_Contracts_Assessment_2026-04-11.md

**Production State: Proxy Terminals**
```
Active Pattern: Fuel_Costs rows (3.4M+) via proxy terminals (z{cust_id}{product})
  ├─ Each proxy terminal represents 1 customer + product combination
  ├─ Fuel_Costs contains daily cost updates for that customer/product
  ├─ This is the current write surface for customer pricing

ODFPC/ODFPCI (Experimental):
  ├─ 10 contract rows (all 2022/2024 experiments, none active)
  ├─ Shows schema is wired but not operationally used
```

### From 08_Price_Notice_Process_Domain_Qualification_2026-05-10.md

**Price Calculation in OD Flow**
```
OD_CalcPrices_ResolveFuelPricingRules_SP:
  ├─ Collects ALL candidate rules (multiple possible per order line)
  ├─ Ranks by: Location match (3000) > Customer (2000) > Group (1000) > Product (200) > Vendor (50) > Terminal (10)
  ├─ Selects MAX(rank) rule
  ├─ Applies rule's [Price_Basis, Adj_Method, Amount] to order
  └─ Stores in Order_Details_Fuel.OrdFuel_Price
```

---

## 5. Open Questions (Validation Needed)

### Schema Questions
1. Does a `Fuel_Formulas` table exist, or are formulas only implicit in OD_Fuel_Pricing_Rules?
2. What are the exact Price_Basis codes used in production? (0 = rack?, 4 = cost+amt, others?)
3. What are the exact Adj_Method codes? (0 = none, 1 = add, others?)
4. Is there a `Fuel_Cost_Basis_Types` reference table, or are these magic numbers?
5. What is the relationship between Fuel_Costs table and OD_Fuel_Pricing_Rules? (lookup or direct value?)

### Semantics Questions
6. When Price_Basis = 4 (Cost+Amount), does Amount always mean $/gallon, or can it be percentage?
7. Can Adj_Method = percentage? If so, is it 5 = 5%, or 0.05 = 5%?
8. How do volume tiers interact with price basis/adjustment? (Is tier price absolute or applied after adjustment?)
9. What happens if no cost basis row is found (e.g., terminal down, product not tracked)? Default? Error?
10. Are there historical cost tables (e.g., prior month's rack cost for audit)?

### Integration Questions
11. Is the proxy terminal pattern (z-prefix) deprecated in favor of ODFPC contracts, or is it a permanent dual system?
12. How does a custom system (external) integrate with Fuel_Costs updates? (Does PDI accept writes to Fuel_Costs, or is it read-only?)
13. If we build custom pricing logic externally, do we need to replicate Fuel_Formulas semantics exactly, or can we simplify?

---

## 6. Planned Validation (Next Session)

### Live Probes (PDI-SQL-01)

```sql
-- 1. Discover fuel_formulas related tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
  AND (TABLE_NAME LIKE '%Formula%' OR TABLE_NAME LIKE '%Basis%' OR TABLE_NAME LIKE '%Fuel_Cost%')
ORDER BY TABLE_NAME;

-- 2. Sample Fuel_Costs structure and content
SELECT TOP 5 * FROM Fuel_Costs ORDER BY Fuel_Cost_Date DESC;

-- 3. Sample OD_Fuel_Pricing_Rules structure
SELECT TOP 3
  ODFuelPrcRule_Key,
  ODFuelPrcRule_Description,
  Price_Basis,
  Adj_Method,
  Amount
FROM OD_Fuel_Pricing_Rules;

-- 4. Check for Fuel_Cost_Basis_Types reference table
SELECT * FROM Fuel_Cost_Basis_Types (if exists);

-- 5. Examine a live order's price calculation
SELECT TOP 1
  Ord_Key,
  OrdFuel_Price,
  OrdFuel_Product_Key,
  OrdFuel_CustFuelCont_Key,
  OrdFuel_Trmnl_Key
FROM Order_Details_Fuel
WHERE OrdFuel_Price IS NOT NULL
ORDER BY OrdFuel_Create_Date DESC;

-- 6. Sample rule with products and origins
SELECT
  r.ODFuelPrcRule_Key,
  r.Price_Basis,
  r.Adj_Method,
  r.Amount,
  COUNT(DISTINCT p.ODFuelPrcProd_Product_ID) AS ProductCount,
  COUNT(DISTINCT o.ODFuelPrcOrigin_Key) AS OriginCount
FROM OD_Fuel_Pricing_Rules r
LEFT JOIN OD_Fuel_Pricing_Products p ON r.ODFuelPrcRule_Key = p.ODFuelPrcProd_ODFuelPrcRule_Key
LEFT JOIN OD_Fuel_Pricing_Origins o ON r.ODFuelPrcRule_Key = o.ODFuelPrcOrigin_ODFuelPrcRule_Key
GROUP BY r.ODFuelPrcRule_Key, r.Price_Basis, r.Adj_Method, r.Amount
LIMIT 10;
```

### Stored Procedures to Review
- `OD_CalcPrices_ResolveFuelPricingRules_SP` (main pricing engine)
- `OD_CalcOrder_SP` (order price calc wrapper)
- `OD_GetEffectiveCustFuelContracts_SP` (contract resolution)

### Documentation to Locate
- PDI Admin manual section on "Price Basis Codes" (if exists)
- PDI Fuel Pricing Rules user guide (look in dcc-pricing-supply docs)
- Any internal Coleman Oil notes on fuel_formulas mapping

---

## 7. Custom Pricing Engine Requirements

Once validation is complete, the custom pricing engine must support:

1. **Cost Basis Resolution**
   - Input: {Terminal, Product, Date}
   - Output: Cost amount (from Fuel_Costs or other source)
   - Fallback: None (error if not found, or use fallback cost?)

2. **Rule Matching**
   - Input: {Customer, Product, Terminal, Date, Volume, Location}
   - Output: {Price_Basis, Adj_Method, Amount} or NULL
   - Logic: Replicate PDI's ranking engine (location > customer > group > product > vendor > terminal)

3. **Price Calculation**
   - Input: {Cost, Price_Basis, Adj_Method, Amount, Volume}
   - Output: Final price per gallon
   - Support: All price basis and adjustment method combinations

4. **Volume Tier Lookup** (optional, v1)
   - Input: {Rule_Key, Volume}
   - Output: Tiered price or NULL
   - Fallback: Use base price if no tier matches

5. **Audit Logging**
   - Log all price calculations with: Rule ID, Cost, Basis, Adjustment, Final Price, Timestamp
   - Enable reverse-engineering: "Why did this order get price X?"

---

## 8. Integration with Clone System

Once ontology is locked, `pdi-clone-core` procedures should replicate:

- `Fuel_Costs` (read-only, daily or on-demand sync)
- `OD_Fuel_Pricing_Rules` hierarchy (all child tables)
- Reference tables: Products, Terminals, Vendors, Cost_Basis_Types (if exists)

---

## Next Steps
1. Run SQL probes on PDI-SQL-01 to validate schema and semantics
2. Review OD_CalcPrices_ResolveFuelPricingRules_SP stored proc for exact logic
3. Capture magic numbers (Price_Basis codes, Adj_Method codes) into reference table
4. Build prototype custom pricing engine (start with simple: basis + fixed adjustment)
5. Test against live order samples: Does custom engine produce same price as PDI?

---

*This document will be updated as validation progresses. All questions in Section 5 are priorities for next session.*
