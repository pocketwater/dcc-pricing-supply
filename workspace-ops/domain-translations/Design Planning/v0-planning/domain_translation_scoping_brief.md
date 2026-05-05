# Domain Translation & Canonical Mapping â€” Scoping Brief

## 1. Problem Statement

We currently maintain multiple translation (xref) and CITT clone tables split across **PDI\_PricingLink** and **PDIâ€‘SQLâ€‘01**, created organically over time. These tables serve mixed purposes:

*   Some normalize messy source data (e.g., Bushby's concatenation work in CITT clones for Axxis uploads)
*   Some define canonical business identity
*   Some bridge directly between systems (e.g., PDIâ†’Gravitate, Gravitateâ†’PDI)

Current state: **CITT tables cache `_ID` translations with no refresh mechanism** â€” when PDI string values change, CITT rows require manual updates. This is identified as state drift, not a durable design.

This has created:

*   **State drift risk** (conflicting or duplicated mappings, stale CITT rows)
*   **Cognitive overhead** (unclear which table defines truth; multiple semantic surfaces for one concept)
*   **Agent risk** (automated systems may select the wrong mapping layer)
*   **Migration friction** (when moving from FTP to API channels, or adding new target systems, no clear ownership)

The goal of this plan is to define a **clear, scalable, and agentâ€‘safe standard** for managing translations and canonical mappings. Upon completion, CITT tables will be deprecated entirely, replaced by a live-derived `_ID` model.

***

## 2. Guiding Principles

1.  **Separate responsibilities, not necessarily tables**
    *   Normalization â‰  identity resolution â‰  target projection
2.  **Canonical truth must live in one place**
    *   No other system defines enterprise identity
3.  **Humans want one screen; pipelines want safe surfaces**
4.  **Agents need one obvious authority**
5.  **Boring, explicit, and wellâ€‘labeled beats clever**

***

## 3. Conceptual Model (Industry Pattern)

### Two Logical Layers (Split by Responsibility)

#### A. Edge Translation (Normalization)

*   Purpose: make source data usable
*   Characteristics:
    *   Domainâ€‘specific
    *   Messy by nature
    *   Allowed to duplicate
    *   Disposable or replaceable
*   Examples:
    *   Gravitate product aliases
    *   Vendorâ€‘specific codes
    *   Fileâ€‘specific quirks

#### B. Canonical Mapping (Identity Resolution)

*   Purpose: define what things **are**
*   Characteristics:
    *   Centralized
    *   Auditable
    *   Stable keys
    *   Shared across pipelines
*   Examples:
    *   Canonical Customer
    *   Canonical Product
    *   Canonical Terminal
    *   Canonical Vendor / Contract

**Rule:**

> Edge tables translate language. Canonical tables define identity. Never mix the two responsibilities.

***

## 4. Pipeline Lens (Operational View)

### Standardized Pipeline Stages

    Ingest
      â†“
    Normalize (edge translation)
      â†“
    Stage
      â†“
    Resolve (canonical mapping)
      â†“
    Validate
      â†“
    Project
      â†“
    Output

*   **Normalize** uses sourceâ€‘specific logic
*   **Resolve** uses canonical mappings
*   **Validate** asserts resolution is:
    *   Unique
    *   Active
    *   Safe
*   **Project** shapes alreadyâ€‘validated rows for the target system

***

## 5. Physical Architecture Decision

### One Physical Registry, One Central Stewardship Surface

Rather than multiple edge tables:

*   Use **one physical, centralized mapping table** in `PDI_PricingLink`
*   Enforce responsibility via **columns + views + governance dimensions**
*   Create **filtered, domain-specific views** as pipeline contracts
*   Use **one central stewardship UI** (command app) with pipeline/functional tabs and scoped filters

This balances:

*   Registry centrality (one authority, no semantic spread)
*   Safety (pipelines and agents consume narrow, named views)
*   Governance (canonical truth remains centralized and auditable)
*   Human clarity (stewards use one shared xref page with context filters, not generic raw-table editing)
*   Scalability (new target systems and channels added without restructuring)

***

## 6. Canonical Home

**Authoritative location:**
âœ… `PDI_PricingLink`

**Rules:**

*   All crossâ€‘system identity resolution occurs here
*   No other system defines canonical identity
*   Other systems may project or consume identity, but not redefine it

***

## 7. Core Data Model

### Master Table: `dbo.Xref_Registry`

**Purpose:**
The single registry for all crossâ€‘system resolution. Each row represents one resolved business relationship with deterministic uniqueness and governance metadata.

**Row semantics:**
- Source side: composite identity (up to 4 keys + deterministic hash)
- Target side: domain-specific resolution (surrogate key, string code, or both depending on target system)
- Governance: workgroup, owning pipeline, consuming views, audit trail

**Key characteristics:**

*   Selfâ€‘describing rows (domain, source system, target system + channel)
*   Supports composite source identities with deterministic hashing
*   Supports flexible target resolution (key-based, code-based, or both)
*   Target-channel aware (e.g., Gravitate FTP vs Gravitate API share domain/source but emit different codes)
*   Workgroup + pipeline ownership for multi-tenant / multi-workspace futures
*   View consumption metadata for cross-repo discoverability
*   Timeâ€‘aware and auditable (soft deletes only)
*   Humanâ€‘editable and agentâ€‘discoverable

**PDI Convention Alignment:**
- When target is PDI: Registry stores `Target_Key` (PDI surrogate `_Key` â€” durable anchor); pipelines derive `Target_Code` (`_ID`) live from PDI clone tables at query time
- When target is other system (e.g., Gravitate): Registry stores `Target_Code` directly
- CRITICAL: `_ID` values are NEVER cached here; they are always derived live. This eliminates CITT table maintenance burden.

***

## 8. Composite Source Support (Realâ€‘World Requirement)

Many domains (e.g., contracts) require multiâ€‘column resolution: supplier + terminal + product + contract context.

### Pattern Adopted

*   Four source key slots: `Source_Key_1`, `Source_Key_2`, `Source_Key_3`, `Source_Key_4` (unused slots = NULL)
*   Deterministic composite hash: SHA2_256 of concatenated slots (persisted, indexed)
*   Uniqueness enforced on hash, not raw slots (prevents slot-order confusion)
*   Slot semantics left to domain documentation (e.g., "Key_1=Supplier, Key_2=Terminal, Key_3=Product, Key_4=ContractType")

### Why This Matters

*   Prevents ambiguous joins and silent duplication
*   Simplifies pipeline logic (one hash to check, not four columns)
*   Prevents agents from guessing join rules
*   Eliminates subtle bugs when source identity shifts over time
*   Allows clean upgrades (e.g., add a 5th dimension by versioning the hash algorithm)

**Rule:**

> Composite source identity must be generated the same way everywhere. The hash is the anchor, not the individual slots.

***

## 9. Safety & Enforcement

### Uniqueness Guarantees

*   One active mapping per:
    *   Domain
    *   Source system
    *   Target system + Target channel
    *   Composite source identity (hash)

**Rationale for Target_Channel:**
When migrating from one interface to another (e.g., Gravitate FTP â†’ API), both mappings must coexist. Same source, same target system, but different channel means different target codes. The channel disambiguates them.

### Validation Rules (Nonâ€‘Interpretive)

*   No match â†’ **BLOCK** (source cannot be resolved)
*   Multiple matches â†’ **BLOCK** (ambiguous; prevents silent data loss)
*   Inactive match â†’ **BLOCK** (stale or retired mapping)
*   Single active match â†’ **PASS** (safe to proceed to projection)

**Rule:** Validation never interprets. It only proves correctness.

***

## 10. Views as Contracts (Critical)

### Resolve vs Stewardship Surfaces

#### Pipeline Contract Views (Readâ€‘Only)
*   Pipelines **never join directly** to `dbo.Xref_Registry`
*   Consume **domainâ€‘specific, channelâ€‘aware views** instead
*   These are the **resolve surfaces** used by automation and agents

Examples:

*   `vw_Xref_Product_Gravitate_To_PDI` â€” Gravitate products â†’ PDI surrogates
*   `vw_Xref_Product_PDI_To_Gravitate_API` â€” PDI products â†’ Gravitate API codes
*   `vw_Xref_Product_PDI_To_Gravitate_FTP` â€” PDI products â†’ Gravitate FTP codes (deprecated after cutover)
*   `vw_Xref_Contract_Axxis_To_PDI` â€” Axxis contracts (STP context) â†’ PDI FuelCont_ID

#### Stewardship Surface (Central Command UI)
*   Nonâ€‘technical interface for humans to manage mappings
*   **One central xref page** in the command app, with tabs for pipeline/functional purpose
*   Unresolved work queue highlighting rows needing action
*   Sourceâ€‘side dropdowns, destinationâ€‘truth pickers
*   Audit visibility and effectiveâ€‘date controls
*   Filtered by pipeline, domain, workgroup, source system, target system, and channel

**Clarification:**
Domain specificity applies to **filters and views**, not to creating separate resolve logic per domain. Resolve remains centralized in one canonical authority and one registry.

### Benefits

*   Stable pipeline interfaces (refactor registry internals without breaking pipelines)
*   Safe source-system upgrades (add new channel, keep old active in parallel)
*   Clear agent guidance (agents find one obvious resolve view, never the raw registry)
*   Central human workflow (one stewardship destination, many filtered working contexts)

***

## 11. Naming & Governance Standards

### Naming

*   `Xref_Registry` â†’ master table
*   `vw_Xref_<Domain>_<Source>_To_<Target>` â†’ pipeline contract (channel optional in name if not ambiguous)
*   `vw_Xref_<Domain>_Stewardship` â†’ domain stewardship surface

### Governed Dimensions (Not Free Text)

All of these must be governed lookup tables or constants, never open strings:

*   **Domain_Name**: Product, Terminal, Vendor, Contract, Destination, Customer, Location, Site, etc.
*   **Source_System**: Gravitate, Axxis, OPIS, PDI, Manual, etc.
*   **Target_System**: PDI, Gravitate, Axxis, etc.
*   **Target_Channel**: FTP, API, Manual, etc. (NULL if not applicable)
*   **Workgroup**: COIL-Pricing-Supply, [Future Workgroup], etc.
*   **Resolution_Status**: UNRESOLVED, ACTIVE, REVIEW_REQUIRED, RETIRED

### Classification (No Gray Area)

Every mapping must clearly declare:

*   Domain (what business entity?)
*   Source system (where does this source value live?)
*   Target system + channel (where and how are we sending the result?)
*   Workgroup + owning pipeline (who stewards this? who uses it?)
*   Resolution status (is this row ready for use?)

***

## 12. Agent Considerations (Explicit Design Goal)

Agents will:

*   Grab the first table that looks right
*   Reuse it broadly
*   Cement bad patterns quickly

This design ensures:

*   Exactly one authoritative mapping registry
*   Exactly one sanctioned access method (views)
*   Clear semantic signals in schema and naming

***

## 13. Migration / Remediation Plan (High Level)

1.  Inventory all existing xref tables (artifact: current-state xref inventory)
2.  Classify each as edge normalization, canonical identity, legacy/unclear, or CITT variant
3. Identify conflicts, duplicates, and contradictory mappings across tables
4.  Stress-test the model with Contracts domain (most complex: STP + context)
5.  Migrate canonical logic into `Xref_Registry` with explicit `_Key` anchors
6.  Bootstrap stewardship UX with unresolved-row queue
7.  Design pipeline contract views for each domain/source/target/channel combination
8.  Deploy registry + views in parallel with legacy xrefs
9.  Validate side-by-side outputs match legacy behavior
10. Cutover: freeze legacy xrefs, pipelines point to new views
11. Retire legacy xrefs (including CITT clones) after 2 release cycles
12. Document governance rules in an ADR

***

## 15. Oneâ€‘Sentence Rule (ADRâ€‘Ready)

> **All crossâ€‘system business identity is resolved in the PricingLink canonical mapping layer. No other system defines enterprise identity. Pipeline views derive `_ID` values live from PDI clone tables; no `_ID` is ever cached in the registry. CITT clone tables will be deprecated upon cutover.**

---

## 16. CITT Table Deprecation & Migration Path

**Current state:** CITT tables (`PDI_CITT_Axxis_Grav_PDI_Products_Clone`, etc.) cache `_ID` translations with no refresh mechanism. When PDI string values change, rows go stale and require manual updates.

**Why they exist:** Workaround for lack of a better place to cache `_ID` translations.

**Future state:** Once the registry is live and pipeline views derive `_ID` values on every query from PDI clone tables, CITT tables have no job. They will be frozen (read-only), run in parallel during cutover validation, then dropped.

**Deprecation sequence:**
1. **Seed phase** â€” Pull current CITT rows into registry as candidates; reconcile against PDI clone data to validate `_Key` resolution
2. **Design phase** â€” Lock contract view definitions, test live derivation against CITT old values
3. **Build phase** â€” Implement registry table, load validated mappings, deploy views in parallel with CITT
4. **Validation phase** â€” Side-by-side comparison of CITT outputs vs. new view outputs
5. **Cutover** â€” Freeze CITT tables (no writes), pipelines point to new views
6. **Deprecation** â€” After 2 release cycles of parallel operation, drop CITT tables

---

## 17. Why This Works

*   **Minimizes drift** â€” one authority, one entry point, cannot redefine identity elsewhere
*   **Eliminates CITT maintenance** â€” no cached `_ID` to go stale; always fresh from source
*   **Scales with new systems** â€” add new source/target/channel without restructuring
*   **Human-friendly UX** â€” stewards see domain-shaped surfaces, not generic registry rows
*   **Agent-safe by construction** â€” exactly one obvious read surface per pipeline, no guessing
*   **Debuggable under pressure** â€” deterministic hash, governed dimensions, clear status states
*   **Boring in the best possible way** â€” explicit, explicit, explicit; no clever heuristics

---

## Next Steps: From Scoping to Planning

This scoping brief establishes the semantic model and governance framework. The next artifacts will be generated in `PROJECT_PLANNING_MANIFEST` format and will include:

1. **Problem & Scope Brief** â€” Defines the failure mode, current-state inventory, and known conflicts
2. **Contracts Stress-Test Brief** â€” Documents the hardest domain (STP + context + effective date nuances)
3. **Canonical Mapping ADR** â€” Records these decisions as architecture record
4. **Current-State Xref Inventory** â€” Catalogs every existing xref, CITT, and bridge table with classification
5. **Seed & Remediation Workbook** â€” Maps legacy tables into new model, flags conflicts and duplicates
6. **Stewardship Lifecycle Spec** â€” Bootstrap model: seed from current xrefs, surface unresolved rows, let stewards propose, Jason approves when needed, retire stale mappings
7. **Stewardship UX Requirements** â€” Domain pages with unresolved work queues, source dropdowns, destination-truth pickers, audit visibility
8. **Physical Architecture Memo** â€” Settles final DDL, view definition patterns, index strategy
9. **Domain Contract Specs** â€” Per-domain specifications for uniqueness rules, resolution outcomes, steward page behavior, pipeline view schema
10. **Pipeline Consumption Contracts** â€” Defines the read-only surfaces, guarantees, blocking behavior
11. **Build Specification** â€” Implementation-ready detail: DDL, constraints, view definitions, API contracts
12. **Validation & Reconciliation Plan** â€” Side-by-side testing, uniqueness checks, ambiguous-match detection
13. **Operations Runbook** â€” How stewards and pipeline operators actually live with it
14. **Release & Deprecation Plan** â€” Rollout order, cutover checkpoints, legacy freeze/retirement, fallback steps

**Key Decision Checkpoints Before Build:**
- [ ] Contracts domain is stress-tested and the model handles STP + context cleanly
- [ ] Stewardship UX is designed and socialized (not a generic registry editor)
- [ ] All governed dimensions (Domain, Source_System, Target_System, Target_Channel, Workgroup, Resolution_Status) are finalized
- [ ] Current-state xref inventory is complete and conflicts are identified
- [ ] CITT table deprecation path is documented
- [ ] Consuming_Views JSON format and tooling is decided

**This Brief Is Ready To:**
- Serve as the foundation for planning stage (transition to `PROJECT_PLANNING_MANIFEST`)
- Be presented to stakeholders for semantic agreement
- Be committed to ADR as the baseline architecture decision
- Guide the planning and design stages

---

## 14. Updated Schema: `dbo.Xref_Registry`

``` sql
CREATE TABLE dbo.Xref_Registry
(
      Xref_ID              int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Xref_Registry PRIMARY KEY

    -- Classification & Ownership
    , Domain_Name          varchar(50)  NOT NULL   -- Product, Terminal, Vendor, Contract, Destination
    , Source_System        varchar(50)  NOT NULL   -- Gravitate, Axxis, OPIS, PDI, Manual
    , Target_System        varchar(50)  NOT NULL   -- PDI, Gravitate, Axxis, etc.
    , Target_Channel       varchar(30)  NULL       -- FTP, API, Manual; NULL if not applicable

    -- Workspace & Stewardship
    , Workgroup            varchar(50)  NOT NULL   -- COIL-Pricing-Supply, [Future Workgroups]
    , Owning_Pipeline      varchar(50)  NOT NULL   -- gravitate-orders, citysv-costs, citysv-prices, etc.

    -- Composite source identity (4 slots; unused = NULL)
    , Source_Key_1         varchar(100) NOT NULL
    , Source_Key_2         varchar(100) NULL
    , Source_Key_3         varchar(100) NULL
    , Source_Key_4         varchar(100) NULL
    , Source_Description   varchar(255) NULL

    -- Composite hash â€” deterministic, generated consistently everywhere
    , Composite_Hash       AS (
          CONVERT(varchar(64),
            HASHBYTES('SHA2_256',
              ISNULL(Source_Key_1,'') + '|' +
              ISNULL(Source_Key_2,'') + '|' +
              ISNULL(Source_Key_3,'') + '|' +
              ISNULL(Source_Key_4,'')
            ), 2)
      ) PERSISTED NOT NULL

    -- Target resolution
    , Target_Key           decimal(18,0) NULL      -- Surrogate when target has one (e.g., PDI _Key)
    , Target_Code          varchar(100)  NULL      -- String code when target uses strings (e.g., Gravitate, Axxis)

    -- Control
    , Resolution_Status    varchar(30)  NOT NULL
        CONSTRAINT DF_Xref_Registry_Status DEFAULT ('UNRESOLVED')
        -- UNRESOLVED, ACTIVE, REVIEW_REQUIRED, RETIRED

    , Is_Active            bit NOT NULL
        CONSTRAINT DF_Xref_Registry_IsActive DEFAULT (0)

    , Effective_From       date NULL
    , Effective_To         date NULL

    -- View consumption mapping (for cross-repo discoverability)
    , Consuming_Views      nvarchar(max) NULL      -- JSON array: [{"repo":"gravitate-orders", "view":"vw_Xref_Product_Gravitate_To_PDI"}, ...]

    -- Stewardship / audit
    , Notes                varchar(1000) NULL
    , Created_Dtm          datetime2(0) NOT NULL
        CONSTRAINT DF_Xref_Registry_Created DEFAULT (SYSDATETIME())
    , Created_By           varchar(128) NOT NULL
        CONSTRAINT DF_Xref_Registry_CreatedBy DEFAULT (SUSER_SNAME())
    , Updated_Dtm          datetime2(0) NULL
    , Updated_By           varchar(128) NULL
);
GO

-- One active mapping per composite identity per domain/source/target/channel
CREATE UNIQUE INDEX UX_Xref_Registry_ActiveComposite
ON dbo.Xref_Registry (Domain_Name, Source_System, Target_System, Target_Channel, Composite_Hash)
WHERE Is_Active = 1;
GO

-- Supporting indexes for common queries
CREATE INDEX IX_Xref_Registry_Domain_Pipeline
ON dbo.Xref_Registry (Domain_Name, Owning_Pipeline, Is_Active);
GO

CREATE INDEX IX_Xref_Registry_Resolution_Status
ON dbo.Xref_Registry (Resolution_Status, Is_Active, Domain_Name);
GO
```

**Schema Notes:**

- `Composite_Hash` is persisted and indexed â€” queries use hash for uniqueness and join efficiency
- `Target_Key` and `Target_Code` are mutually flexible â€” PDI targets use _Key; non-PDI targets use _Code
- **CRITICAL**: `Target_Code` for PDI targets should be NULL in the registry. Pipeline views derive `_ID` live from PDI clone tables
- `Consuming_Views` is JSON for flexibility; parsing tools should be version-aware
- `Effective_From` / `Effective_To` allow temporal validity windows (future enhancement)
- Default `Resolution_Status='UNRESOLVED'` to force conscious approval before activation
---
