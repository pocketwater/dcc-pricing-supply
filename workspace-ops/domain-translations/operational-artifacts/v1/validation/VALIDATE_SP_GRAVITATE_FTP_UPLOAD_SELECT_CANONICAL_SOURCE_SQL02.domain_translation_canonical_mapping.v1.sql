SET NOCOUNT ON;

PRINT '=== VALIDATE sp_Gravitate_FTP_UPLOAD_SELECT SOURCE CONTRACT (SQL-02) ===';
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
      object_name = 'dbo.sp_Gravitate_FTP_UPLOAD_SELECT'
    , object_type = o.type_desc
    , definition_sha256 = CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), @Definition)), 2)
    , uses_legacy_master_xref = CASE WHEN @Definition LIKE '%Gravitate_PDI_Master_XREF%' THEN 1 ELSE 0 END
    , uses_canonical_contract_view = CASE WHEN @Definition LIKE '%vw_Xref_Contract_Gravitate_To_PDI%' THEN 1 ELSE 0 END
FROM sys.objects AS o
WHERE o.object_id = @ObjectId;

IF OBJECT_ID('dbo.vw_Xref_Contract_Gravitate_To_PDI', 'V') IS NOT NULL
BEGIN
    SELECT
          canonical_view_row_count = COUNT(*)
        , canonical_null_contract_id_count = SUM(CASE WHEN PDI_FuelCont_ID IS NULL THEN 1 ELSE 0 END)
    FROM dbo.vw_Xref_Contract_Gravitate_To_PDI;
END;

PRINT '=== END VALIDATE sp_Gravitate_FTP_UPLOAD_SELECT SOURCE CONTRACT (SQL-02) ===';
