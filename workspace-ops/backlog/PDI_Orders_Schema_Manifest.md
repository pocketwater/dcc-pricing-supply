# PDI Orders Schema Manifest

## Purpose

Read-only discovery manifest for `PDI-SQL-01 / PDICompany_2386_01`, centered on `dbo.Orders` and the enforced or code-level domain around it.

This document is intentionally evidence-first:

- foreign keys from `sys.foreign_keys`
- dependency metadata from `sys.sql_expression_dependencies`
- stored procedure body review from `sys.sql_modules`
- direct read/write adjacency inferred only where procedures co-reference `dbo.Orders` with other objects

No DDL was executed. No data was written. No persistent objects were created in the vendor database.

## Executive Read

`dbo.Orders` is the order header table in a much larger vendor-managed order domain. The table itself is deceptively simple from a key standpoint: it has a surrogate primary key `Ord_Key` and one alternate unique key `Ord_No`. The surrounding domain is not simple.

The table is the center of:

- line-item tables for fuel, warehouse items, fees, taxes, freight, payments, preauth, and ship-to overrides
- lifecycle/self-reference relationships for credit, rebill, original-order, and split-national-account variants
- heavy lookup dependency on customer, site, driver, vehicle, terms, invoice, and billing batch objects
- a very large stored procedure surface, dominated by `OD_*` procedures, with downstream `FI_*`, `WI_*`, `AR_*`, and `TX_*` consumers

The strongest practical conclusion is that `dbo.Orders` is not a safe table-upsert domain by table structure alone. PDI expects order lifecycle mutations to happen through procedures, temp work tables, process GUIDs, and status-transition logic.

## How To Think About This Domain

Treat `dbo.Orders` as the header record for a procedure-mediated order workflow, not as an isolated CRUD table.

The working mental model is:

1. An order header is created or copied into `dbo.Orders`.
2. Detail rows are created in one or more child tables depending on order type.
3. Calculation procedures expand pricing, fees, freight, taxes, and load assignments through temp work sets.
4. Status procedures move orders through open, dispatched, delivered, released-for-billing, credit, rebill, and related states.
5. Billing, invoice generation, AR, finance, and warehouse processes consume the order graph.

That means schema keys tell only part of the story. The rest lives in stored procedures and tempdb work patterns such as `OrdersWorkTable`, `Lookup_Keys`, and `Error_Messages`, all of which appear in dependency scans as unresolved transient objects rather than hard relational entities.

## Anchor Object: `dbo.Orders`

### Structural Definition

- table: `dbo.Orders`
- column count: 124
- primary key: `Orders_PK (Ord_Key)`
- alternate unique key: `Ord_No_UK (Ord_No)`
- primary key type: clustered
- business uniqueness exposed by schema: one order number per row

### Notable Header Columns

These are the structurally important header fields surfaced by the metadata and procedure parameter lists:

- identity and business number: `Ord_Key`, `Ord_No`
- type and state: `Ord_Type`, `Ord_Status`, `Ord_Source`
- destination and customer context: `Ord_Dest_Type`, `Ord_Cust_Key`, `Ord_CustLoc_Key`, `Ord_CustCont_Key`, `Ord_Site_Key`
- commercial context: `Ord_Terms_Key`, `Ord_SalesPerson_Key`, `Ord_OrdBillBatch_Key`, `Ord_Buyback_VndInv_Key`, `Ord_Buyback_VndInvPnd_Key`
- scheduling and delivery: `Ord_Order_DateTime`, `Ord_Business_Date`, `Ord_Sch_Deliv_DateTime`, `Ord_Act_Deliv_DateTime`
- workflow/self-link fields: `Ord_OrdCredit_Key`, `Ord_OrdOriginal_Key`, `Ord_OrdRebill_Key`, `Ord_SplitNatAcct_Linked_Ord_Key`
- operational resource links: `Ord_Driver_Key`, `Ord_Vehicle_Key`, `Ord_WhOnly_Load_Key`

### Header-Level Index Facts

- `Orders_PK` enforces row identity on `Ord_Key`
- `Ord_No_UK` enforces unique business numbering on `Ord_No`
- no additional unique composite business key was found on the header

### Consequence

The schema proves two identities, not one:

- internal row identity: `Ord_Key`
- externally legible alternate identity: `Ord_No`

That is enough to identify rows. It is not enough to prove a safe end-to-end external upsert contract for the whole order domain.

## First-Level Relations

### Inbound Dependents of `dbo.Orders`

These tables carry foreign keys into `dbo.Orders` and therefore depend on an existing order header.

| Object | FK To Orders | Key / Grain | Operational meaning |
|---|---|---|---|
| `dbo.Charges` | `Chg_Next_Deliv_Ord_Key -> Ord_Key` | charge row keyed separately | AR/charge activity linked to next delivery order |
| `dbo.Charges_History` | `ChgHst_Next_Deliv_Ord_Key -> Ord_Key` | history row keyed separately | charge history linked to order lifecycle |
| `dbo.OD_EP_ThirdParty_PreAuth_Activity` | `ODEP_Ord_Key -> Ord_Key` | activity row | third-party preauth activity against order |
| `dbo.OD_Status_Log` | `OD_Status_Log_Ord_Key -> Ord_Key` | status log row | procedure-driven order status history |
| `dbo.Order_Attribute_Assignments` | `OrdAttAssign_Ord_Key -> Ord_Key` | assignment row | extensibility attributes attached to order |
| `dbo.Order_Audits` | `OrdAudit_Ord_Key -> Ord_Key` | audit row | vendor audit trail for order changes |
| `dbo.Order_Details_Fees` | `OrdFee_Ord_Key -> Ord_Key` | `OrdFee_Key` | fee line grain |
| `dbo.Order_Details_Fuel` | `OrdFuel_Ord_Key -> Ord_Key` | `OrdFuel_Key` | fuel line grain |
| `dbo.Order_Details_Fuel_Fees` | `OrdFuelFee_Ord_Key -> Ord_Key` | `OrdFuelFee_Key` | fee rows subordinate to fuel lines |
| `dbo.Order_Details_Fuel_Freight` | `OrdFuelFrt_Ord_Key -> Ord_Key` | `OrdFuelFrt_Key` plus freight uniqueness rule | freight line grain |
| `dbo.Order_Details_Taxes` | `OrdTax_Ord_Key -> Ord_Key` | `OrdTax_Key` | tax line grain |
| `dbo.Order_Details_Warehouse` | `OrdWh_Ord_Key -> Ord_Key` | `OrdWh_Key` | warehouse/non-fuel line grain |
| `dbo.Order_Payments` | `OrdPmt_Ord_Key -> Ord_Key` | `OrdPmt_Key` | payment grain |
| `dbo.Order_PreAuth` | `OrdPreAuth_Ord_Key -> Ord_Key` | `OrdPreAuth_Key` | authorization grain |
| `dbo.Order_ShipTo_Overrides` | `OrdShipTo_Ord_Key -> Ord_Key` | override row | shipping override attached to order |
| `dbo.Pulled_Orders` | `PulledOrd_Ord_Key -> Ord_Key` | pulled-order row | order pull/reallocation context |
| `dbo.Receipts` | `Rcpt_Reserved_Ord_Key -> Ord_Key` | receipt row | receipts reserved against order |
| `dbo.Receipts_History` | `RcptHst_Reserved_Ord_Key -> Ord_Key` | receipt history row | historical receipt linkage |
| `dbo.Updated_Orders` | `UpdOrd_Orig_Ord_Key -> Ord_Key` | updated-order row | transient or staged order-update artifact |

### Outbound Parents / Lookups Used by `dbo.Orders`

These are the objects `dbo.Orders` points to directly.

| Object | FK From Orders | Why it matters |
|---|---|---|
| `dbo.BB_Seasons` | `Ord_BBSeason_Key -> BBSeason_Key` | seasonal/budgeting context |
| `dbo.Customer_Contacts` | `Ord_CustCont_Key`, `Ord_Entered_By_CustCont_Key` | order contact and entered-by contact |
| `dbo.Customer_Locations` | `Ord_CustLoc_Key`, `Ord_SplitNatAcct_Linked_Ord_CustLocKey` | destination/customer-location anchor |
| `dbo.Customers` | `Ord_Cust_Key` | customer header |
| `dbo.Digital_Seal_Pay_Methods` | `Ord_DSPayMethod_Key` | digital seal payment configuration |
| `dbo.Drivers` | `Ord_Driver_Key` | assigned driver |
| `dbo.Order_Billing_Batches` | `Ord_OrdBillBatch_Key` | billing batch enrollment |
| `dbo.Order_Fuel_Loads` | `Ord_WhOnly_Load_Key` | load assignment |
| `dbo.Orders` | `Ord_OrdCredit_Key`, `Ord_OrdOriginal_Key`, `Ord_OrdRebill_Key`, `Ord_SplitNatAcct_Linked_Ord_Key` | self-linked lifecycle graph |
| `dbo.SalesPersons` | `Ord_SalesPerson_Key` | selling rep context |
| `dbo.Sites` | `Ord_Site_Key`, `Ord_Freight_DropShip_Site_Key` | delivery/site context |
| `dbo.Terms` | `Ord_Terms_Key` | payment/billing terms |
| `dbo.Vehicles` | `Ord_Vehicle_Key` | assigned vehicle |
| `dbo.Vendor_Invoices` | `Ord_Buyback_VndInv_Key` | buyback invoice linkage |
| `dbo.Vendor_Invoices_Pending` | `Ord_Buyback_VndInvPnd_Key` | pending vendor invoice linkage |

