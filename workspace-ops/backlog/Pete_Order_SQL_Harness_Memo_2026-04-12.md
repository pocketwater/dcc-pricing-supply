**Date:** 2026-04-12
**Status:** Builder memo — scripts delivered, decision pending
**Scope:** SQL harness for one mock fuel order through native ODIMP

---

## 1. Lookup Script — Delivered

**File:** `citysv-gravitate-pdi-ode/sql/tests/poc_pete_order_01_lookup.sql`

Single CTE chain that finds one valid combination:
- Active customer with active `CustomerFuelContractID` + effective detail at test lift date
- Customer location for that customer
- Active `ContractID` (Fuel_Contracts) + effective detail + vendor in junction
- Vendor + terminal resolved from that supply-side contract
- One active site, one active fuel product

Also delivered: `poc_pete_order_02_webpartner_lookup.sql` — separate because the `WebPartnerKey` is the #1 hard-stop unknown and may require a different permissions path.

Run both lookups first. Plug returned values into the execution script.

---

## 2. Staging Harness — Recommendation

**Recommendation: No staging layer at all.**

For a single mock order, the lightest path is direct string concatenation into an `ntext` variable. The proc consumes XML, not tables.

Rejected alternatives:
- **Temp tables / table variables:** Unnecessary indirection. The proc flattens XML into its own `#Orders` temp table internally. Building our own temp table just to serialize back to XML adds a round-trip with no benefit for one row.
- **CTEs:** Can't produce XML output naturally.
- **Permanent scratch tables:** Overkill for POC. Would be justified only if we're running dozens of test orders.

The execution script declares typed variables for each placeholder, then concatenates directly into the XML string. This is the minimum fussy path for one order.

---

## 3. Serializer — Delivered with Body-Verified Element Names

**File:** `citysv-gravitate-pdi-ode/sql/tests/poc_pete_order_03_execute.sql`

### XML hierarchy (proven)

```
PDIFuelOrders
  └─ PDIFuelOrder            ← header grain  (OPENXML: ../../)
       └─ FuelDetail          ← detail grain  (OPENXML: ../)
            └─ LoadDetail     ← load grain    (OPENXML: ./)
```

Proven from `OD_WS_ImportOrders_SP` lines 471–558.

### Element name verification status

| Element | XPath Level | Proc Line | Status |
|---------|-------------|-----------|--------|
| `DestinationType` | `../../` | 479 | **PROVEN** |
| `CustomerID` | `../../` | 480 | **PROVEN** |
| `CustomerLocationID` | `../../` | 481 | **PROVEN** |
| `SiteID` | `../../` | 484 | **PROVEN** |
| `PurchaseOrderNo` | `../../` | 485 | **PROVEN** |
| `DeliveryDateTime` | `../../` | 487 | **PROVEN** — single smalldatetime, not split |
| `LiftDateTime` | `../../` | 508 | **PROVEN** — header level |
| `OrderLineItemNo` | `../` | 515 | **PROVEN** — tinyint |
| `OrderedProductID` | `../` | 516 | **PROVEN** |
| `OrderedQuantity` | `../` | 525 | **PROVEN** |
| `CustomerFuelContractID` | `../` | 531 | **PROVEN** — varchar(15) |
| `LiftDateTime` | `./` | 544 | **PROVEN** — `LoadLiftDateTime` internal name |
| `LoadProductID` | `./` | 545 | **PROVEN** |
| `LiftGrossQuantity` | `./` | 547 | **PROVEN** |
| `LiftNetQuantity` | `./` | 546 | **PROVEN** |
| `OriginType` | `./` | 548 | **PROVEN** |
| `OriginVendorID` | `./` | 549 | **PROVEN** |
| `OriginTerminalID` | `./` | 550 | **PROVEN** |
| `BOLNo` | `./` | 555 | **PROVEN** |
| `ContractID` | `./` | 560 | **PROVEN** — varchar(50) |

### Critical finding: No `LoadSequence` element exists

The native XML schema has **no `LoadSequence` element**. Our locked grain model uses `OrderNo|OrderLineItemNo|LoadSequence` conceptually, but the import proc:
- Identifies loads positionally (by XML node order within `FuelDetail`)
- Optionally accepts `LoadNo` (a `decimal(15,0)` — line 241) for existing load matching
- For `@Action = 0` (new orders), `LoadNo` can be NULL — the proc sets `ImpOrd_Load_Provided = 0` and generates load identity internally

**Impact on POC:** None. For a single-load new order, this is transparent. For multi-load orders later, we'll need to understand how the proc assigns load identity.

### Where I am confident vs want to verify

**Confident:**
- All element names listed above are exact matches to OPENXML WITH clause
- XML is parsed via `sp_xml_preparedocument` + `OPENXML` (line 279)
- Empty string elements are coerced to NULL by the proc's CASE logic (line 380+)

