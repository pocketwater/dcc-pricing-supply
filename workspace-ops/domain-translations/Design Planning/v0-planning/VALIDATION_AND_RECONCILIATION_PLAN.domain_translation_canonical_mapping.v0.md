# VALIDATION_AND_RECONCILIATION_PLAN

## Purpose
Define side-by-side testing, uniqueness checks, ambiguous-match detection, and parity validation between the new Xref_Registry / contract views and the legacy CITT tables while legacy surfaces remain operational.

## Grain Contract
- Grain In: Build Specification, Pipeline Consumption Contracts, Domain Contract Specs.
- Grain Out: Validation-ready test matrix and reconciliation plan sufficient for Validator-stage execution.

## Translation Requirements
- Validation must confirm that `_ID` derivation via live join produces the same values that CITT tables previously cached.
- Validation must enforce dependency safety: no freeze/deprecate/retire action may proceed until all consuming repo references are migrated and validated.

## Ontological Assumptions
- CITT tables are available in parallel during the validation window.
- PDI clone data is current and consistent at validation time.
- Confidence note: high (8/10) for parity test structure; medium (6/10) for timing — dependent on build completion and clone data availability.

---

## Validation Categories

### Category 1: Structure and Constraint Validation
Confirm the registry and governed dimension tables are built correctly.

| Test | Pass Condition |
|---|---|
| All governed dimension FK constraints active | No FK violation on insert of valid dimension values |
| CK_Xref_Registry_ActiveStatus enforced | Cannot set Is_Active = 1 with Resolution_Status != ACTIVE |
| Unique index active | Cannot insert two ACTIVE rows with same composite key |
| Trigger rejects untrimmed Source_Key inputs | Insert with leading/trailing whitespace raises error and rolls back |
| Composite_Hash computed correctly | Hash for known test inputs matches expected SHA2_256 value |

---

### Category 2: Seeding and Lifecycle Validation
Confirm the seed process and lifecycle state machine work correctly.

| Test | Pass Condition |
|---|---|
| Seed rows default to UNRESOLVED, Is_Active = 0 | All bulk-seeded rows have correct defaults |
| Cannot activate without Target_Key for PDI rows | Attempt to set ACTIVE on PDI-target row with NULL Target_Key is blocked |
| REVIEW_REQUIRED → ACTIVE transition records Updated_By and Updated_Dtm | Audit columns populated on approve action |
| ACTIVE → RETIRED transition sets Is_Active = 0 | Is_Active = 0 after retire; Resolution_Status = RETIRED |
| Retired row excluded from all pipeline contract views | Retired rows do not appear in any view output |

---

### Category 3: Pipeline View Validation
Confirm contract views return expected output and blocking behavior is correct.

| Test | Pass Condition |
|---|---|
| Single active mapping for test input | View returns exactly 1 row |
| No active mapping for test input | View returns 0 rows (pipeline must BLOCK) |
| Two active mappings for same input (forced conflict) | Unique index prevents this; test confirms constraint fires |
| Inactive mapping for test input | View returns 0 rows (Is_Active filter excludes it) |
| PDI-target view: `_ID` matches current clone value | Live-derived _ID equals current clone row _ID for same Key |
| Non-PDI target view: Target_Code returned correctly | View exposes correct code for test mapping |

---

### Category 4: CITT Parity Validation (Critical Path)
For each CITT table in migration scope: confirm new views produce identical output.

**Method:**
```sql
-- For each domain/source/target combination:
-- Compare new view output vs CITT table for same source input
SELECT
      c.source_column       AS CITT_Source
    , c.target_id_column    AS CITT_Target_ID
    , v.PDI_FuelProd_ID     AS New_Target_ID   -- example for Product domain
    , CASE
        WHEN c.target_id_column = v.PDI_FuelProd_ID THEN 'MATCH'
        ELSE 'MISMATCH'
      END AS Parity_Result
FROM [CITT_Table] c
LEFT JOIN dbo.vw_Xref_Product_Gravitate_To_PDI v
    ON c.source_column = v.Source_Key_1
ORDER BY Parity_Result DESC;
```

**Pass Condition:** Zero MISMATCH rows for all in-scope inputs.
**Action on MISMATCH:** Treat as BLOCK. Do not proceed to cutover until all mismatches are resolved or explained (for example legitimate CITT stale data that the new registry has corrected).

---

### Category 5: Uniqueness and Ambiguity Checks
Confirm no duplicate or ambiguous active mappings exist post-seed.

```sql
-- Detect duplicate active mappings (should return 0 rows after unique index)
SELECT
      Domain_Name, Source_System, Target_System, Target_Channel, Composite_Hash
    , COUNT(*) AS Active_Count
FROM  dbo.Xref_Registry
WHERE Is_Active = 1
GROUP BY Domain_Name, Source_System, Target_System, Target_Channel, Composite_Hash
HAVING COUNT(*) > 1;

-- Detect UNRESOLVED rows still in queue
SELECT COUNT(*) AS Unresolved_Count
FROM   dbo.Xref_Registry
WHERE  Resolution_Status = 'UNRESOLVED';

-- Detect REVIEW_REQUIRED rows still pending
SELECT COUNT(*) AS Pending_Review_Count
FROM   dbo.Xref_Registry
WHERE  Resolution_Status = 'REVIEW_REQUIRED';
```

---

## Reconciliation Decision Matrix

| Result | Action |
|---|---|
| All structure checks PASS | Proceed to parity validation |
| CITT parity MATCH for all rows | Proceed to cutover planning |
| CITT parity MISMATCH detected | Document each mismatch; determine if CITT was stale or new registry has an error; resolve before cutover |
| Uniqueness violations | Fix data before proceed; treat as BLOCK |
| UNRESOLVED count > 0 | Queue remaining rows for steward; cutover requires zero UNRESOLVED for in-scope domains |

---

## Blocking Issues For Cutover
Cutover must be blocked until:
- Zero CITT parity mismatches that are unexplained.
- Zero uniqueness violations.
- Zero UNRESOLVED rows for domains included in this release cycle.
- All pipeline contract views confirmed deployed and query-tested.
- Sandbox company validation evidence collected per runbook requirement.
- Cross-workspace dependency audit confirms no un-migrated consumers on shared legacy translation surfaces (CitySV, OPIS, DTN, and other production dependencies).

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Validation planning is a design-stage planning artifact, not a reusable execution skill.