## Second-Level Relations

Second-level relations were derived only by following one more FK hop outward from the direct relations above. This is where the domain becomes broad.

### Second-Level Expansion Summary

| Via first-hop object | Second-level object count |
|---|---:|
| `dbo.Sites` | 235 |
| `dbo.Customers` | 101 |
| `dbo.Customer_Locations` | 70 |
| `dbo.Orders` | 33 |
| `dbo.Vendor_Invoices` | 25 |
| `dbo.Vendor_Invoices_Pending` | 20 |
| `dbo.Charges_History` | 18 |
| `dbo.Order_Details_Fuel` | 16 |
| `dbo.Order_Details_Warehouse` | 16 |
| `dbo.Terms` | 16 |
| `dbo.Customer_Contacts` | 14 |
| `dbo.Order_Fuel_Loads` | 12 |
| `dbo.Receipts` | 10 |
| `dbo.Receipts_History` | 10 |
| `dbo.Charges` | 9 |
| `dbo.Vehicles` | 8 |
| `dbo.BB_Seasons` | 7 |
| `dbo.Drivers` | 5 |
| `dbo.SalesPersons` | 5 |
| `dbo.Order_Details_Taxes` | 4 |
| `dbo.Order_Details_Fees` | 3 |
| `dbo.Updated_Orders` | 3 |
| `dbo.OD_Status_Log` | 2 |
| `dbo.Order_Details_Fuel_Fees` | 2 |
| `dbo.Digital_Seal_Pay_Methods` | 1 |
| `dbo.Order_Attribute_Assignments` | 1 |
| `dbo.Order_Billing_Batches` | 1 |
| `dbo.Order_Details_Fuel_Freight` | 1 |
| `dbo.Order_Payments` | 1 |
| `dbo.Pulled_Orders` | 1 |

### Complete Grouped Second-Level Inventory

This is the compact grouped enumeration of all second-level FK relations discovered.

