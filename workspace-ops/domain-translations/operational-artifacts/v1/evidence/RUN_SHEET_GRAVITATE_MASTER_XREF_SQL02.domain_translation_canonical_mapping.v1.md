# Run Sheet: Gravitate Master XREF Canonical Cutover (SQL-02)

Execution window
- Date: 2026-05-15+
- Database: PDI_PricingLink on PDI-SQL-02
- Change type: approval-gated runtime cutover
- Objective: repoint `dbo.sp_Gravitate_FTP_UPLOAD_SELECT` from legacy `dbo.Gravitate_PDI_Master_XREF` to canonical `dbo.vw_Xref_Contract_Gravitate_To_PDI` with rollback-first controls

Operator guardrails
- Do not execute without ADR approval reference.
- Do not execute seed/view/repoint out of order.
- Stop immediately on first runtime error (severity >= 11).
- Roll back procedure source immediately if postchecks fail.
- Do not freeze/rename legacy table in same window as cutover.

Pre-window checklist
1. Confirm ADR reference is recorded for this cutover.
2. Confirm `dbo.Xref_Registry`, `dbo.Gravitate_PDI_Master_XREF`, and `dbo.sp_Gravitate_FTP_UPLOAD_SELECT` exist.
3. Confirm evidence output path is writable.
4. Confirm on-call operator availability for rollback.

Evidence directory
- `dcc-pricing-supply/workspace-ops/domain-translations/operational-artifacts/v1/evidence`

Execution sequence (sqlcmd)

1) Capture pre-change procedure definition
- Input script:
  - `deployment/CAPTURE_SP_GRAVITATE_FTP_UPLOAD_SELECT_SQL02.domain_translation_canonical_mapping.v1.sql`
- Command:
  - `sqlcmd -S PDI-SQL-02 -d PDI_PricingLink -E -b -i "deployment/CAPTURE_SP_GRAVITATE_FTP_UPLOAD_SELECT_SQL02.domain_translation_canonical_mapping.v1.sql" -C -W`
- Save output:
  - `evidence/capture-sp_gravitate_ftp_upload_select-prechange-sql02.txt`

2) Seed canonical contract mappings (200 rows)
- Input script:
  - `deployment/SEED.Xref_Registry.v1.Contract.Gravitate_To_PDI.sql`
- Command:
  - `sqlcmd -S PDI-SQL-02 -d PDI_PricingLink -E -b -i "deployment/SEED.Xref_Registry.v1.Contract.Gravitate_To_PDI.sql" -C -W`
- Save output:
  - `evidence/seed-contract-gravitate-to-pdi-sql02.txt`

3) Create/refresh canonical contract view
- Input script:
  - `deployment/vw_Xref_Contract_Gravitate_To_PDI.sql`
- Command:
  - `sqlcmd -S PDI-SQL-02 -d PDI_PricingLink -E -b -i "deployment/vw_Xref_Contract_Gravitate_To_PDI.sql" -C -W`
- Save output:
  - `evidence/create-vw_xref_contract_gravitate_to_pdi-sql02.txt`

4) Run deployment manifest checks (expects seed/view complete)
- Input script:
  - `deployment/DEPLOYMENT_MANIFEST.sql`
- Command:
  - `sqlcmd -S PDI-SQL-02 -d PDI_PricingLink -E -b -i "deployment/DEPLOYMENT_MANIFEST.sql" -C -W`
- Save output:
  - `evidence/deployment-manifest-v1-sql02.txt`

5) Apply procedure repoint to canonical view
- Input script:
  - `deployment/APPLY_REPOINT_SP_GRAVITATE_FTP_UPLOAD_SELECT_TO_VW_XREF_CONTRACT_GRAVITATE_TO_PDI_SQL02.domain_translation_canonical_mapping.v1.sql`
- Command:
  - `sqlcmd -S PDI-SQL-02 -d PDI_PricingLink -E -b -i "deployment/APPLY_REPOINT_SP_GRAVITATE_FTP_UPLOAD_SELECT_TO_VW_XREF_CONTRACT_GRAVITATE_TO_PDI_SQL02.domain_translation_canonical_mapping.v1.sql" -C -W`
- Save output:
  - `evidence/apply-repoint-sp_gravitate_ftp_upload_select-sql02.txt`

6) Validate procedure source contract and canonical view health
- Input script:
  - `validation/VALIDATE_SP_GRAVITATE_FTP_UPLOAD_SELECT_CANONICAL_SOURCE_SQL02.domain_translation_canonical_mapping.v1.sql`
- Command:
  - `sqlcmd -S PDI-SQL-02 -d PDI_PricingLink -E -b -i "validation/VALIDATE_SP_GRAVITATE_FTP_UPLOAD_SELECT_CANONICAL_SOURCE_SQL02.domain_translation_canonical_mapping.v1.sql" -C -W`
- Save output:
  - `evidence/validate-sp_gravitate_ftp_upload_select-canonical-source-sql02.txt`

Stop conditions (hard)
- Any script error (severity >= 11)
- Any object compile failure
- Missing required object (`Xref_Registry`, canonical view, target procedure)
- Post-check still shows legacy reference in `sp_Gravitate_FTP_UPLOAD_SELECT`
- Canonical view has null `PDI_FuelCont_ID` rows

Rollback trigger
- Trigger rollback on any stop condition from steps 5-6.

Rollback procedure
1. Use pre-change capture output from step 1.
2. Populate captured procedure text into:
   - `deployment/ROLLBACK_SP_GRAVITATE_FTP_UPLOAD_SELECT_FROM_CAPTURE_SQL02.domain_translation_canonical_mapping.v1.sql`
3. Execute:
   - `sqlcmd -S PDI-SQL-02 -d PDI_PricingLink -E -b -i "deployment/ROLLBACK_SP_GRAVITATE_FTP_UPLOAD_SELECT_FROM_CAPTURE_SQL02.domain_translation_canonical_mapping.v1.sql" -C -W`
4. Re-run step 6 validation script.
5. Save outputs:
   - `evidence/rollback-sp_gravitate_ftp_upload_select-sql02.txt`
   - `evidence/validate-sp_gravitate_ftp_upload_select-postrollback-sql02.txt`

Window-close evidence checklist
- `evidence/capture-sp_gravitate_ftp_upload_select-prechange-sql02.txt`
- `evidence/seed-contract-gravitate-to-pdi-sql02.txt`
- `evidence/create-vw_xref_contract_gravitate_to_pdi-sql02.txt`
- `evidence/deployment-manifest-v1-sql02.txt`
- `evidence/apply-repoint-sp_gravitate_ftp_upload_select-sql02.txt`
- `evidence/validate-sp_gravitate_ftp_upload_select-canonical-source-sql02.txt`
- `evidence/gravitate-master-xref-window-decision-summary-2026-05-15.txt`

Decision authority
- Operator approval required before executing step 5.
- If uncertainty appears during window, halt and request operator resolution.
