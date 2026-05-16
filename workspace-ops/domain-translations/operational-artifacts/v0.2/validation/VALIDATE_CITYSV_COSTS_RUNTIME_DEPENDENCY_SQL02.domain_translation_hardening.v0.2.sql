SET NOCOUNT ON;

PRINT '=== VALIDATE CITYSV-COSTS RUNTIME DEPENDENCY STATE (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);
PRINT 'Server: ' + @@SERVERNAME;
PRINT 'Database: ' + DB_NAME();

SELECT
      object_name = QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name)
    , object_type = o.type_desc
    , uses_legacy_citt = CASE WHEN m.definition LIKE '%PDI_CITT_Axxis_Grav_PDI_%' OR m.definition LIKE '%vw_Axxis_PDI_Gravitate_%_CITT%' THEN 1 ELSE 0 END
    , uses_canonical_xref = CASE WHEN m.definition LIKE '%vw_Xref_%Axxis%To_PDI%' OR m.definition LIKE '%vw_CitySV_Axxis_Xref_%_Resolved%' OR m.definition LIKE '%Xref_Registry%' THEN 1 ELSE 0 END
FROM sys.objects AS o
JOIN sys.sql_modules AS m
  ON m.object_id = o.object_id
WHERE o.name IN
(
      'sp_CitySV_Axxis_Costs_INGEST'
    , 'sp_CitySV_Axxis_Costs_PDI_UPLOAD'
    , 'sp_CitySV_Axxis_Costs_PDI_TARGETED_UPLOAD'
    , 'sp_CitySV_Axxis_Costs_PDI_VALIDATE'
    , 'vw_CitySV_Axxis_Cost_PDI_Gravitate_Lineage_Comp'
)
ORDER BY object_name;

SELECT
      object_name = QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name)
    , legacy_refs =
      CONCAT(
          CASE WHEN m.definition LIKE '%PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone%' THEN 'PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone;' ELSE '' END,
          CASE WHEN m.definition LIKE '%PDI_CITT_Axxis_Grav_PDI_Products_Clone%' THEN 'PDI_CITT_Axxis_Grav_PDI_Products_Clone;' ELSE '' END,
          CASE WHEN m.definition LIKE '%PDI_CITT_Axxis_Grav_PDI_Terminals_Clone%' THEN 'PDI_CITT_Axxis_Grav_PDI_Terminals_Clone;' ELSE '' END,
          CASE WHEN m.definition LIKE '%vw_Axxis_PDI_Gravitate_FIVC_CITT%' THEN 'vw_Axxis_PDI_Gravitate_FIVC_CITT;' ELSE '' END,
          CASE WHEN m.definition LIKE '%vw_Axxis_PDI_Gravitate_Prod_CITT%' THEN 'vw_Axxis_PDI_Gravitate_Prod_CITT;' ELSE '' END,
          CASE WHEN m.definition LIKE '%vw_Axxis_PDI_Gravitate_Trmnl_CITT%' THEN 'vw_Axxis_PDI_Gravitate_Trmnl_CITT;' ELSE '' END
      )
    , canonical_refs =
      CONCAT(
          CASE WHEN m.definition LIKE '%vw_CitySV_Axxis_Xref_Supplier_Resolved%' THEN 'vw_CitySV_Axxis_Xref_Supplier_Resolved;' ELSE '' END,
          CASE WHEN m.definition LIKE '%vw_CitySV_Axxis_Xref_Product_Resolved%' THEN 'vw_CitySV_Axxis_Xref_Product_Resolved;' ELSE '' END,
          CASE WHEN m.definition LIKE '%vw_CitySV_Axxis_Xref_Terminal_Resolved%' THEN 'vw_CitySV_Axxis_Xref_Terminal_Resolved;' ELSE '' END,
          CASE WHEN m.definition LIKE '%vw_Xref_Contract_Axxis_To_PDI%' THEN 'vw_Xref_Contract_Axxis_To_PDI;' ELSE '' END,
          CASE WHEN m.definition LIKE '%vw_Xref_Product_Axxis_To_PDI%' THEN 'vw_Xref_Product_Axxis_To_PDI;' ELSE '' END,
          CASE WHEN m.definition LIKE '%vw_Xref_Terminal_Axxis_To_PDI%' THEN 'vw_Xref_Terminal_Axxis_To_PDI;' ELSE '' END,
          CASE WHEN m.definition LIKE '%Xref_Registry%' THEN 'Xref_Registry;' ELSE '' END
      )
FROM sys.objects AS o
JOIN sys.sql_modules AS m
  ON m.object_id = o.object_id
WHERE o.name IN
(
      'sp_CitySV_Axxis_Costs_INGEST'
    , 'sp_CitySV_Axxis_Costs_PDI_UPLOAD'
    , 'sp_CitySV_Axxis_Costs_PDI_TARGETED_UPLOAD'
    , 'sp_CitySV_Axxis_Costs_PDI_VALIDATE'
    , 'vw_CitySV_Axxis_Cost_PDI_Gravitate_Lineage_Comp'
)
ORDER BY object_name;

PRINT '=== END VALIDATE CITYSV-COSTS RUNTIME DEPENDENCY STATE (SQL-02) ===';
