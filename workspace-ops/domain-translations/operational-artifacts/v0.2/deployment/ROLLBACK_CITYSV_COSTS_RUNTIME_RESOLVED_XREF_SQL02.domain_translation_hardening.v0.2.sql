SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '=== ROLLBACK CITYSV-COSTS RUNTIME RESOLVED-XREF MIGRATION (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);

DECLARE @targets TABLE (ObjectName sysname PRIMARY KEY);
INSERT INTO @targets (ObjectName)
VALUES
    ('sp_CitySV_Axxis_Costs_PDI_TARGETED_UPLOAD'),
    ('sp_CitySV_Axxis_Costs_PDI_UPLOAD'),
    ('sp_CitySV_Axxis_Costs_PDI_VALIDATE'),
    ('vw_CitySV_Axxis_Cost_PDI_Gravitate_Lineage_Comp');

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

    SET @new = REPLACE(@new, 'dbo.vw_CitySV_Axxis_Xref_Supplier_Resolved_CostsCompat', 'dbo.vw_Axxis_PDI_Gravitate_FIVC_CITT');
    SET @new = REPLACE(@new, '[dbo].[vw_CitySV_Axxis_Xref_Supplier_Resolved_CostsCompat]', '[dbo].[vw_Axxis_PDI_Gravitate_FIVC_CITT]');
    SET @new = REPLACE(@new, 'dbo.vw_CitySV_Axxis_Xref_Supplier_Resolved', 'dbo.vw_Axxis_PDI_Gravitate_FIVC_CITT');
    SET @new = REPLACE(@new, '[dbo].[vw_CitySV_Axxis_Xref_Supplier_Resolved]', '[dbo].[vw_Axxis_PDI_Gravitate_FIVC_CITT]');

    SET @new = REPLACE(@new, 'dbo.vw_CitySV_Axxis_Xref_Product_Resolved_CostsCompat', 'dbo.vw_Axxis_PDI_Gravitate_Prod_CITT');
    SET @new = REPLACE(@new, '[dbo].[vw_CitySV_Axxis_Xref_Product_Resolved_CostsCompat]', '[dbo].[vw_Axxis_PDI_Gravitate_Prod_CITT]');
    SET @new = REPLACE(@new, 'dbo.vw_CitySV_Axxis_Xref_Product_Resolved', 'dbo.vw_Axxis_PDI_Gravitate_Prod_CITT');
    SET @new = REPLACE(@new, '[dbo].[vw_CitySV_Axxis_Xref_Product_Resolved]', '[dbo].[vw_Axxis_PDI_Gravitate_Prod_CITT]');

    SET @new = REPLACE(@new, 'dbo.vw_CitySV_Axxis_Xref_Terminal_Resolved_CostsCompat', 'dbo.vw_Axxis_PDI_Gravitate_Trmnl_CITT');
    SET @new = REPLACE(@new, '[dbo].[vw_CitySV_Axxis_Xref_Terminal_Resolved_CostsCompat]', '[dbo].[vw_Axxis_PDI_Gravitate_Trmnl_CITT]');
    SET @new = REPLACE(@new, 'dbo.vw_CitySV_Axxis_Xref_Terminal_Resolved', 'dbo.vw_Axxis_PDI_Gravitate_Trmnl_CITT');
    SET @new = REPLACE(@new, '[dbo].[vw_CitySV_Axxis_Xref_Terminal_Resolved]', '[dbo].[vw_Axxis_PDI_Gravitate_Trmnl_CITT]');

    IF @new = @def
        PRINT 'No rollback replacement performed for dbo.' + @obj + ' (already legacy or token mismatch).';
    ELSE
    BEGIN
        EXEC sys.sp_executesql @new;
        PRINT 'Rolled back object dbo.' + @obj;
    END

    FETCH NEXT FROM c INTO @obj;
END

CLOSE c;
DEALLOCATE c;

PRINT '=== ROLLBACK COMPLETE ===';
