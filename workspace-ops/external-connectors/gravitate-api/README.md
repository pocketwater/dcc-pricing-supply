# Gravitate Supply & Dispatch API Connector

This folder contains the initial connector assets to:
- establish authenticated connectivity,
- explore endpoint families,
- document navigation and command patterns,
- prepare integration work for costs in and completed orders out.

## What Is Included

- `gravitate_api_explorer.py`
  - Python endpoint explorer with OAuth token acquisition.
  - Uses client credentials flow against `POST /token`.
  - Can hit any endpoint and print status + body preview.

- `smoke-test.ps1`
  - PowerShell smoke test that validates auth and calls a small set of core endpoints.
  - Good for quick operational checks without Python.

- `endpoint-inventory.md`
  - Curated endpoint map from provided vendor collection.
  - Includes domain grouping and recommended first-pass exploration path.

- `.env.example`
  - Environment variable template for safe local use.

## Prereqs

- Base URL from vendor tenant. Format:
  - `https://coleman.bb.gravitate.energy/api/` ✅ confirmed
- Client credentials with integration scopes.

## Quick Start (PowerShell)

1) Copy `.env.example` values into your session:

```powershell
$env:GRAV_BASE_URL = "https://coleman.bb.gravitate.energy/api/"
$env:GRAV_CLIENT_ID = "<client-id>"
$env:GRAV_CLIENT_SECRET = "<client-secret>"
$env:GRAV_SCOPE = "bbd"
```

2) Run smoke test:

```powershell
.\smoke-test.ps1
```

## Quick Start (Python)

```powershell
python .\gravitate_api_explorer.py --list-default-endpoints
python .\gravitate_api_explorer.py --endpoint v1/location/all
python .\gravitate_api_explorer.py --endpoint v2/order/freight --json '{"last_change_date":"2026-05-01T00:00:00Z"}'
```

## Security Notes

- Do not commit real credentials.
- Prefer environment variables over hard-coded secrets.
- Rotate credentials if they were ever shared in plain text channels.

## Next Integration Targets

- Push fuel cost data:
  - `v1/price/update_many`
- Retrieve completed orders:
  - `v2/order/freight`
  - `v1/order/bol_and_drop` (filter to completed states)
