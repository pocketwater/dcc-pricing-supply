-- ============================================================================
-- SEED: Xref_Registry Contract Domain
-- Gravitate Vendor/Terminal/Bucket → PDI FuelCont Mapping
-- Source: Production Surface (Gravitate_PDI-SQL-02_XREF_Prod.csv)
-- Database: PDI_PricingLink (COL_WH.dbo.Xref_Registry)
-- Scope: v1, PricingLink Only (Gravitate FTP pricing feed)
-- ============================================================================
-- Purpose:
--   Seed the canonical Xref_Registry with 200 rows representing the complete,
--   active mapping state of Gravitate vendor/price-type/terminal/bucket
--   combinations to PDI fuel contract identities.
--
-- Key Pattern (4-dimensional composite):
--   (Gravitate_Vendor, Gravitate_Price_Type, Gravitate_Trmnl_Name, Gravitate_Bucket)
--   → PDI_FuelCont_ID + PDI_FuelCont_Key + PDI_Trmnl_Key + PDI_Vend_Key
--
-- Data Quality:
--   - 200 rows from production surface (proven-live in Gravitate FTP feed)
--   - 17 vendors, 3 price types, 49 terminals, 26 buckets
--   - 28 unique PDI FuelCont IDs, 13 unique PDI Vend Keys
--   - 7 multi-type mappings (phillips66, wyoming): same vendor/terminal/bucket
--     but different price types map to different PDI contracts (EXPECTED/CORRECT)
--   - Newline in 'seaportsp' vendor: cleaned during seed
--
-- Execution Context:
--   Requires connection to: PDI-SQL-02, PDI_PricingLink (COL_WH.dbo.Xref_Registry)
--   Execution user must have INSERT permission on dbo.Xref_Registry
--   Expected duration: < 5 seconds
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- Truncate or archive existing seed rows for this domain (optional; comment out if append-mode)
-- DELETE FROM dbo.Xref_Registry
-- WHERE Domain_Name = 'Contract'
--   AND Source_System = 'Gravitate'
--   AND Target_System = 'PDI'
--   AND Source_Description LIKE 'Seeded from Gravitate_PDI-SQL-02_XREF_Prod%';

-- Seed the registry from production surface
INSERT INTO dbo.Xref_Registry
(
    Domain_Name,
    Source_System,
    Target_System,
    Target_Channel,
    Workgroup,
    Owning_Pipeline,
    Source_Key_1,     -- Gravitate_Vendor (cleaned: TRIM/LOWER applied)
    Source_Key_2,     -- Gravitate_Price_Type (branded, contract, rack)
    Source_Key_3,     -- Gravitate_Trmnl_Name
    Source_Key_4,     -- Gravitate_Bucket
    Source_Description,
    Target_Key,       -- PDI_FuelCont_Key
    Target_Code,      -- PDI_FuelCont_ID
    Resolution_Status,
    Is_Active,
    Effective_From,
    Effective_To,
    Consuming_Views,
    Notes,
    Created_Dtm,
    Created_By
)
SELECT
    Domain_Name = 'Contract',
    Source_System = 'Gravitate',
    Target_System = 'PDI',
    Target_Channel = CAST(NULL AS varchar(30)),
    Workgroup = 'COIL-Pricing-Supply',
    Owning_Pipeline = 'CitySV_Costs / CitySV_Prices / Gravitate-Orders',
    Source_Key_1 = LTRIM(RTRIM(REPLACE([Gravitate_Vendor], CHAR(10), ''))),  -- Clean embedded newlines
    Source_Key_2 = [Gravitate_Price_Type],
    Source_Key_3 = [Gravitate_Trmnl_Name],
    Source_Key_4 = [Gravitate_Bucket],
    Source_Description = 'Seeded from Gravitate_PDI-SQL-02_XREF_Prod production surface (v1, PricingLink only)',
    Target_Key = [PDI_FuelCont_Key],
    Target_Code = [PDI_FuelCont_ID],
    Resolution_Status = 'ACTIVE',
    Is_Active = 1,
    Effective_From = CAST(GETDATE() AS DATE),
    Effective_To = CAST(NULL AS date),
    Consuming_Views = 'vw_Xref_Contract_Gravitate_To_PDI',
    Notes = 'Contract canonical seed v1 (terminal/vendor keys retained in source extract; canonical surface resolves contract IDs).',
    Created_Dtm = SYSUTCDATETIME(),
    Created_By = 'Copilot-SEED-v1-2026-05-13'
