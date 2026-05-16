SET NOCOUNT ON;

PRINT '=== CAPTURE CITYSV-COSTS RUNTIME DEFINITIONS (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);
PRINT 'Server: ' + @@SERVERNAME;
PRINT 'Database: ' + DB_NAME();

SELECT
      capture_utc = CONVERT(varchar(30), GETUTCDATE(), 126)
    , object_name = QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name)
    , object_type = o.type_desc
    , object_definition = OBJECT_DEFINITION(o.object_id)
FROM sys.objects AS o
WHERE o.name IN
(
      'sp_CitySV_Axxis_Costs_INGEST'
    , 'sp_CitySV_Axxis_Costs_PDI_UPLOAD'
    , 'sp_CitySV_Axxis_Costs_PDI_TARGETED_UPLOAD'
    , 'sp_CitySV_Axxis_Costs_PDI_VALIDATE'
    , 'vw_CitySV_Axxis_Cost_PDI_Gravitate_Lineage_Comp'
)
ORDER BY object_name;

PRINT '=== END CAPTURE CITYSV-COSTS RUNTIME DEFINITIONS (SQL-02) ===';
