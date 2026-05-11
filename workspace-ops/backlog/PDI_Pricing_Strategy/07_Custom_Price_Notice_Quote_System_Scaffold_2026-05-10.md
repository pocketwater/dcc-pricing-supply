# Custom Price Notice & Quote System — Project Scaffold

**Date:** 2026-05-10
**Author:** Pete (GitHub Copilot)

---

## Objective
Design and implement a custom price notice and quote delivery system, leveraging PDI grouping tables for customer segmentation, but maintaining all pricing logic, quote generation, and email delivery outside of PDI. Minimize dependency on high-cost linked server operations.

---

## Key Principles
- **PDI as Source of Truth for Groups:** Use PDI grouping/dimension tables (e.g., Customer, Customer_Location, Contract Groups) for segmentation, but do not rely on PDI for pricing logic or quote delivery.
- **Externalized Pricing Logic:** All price calculations, quote formatting, and delivery orchestration are handled in the custom system.
- **Clone System as ETL Layer:** Leverage the workspace clone system (`pdi-clone-core`) to sync PDI dimension tables into `PDI_PricingLink` as low-cost, reliable ETL. No linked server overhead.
- **Scalable Email Delivery:** Use a reputable email API (SendGrid, SES, etc.) for high-volume, programmatic quote delivery with reporting.
- **Future-Proof for ODIMP Price Payload:** Design with the assumption that price as an ODIMP payload will be validated and integrated.

---

## Scope

**In Scope:**
- **OD Order-Time Pricing:** Replicate PDI's order-time pricing logic (real-time calculation during order entry/upload).
- **Custom Fuel Formulas:** Leverage PDI's fuel_formulas semantics to calculate prices based on cost basis, adjustments, and product rules.
- **Quote Generation & Email:** Custom formatting and bulk delivery via email API.

**Out of Scope (For Now):**
- **Cardlock Pricing (CP):** PDI's Cardlock system is not part of this initiative.
- **OD-Warehouse Pricing:** Warehouse transfer pricing is deferred.

---

## Deep Dive: PDI Fuel_Formulas

1. **Data Layer**
   - Use clone system (`pdi-clone-core` procs) to sync PDI dimension tables into `PDI_PricingLink`:
     - Customers, Customer_Locations, Contract_Groups, OD_Fuel_Pricing_* (rules, products, locations, origins)
   - Maintain custom tables in `PDI_PricingLink` for calculated prices, quote history, and delivery logs.
   - No linked server queries; clone system handles all PDI synchronization.

2. **Pricing Engine**
   - Implement pricing rules engine (in code or SQL) to calculate prices for each customer/product/date.
   - Support group, customer, and location-level overrides.
   - Log all calculations for auditability.

3. **Quote Generation**
   - Generate custom-formatted quote emails (HTML/text, with optional PDF/CSV attachments).
   - Use templates with dynamic fields for branding and personalization.

4. **Email Delivery**
   - Integrate with email API (SendGrid, SES, etc.) for batch sending.
   - Capture delivery status, bounces, and engagement via API/webhooks.
   - Store all delivery/reporting data in local tables for dashboarding.

5. **Orchestration & Monitoring**
   - Orchestrate daily quote runs, error handling, and retries.
   - Provide dashboards for delivery status, failures, and customer engagement.

---

## Implementation Steps

1. **ETL: Leverage Clone System**
   - Add sync procedures to `pdi-clone-core` to replicate required PDI tables into `PDI_PricingLink`:
     - Customer, Customer_Location, Contract_Groups
     - OD_Fuel_Pricing_Rules, OD_Fuel_Pricing_Products, OD_Fuel_Pricing_Locations, OD_Fuel_Pricing_Origins
     - Fuel_Formulas and related cost/pricing basis tables
   - Schedule daily or on-demand sync to keep dimensions current.
   - Eliminate linked server overhead.

2. **Schema: Custom Tables**
   - `Calculated_Prices` (customer, product, date, price, rule_id, calc_log)
   - `Quote_History` (customer, quote_id, sent_date, status, template_id)
   - `Email_Delivery_Log` (quote_id, email_id, status, bounce_reason, engagement)

3. **Pricing Engine**
   - Implement rule engine (start simple: cost + markup, expand as needed).
   - Support group and customer-level overrides.
   - Log all calculations.

4. **Quote Generation**
   - Design HTML/text templates with dynamic fields.
   - Implement code to generate quote content and optional attachments.

5. **Email Integration**
   - Integrate with chosen email API.
   - Implement batch sending, error handling, and reporting ingestion.

6. **Orchestration**
   - Schedule daily quote runs.
   - Monitor for failures, retries, and reporting.

7. **Validation Precursor**
   - Validate price as ODIMP payload (critical for future integration).

---

## Open Questions / Risks
- **ODIMP Price Payload:** Must validate that price can be reliably delivered as part of ODIMP import/export.
- **PDI Table Access:** Confirm that required grouping tables are accessible via low-cost ETL.
- **Email Deliverability:** Monitor for spam/blacklist issues as volume scales.
- **Auditability:** Ensure all price calculations and deliveries are logged for compliance.

---

## Next Steps
- Review and validate this scaffold.
- Prioritize ETL and schema design.
- Schedule ODIMP price payload validation.
- Select email provider and prototype integration.

---

*This is a living document. Update as design and validation progress.*