- `dbo.Sites` (235): `dbo.AP_InvoiceExport_Details`; `dbo.Bank_Account_Import_Details`; `dbo.Bank_Reconciliation_Details`; `dbo.Bank_Reconciliation_Matching_Groups`; `dbo.Bank_Register`; `dbo.BI_Alert_Details`; `dbo.Bills_Of_Lading_Details`; `dbo.Bills_Of_Lading_Exceptions`; `dbo.BusEntity_Info`; `dbo.Card_Formats`; `dbo.Cards`; `dbo.Charge_Details`; `dbo.Charge_Details_History`; `dbo.Charge_Details_Pending`; `dbo.Charges`; `dbo.Charges_History`; `dbo.Charges_Pending`; `dbo.CI_Events`; `dbo.Competitor_Survey_Sites`; `dbo.Competitor_Surveys`; `dbo.Consigned_Settlement_Sites`; `dbo.Consigned_Settlement_Transfer_Details`; `dbo.Cost_Inventory`; `dbo.Count_Sheet_Sequences`; `dbo.CP_Billing_Details`; `dbo.CP_Price_Notices`; `dbo.CP_Transactions`; `dbo.Credit_Request_Pickups`; `dbo.Credit_Request_Totes`; `dbo.Customer_Contacts_CP_Sites`; `dbo.Customer_Fuel_Origins`; `dbo.Customer_Fuel_Prices`; `dbo.Customer_Loc_Warehouse_Authorizations`; `dbo.Customer_Locations`; `dbo.Customer_Per_Load_Prices`; `dbo.Customer_Pricing_CP_Rules`; `dbo.Customer_Pricing_Rules`; `dbo.Customer_Site_Authorizations`; `dbo.Customer_Warehouse_Authorizations`; `dbo.Customer_Warehouses`; `dbo.Customers`; `dbo.Daily_Adjustment_Headers`; `dbo.Daily_Invoice_Headers`; `dbo.Daily_Transfer_Headers`; `dbo.DataID_Values_NonDR`; `dbo.Dealer_Remit_Calc_Headers`; `dbo.Dealer_Remit_Site_Contracts`; `dbo.Dealer_Remit_Transaction_Details`; `dbo.Delivery_Routes`; `dbo.Distribution_Details`; `dbo.DRUpdate_Queue`; `dbo.Equipment_Dates`; `dbo.Equipment_Sites_Locations`; `dbo.Finance_Charges`; `dbo.Franchisee_Fuel_Delivery_Inventory`; `dbo.Fuel_Adjustments`; `dbo.Fuel_Auditor_Tank_Readings`; `dbo.Fuel_Contract_Destinations`; `dbo.Fuel_Costs_By_Dest_PerLoad`; `dbo.Fuel_Costs_By_Destination`; `dbo.Fuel_Costs_by_Destination_History`; `dbo.Fuel_Daily_Inventory`; `dbo.Fuel_Deliveries`; `dbo.Fuel_Delivery_Inventory`; `dbo.Fuel_Delivery_Products`; `dbo.Fuel_Delivery_Tank_Summary`; `dbo.Fuel_Formula_Details`; `dbo.Fuel_Formula_Identifiers`; `dbo.Fuel_Freight_Destinations`; `dbo.Fuel_Freight_Origins`; `dbo.Fuel_Layered_Cost_Assignments`; `dbo.Fuel_Meters`; `dbo.Fuel_Order_Destinations`; `dbo.Fuel_Order_Rules`; `dbo.Fuel_Origin_Overrides`; `dbo.Fuel_Pending_Inventory`; `dbo.Fuel_Prices_Header`; `dbo.Fuel_Product_Zones`; `dbo.Fuel_Reference_Index_Sites`; `dbo.Fuel_Sales`; `dbo.Fuel_Stick_Headers`; `dbo.GL_Export_Journal_Entries`; `dbo.Ideal_Costs`; `dbo.INCS_Batch_Sites`; `dbo.InterEntity_Billing_Sites`; `dbo.Inventory_Audit_Invalid_Items`; `dbo.Inventory_Audits`; `dbo.Item_Inquiry_Unknown_Items`; `dbo.Item_Inventory`; `dbo.Item_Rec_IDs`; `dbo.Item_Verifications`; `dbo.Lottery_Books`; `dbo.Lottery_Counts`; `dbo.Memo_Merch_Invc_Headers`; `dbo.Merch_Orders`; `dbo.Miscellaneous_Deposits`; `dbo.Notifications`; `dbo.OD_Fuel_Pricing_Origins`; `dbo.OD_Fuel_Pricing_Rules`; `dbo.OD_Fuel_Pricing_Strategies`; `dbo.OD_NonInv_Pricing_Rules`; `dbo.OD_NonInv_Pricing_Strategies`; `dbo.OD_Wh_Price_Exc_Batch_Details`; `dbo.OD_Wh_Price_Exceptions`; `dbo.OD_Wh_Pricing_Rules`; `dbo.OD_Wh_Pricing_Strategies`; `dbo.OD_Wh_Pricing_Warehouses`; `dbo.Order_Details_Fuel`; `dbo.Order_Details_Warehouse`; `dbo.Order_Details_Warehouse_Pending`; `dbo.Order_Dispatch_Areas`; `dbo.Order_Fuel_Load_Details`; `dbo.Order_Fuel_Loads`; `dbo.Orders_Pending`; `dbo.Paperwork_Batches`; `dbo.PB_Comp_Costs`; `dbo.PB_Comp_Prices`; `dbo.PB_Exceptions_Costs`; `dbo.PB_Exceptions_Invalid_UPCs`; `dbo.PB_Exceptions_Invalid_VINs`; `dbo.PB_Ordering_Exclusion_Details`; `dbo.Price_Change_Adjustment_Batch_Details`; `dbo.Product_Bins`; `dbo.Profit_Centers`; `dbo.Promotional_Campaign_Rebate_Amounts`; `dbo.Rebate_Accruals`; `dbo.Rebate_Billing_Site_Detail`; `dbo.Rebate_Billing_Tax_Details`; `dbo.Rebate_Provider_Items`; `dbo.Rebate_Recon_Adjustments`; `dbo.Rebate_Sites`; `dbo.Receipts`; `dbo.Receipts_History`; `dbo.Receipts_Pending`; `dbo.Receipts_Pending_Distributions`; `dbo.Recurring_Invoices`; `dbo.Recurring_Order_Destinations`; `dbo.Recurring_Order_Details_Warehouse`; `dbo.Recurring_Orders`; `dbo.Retail_Inventory`; `dbo.Retail_MixMatch_Price_Details`; `dbo.Retail_MixMatch_Prices`; `dbo.Retail_Price_Details_Pending`; `dbo.Retail_Prices`; `dbo.Retail_Prices_Boundaries_Item_Overrides`; `dbo.Retail_Prices_Entered`; `dbo.Retail_Prices_Resolved`; `dbo.Retail_Prices_Review`; `dbo.Retail_Prices_To_Replace`; `dbo.SA_Adjustments`; `dbo.SA_Adjustments_RSM`; `dbo.SA_Invoices`; `dbo.SA_Item_Verifications`; `dbo.SA_Lottery_Activates`; `dbo.SA_Lottery_Books`; `dbo.SA_Lottery_Counts`; `dbo.SA_Lottery_Receives`; `dbo.SA_Lottery_Returns`; `dbo.SA_Lottery_Vendings`; `dbo.SA_Merch_Orders`; `dbo.SA_Shelf_Label_Batches`; `dbo.SA_Transfers`; `dbo.Sales_Forecast_Event_Process`; `dbo.Sales_Forecast_Relationships`; `dbo.Seasonal_Adjustments`; `dbo.Site_Attribute_Assignments`; `dbo.Site_Authorities`; `dbo.Site_Calendar_General_Events`; `dbo.Site_Certificates`; `dbo.Site_Competitor_Sites`; `dbo.Site_Discount_Assignments`; `dbo.Site_DR_General`; `dbo.Site_DR_Info`; `dbo.Site_DR_Lookup_Dates`; `dbo.Site_DR_Lookup_Values`; `dbo.Site_DR_Transfers`; `dbo.Site_Fuel_Carriers`; `dbo.Site_Fuel_Origins`; `dbo.Site_Fuel_Replacement_Origins`; `dbo.Site_Fuel_Vendors`; `dbo.Site_Handheld_App_Profile_Dates`; `dbo.Site_Inventory_Profile_Dates`; `dbo.Site_Item_Activity_Dates`; `dbo.Site_Item_Attributes`; `dbo.Site_Item_Package_Checksums`; `dbo.Site_Item_Verification_Profile_Dates`; `dbo.Site_Labor_Scheduling_Rule_Dates`; `dbo.Site_Lottery_Profile_Dates`; `dbo.Site_MB_Profile_Dates`; `dbo.Site_Menu_Versions`; `dbo.Site_Operational_Item_List_Dates`; `dbo.Site_Order_Profile_Dates`; `dbo.Site_Plan_O_Gram_Dates`; `dbo.Site_PO_Sequences`; `dbo.Site_POS_Configurations`; `dbo.Site_Reminders`; `dbo.Site_Surveys`; `dbo.Site_Tank_Dates`; `dbo.Site_Tax_Exceptions`; `dbo.Site_Third_Party_Warehouse_Vendors`; `dbo.Site_Wh_Inventory_Bins`; `dbo.Sites`; `dbo.Tax_CardProc_Sales`; `dbo.Tax_Fuel_Deliveries`; `dbo.Tax_Fuel_Sale_Products`; `dbo.Tax_Fuel_Sales`; `dbo.Tax_Warehouse_Sale_Products`; `dbo.Terminal_Groups`; `dbo.Terminals`; `dbo.Trait_Assignments`; `dbo.Vehicles`; `dbo.Vendor_Costs`; `dbo.Vendor_CreditCard_Details`; `dbo.Vendor_Delivery_Schedule_Overrides`; `dbo.Vendor_Delivery_Site_Dates`; `dbo.Vendor_Delivery_Site_WeekDays`; `dbo.Vendor_Discounts`; `dbo.Vendor_Invc_1099_External`; `dbo.Vendor_Invc_Pending_DR_Details`; `dbo.Vendor_Invoices`; `dbo.Vendor_Order_Rules`; `dbo.Vendor_Site_Accounts`; `dbo.Vendor_Transactions`; `dbo.Vendors`; `dbo.Warehouse_Adjustments`; `dbo.Warehouse_Allowance_Destinations`; `dbo.Warehouse_Allowance_Origins`; `dbo.Warehouse_Count_Batches`; `dbo.Warehouse_Daily_Inventory`; `dbo.Warehouse_Group_Details`; `dbo.Warehouse_Inventory`; `dbo.Warehouse_Purchase_Details`; `dbo.Warehouse_Repack_Batches`; `dbo.Warehouse_Repackaging_Rules`; `dbo.Wholesale_Prices`
- `dbo.Customers` (101): `dbo.AR_EP_ThirdParty_Customer_Attributes`; `dbo.AR_Web_Profile_Legal_Terms`; `dbo.AR_Web_Settings`; `dbo.AR99_Customer_Payee_Details`; `dbo.Bank_Accounts`; `dbo.Bank_Transaction_Details`; `dbo.Billing_Groups`; `dbo.BusEntity_Info`; `dbo.Card_Department_Fields`; `dbo.Card_Departments`; `dbo.Card_Formats`; `dbo.Cards`; `dbo.Charges`; `dbo.Charges_History`; `dbo.Charges_Pending`; `dbo.CI_Events`; `dbo.Consigned_Settlement_Sites`; `dbo.CP_Billing_Batches`; `dbo.CP_Price_Notice_Rules`; `dbo.CP_Price_Notices`; `dbo.CP_Transactions`; `dbo.Credit_Managers`; `dbo.Credit_Ratings`; `dbo.Customer_1099K`; `dbo.Customer_Activity`; `dbo.Customer_Attribute_Assignments`; `dbo.Customer_Authorities`; `dbo.Customer_Authorized_Users`; `dbo.Customer_Balances`; `dbo.Customer_Card_Format_Settings`; `dbo.Customer_Card_Templates`; `dbo.Customer_Certificates`; `dbo.Customer_Classes`; `dbo.Customer_Comments`; `dbo.Customer_Contacts`; `dbo.Customer_Discount_Rules`; `dbo.Customer_Doc_Delivery`; `dbo.Customer_Fuel_Contracts`; `dbo.Customer_Locations`; `dbo.Customer_Notes`; `dbo.Customer_Payment_Accounts`; `dbo.Customer_PO_Numbers`; `dbo.Customer_Pricing_CP_Rules`; `dbo.Customer_Pricing_Group_Overrides`; `dbo.Customer_Pricing_Rules`; `dbo.Customer_Reporting_Groups`; `dbo.Customer_Sales_Info`; `dbo.Customer_Site_Authorizations`; `dbo.Customer_Tax_Exceptions`; `dbo.Customer_Terms_Products`; `dbo.Customer_Types`; `dbo.Customer_Warehouse_Authorizations`; `dbo.Customer_Warehouse_Group_Authorizations`; `dbo.Customer_Warehouses`; `dbo.Customer_Web_Audits`; `dbo.Customers`; `dbo.Daily_AR`; `dbo.DBAs`; `dbo.Digital_Seal_Pay_Methods`; `dbo.EFT_Groups`; `dbo.Finance_Charges`; `dbo.Fuel_Reference_Index_Customers`; `dbo.Message_Groups`; `dbo.OD_Fuel_Discount_Strategies`; `dbo.OD_Fuel_Pricing_Strategies`; `dbo.OD_NonInv_Discount_Strategies`; `dbo.OD_NonInv_Pricing_Strategies`; `dbo.OD_Status_Log`; `dbo.OD_Wh_Discount_Strategies`; `dbo.OD_Wh_Price_Exc_Batch_Details`; `dbo.OD_Wh_Price_Exceptions`; `dbo.OD_Wh_Pricing_Strategies`; `dbo.Payment_Cards`; `dbo.Payment_Transactions`; `dbo.PN_Legal_Notice`; `dbo.Rebate_Customers`; `dbo.Rebates`; `dbo.Receipt_Batches`; `dbo.Receipt_Paymaster_Details`; `dbo.Receipts`; `dbo.Receipts_History`; `dbo.Receipts_Pend_EFT_Exceptions`; `dbo.Receipts_Pending`; `dbo.Receipts_Pending_Remittance`; `dbo.Receipts_Remittance`; `dbo.Recurring_Order_Destinations`; `dbo.Site_Inventory_Profile_Dates`; `dbo.Site_Tank_Dates`; `dbo.Sites`; `dbo.Statement_Batch_Details`; `dbo.Tax_CardProc_Sales`; `dbo.Tax_Fuel_Sales`; `dbo.Tax_Warehouse_Sales`; `dbo.Terms`; `dbo.Transaction_Codes`; `dbo.Translation_Table_Header`; `dbo.TX_1099_Merchant_Category`; `dbo.Vendor_CreditCard_Details`; `dbo.Vendors`; `dbo.Warehouse_Allowance_Destinations`; `dbo.Warehouse_Price_Notice_Rules`
- `dbo.Customer_Locations` (70): `dbo.BB_Season_CustLocs`; `dbo.Billing_Groups`; `dbo.Bills_Of_Lading_Details`; `dbo.Bills_Of_Lading_Exceptions`; `dbo.Cards`; `dbo.Charges`; `dbo.Charges_History`; `dbo.Charges_Pending`; `dbo.CI_Events`; `dbo.Customer_Authorities`; `dbo.Customer_Certificates`; `dbo.Customer_Discount_Rules`; `dbo.Customer_Fuel_Carriers`; `dbo.Customer_Fuel_Origins`; `dbo.Customer_Fuel_Prices`; `dbo.Customer_Fuel_Tanks`; `dbo.Customer_Fuel_Vendors`; `dbo.Customer_Loc_Attribute_Assignments`; `dbo.Customer_Loc_National_Accounts`; `dbo.Customer_Loc_Warehouse_Authorizations`; `dbo.Customer_Loc_Warehouse_Grp_Authorizations`; `dbo.Customer_Location_Calendars`; `dbo.Customer_Per_Load_Prices`; `dbo.Customer_PO_Numbers`; `dbo.Customer_Pricing_Group_Overrides`; `dbo.Customer_Pricing_Rules`; `dbo.Customer_Sales_Info`; `dbo.Customer_Tax_Exceptions`; `dbo.Customer_Trait_Assignments`; `dbo.Customer_Warehouses`; `dbo.Customers`; `dbo.Degree_Day_Regions`; `dbo.Delivery_Routes`; `dbo.Equipment_Dates`; `dbo.Equipment_Sites_Locations`; `dbo.Fuel_Contract_Destinations`; `dbo.Fuel_Costs_By_Dest_PerLoad`; `dbo.Fuel_Costs_By_Destination`; `dbo.Fuel_Costsby_Destination_History`; `dbo.Fuel_Deliveries`; `dbo.Fuel_Delivery_Products`; `dbo.Fuel_Freight_Destinations`; `dbo.Fuel_Order_Destinations`; `dbo.Fuel_Product_Zones`; `dbo.Fuel_Reference_Index_Customer_Locations`; `dbo.Fuel_Sales`; `dbo.Message_Groups`; `dbo.OD_Fuel_Discount_Locations`; `dbo.OD_Fuel_Pricing_Locations`; `dbo.OD_NonInv_Discount_Locations`; `dbo.OD_NonInv_Pricing_Locations`; `dbo.OD_Status_Log`; `dbo.OD_Wh_Discount_Locations`; `dbo.OD_Wh_Price_Exc_Batch_Details`; `dbo.OD_Wh_Price_Exceptions`; `dbo.OD_Wh_Pricing_Locations`; `dbo.Order_Dispatch_Areas`; `dbo.Order_Fuel_Loads`; `dbo.Price_Notice_Rules`; `dbo.Receipts_Pending_Remittance`; `dbo.Receipts_Remittance`; `dbo.Receipts_Remittance_History`; `dbo.Recurring_Order_Destinations`; `dbo.Site_Tank_Dates`; `dbo.Sites`; `dbo.Tank_Readings`; `dbo.Tax_Fuel_Deliveries`; `dbo.Tax_Fuel_Sales`; `dbo.Tax_Warehouse_Sales`; `dbo.Warehouse_Allowance_Destinations`
- `dbo.Orders` (33): `dbo.BB_Seasons`; `dbo.Charges`; `dbo.Charges_History`; `dbo.Customer_Contacts`; `dbo.Customer_Locations`; `dbo.Customers`; `dbo.Digital_Seal_Pay_Methods`; `dbo.Drivers`; `dbo.OD_EP_ThirdParty_PreAuth_Activity`; `dbo.OD_Status_Log`; `dbo.Order_Attribute_Assignments`; `dbo.Order_Audits`; `dbo.Order_Billing_Batches`; `dbo.Order_Details_Fees`; `dbo.Order_Details_Fuel`; `dbo.Order_Details_Fuel_Fees`; `dbo.Order_Details_Fuel_Freight`; `dbo.Order_Details_Taxes`; `dbo.Order_Details_Warehouse`; `dbo.Order_Fuel_Loads`; `dbo.Order_Payments`; `dbo.Order_PreAuth`; `dbo.Order_ShipTo_Overrides`; `dbo.Pulled_Orders`; `dbo.Receipts`; `dbo.Receipts_History`; `dbo.SalesPersons`; `dbo.Sites`; `dbo.Terms`; `dbo.Updated_Orders`; `dbo.Vehicles`; `dbo.Vendor_Invoices`; `dbo.Vendor_Invoices_Pending`
- `dbo.Vendor_Invoices` (25): `dbo.AP_InvoiceExport_Details`; `dbo.AP_Payment_Request_Details`; `dbo.AP_Terms`; `dbo.BusEntity_Info`; `dbo.Consigned_Settlement_Invoice_Details`; `dbo.Fuel_Delivery_Freight`; `dbo.Fuel_Delivery_Products`; `dbo.Fuel_Delivery_Taxes`; `dbo.InterEntity_Billing_Sites`; `dbo.Manual_Check_Details`; `dbo.Sites`; `dbo.Tax_TaxType_Codes`; `dbo.Tax_TaxType_SubCategory_Codes`; `dbo.Vendor_Invc_1099`; `dbo.Vendor_Invc_Dist_Posted`; `dbo.Vendor_Invc_Distribution`; `dbo.Vendor_Invc_Job_Codes`; `dbo.Vendor_Invc_Taxes`; `dbo.Vendor_Invc_Utility_Details`; `dbo.Vendor_Invoice_Posted_Batches`; `dbo.Vendor_Payment_Details`; `dbo.Vendor_Surveys`; `dbo.Vendor_TransRecon_Books`; `dbo.Vendors`; `dbo.Warehouse_Purchases`
- `dbo.Vendor_Invoices_Pending` (20): `dbo.AP_Terms`; `dbo.BusEntity_Info`; `dbo.FI_Invoice_Attribute_Assignments`; `dbo.Fuel_Delivery_Freight`; `dbo.Fuel_Delivery_Products`; `dbo.Fuel_Delivery_Taxes`; `dbo.Incidental_Costs`; `dbo.Product_Tax_Groups`; `dbo.Tax_TaxType_Codes`; `dbo.Tax_TaxType_SubCategory_Codes`; `dbo.Vendor_Invc_1099`; `dbo.Vendor_Invc_Distribution`; `dbo.Vendor_Invc_Job_Codes`; `dbo.Vendor_Invc_Pending_Details`; `dbo.Vendor_Invc_Pending_DR_Details`; `dbo.Vendor_Invc_Pending_Terms`; `dbo.Vendor_Invc_Taxes`; `dbo.Vendor_Invc_Utility_Details`; `dbo.Vendor_Invoice_Batches`; `dbo.Vendors`
- `dbo.Charges_History` (18): `dbo.AR_CC_Activity_Batches`; `dbo.BB_Groups`; `dbo.BusEntity_Info`; `dbo.Charge_Batches`; `dbo.Charge_Details_History`; `dbo.CP_Billing_Details`; `dbo.CP_Trans_Taxes`; `dbo.Customer_Locations`; `dbo.Customer_Scheduled_Payment_Details`; `dbo.Customers`; `dbo.Daily_AR`; `dbo.Finance_Charge_Details`; `dbo.Order_Details_Taxes`; `dbo.Receipts_Applied_History`; `dbo.Receipts_Pending`; `dbo.Sites`; `dbo.Statement_Batch_Details`; `dbo.Terms`
- `dbo.Order_Details_Fuel` (16): `dbo.Customer_Fuel_Contract_Details`; `dbo.Customer_Fuel_Contracts`; `dbo.Customer_Pricing_Rules`; `dbo.Equipment`; `dbo.OD_Fuel_Discount_Rules`; `dbo.OD_Fuel_Pricing_Rules`; `dbo.Order_Details_Fuel_Allowances`; `dbo.Order_Details_Fuel_Attribute_Assignments`; `dbo.Order_Details_Fuel_Fees`; `dbo.Order_Fuel_Load_Details`; `dbo.Product_Blends`; `dbo.Products`; `dbo.Sites`; `dbo.Terminals`; `dbo.Transaction_Codes`; `dbo.Vendors`
- `dbo.Order_Details_Warehouse` (16): `dbo.Customer_Pricing_Rules`; `dbo.Equipment`; `dbo.OD_NonInv_Discount_Rules`; `dbo.OD_NonInv_Pricing_Rules`; `dbo.OD_Wh_Discount_Rules`; `dbo.OD_Wh_Price_Exceptions`; `dbo.OD_Wh_Pricing_Rules`; `dbo.Order_Details_Fees`; `dbo.Order_Details_Warehouse_Attribute_Assignments`; `dbo.Order_Details_WI_Allowances`; `dbo.Order_Picking_Batches`; `dbo.Product_Packages`; `dbo.Products`; `dbo.Sites`; `dbo.Transaction_Codes`; `dbo.Warehouse_Repack_Batches`
- `dbo.Terms` (16): `dbo.BB_Season_Configs`; `dbo.Business_Calendars`; `dbo.Card_Formats`; `dbo.Charges`; `dbo.Charges_History`; `dbo.Charges_Pending`; `dbo.CP_Billing_Details`; `dbo.Customer_Fuel_Contract_Details`; `dbo.Customer_Sales_Info`; `dbo.Customer_Terms_Products`; `dbo.Customers`; `dbo.Finance_Charges`; `dbo.Order_Details_Taxes`; `dbo.Orders_Pending`; `dbo.Recurring_Orders`; `dbo.Transaction_Codes`
- `dbo.Customer_Contacts` (14): `dbo.AR_Web_Settings`; `dbo.CP_Price_Notices`; `dbo.Customer_Comments`; `dbo.Customer_Contact_Functions`; `dbo.Customer_Contact_Web_Alerts`; `dbo.Customer_Contact_Web_Functions`; `dbo.Customer_Contacts_CP_Products`; `dbo.Customer_Contacts_CP_Sites`; `dbo.Customer_Doc_Delivery_CustConts`; `dbo.Customer_Web_Portal_Tracking`; `dbo.Customers`; `dbo.Payment_Card_Auth_Users`; `dbo.Payment_Cards`; `dbo.Payment_Transactions`
- `dbo.Order_Fuel_Loads` (12): `dbo.Customer_Locations`; `dbo.Drivers`; `dbo.Order_Fuel_Load_Details`; `dbo.Order_Fuel_Load_Freight`; `dbo.Order_Fuel_Load_Taxes`; `dbo.Pulled_Loads`; `dbo.Sites`; `dbo.Tax_Authorities`; `dbo.Terminals`; `dbo.Transport_Mode`; `dbo.Vehicles`; `dbo.Vendors`
- `dbo.Receipts` (10): `dbo.BB_Seasons`; `dbo.BusEntity_Info`; `dbo.Customers`; `dbo.Receipt_Paymaster_Details`; `dbo.Receipts_Applied`; `dbo.Receipts_Pending`; `dbo.Receipts_Remittance`; `dbo.Receipts_Remittance_History`; `dbo.Sites`; `dbo.Transaction_Codes`
- `dbo.Receipts_History` (10): `dbo.AR_CC_Activity_Batches`; `dbo.BB_Seasons`; `dbo.BusEntity_Info`; `dbo.Customer_Scheduled_Payment_Details`; `dbo.Customers`; `dbo.Receipts_Applied_History`; `dbo.Receipts_Pending`; `dbo.Sites`; `dbo.Statement_Batch_Details`; `dbo.Transaction_Codes`
- `dbo.Charges` (9): `dbo.BB_Groups`; `dbo.BusEntity_Info`; `dbo.Charge_Batches`; `dbo.Charge_Details`; `dbo.Customer_Locations`; `dbo.Customers`; `dbo.Receipts_Applied`; `dbo.Sites`; `dbo.Terms`
- `dbo.Vehicles` (8): `dbo.CI_Events`; `dbo.OD_Equipment_Types`; `dbo.OD_Vehicle_Attribute_Assignments`; `dbo.Order_Fuel_Loads`; `dbo.Orders_Pending`; `dbo.Recurring_Orders`; `dbo.Sites`; `dbo.Vendors`
- `dbo.BB_Seasons` (7): `dbo.BB_Season_Configs`; `dbo.BB_Season_CustLocs`; `dbo.Charge_Batches`; `dbo.Orders_Pending`; `dbo.Receipts`; `dbo.Receipts_History`; `dbo.Receipts_Pending`
- `dbo.Drivers` (5): `dbo.OD_Driver_Attribute_Assignments`; `dbo.Order_Fuel_Loads`; `dbo.Orders_Pending`; `dbo.Recurring_Orders`; `dbo.Vendors`
- `dbo.SalesPersons` (5): `dbo.Customer_Fuel_Contract_Details`; `dbo.Customer_Sales_Info`; `dbo.OD_SalesPerson_Attribute_Assignments`; `dbo.Orders_Pending`; `dbo.Recurring_Orders`
- `dbo.Order_Details_Taxes` (4): `dbo.Charges_History`; `dbo.Tax_Exceptions`; `dbo.Taxes`; `dbo.Terms`
- `dbo.Order_Details_Fees` (3): `dbo.Common_Conv_Units`; `dbo.Order_Details_Warehouse`; `dbo.Products`
- `dbo.Updated_Orders` (3): `dbo.Updated_Order_Details_Fuel`; `dbo.Updated_Order_Details_Warehouse`; `dbo.Updated_Order_Fuel_Loads`
- `dbo.OD_Status_Log` (2): `dbo.Customer_Locations`; `dbo.Customers`
- `dbo.Order_Details_Fuel_Fees` (2): `dbo.Order_Details_Fuel`; `dbo.Products`
- `dbo.Digital_Seal_Pay_Methods` (1): `dbo.Customers`
- `dbo.Order_Attribute_Assignments` (1): `dbo.Attributes`
- `dbo.Order_Billing_Batches` (1): `dbo.MOI_Batches`
- `dbo.Order_Details_Fuel_Freight` (1): `dbo.Fuel_Freight_Rules`
- `dbo.Order_Payments` (1): `dbo.Transaction_Codes`
- `dbo.Pulled_Orders` (1): `dbo.Web_Service_Profiles_OD`

