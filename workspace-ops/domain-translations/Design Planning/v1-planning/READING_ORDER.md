# V1 Planning Reading Order

**Iteration:** v1 (citysv-costs CITT canonicalization)
**Start Date:** 2026-05-13

## Recommended Reading Order

1. **SCOPE.domain_translation_canonical_mapping.v1.md** — Executive summary and migration objectives
   - Understand what's being migrated and why
   - Review risk profile
   - Confirm success criteria

2. **DESIGN.domain_translation_canonical_mapping.v1.md** — Technical specifications
   - Registry entry schema for three domains (Product, Terminal, Vendor/Contract)
   - Contract view definitions
   - Deprecation & freeze plan
   - Validation gates

## Quick Reference

### Tables Being Migrated
- `PDI_CITT_Axxis_Grav_PDI_Products_Clone` (58 rows)
- `PDI_CITT_Axxis_Grav_PDI_Terminals_Clone` (90 rows)
- `PDI_CITT_Axxis_Grav_PDI_Vend_FIVC_Clone` (53 rows)

### New Contract Views
- `vw_Xref_Product_Gravitate_To_PDI`
- `vw_Xref_Terminal_Gravitate_To_PDI`
- `vw_Xref_Contract_Axxis_To_PDI`

### Consuming Views to Repoint
- `vw_CitySV_Axxis_Prices_Resolve_LatestOperationalPrice`

## Next Steps

1. Stakeholder review of SCOPE and DESIGN
2. Approval from Jason Vassar and COIL Pricing team
3. Move to Build phase (seed scripts, contract views, deployment SQL)
