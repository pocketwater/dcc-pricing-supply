# OPERATIONS_RUNBOOK

## Purpose
Define how stewards and pipeline operators live with the canonical mapping system day-to-day: how new mappings are added, how broken pipelines are diagnosed, how drift is detected and resolved, and how the stewardship queue is worked.

## Grain Contract
- Grain In: Stewardship Lifecycle Spec, Pipeline Consumption Contracts, Validation Plan.
- Grain Out: Operational procedures sufficient for day-to-day stewardship and pipeline triage without engineering support.

## Translation Requirements
- Operations must enforce translation responsibility separation. Operators must not confuse edge normalization objects (pipeline-local) with canonical registry operations.

## Ontological Assumptions
- Operators are domain-aware business users or pipeline maintainers.
- Stewardship command-app UI is deployed and accessible.
- Confidence note: high (8/10) for procedure structure; medium for specific UI navigation steps before UX build confirmation.

---

## Routine 1: Resolving an Unresolved Mapping

**When it happens:** A pipeline encounters a BLOCK because a source value has no active mapping in the registry.

**Steps:**
1. Pipeline logs BLOCK outcome with source value and domain context.
2. Operator opens stewardship page in command app.
3. Filter by Domain + Source System + Resolution_Status = UNRESOLVED.
4. Locate the row for the source value in question (may need to add it as a new row if it was never seeded).
5. Assign Target:
   - For PDI target: use the PDI Key lookup to find the correct FuelProd_Key / FuelCont_Key / etc.
   - For non-PDI target: enter Target_Code directly.
6. Confirm slot semantics are populated correctly.
7. Set Resolution_Status = REVIEW_REQUIRED and save.
8. If you are a senior steward: review and approve (set ACTIVE, Is_Active = 1).
9. If not senior steward: flag for senior steward approval.
10. Pipeline will pass on next execution once mapping is ACTIVE.

**Do not:** Create free-text dimension values. Use only governed enumerations.

---

## Routine 2: Investigating a BLOCK in a Pipeline

**When it happens:** Pipeline fails at resolution stage with BLOCK outcome.

**Diagnosis steps:**
1. Identify the pipeline, domain, source value, and source system from the BLOCK log entry.
2. Query the appropriate contract view directly for the blocking source value:
   ```sql
   SELECT * FROM dbo.vw_Xref_<Domain>_<Source>_To_<Target>
   WHERE Source_Key_1 = '<value>';
   ```
3. If 0 rows: mapping does not exist or is not active. Follow Routine 1.
4. If >1 rows: uniqueness violation — should not be possible with unique index active; escalate to engineering.
5. If row exists but Is_Active = 0: mapping is in UNRESOLVED or REVIEW_REQUIRED state. Follow Routine 1 (approve step).
6. If row exists, Is_Active = 1, but PDI_ID is NULL: clone join is broken. Escalate to engineering (PDI clone surface may be stale or object name changed).

---

## Routine 3: Adding a New Mapping for a New Source Value

**When it happens:** Source system adds a new product, terminal, customer, etc. that needs a canonical mapping.

**Steps:**
1. Open stewardship page.
2. Click "Add New Mapping".
3. Select governed dimension values: Domain, Source System, Target System, Target Channel (if applicable), Workgroup, Owning Pipeline.
4. Enter Source_Key values using the slot labels for the selected domain (for example "Product Code" for Product domain).
5. Enter Source_Description (optional but recommended).
6. Assign Target:
   - PDI target: use key lookup control.
   - Non-PDI: enter Target_Code.
7. Save as REVIEW_REQUIRED.
8. Senior steward approves and activates.
9. Pipeline resolves on next execution.

---

## Routine 4: Retiring a Stale or Deprecated Mapping

**When it happens:** Source system retires a product, terminal, contract, etc.

**Steps:**
1. Locate the ACTIVE mapping row in stewardship page.
2. Confirm a replacement mapping exists if the source value is being renamed or migrated (not simply retired).
3. Click "Retire" action.
4. Enter Notes describing the reason for retirement.
5. Confirm action.
6. Row transitions to RETIRED, Is_Active = 0.
7. Row is excluded from all pipeline contract views immediately.
8. If pipelines still send the retired source value after retirement, they will BLOCK. Expected behavior; the source side should also be updated.

---

## Routine 5: Drift Detection Response

**When it happens:** Scheduled drift-detection process flags an ACTIVE row as REVIEW_REQUIRED because `_Key` is no longer found in PDI clone.

**Steps:**
1. Open stewardship page.
2. Filter by Resolution_Status = REVIEW_REQUIRED.
3. Check the Notes column for the drift detection flag message.
4. Investigate in PDI: was the product/terminal/contract renamed, re-keyed, or retired in PDI?
5. If re-keyed: update Target_Key to new value, approve and re-activate.
6. If retired in PDI: retire this mapping row (Routine 4).
7. If false positive (clone was temporarily stale): re-confirm Key and re-activate.

**Do not:** Silently set ACTIVE without confirming the correct Key. Drift detection exists for a reason.

---

## Routine 6: Adding a New Pipeline View (New Consumer Onboarding)

**When it happens:** A new pipeline or repo needs to consume canonical mappings for a domain/source/target combination that doesn't yet have a contract view.

**Steps:**
1. Confirm the domain, source system, target system, and channel combination.
2. Verify the combination is covered in Domain Contract Specs (if not, spec must be drafted first).
3. Build and deploy the new pipeline contract view per Physical Architecture Memo pattern.
4. Register the new view in `Consuming_Views` JSON field on relevant registry rows.
5. Update Pipeline Consumption Contracts document.
6. Pipeline author uses the new view.

---

## Escalation Contacts
| Issue Type | Route |
|---|---|
| Uniqueness constraint violation (> 1 active row) | Engineering |
| PDI clone join returning NULL for known-good Key | Engineering (clone health) |
| Governed dimension value needed that doesn't exist | Jason approval → add to dimension table |
| New domain not in governed list | Architecture decision required before proceeding |
| CITT table producing different output than new view | Engineering + Validator (treat as MISMATCH, do not self-resolve) |

---

## Skill Opportunity Review
- Classification: NO_CANDIDATE
- Rationale: Operations runbook is program-specific procedural documentation, not a reusable execution skill pattern.