## Stored Procedure Surface

### What The Metadata Shows

- procedures with dependency metadata referencing `dbo.Orders`: 509
- dominant family by prefix: `OD_*` with 347 procedures
- next largest consumers: `FI_*` 47, `WI_*` 30, `AR_*` 26, `TX_*` 21

This distribution is important: `dbo.Orders` is not just an order-entry table. It is a cross-functional transaction anchor consumed by billing, finance, warehouse, AR, and tax logic.

### Highest-Connectivity Procedures

These are the highest-signal procedures by referenced-object breadth in the dependency graph:

- `dbo.OD_GetOrder_SP` - 75 referenced objects
- `dbo.OD_OrderImportValidate_SP` - 67
- `dbo.OD_SetOrderStatus_RelForBilling_SP` - 60
- `dbo.OD_WS_GetFuelOrders_SP` - 60
- `dbo.OD_PostSiteOrders_SP` - 58
- `dbo.OD_Export_SP` - 57
- `dbo.OD_SetOrderStatus_Dispatched_SP` - 49
- `dbo.OD_SetOrderStatus_Open_SP` - 48
- `dbo.OD_WS_GetWarehouseOrders_SP` - 48
- `dbo.OD_PackSlip_SP` - 47

### Architecture-Stage Grouping

The stage grouping below is evidence-based from naming, parameter shape, and body snippets. It is still labeled as an architectural interpretation, not a vendor-published taxonomy.

