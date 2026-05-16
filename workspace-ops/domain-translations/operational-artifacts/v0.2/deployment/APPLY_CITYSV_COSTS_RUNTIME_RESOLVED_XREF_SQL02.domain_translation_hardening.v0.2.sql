SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '=== APPLY CITYSV-COSTS RUNTIME RESOLVED-XREF MIGRATION (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);

DECLARE @targets TABLE (ObjectName sysname PRIMARY KEY);
INSERT INTO @targets (ObjectName)
VALUES
    ('sp_CitySV_Axxis_Costs_PDI_TARGETED_UPLOAD'),
    ('sp_CitySV_Axxis_Costs_PDI_UPLOAD'),
    ('sp_CitySV_Axxis_Costs_PDI_VALIDATE'),
    ('vw_CitySV_Axxis_Cost_PDI_Gravitate_Lineage_Comp');

IF OBJECT_ID('dbo.vw_CitySV_Axxis_Xref_Supplier_Resolved', 'V') IS NULL
    THROW 51000, 'Missing required view: dbo.vw_CitySV_Axxis_Xref_Supplier_Resolved', 1;
IF OBJECT_ID('dbo.vw_CitySV_Axxis_Xref_Product_Resolved', 'V') IS NULL
    THROW 51000, 'Missing required view: dbo.vw_CitySV_Axxis_Xref_Product_Resolved', 1;
IF OBJECT_ID('dbo.vw_CitySV_Axxis_Xref_Terminal_Resolved', 'V') IS NULL
    THROW 51000, 'Missing required view: dbo.vw_CitySV_Axxis_Xref_Terminal_Resolved', 1;

