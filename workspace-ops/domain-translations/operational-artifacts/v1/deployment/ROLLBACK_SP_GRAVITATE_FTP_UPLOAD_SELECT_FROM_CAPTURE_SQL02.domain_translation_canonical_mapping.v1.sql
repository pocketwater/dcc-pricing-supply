SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '=== ROLLBACK sp_Gravitate_FTP_UPLOAD_SELECT FROM CAPTURED DEFINITION (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);
PRINT 'Server: ' + @@SERVERNAME;
PRINT 'Database: ' + DB_NAME();

DECLARE @ObjectId int = OBJECT_ID('dbo.sp_Gravitate_FTP_UPLOAD_SELECT');

IF @ObjectId IS NULL
BEGIN
    RAISERROR('FATAL: dbo.sp_Gravitate_FTP_UPLOAD_SELECT not found', 16, 1);
    RETURN;
END;

/*
Paste the exact CREATE/ALTER PROCEDURE text captured before cutover into
@ProcedureDefinition (N'' string literal) and then run this script.
*/
DECLARE @ProcedureDefinition nvarchar(max) = N'__PASTE_CAPTURED_PROCEDURE_DEFINITION_HERE__';

IF @ProcedureDefinition = N'__PASTE_CAPTURED_PROCEDURE_DEFINITION_HERE__'
BEGIN
    RAISERROR('FATAL: No captured procedure definition provided. Populate @ProcedureDefinition first.', 16, 1);
    RETURN;
END;

DECLARE @BeforeHash varchar(64) = CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), OBJECT_DEFINITION(@ObjectId))), 2);

SET @ProcedureDefinition = REPLACE(@ProcedureDefinition, 'CREATE PROCEDURE', 'ALTER PROCEDURE');

BEGIN TRANSACTION;

EXEC sp_executesql @ProcedureDefinition;

DECLARE @RestoredDefinition nvarchar(max) = OBJECT_DEFINITION(@ObjectId);
DECLARE @AfterHash varchar(64) = CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), @RestoredDefinition)), 2);

IF @RestoredDefinition NOT LIKE '%Gravitate_PDI_Master_XREF%'
BEGIN
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    RAISERROR('FATAL: Restored definition does not reference Gravitate_PDI_Master_XREF; review captured text.', 16, 1);
    RETURN;
END;

COMMIT TRANSACTION;

SELECT
      status = 'ROLLBACK_APPLIED'
    , before_sha256 = @BeforeHash
    , after_sha256 = @AfterHash
    , references_legacy_master_xref = CASE WHEN @RestoredDefinition LIKE '%Gravitate_PDI_Master_XREF%' THEN 1 ELSE 0 END
    , references_canonical_contract_view = CASE WHEN @RestoredDefinition LIKE '%vw_Xref_Contract_Gravitate_To_PDI%' THEN 1 ELSE 0 END;

PRINT '=== END ROLLBACK sp_Gravitate_FTP_UPLOAD_SELECT FROM CAPTURED DEFINITION (SQL-02) ===';
