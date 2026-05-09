# Gravitate API Read Menu Index

Purpose: business-friendly index of what we can actually see right now (no guesses), with row/column shape.

Scope context:
- Tenant: coleman
- Base URL: https://coleman.bb.gravitate.energy/api/
- Current scope: bbd
- Probe basis: exhaustive + safe read-only probe passes completed 2026-05-07 and 2026-05-08

---

## Quick Lingo (Business-User Version)

- Endpoint: one menu item in the API.
- Scope: permission bundle attached to the credential.
- 200: we can read it now.
- 401: endpoint exists but our scope cannot read it.
- 404: exact path tested did not resolve in this tenant.
- Row grain: what one row represents.
- Column shape: field list available on each row.

---

## Confidence Levels (How To Read The Evidence)

- Strong evidence: 200 on an exact path (confirmed readable now).
- Strong evidence: 401 on an exact path (endpoint exists, but blocked by scope).
- Medium evidence: 404 on an exact path (that route is not available at that path here).
- Important caveat: 404 does not prove the capability is absent everywhere. It may exist under a different route name, version, or tenant configuration.
- Discovery finding from safe checks: common route catalogs were not exposed on tested paths (`openapi.json`, `swagger.json`, `api-docs`, etc.), so no authoritative self-listed full menu is currently visible to us.

---

## Read Menu Status Snapshot

| Bucket | Count | Meaning |
|---|---:|---|
| Readable now (200) | 10 | Safe to pull with current credentials/scope |
| Auth-blocked (401) | 2 | Endpoint exists; needs broader read scope |
| Not present (404) | Many tested | Not currently available under tested paths |

Reference detail: see [endpoint-inventory.md](endpoint-inventory.md).

---

## Whole Menu We Can Read Right Now (200)

| Endpoint | Entity | Row grain | Most useful columns (observed) | Typical row count |
|---|---|---|---|---:|
| v1/location/all | Locations | 1 row per location record | id, name, short_name, market, market_id, type, lat, lon, address, city, state, active, timezone, source_id, source_system_id | 2,574 |
| v1/counterparty/all | Counterparties | 1 row per counterparty | id, name, goid, scac, types, carrier_type, trailer_config, source_id | 1,730 |
| v1/trailer/all | Trailers | 1 row per trailer | id, trailer_number, configuration, depot, make, model, weight, updated_on | 116 |
| v1/tractor/all | Tractors | 1 row per tractor | id, tractor_number, depot, depot_id, vin, model, make, year | 117 |
| v1/driver/all | Drivers | 1 row per driver | id, name, username, depot_id, depot_name, in_cab_trip_mode, trailer_number | 192 |
| v1/product/all | Products | 1 row per product | id, name, short_name, group, weight_group, source_id, source_system_id, blends, grade, brand | 162 |
| v1/depot/all | Depots | 1 row per depot | key, id, name, city, state, postal_code, market, sector | 24 |
| v1/market/all | Markets | 1 row per market | id, name, network_radius, active, trailer_config, sectors | 14 |
| v1/store/all | Stores | 1 row per store | _id, store_number, name, market, market_id, sector, sector_id, tanks | 2,395 |
| v2/order/freight | Freighted orders | 1 row per order, with nested line items | number, po, freight_rate, freight_total, freight_items[] | dynamic (filter-dependent) |

Notes:
- v1/store/all includes a tanks column in schema, but tanks[] has been empty in observed tenant data.
- v1/product/all has useful PDI linkage fields: source_system_id and source_id.

---

## Order Shape (v2/order/freight)

### Order-level columns (top row)

| Column | Meaning |
|---|---|
| number | Order number |
| po | Purchase order reference (nullable) |
| freight_rate | Blended freight rate across line items |
| freight_total | Total freight cost for the order |
| freight_items | Array of per-line freight details |

### Freight line columns (inside freight_items[])

| Column | Meaning |
|---|---|
| id | Freight line identifier |
| type | Freight type (example: Base Freight) |
| subtype | Band or subtype (example: Band 10-14) |
| rate | Rate per UOM |
| amount | Quantity in UOM |
| total | Extended freight amount |
| uom | Unit of measure (example: gallons) |
| product_group | Product family |
| product_id | Product identifier |
| product_name | Product display name |
| origin | Origin name |
| origin_id | Origin identifier |
| destination | Destination name |
| destination_id | Destination identifier |
| legs | Route legs with distance |
| gross_volume | Gross quantity |
| net_volume | Net quantity |
| ordered_volume | Ordered quantity |
| bol_number | Bill of lading number |
| bol_date | Lift/load datetime |
| delivery_date | Delivery completion datetime |
| manual | Manual entry flag |
| requires_approval | Approval workflow flag |
| threshold_violation | Pricing/threshold flag |
| exclude_from_invoice | Billing exclusion flag |
| extra_data | Additional payload (observed: mileage) |

---

## Auth-Blocked Read Menu (401)

| Endpoint | What it likely represents | Current status |
|---|---|---|
| v1/price/all | Price catalog feed | Exists, blocked by scope |
| v1/terminal/all | Terminal master feed | Exists, blocked by scope |

Known required scope family from prior probe evidence: ia.r or i.r.

---

## Not Found At Tested Paths (404)

Examples tested and not found:
- v1/order/bol_and_drop
- v1/order/all
- v2/order/all
- v1/order/list
- v2/order/list
- v1/order/get
- v2/order/get
- v1/order/stop/all
- v2/order/stop/all
- v1/order/audit/all
- v2/order/audit/all
- v1/movement/all
- v2/movement/all

Interpretation: these are not auth-blocked at the tested paths; those exact routes did not resolve in this tenant during probe.

---

## How To Talk About This In Business Terms

- We currently have ten live read feeds for master/reference plus freighted orders.
- Pricing and terminal masters are available in platform but blocked by our current permission scope.
- Order details are available through one freight endpoint with nested line-level rows.
- Missing order endpoints are path availability issues (404), not permission issues (401).

---

## Next Step: Get The Authoritative Whole Menu

To move from probe evidence to a complete tenant menu, request Gravitate's official route contract for this tenant and credential scope.

### Ask Packet (Copy/Paste)

Subject: Request for authoritative API route catalog - coleman tenant

Hello Gravitate team,

We need the authoritative API endpoint catalog for our tenant and current credential scope so we can validate read coverage without route-name guessing.

Tenant and auth context:
- Tenant: coleman
- Base URL: https://coleman.bb.gravitate.energy/api/
- Current scope: bbd
- We have confirmed readable routes and some 401/404 outcomes, but no exposed OpenAPI/Swagger catalog on common paths.

Please provide:
1. OpenAPI/Swagger spec for this tenant (JSON or YAML), including path list and request/response schemas.
2. Scope-to-endpoint matrix for our app credentials (which routes are readable/writable by each scope).
3. Version map and aliases (for example any v1 vs v2 replacements).
4. Tenant-enabled feature flags/modules that alter route availability.
5. Any officially supported endpoint-discovery route, if one exists.

Our goal is to build a complete read-menu inventory for business integration planning and avoid unnecessary probe traffic.

Thank you.

### Why This Matters

- 200 and 401 are strong evidence for specific paths.
- 404 only proves an exact path did not resolve.
- A published route contract is the only deterministic source for "whole menu" completeness.
