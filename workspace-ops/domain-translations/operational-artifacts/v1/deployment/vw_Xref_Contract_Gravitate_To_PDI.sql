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

CREATE VIEW dbo.vw_Xref_Contract_Gravitate_To_PDI
AS
SELECT
    -- Gravitate source keys (4-part composite identifier)
    Gravitate_Vendor = X.Source_Key_1,
    Gravitate_Price_Type = X.Source_Key_2,
    Gravitate_Trmnl_Name = X.Source_Key_3,
    Gravitate_Bucket = X.Source_Key_4,
    
    -- PDI target identities
    PDI_FuelCont_Key = TRY_CAST(X.Target_Key AS INT),
    PDI_FuelCont_ID = X.Target_Code,
    PDI_Trmnl_Key = TRY_CAST(X.Target_Secondary_1 AS INT),
    PDI_Vend_Key = TRY_CAST(X.Target_Secondary_2 AS INT),
    
    -- Metadata
    Resolution_Status = X.Is_Active,
    Effective_From = X.Effective_From,
    Source_Description = X.Source_Description
    
FROM dbo.Xref_Registry X
WHERE X.Domain_Name = 'Contract'
  AND X.Source_System = 'Gravitate'
  AND X.Target_System = 'PDI'
  AND X.Is_Active = 1;
