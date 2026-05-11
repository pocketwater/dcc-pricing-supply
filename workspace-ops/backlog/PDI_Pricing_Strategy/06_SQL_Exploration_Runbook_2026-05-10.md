# PDI Fuel_Formulas SQL Exploration Runbook

**Date:** 2026-05-10
**Target:** PDI-SQL-01, Database: PDICompany_2386_01
**Purpose:** Direct SQL validation of fuel_formulas schema and pricing logic

---

## Session Overview

Execute the following SQL queries **directly on SQL-01** to validate:
1. Schema discovery (what tables exist)
2. Structure and relationships
3. Live data samples
4. Stored procedure logic
5. Price calculation examples

**Recommended Tool:** SQL Server Management Studio (SSMS) on PDI-SQL-01, or direct T-SQL execution.

---

## Phase 1: Schema Discovery

### Query 1.1: Find all Fuel, Cost, and Basis tables

```sql
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS c
     WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA
       AND c.TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_SCHEMA = 'dbo'
  AND (TABLE_NAME LIKE '%Fuel%'
       OR TABLE_NAME LIKE '%Formula%'
       OR TABLE_NAME LIKE '%Cost%'
       OR TABLE_NAME LIKE '%Basis%'
       OR TABLE_NAME LIKE '%Price%')
ORDER BY TABLE_NAME;
```

**Expected Output:** 20–40 rows (list all pricing-related tables)

---

### Query 1.2: Specifically look for Fuel_Formulas and Fuel_Costs

```sql
SELECT TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME IN ('Fuel_Formulas', 'Fuel_Costs', 'Fuel_Cost_Basis_Types', 'Fuel_Cost_History')
ORDER BY TABLE_NAME;
```

**Expected Output:** Confirms which of these core tables exist in this tenant.

---

### Query 1.3: Search for any table with "Formula" in the name

```sql
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME LIKE '%[Ff]ormula%'
ORDER BY TABLE_NAME;
```

**Expected Output:** May reveal `Fuel_Formulas`, `OD_Fuel_Pricing_Formulas`, or other formula-related tables.

---

## Phase 2: Table Structure

### Query 2.1: Fuel_Costs table structure

```sql
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Fuel_Costs'
ORDER BY ORDINAL_POSITION;
```

**Expected Columns:** `Fuel_Cost_Key`, `Fuel_Cost_Date`, `Trmnl_Key`, `Prod_Key`, `Cost_Amount`, possibly others like `Cost_UOM`, `Basis_Type`, `Vend_Key`.

---

### Query 2.2: OD_Fuel_Pricing_Rules table structure

```sql
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'OD_Fuel_Pricing_Rules'
ORDER BY ORDINAL_POSITION;
```

**Expected Columns:** `ODFuelPrcRule_Key`, `Price_Basis`, `Adj_Method`, `Amount`, and 40+ other columns.

---

### Query 2.3: Look for Fuel_Cost_Basis_Types reference table

```sql
SELECT * FROM Fuel_Cost_Basis_Types;
```

**Expected Output:** Reference data mapping `Cost_Basis_Code` to description (e.g., 0=Rack, 4=Cost+Amount, etc.).

---

## Phase 3: Live Data Samples

### Query 3.1: Sample Fuel_Costs (most recent)

```sql
SELECT TOP 10
    Fuel_Cost_Key,
    Fuel_Cost_Date,
    Trmnl_Key,
    Prod_Key,
    Cost_Amount
FROM Fuel_Costs
ORDER BY Fuel_Cost_Date DESC, Trmnl_Key, Prod_Key;
```

**Expected Output:** Recent cost records. Look for:
- Date range coverage
- Terminal/product distribution
- Cost values (reasonable range for fuel)

---

### Query 3.2: Sample OD_Fuel_Pricing_Rules

```sql
SELECT TOP 5
    ODFuelPrcRule_Key,
    ODFuelPrcRule_Description,
    Price_Basis,
    Adj_Method,
    Amount
FROM OD_Fuel_Pricing_Rules
ORDER BY ODFuelPrcRule_Key DESC;
```

**Expected Output:** Recent or active rules. Note:
- Range of Price_Basis values (0, 4, others?)
- Range of Adj_Method values (0, 1, others?)
- Amount values (dollars, percentages?)

---

### Query 3.3: Sample Order_Details_Fuel with prices

```sql
SELECT TOP 10
    Ord_Key,
    OrdFuel_Price,
    OrdFuel_Product_Key,
    OrdFuel_CustFuelCont_Key,
    OrdFuel_Trmnl_Key,
    OrdFuel_Create_Date
FROM Order_Details_Fuel
WHERE OrdFuel_Price IS NOT NULL
ORDER BY OrdFuel_Create_Date DESC;
```

