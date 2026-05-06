SET NOCOUNT ON;

PRINT '=== FUNCTIONAL TEST BOOTSTRAP v0 (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);
PRINT 'Server: ' + @@SERVERNAME;
PRINT 'Database: ' + DB_NAME();

-- 1) Build-object preflight
SELECT 'preflight_xref_registry_exists' AS test_name,
       CASE WHEN OBJECT_ID('dbo.Xref_Registry','U') IS NULL THEN 0 ELSE 1 END AS pass_flag;

SELECT 'preflight_contract_views_exist' AS test_name,
       SUM(CASE WHEN OBJECT_ID(v.view_name,'V') IS NOT NULL THEN 1 ELSE 0 END) AS existing_count,
       COUNT(*) AS required_count
FROM (VALUES
    ('dbo.vw_Xref_Product_Gravitate_To_PDI'),
    ('dbo.vw_Xref_Terminal_Gravitate_To_PDI'),
    ('dbo.vw_Xref_Contract_Axxis_To_PDI'),
    ('dbo.vw_Xref_Destination_Gravitate_To_PDI')
) v(view_name);

-- 2) Legacy inventory discovery (xref/citt/mapping)
SELECT t.name AS table_name,
       SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.name LIKE '%XREF%'
   OR t.name LIKE '%CITT%'
   OR t.name LIKE '%Mapping%'
GROUP BY t.name
ORDER BY t.name;

-- 3) Contract Source_Key_4 discovery support
SELECT 'contract_type_distribution_raw' AS test_name,
       Contract_Type,
       COUNT(*) AS row_count
FROM dbo.CitySV_Gravitate_Orders_Ingest_Raw
GROUP BY Contract_Type
ORDER BY row_count DESC;

SELECT 'contract_type_distribution_xref' AS test_name,
       Contract_Type,
       COUNT(*) AS row_count
FROM dbo.CitySV_OrdersUpload_GravitateVendor_XREF
GROUP BY Contract_Type
ORDER BY row_count DESC;

PRINT '=== END FUNCTIONAL TEST BOOTSTRAP v0 ===';
