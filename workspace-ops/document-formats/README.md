# Document Formats

Canonical source for PDF/print stylesheet templates used across DCC workspace documents.

## Purpose

Provides reusable, version-controlled CSS for Markdown Preview Enhanced (MPE) PDF exports. Keeps formatting consistent across governance docs, inventory tables, runbooks, and architecture artifacts without depending on personal global settings.

## Files

| File | Purpose |
|---|---|
| `pdf-technical-tables.css` | General-purpose format for technical/governance docs with wide tables. A4 landscape, fixed-layout tables, dark headers, zebra-stripe rows. |

## How to Use (MPE Export)

1. Open any `.md` file in VS Code.
2. Open the MPE preview (`Ctrl+Shift+V`, or right-click the tab → **Markdown Preview Enhanced: Open Preview**).
3. Right-click inside the preview pane → **Chrome (Puppeteer)** → **Export as PDF**.

The workspace CSS at `.vscode/markdown-preview-enhanced/style.css` is applied automatically to all MPE previews and exports in this workspace — no per-file setup required.

## Updating Styles

1. Edit the canonical source here (`document-formats/<name>.css`).
2. Copy the changes to `.vscode/markdown-preview-enhanced/style.css` (the active copy MPE reads).
3. Reload the preview to verify, then commit both files together.

## Adding New Format Variants

Add a new `.css` file in this folder named for its use case (e.g. `pdf-prose-report.css`, `pdf-data-portrait.css`). Document it in the table above. To activate a variant, copy it over `.vscode/markdown-preview-enhanced/style.css`.

## Current Active Format

`pdf-technical-tables.css` — A4 landscape, 11px table font, fixed-layout column wrapping, dark header row, alternating row shading.
