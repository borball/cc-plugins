---
description: "Export a Red Hat support case to markdown"
argument-hint: "<CASE#> [--download-attachments]"
---

## Name
rh-case:export

## Synopsis
```
/rh-case:export <CASE#> [--output FILE] [--download-attachments]
```

## Description
Export a Red Hat support case to a markdown file, optionally downloading all attachments.

## Implementation

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-export.sh CASE_NUMBER [--output FILENAME] [--no-comments] [--no-attachments] [--download-attachments]
```

Default output file: `case-CASE_NUMBER.md`

If the user asks to download attachments (e.g., "export with attachments", "download attachments"), add the `--download-attachments` flag. This saves all case attachments to a `case-CASE_NUMBER-attachments/` directory.

After export, let the user know the file was created and offer to:
- Read and summarize the case
- Analyze the case with `/rh-case:analyze`
- Suggest next steps based on the case content

## Examples

```
/rh-case:export 04401234
/rh-case:export 04401234 --download-attachments
/rh-case:export 04401234 --output my-case.md
```
