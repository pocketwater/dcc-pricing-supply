# Gravitate API — Endpoint Inventory
**Tenant:** `coleman` | **Base URL:** `https://coleman.bb.gravitate.energy/api/`
**Auth:** OAuth2 client credentials — `POST /token` → JWT bearer
**Scope in use:** `bbd` (bulk buy dispatch)
**Last explored:** 2026-05-07 (exhaustive probe — 102 paths tested)

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Confirmed working (HTTP 200, live data) |
| 🔒 | Endpoint exists, scope insufficient (HTTP 401) |
| ❌ | Not found under our tenant/scope (HTTP 404) |
| ✏️ | Write endpoint — not probed (production risk) |

---

## Authentication

### `POST /token`
Form-encoded body (not JSON):

| Field | Value |
|---|---|
| `client_id` | `acf14797ea0a13b9360c10300b06488d6d279d7cb8d7d1ba` |
| `client_secret` | *(in 1Password)* |
| `scope` | `bbd` |

Returns `{ access_token, token_type, expires_in }`. Pass as `Authorization: Bearer <token>`.

---

## Master Data Endpoints — all ✅, all `POST {}` (empty body returns full catalog)

| Endpoint | Records | Key Fields |
|---|---|---|
| `v1/location/all` | **2,574** | id, name, short_name, market, market_id, type, lat, lon, address, city, state, active, timezone, source_id, source_system_id, supply_zones, dwells, geofence |
| `v1/counterparty/all` | **1,730** | id, name, goid, scac, types[], carrier_type, trailer_config, source_id |
| `v1/trailer/all` | **116** | id, trailer_number, configuration, depot, make, model, weight, updated_on |
| `v1/tractor/all` | **117** | id, tractor_number, depot, depot_id, vin, model, make, year |
| `v1/driver/all` | **192** | id, name, username, depot_id, depot_name, in_cab_trip_mode, trailer_number |
| `v1/product/all` | **162** | id, name, short_name, group, weight_group, source_id, source_system_id, blends[], grade, brand |
| `v1/depot/all` | **24** | key, id, name, city, state, postal_code, market, sector |
| `v1/market/all` | **14** | id, name, network_radius, active, trailer_config, sectors[] |
| `v1/store/all` | **2,395** | _id, store_number, name, market, market_id, sector, sector_id, tanks[] |

**PDI join key:** On `v1/product/all` — `source_system_id = "PDI"` and `source_id` = PDI product code.
**Tanks:** `v1/store/all` has a `tanks[]` field in schema but was empty across all 2,395 records in this tenant.

### `v1/location/all` — full field sample
```json
{
  "id": "64302c6f879bcd7ac951f06f",
  "name": "Anacortes", "short_name": "Anacortes",
  "market": "Bellingham", "market_id": "64302553a4db1ee3823c1bf1",
  "type": "Depot",
  "lat": 48.4586, "lon": -122.5344,
  "address": "9783 Padilla Heights Rd", "city": "Anacortes", "state": "WA",
  "active": true, "timezone": "America/Los_Angeles",
  "source_id": null, "source_system": "", "source_system_id": "",
  "supply_zones": [], "dwells": [{"product_group": "default", "set_dwell": 30}],
  "geofence": [], "supply_map": [], "tcn": null, "store_id": null, "extra_data": {}
}
```

### `v1/product/all` — full field sample
```json
{
  "id": "64302059879bcd7ac951f05d",
  "name": "Ethanol E100", "short_name": "E100",
  "group": "Ethanol", "weight_group": "ETHANOL",
  "source_id": "ethanl", "source_system": null, "source_system_id": "PDI",
  "blends": [], "alternate_products": [],
  "grade": null, "mf_rating": null, "oxy_type": null, "brand": null,
  "extra_data": {"source_id": "ethanl", "source_system_id": "PDI"}
}
```

---

## Order Data Endpoints

### `v2/order/freight` ✅ — PRIMARY ORDER SOURCE

Returns completed order freight detail. One record per order, with a `freight_items[]` array (one item per product line).

**Filters (POST body):**

| Filter | Type | Notes |
|---|---|---|
| `last_change_date` | ISO datetime string | Orders modified since this datetime |
| `order_numbers` | `list[int]` | Specific orders by order number |
| `order_ids` | `list[str]` | Specific orders by internal GUID |

Empty body `{}` returns up to ~3,500 most recent orders.

**Top-level fields:**

| Field | Type | Notes |
|---|---|---|
| `number` | int | Order number — joins to PDI `OrderNumber` |
| `po` | string\|null | Purchase order reference |
| `freight_rate` | float | Blended freight rate across all items |
| `freight_total` | float | Total freight cost for order |
| `freight_items` | list | Per-product-line detail |

**`freight_items[]` fields:**

