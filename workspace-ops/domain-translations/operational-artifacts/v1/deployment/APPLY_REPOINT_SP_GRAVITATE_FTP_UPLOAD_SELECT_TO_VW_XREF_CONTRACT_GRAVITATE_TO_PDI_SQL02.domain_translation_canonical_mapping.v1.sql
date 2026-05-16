SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '=== APPLY REPOINT sp_Gravitate_FTP_UPLOAD_SELECT TO CANONICAL VIEW (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);
PRINT 'Server: ' + @@SERVERNAME;
PRINT 'Database: ' + DB_NAME();

DECLARE @ObjectId int = OBJECT_ID('dbo.sp_Gravitate_FTP_UPLOAD_SELECT');

IF @ObjectId IS NULL
BEGIN
    RAISERROR('FATAL: dbo.sp_Gravitate_FTP_UPLOAD_SELECT not found', 16, 1);
    RETURN;
END;

IF OBJECT_ID('dbo.vw_Xref_Contract_Gravitate_To_PDI', 'V') IS NULL
BEGIN
    RAISERROR('FATAL: dbo.vw_Xref_Contract_Gravitate_To_PDI not found', 16, 1);
    RETURN;
END;

DECLARE @CurrentDefinition nvarchar(max) = OBJECT_DEFINITION(@ObjectId);
DECLARE @NewDefinition nvarchar(max);
DECLARE @BeforeHash varchar(64);
DECLARE @AfterHash varchar(64);

SET @BeforeHash = CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), @CurrentDefinition)), 2);

IF @CurrentDefinition LIKE '%vw_Xref_Contract_Gravitate_To_PDI%'
   AND @CurrentDefinition NOT LIKE '%Gravitate_PDI_Master_XREF%'
BEGIN
    PRINT 'No-op: procedure already points to canonical view and does not reference legacy master xref.';

    SELECT
          status = 'NO_OP_ALREADY_REPOINTED'
        , definition_sha256 = @BeforeHash;

    RETURN;
END;

IF @CurrentDefinition NOT LIKE '%Gravitate_PDI_Master_XREF%'
BEGIN
    RAISERROR('FATAL: Procedure text does not contain expected token Gravitate_PDI_Master_XREF; refusing blind rewrite.', 16, 1);
    RETURN;
END;

SET @NewDefinition = @CurrentDefinition;

-- Replace common schema-qualified and bracketed forms first.
SET @NewDefinition = REPLACE(@NewDefinition, '[dbo].[Gravitate_PDI_Master_XREF]', '[dbo].[vw_Xref_Contract_Gravitate_To_PDI]');
SET @NewDefinition = REPLACE(@NewDefinition, 'dbo.Gravitate_PDI_Master_XREF', 'dbo.vw_Xref_Contract_Gravitate_To_PDI');
SET @NewDefinition = REPLACE(@NewDefinition, '[Gravitate_PDI_Master_XREF]', '[vw_Xref_Contract_Gravitate_To_PDI]');
SET @NewDefinition = REPLACE(@NewDefinition, 'Gravitate_PDI_Master_XREF', 'vw_Xref_Contract_Gravitate_To_PDI');
SET @NewDefinition = REPLACE(@NewDefinition, 'CREATE PROCEDURE', 'ALTER PROCEDURE');

IF @NewDefinition = @CurrentDefinition
BEGIN
    RAISERROR('FATAL: Replacement produced no text change; aborting.', 16, 1);
    RETURN;
END;

BEGIN TRANSACTION;

EXEC sp_executesql @NewDefinition;

DECLARE @RepointedDefinition nvarchar(max) = OBJECT_DEFINITION(@ObjectId);
SET @AfterHash = CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), @RepointedDefinition)), 2);

IF @RepointedDefinition NOT LIKE '%vw_Xref_Contract_Gravitate_To_PDI%'
BEGIN
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    RAISERROR('FATAL: Post-change definition missing canonical view reference.', 16, 1);
    RETURN;
END;

IF @RepointedDefinition LIKE '%Gravitate_PDI_Master_XREF%'
BEGIN
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    RAISERROR('FATAL: Post-change definition still references legacy master xref.', 16, 1);
    RETURN;
END;

COMMIT TRANSACTION;

SELECT
      status = 'REPOINT_APPLIED'
    , before_sha256 = @BeforeHash
    , after_sha256 = @AfterHash
    , references_legacy_master_xref = CASE WHEN @RepointedDefinition LIKE '%Gravitate_PDI_Master_XREF%' THEN 1 ELSE 0 END
    , references_canonical_contract_view = CASE WHEN @RepointedDefinition LIKE '%vw_Xref_Contract_Gravitate_To_PDI%' THEN 1 ELSE 0 END;

PRINT '=== END APPLY REPOINT sp_Gravitate_FTP_UPLOAD_SELECT TO CANONICAL VIEW (SQL-02) ===';