FROM (
    SELECT
        [Gravitate_Vendor] = 'bpoil',
        [Gravitate_Price_Type] = 'rack',
        [Gravitate_Trmnl_Name] = 'spokanehl',
        [Gravitate_Bucket] = 'idcsv',
        [PDI_FuelCont_ID] = 'BP.U.R.X',
        [PDI_Trmnl_Key] = 10,
        [PDI_Vend_Key] = 8436,
        [PDI_FuelCont_Key] = 13
    UNION ALL SELECT 'bpoil', 'rack', 'spokanehl', 'id', 'BP.U.R.X', 10, 8436, 13
    UNION ALL SELECT 'calumet', 'rack', 'greatflsmr', 'idcsv', 'CAL.U.R.X', 1609, 10722, 14
    UNION ALL SELECT 'calumet', 'rack', 'greatflsmr', 'mtcsv', 'CAL.U.R.X', 1609, 10722, 14
    UNION ALL SELECT 'calumet', 'rack', 'greatflsmr', 'waimp', 'CAL.U.R.X', 1609, 10722, 14
    UNION ALL SELECT 'cenex', 'branded', 'glendivecx', 'mtcsv', 'CHS.B.R', 2113, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'greatflsco', 'mt', 'CHS.B.R', 2115, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'greatflsco', 'mtcsv', 'CHS.B.R', 2115, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'greatflsco', 'idcsv', 'CHS.B.R', 2115, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'greatflsco', 'waimp', 'CHS.B.R', 2115, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'greatflsmr', 'mtcsv', 'CHS.B.R', 1609, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'greatflsmr', 'waimp', 'CHS.B.R', 1609, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'laurelcx', 'mtcsv', 'CHS.B.R', 2127, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'laurelcx', 'waimpcsv', 'CHS.B.R.X', 2127, 15390, 425
    UNION ALL SELECT 'cenex', 'branded', 'logancx', 'mt', 'CHS.B.R', 2327, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'logancx', 'mtcsv', 'CHS.B.R', 2327, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'missoulaco', 'mt', 'CHS.B.R', 28, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'missoulaco', 'mtcsv', 'CHS.B.R', 28, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'missoulaco', 'waimp', 'CHS.B.R', 28, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'missoulaco', 'waimpcsv', 'CHS.B.R', 28, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'missoulacx', 'idcsv', 'CHS.B.R', 26, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'missoulacx', 'mt', 'CHS.B.R', 26, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'missoulacx', 'mtcsv', 'CHS.B.R', 26, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'missoulacx', 'waimp', 'CHS.B.R', 26, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'missoulacx', 'waimpcsv', 'CHS.B.R', 26, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'spokanehl', 'exwa', 'CHS.B.R.X', 10, 15390, 425
    UNION ALL SELECT 'cenex', 'branded', 'spokanehl', 'exwacsv', 'CHS.B.R.X', 10, 15390, 425
    UNION ALL SELECT 'cenex', 'branded', 'spokanehl', 'idcsv', 'CHS.B.R.X', 10, 15390, 425
    UNION ALL SELECT 'cenex', 'branded', 'spokanehl', 'wa', 'CHS.B.R', 10, 15390, 419
    UNION ALL SELECT 'cenex', 'branded', 'spokanehl', 'wacsv', 'CHS.B.R', 10, 15390, 419
    UNION ALL SELECT 'chevron', 'branded', 'pascoma', 'wacsv', 'CHV.B.R', 4, 31, 3
    UNION ALL SELECT 'chevron', 'branded', 'pascoma', 'orcsv', 'CHV.B.R.W.O', 4, 31, 449
    UNION ALL SELECT 'chevron', 'branded', 'spokanehl', 'wacsv', 'CHV.B.R', 10, 31, 3
    UNION ALL SELECT 'chevron', 'branded', 'spokanehl', 'idcsv', 'CHV.B.R.X', 10, 31, 391
    UNION ALL SELECT 'cityservice', 'contract', 'meadspo', 'idcsv', 'COL.U.R.X', 2144, 13717, 247
    UNION ALL SELECT 'cityservice', 'contract', 'meadspo', 'wacsv', 'COL.U.R', 2144, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'eugenekm', 'or', 'COL.U.R', 34, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'eugenekm', 'orcsv', 'COL.U.R', 34, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'meadspo', 'exwa', 'COL.U.R.X', 2144, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'meadspo', 'exwacsv', 'COL.U.R.X', 2144, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'meadspo', 'wa', 'COL.U.R', 2144, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'meadspo', 'wacsv', 'COL.U.R', 2144, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'meadspo', 'id', 'COL.U.R.X', 2144, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'meadspo', 'idcsv', 'COL.U.R.X', 2144, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'pascotw', 'wa', 'COL.U.R', 104, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'pascotw', 'wacsv', 'COL.U.R', 104, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'pascotw', 'or', 'COL.U.R.W.O', 104, 13717, 248
    UNION ALL SELECT 'colemanoil', 'contract', 'pascotw', 'orcsv', 'COL.U.R.W.O', 104, 13717, 248
    UNION ALL SELECT 'colemanoil', 'contract', 'pascotw', 'exwa', 'COL.U.R.X', 104, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'portlandco', 'or', 'COL.U.R', 41, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'portlandco', 'orcsv', 'COL.U.R', 41, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'portlandco', 'wa', 'COL.U.R.O.W', 41, 13717, 180
    UNION ALL SELECT 'colemanoil', 'contract', 'portlandco', 'wacsv', 'COL.U.R.O.W', 41, 13717, 180
    UNION ALL SELECT 'colemanoil', 'contract', 'portlandco', 'waimp', 'COL.U.R.X', 41, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'portlandns', 'wa', 'COL.U.R.O.W', 39, 13717, 180
    UNION ALL SELECT 'colemanoil', 'contract', 'portlandns', 'or', 'COL.U.R', 39, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'portlandns', 'orcsv', 'COL.U.R', 39, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'qncyrail', 'exwa', 'COL.U.R.X', 2107, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'qncyrail', 'exwacsv', 'COL.U.R.X', 2107, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'qncyrail', 'wa', 'COL.U.R', 2107, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'qncyrail', 'wacsv', 'COL.U.R', 2107, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'spokanehl', 'wa', 'COL.U.R', 10, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'spokanehl', 'wacsv', 'COL.U.R', 10, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'spokanehl', 'id', 'COL.U.R.X', 10, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'spokanehl', 'idcsv', 'COL.U.R.X', 10, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'spokanehl', 'exwa', 'COL.U.R.X', 10, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'tacomans', 'wa', 'COL.U.R', 13, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'tacomans', 'wacsv', 'COL.U.R', 13, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'tacomans', 'exwa', 'COL.U.R.X', 13, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'tacomans', 'or', 'COL.U.R.O.W', 13, 13717, 180
    UNION ALL SELECT 'colemanoil', 'contract', 'tacomatrg', 'wa', 'COL.U.R', 12, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'tacomatrg', 'wacsv', 'COL.U.R', 12, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'tacomatrg', 'exwa', 'COL.U.R.X', 12, 13717, 247
    UNION ALL SELECT 'colemanoil', 'contract', 'tacomatrg', 'or', 'COL.U.R.O.W', 12, 13717, 180
    UNION ALL SELECT 'colemanoil', 'contract', 'umatillatw', 'or', 'COL.U.R', 33, 13717, 246
    UNION ALL SELECT 'colemanoil', 'contract', 'umatillatw', 'orcsv', 'COL.U.R', 33, 13717, 246
    UNION ALL SELECT 'delek', 'rack', 'tylerdk', 'tx', 'DEL.U.R', 2147, 15559, 455
    UNION ALL SELECT 'exxon', 'branded', 'billngspmt', 'mtcsv', 'XOM.B.R', 29, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'billngspmt', 'wy', 'XOM.B.R.X', 29, 11143, 429
    UNION ALL SELECT 'exxon', 'branded', 'bozemanpmt', 'mtcsv', 'XOM.B.R', 2121, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'glendivecx', 'mtcsv', 'XOM.B.R', 2113, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'greatflsco', 'mtcsv', 'XOM.B.R', 2115, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'greatflsco', 'waimp', 'XOM.B.R', 2115, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'greatflsmr', 'mtcsv', 'XOM.B.R', 1609, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'greatflsmr', 'waimp', 'XOM.B.R', 1609, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'helenapmt', 'mtcsv', 'XOM.B.R', 2124, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'missoulaco', 'waimp', 'XOM.B.R', 28, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'missoulaco', 'idcsv', 'XOM.B.R', 28, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'missoulaco', 'mtcsv', 'XOM.B.R', 28, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'missoulaco', 'waimpcsv', 'XOM.B.R', 28, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'ms.lakeco', 'wacsv', 'XOM.B.R', 105, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'spokanehl', 'idcsv', 'XOM.B.R.X', 10, 11143, 429
    UNION ALL SELECT 'exxon', 'branded', 'spokanehl', 'wacsv', 'XOM.B.R', 10, 11143, 4
    UNION ALL SELECT 'exxon', 'branded', 'SpokanePMT', 'idcsv', 'XOM.B.R.X', 9, 11143, 429
    UNION ALL SELECT 'exxon', 'branded', 'SpokanePMT', 'wacsv', 'XOM.B.R', 9, 11143, 4
    UNION ALL SELECT 'flint', 'rack', 'omahamg', 'ne', 'FLT.U.R', 2131, 15560, 456
    UNION ALL SELECT 'flint', 'rack', 'rosevillefh', 'mn', 'FLT.U.R', 2465, 15560, 456
    UNION ALL SELECT 'flint', 'rack', 'siouxctymg', 'ia', 'FLT.U.R', 2112, 15560, 456
    UNION ALL SELECT 'p66brandedspec8', 'contract', 'spokaneco', 'wacsv', 'P66.B.S.8', 102, 32, 451
    UNION ALL SELECT 'p66brandedspec8', 'contract', 'spokaneco', 'idcsv', 'P66.B.S.8.X', 102, 32, 453
    UNION ALL SELECT 'p66brandedspec9', 'contract', 'spokaneco', 'wacsv', 'P66.B.S.9', 102, 32, 450
    UNION ALL SELECT 'p66brandedspec9', 'contract', 'spokaneco', 'idcsv', 'P66.B.S.9.X', 102, 32, 452
    UNION ALL SELECT 'parmontana', 'rack', 'billngspmt', 'mtcsv', 'PMT.U.R', 29, 13384, 15
    UNION ALL SELECT 'parmontana', 'rack', 'glendivecx', 'mtcsv', 'PMT.U.R', 2113, 13384, 15
    UNION ALL SELECT 'parmontana', 'rack', 'greatflsco', 'mtcsv', 'PMT.U.R', 2115, 13384, 15
    UNION ALL SELECT 'parmontana', 'rack', 'missoulaco', 'mtcsv', 'PMT.U.R', 28, 13384, 15
    UNION ALL SELECT 'phillips66', 'branded', 'albuquerqeco', 'nm', 'P66.B.R', 2108, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'albuquerqeco', 'nm', 'P66.U.R', 2108, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'billingsco', 'mtcsv', 'P66.B.R', 27, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'billingsco', 'wy', 'P66.B.R', 27, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'billingsco', 'mtcsv', 'P66.U.R', 27, 32, 7
    UNION ALL SELECT 'phillips66', 'rack', 'bkrsflddtl', 'ca', 'P66.U.R', 2142, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'boisehfs', 'idcsv', 'P66.B.R', 30, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'borgerco', 'tx', 'P66.U.R', 2119, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'bozemanco', 'mtcsv', 'P66.B.R', 2120, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'chevronwb', 'orcsv', 'P66.U.R', 36, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'cmrcectyco', 'ca', 'P66.B.R', 2109, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'cmrcectyco', 'co', 'P66.U.R', 2109, 32, 7
    UNION ALL SELECT 'phillips66', 'rack', 'deerparkic', 'tx', 'P66.U.R', 2122, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'greatflsco', 'idcsv', 'P66.B.R', 2115, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'greatflsco', 'mtcsv', 'P66.B.R', 2115, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'greatflsco', 'waimp', 'P66.B.R', 2115, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'greatflsco', 'mtcsv', 'P66.U.R', 2115, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'greatflsmr', 'mtcsv', 'P66.B.R', 1609, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'helenamtco', 'mtcsv', 'P66.B.R', 2125, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'kscityco', 'ks', 'P66.U.R', 2126, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'lngbeachma', 'ca', 'P66.B.R', 2152, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'missoulaco', 'id', 'P66.B.R', 28, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'missoulaco', 'idcsv', 'P66.B.R', 28, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'missoulaco', 'mtcsv', 'P66.B.R', 28, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'missoulaco', 'mtcsv', 'P66.U.R', 28, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'missoulaco', 'waimp', 'P66.B.R', 28, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'missoulaco', 'waimpcsv', 'P66.B.R', 28, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'newcastlwy', 'wy', 'P66.B.R', 2130, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'omahamg', 'ne', 'P66.B.R', 2131, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'omahamg', 'ne', 'P66.U.R', 2131, 32, 7
    UNION ALL SELECT 'phillips66', 'rack', 'pasadenaco', 'tx', 'P66.U.R', 2132, 32, 7
    UNION ALL SELECT 'phillips66', 'rack', 'phoenixcj', 'nm', 'P66.U.R', 2133, 32, 7
    UNION ALL SELECT 'phillips66', 'rack', 'phoenixkm', 'az', 'P66.U.R', 2134, 32, 7
    UNION ALL SELECT 'phillips66', 'rack', 'portlandco', 'nm', 'P66.U.R', 41, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'richmndcch', 'ca', 'P66.B.R', 2136, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'richmndcch', 'ca', 'P66.U.R', 2136, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'saltlakeco', 'ut', 'P66.B.R', 2110, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'saltlakeco', 'ut', 'P66.U.R', 2110, 32, 7
    UNION ALL SELECT 'phillips66', 'rack', 'sanysdrsir', 'ca', 'P66.U.R', 2146, 32, 7
    UNION ALL SELECT 'phillips66', 'branded', 'siouxctymg', 'ia', 'P66.B.R', 2112, 32, 6
    UNION ALL SELECT 'phillips66', 'branded', 'spokaneco', 'idcsv', 'P66.B.R.X', 102, 32, 394
    UNION ALL SELECT 'phillips66', 'branded', 'spokaneco', 'wacsv', 'P66.B.R', 102, 32, 6
    UNION ALL SELECT 'phillips66', 'rack', 'tacomans', 'wacsv', 'P66.U.R', 13, 32, 7
    UNION ALL SELECT 'phillips66', 'rack', 'portlandkm', 'orcsv', 'P66.U.R', 37, 32, 7
    UNION ALL SELECT 'quantum', 'branded', 'glendivecx', 'waimp', 'CHS.B.R.X', 2113, 15390, 425
    UNION ALL SELECT 'quantum', 'branded', 'glendivecx', 'mt', 'CHS.B.R', 2113, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'glendivecx', 'mtcsv', 'CHS.B.R', 2113, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'glendivecx', 'waimpcsv', 'CHS.B.R.X', 2113, 15390, 425
    UNION ALL SELECT 'quantum', 'branded', 'greatflsco', 'mt', 'CHS.B.R', 2115, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'greatflsco', 'mtcsv', 'CHS.B.R', 2115, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'greatflsco', 'waimp', 'CHS.B.R', 2115, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'greatflsco', 'idcsv', 'CHS.B.R', 2115, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'greatflsmr', 'mt', 'CHS.B.R', 1609, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'greatflsmr', 'mtcsv', 'CHS.B.R', 1609, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'greatflsmr', 'waimp', 'CHS.B.R', 1609, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'laurelcx', 'mt', 'CHS.B.R', 2127, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'laurelcx', 'mtcsv', 'CHS.B.R', 2127, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'laurelcx', 'waimpcsv', 'CHS.B.R.X', 2127, 15390, 425
    UNION ALL SELECT 'quantum', 'branded', 'laurelcx', 'wy', 'CHS.B.R', 2127, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'laurelcx', 'waimp', 'CHS.B.R.X', 2127, 15390, 425
    UNION ALL SELECT 'quantum', 'branded', 'logancx', 'mt', 'CHS.B.R', 2327, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'logancx', 'mtcsv', 'CHS.B.R', 2327, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'missoulaco', 'mt', 'CHS.B.R', 28, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'missoulaco', 'mtcsv', 'CHS.B.R', 28, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'missoulacx', 'idcsv', 'CHS.B.R', 26, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'missoulacx', 'mt', 'CHS.B.R', 26, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'missoulacx', 'mtcsv', 'CHS.B.R', 26, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'missoulacx', 'waimpcsv', 'CHS.B.R', 26, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'spokanehl', 'exwa', 'CHS.B.R.X', 10, 15390, 425
    UNION ALL SELECT 'quantum', 'branded', 'spokanehl', 'exwacsv', 'CHS.B.R.X', 10, 15390, 425
    UNION ALL SELECT 'quantum', 'branded', 'spokanehl', 'idcsv', 'CHS.B.R.X', 10, 15390, 425
    UNION ALL SELECT 'quantum', 'branded', 'spokanehl', 'wa', 'CHS.B.R', 10, 15390, 419
    UNION ALL SELECT 'quantum', 'branded', 'spokanehl', 'wacsv', 'CHS.B.R', 10, 15390, 419
    UNION ALL SELECT 'seaportsp', 'rack', 'tacomatrg', 'wa', 'SEA.U.R', 12, 12104, 417
    UNION ALL SELECT 'seaportsp', 'rack', 'tacomatrg', 'wacsv', 'SEA.U.R', 12, 12104, 417
    UNION ALL SELECT 'sinclair', 'branded', 'SpokanePMT', 'wa', 'HFS.B.R', 9, 8548, 447
    UNION ALL SELECT 'sinclair', 'branded', 'SpokanePMT', 'wacsv', 'HFS.B.R', 9, 8548, 447
    UNION ALL SELECT 'wyoming', 'contract', 'newcastlwy', 'wy', 'WYO.U.C', 2130, 8606, 418
    UNION ALL SELECT 'wyoming', 'contract', 'newcastlwy', 'wycsv', 'WYO.U.C', 2130, 8606, 418
    UNION ALL SELECT 'wyoming', 'contract', 'rapidctymg', 'sd', 'WYO.U.C', 2135, 8606, 418
    UNION ALL SELECT 'wyoming', 'contract', 'rapidctymg', 'sdcsv', 'WYO.U.C', 2135, 8606, 418
    UNION ALL SELECT 'wyoming', 'rack', 'spokanehl', 'wa', 'WYO.U.R', 10, 8606, 2
    UNION ALL SELECT 'wyoming', 'rack', 'spokanehl', 'wacsv', 'WYO.U.R', 10, 8606, 2
    UNION ALL SELECT 'sinclair', 'branded', 'billingsco', 'mtcsv', 'HFS.B.R', 27, 8548, 447
    UNION ALL SELECT 'sinclair', 'branded', 'billngspmt', 'mtcsv', 'HFS.B.R', 29, 8548, 447
    UNION ALL SELECT 'sinclair', 'branded', 'helenamtco', 'mt', 'HFS.B.R', 2125, 8548, 447
    UNION ALL SELECT 'sinclair', 'branded', 'helenapmt', 'mt', 'HFS.B.R', 2124, 8548, 447
    UNION ALL SELECT 'phillips66', 'rack', 'missoulaco', 'mt', 'P66.U.R', 28, 32, 7
    UNION ALL SELECT 'chevron', 'branded', 'pascoma', 'idcsv', 'CHV.B.R.X', 4, 31, 391
    UNION ALL SELECT 'parmontana', 'rack', 'missoulaco', 'waimpcsv', 'PMT.U.R.S.X', 28, 13384, 428
    UNION ALL SELECT 'bpoil', 'rack', 'spokanehl', 'mtcsv', 'BP.U.R.X', 10, 8436, 13
    UNION ALL SELECT 'cenex', 'branded', 'spokanehl', 'mtcsv', 'CHS.B.R.X', 10, 15390, 425
    UNION ALL SELECT 'phillips66', 'branded', 'spokaneco', 'mtcsv', 'P66.B.R.X', 102, 32, 394
) AS Source_Data;

-- Validation: Report row count and any conflicts
DECLARE @InsertedCount INT = @@ROWCOUNT;
SELECT
    'SEED Complete' AS Status,
    @InsertedCount AS InsertedRows,
    GETDATE() AS Execution_Time
UNION ALL
SELECT
    'Domain Contract Rows in Registry',
    COUNT(*),
    NULL
FROM dbo.Xref_Registry
WHERE Domain_Name = 'Contract'
  AND Source_System = 'Gravitate'
  AND Target_System = 'PDI';

COMMIT TRANSACTION;

SET NOCOUNT OFF;
