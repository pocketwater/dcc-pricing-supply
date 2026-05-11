# Wholesale Fuel Customer Pricing Contracts: Decision Brief

Date: 2026-04-11

> Audience: Mid-level managers
> Objective: Decide whether to move customer pricing onto the native ODFPC/ODFPCI lane

## Executive Recommendation (Aligned with Grain Lock)
Proceed with validation spike for ODFPC/ODFPCI as the preferred future path for customer pricing, but recognize that for the immediate _Orders_Upload refactor, the order-detail grain uses `CustomerFuelContractID` (already proven in native `Order_Details_Fuel` table and validated during ODIMP import).

The ODFPC/ODFPCI path is a FUTURE enhancement to replace/supplement the current `Customer_Fuel_Contracts` model; it does NOT affect the locked _Orders_Upload grammar.

## Bottom Line
This appears to be a cleaner and more native path than the current proxy-terminal/FIVC workaround for customer pricing maintained outside PDI.

**Current locked state:** _Orders_Upload uses `CustomerFuelContractID` which resolves to `Customer_Fuel_Contracts` (existing production table, already live in ODIMP).

**Future enhancement:** ODFPC/ODFPCI as a competing/replacement customer pricing mechanism. This is separate from the supply-side vendor fuel contract model, so supply-side and customer-side concerns remain distinct.

## What Is Confirmed
- Wholesale Fuel Customer Pricing Contracts is a first-class feature in PDI Enterprise 8.5+.
- The workflow exists end-to-end:
  - ODCCG: Customer contract groups
  - ODFPC / ODFPCP / ODFPCR: Contract profile and rules
  - ODFPCI: Fuel Pricing Contract Import
  - ODE: Contract application during order/quote entry
  - ODCR: Contract reporting
- Contract pricing takes precedence over standard and discount pricing rules.
- Customer-to-contract-group assignment is not effective-date driven; effective dates are handled by contract/profile.

## Why This Is Better Than the Current Pattern
- Aligns directly to customer pricing contract semantics.
- Avoids forcing customer pricing through vendor/terminal fuel contract artifacts.
- Reduces fragility from clone-chain joins and proxy terminal conventions.
- Improves supportability by staying on a native OD contract/import path.

## Current-State Friction (Evidence)
- Existing logic is vendor/FIVC-chain heavy and includes clone-hop translation.
- There is known ambiguity in vendor-to-fuel-contract mappings (fan-out/non-determinism).
- Proxy terminal behavior appears in planning/history artifacts.

## Key Caveat
ODFPCI existence and setup flow are confirmed, but full field-level import contract details are not yet confirmed from documentation alone:
- exact columns
- matching keys
- update/overwrite behavior
- exception handling behavior

## Recommended Validation Spike (Low Risk)
1. Build a minimal non-prod ODFPCI test import:
   - 2 to 3 customers
   - 1 customer-group contract
   - 1 direct-customer contract
2. Validate ODE precedence against existing standard/discount pricing.
3. Validate ODCR reporting visibility.
4. Re-run changed values to prove update semantics:
   - insert vs replace vs merge
   - effective-date overlap behavior
5. Capture exception outputs with intentional bad rows:
   - unknown customer
   - invalid product
   - bad date windows

## Migration Direction If Spike Passes
- Keep vendor fuel contracts for supply-side vendor/terminal logic.
- Move customer-specific deal pricing into customer pricing contracts (ODFPC/ODFPCI).
- Phase out proxy terminal ID usage for customer pricing publication.

## Success Criteria
- No proxy-terminal dependency for customer pricing loads.
- Deterministic customer pricing outcomes in ODE.
- Operators can audit pricing via ODCR without translation-chain debugging.
- Clear rollback path for contract import batches.

<div class="page"/>

## Production Discovery Addendum

Date: 2026-04-11 - Live read-only queries against `PDICompany_2386_01` on `PDI-SQL-01`.

### Current State: Proxy Terminal / Fuel_Costs Pattern (Confirmed Active)

| Metric | Value |
|---|---|
| Z-prefix proxy terminals in PDI | 2,462 |
| Proxy terminals with active Fuel_Costs rows | 1,518 |
| Total Fuel_Costs rows via proxy terminals | 3,429,708 |
| Earliest row | 2022-11-10 |
| Latest row | 2026-04-11 (today) |

Naming convention: `z{cust_id}{product_suffix}` - each is a synthetic terminal representing one customer/product combination.

Examples:
- `z875045100 Horizon Making/Othello P66`
- `z875367100 Yakima SD`
- `z9000491001 City of Malin`

The proxy terminal row is the live daily customer pricing write surface. `Fuel_Costs` is the current write target.

### ODFPC Contract State (Experimental, Not Operationally Active)

| Table | Rows | Note |
|---|---|---|
| `Customer_Contract_Groups` | 2 | One unnamed, one "Shell Branded" |
| `Customer_Fuel_Contracts` | 10 | All 2022/2024 experiments |
| `Customer_Fuel_Contract_Details` | 10 | All 2022/2024, all `Status=0` |
| `Customer_Fuel_Contract_Batches` | 0 | Never imported via ODFPCI |

All 10 contract headers are isolated experiments (individual customers: 442676, 238795, 867078, 867713, 867296, 867027, 867028, 867030, 867665; plus one Shell Branded group entry). None are in active commercial use.

### Customer_Fuel_Prices (OD Rule-Driven, Not Contract-Detail Pricing)

120 rows dated July 2025. All rows are tied to OD pricing rule keys (3761, 4234) via terminal WA4400. This is a separate OD-strategy experiment and is not part of the ODFPC contract mechanism being evaluated.

### Confirmed Separation of Concerns
The current proxy-terminal pattern and the ODFPC contract feature write to different tables and different pipelines.

They do not conflict structurally and could coexist during migration. The critical unknown for the spike is runtime behavior in ODE when both write paths are present for the same customer.