| Field | Type | Notes |
|---|---|---|
| `type` | string | `"Base Freight"`, `"Undefined"` |
| `subtype` | string | Distance band, e.g. `"Band 10-14"` |
| `rate` | float | Per-gallon freight rate |
| `amount` | float | Volume in UOM |
| `total` | float | `rate × amount` |
| `uom` | string | `"gallons"` or `"Undefined"` |
| `product_group` | string\|null | `"Gasoline"`, `"Diesel"`, etc. |
| `product_id` | string\|null | Gravitate product GUID |
| `product_name` | string\|null | e.g. `"E10 87 Regular"` |
| `origin` / `origin_id` | string\|null | Origin terminal name + GUID |
| `destination` / `destination_id` | string\|null | Delivery site name + GUID |
| `legs[]` | list | Route legs: origin, destination, distance (miles) |
| `gross_volume` | float\|null | Gross gallons loaded |
| `net_volume` | float\|null | Net (temperature-corrected) gallons |
| `ordered_volume` | float\|null | Originally ordered quantity |
| `bol_number` | string\|null | Bill of lading number |
| `bol_date` | ISO datetime\|null | BOL load timestamp |
| `delivery_date` | ISO datetime\|null | Delivery completion timestamp |
| `manual` | bool | True if freight was manually entered |
| `requires_approval` | bool | Approval workflow pending |
| `threshold_violation` | bool | Rate outside configured threshold |
| `exclude_from_invoice` | bool | Billing exclusion flag |
| `extra_data` | dict | Tenant-specific; observed key: `mileage` |

**Full example — populated record:**
```json
{
  "number": 196003, "po": null,
  "freight_rate": 0.0405, "freight_total": 441.63,
  "freight_items": [{
    "type": "Base Freight", "subtype": "Band 10-14",
    "rate": 0.0397, "amount": 7900.0, "total": 313.63, "uom": "gallons",
    "product_name": "E10 87 Regular", "product_group": "Gasoline",
    "origin": "Par Spokane", "destination": "NOMNOM 62134 AIRWAY",
    "legs": [{"origin": "Par Spokane", "destination": "NOMNOM 62134 AIRWAY", "distance": 13.57}],
    "gross_volume": 7900.0, "net_volume": 7914.0, "ordered_volume": 8000.0,
    "bol_number": "575908",
    "bol_date": "2026-05-07T12:40:18.785000",
    "delivery_date": "2026-05-07T14:28:57.084000",
    "extra_data": {"mileage": 14}
  }]
}
```

---

### `v1/order/bol_and_drop` ❌ — 404
All payload variants tested — not present in this tenant's deployment.

---

## Write Endpoints ✏️ — NOT probed

**Warning:** Credentials work against production. Do not call write endpoints unintentionally.

| Endpoint | Purpose | Scope needed |
|---|---|---|
| `v1/price/update_many` | Push fuel prices | `ipd.w` (inferred) |
| `v1/directive/upsert_many` | Upsert supply directives | `ipd.w` (inferred) |
| `v1/order/upsert_routes` | Modify planned routes | `io.w` (inferred) |
| `v1/ebol/create_many` | Create electronic BOLs | `io.w` (inferred) |
| `v1/sales_adjusted_deliveries/upsert_many` | Adjust delivery volumes | `io.w` (inferred) |
| `v1/integration/upload_sales_data` | Push sales data | `i.w` (inferred) |
| `v1/integration/ims_upload_manual` | Manual IMS upload | `i.w` (inferred) |

---

## Scope Boundary Map

Confirmed via exhaustive probe (102 paths, 2026-05-07):

| Scope | Access level | Confirmed endpoints |
|---|---|---|
| `bbd` *(current)* | Supply & dispatch read | 10 endpoints (all master data + `v2/order/freight`) |
| `ia.r` / `i.r` | Integration admin read | Unlocks `v1/price/all`, `v1/terminal/all` (both 401 with `bbd`) |
| `ia.w` / `i.w` | Integration admin write | Upload/sync endpoints (not probed) |
| `io.r` / `io.w` | Order integration | Order write/update endpoints (not probed) |
| `ipd.w` | Pricing & directives write | `v1/price/update_many`, directives (not probed) |

**Probe totals:** 10 working ✅ · 2 scope-blocked 🔒 (`v1/price/all`, `v1/terminal/all`) · 90 not present ❌
To request additional scopes, contact Alejandro Jordan at Gravitate.

---

## Integration Targets

### Priority 1 — Order sync to PDI ODE (active)
**Endpoint:** `v2/order/freight`
**Join key:** `number` ↔ PDI `OrderNumber`; `product.source_id` ↔ PDI product code
**Current path:** SFTP export from Gravitate → PDI ODE. REST API is an available alternative pull path.

### Priority 2 — Price feed push (future)
**Endpoint:** `v1/price/update_many`
**Blocker:** Requires `ipd.w` scope — not in current credentials. Contact Alejandro Jordan.

### Priority 3 — Freight cost reconciliation (future)
**Endpoint:** `v2/order/freight`
**Use case:** Pull per-order, per-leg freight rates/costs for comparison against PDI-calculated freight.

---

## Quick Reference

```powershell
# Smoke test (PowerShell)
& "gravitate-api\smoke-test.ps1" `
  -BaseUrl "https://coleman.bb.gravitate.energy/api/" `
  -ClientId "acf14797ea0a13b9360c10300b06488d6d279d7cb8d7d1ba" `
  -ClientSecret "<from 1Password>"

# Pull last 7 days of orders (PowerShell)
$token = (Invoke-RestMethod -Method Post -Uri "https://coleman.bb.gravitate.energy/api/token" `
  -Body @{client_id="acf14797ea0a13b9360c10300b06488d6d279d7cb8d7d1ba";client_secret="<secret>";scope="bbd"}).access_token
$orders = Invoke-RestMethod -Method Post -Uri "https://coleman.bb.gravitate.energy/api/v2/order/freight" `
  -Headers @{Authorization="Bearer $token"} `
  -ContentType "application/json" `
  -Body '{"last_change_date":"2026-05-01T00:00:00"}'
$orders.Count
```