#### 1. Entry / UI Context / Retrieval

Likely front-end or operator entry points because they accept direct filter fields, context parameters, or row identifiers rather than batch GUIDs.

- `dbo.OD_GetOrder_SP`
  - evidence: parameters `@Ord_Key`, `@GetContext`, `@UserKey`
  - role: retrieve a single order with broad related context
- `dbo.OD_ListOrders_SP`
  - evidence: 104 filter parameters; search/list semantics
  - role: order worklist/query surface
- `dbo.OD_ContextOrderEntryDest_SP`
  - evidence: destination/date context parameters; order-entry destination lookup
  - role: populate order-entry defaults and context
- `dbo.OD_WS_GetFuelOrders_SP`
  - evidence: XML request payload plus `WebPartnerKey`
  - role: service/API retrieval for fuel orders
- `dbo.OD_WS_GetWarehouseOrders_SP`
  - evidence: XML request payload plus `WebPartnerKey`
  - role: service/API retrieval for warehouse orders

#### 2. Create / Save / Copy / Import

These are the strongest candidate write entry points into the header table.

- `dbo.OD_CreateOrder_SP`
  - evidence: 19 creation-oriented parameters including destination, type, schedule, contact, notes
  - snippet shows creation workflow scaffold and order-type handling
- `dbo.OD_SaveOrder_SP`
  - evidence: 91 header-field parameters; snippet contains `INSERT INTO Orders (...)`
  - role: full header persistence surface
- `dbo.OD_CopyOrder_Orders_SP`
  - evidence: snippet contains `INSERT INTO Orders (...)`
  - role: clone/move/copy existing orders into new headers
- `dbo.OD_CreateBackOrder_SP`
  - evidence: accepts `@OrigOrdKey`; snippet checks for duplicate `Ord_No` derived from original order
  - role: backorder creation based on existing header
