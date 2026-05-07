SET NOCOUNT ON;

PRINT '=== DEPLOY VENDOR CARRIER CANONICAL MAPPING v1 (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);
PRINT 'Server: ' + @@SERVERNAME;
PRINT 'Database: ' + DB_NAME();

/* 1) Freeze legacy source view */
IF OBJECT_ID('dbo.vw_PDI_Gravitate_FullName_Carrier_XREF_Freeze','V') IS NULL
   AND OBJECT_ID('dbo.vw_PDI_Gravitate_FullName_Carrier_XREF','V') IS NOT NULL
BEGIN
    EXEC sp_rename
        @objname = N'dbo.vw_PDI_Gravitate_FullName_Carrier_XREF',
        @newname = N'vw_PDI_Gravitate_FullName_Carrier_XREF_Freeze',
        @objtype = N'OBJECT';

    PRINT 'Renamed legacy carrier xref view to _Freeze.';
END;

/* Optional compatibility shim so old dependencies do not break immediately. */
IF OBJECT_ID('dbo.vw_PDI_Gravitate_FullName_Carrier_XREF','V') IS NULL
   AND OBJECT_ID('dbo.vw_PDI_Gravitate_FullName_Carrier_XREF_Freeze','V') IS NOT NULL
BEGIN
    EXEC ('
        CREATE VIEW dbo.vw_PDI_Gravitate_FullName_Carrier_XREF
        AS
        SELECT *
        FROM dbo.vw_PDI_Gravitate_FullName_Carrier_XREF_Freeze;
    ');

    PRINT 'Created compatibility shim: vw_PDI_Gravitate_FullName_Carrier_XREF -> _Freeze.';
END;

/* 2) Seed canonical registry entries from frozen legacy map + carrier vendor clone */
;WITH SeedRows AS
(
    SELECT DISTINCT
          Domain_Name      = 'Vendor'
        , Source_System    = 'Gravitate'
        , Target_System    = 'PDI'
        , Target_Channel   = CAST(NULL AS varchar(30))
        , Workgroup        = 'COIL-Pricing-Supply'
        , Owning_Pipeline  = 'Gravitate_Orders'
        , Source_Key_1     = NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), F.[.Long_Name]))), '')
        , Source_Key_2     = NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), F.SCAC))), '')
        , Source_Key_3     = CAST(NULL AS varchar(100))
        , Source_Key_4     = CAST(NULL AS varchar(100))
        , Source_Description = CONCAT('Seeded from ', 'vw_PDI_Gravitate_FullName_Carrier_XREF_Freeze')
        , Target_Key       = TRY_CONVERT(decimal(18, 0), V.Vend_Key)
        , Target_Code      = NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), V.Vend_ID))), '')
        , Resolution_Status = 'ACTIVE'
        , Is_Active         = CAST(1 AS bit)
        , Effective_From    = CAST(GETDATE() AS date)
        , Effective_To      = CAST(NULL AS date)
        , Consuming_Views   = N'dbo.vw_Gravitate_Orders_Ready'
        , Notes             = CAST('Initial v1 carrier-name seed from frozen legacy carrier xref.' AS varchar(1000))
        , Composite_Hash    = UPPER(CONVERT(varchar(64), HASHBYTES('SHA2_256',
              CONCAT(
                  'Vendor|Gravitate|PDI|',
                  UPPER(ISNULL(NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), F.[.Long_Name]))), ''), '')),
                  '|',
                  UPPER(ISNULL(NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), F.SCAC))), ''), '')),
                  '|',
                  UPPER(ISNULL(NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), F.FIFC_Vend_ID))), ''), ''))
              )
          ), 2))
    FROM dbo.vw_PDI_Gravitate_FullName_Carrier_XREF_Freeze AS F
    INNER JOIN dbo.PDI_Vendors_Clone AS V
        ON NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), V.Vend_ID))), '')
         = NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), F.FIFC_Vend_ID))), '')
    WHERE NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), F.[.Long_Name]))), '') IS NOT NULL
      AND (
            UPPER(ISNULL(V.Vend_Class_ID, '')) = 'CARRIER'
         OR UPPER(ISNULL(V.Vend_Type_Description, '')) = 'CARRIER'
      )
)
INSERT dbo.Xref_Registry
(
      Domain_Name
    , Source_System
    , Target_System
    , Target_Channel
    , Workgroup
    , Owning_Pipeline
    , Source_Key_1
    , Source_Key_2
    , Source_Key_3
    , Source_Key_4
    , Source_Description
    , Target_Key
    , Target_Code
    , Resolution_Status
    , Is_Active
    , Effective_From
    , Effective_To
    , Consuming_Views
    , Notes
    , Created_Dtm
    , Created_By
)
SELECT
      S.Domain_Name
    , S.Source_System
    , S.Target_System
    , S.Target_Channel
    , S.Workgroup
    , S.Owning_Pipeline
    , S.Source_Key_1
    , S.Source_Key_2
    , S.Source_Key_3
    , S.Source_Key_4
    , S.Source_Description
    , S.Target_Key
    , S.Target_Code
    , S.Resolution_Status
    , S.Is_Active
    , S.Effective_From
    , S.Effective_To
    , S.Consuming_Views
    , S.Notes
    , SYSUTCDATETIME() AS Created_Dtm
    , SUSER_SNAME() AS Created_By
FROM SeedRows AS S
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Xref_Registry AS X
    WHERE X.Domain_Name    = S.Domain_Name
      AND X.Source_System  = S.Source_System
      AND X.Target_System  = S.Target_System
      AND ISNULL(X.Target_Channel, '') = ISNULL(S.Target_Channel, '')
      AND UPPER(ISNULL(X.Source_Key_1, '')) = UPPER(ISNULL(S.Source_Key_1, ''))
      AND X.Is_Active = 1
);

PRINT 'Seeded canonical carrier vendor rows into Xref_Registry.';

/* 3) Canonical consumption view */
EXEC ('
CREATE OR ALTER VIEW dbo.vw_Xref_Vendor_Gravitate_To_PDI
AS
SELECT
      X.Xref_ID
    , Gravitate_Carrier_Name = X.Source_Key_1
    , Gravitate_Carrier_SCAC = X.Source_Key_2
    , PDI_Vend_Key           = X.Target_Key
    , PDI_Vend_ID            = X.Target_Code
    , Vend_Description       = V.Vend_Description
    , Vend_Class_ID          = V.Vend_Class_ID
    , Vend_Type_Description  = V.Vend_Type_Description
    , X.Resolution_Status
    , X.Is_Active
FROM dbo.Xref_Registry AS X
LEFT JOIN dbo.PDI_Vendors_Clone AS V
    ON V.Vend_Key = TRY_CONVERT(int, X.Target_Key)
WHERE X.Domain_Name   = ''Vendor''
  AND X.Source_System = ''Gravitate''
  AND X.Target_System = ''PDI''
  AND X.Resolution_Status = ''ACTIVE''
  AND X.Is_Active = 1;
');

PRINT 'Created/updated dbo.vw_Xref_Vendor_Gravitate_To_PDI.';
PRINT '=== END DEPLOY VENDOR CARRIER CANONICAL MAPPING v1 ===';
