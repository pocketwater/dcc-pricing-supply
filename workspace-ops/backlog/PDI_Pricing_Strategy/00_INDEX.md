# PDI Pricing Strategy — Document Index

**Phase:** 7–9 (Q2 2026)
**Objective:** Design and implement custom price notice and quote system, leveraging PDI grouping tables and fuel_formulas.

---

## Recommended Reading Order

Use this sequence when reading the full set end to end.

1. [00_INDEX.md](./00_INDEX.md) — orientation and scope
2. [01_CustFuelContract_Domain_Qualification_2026-04-15.md](./01_CustFuelContract_Domain_Qualification_2026-04-15.md) — problem framing and viability gate
3. [02_Wholesale_Fuel_Customer_Pricing_Contracts_Assessment_2026-04-11.md](./02_Wholesale_Fuel_Customer_Pricing_Contracts_Assessment_2026-04-11.md) — preferred production path and constraints
4. [03_CustFuelContract_ContainerVsRules_2026-04-12.md](./03_CustFuelContract_ContainerVsRules_2026-04-12.md) — rule-scope design pattern
5. [04_PDI_Help_OD_Fuel_Pricing_Extraction_2026-05-10.md](./04_PDI_Help_OD_Fuel_Pricing_Extraction_2026-05-10.md) — external documentation evidence staging
6. [05_PDI_Fuel_Formulas_Deep_Dive_2026-05-10.md](./05_PDI_Fuel_Formulas_Deep_Dive_2026-05-10.md) — working semantics model and open items
7. [06_SQL_Exploration_Runbook_2026-05-10.md](./06_SQL_Exploration_Runbook_2026-05-10.md) — validation execution plan
8. [07_Custom_Price_Notice_Quote_System_Scaffold_2026-05-10.md](./07_Custom_Price_Notice_Quote_System_Scaffold_2026-05-10.md) — implementation scaffold and build plan
9. [08_Price_Notice_Process_Domain_Qualification_2026-05-10.md](./08_Price_Notice_Process_Domain_Qualification_2026-05-10.md) — three-system analysis (CP/Cardlock, OD, OD-Warehouse) and external UX replacement strategy

### Quick-Start Path (If You Only Have 20 Minutes)

1. [01_CustFuelContract_Domain_Qualification_2026-04-15.md](./01_CustFuelContract_Domain_Qualification_2026-04-15.md)
2. [04_PDI_Help_OD_Fuel_Pricing_Extraction_2026-05-10.md](./04_PDI_Help_OD_Fuel_Pricing_Extraction_2026-05-10.md)
3. [05_PDI_Fuel_Formulas_Deep_Dive_2026-05-10.md](./05_PDI_Fuel_Formulas_Deep_Dive_2026-05-10.md)
4. [07_Custom_Price_Notice_Quote_System_Scaffold_2026-05-10.md](./07_Custom_Price_Notice_Quote_System_Scaffold_2026-05-10.md)

---

## Related Documents

### Phase 7: Customer Fuel Contracts Qualification
- [01_CustFuelContract_Domain_Qualification_2026-04-15.md](./01_CustFuelContract_Domain_Qualification_2026-04-15.md) — Viability assessment, upsert path, minimum viable contract
- [02_Wholesale_Fuel_Customer_Pricing_Contracts_Assessment_2026-04-11.md](./02_Wholesale_Fuel_Customer_Pricing_Contracts_Assessment_2026-04-11.md) — ODFPC/ODFPCI as preferred path; production discovery
- [03_CustFuelContract_ContainerVsRules_2026-04-12.md](./03_CustFuelContract_ContainerVsRules_2026-04-12.md) — Rule scoping strategy; hybrid pattern (few containers + many rules)

### Phase 8: Price Notice Process Domain Qualification
- [08_Price_Notice_Process_Domain_Qualification_2026-05-10.md](./08_Price_Notice_Process_Domain_Qualification_2026-05-10.md) — Three-system analysis (CP/Cardlock, OD, OD-Warehouse); external UX replacement strategy; pain points and risks

### Phase 9: Custom Price Notice & Quote System (This Document Set)
- [07_Custom_Price_Notice_Quote_System_Scaffold_2026-05-10.md](./07_Custom_Price_Notice_Quote_System_Scaffold_2026-05-10.md) — Project scaffold using clone system as ETL; schema design; email integration
- [05_PDI_Fuel_Formulas_Deep_Dive_2026-05-10.md](./05_PDI_Fuel_Formulas_Deep_Dive_2026-05-10.md) — Pricing basis and formula semantics; ontology capture (in progress)
- [06_SQL_Exploration_Runbook_2026-05-10.md](./06_SQL_Exploration_Runbook_2026-05-10.md) — Ready-to-execute SQL queries for PDI-SQL-01 schema validation
- [04_PDI_Help_OD_Fuel_Pricing_Extraction_2026-05-10.md](./04_PDI_Help_OD_Fuel_Pricing_Extraction_2026-05-10.md) — PDI help extraction staged in strategy (non-ontology)

