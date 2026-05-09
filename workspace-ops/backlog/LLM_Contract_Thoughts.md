# LLM_Contract_Thoughts

## Always test output frequently
- Build orders should always include human check points at every key business build phase. Human's need to see the shape and the values to correct course and insure build is aligned with intent.

## Coleman Oil is my employer and our solutions are in line with its corporate interests.
- Abbreviations for Coleman oil include "COIL" and "CMNO"

## A unit of operations work at COIL is a "load" as in a "load of fuel".
- "Load" by itself may be decieving depending on business context.
- A "full load" reffers to a full truck and trailer of fuel. This translates roughly to 10,000 gallons of fuel depending on compartment product payload.

## A "site" typically refers to a company owned fuel destination.
    - Examples "bulk plant", "cardlock"

## SIIMPS
    - PDI's SIIMPS process is a user interface to build schema compliant.

## PDI Enterprise Context

- **PDI Enterprise** is Coleman Oil’s back-office ERP system.
- The production database (`PDICompany_2386_01`) resides on server **PDI-SQL-01**.

### PDI Key Naming Conventions

- Columns ending in **`_Key`**
  - Represent **surrogate primary keys**
  - Integer identity columns
  - Used for joins and relational integrity within PDI

- Columns ending in **`_ID`**
  - Represent **business identifier codes**
  - Human-readable or externally sourced values
  - Used for integration, matching, and business logic

### PDI Builder Guidance

- Always join on `_Key` columns when working **within PDI tables**
- Use `_ID` columns when:
  - integrating external data (Axxis, DTN, etc.)
  - constructing business-facing identifiers (e.g., `Trmnl_ID`)
- Do **not** assume `_ID` values are unique unless explicitly documented
---
## PETE ORDER -- ADOPT LLM-FRIENDLY SQL NAMING STANDARD (v1 — LOCKED)

We are formalizing a naming standard to reduce semantic drift and improve both human and LLM reasoning across the CitySV schema.

This is not optional going forward.

---

## Objective

All SQL objects must carry enough meaning in their names to answer:

* what domain this belongs to
* what layer/purpose it serves
* what the row grain is (when relevant)
* what time/status semantics apply

If a name cannot answer most of those, it is not acceptable.

---

## 1. Object Naming Pattern (REQUIRED)

### Tables

```text
[Domain]_[Subdomain]_[Entity/Purpose]
```

Examples:

* `CitySV_Axxis_Prices_Fact`
* `CitySV_Axxis_Prices_AcctDest`
* `CitySV_Axxis_Prices_AcctDest_STP`
* `CitySV_Axxis_Prices_Publish_Grain_Map`

---

### Views

```text
vw_[Domain]_[Subdomain]_[Purpose]_[Qualifier]
```

Examples:

* `vw_CitySV_Axxis_Prices_Publish_Candidate`
* `vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice`
* `vw_CitySV_Axxis_Prices_Fact_Latest_ByAcctDestSTP`

---

### Stored Procedures

```text
sp_[Domain]_[Subdomain]_[Action]_[Qualifier]
```

Examples:

* `sp_CitySV_Axxis_Prices_FACT_REFRESH`
* `sp_CitySV_Axxis_Prices_VALIDATE_REFRESH`
* `sp_CitySV_Axxis_Prices_PUBLISH_EXECUTE`

---

## 2. Domain Prefix (REQUIRED)

* All objects must begin with domain context
* Example: `CitySV_Axxis_Prices_...`

Do not invert or omit domain.

---

## 3. Layer / Purpose Naming (REQUIRED)

Use explicit layer words:

Allowed:

* `Raw`
* `Reject`
* `Typed`
* `Fact`
* `History`
* `Snapshot`
* `Resolve`
* `Publish`
* `Validate`
* `Clone`
* `Map`
* `Ledger`
* `Intent`
* `Batch_Summary`

Avoid vague terms unless explicitly defined:

* `Base`
* `Final`
* `Dataset`
* `Output`

---

## 4. Grain Visibility (REQUIRED WHEN NON-OBVIOUS)

If row grain is not obvious, encode it in the name.

Use:

* `_BySTP`
* `_ByAcctDest`
* `_ByAcctDestSTP`
* `_ByPublishGrain`
* `_ByBatch`

Examples:

