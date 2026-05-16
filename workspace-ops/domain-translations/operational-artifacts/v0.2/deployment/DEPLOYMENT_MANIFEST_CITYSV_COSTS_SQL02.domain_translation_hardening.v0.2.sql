SET NOCOUNT ON;
PRINT '=== DEPLOYMENT MANIFEST CITYSV-COSTS v0.2 (SQL-02) ===';
PRINT 'UTC: ' + CONVERT(varchar(30), GETUTCDATE(), 126);

PRINT 'Execution order for Saturday window:';
PRINT '1) validation/CAPTURE_CITYSV_COSTS_RUNTIME_DEFS_SQL02.domain_translation_hardening.v0.2.sql';
PRINT '2) validation/VALIDATE_CITYSV_COSTS_RUNTIME_DEPENDENCY_SQL02.domain_translation_hardening.v0.2.sql';
PRINT '3) deployment/APPLY_CITYSV_COSTS_RUNTIME_RESOLVED_XREF_SQL02.domain_translation_hardening.v0.2.sql';
PRINT '4) validation/VALIDATE_CITYSV_COSTS_RUNTIME_DEPENDENCY_SQL02.domain_translation_hardening.v0.2.sql (postchange)';
PRINT '5) runtime sanity checks';
PRINT 'Rollback script:';
PRINT 'deployment/ROLLBACK_CITYSV_COSTS_RUNTIME_RESOLVED_XREF_SQL02.domain_translation_hardening.v0.2.sql';

SELECT
    object_name = QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name),
    object_type = o.type_desc,
    exists_flag = 1
FROM sys.objects o
WHERE o.name IN (
    'sp_CitySV_Axxis_Costs_PDI_TARGETED_UPLOAD',
    'sp_CitySV_Axxis_Costs_PDI_UPLOAD',
    'sp_CitySV_Axxis_Costs_PDI_VALIDATE',
    'vw_CitySV_Axxis_Cost_PDI_Gravitate_Lineage_Comp',
    'vw_CitySV_Axxis_Xref_Supplier_Resolved',
    'vw_CitySV_Axxis_Xref_Product_Resolved',
    'vw_CitySV_Axxis_Xref_Terminal_Resolved'
)
ORDER BY object_name;

PRINT '=== END MANIFEST ===';
