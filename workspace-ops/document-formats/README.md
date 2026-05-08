# Document Formats

Canonical source for PDF/print stylesheet templates used across DCC workspace documents.

## Purpose

Provides reusable, version-controlled CSS for Markdown Preview Enhanced (MPE) PDF exports. Keeps formatting consistent across governance docs, inventory tables, runbooks, and architecture artifacts without depending on personal global settings.

## Files

| File | Purpose |
|---|---|
| `pdf-technical-tables.less` | General-purpose format for technical/governance docs with wide tables. A4 landscape (set via front-matter), fixed-layout tables, dark headers, zebra-stripe rows. |

## How to Use (MPE Export)

1. Open any `.md` file in VS Code.
2. Open the MPE preview (`Ctrl+Shift+V`, or right-click the tab → **Markdown Preview Enhanced: Open Preview**).
3. Right-click inside the preview pane → **Chrome (Puppeteer)** → **Export as PDF**.

The workspace CSS at `.vscode/markdown-preview-enhanced/style.css` is applied automatically to all MPE previews and exports in this workspace — no per-file setup required.

## Page Size and Orientation

Page size and margins are **not** set in CSS — MPE Puppeteer ignores `@page` rules. Set them in the markdown file's front-matter:

```yaml
---
puppeteer:
  landscape: true
  format: "A4"
  margin:
    top: "1cm"
    bottom: "1cm"
    left: "1cm"
    right: "1cm"
---
```

This is already present in `domain-translations/README.md`.

## Updating Styles

1. Edit the canonical source here (`document-formats/<name>.less`).
2. Copy the changes to `.vscode/markdown-preview-enhanced/style.less` (the active file MPE reads — must be `.less`, not `.css`).
3. Reload the MPE preview (`Ctrl+Shift+P` → **Markdown Preview Enhanced: Refresh Preview**), then commit both files.

## Adding New Format Variants

Add a new `.less` file in this folder named for its use case (e.g. `pdf-prose-report.less`). Document it in the table above. To activate a variant, copy it over `.vscode/markdown-preview-enhanced/style.less`.

## Current Active Format

`pdf-technical-tables.less` — A4 landscape (via front-matter), 10px table font in print, fixed-layout column wrapping, dark header row, alternating row shading.