* `vw_CitySV_Axxis_Prices_Fact_Latest_ByAcctDestSTP`
* `vw_CitySV_Axxis_Prices_Resolve_Summary_ByAcctDest`

---

## 5. Time/Status Words (STRICTLY CONTROLLED)

These words are high-risk and must follow strict meaning:

* **Latest** = one row per grain ranked by defined business rule
* **Current** = active under current effective-date logic
* **Active** = explicitly flagged active
* **Final** = terminal pipeline output (not “latest version”)
* **Effective** = business-effective timing (not ingest time)

If used, the ranking or logic must be documented.

---

## 6. Date/Time Column Naming (MANDATORY UPGRADE)

Do not rely on ambiguous fields like:

* `Eff_Date`
* `Eff_Time`
* `QuoteEffDate`

Instead use business-meaning names:

Examples:

* `Source_Eff_Dtm`
* `Publish_Eff_Dtm`
* `Batch_Load_Dtm`
* `Ingest_Dtm`
* `Analyst_Decision_Dtm`

### Rule

If two date fields can be confused, rename one or both.

---

## 7. Key Naming (LOCKED)

### Surrogate keys

```text
[Entity]_Key
```

Examples:

* `STP_Key`
* `AcctDest_Key`
* `AcctDest_STP_Key`

### Business IDs

```text
[Entity]_ID
```

Examples:

* `Cust_ID`
* `CustLoc_ID`

Do not mix `ID`, `Key`, `Code`, `Number` inconsistently.

---

## 8. Bridge / Map Naming

Objects translating between grains must be explicit.

Use:

* `_Map`
* `_Bridge`
* `_Xref`

Examples:

* `CitySV_Axxis_Prices_AcctDest_Customer_Map`
* `vw_CitySV_Axxis_Prices_Customer_Bridge_Current`

---

## 9. Status Naming (NO OVERLOADING)

Do not use generic `Status`.

Instead use:

* `Validation_Status`
* `Processing_Status`
* `Expectation`
* `Disposition`

Each must represent a single concept.

---

## 10. Approved Suffix Vocabulary (LOCKED)

Use consistently:

* `_LU`
* `_Map`
* `_Bridge`
* `_Fact`
* `_History`
* `_Snapshot`
* `_Ledger`
* `_Current`
* `_Latest`
* `_Summary`
* `_Diagnostics`
* `_Inbox`
* `_Candidate`
* `_Upload`
* `_Clone`

Do not invent synonyms unless necessary.

---

## 11. Numeric Prefixes (EXPLICITLY FORBIDDEN IN SQL OBJECTS)

Do NOT use:

```text
000001_tbl...
000002_vw...
```

Reason:

* adds noise
* does not improve semantic understanding
* creates maintenance overhead

### Allowed use

Numeric sequencing is allowed ONLY in:

* playbooks
* manifests
* repo folders
* pipeline stage labels

Example:

* `10_Extract`
* `20_Typed`
* `30_Fact`
* `40_Resolve`
* `50_Publish`

---

## 12. Thin Truth-Layer Views (REQUIRED PATTERN)

When logic is reused or complex, promote it to a named view.

Examples:

* `vw_CitySV_Axxis_Prices_Fact_Latest_ByAcctDestSTP`
* `vw_CitySV_Axxis_Prices_Customer_Bridge_Current`

Purpose:

* reduce repeated logic
* stabilize joins
* improve readability and LLM accuracy

---

## 13. Manifest Contract (MANDATORY)

For each major object, the manifest must include:

* ObjectName
* Purpose
* RowGrain
* PrimaryJoinKey
* AuthoritativeDateField
* DateFieldMeaning
* StatusFieldMeaning
* Layer
* UsageType (Diagnostic / Operational / Publish)

No object is considered “complete” without this.

---

## 14. Immediate Action

1. Review current Prices objects and identify violations of this standard
2. Propose renames where:

   * grain is unclear
   * date semantics are ambiguous
   * vague terms are used
3. Do NOT rename blindly — return proposals first

---

## 15. Intent

We are not optimizing for naming aesthetics.

We are optimizing for:

* correct business meaning
* safe downstream usage
* reduced semantic drift
* faster, more reliable LLM collaboration

Return with:

* list of current objects needing rename or clarification
* proposed corrected names
* any conflicts or edge cases

No implementation yet. Proposal only.
---
