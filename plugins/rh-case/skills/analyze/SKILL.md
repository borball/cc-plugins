---
name: Red Hat Case Analysis
description: Deep AI analysis of a Red Hat support case with attachment inspection, KCS/Jira correlation
---

# Red Hat Case Analysis

This skill performs comprehensive analysis of a Red Hat support case, combining attachment inspection, API data, KCS knowledge base search, and Jira bug correlation.

## When to Use This Skill

Use this skill when:
- The user invokes `/rh-case:analyze <CASE#>`
- The user asks to analyze, investigate, or triage a specific Red Hat support case

## Prerequisites

- Red Hat API credentials configured (run `/rh-case:init` if not)
- `curl` and `jq` available on the system
- Optional: Jira MCP server configured for bug correlation

## Implementation Steps

### Step 1: Check for exported data

Check if the case has already been exported with attachments:
- Look for `case-CASE_NUMBER.md` and `case-CASE_NUMBER-attachments/` in the current directory.
- If not found, suggest exporting first for best results:
  > For the most accurate analysis, export the case with attachments first:
  > `/rh-case:export CASE_NUMBER --download-attachments`
  >
  > This downloads must-gather bundles, sosreports, and other diagnostic files that provide critical context for root cause analysis.
  >
  > Want me to run the export now, or proceed with API data only?

### Step 2: Analyze exported attachments

If `case-CASE_NUMBER-attachments/` exists, examine the downloaded files:

**For sosreports (`.tar.xz`):**
- Extract and scan for key diagnostic data:
  ```bash
  tar -tf <sosreport> | head -50  # list contents
  ```
- Look for OOM events, kernel crashes, error logs in `sos_commands/logs/`, `var/log/`
- Check system configuration in `sos_commands/`, `etc/`

**For must-gather bundles (`.tgz`, `.tar.gz`):**
- Extract and scan for cluster state, operator logs, event dumps
- Look for pod failures, node conditions, operator degraded states

**For other files:**
- Read log files, configuration dumps, or screenshots as appropriate

Summarize key findings from the attachments before proceeding.

### Step 3: Fetch case details with comments

Run the show script to get case metadata, description, and full comment history:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-show.sh CASE_NUMBER --comments --attachments
```

### Step 4: Generate analysis summary

Combine all available data to produce:

- **Problem Summary** — What happened, in 2-3 sentences
- **Root Cause Indicators** — What the data suggests about root cause (cite specific evidence from attachments if analyzed)
- **Timeline** — Key events in chronological order
- **Impact** — What is affected (nodes, services, customers)
- **Current Status** — Where things stand now

### Step 5: Search KCS for related solutions

Extract 2-3 key technical terms from the case and search KCS:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-search.sh --type kcs "<extracted keywords>"
```

Try multiple keyword combinations if the first search yields poor results.

### Step 6: Search for similar cases

Use the same keywords to find related support cases:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-search.sh --type cases "<extracted keywords>"
```

### Step 7: Search Jira for related bugs

**Step 7a — Extract references from case text:**
Scan the case description and comments for bug tracker references:
- Jira patterns: `OCPBUGS-*`, `RHEL-*`, `ACM-*`, or any `https://issues.redhat.com/browse/*` or `https://redhat.atlassian.net/browse/*` URLs
- Bugzilla patterns: `https://bugzilla.redhat.com/show_bug.cgi?id=*`

**Step 7b — Fetch referenced Jira issues:**
For each Jira issue key found, use the `jira_get_issue` MCP tool to fetch its current status, summary, and resolution.

**Step 7c — Search Jira for similar bugs:**
Use the `jira_search` MCP tool with JQL, for example:
- `text ~ "ptp sync lost ice E825" ORDER BY updated DESC`
- `project = OCPBUGS AND text ~ "<keywords>" ORDER BY updated DESC`

If the Jira MCP server is not available, fall back to listing the extracted references without fetching details.

### Step 8: Save and present findings

Save the analysis to `case-CASE_NUMBER-analysis.md`. If the file already exists, update it with the latest findings (preserve any manual notes the user may have added under a `### Notes` section at the end).

The report format:

```markdown
# Case CASE_NUMBER — Analysis

_Last updated: YYYY-MM-DD HH:MM:SS_

## Summary
(your analysis)

## Root Cause Indicators
(what the evidence points to — cite attachment data if analyzed)

## Timeline
(key events)

## Attachment Analysis
(key findings from sosreports, must-gather, logs — if attachments were analyzed)

## Related KCS Solutions
(list any relevant KCS articles/solutions found, with links)

## Similar Cases
(list any related cases found)

## Referenced Bugs
(any Jira/Bugzilla references found in the case)

## Recommended Next Steps
(suggested actions based on the analysis)
```

After saving, tell the user the file path.

## Important Notes

- The analysis requires AI reasoning to synthesize findings — this is not a simple data dump
- Always try multiple KCS search queries with different keyword combinations
- Prioritize actionable insights over exhaustive data reproduction
- If attachments contain large log files, focus on error patterns rather than reading everything
