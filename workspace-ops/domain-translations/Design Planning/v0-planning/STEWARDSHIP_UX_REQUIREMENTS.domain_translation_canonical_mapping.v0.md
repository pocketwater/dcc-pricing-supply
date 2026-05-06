# STEWARDSHIP_UX_REQUIREMENTS

## Purpose
Define the functional requirements for the central stewardship interface that allows human stewards to manage, review, and approve canonical mapping rows without direct database access.

## Grain Contract
- Grain In: Stewardship Lifecycle Spec, governed dimension list, ADR stewardship decision (D10).
- Grain Out: UX requirements sufficient for command-app design and Build Specification input.

## Translation Requirements
- UX must enforce translation responsibility separation visually. Stewards should not confuse edge normalization and canonical identity surfaces.

## Ontological Assumptions
- Stewards are domain-aware business users, not database administrators.
- The UX must make governed dimensions feel like choices, not free-text fields.
- Confidence note: high (8/10) for work queue model; medium (6/10) for specific control layout pending stakeholder review.

---

## Core Design Mandate
One central xref page in the command app. No separate canonical registry editor per domain. Context is applied via filters and tabs, not separate pages. Stewards navigate to one place and use scope controls to focus on their work.

---

## Page Structure

### Primary Surface: Xref Registry Stewardship
A filterable, paged grid of registry rows with the following scope controls:

**Filter Bar (top of page)**
- Domain (dropdown, governed enum)
- Source System (dropdown, governed enum)
- Target System (dropdown, governed enum)
- Target Channel (dropdown, governed enum + NULL option)
- Owning Pipeline (dropdown)
- Resolution Status (multi-select)
- Is Active (toggle)
- Work Queue Only (checkbox — limits to UNRESOLVED + REVIEW_REQUIRED)

**Grid Columns**
- Xref_ID
- Domain_Name
- Source_System
- Target_System
- Target_Channel
- Source_Key_1 (labeled by domain slot semantic)
- Source_Key_2 (labeled by domain slot semantic; hidden when NULL for domain)
- Source_Key_3 (same)
- Source_Key_4 (same)
- Source_Description
- Target_Key (shown as resolved identity label where possible)
- Target_Code
- Resolution_Status (badge with color coding)
- Is_Active (toggle, action-gated)
- Effective_From / Effective_To
- Updated_By / Updated_Dtm
- Actions column (Review, Approve, Retire, Flag)

---

## Work Queue

### Unresolved Work Queue Panel
- Surfaces all rows where Resolution_Status IN (UNRESOLVED, REVIEW_REQUIRED).
- Sorted by domain, then by age (oldest first).
- Shows conflict flag prominently for rows with CONFLICT_FLAG = Y.
- Count badge on tab showing total outstanding items.

### Batch Actions
- Approve selected (moves REVIEW_REQUIRED to ACTIVE for a set of rows after confirmation).
- Reject selected (moves back to UNRESOLVED with required notes).
- Retire selected (moves ACTIVE to RETIRED after confirmation).

---

## Edit / Review Drawer
When a steward opens a row for review, the drawer shows:

- All classification dimensions (read-only display of Domain, Source, Target, Channel, Workgroup, Pipeline).
- Source slot labels mapped to domain-specific semantic names (for example "Slot 1: Supplier" for Contract domain).
- Target resolution panel:
  - For PDI targets: `_Key` lookup with current clone data lookup indicator.
  - For non-PDI targets: Target_Code input.
- Composite hash display (read-only computed value).
- Current Resolution_Status and transition options.
- Notes field (free text for steward comments).
- Effective_From and Effective_To date pickers.
- Audit trail section: Created_By, Created_Dtm, Updated_By, Updated_Dtm.
- Consuming_Views display (JSON-rendered as readable list of repo/view pairs).

---

## Source Dropdowns (Steward Entry)
When creating a new row manually:
- All governed dimension fields are dropdowns with controlled lists (no free text).
- Slot label dynamically updates based on Domain selection (shows "Supplier" not "Source_Key_1" for Contract).
- Target lookup for PDI resolves candidate `_Key` from clone data with a search/confirm UX.

---

## Notifications and Guardrails
- Row cannot be set ACTIVE if a conflicting ACTIVE row exists for same composite key (uniqueness constraint preview before save).
- Attempting to activate a row with UNRESOLVED Target_Key for PDI target is blocked with message: "Target_Key must be resolved before activation."
- Retiring a row that has no replacement active mapping shows a warning: "No active replacement exists for this mapping."

---

## Domain-Specific Slot Label Maps
| Domain | Slot 1 | Slot 2 | Slot 3 | Slot 4 |
|---|---|---|---|---|
| Product | Product Code | — | — | — |
| Terminal | Terminal Code | — | — | — |
| Contract | Supplier | Terminal | Product | Contract Type |
| Destination | Destination Code | — | — | — |
| Vendor | Vendor Code | — | — | — |
| Customer | Customer Code | — | — | — |

---

## Access Control Requirements
- Stewards have domain-scoped read + propose access (can set REVIEW_REQUIRED, cannot directly set ACTIVE).
- Senior stewards / pipeline owners have promote access (can set ACTIVE).
- Admins / Jason have full lifecycle access.
- No direct table access for any steward persona.

---

## Out of Scope (This Spec)
- Edge normalization table management.
- PDI clone table browsing.
- Pipeline execution or job scheduling.

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: UX requirements authoring is planning-stage design output, not a reusable execution skill.
