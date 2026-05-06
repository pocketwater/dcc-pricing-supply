/*
Validation Execution Pack v0
Purpose: Execute checklist items 1-3 with evidence capture-ready result sets.
Notes:
- Run in PDI_PricingLink context.
- Replace placeholders before execution:
  {{PDI_CLONE_DB}} and {{CITT_TABLE_PRODUCT_GRAVITATE_TO_PDI}}
*/

SET NOCOUNT ON;

PRINT '=== START VALIDATION EXECUTION PACK ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);

/* =========================================================
   Item 1: Structure validation execution
   ========================================================= */
PRINT 'Item 1 - Structure validation execution';

-- 1A. Required tables exist
SELECT 'required_table_exists' AS test_name, o.name AS object_name
FROM sys.objects o
WHERE o.type = 'U'
  AND o.name IN (
    'Xref_DomainNames',
    'Xref_SourceSystems',
    'Xref_TargetSystems',
    'Xref_TargetChannels',
    'Xref_Workgroups',
    'Xref_ResolutionStatuses',
    'Xref_Registry'
  )
ORDER BY o.name;

-- 1B. Required views exist
SELECT 'required_view_exists' AS test_name, o.name AS object_name
FROM sys.objects o
WHERE o.type = 'V'
  AND o.name IN (
    'vw_Xref_Product_Gravitate_To_PDI',
    'vw_Xref_Product_Axxis_To_PDI',
    'vw_Xref_Product_PDI_To_Gravitate_API',
    'vw_Xref_Product_PDI_To_Gravitate_FTP',
    'vw_Xref_Terminal_Gravitate_To_PDI',
    'vw_Xref_Terminal_Axxis_To_PDI',
    'vw_Xref_Contract_Axxis_To_PDI',
    'vw_Xref_Destination_Gravitate_To_PDI',
    'vw_Xref_Stewardship_All'
  )
ORDER BY o.name;

-- 1C. Key constraints/indexes exist
SELECT 'constraint_exists' AS test_name, kc.name AS object_name
FROM sys.key_constraints kc
WHERE kc.name IN ('PK_Xref_Registry')
UNION ALL
SELECT 'check_constraint_exists' AS test_name, cc.name AS object_name
FROM sys.check_constraints cc
WHERE cc.name IN ('CK_Xref_Registry_ActiveStatus', 'CK_Xref_Registry_TargetNotNull')
UNION ALL
SELECT 'index_exists' AS test_name, i.name AS object_name
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.Xref_Registry')
  AND i.name IN ('UX_Xref_Registry_ActiveComposite', 'IX_Xref_Registry_Domain_Pipeline', 'IX_Xref_Registry_Resolution_Status')
ORDER BY test_name, object_name;

-- 1D. Duplicate active mapping guardrail (should return 0 rows)
SELECT 'duplicate_active_mappings' AS test_name,
       Domain_Name, Source_System, Target_System, Target_Channel, Composite_Hash,
       COUNT(*) AS active_count
FROM dbo.Xref_Registry
WHERE Is_Active = 1
GROUP BY Domain_Name, Source_System, Target_System, Target_Channel, Composite_Hash
HAVING COUNT(*) > 1;

-- 1E. Active status rule consistency (should return 0 rows)
SELECT 'invalid_active_status_pairings' AS test_name,
       COUNT(*) AS violation_count
FROM dbo.Xref_Registry
WHERE (Is_Active = 1 AND Resolution_Status <> 'ACTIVE')
   OR (Is_Active = 0 AND Resolution_Status = 'ACTIVE');

-- 1F. Orphaned dimension references (should return 0 rows)
SELECT 'orphaned_domain_reference' AS test_name,
       COUNT(*) AS violation_count
FROM dbo.Xref_Registry x
LEFT JOIN dbo.Xref_DomainNames d ON x.Domain_Name = d.Name
WHERE d.Name IS NULL;

/* =========================================================
   Item 2: Lifecycle behavior validation
   ========================================================= */
PRINT 'Item 2 - Lifecycle behavior validation';

-- 2A. Queue counts by state
SELECT 'lifecycle_state_counts' AS test_name,
       Resolution_Status,
       COUNT(*) AS row_count
FROM dbo.Xref_Registry
GROUP BY Resolution_Status
ORDER BY Resolution_Status;

