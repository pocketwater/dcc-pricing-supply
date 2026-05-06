# PHYSICAL_ARCHITECTURE_MEMO

## Purpose
Settle the final physical design direction for `dbo.Xref_Registry`: DDL patterns, index strategy, view definition patterns, and Consuming_Views JSON format. This memo is the authoritative pre-build design reference.

## Status
DRAFT — Pending Build-stage DDL formalization. All content is planning-grade.

## Grain Contract
- Grain In: Approved ADR, Stewardship Lifecycle Spec, Contracts stress-test brief.
- Grain Out: Build-ready physical architecture decisions and DDL guidance sufficient for the Build Specification.

## Translation Requirements
- This memo records physical implementation patterns for translation responsibilities. DDL must reflect ADR separation rules exactly.

## Ontological Assumptions
- SQL Server is the target platform (PDI_PricingLink).
- Computed persisted columns are supported and eligible for indexing.
- Confidence note: high (9/10) for schema and index direction; medium (7/10) for Consuming_Views JSON parsing tooling.

---

## Registry Table: `dbo.Xref_Registry`
See scoping brief Section 14 for the full DDL as the baseline. This memo records architectural decisions layered on top.

### Key Column Decisions

**Composite_Hash**
- Computed as `CONVERT(varchar(64), HASHBYTES('SHA2_256', ISNULL(Source_Key_1,'') + '|' + ISNULL(Source_Key_2,'') + '|' + ISNULL(Source_Key_3,'') + '|' + ISNULL(Source_Key_4,'')), 2)`.
- PERSISTED: yes. Required for indexing.
- Hash delimiter is pipe (`|`). This is fixed and must not vary by pipeline or tool.
- Hash inputs must be trimmed and normalized (LTRIM/RTRIM) before insertion to prevent invisible whitespace collisions.

**Target_Key vs Target_Code**
- `Target_Key` is `decimal(18,0)` matching PDI surrogate types. Used for all PDI-target mappings.
- `Target_Code` is `varchar(100)`. Used for non-PDI target systems (Gravitate, Axxis) that resolve by string code.
- Both may coexist on a single row only if the target system genuinely uses both forms (rare; document in row Notes if used).
- `Target_Code` must be NULL for PDI-target rows. Views derive `_ID` live. Violation of this is a data quality defect.

**Resolution_Status and Is_Active**
- These are redundant by design for safety: Is_Active = 1 is only valid when Resolution_Status = ACTIVE.
- Unique index filters on `Is_Active = 1`.
- Build phase must include a check constraint enforcing the relationship: `CHECK (Is_Active = 0 OR Resolution_Status = 'ACTIVE')`.

**Consuming_Views**
- JSON array, format: `[{"repo": "gravitate-orders", "view": "vw_Xref_Product_Gravitate_To_PDI"}, ...]`.
- NULL is valid when no consuming views are registered yet.
- Parsing tools must handle NULL gracefully.
- Format is fixed. Version it by bumping a top-level `"version"` key if the schema evolves.
- Do not store column-level metadata in Consuming_Views; use row Notes for supplemental context.

---

## Index Strategy

### Primary Key
```sql
CONSTRAINT PK_Xref_Registry PRIMARY KEY CLUSTERED (Xref_ID)
```

### Unique Active Index (Uniqueness Enforcement)
```sql
CREATE UNIQUE INDEX UX_Xref_Registry_ActiveComposite
ON dbo.Xref_Registry (Domain_Name, Source_System, Target_System, Target_Channel, Composite_Hash)
WHERE Is_Active = 1;
```
This is the primary safety mechanism. The filtered WHERE clause means UNRESOLVED/RETIRED rows do not participate.

### Supporting Indexes
```sql
-- Domain + pipeline lookup (stewardship and agent context)
CREATE INDEX IX_Xref_Registry_Domain_Pipeline
ON dbo.Xref_Registry (Domain_Name, Owning_Pipeline, Is_Active);

-- Work queue lookup (stewardship surface)
CREATE INDEX IX_Xref_Registry_Resolution_Status
ON dbo.Xref_Registry (Resolution_Status, Is_Active, Domain_Name);
```

### Additional Index Candidates (evaluate at build)
- `(Source_System, Target_System, Is_Active)` for cross-domain cross-system queries.
- `(Target_Key)` if PDI key reverse lookups are needed.
- Avoid over-indexing; audit real query patterns post-deployment before adding more.

---

## View Definition Patterns

### Pipeline Contract View (read-only, PDI target)
```sql
CREATE VIEW dbo.vw_Xref_Product_Gravitate_To_PDI
AS
SELECT
      x.Xref_ID
    , x.Source_Key_1              AS Gravitate_ProductCode
    , x.Target_Key                AS PDI_FuelProd_Key
    , p.FuelProd_ID               AS PDI_FuelProd_ID     -- live-derived, never cached
    , x.Resolution_Status
    , x.Is_Active
FROM dbo.Xref_Registry x
INNER JOIN PDIClone.dbo.FuelProducts_Clone p  -- exact clone surface TBD at build
    ON x.Target_Key = p.FuelProd_Key
WHERE x.Domain_Name    = 'Product'
  AND x.Source_System  = 'Gravitate'
  AND x.Target_System  = 'PDI'
  AND x.Target_Channel IS NULL
  AND x.Is_Active      = 1;
GO
```
Key rules:
- Always filter to exactly one Domain/Source/Target/Channel combination.
- Always inner-join to clone for `_ID` derivation (PDI targets).
- Never expose UNRESOLVED or RETIRED rows.
- View body must not contain GROUP BY, subqueries, or aggregation; keep views simple for pipeline safety.

### Pipeline Contract View (non-PDI target)
```sql
CREATE VIEW dbo.vw_Xref_Product_PDI_To_Gravitate_API
AS
SELECT
      x.Xref_ID
    , x.Source_Key_1              AS PDI_ProductCode      -- populated at build from PDI source
    , x.Target_Code               AS Gravitate_API_Code
    , x.Resolution_Status
    , x.Is_Active
FROM dbo.Xref_Registry x
WHERE x.Domain_Name    = 'Product'
  AND x.Source_System  = 'PDI'
  AND x.Target_System  = 'Gravitate'
  AND x.Target_Channel = 'API'
  AND x.Is_Active      = 1;
GO
```

### Stewardship View
```sql
CREATE VIEW dbo.vw_Xref_Stewardship_All
AS
SELECT  x.*
FROM    dbo.Xref_Registry x
-- No Is_Active filter: stewardship needs full lifecycle visibility
-- Application layer applies user-scope filters
GO
```

---

## Governed Dimension Tables (Required at Build)
Each of the following must be implemented as lookup tables or enforced via application-layer validation (not plain varchar free text):
- `dbo.Xref_DomainNames`
- `dbo.Xref_SourceSystems`
- `dbo.Xref_TargetSystems`
- `dbo.Xref_TargetChannels`
- `dbo.Xref_Workgroups`
- `dbo.Xref_ResolutionStatuses`

Foreign key enforcement to these tables is preferred. If not enforced via FK, enforce via trigger or application constraint with explicit rationale noted.

---

## Database Location Decision
- Xref_Registry and all views: PDI_PricingLink (authoritative canonical home per ADR D1).
- PDI clone surfaces used in view joins remain in their current locations (PDI clone database).
- No registry objects in PDI-SQL-01; that location is a consumer only.

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Architecture memo is a planning-stage design document, not a reusable execution skill.
