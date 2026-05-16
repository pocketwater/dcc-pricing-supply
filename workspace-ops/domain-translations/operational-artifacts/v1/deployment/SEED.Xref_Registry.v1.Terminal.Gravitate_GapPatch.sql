-- ============================================================================
-- SEED PATCH: Xref_Registry Terminal Domain (Gravitate gap closure)
-- Database: PDI_PricingLink
-- Scope: Add missing terminal tokens required by contract view key resolution
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DECLARE @Today date = CAST(GETDATE() AS date);
DECLARE @Inserted int = 0;

;WITH SourceRows AS
(
    SELECT
          Source_Key_1 = 'boisehfs'
        , Target_Key = CAST(30 AS decimal(15,0))
        , Target_Code = 'ID4150'
    UNION ALL
    SELECT
          Source_Key_1 = 'qncyrail'
        , Target_Key = CAST(2107 AS decimal(15,0))
        , Target_Code = 'WAC002'
)
INSERT dbo.Xref_Registry
(
      Domain_Name
    , Source_System
    , Target_System
    , Target_Channel
    , Workgroup
    , Owning_Pipeline
    , Source_Key_1
    , Source_Key_2
    , Source_Key_3
    , Source_Key_4
    , Source_Description
    , Target_Key
    , Target_Code
    , Resolution_Status
    , Is_Active
    , Effective_From
    , Effective_To
    , Consuming_Views
    , Notes
    , Created_Dtm
    , Created_By
)
SELECT
      Domain_Name = 'Terminal'
    , Source_System = 'Gravitate'
    , Target_System = 'PDI'
    , Target_Channel = CAST(NULL AS varchar(30))
    , Workgroup = 'COIL-Pricing-Supply'
    , Owning_Pipeline = 'gravitate-orders'
    , Source_Key_1 = S.Source_Key_1
    , Source_Key_2 = CAST(NULL AS varchar(100))
    , Source_Key_3 = CAST(NULL AS varchar(100))
    , Source_Key_4 = CAST(NULL AS varchar(100))
    , Source_Description = 'Terminal canonical gap patch for contract feed continuity (v1, SQL-02)'
    , Target_Key = S.Target_Key
    , Target_Code = S.Target_Code
    , Resolution_Status = 'ACTIVE'
    , Is_Active = 1
    , Effective_From = @Today
    , Effective_To = CAST(NULL AS date)
    , Consuming_Views = 'vw_Xref_Contract_Gravitate_To_PDI'
    , Notes = 'Added by v1 terminal gap patch to eliminate legacy fallback dependency in contract view.'
    , Created_Dtm = SYSUTCDATETIME()
    , Created_By = 'Copilot-SEED-v1-2026-05-15'
FROM SourceRows S
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Xref_Registry X
    WHERE X.Domain_Name = 'Terminal'
      AND X.Source_System = 'Gravitate'
      AND X.Target_System = 'PDI'
      AND X.Is_Active = 1
      AND LOWER(X.Source_Key_1) = LOWER(S.Source_Key_1)
      AND TRY_CAST(X.Target_Key AS decimal(15,0)) = S.Target_Key
);

SET @Inserted = @@ROWCOUNT;

COMMIT TRANSACTION;

SELECT
      Result = 'TERMINAL_GAP_PATCH_COMPLETE'
    , Inserted_Rows = @Inserted;