**Want to verify (but not blocking):**
- Whether omitting optional nodes entirely (vs providing them empty) causes any validation error. Proc logic suggests omitted = NULL which is safe, but has not been tested.
- Whether `DeliveryDateTime` as `'2026-04-15 08:00'` string format parses correctly into `smalldatetime`. Standard SQL format should work, but OPENXML datetime parsing can be subtly format-sensitive.

---

## 4. Safe Execution Harness — Delivered

### Parameter choices

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `@WebPartnerKey` | From lookup | **Hard dependency.** Must resolve against `Web_Service_Profiles_OD` + `SI_WebServicePartners_GVW`. Controls all validation flags. |
| `@Action` | `0` | AddFuelOrder. Proven path for new order creation (line 2352). |
| `@TargetOrderStatus` | `2` (Open) | **Safest.** No billing promotion, no batch creation, no invoice generation. Order sits at Open and can be cancelled. Status 4 would trigger delivered-promotion validation; status 5 would trigger release-for-billing. |
| `@SkipLogging` | `0` | Keep logging on for traceability. |

### Risk reduction

- **PO number as tracer:** `POC-PETE-001` is used as `PurchaseOrderNo` so the order can be found immediately via `Ord_Cust_PO_No`.
- **BOL as tracer:** `POC-BOL-001` on load detail.
- **No OrderNo provided:** Letting the proc auto-assign avoids colliding with real order numbers.
- **Status 2 (Open):** Can be cancelled via status procedure or ODE UI without billing side effects.

### Post-execution inspection

Four inspection queries are in the execution script (Step 4):
1. Find order header by PO number
2. Check `Order_Details_Fuel` — verify `OrdFuel_CustFuelCont_Key` is populated
3. Check `Order_Fuel_Loads` — verify load was created
4. Check `Order_Fuel_Load_Details` — verify `LoadDtl_FuelCont_Key` is populated and BOL is on load

Plus a tempdb error check, with caveat that temp data may be cleaned up by the time you run it.

### Error capture

The proc itself returns a result set with order status and result codes:
- Result `0` = success
- Result `1` = success with warnings
- Result `2` = validation failure
- Result `3` = post failure

The SSMS Results pane will show this immediately after EXEC. If errors occur, the `tempdb..Import_Errors` table (if still populated) carries error descriptions.

---

## 5. Stop/Go Recommendation

**Recommendation: B then A.**

Do **one more targeted verification pass**, then proceed with native proc call.

### Why not straight to A

Two unknowns are cheap to resolve and expensive to debug if wrong:

1. **WebPartnerKey.** We have never queried for this. If no valid partner exists or the permissions boundary blocks the lookup, execution is dead on arrival. The lookup script is ready — run it first.

2. **DateTime format parsing.** The OPENXML parsing of `smalldatetime` from string values in XML is not tested. A 30-second test: take the OPENXML fragment from the proc, paste a minimal XML doc into a standalone test, and verify the datetime arrives correctly. If it arrives as NULL, we know to adjust format.

### Why not C

The evidence strongly supports A/B:
- We have the full OPENXML column list from the live proc body
- We have the exact EXEC signature
- We have the internal chain: Resolve → Validate → Post → Promote
- Both contract lanes are proven end-to-end with exact write targets
- The proc is a mature production path, not an experiment

Going to C (lower-level write chain) means abandoning the orchestrated path and replicating logic that PDI has already built. That's the opposite of the POC goal.

### Concrete next steps

1. Run `poc_pete_order_02_webpartner_lookup.sql` — get a valid `@WebPartnerKey` (5 minutes)
2. Run `poc_pete_order_01_lookup.sql` — get one valid test data combination (5 minutes)
3. *(Optional but recommended)* Test datetime format in a standalone OPENXML parse (5 minutes)
4. Fill placeholders in `poc_pete_order_03_execute.sql` with real values
5. Execute with `@TargetOrderStatus = 2`
6. Run inspection queries immediately after

---

## Files Delivered

| File | Location | Purpose |
|------|----------|---------|
| [poc_pete_order_01_lookup.sql](sql/tests/poc_pete_order_01_lookup.sql) | `citysv-gravitate-pdi-ode/sql/tests/` | Find valid test data combination |
| [poc_pete_order_02_webpartner_lookup.sql](sql/tests/poc_pete_order_02_webpartner_lookup.sql) | `citysv-gravitate-pdi-ode/sql/tests/` | Find valid WebPartnerKey |
| [poc_pete_order_03_execute.sql](sql/tests/poc_pete_order_03_execute.sql) | `citysv-gravitate-pdi-ode/sql/tests/` | XML assembly + execution + inspection |
