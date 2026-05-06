# BUILD_SPECIFICATION

## Purpose
Provide implementation-ready detail for the Build stage: DDL, constraints, view definitions, governed dimension seed data, check constraints, and API contract surface. This document is the handoff input for the Builder agent.

## Status
PLANNING_GRADE — No SQL objects have been created. This document represents the intended build target, subject to Design-stage approval.

## Grain Contract
- Grain In: Physical Architecture Memo, Domain Contract Specs, Pipeline Consumption Contracts, Stewardship Lifecycle Spec.
- Grain Out: Build-ready implementation instructions with explicit DDL targets, object list, and validation query stubs.

## Translation Requirements
- Build must implement all ADR separation rules exactly. Any deviation from D1–D10 is a build defect.

## Ontological Assumptions
- PDI_PricingLink is the target database. Builder has deploy access or confirms via sandbox company before production.
- PDI clone join paths will be confirmed during Build; placeholder view join targets must be updated before deploy.
- Confidence note: high (9/10) for DDL structure; medium (7/10) for clone join path specifics.

---

## Objects To Build (In Order)

### Phase 1 — Governed Dimension Tables
Build all lookup/dimension tables before the main registry to allow FK enforcement.

| Object | Type | Location |
|---|---|---|
| `dbo.Xref_DomainNames` | Table | PDI_PricingLink |
| `dbo.Xref_SourceSystems` | Table | PDI_PricingLink |
| `dbo.Xref_TargetSystems` | Table | PDI_PricingLink |
| `dbo.Xref_TargetChannels` | Table | PDI_PricingLink |
| `dbo.Xref_Workgroups` | Table | PDI_PricingLink |
| `dbo.Xref_ResolutionStatuses` | Table | PDI_PricingLink |

Each dimension table: single column `Name varchar(50) NOT NULL PRIMARY KEY` plus optional metadata columns (description, is_active, sort_order).

**Seed data for Xref_DomainNames:**
Product, Terminal, Contract, Destination, Customer, Vendor, Location, Site

**Seed data for Xref_SourceSystems:**
Gravitate, Axxis, OPIS, PDI, Manual

**Seed data for Xref_TargetSystems:**
PDI, Gravitate, Axxis

**Seed data for Xref_TargetChannels:**
FTP, API, Manual

**Seed data for Xref_Workgroups:**
COIL-Pricing-Supply

**Seed data for Xref_ResolutionStatuses:**
UNRESOLVED, ACTIVE, REVIEW_REQUIRED, RETIRED

---

### Phase 2 — Registry Table `dbo.Xref_Registry`

**Core DDL** (see Physical Architecture Memo and scoping brief Section 14 for full CREATE TABLE statement).

**Additional Check Constraint:**
```sql
ALTER TABLE dbo.Xref_Registry
ADD CONSTRAINT CK_Xref_Registry_ActiveStatus
CHECK (Is_Active = 0 OR Resolution_Status = 'ACTIVE');
GO
```

**Foreign Key Constraints:**
```sql
ALTER TABLE dbo.Xref_Registry
ADD CONSTRAINT FK_Xref_Registry_Domain
    FOREIGN KEY (Domain_Name) REFERENCES dbo.Xref_DomainNames(Name);

ALTER TABLE dbo.Xref_Registry
ADD CONSTRAINT FK_Xref_Registry_SourceSystem
    FOREIGN KEY (Source_System) REFERENCES dbo.Xref_SourceSystems(Name);

ALTER TABLE dbo.Xref_Registry
ADD CONSTRAINT FK_Xref_Registry_TargetSystem
    FOREIGN KEY (Target_System) REFERENCES dbo.Xref_TargetSystems(Name);

ALTER TABLE dbo.Xref_Registry
ADD CONSTRAINT FK_Xref_Registry_Workgroup
    FOREIGN KEY (Workgroup) REFERENCES dbo.Xref_Workgroups(Name);

ALTER TABLE dbo.Xref_Registry
ADD CONSTRAINT FK_Xref_Registry_ResolutionStatus
    FOREIGN KEY (Resolution_Status) REFERENCES dbo.Xref_ResolutionStatuses(Name);
-- Target_Channel allows NULL (no FK on nullable channel, validate via app layer)
GO
```

**Input Normalization Trigger:**
```sql
-- BEFORE insert/update: trim Source_Key_1 through Source_Key_4 to prevent hash collision
CREATE TRIGGER trg_Xref_Registry_NormalizeKeys
ON dbo.Xref_Registry
AFTER INSERT, UPDATE
AS
BEGIN
    -- If Source_Key values have leading/trailing whitespace, raise error to force clean input
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE Source_Key_1 != LTRIM(RTRIM(Source_Key_1))
           OR (Source_Key_2 IS NOT NULL AND Source_Key_2 != LTRIM(RTRIM(Source_Key_2)))
           OR (Source_Key_3 IS NOT NULL AND Source_Key_3 != LTRIM(RTRIM(Source_Key_3)))
           OR (Source_Key_4 IS NOT NULL AND Source_Key_4 != LTRIM(RTRIM(Source_Key_4)))
    )
    BEGIN
        RAISERROR('Source_Key values must be pre-trimmed before insert. Hash integrity requires clean inputs.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
GO
```

---

### Phase 3 — Indexes
Apply indexes per Physical Architecture Memo:
- `UX_Xref_Registry_ActiveComposite` (filtered unique)
- `IX_Xref_Registry_Domain_Pipeline`
- `IX_Xref_Registry_Resolution_Status`

---

### Phase 4 — Pipeline Contract Views
Build all views defined in Pipeline Consumption Contracts document.

Before deploying each view:
1. Confirm exact clone join path (table name, key column name) against current PDI clone database.
2. Confirm clone database is accessible from PDI_PricingLink context.
3. Replace placeholder `PDIClone.dbo.*` references with confirmed objects.

---

### Phase 5 — Stewardship View
Build `dbo.vw_Xref_Stewardship_All` per Physical Architecture Memo pattern.

---

## Validation Queries Included: YES (see Validation & Reconciliation Plan)

---

## Pre-Deploy Checklist
- [ ] Governed dimension tables built and seeded.
- [ ] Registry table built with all constraints.
- [ ] Unique index confirmed deployed with filter clause.
- [ ] Check constraint `CK_Xref_Registry_ActiveStatus` confirmed.
- [ ] All FK constraints confirmed.
- [ ] Trigger deployed and tested.
- [ ] All pipeline contract views confirmed deployed.
- [ ] Clone join paths confirmed for all PDI-target views.
- [ ] Stewardship view deployed.
- [ ] Sandbox company validation evidence collected (required for PDI endpoint pipelines per runbook).

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Build specification is a planning-stage artifact; execution-layer build work occurs in Build stage.
