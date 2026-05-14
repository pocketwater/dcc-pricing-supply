// ============================================================================
// XREF Translation Surface — Node.js Backend
// Purpose: Serve translation table data, support search/filter/export/append
// Database: PDI-SQL-02 / PDI_PricingLink (COL_WH.dbo)
// ============================================================================

const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const bodyParser = require('body-parser');
const { stringify } = require('csv-stringify/sync');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// ============================================================================
// DATABASE CONFIGURATION
// ============================================================================

const dbConfig = {
  server: process.env.DB_SERVER || 'PDI-SQL-02',
  database: process.env.DB_NAME || 'PDI_PricingLink',
  authentication: {
    type: 'default',
    options: {
      userName: process.env.DB_USER || '',
      password: process.env.DB_PASSWORD || ''
    }
  },
  options: {
    trustServerCertificate: true,
    trustedConnection: true, // Windows Auth
    enableKeepAlive: true,
    connectionTimeout: 15000,
    requestTimeout: 30000
  }
};

// If running locally with Windows Auth, simplify config:
const localDbConfig = {
  server: 'PDI-SQL-02',
  database: 'PDI_PricingLink',
  authentication: {
    type: 'default',
    options: {
      trustedConnection: true
    }
  },
  options: {
    trustServerCertificate: true,
    enableKeepAlive: true
  }
};

let pool;

// Initialize connection pool
async function initDb() {
  try {
    pool = new sql.ConnectionPool(localDbConfig);
    await pool.connect();
    console.log('Database connected: PDI-SQL-02 / PDI_PricingLink');
  } catch (err) {
    console.error('Database connection error:', err);
    process.exit(1);
  }
}

// ============================================================================
// TRANSLATION TABLE DEFINITIONS
// ============================================================================

const TRANSLATION_TABLES = {
  registry_contract: {
    name: 'Registry — Gravitate Contract (NEW)',
    query: `
      SELECT
        Gravitate_Vendor,
        Gravitate_Price_Type,
        Gravitate_Trmnl_Name,
        Gravitate_Bucket,
        PDI_FuelCont_ID,
        PDI_Trmnl_Key,
        PDI_Vend_Key,
        Is_Active,
        Effective_From
      FROM dbo.vw_Xref_Contract_Gravitate_To_PDI
      ORDER BY Gravitate_Vendor, Gravitate_Price_Type, Gravitate_Trmnl_Name, Gravitate_Bucket
    `,
    insertQuery: `
      INSERT INTO dbo.Xref_Registry
      (Domain_Name, Source_System, Target_System, Workgroup, Owning_Pipeline,
       Source_Key_1, Source_Key_2, Source_Key_3, Source_Key_4,
       Target_Key, Target_Code, Target_Secondary_1, Target_Secondary_2,
       Is_Active, Effective_From, Consuming_Views, Source_Description, Created_By, Created_Date)
      VALUES
      ('Contract', 'Gravitate', 'PDI', 'COIL-Pricing-Supply',
       'CitySV_Costs / CitySV_Prices',
       @Source_Key_1, @Source_Key_2, @Source_Key_3, @Source_Key_4,
       @Target_Key, @Target_Code, @Target_Secondary_1, @Target_Secondary_2,
       1, CAST(GETDATE() AS DATE), 'vw_Xref_Contract_Gravitate_To_PDI',
       'Manual append via web surface', 'web-surface-' + SYSTEM_USER, GETDATE())
    `,
    editable: true
  },
  legacy_products: {
    name: 'Legacy — CITT Products Clone (PENDING MIGRATION)',
    query: `
      SELECT * FROM dbo.PDI_CITT_Axxis_Grav_PDI_Products_Clone
      ORDER BY PDI_Prod_ID
    `,
    editable: false
  },
  legacy_terminals: {
    name: 'Legacy — CITT Terminals Clone (PENDING MIGRATION)',
    query: `
      SELECT * FROM dbo.PDI_CITT_Axxis_Grav_PDI_Terminals_Clone
      ORDER BY PDI_Trmnl_ID
    `,
    editable: false
  },
  legacy_vend_fivc: {
    name: 'Legacy — CITT Vendor/FIVC Clone (PENDING MIGRATION)',
    query: `
      SELECT * FROM dbo.PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone
      ORDER BY PDI_Vendor_Code
    `,
    editable: false
  },
  legacy_master_xref: {
    name: 'Legacy — Gravitate PDI Master XREF (PENDING FREEZE)',
    query: `
      SELECT TOP 200 * FROM dbo.Gravitate_PDI_Master_XREF
      ORDER BY Gravitate_Vendor, Gravitate_Trmnl_Name, Gravitate_Bucket
    `,
    editable: false
  }
};

