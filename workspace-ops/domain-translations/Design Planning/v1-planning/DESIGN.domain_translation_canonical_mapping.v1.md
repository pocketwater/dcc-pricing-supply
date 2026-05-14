# V1 Design Specification: Registry Entries and Contract Views

**Iteration:** v1
**Component:** Gravitate Product/Terminal/Vendor Domain Canonicalization (PricingLink Only)
**Date:** 2026-05-13

## Scope Constraint (Critical)

**Database/Pipeline Boundary:**
- **IN SCOPE (v1):** PDI_PricingLink — Gravitate FTP pricing feed (`sp_Gravitate_FTP_UPLOAD_SELECT` and dependent procedures)
- **OUT OF SCOPE (v1):** COL_WH — `sp_Gravitate_Price_Feed` remains independent; separate migration if/when needed

This design applies exclusively to the PricingLink Gravitate pricing feed. COL_WH operations are out of scope for this iteration.

---

## Registry Entry Design

**CRITICAL CORRECTION (2026-05-13):** Production surface analysis reveals the current working mappings are **NOT** three separate grain-silos (Product, Terminal, Vendor), but rather a **single 4-key composite mapping** from Gravitate operational attributes → PDI contract identity. This section has been revised to match production reality.

---

### Domain: Contract (Gravitate STP → PDI)

**Source:** `Gravitate_PDI-SQL-02_XREF_Prod` (production surface; currently realized as views over CITT clones + Gravitate_PDI_Master_XREF)
**Target:** `Xref_Registry`

**Production Surface Inventory:**
- **200 active rows** representing the complete, working set of vendor/price-type/terminal/bucket → PDI FuelCont mappings
- **17 vendors**, **3 price types** (branded, contract, rack), **49 terminals**, **26 buckets**, **28 unique PDI FuelCont IDs**
- **Multi-type mapping pattern:** 7 vendor/terminal/bucket combinations legitimately map to **multiple PDI FuelCont IDs** depending on price type (e.g., phillips66/albuquerqeco/nm → {P66.B.R, P66.U.R})

**Mapping Key Structure (4-dimensional composite):**
```
(Gravitate_Vendor, Gravitate_Price_Type, Gravitate_Trmnl_Name, Gravitate_Bucket)
    → PDI_FuelCont_ID + PDI_FuelCont_Key + PDI_Trmnl_Key + PDI_Vend_Key
```

| Field | Value | Notes |
|-------|-------|-------|
| `Domain_Name` | `Contract` | Single unified domain (Fuel Contract identity resolution) |
| `Source_System` | `Gravitate` | Gravitate operational naming (vendor/price-type/terminal/bucket) |
| `Target_System` | `PDI` | Maps to PDI contract identity (FuelCont_ID, FuelCont_Key) |
| `Workgroup` | `COIL-Pricing-Supply` | Portfolio ownership |
| `Owning_Pipeline` | `CitySV_Costs` / `CitySV_Prices` / `Gravitate-Orders` | Consuming pipelines |
| `Source_Key_1` | Gravitate Vendor (e.g., `phillips66`, `colemanoil`) | Supplier brand/legal entity |
| `Source_Key_2` | Gravitate Price Type (e.g., `branded`, `rack`, `contract`) | Pricing model/contract type |
| `Source_Key_3` | Gravitate Terminal Name (e.g., `spokanehl`, `missoulaco`) | Supply location identifier |
| `Source_Key_4` | Gravitate Bucket (e.g., `wa`, `wacsv`, `exwa`, `mtcsv`) | Geographic/service tier bucket |
| `Target_Key` | PDI `FuelCont_Key` (numeric) | From `PDI_Fuel_Contracts_Clone` |
| `Target_Code` | PDI `FuelCont_ID` (varchar) | Cached contract identifier (e.g., `P66.U.R`, `COL.U.R.X`) |
| `Target_Secondary_1` | PDI `Trmnl_Key` (numeric) | Terminal reference (cached for join efficiency) |
| `Target_Secondary_2` | PDI `Vend_Key` (numeric) | Vendor reference (cached for join efficiency) |
| `Resolution_Status` | `ACTIVE` | All seed rows active on deploy |
| `Effective_From` | Deployment date (2026-05-13) | v1 cutover date |
| `Consuming_Views` | `vw_Xref_Contract_Gravitate_To_PDI` | Contract view name (replaces scattered joins) |
| `Source_Description` | `Seeded from Gravitate_PDI-SQL-02_XREF_Prod production surface` | Authoritative audit trail |