---

## In-Folder Inventory (Orphan Guard)

Every markdown file currently in this folder is listed below.

- [00_INDEX.md](./00_INDEX.md)
- [01_CustFuelContract_Domain_Qualification_2026-04-15.md](./01_CustFuelContract_Domain_Qualification_2026-04-15.md)
- [02_Wholesale_Fuel_Customer_Pricing_Contracts_Assessment_2026-04-11.md](./02_Wholesale_Fuel_Customer_Pricing_Contracts_Assessment_2026-04-11.md)
- [03_CustFuelContract_ContainerVsRules_2026-04-12.md](./03_CustFuelContract_ContainerVsRules_2026-04-12.md)
- [04_PDI_Help_OD_Fuel_Pricing_Extraction_2026-05-10.md](./04_PDI_Help_OD_Fuel_Pricing_Extraction_2026-05-10.md)
- [05_PDI_Fuel_Formulas_Deep_Dive_2026-05-10.md](./05_PDI_Fuel_Formulas_Deep_Dive_2026-05-10.md)
- [06_SQL_Exploration_Runbook_2026-05-10.md](./06_SQL_Exploration_Runbook_2026-05-10.md)
- [07_Custom_Price_Notice_Quote_System_Scaffold_2026-05-10.md](./07_Custom_Price_Notice_Quote_System_Scaffold_2026-05-10.md)
- [08_Price_Notice_Process_Domain_Qualification_2026-05-10.md](./08_Price_Notice_Process_Domain_Qualification_2026-05-10.md)

---

## Key Clarifications (May 10, 2026)

### Scope Refinements
- **"CP" = Cardlock Pricing**, not Customer Pricing — not in scope for this initiative
- **OD Pricing** (order-time, real-time calculation) is the focus
- **OD-Warehouse Pricing** deferred for future phase

### Architecture Decision
- **ETL Layer:** Use workspace clone system (`pdi-clone-core`) to replicate PDI dimension tables into `PDI_PricingLink`
- **No High-Cost Linked Servers:** Clone system eliminates linked server overhead
- **Pricing Logic:** Externalized (not in PDI), but leverages PDI fuel_formulas semantics

### Validation Precursor
- **Price as ODIMP Payload:** Must validate that price can be reliably delivered as part of ODIMP import/export (scheduled for next session)

### PDI Documentation
- **1Password Share:** https://share.1password.com/s#42yREYXo5D0xX10LudB8SZaFZ5jgs3LNbOtWF9kxk2I
  - Contains PDI pricing documentation and reference materials
  - Pending: Paste content here for integration into this document set

---

## Current Status
- Phases 7–8: Completed (briefs attached)
- Phase 9 Scaffold: Refactored with clone-system ETL (complete)
- Phase 9 Fuel_Formulas Deep Dive: Ontology framework complete (in /PDI_Pricing_Strategy/); live validation scheduled next session
- Phase 9 Price-as-ODIMP-Payload Validation: Scheduled next session

---

## Next Steps

### Session 2 (Tomorrow)

1. **Execute SQL Exploration Runbook** on PDI-SQL-01:
   - Use the queries in [06_SQL_Exploration_Runbook_2026-05-10.md](./06_SQL_Exploration_Runbook_2026-05-10.md)
   - Run all 7 phases (Schema Discovery → Reference Data → Stored Procedures)
   - Capture results and document findings

2. **Retrieve PDI Documentation** from 1Password:
   - Access: https://share.1password.com/s#42yREYXo5D0xX10LudB8SZaFZ5jgs3LNbOtWF9kxk2I
   - Extract relevant sections on fuel_formulas, price basis codes, adjustment methods
   - Paste into fuel_formulas deep dive document (Section 3 and 5)

3. **Validate ODIMP Price Payload**:
   - Confirm that price can be delivered as part of _Orders_Upload
   - Test with sample order batch

4. **Clone System Design**:
   - Design sync procedures for required PDI tables into PDI_PricingLink
   - List tables: Fuel_Costs, OD_Fuel_Pricing_Rules hierarchy, Products, Terminals, Vendors

5. **Prototype Custom Pricing Engine**:
   - Implement simple cost+markup logic based on discovered formulas
   - Test against live PDI order samples
   - Compare results with PDI calculated prices

6. **Email Integration**:
   - Select email provider (SendGrid, SES, or Mailgun)
   - Prototype bulk quote sending API
