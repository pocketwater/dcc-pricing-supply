# PDI Help Extraction — OD Fuel Pricing (Strategy Staging)

Date: 2026-05-10
Status: Staged in strategy folder (not merged into ontology)

---

## Purpose
Capture PDI Enterprise Help evidence relevant to OD fuel pricing semantics and map it to open strategy questions, without writing into ontology yet.

---

## Scope Captured From PDI Help Navigation

The following documentation nodes were identified in the Enterprise Help tree as directly relevant to OD pricing behavior:

1. PDI Order Desk (OD) -> Wholesale Pricing -> OD Fuel Pricing - Setup Tasks
2. PDI Order Desk (OD) -> Wholesale Pricing -> Wholesale Fuel Pricing Strategies - Web Client (ODFPS)
3. PDI Order Desk (OD) -> Wholesale Pricing -> Wholesale Pricing Rules - Setting Up (ODCPR)
4. PDI Order Desk (OD) -> OD Price Notices - Setup and Processing Tasks
5. PDI Order Desk (OD) -> OD Fuel Price Notice Rules - Setup Tasks
6. PDI Fuel Inventory (FI) -> Fuel Cost Formulas - Setup and Processing Tasks
7. PDI Fuel Inventory (FI) -> Fuel Costs - Setup and Processing Tasks
8. PDI Accounts Receivable (AR) -> Customers - Locations: Pricing (ARC)
9. PDI Accounts Receivable (AR) -> Customers - Locations: OD Price Notices (ARC)

---

## Strategy Mapping (SQL Discovery -> Doc Targets)

1. Price basis code meaning validation
- SQL locked production codes: 0,1,2,4,5,7,8,10,11,14
- Doc targets: ODFPS, ODCPR, FI Fuel Cost Formulas
- Expected output: plain-language meaning for each active basis code

2. Adjustment method semantics (0/1)
- SQL locked: 0=no adjustment, 1=add adjustment (distribution observed)
- Doc targets: ODCPR, ODFPS
- Expected output: exact behavior and precedence when adjustment and basis are both present

3. Hierarchy / precedence validation
- SQL indicates location-specific mappings via OD_Fuel_Pricing_Locations
- Doc targets: ODCPR, ODFPS, ARC location pricing
- Expected output: explicit precedence chain (location vs customer/group/product/vendor/terminal)

4. Effective date and fallback behavior
- SQL shows date-scoped rules and formula rows
- Doc targets: FI Fuel Cost Formulas, ODCPR
- Expected output: active-date selection rules, overlap behavior, fallback behavior when no qualifying row

5. Price notice generation dependencies
- SQL/discovery found OD and AR touchpoints
- Doc targets: OD Price Notices, OD Fuel Price Notice Rules, ARC OD Price Notices
- Expected output: required fields, trigger conditions, and export/report implications

---

## Evidence Notes (Current)

1. Confirmed from help tree labels that OD pricing and FI formula domains are separately documented and cross-connected.
2. Confirmed dedicated nodes exist for both:
- pricing rule setup
- price notice rules
- notice generation/process
3. Confirmed AR location-level pages include OD price notice and pricing tabs, indicating customer-location overrides are first-class configuration surfaces.

Note: This staged brief currently captures validated navigation-level evidence and extraction targets. Topic-body extraction is queued for next pass once page-level article content is read section by section.

---

## Recommended Next Pass (In Strategy Folder)

1. Add a per-node capture file with:
- screen title
- canonical help URL
- verbatim setting labels
- behavior summary

2. Build a codebook draft in strategy staging only:
- Price_Basis_Codebook_DRAFT
- Adj_Method_Codebook_DRAFT
- Rule_Precedence_DRAFT

3. After operator review, promote selected findings into ontology.

---

## Non-Ontology Guardrail

Per operator request, this artifact is intentionally staged in strategy only and does not modify ontology documents.
