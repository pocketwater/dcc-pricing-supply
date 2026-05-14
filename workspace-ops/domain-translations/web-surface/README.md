# XREF Translation Surface — Web App

A single-page web application for viewing, searching, filtering, and managing Gravitate → PDI translation tables in the canonical Xref_Registry.

---

## Features

✅ **Dropdown Table Selection** — View new registry view + legacy tables pending migration  
✅ **Search & Filter** — Find specific rows by any column  
✅ **Export to CSV** — Download table data for offline analysis  
✅ **Append-Only Row Addition** — Add new mappings to the registry (registry_contract only)  
✅ **Row Statistics** — View row count and column count for current table  
✅ **Windows Auth** — Connects directly to PDI-SQL-02 using Windows authentication (local)  

---

## Scope

**In Scope (v1):**
- `vw_Xref_Contract_Gravitate_To_PDI` (NEW — read/write)
- `PDI_CITT_Axxis_Grav_PDI_Products_Clone` (legacy — read-only)
- `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone` (legacy — read-only)
- `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone` (legacy — read-only)
- `Gravitate_PDI_Master_XREF` (legacy — read-only)

**Out of Scope (v1):**
- COL_WH database (separate instance)
- Data editing/update operations (append-only)

---

## Local Setup

### Prerequisites