- `dbo.OD_OrdImpPost_WriteOrders_SP`
  - evidence: batch/import parameters; snippet contains `INSERT INTO Orders (...)`
  - role: import-post write surface
- `dbo.OD_WS_ImportOrders_SP`
  - evidence: XML import payload, target status, web partner key
  - role: service/API import surface

#### 3. Calculation / Enrichment / Normalization

These procedures depend on process GUIDs and mutate calculated state rather than acting like simple UI saves.

- `dbo.OD_CalcOrder_SP`
  - evidence: 21 parameters including override resets, dispatching, billing-release flags, process GUID
  - role: central order calculation orchestration
- `dbo.OD_CalcOrder_UpdateOrders_SP`
  - evidence: process GUID and concurrency-oriented snippet
  - role: write-back after calculation
- `dbo.OD_CalcOrder_CreateFuelLoads_SP`
  - evidence: process GUID and load GUID
  - role: load creation after calculation

#### 4. Status Transition / Fulfillment / Dispatch

These move orders between operational states using GUID worksets.

- `dbo.OD_SetOrderStatus_Open_SP`
- `dbo.OD_SetOrderStatus_Dispatched_SP`
- `dbo.OD_SetOrderStatus_Delivered_SP`
- `dbo.OD_PostSiteOrders_SP`

Evidence:

- batch/work GUID parameters instead of row-form parameters
- snippets show `OrdersWorkTable`, load lookups, and downstream operational calls
- delivered/dispatched/open semantics are explicit in procedure names

#### 5. Billing / Invoice Generation / Credit-Rebill

These procedures turn orders into financial artifacts.

- `dbo.OD_Billing_PostMOIBatch_SP`
  - evidence: batch key, copies, print flags, user key
- `dbo.OD_GenerateInvoicesFromOrders_GetFuelDetails_SP`
- `dbo.OD_GenerateInvoicesFromOrders_GetNonFuelDetails_SP`
- `dbo.OD_CreditAndRebillOrders_SP`

Evidence:

- batch-oriented parameterization
- references to invoice generation, MOI batch posting, rebill workflow

#### 6. Downstream Consumers Outside Core OD Family

These are not likely entry points. They are downstream consumers of the order graph.

- `FI_*`: finance posting, BOL confirmation, deliveries, cost-of-sales
- `WI_*`: warehouse and inventory consumers
- `AR_*`: receipt, statement, customer inquiry, aging surfaces
- `TX_*`: tax recalculation and exception handling

### UI / Service Entry Points vs Batch / System Procedures

#### Likely front-end or interactive entry points

- `dbo.OD_GetOrder_SP`
- `dbo.OD_ListOrders_SP`
- `dbo.OD_ContextOrderEntryDest_SP`
- `dbo.OD_CreateOrder_SP`
- `dbo.OD_SaveOrder_SP`

Reasoning:

- row-oriented or filter-oriented parameter lists
- context-oriented names
- no scheduler or batch envelope in signature

#### Likely service/API entry points

- `dbo.OD_WS_GetFuelOrders_SP`
- `dbo.OD_WS_GetWarehouseOrders_SP`
- `dbo.OD_WS_ImportOrders_SP`

Reasoning:

- `WS` prefix
- XML payload parameters
- `WebPartnerKey` parameters

#### Likely batch/system/integration procedures

- `dbo.OD_OrdImpPost_WriteOrders_SP`
- `dbo.OD_CalcOrder_SP`
- `dbo.OD_CalcOrder_UpdateOrders_SP`
- `dbo.OD_CalcOrder_CreateFuelLoads_SP`
- `dbo.OD_SetOrderStatus_Open_SP`
- `dbo.OD_SetOrderStatus_Dispatched_SP`
- `dbo.OD_SetOrderStatus_Delivered_SP`
- `dbo.OD_PostSiteOrders_SP`
- `dbo.OD_Billing_PostMOIBatch_SP`
- `dbo.OD_GenerateInvoicesFromOrders_GetFuelDetails_SP`
- `dbo.OD_GenerateInvoicesFromOrders_GetNonFuelDetails_SP`
- most `FI_*`, `WI_*`, `AR_*`, and `TX_*` consumers

Reasoning:

- process GUIDs, batch keys, import envelopes, billing batches, and status transitions

## Direct Read / Write Adjacency Findings

*(No additional adjacency findings beyond what is captured in the procedure surface and FK inventory above.)*

---

## Import Procedure Chain (Proved April 2026)

Evidence source: Live procedure body reads via `OBJECT_DEFINITION()` on PDI-SQL-01 using `COLEMANOIL\jason.vassar` Windows auth. All procedure contents confirmed directly — these are not inferences from metadata.

### Entry Surface

**`OD_WS_ImportOrders_SP`** — The canonical import entry point.

Parameters: `@OrderXML ntext`, `@TargetOrderStatus int`, `@WebPartnerKey int`, `@Action int`

Behavior:
1. Parses XML via `OPENXML` into `tempdb..Import_Orders` work table
2. XML hierarchy: `PDIFuelOrders > PDIFuelOrder > FuelDetail > LoadDetail`
3. OPENXML XPath levels:
   - Header fields: `../../` (grandparent)
   - Detail fields: `../` (parent)
   - Load fields: `./` (current node)
4. Calls downstream procs in sequence (see chain below)

### Verified Import Chain (Call Order)

| Step | Procedure | Purpose |
|------|-----------|---------|
| 1 | `OD_WS_ImportOrders_SP` | XML parse → `tempdb..Import_Orders` |
| 2 | `OD_OrdImp_LookupKeys_SP` | ID-to-Key resolution for all reference fields |
| 3 | `OD_OrderImportValidate_SP` | Validation at `@Action` / `@TargetOrderStatus` level |
| 4 | `OD_OrdImpPost_WriteOrders_SP` | `INSERT INTO Orders (...)` — header materialization |
| 5 | `OD_OrdImpPost_WriteLoads_SP` | `INSERT INTO Order_Fuel_Load_Details (...)` — load materialization |
| 6 | `OD_CalcOrder_SP` | Pricing, freight, tax, fee calculation |
| 7 | `OD_SetOrderStatus_*` | Status promotion to `@TargetOrderStatus` |

### Key Resolution Logic (`OD_OrdImp_LookupKeys_SP`)

Two distinct contract lanes are resolved during key lookup:

**Pricing Lane (CustomerFuelContractID):**
```
XML field: CustomerFuelContractID (at ../FuelDetail level)
  → ImpOrd_CustFuelCont_ID
  → JOIN Customer_Fuel_Contracts ON CustFuelCont_ID = ImpOrd_CustFuelCont_ID
  → ImpOrd_CustFuelCont_Key
  → Effective detail: Customer_Fuel_Contract_Details
      WHERE CustFuelContDtl_Eff_Datetime <= LiftDate AND (not expired) AND Status = 0
  → ImpOrd_CustFuelContDtl_Key
  → Write target: Order_Details_Fuel.OrdFuel_CustFuelCont_Key + OrdFuel_CustFuelContDtl_Key
```

**Cost Lane (ContractID):**
```
XML field: ContractID (at ./LoadDetail level)
  → ImpOrd_FuelCont_ID
  → JOIN Fuel_Contracts ON FuelCont_ID = ImpOrd_FuelCont_ID
      WHERE ImpOrd_Vend_Key IS NOT NULL AND ImpOrd_Record_Type = 'F'
  → ImpOrd_FuelCont_Key
  → Effective detail: Fuel_Contract_Details
      WHERE FuelContDtl_Eff_Datetime <= LiftDate AND (not expired) AND Status = 0
  → ImpOrd_FuelContDtl_Key
  → Write target: Order_Fuel_Load_Details.LoadDtl_FuelCont_Key + LoadDtl_FuelContDtl_Key
```

### Validation Highlights (`OD_OrderImportValidate_SP`)

67 referenced objects. Key validations for fuel orders (`@TargetOrderStatus = 2`):

| Field | Validation | Proc Evidence |
|-------|-----------|---------------|
| `DestinationType` | Must be 0 or 1 | Hard check (line ~684) |
| `CustomerID` | Must resolve for Dest_Type=1 | Hard check (line ~789) |
| `CustomerLocationID` | Must resolve for Dest_Type=1 | Hard check (line ~789) |
| `OrderedProductID` | Must resolve in `dbo.Products` | Hard check (line ~2133) |
| `OrderedQuantity` | Must be non-zero for fuel records | Hard check (line ~3001) |
| `LiftGrossQuantity` | Must be non-zero when `@OrderPromotionStatus > 1 AND @CalledFromWebService = 1` | Line ~3023 |
| `LiftNetQuantity` | Same gate | Line ~3048 |

### tempdb Work Pattern

The import chain uses `tempdb..Import_Orders` as the single shared work table. This is not a permanent table — it is created per-batch with a `@BatchKey` discriminator. The `Orders_BatchKey` column partitions concurrent imports.

