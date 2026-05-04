# Domain Translation & Canonical Mapping — Scoping Brief

## 1. Problem Statement

We currently maintain multiple translation (xref) and CITT clone tables split across **PDI\_PricingLink** and **PDI‑SQL‑01**, created organically over time. These tables serve mixed purposes:

*   Some normalize messy source data (e.g., Bushby's concatenation work in CITT clones for Axxis uploads)
*   Some define canonical business identity
*   Some bridge directly between systems (e.g., PDI→Gravitate, Gravitate→PDI)

Current state: **CITT tables cache `_ID` translations with no refresh mechanism** — when PDI string values change, CITT rows require manual updates. This is identified as state drift, not a durable design.

This has created:

*   **State drift risk** (conflicting or duplicated mappings, stale CITT rows)
*   **Cognitive overhead** (unclear which table defines truth; multiple semantic surfaces for one concept)
*   **Agent risk** (automated systems may select the wrong mapping layer)
*   **Migration friction** (when moving from FTP to API channels, or adding new target systems, no clear ownership)

The goal of this plan is to define a **clear, scalable, and agent‑safe standard** for managing translations and canonical mappings. Upon completion, CITT tables will be deprecated entirely, replaced by a live-derived `_ID` model.

***

## 2. Guiding Principles

1.  **Separate responsibilities, not necessarily tables**
    *   Normalization ≠ identity resolution ≠ target projection
2.  **Canonical truth must live in one place**
    *   No other system defines enterprise identity
3.  **Humans want one screen; pipelines want safe surfaces**
4.  **Agents need one obvious authority**
5.  **Boring, explicit, and well‑labeled beats clever**

***

## 3. Conceptual Model (Industry Pattern)

### Two Logical Layers (Split by Responsibility)

#### A. Edge Translation (Normalization)

*   Purpose: make source data usable
*   Characteristics:
    *   Domain‑specific
    *   Messy by nature
    *   Allowed to duplicate
    *   Disposable or replaceable
*   Examples:
    *   Gravitate product aliases
    *   Vendor‑specific codes
    *   File‑specific quirks

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
      ↓
    Normalize (edge translation)
      ↓
    Stage
      ↓
    Resolve (canonical mapping)
      ↓
    Validate
      ↓
    Project
      ↓
    Output

*   **Normalize** uses source‑specific logic
*   **Resolve** uses canonical mappings
*   **Validate** asserts resolution is:
    *   Unique
    *   Active
    *   Safe
*   **Project** shapes already‑validated rows for the target system

***

## 5. Physical Architecture Decision

### ✅ One Physical Registry, Many Domain-Specific Stewardship Surfaces

Rather than multiple edge tables:

*   Use **one physical, centralized mapping table** in `PDI_PricingLink`
*   Enforce responsibility via **columns + views + governance dimensions**
*   Create **filtered, domain‑specific views** as pipeline contracts
*   Optimize **stewardship UX** for domain shape, not generic registry rows

This balances:

*   Registry centrality (one authority, no semantic spread)
*   Safety (pipelines and agents consume narrow, named views)
*   Governance (canonical truth remains centralized and auditable)
*   Human clarity (stewards edit domain-shaped surfaces, not generic slots)
*   Scalability (new target systems and channels added without restructuring)

***

## 6. Canonical Home

**Authoritative location:**
✅ `PDI_PricingLink`

**Rules:**

*   All cross‑system identity resolution occurs here
*   No other system defines canonical identity
*   Other systems may project or consume identity, but not redefine it

***

## 7. Core Data Model

### Master Table: `dbo.Xref_Registry`

**Purpose:**
The single registry for all cross‑system resolution. Each row represents one resolved business relationship with deterministic uniqueness and governance metadata.

**Row semantics:**
- Source side: composite identity (up to 4 keys + deterministic hash)
- Target side: domain-specific resolution (surrogate key, string code, or both depending on target system)
- Governance: workgroup, owning pipeline, consuming views, audit trail

**Key characteristics:**

*   Self‑describing rows (domain, source system, target system + channel)
*   Supports composite source identities with deterministic hashing
*   Supports flexible target resolution (key-based, code-based, or both)
*   Target-channel aware (e.g., Gravitate FTP vs Gravitate API share domain/source but emit different codes)
*   Workgroup + pipeline ownership for multi-tenant / multi-workspace futures
*   View consumption metadata for cross-repo discoverability
*   Time‑aware and auditable (soft deletes only)
*   Human‑editable and agent‑discoverable

**PDI Convention Alignment:**
- When target is PDI: Registry stores `Target_Key` (PDI surrogate `_Key` — durable anchor); pipelines derive `Target_Code` (`_ID`) live from PDI clone tables at query time
- When target is other system (e.g., Gravitate): Registry stores `Target_Code` directly
- CRITICAL: `_ID` values are NEVER cached here; they are always derived live. This eliminates CITT table maintenance burden.

***

## 8. Composite Source Support (Real‑World Requirement)

Many domains (e.g., contracts) require multi‑column resolution: supplier + terminal + product + contract context.

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
When migrating from one interface to another (e.g., Gravitate FTP → API), both mappings must coexist. Same source, same target system, but different channel means different target codes. The channel disambiguates them.

### Validation Rules (Non‑Interpretive)

*   No match → **BLOCK** (source cannot be resolved)
*   Multiple matches → **BLOCK** (ambiguous; prevents silent data loss)
*   Inactive match → **BLOCK** (stale or retired mapping)
*   Single active match → **PASS** (safe to proceed to projection)

**Rule:** Validation never interprets. It only proves correctness.

***

## 10. Views as Contracts (Critical)

### Two View Families

#### Pipeline Contract Views (Read‑Only)
*   Pipelines **never join directly** to `dbo.Xref_Registry`
*   Consume **domain‑specific, channel‑aware views** instead

Examples:

*   `vw_Xref_Product_Gravitate_To_PDI` — Gravitate products → PDI surrogates
*   `vw_Xref_Product_PDI_To_Gravitate_API` — PDI products → Gravitate API codes
*   `vw_Xref_Product_PDI_To_Gravitate_FTP` — PDI products → Gravitate FTP codes (deprecated after cutover)
*   `vw_Xref_Contract_Axxis_To_PDI` — Axxis contracts (STP context) → PDI FuelCont_ID

#### Stewardship Surfaces (Domain‑Shaped)
*   Non‑technical interface for humans to manage mappings
*   One surface per domain (not per table)
*   Unresolved work queue highlighting rows needing action
*   Source‑side dropdowns, destination‑truth pickers
*   Audit visibility and effective‑date controls
*   Filtered to domain + workgroup context

### Benefits

*   Stable pipeline interfaces (refactor registry internals without breaking pipelines)
*   Safe source-system upgrades (add new channel, keep old active in parallel)
*   Clear agent guidance (agents find one obvious view, never the raw registry)
*   Intentional scope control (stewards see domain shape, not generic slots)

***

## 11. Naming & Governance Standards

### Naming

*   `Xref_Registry` → master table
*   `vw_Xref_<Domain>_<Source>_To_<Target>` → pipeline contract (channel optional in name if not ambiguous)
*   `vw_Xref_<Domain>_Stewardship` → domain stewardship surface

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

## 15. One‑Sentence Rule (ADR‑Ready)

> **All cross‑system business identity is resolved in the PricingLink canonical mapping layer. No other system defines enterprise identity. Pipeline views derive `_ID` values live from PDI clone tables; no `_ID` is ever cached in the registry. CITT clone tables will be deprecated upon cutover.**

---

## 16. CITT Table Deprecation & Migration Path

**Current state:** CITT tables (`PDI_CITT_Axxis_Grav_PDI_Products_Clone`, etc.) cache `_ID` translations with no refresh mechanism. When PDI string values change, rows go stale and require manual updates.

**Why they exist:** Workaround for lack of a better place to cache `_ID` translations.

**Future state:** Once the registry is live and pipeline views derive `_ID` values on every query from PDI clone tables, CITT tables have no job. They will be frozen (read-only), run in parallel during cutover validation, then dropped.

**Deprecation sequence:**
1. **Seed phase** — Pull current CITT rows into registry as candidates; reconcile against PDI clone data to validate `_Key` resolution
2. **Design phase** — Lock contract view definitions, test live derivation against CITT old values
3. **Build phase** — Implement registry table, load validated mappings, deploy views in parallel with CITT
4. **Validation phase** — Side-by-side comparison of CITT outputs vs. new view outputs
5. **Cutover** — Freeze CITT tables (no writes), pipelines point to new views
6. **Deprecation** — After 2 release cycles of parallel operation, drop CITT tables

---

## 17. Why This Works

*   **Minimizes drift** — one authority, one entry point, cannot redefine identity elsewhere
*   **Eliminates CITT maintenance** — no cached `_ID` to go stale; always fresh from source
*   **Scales with new systems** — add new source/target/channel without restructuring
*   **Human-friendly UX** — stewards see domain-shaped surfaces, not generic registry rows
*   **Agent-safe by construction** — exactly one obvious read surface per pipeline, no guessing
*   **Debuggable under pressure** — deterministic hash, governed dimensions, clear status states
*   **Boring in the best possible way** — explicit, explicit, explicit; no clever heuristics

---

## Next Steps: From Scoping to Planning

This scoping brief establishes the semantic model and governance framework. The next artifacts will be generated in `PROJECT_PLANNING_MANIFEST` format and will include:

1. **Problem & Scope Brief** — Defines the failure mode, current-state inventory, and known conflicts
2. **Contracts Stress-Test Brief** — Documents the hardest domain (STP + context + effective date nuances)
3. **Canonical Mapping ADR** — Records these decisions as architecture record
4. **Current-State Xref Inventory** — Catalogs every existing xref, CITT, and bridge table with classification
5. **Seed & Remediation Workbook** — Maps legacy tables into new model, flags conflicts and duplicates
6. **Stewardship Lifecycle Spec** — Bootstrap model: seed from current xrefs, surface unresolved rows, let stewards propose, Jason approves when needed, retire stale mappings
7. **Stewardship UX Requirements** — Domain pages with unresolved work queues, source dropdowns, destination-truth pickers, audit visibility
8. **Physical Architecture Memo** — Settles final DDL, view definition patterns, index strategy
9. **Domain Contract Specs** — Per-domain specifications for uniqueness rules, resolution outcomes, steward page behavior, pipeline view schema
10. **Pipeline Consumption Contracts** — Defines the read-only surfaces, guarantees, blocking behavior
11. **Build Specification** — Implementation-ready detail: DDL, constraints, view definitions, API contracts
12. **Validation & Reconciliation Plan** — Side-by-side testing, uniqueness checks, ambiguous-match detection
13. **Operations Runbook** — How stewards and pipeline operators actually live with it
14. **Release & Deprecation Plan** — Rollout order, cutover checkpoints, legacy freeze/retirement, fallback steps

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

    -- Composite hash — deterministic, generated consistently everywhere
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

- `Composite_Hash` is persisted and indexed — queries use hash for uniqueness and join efficiency
- `Target_Key` and `Target_Code` are mutually flexible — PDI targets use _Key; non-PDI targets use _Code
- **CRITICAL**: `Target_Code` for PDI targets should be NULL in the registry. Pipeline views derive `_ID` live from PDI clone tables
- `Consuming_Views` is JSON for flexibility; parsing tools should be version-aware
- `Effective_From` / `Effective_To` allow temporal validity windows (future enhancement)
- Default `Resolution_Status='UNRESOLVED'` to force conscious approval before activation
---
# Pete Design Review
I’m treating this as a design review, not an implementation task. I’m going to pressure-test the draft against the actual failure mode you called out: humans and agents selecting the wrong mapping surface because the semantics aren’t obvious.

The direction is right. The part I would defend strongly is the semantic split: edge normalization is not canonical identity, and canonical identity is not target-system projection. That separation addresses the actual problem you described, which is not just table sprawl, but meaning sprawl. When humans and agents can’t tell whether a table is “clean up source junk,” “decide what this thing is,” or “shape data for PDI,” drift is inevitable.

The main pressure point in your draft is the move from “one authoritative canonical layer” to “one physical registry table.” I agree with the first statement. I’m not yet convinced you should lock in the second. A single table helps discoverability and agent safety, but it can become too generic for the only people who actually have to live in it: stewards resolving real-world mismatches under time pressure. If a contract mapping, a product alias, and a customer identity all end up represented through the same generic slot pattern, you may reduce table count while increasing human ambiguity. The invariant you really need is one authority, one sanctioned access path for pipelines, and one obvious stewardship surface. That can be a single table, but it could also be a canonical core plus domain-shaped stewardship views.

If this were my call, I’d keep these parts of the draft almost unchanged: one canonical home in PricingLink, views as pipeline contracts, block on no match or ambiguous match, and explicit stage separation of normalize -> resolve -> validate -> project. Those are solid. The parts I’d tighten before any build decision are these:
1. Split “identity resolution” from “target projection” more explicitly. “What is this?” and “what code do we send to PDI?” are related, but they are not the same decision.
2. Don’t rely on free-text classifiers like domain, source, target, and status if you want long-term discipline. Those should be governed dimensions, not open strings.
3. Avoid overlapping control fields unless each has a distinct job. `Is_Active`, `Resolution_Status`, and effective dates can drift out of sync fast.
4. Treat composite identity as a first-class concept, but be careful with overly generic key/value slots. They are flexible for the database and opaque for humans.
5. Design the stewarding experience, not just the storage model. Humans should edit domain-shaped views or forms, not a generic registry row if you can avoid it.

The other thing I’d push harder on is governance, because that is where xref systems usually fail. The technical model matters, but the bigger question is: who is allowed to create, change, retire, and approve mappings? If that is fuzzy, you will just create a cleaner-looking version of state spread. Since xrefs are one of the few human-touch surfaces in the pipeline, the UX should optimize for unresolved work queues, searchability by source and canonical identity, visible match rationale, temporal visibility, and safe retirement. That matters as much as the DDL.

So my short read is: your conceptual model is strong, your “single authority” rule is strong, your “views as contracts” rule is strong, and your risk framing is correct. The piece I would keep open for discussion is whether “single authority” must mean “single generic physical table,” or whether the better answer is “single canonical authority with domain-specific stewardship surfaces.” I suspect the latter is the safer long-term shape.

The next useful discussion would be to settle these decisions before any schema work:
1. Is canonical identity independent of PDI, or is PDI effectively the enterprise key for some domains?
    - I don't think we can safely say 100% but probably, pretty close to it, will resolve to PDI identities
2. Are mappings always one-to-one, or do some domains legitimately require one-to-many by date, terminal, customer, or contract context?
    - No, I don't think 1:1 will be frequent. Most cost rows require at least four elements, supplier, terminal, product (STP), plus some equivelent to a fuel contract as the 4th column.
3. Should target projection live in the same structure as canonical identity, or in a downstream projection layer keyed off the canonical entity?
    - I don't know, and I'm not clear on what you mean.
4. What is the human workflow for unresolved rows: propose, review, approve, activate, retire?
    - I see this working as a page on a web-app that includes all xrefs required in a particular domain. The user has something like a drop down list of available xrefs and they can alter the factors on a table container inside the filtered page.
5. Which domain is the stress test: contracts, products, or customers? I’d use contracts first because they usually expose the cracks fastest.
    - Contracts for sure are the trickiest.

If you want, I can take your draft and turn it into a sharper decision memo with explicit tradeoffs between “single registry table” and “single canonical authority with domain-specific stewardship surfaces,” without getting into implementation yet.

---
# Pete second sweep on GPT 5.4 "extra high" slow thinking

I’m treating this as a design discussion and narrowing on the actual failure mode: too many bridge surfaces, unclear ownership, and humans/agents picking the wrong table for the wrong job.

**My Read**

The direction is right, but the real problem is not just “too many xref tables.” It is that the same-looking surfaces are doing three different jobs: cleaning up source mess, deciding what a thing is, and shaping data for a target system. Once those jobs blur together, physical table count almost stops mattering. Humans guess. Agents guess faster.

That is why I would frame the goal as reducing semantic spread, not just consolidating storage. If you solve only for “one table,” you can end up with one large, confusing table instead of many smaller confusing ones.

**What I’d Anchor On**

I would keep these as non-negotiable:

- One authoritative canonical mapping authority in `PricingLink`
- Edge normalization kept separate from canonical identity
- Pipelines and agents consuming narrow, named contract surfaces
- Blocking on no match, ambiguous match, or inactive match
- Domain-specific human stewardship surfaces instead of generic raw-table editing

The part I would keep open is the phrase “one physical registry table.” That may be right under the hood, but I would not make it the headline decision yet. Your actual design requirement is: one authority, one obvious stewardship experience, one sanctioned consumption path. That can be implemented with one table, but it does not have to be.

Because xrefs are one of the few true human-touch surfaces, I would optimize for steward clarity first. A human should land on a Contracts page and see contract-shaped fields. They should not be forced to think in generic registry rows if the domain really lives at supplier + terminal + product + contract context.

**The Key Separation To Make Explicit**

The biggest design distinction to settle is this:

- Identity resolution answers: “What business thing is this?”
- Target projection answers: “What do we send to PDI for this thing?”

Those are related, but they are not the same decision.

A contract row from Gravitate might resolve to one canonical contract identity, and that identity might currently project almost directly to a PDI key. But if PDI codes, routing rules, or effective logic change later, you do not want that change to look like the business identity itself changed. If identity and projection are welded together too early, the model becomes brittle.

Given your note that PDI is probably the practical enterprise anchor for many domains, I would treat that as a current operating fact, not a design assumption. In other words: allow canonical identity to equal PDI identity for now where appropriate, but do not collapse the concepts in the model.

**What I’d Recommend**

If the priority is getting humans and agents out of the “which bridge table is the right one?” trap, I would aim for this shape:

- One canonical authority
- Domain-shaped stewardship surfaces
- Read-only pipeline contract views
- Separate edge translation from canonical mapping
- Keep target projection downstream from identity, even if today they often share the same values

That is why I’d favor “single canonical authority with domain-specific stewardship surfaces” over “single giant registry table” as the design principle.

For contracts specifically, I would not design around a simple `Source_Code` mental model. Contracts are your stress test because they are inherently composite. If the real grain is something like supplier + terminal + product + contract context, then that grain should be explicit in the stewardship experience. Generic slotting can exist internally if needed, but it is a poor primary abstraction for the humans maintaining it.

**What Needs To Be Decided Before Any Schema Talk**

1. Is PDI the current practical canonical key for each domain, or only for some domains?
    - I don't think we can safely say 100% but probably, pretty close to it, will resolve to PDI identities
2. Does target projection stay coupled to canonical mapping, or become a downstream layer keyed from canonical identity?
    - I don't understand what you mean.
3. What is the human lifecycle: propose, review, approve, activate, retire?
    - Hopefully, we can get something workable out of our current suite of xrefs and CITT clones. That would be the first step, the remainder of the missing or mismatched rows would be addressed durring normal business ops.
4. Who owns each domain’s mappings and who has approval authority?
    - Thats tbd I'll be the ultimate authority however
5. What exact unresolved-work experience do stewards need on day one?
    - A surface where they can enter source equivelents with destination truth in drop down boxes.

Other questions you may have and their answers.
1. Is canonical identity independent of PDI, or is PDI effectively the enterprise key for some domains?
    - I don't think we can safely say 100% but probably, pretty close to it, will resolve to PDI identities
2. Are mappings always one-to-one, or do some domains legitimately require one-to-many by date, terminal, customer, or contract context?
    - No, I don't think 1:1 will be frequent. Most cost rows require at least four elements, supplier, terminal, product (STP), plus some equivelent to a fuel contract as the 4th column.
3. Should target projection live in the same structure as canonical identity, or in a downstream projection layer keyed off the canonical entity?
    - I don't know, and I'm not clear on what you mean.
4. What is the human workflow for unresolved rows: propose, review, approve, activate, retire?
    - I see this working as a page on a web-app that includes all xrefs required in a particular domain. The user has something like a drop down list of available xrefs and they can alter the factors on a table container inside the filtered page.
5. Which domain is the stress test: contracts, products, or customers? I’d use contracts first because they usually expose the cracks fastest.
    - Contracts for sure are the trickiest.

## Response to my questions

1. PDI should be treated as the practical canonical anchor for now, but not as a permanent law of the model. That means the design can be PDI-first without being PDI-hardcoded. In plain terms: for most domains, the canonical answer will probably end up being a PDI identity, but the standard should still say “canonical identity is resolved here” rather than “PDI always is the identity.” That gives you room if one domain later breaks that assumption.

2. On target projection: this is the distinction you asked about. Canonical mapping means “what business thing is this row referring to?” Target projection means “what exact code, key, or shape do we send to system X?” Example: a Gravitate contract-like row might resolve to one real business contract. That is identity resolution. The choice of which PDI `FuelCont_ID`, product code, or other target fields get emitted for that resolved thing is projection. If you keep them conceptually separate, you avoid a future problem where changing a PDI output rule looks like the business identity itself changed. For phase 1, they can live very close together, especially if PDI is usually the answer, but I would still keep the concepts distinct in the design doc.

3. Your lifecycle answer suggests you do not need a heavy approval workflow on day one. You need a pragmatic bootstrap model:
   1. Seed from current xrefs and CITT clones.
   2. Surface unresolved or suspicious rows.
   3. Let operators map source equivalents to approved destination truth.
   4. Have you as final approver when needed.
   5. Let the rest be normal business stewardship over time.

   That is much simpler and more realistic than designing a full enterprise workflow engine upfront.

4. Ownership is good enough for now if the rule is: domain stewardship may be distributed, final authority is Jason. You do not need the perfect org chart before you define the technical pattern. You do need one explicit rule in the design: no mapping becomes authoritative unless it lands in the canonical authority surface.

5. Your day-one UX requirement is the most important constraint in the whole discussion. The human surface should not look like a generic registry editor. It should look like a domain page with unresolved source-side values and destination-truth dropdowns, filtered to the domain the user is working in. That pushes strongly against “one generic table as the primary human interface” and toward “one canonical authority with domain-specific stewardship surfaces.”

The biggest implication from your answers is this: I would no longer describe the target design as “one physical registry table” unless you mean that only as an internal implementation option. The stronger design statement is: one canonical authority, domain-specific stewardship surfaces, and pipeline-safe views. That matches your actual operating need much better than a storage-first statement.

The contracts answer is also decisive. Since contracts are composite and rarely simple 1:1 lookups, they should be the stress test. If the model cannot represent supplier + terminal + product + contract-context cleanly for both humans and pipelines, it is the wrong model. That is why I would be very cautious about a single `Source_Code` style abstraction as the primary mental model.

My recommendation at this point:

1. Keep “single canonical authority in PricingLink” as the core rule.
2. Drop or soften “single physical registry table” from the current draft.
3. Make “domain-specific stewardship surfaces” a first-class design principle.
4. State explicitly that PDI is the likely practical canonical anchor in many domains, but not an invariant.
5. Use contracts as the first decision test before any schema design.

If you want, the next useful step is for me to rewrite this into a tighter decision memo that reflects your answers and replaces the ambiguous parts, especially around target projection and the stewardship model.

---

I’m turning this into a staged artifact sequence so you can see the build order before any schema or UI work gets locked in.

If you build this the way I’m suggesting, the artifact sequence should force semantic clarity and stewardship design before any schema gets blessed. The minimum serious sequence is this:

1. Problem and scope brief.
Defines the failure mode you are actually solving: state spread, semantic confusion, duplicated bridge logic, and agent misuse of the wrong xref surface.

2. Current-state xref inventory.
Catalogs every existing xref, bridge table, clone, and CITT-derived surface, including where it lives, what it does, who uses it, and whether it is normalization, identity, projection, or unclear.

3. Contracts stress-test brief.
Takes the hardest domain first and documents the real grain, likely something close to supplier + terminal + product + contract context, plus date/effective nuances and known exceptions.

4. Canonical mapping ADR.
Records the core decisions: one canonical authority in PricingLink, separation of edge normalization from canonical identity, pipelines consuming named contract views, and PDI treated as the likely practical anchor but not an unbreakable law.

5. `PROJECT_PLANNING_MANIFEST`.
Serves as the planning index that ties the prior artifacts together, lists open decisions, and states what must be true before design work starts.

6. Stewardship lifecycle and governance spec.
Defines how mappings come into the system and change over time: bootstrap from current xrefs, unresolved-row handling, who can edit, when your approval is required, and how rows are retired without creating silent drift.

7. Stewardship UX requirements pack.
Describes the human surface by domain: unresolved work queue, filters, source-side values, destination-truth dropdowns, search, audit visibility, and the exact actions a steward can take on day one.

8. Canonical information model.
Defines the logical model independent of storage choice: domains, source systems, canonical entities, projection concepts, composite identity rules, statuses, effective dating, and audit semantics.

9. Physical architecture decision memo.
Settles the storage shape after the semantics are known: single registry table plus domain views, or canonical core plus domain-shaped stewardship surfaces. This is where storage follows meaning, not the other way around.

10. Domain contract spec for Contracts.
Defines the first domain-specific contract in detail: required fields, valid combinations, uniqueness rules, resolution outcomes, and what the steward page and pipeline view must expose.

11. Pipeline consumption contract spec.
Defines the sanctioned read surfaces for downstream jobs: naming, columns, guarantees, blocking behavior, and the explicit rule that pipelines do not join raw canonical storage directly.

12. Seed and remediation workbook.
Maps current xrefs and CITT clones into the target model, shows conflicts, identifies duplicate or contradictory mappings, and separates auto-seedable rows from manual-review rows.

13. Build spec package.
Turns the approved design into implementation-ready detail: DDL, governed lookup dimensions, constraints, view definitions, API/page behavior, audit fields, and migration script requirements.

14. Validation and reconciliation plan.
Defines how you prove the new model is correct: uniqueness checks, ambiguous-match blocking, inactive-row behavior, effective-date behavior, and side-by-side comparison of legacy outputs versus new outputs.

15. Steward operations runbook.
Explains how people actually live with it: add mappings, fix unresolved rows, handle duplicates, retire stale mappings, and diagnose why a pipeline row did or did not resolve.

16. Release and deprecation plan.
Specifies rollout order, cutover checkpoints, legacy bridge tables to freeze or retire, fallback steps, and what metrics prove the new authority surface is actually replacing state spread.

If I were compressing this into the leanest workable package, I would merge `1-5` into one planning packet, `6-11` into one design packet, and keep `12-16` as execution artifacts. The main sequencing rule is simple: do not write final DDL until the contracts stress test, stewardship UX, and canonical-vs-projection decisions are nailed down.

If you want, I can turn this into a cleaner stage-gated artifact map with explicit Plan -> Design -> Build -> Validate -> UX -> Review -> Release outputs.
