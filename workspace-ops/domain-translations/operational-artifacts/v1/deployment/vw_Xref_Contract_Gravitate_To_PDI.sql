-- ============================================================================
-- CONTRACT VIEW: vw_Xref_Contract_Gravitate_To_PDI
-- Purpose: Replace direct joins to legacy CITT tables and Gravitate_PDI_Master_XREF
-- Database: PDI_PricingLink (COL_WH.dbo)
-- Scope: v1, PricingLink Only (Gravitate FTP pricing feed)
-- ============================================================================
--
-- This view provides the contract resolution for the Gravitate FTP pricing
-- feed. It maps Gravitate operational attributes (vendor, price-type,
-- terminal, bucket) to PDI fuel contract identities via the canonical
-- Xref_Registry.
--
-- Expected Consumer: sp_Gravitate_FTP_UPLOAD_SELECT
-- Current Legacy Source: Gravitate_PDI_Master_XREF (will be frozen post-migration)
--
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_Xref_Contract_Gravitate_To_PDI
AS
SELECT
    -- Gravitate source keys (4-part composite identifier)
    Gravitate_Vendor = X.Source_Key_1,
    Gravitate_Price_Type = X.Source_Key_2,
    Gravitate_Trmnl_Name = X.Source_Key_3,
    Gravitate_Bucket = X.Source_Key_4,

    -- PDI target identities
    PDI_FuelContDtl_Key = TRY_CAST(X.Target_Key AS INT),
    PDI_FuelCont_Key = TRY_CAST(X.Target_Key AS INT),
    PDI_FuelCont_ID = X.Target_Code,
    -- Clone/canonical path only: terminal from xref domain and vendor from FIVC clone.
    PDI_Trmnl_Key = T1.PDI_Trmnl_Key,
    PDI_Vend_Key = FV1.Vend_Key,

    -- Metadata
    Resolution_Status = X.Resolution_Status,
    Is_Active = X.Is_Active,
    Effective_From = X.Effective_From,
    Source_Description = X.Source_Description

FROM dbo.Xref_Registry X
OUTER APPLY
(
    SELECT TOP (1)
        PDI_Trmnl_Key = TRY_CAST(TX.Target_Key AS INT)
    FROM dbo.Xref_Registry TX
    WHERE TX.Domain_Name = 'Terminal'
      AND TX.Source_System = 'Gravitate'
      AND TX.Target_System = 'PDI'
      AND TX.Is_Active = 1
      AND LOWER(TX.Source_Key_1) = LOWER(X.Source_Key_3)
    ORDER BY TRY_CAST(TX.Target_Key AS INT)
) AS T1
OUTER APPLY
(
    SELECT TOP (1)
        Vend_Key = FV.Vend_Key
    FROM dbo.PDI_FIVC_Vendor_Clone FV
    WHERE FV.FuelContDtl_Key = TRY_CAST(X.Target_Key AS INT)
    ORDER BY FV.Vend_Key
) AS FV1
WHERE X.Domain_Name = 'Contract'
  AND X.Source_System = 'Gravitate'
  AND X.Target_System = 'PDI'
  AND X.Is_Active = 1;