EXEC('CREATE OR ALTER VIEW dbo.vw_CitySV_Axxis_Xref_Supplier_Resolved_CostsCompat
AS
SELECT
            Axxis_Supplier_Name = S.Axxis_Supplier
        , Axxis_Supplier = S.Axxis_Supplier
    , Grav_Supplier = CONVERT(varchar(100), NULL)
        , Vend_Key = V.Vend_Key
        , Vend_ID = S.Vend_ID
        , FuelContDtl_Key = V.FuelContDtl_Key
        , FuelContDtl_FuelCont_Key = V.FuelContDtl_FuelCont_Key
        , PDI_FuelCont_ID = S.PDI_FuelCont_ID
    , FuelCont_Description = V.FuelCont_Description
        , Mapping_Source = S.Mapping_Source
FROM dbo.vw_CitySV_Axxis_Xref_Supplier_Resolved AS S
OUTER APPLY (
        SELECT TOP (1)
                    C.Vend_Key
                , C.FuelContDtl_Key
                , C.FuelContDtl_FuelCont_Key
        , C.FuelCont_Description
        FROM dbo.PDI_FIVC_Vendor_Clone AS C
        WHERE CONVERT(varchar(100), C.FuelCont_ID) = CONVERT(varchar(100), S.PDI_FuelCont_ID)
            AND CONVERT(varchar(50), C.Vend_ID) = CONVERT(varchar(50), S.Vend_ID)
        ORDER BY C.FuelContDtl_Key DESC
) AS V;');

EXEC('CREATE OR ALTER VIEW dbo.vw_CitySV_Axxis_Xref_Terminal_Resolved_CostsCompat
AS
SELECT
            Axxis_Trmnl_Name = T.Axxis_Trmnl
        , Axxis_Trmnl = T.Axxis_Trmnl
    , Grav_Trmnl = CONVERT(varchar(100), NULL)
        , PDI_Trmnl_ID = T.PDI_Trmnl_ID
    , Trmnl_Key = TC.Trmnl_Key
    , PDI_Terminal = TC.Trmnl_Description
    , TrmnlGrp_Description = TC.TrmnlGrp_Description
    , TrmnlRptGrp_Description = TC.TrmnlRptGrp_Description
    , State_Code = TC.Trmnl_State_Code
        , Mapping_Source = T.Mapping_Source
FROM dbo.vw_CitySV_Axxis_Xref_Terminal_Resolved AS T
LEFT JOIN dbo.PDI_Terminals_Clone AS TC
    ON CONVERT(varchar(50), TC.Trmnl_ID) = CONVERT(varchar(50), T.PDI_Trmnl_ID);');

EXEC('CREATE OR ALTER VIEW dbo.vw_CitySV_Axxis_Xref_Product_Resolved_CostsCompat
AS
SELECT
            Axxis_Prod_Name = P.Axxis_Prod
        , Axxis_Prod = P.Axxis_Prod
        , PDI_Prod_ID = P.PDI_Prod_ID
    , Grav_Prod = CONVERT(varchar(100), NULL)
    , Prod_Key = PC.Prod_Key
    , Prod_Description = PC.Prod_Description
        , Mapping_Source = P.Mapping_Source
FROM dbo.vw_CitySV_Axxis_Xref_Product_Resolved AS P
LEFT JOIN dbo.PDI_Products_Clone AS PC
    ON CONVERT(varchar(50), PC.Prod_ID) = CONVERT(varchar(50), P.PDI_Prod_ID);');

DECLARE @obj sysname;
DECLARE @def nvarchar(max);
DECLARE @new nvarchar(max);
DECLARE @err nvarchar(2048);

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
SELECT ObjectName FROM @targets ORDER BY ObjectName;

OPEN c;
FETCH NEXT FROM c INTO @obj;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @def = OBJECT_DEFINITION(OBJECT_ID('dbo.' + @obj));
    IF @def IS NULL
    BEGIN
        SET @err = N'Missing target object definition: dbo.' + @obj;
        THROW 51000, @err, 1;
    END

    SET @new = @def;

    SET @new = REPLACE(@new, 'CREATE PROCEDURE', 'CREATE OR ALTER PROCEDURE');
    SET @new = REPLACE(@new, 'CREATE PROC', 'CREATE OR ALTER PROC');
    SET @new = REPLACE(@new, 'CREATE VIEW', 'CREATE OR ALTER VIEW');

    SET @new = REPLACE(@new, 'dbo.PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone', 'dbo.vw_CitySV_Axxis_Xref_Supplier_Resolved_CostsCompat');
    SET @new = REPLACE(@new, '[dbo].[PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone]', '[dbo].[vw_CitySV_Axxis_Xref_Supplier_Resolved_CostsCompat]');
    SET @new = REPLACE(@new, 'dbo.vw_Axxis_PDI_Gravitate_FIVC_CITT', 'dbo.vw_CitySV_Axxis_Xref_Supplier_Resolved_CostsCompat');
    SET @new = REPLACE(@new, '[dbo].[vw_Axxis_PDI_Gravitate_FIVC_CITT]', '[dbo].[vw_CitySV_Axxis_Xref_Supplier_Resolved_CostsCompat]');

    SET @new = REPLACE(@new, 'dbo.PDI_CITT_Axxis_Grav_PDI_Products_Clone', 'dbo.vw_CitySV_Axxis_Xref_Product_Resolved_CostsCompat');
    SET @new = REPLACE(@new, '[dbo].[PDI_CITT_Axxis_Grav_PDI_Products_Clone]', '[dbo].[vw_CitySV_Axxis_Xref_Product_Resolved_CostsCompat]');
    SET @new = REPLACE(@new, 'dbo.vw_Axxis_PDI_Gravitate_Prod_CITT', 'dbo.vw_CitySV_Axxis_Xref_Product_Resolved_CostsCompat');
    SET @new = REPLACE(@new, '[dbo].[vw_Axxis_PDI_Gravitate_Prod_CITT]', '[dbo].[vw_CitySV_Axxis_Xref_Product_Resolved_CostsCompat]');

    SET @new = REPLACE(@new, 'dbo.PDI_CITT_Axxis_Grav_PDI_Terminals_Clone', 'dbo.vw_CitySV_Axxis_Xref_Terminal_Resolved_CostsCompat');
    SET @new = REPLACE(@new, '[dbo].[PDI_CITT_Axxis_Grav_PDI_Terminals_Clone]', '[dbo].[vw_CitySV_Axxis_Xref_Terminal_Resolved_CostsCompat]');
    SET @new = REPLACE(@new, 'dbo.vw_Axxis_PDI_Gravitate_Trmnl_CITT', 'dbo.vw_CitySV_Axxis_Xref_Terminal_Resolved_CostsCompat');
    SET @new = REPLACE(@new, '[dbo].[vw_Axxis_PDI_Gravitate_Trmnl_CITT]', '[dbo].[vw_CitySV_Axxis_Xref_Terminal_Resolved_CostsCompat]');

    IF @new = @def
        PRINT 'No replacement performed for dbo.' + @obj + ' (already migrated or token mismatch).';
    ELSE
    BEGIN
        EXEC sys.sp_executesql @new;
        PRINT 'Applied migration for dbo.' + @obj;
    END

    FETCH NEXT FROM c INTO @obj;
END

CLOSE c;
DEALLOCATE c;

PRINT '=== APPLY COMPLETE ===';