Work table columns map 1:1 from OPENXML output. All `ImpOrd_*` prefixed columns carry either raw XML values or resolved keys.

---

## Import Infrastructure (SIIMPS / ODIMP)

Evidence source: `SI_Import_Types`, `SI_Import_Mapping_Profiles`, `SI_Import_Mappings` tables on PDI-SQL-01.

### Import Types Relevant to Orders Domain

| Type Key | Type | Description | .NET Class |
|----------|------|-------------|------------|
| 5 | 5 | ImptODOrders | `prodfuelcmd.ImptODOrders` |
| 69 | 69 | OD Fuel Pricing Contract Import | `prodfuelcmd.ImptODFuelPricingContracts` |

### Active Order Import Profiles (Type 5)

| Profile Key | Description | Header Row | AllowNew | AllowReplace |
|-------------|-------------|------------|----------|--------------|
| **68** | Order Import (enhanced single line fuel) | No | Yes | No |
| 69 | Order Import (hdr and dtl) | No | Yes | No |
| 70 | Order Import (single line fuel) | No | Yes | No |
| 71 | Order Import (single line non-inventory) | No | Yes | No |
| 72 | Order Import (single line warehouse) | No | Yes | No |
| 207–266 | 13 user-created `zzz*` profiles | Mixed | Yes | Mixed |

### Profile 68 — The `_Orders_Upload` Target Profile

- Field delimiter: `,` (comma)
- Text delimiter: `"` (double-quote)
- First row headings: **No**
- Date format: `MM/dd/yyyy HH:mm` (DateOrderType = 0)
- Allow new: Yes
- Allow replace: No
- Record type: `F` = Fuel Order Detail (38 columns)

### ODFPCI Import Profile (Type 69)

| Profile Key | Description | Header Row | AllowNew | AllowReplace |
|-------------|-------------|------------|----------|--------------|
| **64** | OD Fuel Pricing Contract Import | No | Yes | Yes |

Record types: CFC, CFCDTL, CFCVOL, FPRULE, FPPROD, FPPRODGRP, FPLOC, FPOVEN, FPOTRML, FPOFC, FPOBP (11 record types).

### WebPartner Configuration

| Key | ID | Service Account | Cost_Option | Price_Option | CustFuelContractImportOption |
|-----|-----|----------------|-------------|--------------|------------------------------|
| 1 | Chevron | `ColemanOil\svc-Quser` | 0 (do not override) | 0 (do not override) | Not 0 (enabled) |

`svc-Quser` is the PDI application-tier Windows domain service account. It connects via integrated auth from the PDI application server. No SQL login exists for this account — it is not directly callable from SQL clients.

---

## Customer Fuel Contract Domain (Proved April 2026)

Evidence source: Direct table reads and procedure body reads on PDI-SQL-01. All structure confirmed from live schema, not documentation.

### Hierarchy (4 levels)

```
Customer_Fuel_Contracts                       ← header, binds to Cust_Key or CustContGrp_Key
  └─ Customer_Fuel_Contract_Details           ← effective date period, status, expiration
       └─ OD_Fuel_Pricing_Rules               ← pricing logic (46+ columns)
            ├─ OD_Fuel_Pricing_Products       ← product scope
            ├─ OD_Fuel_Pricing_Locations      ← customer location scope (optional)
            └─ OD_Fuel_Pricing_Origins        ← vendor/terminal/contract scope (optional)
```

### Key Tables

| Table | PK | Parent FK | Live Row Count |
|-------|-----|-----------|---------------|
| `Customer_Fuel_Contracts` | `CustFuelCont_Key` | `CustFuelCont_Cust_Key` → Customers | 11 |
| `Customer_Fuel_Contract_Details` | `CustFuelContDtl_Key` | `CustFuelContDtl_CustFuelCont_Key` | 11 |
| `OD_Fuel_Pricing_Rules` | `ODFuelPrcRule_Key` | `ODFuelPrcRule_CustFuelContDtl_Key` | 11 |
| `OD_Fuel_Pricing_Products` | `ODFuelPrcProd_Key` | `ODFuelPrcProd_ODFuelPrcRule_Key` | 20 |
| `OD_Fuel_Pricing_Locations` | `ODFuelPrcLoc_Key` | `ODFuelPrcLoc_ODFuelPrcRule_Key` | 9 |
| `OD_Fuel_Pricing_Origins` | `ODFuelPrcOrigin_Key` | `ODFuelPrcOrigin_ODFuelPrcRule_Key` | 0 |
| `Customer_Contract_Groups` | `CustContGrp_Key` | — | 2 |
| `Customer_Fuel_Contract_Batches` | — | — | 0 |

### Contract Types

| CustFuelCont_Type | Meaning | Binding | Live Count |
|-------------------|---------|---------|-----------|
| 0 | Direct customer | `CustFuelCont_Cust_Key` = specific customer | 10 |
| 1 | Contract group | `CustFuelCont_CustContGrp_Key` = group key, no Cust_Key | 1 |

### Contract Groups

| Key | Description | Sales_Type |
|-----|-------------|-----------|
| 1 | Shell Branded | 1 (Fuel) |
| 2 | Oregon Rack Lifters | 1 (Fuel) |

Group membership via `Customer_Sales_Info.CustSls_CustContGrp_Key`. **Zero customers are currently assigned to any group** (confirmed: `COUNT(*) WHERE CustSls_CustContGrp_Key IS NOT NULL = 0`).

### Pricing Rule Resolution Engine

**Proc:** `OD_CalcPrices_ResolveFuelPricingRules_SP` (called by `OD_CalcOrder_SP`)

Resolution order:
1. Override/Dispatched — `ODPC_CustFuelContDtl_Key` already set on order line
2. Direct customer — `ODPC_Cust_Key = CustFuelCont_Cust_Key`
3. Contract group — `ODPC_Cust_Contract_Group_Key = CustFuelCont_CustContGrp_Key`

Steps 2 and 3 are a UNION — both contribute candidate rules to the ranking engine.

**Proc:** `OD_CalcPrices_ResolveFuelPricingRules_GetRules_SP`

Deterministic ranking via weighted score (`crRank`):

| Match Dimension | Points |
|----------------|--------|
| Customer Location | 3000 |
| Customer | 2000 |
| Contract Group | 1000 |
| Product | 200 |
| Product Price Group | 100 |
| Vendor | 50 |
| Bulk Plant | 50 |
| Fuel Contract | 20 |
| Terminal | 10 |

Selection: `MAX(crRank)` per `crOrdFuelKey` — single winner per order fuel line. Not additive.

### ODFPCI Import Pipeline (15 Stored Procs)

```
ODW_FuelPricingContractImport_ResolveKeys_SP           ← ID → Key resolution
ODW_FuelPricingContractImport_SetDefaults_SP            ← fills ~30 nullable fields with zeros
ODW_FuelPricingContractImport_CopyExistingContractDetails_SP ← preserves existing values during update
ODW_FuelPricingContractImport_Validate_SP               ← master validator
  ├─ ValidateDuplicateRecords_SP
  ├─ ValidateDuplicateRules_SP                          ← coverage matrix uniqueness check
  ├─ ValidateRules_SP
  ├─ ValidateProducts_SP
  ├─ ValidateLocations_SP
  ├─ ValidateOrigins_SP
  └─ ValidateContractRuleAttributeAssignments_SP
ODW_FuelPricingContractImport_ResolveInUseContracts_SP  ← checks if contract is on active orders
ODW_FuelPricingContractImport_Post_SP                   ← writes to permanent tables
ODW_FuelPricingContractImport_DeleteBatch_SP            ← cleanup
ODW_FuelPricingContractImport_SingleLine_Split_SP       ← Type 100 single-line format splitter
```

**Post_SP upsert behavior:**
- UPDATE existing rules: matched by `Contract_ID + Effective_DateTime + Description` (where `Imp_ODFuelPrcRule_Key IS NOT NULL`)
- INSERT new rules: where `Imp_ODFuelPrcRule_Key IS NULL`
- All 46+ fields overwritten on update (not partial merge)

**ValidateDuplicateRules_SP behavior:**
- Builds coverage matrix: rule × product × location × origin
- Checks new-vs-new AND new-vs-existing for overlap
- Flags duplicate coverage as validation error (blocks import)

---

## Permission Model (Proved April 2026)

Evidence source: Direct execution attempts and `HAS_PERMS_BY_NAME()` checks on PDI-SQL-01.

| Account | Type | DB Roles | DML | EXECUTE on OD_* procs |
|---------|------|----------|-----|----------------------|
| `COLEMANOIL\jason.vassar` | Windows auth | default | Read only | **No** |
| `svc-fuelpriceauto` | SQL auth | `db_datareader` + explicit INSERT/UPDATE/DELETE | Table-level DML | **No** |
| `ColemanOil\svc-Quser` | Windows auth (app tier) | — | Full (via procs) | **Yes** — this is the designed execution identity |