**Expected Output:** Recent orders with calculated prices. Shows what the final price looks like on a real order.

---

## Phase 4: Rule Scoping and Relationships

### Query 4.1: OD_Fuel_Pricing_Rules with product count

```sql
SELECT
    r.ODFuelPrcRule_Key,
    r.ODFuelPrcRule_Description,
    r.Price_Basis,
    r.Adj_Method,
    r.Amount,
    COUNT(DISTINCT p.ODFuelPrcProd_Product_ID) AS ProductCount,
    COUNT(DISTINCT l.ODFuelPrcLoc_CustLoc_ID) AS LocationCount,
    COUNT(DISTINCT o.ODFuelPrcOrigin_Key) AS OriginCount
FROM OD_Fuel_Pricing_Rules r
LEFT JOIN OD_Fuel_Pricing_Products p ON r.ODFuelPrcRule_Key = p.ODFuelPrcProd_ODFuelPrcRule_Key
LEFT JOIN OD_Fuel_Pricing_Locations l ON r.ODFuelPrcRule_Key = l.ODFuelPrcLoc_ODFuelPrcRule_Key
LEFT JOIN OD_Fuel_Pricing_Origins o ON r.ODFuelPrcRule_Key = o.ODFuelPrcOrigin_ODFuelPrcRule_Key
GROUP BY
    r.ODFuelPrcRule_Key,
    r.ODFuelPrcRule_Description,
    r.Price_Basis,
    r.Adj_Method,
    r.Amount
ORDER BY r.ODFuelPrcRule_Key DESC;
```

**Expected Output:** Shows rule scoping complexity (how many products, locations, origins per rule). Helps understand if rules are broad or narrow.

---

### Query 4.2: Expand one rule to see full scope

```sql
DECLARE @RuleKey INT = 18;  -- Change to any actual rule key

SELECT
    'Rule' AS EntityType,
    r.ODFuelPrcRule_Key,
    r.ODFuelPrcRule_Description,
    r.Price_Basis,
    r.Adj_Method,
    r.Amount,
    NULL AS ScopeValue
FROM OD_Fuel_Pricing_Rules r
WHERE r.ODFuelPrcRule_Key = @RuleKey

UNION ALL

SELECT
    'Product' AS EntityType,
    @RuleKey,
    'Product',
    NULL,
    NULL,
    NULL,
    CAST(p.ODFuelPrcProd_Product_ID AS VARCHAR(50))
FROM OD_Fuel_Pricing_Products p
WHERE p.ODFuelPrcProd_ODFuelPrcRule_Key = @RuleKey

UNION ALL

SELECT
    'Location' AS EntityType,
    @RuleKey,
    'Location',
    NULL,
    NULL,
    NULL,
    CAST(l.ODFuelPrcLoc_CustLoc_ID AS VARCHAR(50))
FROM OD_Fuel_Pricing_Locations l
WHERE l.ODFuelPrcLoc_ODFuelPrcRule_Key = @RuleKey

UNION ALL

SELECT
    'Origin' AS EntityType,
    @RuleKey,
    'Origin',
    NULL,
    NULL,
    NULL,
    CONCAT(o.ODFuelPrcOrigin_Type, ':',
           COALESCE(CAST(o.ODFuelPrcOrigin_Vendor_Key AS VARCHAR(20)),
                   CAST(o.ODFuelPrcOrigin_Terminal_Key AS VARCHAR(20)),
                   CAST(o.ODFuelPrcOrigin_FuelCont_Key AS VARCHAR(20)),
                   'N/A'))
FROM OD_Fuel_Pricing_Origins o
WHERE o.ODFuelPrcOrigin_ODFuelPrcRule_Key = @RuleKey

ORDER BY EntityType, ScopeValue;
```

**Expected Output:** Full scope of one rule (products, locations, origins). Shows the structure and complexity.

---

## Phase 5: Pricing Calculation Walkthrough

### Query 5.1: Pick a real order and trace its pricing

