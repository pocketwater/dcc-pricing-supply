SET NOCOUNT ON;

PRINT '=== CAPTURE sp_Gravitate_FTP_UPLOAD_SELECT DEFINITION (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);
PRINT 'Server: ' + @@SERVERNAME;
PRINT 'Database: ' + DB_NAME();

DECLARE @ObjectId int = OBJECT_ID('dbo.sp_Gravitate_FTP_UPLOAD_SELECT');

IF @ObjectId IS NULL
BEGIN
    RAISERROR('FATAL: dbo.sp_Gravitate_FTP_UPLOAD_SELECT not found', 16, 1);
    RETURN;
END;

DECLARE @Definition nvarchar(max) = OBJECT_DEFINITION(@ObjectId);

SELECT
      capture_utc = CONVERT(varchar(30), GETUTCDATE(), 126)
    , object_name = 'dbo.sp_Gravitate_FTP_UPLOAD_SELECT'
    , definition_sha256 = CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), @Definition)), 2)
    , contains_legacy_master_xref = CASE WHEN @Definition LIKE '%Gravitate_PDI_Master_XREF%' THEN 1 ELSE 0 END
    , contains_canonical_contract_view = CASE WHEN @Definition LIKE '%vw_Xref_Contract_Gravitate_To_PDI%' THEN 1 ELSE 0 END;

SELECT
      object_definition = @Definition;

PRINT '=== END CAPTURE sp_Gravitate_FTP_UPLOAD_SELECT DEFINITION (SQL-02) ===';
