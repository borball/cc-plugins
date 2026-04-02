---
description: "Analyze a Red Hat support case: summarize, find related KCS solutions and similar cases"
argument-hint: "<CASE#>"
---

## Name
rh-case:analyze

## Synopsis
```
/rh-case:analyze <CASE#>
```

## Description
Perform a deep AI analysis of a Red Hat support case. Fetches case details, inspects exported attachments (sosreports, must-gather), searches KCS for related solutions, finds similar cases, and correlates with Jira bugs. Saves the analysis report to a markdown file.

## Implementation

### Step 1: Check for exported data

Check if the case has already been exported with attachments:
- Look for `case-CASE_NUMBER.md` and `case-CASE_NUMBER-attachments/` in the current directory.
- If not found, tell the user:
  > For the most accurate analysis, export the case with attachments first:
  > `/rh-case:export CASE_NUMBER --download-attachments`
  >
  > This downloads must-gather bundles, sosreports, and other diagnostic files that provide critical context for root cause analysis.
  >
  > Want me to run the export now, or proceed with API data only?
- If the user wants to proceed without export, skip to Step 3.

### Step 2: Analyze exported attachments

If `case-CASE_NUMBER-attachments/` exists, examine the downloaded files:

**For sosreports (`.tar.xz`):**
- Extract and scan for key diagnostic data
- Look for OOM events, kernel crashes, error logs

**For must-gather bundles (`.tgz`, `.tar.gz`):**
- Extract and scan for cluster state, operator logs, event dumps
- Look for pod failures, node conditions, operator degraded states

Summarize key findings from the attachments before proceeding.

### Step 3: Fetch case details with comments
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-show.sh CASE_NUMBER --comments --attachments
```

### Step 4: Generate analysis summary

Combine the attachment analysis (if available) with case data to produce:
- **Problem Summary** — What happened, in 2-3 sentences
- **Root Cause Indicators** — What the data suggests (cite evidence from attachments if analyzed)
- **Timeline** — Key events in chronological order
- **Impact** — What is affected
- **Current Status** — Where things stand now

### Step 5: Search KCS for related solutions
Extract 2-3 key technical terms and search KCS:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-search.sh --type kcs "<extracted keywords>"
```

### Step 6: Search for similar cases
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-search.sh --type cases "<extracted keywords>"
```

### Step 7: Search Jira for related bugs

**Step 7a** — Scan case text for Jira references: `OCPBUGS-*`, `RHEL-*`, `ACM-*`, or Jira/Bugzilla URLs.

**Step 7b** — For each Jira issue key found, use the `jira_get_issue` MCP tool to fetch status, summary, and resolution.

**Step 7c** — Use the `jira_search` MCP tool with JQL to find related issues.

If Jira MCP is unavailable, list extracted references without fetching details.

### Step 8: Save and present findings

Save to `case-CASE_NUMBER-analysis.md`. If the file already exists, update it (preserve any manual `### Notes` section).

Report format:
```markdown
# Case CASE_NUMBER — Analysis

_Last updated: YYYY-MM-DD HH:MM:SS_

## Summary
## Root Cause Indicators
## Timeline
## Attachment Analysis
## Related KCS Solutions
## Similar Cases
## Referenced Bugs
## Recommended Next Steps
```

## Examples

```
/rh-case:analyze 04401234
```