```sql
DECLARE @OrdKey INT = (SELECT TOP 1 Ord_Key FROM Orders WHERE Ord_Key > 0 ORDER BY Ord_Create_Date DESC);

-- The order itself
SELECT
    o.Ord_Key,
    o.Ord_No,
    o.Ord_Cust_Key,
    o.Ord_CustLoc_Key,
    CONVERT(DATE, o.Ord_Create_Date) AS OrderDate
FROM Orders o
WHERE o.Ord_Key = @OrdKey;

-- Order details (fuel lines)
SELECT
    of.OrdFuel_Key,
    of.OrdFuel_Product_Key,
    of.OrdFuel_Price,
    of.OrdFuel_Qty,
    of.OrdFuel_CustFuelCont_Key,
    of.OrdFuel_Trmnl_Key
FROM Order_Details_Fuel of
WHERE of.OrdFuel_Ord_Key = @OrdKey;

-- Customer info
SELECT
    c.Cust_Key,
    c.Cust_ID,
    c.Cust_Name
FROM Customers c
WHERE c.Cust_Key = (SELECT Ord_Cust_Key FROM Orders WHERE Ord_Key = @OrdKey);
```

**Expected Output:** Shows an order, its fuel lines, and the customer. Use `OrdFuel_Price` value as the reference for validation.

---

### Query 5.2: Reverse-engineer the contract and rule that produced the price

```sql
DECLARE @OrdFuelKey INT = (SELECT TOP 1 OrdFuel_Key FROM Order_Details_Fuel WHERE OrdFuel_Price IS NOT NULL ORDER BY OrdFuel_Create_Date DESC);

SELECT
    of.OrdFuel_Key,
    of.OrdFuel_Price,
    of.OrdFuel_CustFuelCont_Key,
    cfc.CustFuelCont_ID,
    cfcd.CustFuelContDtl_Effective_DateTime,
    cfcd.CustFuelContDtl_Expiration_DateTime,
    r.ODFuelPrcRule_Key,
    r.ODFuelPrcRule_Description,
    r.Price_Basis,
    r.Adj_Method,
    r.Amount
FROM Order_Details_Fuel of
LEFT JOIN Customer_Fuel_Contracts cfc ON of.OrdFuel_CustFuelCont_Key = cfc.CustFuelCont_Key
LEFT JOIN Customer_Fuel_Contract_Details cfcd ON cfc.CustFuelCont_Key = cfcd.CustFuelContDtl_CustFuelCont_Key
LEFT JOIN OD_Fuel_Pricing_Rules r ON cfcd.CustFuelContDtl_Key = r.ODFuelPrcRule_CustFuelContDtl_Key
WHERE of.OrdFuel_Key = @OrdFuelKey;
```

**Expected Output:** Links the order price to the contract and rule that produced it. Shows the formula parameters.

---

### Query 5.3: Lookup the cost basis for that order

```sql
DECLARE @OrdFuelKey INT = (SELECT TOP 1 OrdFuel_Key FROM Order_Details_Fuel WHERE OrdFuel_Price IS NOT NULL ORDER BY OrdFuel_Create_Date DESC);

DECLARE @Trmnl_Key INT, @Prod_Key INT, @OrderDate DATE;

SELECT TOP 1
    @Trmnl_Key = of.OrdFuel_Trmnl_Key,
    @Prod_Key = of.OrdFuel_Product_Key,
    @OrderDate = CONVERT(DATE, of.OrdFuel_Create_Date)
FROM Order_Details_Fuel of
WHERE of.OrdFuel_Key = @OrdFuelKey;

-- Find the cost that would have been used
SELECT TOP 5
    fc.Fuel_Cost_Key,
    fc.Fuel_Cost_Date,
    fc.Trmnl_Key,
    fc.Prod_Key,
    fc.Cost_Amount,
    DATEDIFF(DAY, fc.Fuel_Cost_Date, @OrderDate) AS DaysBefore
FROM Fuel_Costs fc
WHERE fc.Trmnl_Key = @Trmnl_Key
  AND fc.Prod_Key = @Prod_Key
  AND fc.Fuel_Cost_Date <= @OrderDate
ORDER BY fc.Fuel_Cost_Date DESC;
```

**Expected Output:** Shows the cost basis that would have been used to calculate the order price. Helps validate the pricing formula.

---

## Phase 6: Reference Data

### Query 6.1: All unique Price_Basis values in use

```sql
SELECT DISTINCT Price_Basis, COUNT(*) AS RuleCount
FROM OD_Fuel_Pricing_Rules
GROUP BY Price_Basis
ORDER BY Price_Basis;
```

**Expected Output:** Shows which price basis codes are actually used. Answer: What are the numeric codes for each basis type?

---

### Query 6.2: All unique Adj_Method values in use

```sql
SELECT DISTINCT Adj_Method, COUNT(*) AS RuleCount
FROM OD_Fuel_Pricing_Rules
GROUP BY Adj_Method
ORDER BY Adj_Method;
```

**Expected Output:** Shows which adjustment methods are used. Answer: What are the numeric codes for each method?

