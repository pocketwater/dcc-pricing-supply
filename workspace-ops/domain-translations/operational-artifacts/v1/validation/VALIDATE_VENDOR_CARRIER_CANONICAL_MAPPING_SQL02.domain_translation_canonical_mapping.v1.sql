SET NOCOUNT ON;

PRINT '=== VALIDATE VENDOR CARRIER CANONICAL MAPPING v1 (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);

SELECT
      'registry_vendor_gravitate_active_count' AS test_name
    , COUNT(*) AS row_count
FROM dbo.Xref_Registry
WHERE Domain_Name = 'Vendor'
  AND Source_System = 'Gravitate'
  AND Target_System = 'PDI'
  AND Resolution_Status = 'ACTIVE'
  AND Is_Active = 1;

SELECT TOP (200)
      'canonical_view_sample' AS test_name
    , Gravitate_Carrier_Name
    , Gravitate_Carrier_SCAC
    , PDI_Vend_ID
    , Vend_Description
    , Vend_Class_ID
    , Vend_Type_Description
FROM dbo.vw_Xref_Vendor_Gravitate_To_PDI
ORDER BY Gravitate_Carrier_Name;

/* Carriers present in stage as text names that still do not map to canonical vendor IDs */
WITH StageCarrierNames AS
(
    SELECT DISTINCT
        Carrier_Name = NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), S.Carrier_ID))), '')
    FROM dbo.vw_Gravitate_Orders_Stage AS S
    WHERE TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), S.Carrier_ID))), '')) IS NULL
      AND NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), S.Carrier_ID))), '') IS NOT NULL
)
SELECT
      'unmapped_stage_carrier_names' AS test_name
    , SCN.Carrier_Name
FROM StageCarrierNames AS SCN
LEFT JOIN dbo.vw_Xref_Vendor_Gravitate_To_PDI AS X
    ON UPPER(X.Gravitate_Carrier_Name) = UPPER(SCN.Carrier_Name)
WHERE X.Xref_ID IS NULL
ORDER BY SCN.Carrier_Name;

PRINT '=== END VALIDATE VENDOR CARRIER CANONICAL MAPPING v1 ===';