// ============================================================================
// API ROUTES
// ============================================================================

// GET available tables
app.get('/api/tables', (req, res) => {
  const tables = Object.entries(TRANSLATION_TABLES).map(([key, value]) => ({
    id: key,
    name: value.name,
    editable: value.editable
  }));
  res.json(tables);
});

// GET table data with optional search/filter
app.get('/api/table/:tableId', async (req, res) => {
  try {
    const { tableId } = req.params;
    const { search, column } = req.query;

    const tableConfig = TRANSLATION_TABLES[tableId];
    if (!tableConfig) {
      return res.status(404).json({ error: 'Table not found' });
    }

    let query = tableConfig.query;

    // If search provided, add WHERE clause
    if (search && column) {
      query = query.replace(
        'ORDER BY',
        `WHERE ${column} LIKE '%${search.replace(/'/g, "''")}%' ORDER BY`
      );
    }

    const request = new sql.Request(pool);
    const result = await request.query(query);

    res.json({
      table: tableId,
      name: tableConfig.name,
      rowCount: result.recordset.length,
      columns: result.recordset.length > 0 ? Object.keys(result.recordset[0]) : [],
      rows: result.recordset
    });
  } catch (err) {
    console.error('Query error:', err);
    res.status(500).json({ error: err.message });
  }
});

// POST new row (append-only to registry)
app.post('/api/table/registry_contract/append', async (req, res) => {
  try {
    const {
      Gravitate_Vendor,
      Gravitate_Price_Type,
      Gravitate_Trmnl_Name,
      Gravitate_Bucket,
      PDI_FuelCont_ID,
      PDI_Trmnl_Key,
      PDI_Vend_Key,
      PDI_FuelCont_Key
    } = req.body;

    if (!Gravitate_Vendor || !Gravitate_Price_Type || !Gravitate_Trmnl_Name || !Gravitate_Bucket) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const request = new sql.Request(pool);
    request.input('Source_Key_1', sql.VarChar(100), Gravitate_Vendor);
    request.input('Source_Key_2', sql.VarChar(100), Gravitate_Price_Type);
    request.input('Source_Key_3', sql.VarChar(100), Gravitate_Trmnl_Name);
    request.input('Source_Key_4', sql.VarChar(100), Gravitate_Bucket);
    request.input('Target_Key', sql.Int, PDI_FuelCont_Key);
    request.input('Target_Code', sql.VarChar(100), PDI_FuelCont_ID);
    request.input('Target_Secondary_1', sql.Int, PDI_Trmnl_Key);
    request.input('Target_Secondary_2', sql.Int, PDI_Vend_Key);

    const insertQuery = TRANSLATION_TABLES.registry_contract.insertQuery;
    await request.query(insertQuery);

    res.json({ success: true, message: 'Row appended successfully' });
  } catch (err) {
    console.error('Insert error:', err);
    res.status(500).json({ error: err.message });
  }
});

// GET table data as CSV
app.get('/api/table/:tableId/export', async (req, res) => {
  try {
    const { tableId } = req.params;
    const tableConfig = TRANSLATION_TABLES[tableId];

    if (!tableConfig) {
      return res.status(404).json({ error: 'Table not found' });
    }

    const request = new sql.Request(pool);
    const result = await request.query(tableConfig.query);

    const csv = stringify(result.recordset, {
      header: true,
      columns: Object.keys(result.recordset[0] || {})
    });

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="${tableId}_${new Date().toISOString().split('T')[0]}.csv"`);
    res.send(csv);
  } catch (err) {
    console.error('Export error:', err);
    res.status(500).json({ error: err.message });
  }
});

// GET table statistics
app.get('/api/table/:tableId/stats', async (req, res) => {
  try {
    const { tableId } = req.params;
    const tableConfig = TRANSLATION_TABLES[tableId];

    if (!tableConfig) {
      return res.status(404).json({ error: 'Table not found' });
    }

    const request = new sql.Request(pool);
    const result = await request.query(tableConfig.query);

    const rowCount = result.recordset.length;
    const columns = result.recordset.length > 0 ? Object.keys(result.recordset[0]) : [];

    res.json({
      table: tableId,
      rowCount,
      columnCount: columns.length,
      columns
    });
  } catch (err) {
    console.error('Stats error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', database: 'PDI-SQL-02', instance: 'PDI_PricingLink' });
});

// ============================================================================
// START SERVER
// ============================================================================

app.listen(PORT, async () => {
  console.log(`Server running on http://localhost:${PORT}`);
  await initDb();
});

// Graceful shutdown
process.on('SIGINT', async () => {
  if (pool) {
    await pool.close();
  }
  process.exit(0);
});