-- 2B. ACTIVE rows must be active (should return 0 rows)
SELECT 'active_rows_not_flagged_active' AS test_name,
       COUNT(*) AS violation_count
FROM dbo.Xref_Registry
WHERE Resolution_Status = 'ACTIVE'
  AND Is_Active <> 1;

-- 2C. RETIRED rows must be inactive (should return 0 rows)
SELECT 'retired_rows_still_active' AS test_name,
       COUNT(*) AS violation_count
FROM dbo.Xref_Registry
WHERE Resolution_Status = 'RETIRED'
  AND Is_Active <> 0;

-- 2D. Queue blockers
SELECT 'queue_blockers' AS test_name,
       SUM(CASE WHEN Resolution_Status = 'UNRESOLVED' THEN 1 ELSE 0 END) AS unresolved_count,
       SUM(CASE WHEN Resolution_Status = 'REVIEW_REQUIRED' THEN 1 ELSE 0 END) AS review_required_count
FROM dbo.Xref_Registry;

/* =========================================================
   Item 3: Contract-view behavior validation
   ========================================================= */
PRINT 'Item 3 - Contract-view behavior validation';

-- 3A. Row counts by key view
SELECT 'view_row_count' AS test_name, 'vw_Xref_Product_Gravitate_To_PDI' AS view_name, COUNT(*) AS row_count
FROM dbo.vw_Xref_Product_Gravitate_To_PDI
UNION ALL
SELECT 'view_row_count', 'vw_Xref_Terminal_Gravitate_To_PDI', COUNT(*)
FROM dbo.vw_Xref_Terminal_Gravitate_To_PDI
UNION ALL
SELECT 'view_row_count', 'vw_Xref_Contract_Axxis_To_PDI', COUNT(*)
FROM dbo.vw_Xref_Contract_Axxis_To_PDI
UNION ALL
SELECT 'view_row_count', 'vw_Xref_Destination_Gravitate_To_PDI', COUNT(*)
FROM dbo.vw_Xref_Destination_Gravitate_To_PDI;

-- 3B. Active-state leak check (should return 0 rows)
SELECT 'active_state_leak_check' AS test_name,
       COUNT(*) AS violation_count
FROM dbo.vw_Xref_Stewardship_All
WHERE Resolution_Status <> 'ACTIVE'
  AND Is_Active = 1;

-- 3C. Product clone parity spot-check (top sample)
-- Replace {{PDI_CLONE_DB}} with actual clone DB name (example: PDI_Clone_DB).
DECLARE @cloneSql nvarchar(max) = N'
SELECT TOP 50
      ''product_clone_spot_check'' AS test_name
    , v.Gravitate_ProductCode
    , v.PDI_FuelProd_Key
    , v.PDI_FuelProd_ID AS view_id
    , c.FuelProd_ID     AS clone_id
    , CASE WHEN v.PDI_FuelProd_ID = c.FuelProd_ID THEN ''MATCH'' ELSE ''MISMATCH'' END AS parity_result
FROM dbo.vw_Xref_Product_Gravitate_To_PDI v
INNER JOIN [{{PDI_CLONE_DB}}].dbo.FuelProducts_Clone c
    ON v.PDI_FuelProd_Key = c.FuelProd_Key
ORDER BY parity_result DESC, v.Gravitate_ProductCode;';
EXEC sp_executesql @cloneSql;

/* =========================================================
   Optional: Item 4 bootstrap parity query (requires table binding)
   ========================================================= */
PRINT 'Optional parity bootstrap - replace placeholders before use';

DECLARE @paritySql nvarchar(max) = N'
SELECT TOP 200
      c.source_column       AS CITT_Source
    , c.target_id_column    AS CITT_Target_ID
    , v.PDI_FuelProd_ID     AS New_Target_ID
    , CASE
        WHEN c.target_id_column = v.PDI_FuelProd_ID THEN ''MATCH''
        ELSE ''MISMATCH''
      END AS Parity_Result
FROM [{{CITT_TABLE_PRODUCT_GRAVITATE_TO_PDI}}] c
LEFT JOIN dbo.vw_Xref_Product_Gravitate_To_PDI v
    ON c.source_column = v.Gravitate_ProductCode
ORDER BY Parity_Result DESC, CITT_Source;';
PRINT @paritySql;

PRINT '=== END VALIDATION EXECUTION PACK ===';
