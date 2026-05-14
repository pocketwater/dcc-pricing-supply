# V1 Design Specification: Registry Entries and Contract Views

**Iteration:** v1  
**Component:** Gravitate Product/Terminal/Vendor Domain Canonicalization  
**Date:** 2026-05-13

---

## Registry Entry Design

### Domain: Product (Gravitate → PDI)

**Source:** `PDI_CITT_Axxis_Grav_PDI_Products_Clone`  
**Target:** `Xref_Registry`  
**Legacy Replacement:** `CitySV_OrdersUpload_GravitateProduct_XREF`

| Field | Value | Notes |
|-------|-------|-------|
| `Domain_Name` | `Product` | Primary business domain |
| `Source_System` | `Axxis` | From CITT clone of Axxis product codes |
| `Target_System` | `PDI` | Maps to PDI product identity |
| `Workgroup` | `COIL-Pricing-Supply` | Portfolio ownership |
| `Owning_Pipeline` | `CitySV_Prices` / `CitySV_Costs` | Consuming pipeline |
| `Source_Key_1` | Axxis product code (e.g., `87e10`, `no2ulr`) | Normalized to lowercase |
| `Target_Key` | PDI `Prod_Key` (numeric) | From `PDI_Products_Clone` |
| `Target_Code` | PDI `Prod_ID` (varchar) | Cached `_ID` for reference |
| `Resolution_Status` | `ACTIVE` | All seed rows active on deploy |
| `Effective_From` | Deployment date (2026-05-13) | v1 cutover date |
| `Consuming_Views` | `vw_Xref_Product_Gravitate_To_PDI` | Contract view name |
| `Source_Description` | `Seeded from PDI_CITT_Axxis_Grav_PDI_Products_Clone` | Audit trail |

**Seed Query Logic:**
```sql
SELECT DISTINCT
    Domain_Name = 'Product',
    Source_System = 'Axxis',
    Target_System = 'PDI',
    Source_Key_1 = LOWER(TRIM(C.PDI_Prod_ID)),
    Target_Key = P.Prod_Key,
    Target_Code = P.Prod_ID,
    ...
FROM PDI_CITT_Axxis_Grav_PDI_Products_Clone C
JOIN PDI_Products_Clone P ON P.Prod_Key = (SELECT TOP 1 Prod_Key FROM PDI_Products_Clone WHERE Prod_ID = C.PDI_Prod_ID)
```

**Row Count:** ~58 (from CITT clone)

---

### Domain: Terminal (Axxis → PDI)

**Source:** `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone`  
**Target:** `Xref_Registry`  
**Legacy Replacement:** `CitySV_OrdersUpload_GravitateTerminal_XREF` (future)

| Field | Value | Notes |
|-------|-------|-------|
| `Domain_Name` | `Terminal` | Primary business domain |
| `Source_System` | `Axxis` | From CITT clone of Axxis terminal codes |
| `Target_System` | `PDI` | Maps to PDI terminal identity |
| `Workgroup` | `COIL-Pricing-Supply` | Portfolio ownership |
| `Owning_Pipeline` | `CitySV_Costs` | Cost-resolution pipeline |
| `Source_Key_1` | Axxis terminal code (e.g., `spokanehl`, `greatflsco`) | Normalized |
| `Target_Key` | PDI `Trmnl_Key` (numeric) | From `PDI_Terminals_Clone` |
| `Target_Code` | PDI `Trmnl_ID` (varchar) | Cached `_ID` for reference |
| `Resolution_Status` | `ACTIVE` | All seed rows active on deploy |
| `Effective_From` | Deployment date | v1 cutover date |
| `Consuming_Views` | `vw_Xref_Terminal_Gravitate_To_PDI` | Contract view name |

**Row Count:** ~90 (from CITT clone)

---

### Domain: Vendor/Contract (Axxis STP → PDI)

**Source:** `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone`  
**Target:** `Xref_Registry`  
**Legacy Replacement:** None (new domain grain)

| Field | Value | Notes |
|-------|-------|-------|
| `Domain_Name` | `Contract` | Business domain (Fuel Contract) |
| `Source_System` | `Axxis` | From CITT clone of Axxis vendor/FIVC codes |
| `Target_System` | `PDI` | Maps to PDI fuel contract identity |
| `Workgroup` | `COIL-Pricing-Supply` | Portfolio ownership |
| `Owning_Pipeline` | `CitySV_Costs` / `CitySV_Prices` | Cost/price resolution pipelines |
| `Source_Key_1` | Axxis vendor code (e.g., `P66B887238`) | Supplier/contract identifier |
| `Target_Key` | PDI `FuelCont_Key` (numeric) | From `PDI_Fuel_Contracts_Clone` |
| `Target_Code` | PDI `FuelCont_ID` (varchar) | Cached `_ID` (e.g., `P66.U.R`) |
| `Resolution_Status` | `ACTIVE` | All seed rows active on deploy |
| `Effective_From` | Deployment date | v1 cutover date |
| `Consuming_Views` | `vw_Xref_Contract_Axxis_To_PDI` | Contract view name |

**Row Count:** ~53 (from CITT clone)

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