`svc-Quser` is not directly callable from SQL clients. It connects via integrated Windows auth from the PDI application server (ODIMP/ODE application layer). All import and order operations must go through the ODIMP front door to execute under this identity.

---

## Live Data Evidence (April 2026 Snapshot)

### Orders Domain

| Metric | Value |
|--------|-------|
| Total orders | 513,331 |
| Status 6 (posted) | 471,294 |
| Posted with billing batch | 471,294 (100%) |
| Posted with invoice number | 471,294 (100%) |
| Posted with post datetime | 471,294 (100%) |
| `Order_Billing_Batches` rows | 65,200 |
| Multi-order batches | 42,316 |
| Avg orders per batch | 7.39 |
| Max orders in one batch | 397 |
| `Order_Batches` rows | 0 |
| `Orders_Pending` rows | 0 |

### Customer Fuel Contract Domain

| Metric | Value |
|--------|-------|
| Customer Fuel Contracts | 11 (10 direct + 1 group) |
| Contract Details | 11 |
| Pricing Rules | 11 |
| Product assignments | 20 |
| Location assignments | 9 |
| Origin assignments | 0 |
| Contract groups | 2 |
| Customers assigned to groups | 0 |
| Contract import batches | 0 (never imported via ODFPCI) |

### Proxy Terminal Baseline (Current Operational Pattern)

| Metric | Value |
|--------|-------|
| Z-prefix proxy terminals | 2,462 |
| Proxy terminals with active Fuel_Costs rows | 1,518 |
| Total Fuel_Costs rows via proxy terminals | 3,429,708 |
| Date range | 2022-11-10 through 2026-04-11 |

Naming convention: `z{cust_id}{product_suffix}` — synthetic terminals representing customer/product pricing. `Fuel_Costs` is the current write target for customer pricing.

---

## POC Evidence (April 2026)

### Pete Order Round-Trip (Phase 6)

| Aspect | Value |
|--------|-------|
| Order number | `2604-406571` (Ord_Key 533454) |
| Import path | ODIMP CSV → Profile 68 → `OD_WS_ImportOrders_SP` chain |
| Customer | 867665 (City of Sumas) |
| Product | 2100200 (Clear ULSD2) |
| CustomerFuelContractID | `867665` → CustFuelCont_Key 10, Detail_Key 15 |
| ContractID | `CHS.B.R` → FuelCont_Key 455 |
| Pricing resolution | OrdFuel_CustFuelCont_Key=10, Unit_Price=0.45 (Cost + $0.45 per rule) |
| Final status | Cancelled (Status 8), load removed — clean POC teardown |

This proved: ODIMP CSV → native proc chain → full three-grain materialization (header + detail + load) → contract resolution → pricing calculation. The entire `_Orders_Upload` → ODIMP path is viable.

The direct module adjacency scan shows that procedures referencing `dbo.Orders` most frequently also reference:

- `dbo.Order_Details_Fuel`
- `dbo.Order_Fuel_Load_Details`
- `dbo.Sites`
- `dbo.Customers`
- `dbo.Order_Details_Warehouse`
- `dbo.Products`
- `dbo.Customer_Locations`
- `dbo.Order_Fuel_Loads`
- helper procedures/functions such as `dbo.LI_ClearTransientData_SP`, `dbo.SI_GetConfigValue_FN`, `dbo.SI_GetConfigValueBoolean_FN`, `dbo.LI_AddErrMsg_FN`, `dbo.LI_Translate_FN`

This is the clearest signal that the real operational domain is header + lines + loads + customer/site/product context, not header alone.

## Minimum Upsert Grain Analysis

### What Is Proven

#### Header grain

- primary key: `Ord_Key`
- unique alternate key: `Ord_No`

That proves:

- one internal row per `Ord_Key`
- one unique order number per `Ord_No`

#### Child grains

- fuel line: `dbo.Order_Details_Fuel (OrdFuel_Key)`
- warehouse line: `dbo.Order_Details_Warehouse (OrdWh_Key)`
- fee line: `dbo.Order_Details_Fees (OrdFee_Key)`
- tax line: `dbo.Order_Details_Taxes (OrdTax_Key)`
- fuel fee line: `dbo.Order_Details_Fuel_Fees (OrdFuelFee_Key)`
- fuel freight line: `dbo.Order_Details_Fuel_Freight (OrdFuelFrt_Key)`
- load grain: `dbo.Order_Fuel_Loads (Load_Key)`

Additional proof:

- `dbo.Order_Details_Fuel_Freight` has a separate unique constraint on `(OrdFuelFrt_FrtRule_Key, OrdFuelFrt_Ord_Key, OrdFuelFrt_OrdFuel_Key)`
  - this proves freight is not modeled as a simple append-only child of order header; it also has line-level uniqueness semantics

### What The Write Procedures Prove

- `dbo.OD_SaveOrder_SP` exposes essentially the full header column surface and contains `INSERT INTO Orders (...)`
- `dbo.OD_CopyOrder_Orders_SP` creates new order headers via `INSERT INTO Orders (...)`
- `dbo.OD_OrdImpPost_WriteOrders_SP` also inserts headers via batch/import flow
- `dbo.OD_CreateBackOrder_SP` derives a new order number from an existing order and explicitly checks duplicate `Ord_No`
- `dbo.OD_CreditAndRebillOrders_SP` stages copy/rebill activity through temp work structures rather than a single natural key upsert

### Competing Hypotheses

#### Hypothesis A: the minimum safe header upsert grain is `Ord_No`

Evidence for:

- `Ord_No` has a hard unique constraint
- procedures visibly care about order-number duplication

Evidence against:

- lifecycle flows create copied/backordered/rebilled orders with new headers and self-links
- self-referential FKs show order-to-order lineage that is not captured by `Ord_No` alone
- the domain is procedure-mediated, so uniqueness of `Ord_No` does not imply completeness of header mutation behavior

#### Hypothesis B: the minimum safe header upsert grain is `Ord_Key`

Evidence for:

- `Ord_Key` is the actual primary key and all first-level child FKs point to it
- line tables and audit/status tables all anchor on `Ord_Key`

Evidence against:

- external integrations generally do not begin with a vendor surrogate key for new rows
- create/import procedures take business fields and process envelopes, not just `Ord_Key`

### Conclusion

The true minimum safe upsert grain cannot be fully proven as a pure table-level external contract.

What can be proven is:

- internal header identity is `Ord_Key`
- alternate business uniqueness is `Ord_No`
- the order domain immediately fans out into separate child grains for fuel, warehouse, fee, tax, freight, payment, and load rows

So the conservative operational conclusion is:

- if you are reasoning about `dbo.Orders` alone, the header row grain is one row per `Ord_Key`, with `Ord_No` as unique alternate key
- if you are reasoning about a safe business upsert of the full order domain, header-only grain is insufficient; you must account for child-line grains and procedure-mediated lifecycle rules

## Vendor-Native PDI Domain vs CitySV Touchpoints

### Vendor-native PDI domain objects

Everything documented above is vendor-native PDI schema surface discovered in `PDICompany_2386_01`.

### CitySV integration / operational touchpoints

In the `citysv-gravitate-pdi-ode` repo, I did not find direct `dbo.Orders` DML or explicit `dbo.Orders` references.

What the repo does own is upstream and adjacent:

- `dbo.CitySV_Gravitate_Orders_Ingest_Raw`
- `dbo.CitySV_Gravitate_Orders_Ingest_RunLog`
- `dbo.sp_CitySV_Gravitate_Orders_INGEST`
- `dbo.usp_CitySV_UploadB_CITT_Translate`
- server-side `Pull-GravitateOrders.ps1`

Those objects translate Gravitate-delivered order files into PDI identifiers for Upload B work. They are not the native PDI `dbo.Orders` write surface.

## Ambiguities And Soft-Logic Warning Signs

- unresolved dependency objects such as `.OrdersWorkTable`, `.Lookup_Keys`, and `.Error_Messages` show that important workflow state lives in temp/transient structures rather than hard relational schema
- self-referential FKs on `dbo.Orders` show credit/rebill/original/split lineage, but they do not by themselves explain the lifecycle rules; procedures do
- only one alternate unique key exists on the header (`Ord_No`), so many workflow constraints appear to be application-enforced rather than declaratively constrained
- the procedure surface is large enough that a table-only interpretation of order behavior would be misleading

## Practical Bottom Line

`dbo.Orders` sits at the center of a procedure-driven order engine.

For documentation, investigation, or integration design, the minimal trustworthy model is:

- header: `dbo.Orders`
- primary child lines: fuel, warehouse, fee, tax, freight, payment, preauth
- operational context: customer, customer location, site, driver, vehicle, terms, load
- lifecycle logic: OD create/save/import/calc/status/billing procedures

Anything less than that will miss the actual grain and the actual points where vendor logic makes decisions.
