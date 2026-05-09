# Quantum CHS Overview

## Accounting Process

### PDI Enterprise Company _01 - Coleman Oil
1. Gravitate reports delivered load to a Quantum configured customer location.
2. Order created
    - CHS is the Vendor
    > PDI Vend_ID 143 | CHS inc.
    > PDI FuelCont_ID CHS.B.R | Cenex Branded Rack
    - Gravitate delivered customer is the order customer of record.
    - Terms: ?

### PDI Enterprise Company _93 - Quantum Eneregy, LLC
1. Gravitate reports delivered load to a Quantum configured customer location.
2. Order created
    - This order is a clone of the _01 order with different Billing parties.
    - Coleman Oil is the Vendor **currently not present in _93**
        > PDI Vend_ID TBD | TBD
        > PDI FuelCont_ID TBD | TBD
    - CHS is the customer **currently not present in _93**
        > PDI Cust_ID
    - Terms: ?
