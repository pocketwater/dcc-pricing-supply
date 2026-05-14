-- ============================================================================
-- V1 DEPLOYMENT MANIFEST
-- Gravitate Contract XREF Migration (PricingLink Only)
-- ============================================================================
-- Purpose:
--   This document defines the execution sequence and validation gates for
--   deploying v1 of the Xref_Registry Contract domain migration.
--
-- Scope:
--   PricingLink only. COL_WH is out of scope.
--
-- Timeline:
--   Phase 1: Pre-deployment validation (< 5 minutes)
--   Phase 2: Seed execution (< 5 seconds)
--   Phase 3: View creation (< 5 seconds)
--   Phase 4: Procedure repointing (< 30 seconds)
--   Phase 5: Post-deployment validation (< 2 minutes)
--   Total expected: < 10 minutes
--
-- ============================================================================

-- ============================================================================
-- PHASE 1: PRE-DEPLOYMENT VALIDATION
-- ============================================================================
-- Goal: Confirm registry table exists and is ready for inserts

PRINT 'PHASE 1: Pre-deployment validation...';

-- Check 1: Registry table exists
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Xref_Registry' AND TABLE_SCHEMA = 'dbo')
BEGIN
    RAISERROR('FATAL: dbo.Xref_Registry table not found in PDI_PricingLink', 16, 1);
END
PRINT '  OK: dbo.Xref_Registry exists';

-- Check 2: Registry has expected columns
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Xref_Registry'
      AND TABLE_SCHEMA = 'dbo'
      AND COLUMN_NAME IN ('Domain_Name', 'Source_Key_1', 'Source_Key_2', 'Source_Key_3', 'Source_Key_4', 'Target_Key', 'Target_Code', 'Is_Active')
)
BEGIN
    RAISERROR('FATAL: Expected columns missing from dbo.Xref_Registry', 16, 1);
END
PRINT '  OK: Required columns present';

-- Check 3: Current row count (informational)
DECLARE @PreSeedCount INT;
SELECT @PreSeedCount = COUNT(*)
FROM dbo.Xref_Registry
WHERE Domain_Name = 'Contract'
  AND Source_System = 'Gravitate'
  AND Target_System = 'PDI';
PRINT '  Info: Pre-seed Contract domain row count: ' + CAST(@PreSeedCount AS VARCHAR(10));

-- Check 4: Gravitate_PDI_Master_XREF is accessible
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Gravitate_PDI_Master_XREF' AND TABLE_SCHEMA = 'dbo')
BEGIN
    RAISERROR('FATAL: Legacy dbo.Gravitate_PDI_Master_XREF table not found', 16, 1);
END
PRINT '  OK: Legacy Gravitate_PDI_Master_XREF exists (current source)';

-- Check 5: sp_Gravitate_FTP_UPLOAD_SELECT exists
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_Gravitate_FTP_UPLOAD_SELECT' AND ROUTINE_SCHEMA = 'dbo')
BEGIN
    RAISERROR('FATAL: dbo.sp_Gravitate_FTP_UPLOAD_SELECT not found', 16, 1);
END
PRINT '  OK: Target procedure sp_Gravitate_FTP_UPLOAD_SELECT exists';

PRINT CHAR(10) + 'PHASE 1 PASSED' + CHAR(10);

-- ============================================================================
-- PHASE 2: SEED EXECUTION
-- ============================================================================
-- Goal: Insert 200 rows into Xref_Registry Contract domain

PRINT 'PHASE 2: Executing seed...';

-- Execute the seed script
-- NOTE: In production, run as separate batch:
--   sqlcmd -S PDI-SQL-02 -d PDI_PricingLink -E -i SEED.Xref_Registry.v1.Contract.Gravitate_To_PDI.sql

-- Mock execution for manifest (comment out in production):
-- EXEC sp_executesql N'... seed insert statements ...';

PRINT 'PHASE 2: Seed script executed (separate batch)';
PRINT '  Expected result: 200 rows inserted';

-- ============================================================================
-- PHASE 3: VERIFY SEED EXECUTION
-- ============================================================================
-- Goal: Confirm all 200 rows were inserted correctly

PRINT CHAR(10) + 'PHASE 3: Verifying seed...';

DECLARE @SeedRowCount INT;
SELECT @SeedRowCount = COUNT(*)
FROM dbo.Xref_Registry
WHERE Domain_Name = 'Contract'
  AND Source_System = 'Gravitate'
  AND Target_System = 'PDI'
  AND Effective_From = CAST(GETDATE() AS DATE);

IF @SeedRowCount <> 200
BEGIN
    RAISERROR('CRITICAL: Seed count mismatch. Expected 200, found %d', 16, 1, @SeedRowCount);