- **Node.js** >= 18.0.0 ([download](https://nodejs.org/))
- **Network access** to PDI-SQL-02 from your local machine
- **Windows authentication** enabled (runs on domain account)

### Installation

1. Navigate to the web-surface directory:
   ```bash
   cd "dcc-pricing-supply/workspace-ops/domain-translations/web-surface"
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the server:
   ```bash
   npm start
   ```

   Or for development (auto-reload on file changes):
   ```bash
   npm run dev
   ```

4. Open browser to: **http://localhost:3000**

---

## Usage

### View a Table

1. Click the **"Select Table"** dropdown
2. Choose a table (registry_contract recommended for new data)
3. Table data loads automatically

### Search Rows

1. Enter a search term in the **Search** field
2. Select the **Column** to search in
3. Click **Search**
4. Results update in-table

### Export Data

1. Select a table
2. Click **Export to CSV**
3. File downloads (e.g., `registry_contract_2026-05-13.csv`)

### Add New Row (Registry Only)

1. Select `registry_contract` table
2. Click **+ Add Row**
3. Fill in form fields:
   - `Gravitate_Vendor` — e.g., `phillips66`, `colemanoil`
   - `Gravitate_Price_Type` — `branded`, `rack`, or `contract`
   - `Gravitate_Trmnl_Name` — e.g., `spokanehl`, `missoulaco`
   - `Gravitate_Bucket` — e.g., `wa`, `mtcsv`, `exwa`
   - `PDI_FuelCont_ID` — e.g., `P66.U.R`, `COL.U.R.X`
   - `PDI_Trmnl_Key` — numeric key (e.g., 10, 28)
   - `PDI_Vend_Key` — numeric key (e.g., 32, 13717)
   - `PDI_FuelCont_Key` — numeric key (e.g., 6, 7)
4. Click **Save**

---

## Database Connection

### Local Development (Windows Auth)

The app connects using Windows integrated authentication:
- **Server:** PDI-SQL-02
- **Database:** PDI_PricingLink (COL_WH schema)
- **Auth:** Trusted Connection (Windows domain account)

**Note:** You must be on the network or connected via VPN to reach PDI-SQL-02.

### Production / Azure Deployment

When deploying to Azure, you'll need to:

1. Set environment variables:
   ```bash
   DB_SERVER=<PDI-SQL-02 or connection string>
   DB_NAME=PDI_PricingLink
   DB_USER=<service account username>
   DB_PASSWORD=<service account password>
   ```

2. Update `server.js` to use `dbConfig` instead of `localDbConfig` (see comments in code)

3. Configure Azure App Service networking to reach PDI-SQL-02

---

## API Endpoints

All endpoints are prefixed with `/api`:

### GET /tables
Returns list of available tables.

**Response:**
```json
[
  { "id": "registry_contract", "name": "Registry — Gravitate Contract (NEW)", "editable": true },
  { "id": "legacy_products", "name": "Legacy — CITT Products Clone (PENDING MIGRATION)", "editable": false }
]
```

### GET /table/:tableId
Returns table data with optional search/filter.

**Query Params:**
- `search` — search term (optional)
- `column` — column to search in (optional)

**Response:**
```json
{
  "table": "registry_contract",
  "name": "Registry — Gravitate Contract (NEW)",
  "rowCount": 200,
  "columns": ["Gravitate_Vendor", "Gravitate_Price_Type", ...],
  "rows": [...]
}
```

### GET /table/:tableId/stats
Returns row count and column count.

### GET /table/:tableId/export
Downloads table as CSV file.

### POST /table/registry_contract/append
Appends a new row to the registry.

**Body:**
```json
{
  "Gravitate_Vendor": "phillips66",
  "Gravitate_Price_Type": "branded",
  "Gravitate_Trmnl_Name": "spokanehl",
  "Gravitate_Bucket": "wa",
  "PDI_FuelCont_ID": "P66.B.R",
  "PDI_Trmnl_Key": 10,
  "PDI_Vend_Key": 32,
  "PDI_FuelCont_Key": 6
}
```

---

## Troubleshooting

### Connection Error: "Cannot connect to PDI-SQL-02"

**Cause:** Network issue or server not reachable

**Solution:**
1. Verify you're on the network or connected via VPN
2. Test connection: `ping PDI-SQL-02`
3. Verify port 1433 is reachable: `telnet PDI-SQL-02 1433`

### No Tables in Dropdown

**Cause:** Database connection failed

**Solution:**
1. Check browser console (F12) for error messages
2. Verify Windows auth is working (`whoami` in PowerShell)
3. Restart the server: `npm start`

### Add Row Form Not Appearing

**Cause:** Table must be registry_contract and editable=true

**Solution:**
1. Select `registry_contract` from dropdown
2. Verify the table is showing in the list (not read-only)

### Export Not Working

**Cause:** CORS or API issue

**Solution:**
1. Check browser console for errors
2. Ensure server is running on port 3000
3. Try refreshing the page

---

## File Structure

```
web-surface/
├── package.json              # Node dependencies and scripts
├── server.js                 # Express backend, API routes, DB config
└── public/
    └── index.html            # Single-page app (HTML/CSS/JS)
```

---

## Security Notes

⚠️ **Local Development Only (v1)**
- No authentication layer in frontend
- All database operations use logged-in Windows account
- Append-only writes to maintain data integrity
- Not suitable for public internet exposure

**Before Azure deployment:**
1. Add API authentication (OAuth, API keys, etc.)
2. Implement row-level security for sensitive data
3. Add audit logging for all writes
4. Enable HTTPS
5. Restrict IP access

---

## Performance

- **Typical Load Time:** < 2 seconds for 200-row table
- **Search Performance:** ~1 second for 200 rows
- **Export Speed:** < 5 seconds for 200 rows to CSV

For larger datasets, consider pagination or filtering on the server.

---

## Maintenance

### Update Dependencies

```bash
npm update
npm audit fix
```

### Monitor Server Health

```bash
curl http://localhost:3000/api/health
```

Expected response:
```json
{ "status": "ok", "database": "PDI-SQL-02", "instance": "PDI_PricingLink" }
```

### View Logs

Server logs print to console. For production, redirect to file:

```bash
npm start > server.log 2>&1 &
```

---

## Future Enhancements

- [ ] Pagination for large tables (1000+ rows)
- [ ] Row-level edit/update capabilities
- [ ] Audit trail of all append operations
- [ ] Comparison view (legacy vs. registry)
- [ ] Bulk import from CSV
- [ ] Advanced filtering (date ranges, multi-column)
- [ ] User authentication layer
- [ ] Dark mode

---

## Contact

**Created:** 2026-05-13  
**Owner:** COIL Pricing Supply Team  
**Support:** Pete (Copilot)