**Seed Data Source:**
Production surface CSV (200 rows) provides the authoritative, currently-working mappings. No inference or join logic required; all rows are proven-live in production.

**Data Quality Noted:**
- Newline character in vendor `seaportsp` — to be cleaned during seed
- 7 multi-type mappings (phillips66, wyoming) confirmed as legitimate (different price types → different contracts for same terminal/bucket)

**Row Count:** 200 (from production surface; represents complete operational mapping state)

---

## Contract View Definitions

### vw_Xref_Product_Gravitate_To_PDI

**Purpose:** Replace direct joins to `PDI_CITT_Axxis_Grav_PDI_Products_Clone`

**Schema:**
```sql
CREATE VIEW dbo.vw_Xref_Product_Gravitate_To_PDI AS
SELECT
    Gravitate_ProductCode = X.Source_Key_1,
    PDI_Prod_Key = TRY_CAST(X.Target_Key AS int),
    PDI_Prod_ID = X.Target_Code,
    Is_Active = X.Is_Active
FROM dbo.Xref_Registry X
WHERE X.Domain_Name = 'Product'
  AND X.Source_System = 'Axxis'
  AND X.Target_System = 'PDI'
  AND X.Is_Active = 1;
```

**Consumption:** Replace joins in:
- `vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice` (current: `PDI_CITT_Axxis_Grav_PDI_Products_Clone`)

---

### vw_Xref_Terminal_Gravitate_To_PDI

**Purpose:** Replace direct joins to `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone`

**Schema:**
```sql
CREATE VIEW dbo.vw_Xref_Terminal_Gravitate_To_PDI AS
SELECT
    Axxis_TerminalCode = X.Source_Key_1,
    PDI_Trmnl_Key = TRY_CAST(X.Target_Key AS int),
    PDI_Trmnl_ID = X.Target_Code,
    Is_Active = X.Is_Active
FROM dbo.Xref_Registry X
WHERE X.Domain_Name = 'Terminal'
  AND X.Source_System = 'Axxis'
  AND X.Target_System = 'PDI'
  AND X.Is_Active = 1;
```

**Consumption:** Replace joins in:
- `vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice` (current: `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone`)

---

### vw_Xref_Contract_Axxis_To_PDI

**Purpose:** Replace direct joins to `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone`

**Schema:**
```sql
CREATE VIEW dbo.vw_Xref_Contract_Axxis_To_PDI AS
SELECT
    Axxis_VendorCode = X.Source_Key_1,
    PDI_FuelCont_Key = TRY_CAST(X.Target_Key AS int),
    PDI_FuelCont_ID = X.Target_Code,
    Is_Active = X.Is_Active
FROM dbo.Xref_Registry X
WHERE X.Domain_Name = 'Contract'
  AND X.Source_System = 'Axxis'
  AND X.Target_System = 'PDI'
  AND X.Is_Active = 1;
```

**Consumption:** Replace joins in:
- `vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice` (current: `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone`)

---

## Deprecation & Freeze Plan

### Phase 1: Seed & Freeze (v1 deploy)
1. Create registry entries from CITT clones
2. Create contract views
3. Freeze legacy CITT tables (rename to `_Freeze`)
4. Create compatibility shims (optional, for safety)

### Phase 2: Repoint (v1 + 2 weeks)
1. Update `vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice` to join contract views
2. Validate FTP upload output unchanged
3. Validate cost-resolution pipeline unchanged
4. Remove compatibility shims

### Phase 3: Removal (v1 + 4 weeks)
1. Drop frozen CITT tables
2. Archive seed scripts in git history
3. Update workspace-ops documentation

---

## Validation Gates

- [ ] Registry seed row count matches CITT source (product: 58, terminal: 90, vendor: 53)
- [ ] Contract view joins produce identical result sets to legacy CITT joins (on key columns)
- [ ] `sp_Gravitate_FTP_UPLOAD_SELECT` output unchanged (row count, schema)
- [ ] Cost-resolution pipeline STP grain preserved
- [ ] No new join errors in citysv-prices downstream consumers