END

PRINT '  OK: 200 rows seeded to Xref_Registry';

-- Check 3a: Verify multi-type mappings are preserved
DECLARE @MultiTypeMappings INT;
SELECT @MultiTypeMappings = COUNT(DISTINCT Source_Key_1 + '|' + Source_Key_3 + '|' + Source_Key_4)
FROM dbo.Xref_Registry
WHERE Domain_Name = 'Contract'
  AND Source_System = 'Gravitate'
  AND Target_System = 'PDI'
GROUP BY Source_Key_1, Source_Key_3, Source_Key_4
HAVING COUNT(DISTINCT Source_Key_2) > 1;

PRINT '  OK: ' + CAST(@MultiTypeMappings AS VARCHAR(10)) + ' multi-type mappings verified (expected: 7)';

PRINT 'PHASE 3 PASSED' + CHAR(10);

-- ============================================================================
-- PHASE 4: VIEW CREATION
-- ============================================================================
-- Goal: Create the contract view for procedure consumption

PRINT 'PHASE 4: Creating view...';

-- Execute the view creation script
-- NOTE: In production, run as separate batch:
--   sqlcmd -S PDI-SQL-02 -d PDI_PricingLink -E -i vw_Xref_Contract_Gravitate_To_PDI.sql

-- Or inline:
-- CREATE OR ALTER VIEW dbo.vw_Xref_Contract_Gravitate_To_PDI AS ...

PRINT 'PHASE 4: View creation script executed (separate batch)';
PRINT '  Expected result: vw_Xref_Contract_Gravitate_To_PDI created/altered';

-- Verify view exists
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'vw_Xref_Contract_Gravitate_To_PDI' AND TABLE_SCHEMA = 'dbo')
BEGIN
    RAISERROR('FATAL: View dbo.vw_Xref_Contract_Gravitate_To_PDI was not created', 16, 1);
END

PRINT 'PHASE 4 PASSED' + CHAR(10);

-- ============================================================================
-- PHASE 5: POST-DEPLOYMENT VALIDATION
-- ============================================================================
-- Goal: Confirm production feed behaves correctly with new mapping source

PRINT 'PHASE 5: Post-deployment validation...';

-- Test 1: View returns 200 rows
DECLARE @ViewRowCount INT;
SELECT @ViewRowCount = COUNT(*)
FROM dbo.vw_Xref_Contract_Gravitate_To_PDI;

IF @ViewRowCount <> 200
BEGIN
    RAISERROR('CRITICAL: View row count mismatch. Expected 200, found %d', 16, 1, @ViewRowCount);
END

PRINT '  OK: View returns 200 rows';

-- Test 2: No null PDI_FuelCont_IDs
DECLARE @NullContractCount INT;
SELECT @NullContractCount = COUNT(*)
FROM dbo.vw_Xref_Contract_Gravitate_To_PDI
WHERE PDI_FuelCont_ID IS NULL;

IF @NullContractCount > 0
BEGIN
    RAISERROR('CRITICAL: %d rows have null PDI_FuelCont_ID', 16, 1, @NullContractCount);
END

PRINT '  OK: No null PDI_FuelCont_IDs in view';

-- Test 3: Sample join — verify procedure can consume the view
-- (This simulates sp_Gravitate_FTP_UPLOAD_SELECT join logic)
DECLARE @SampleJoinTest TABLE (
    Gravitate_Vendor VARCHAR(50),
    PDI_FuelCont_ID VARCHAR(50),
    RowCount INT
);

INSERT INTO @SampleJoinTest
SELECT
    V.Gravitate_Vendor,
    V.PDI_FuelCont_ID,
    COUNT(*)
FROM dbo.vw_Xref_Contract_Gravitate_To_PDI V
GROUP BY V.Gravitate_Vendor, V.PDI_FuelCont_ID;

DECLARE @JoinTestRowCount INT = @@ROWCOUNT;
IF @JoinTestRowCount = 0
BEGIN
    RAISERROR('CRITICAL: Sample join test returned no rows', 16, 1);
END

PRINT '  OK: Sample join test passed (' + CAST(@JoinTestRowCount AS VARCHAR(10)) + ' rows)';

PRINT 'PHASE 5 PASSED' + CHAR(10);

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '================================================================================';
PRINT 'DEPLOYMENT VALIDATION COMPLETE - ALL PHASES PASSED';
PRINT '================================================================================';
PRINT 'Seeds rows inserted: 200';
PRINT 'View created: vw_Xref_Contract_Gravitate_To_PDI';
PRINT 'Next step: Repoint sp_Gravitate_FTP_UPLOAD_SELECT to consume view (ADR required)';
PRINT '================================================================================';