---

### Query 6.3: Products involved in fuel pricing

```sql
SELECT
    prod.Prod_Key,
    prod.Prod_ID,
    prod.Prod_Name,
    COUNT(DISTINCT r.ODFuelPrcRule_Key) AS RuleCount,
    COUNT(DISTINCT fc.Fuel_Cost_Key) AS CostRecordCount
FROM Products prod
LEFT JOIN OD_Fuel_Pricing_Products p ON prod.Prod_Key = p.ODFuelPrcProd_Product_ID
LEFT JOIN OD_Fuel_Pricing_Rules r ON p.ODFuelPrcProd_ODFuelPrcRule_Key = r.ODFuelPrcRule_Key
LEFT JOIN Fuel_Costs fc ON prod.Prod_Key = fc.Prod_Key
WHERE prod.Prod_Key IN (SELECT DISTINCT Prod_Key FROM Fuel_Costs)
GROUP BY prod.Prod_Key, prod.Prod_ID, prod.Prod_Name
ORDER BY RuleCount DESC, CostRecordCount DESC;
```

**Expected Output:** Which products have pricing rules and cost records. Helps prioritize which products the custom engine needs to support.

---

### Query 6.4: Terminals involved in fuel pricing

```sql
SELECT
    t.Trmnl_Key,
    t.Trmnl_ID,
    COUNT(DISTINCT fc.Fuel_Cost_Key) AS CostRecordCount,
    MIN(fc.Fuel_Cost_Date) AS EarliestCost,
    MAX(fc.Fuel_Cost_Date) AS LatestCost
FROM Terminals t
LEFT JOIN Fuel_Costs fc ON t.Trmnl_Key = fc.Trmnl_Key
WHERE t.Trmnl_Key IN (SELECT DISTINCT Trmnl_Key FROM Fuel_Costs)
GROUP BY t.Trmnl_Key, t.Trmnl_ID
ORDER BY CostRecordCount DESC;
```

**Expected Output:** Which terminals have fuel costs published. Shows geographic/operational distribution.

---

## Phase 7: Stored Procedure Analysis

### Query 7.1: List all pricing-related stored procedures

```sql
SELECT
    ROUTINE_SCHEMA,
    ROUTINE_NAME,
    ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'dbo'
  AND (ROUTINE_NAME LIKE '%Calc%Pric%'
       OR ROUTINE_NAME LIKE '%FuelPric%'
       OR ROUTINE_NAME LIKE '%Fuel_Cost%'
       OR ROUTINE_NAME LIKE '%Formula%')
ORDER BY ROUTINE_NAME;
```

**Expected Output:** All pricing calculation stored procedures. Key ones to review:
- `OD_CalcPrices_ResolveFuelPricingRules_SP`
- `OD_CalcOrder_SP`
- `OD_GetEffectiveCustFuelContracts_SP`

---

### Query 7.2: Get the source code of a pricing proc

```sql
-- Replace 'OD_CalcPrices_ResolveFuelPricingRules_SP' with the actual proc name
EXEC sp_helptext 'OD_CalcPrices_ResolveFuelPricingRules_SP';
```

**Expected Output:** Full T-SQL source of the pricing engine. **Critical for understanding the exact formula and ranking logic.**

---

## Execution Instructions

1. **Copy each query** from the sections above
2. **Execute on SQL-01** in SSMS or sqlcmd
3. **Capture results** in a text file or screenshot
4. **Document findings** in the corresponding sections of the fuel_formulas deep dive document
5. **Update open questions** with actual answers (replace ? with discovered values)

---

## Expected Discoveries

After running these queries, you should know:

✓ Which fuel_formulas tables exist
✓ The exact structure of Fuel_Costs and OD_Fuel_Pricing_Rules
✓ All Price_Basis codes and their meanings
✓ All Adj_Method codes and their meanings
✓ Real examples of rules with products, locations, and origins
✓ How a real order's price was calculated
✓ The cost basis lookup logic
✓ Which products and terminals are in scope
✓ The exact ranking logic used by OD_CalcPrices_ResolveFuelPricingRules_SP

---

## Document Updates

After execution, update `/PDI_Pricing_Strategy/05_PDI_Fuel_Formulas_Deep_Dive_2026-05-10.md`:

- Section 5 (Open Questions): Replace ? with discovered values
- Section 3 (Ontology): Add actual Price_Basis and Adj_Method mappings
- Section 7 (Custom Pricing Engine Requirements): Validate all 5 requirements against live data

---

*This runbook is designed for direct execution. Take your time; thorough discovery now prevents assumptions later.*
