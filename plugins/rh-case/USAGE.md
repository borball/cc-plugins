# Usage Guide

This plugin is designed for **AI-native** interaction — you talk to Claude Code in natural language, and slash commands handle the API calls behind the scenes. You don't need to memorize flags or syntax.

## Getting Started

```
> /rh-case:init
```

Claude will walk you through pasting your offline token and account number. That's it.

## Everyday Examples

### Check your cases

```
> /rh-case:list
> /rh-case:list open cases
> /rh-case:list high severity openshift cases
```

You can also just ask Claude directly:

```
> show me all my open cases
> do I have any urgent cases?
> list cases waiting on Red Hat
```

### View a specific case

```
> /rh-case:show 04407007
```

Or conversationally:

```
> what's the latest on case 04407007?
> show me case 04407007 with comments
```

### Export a case with attachments

Before running a deep analysis, export the case with its attachments:

```
> /rh-case:export 04407007 --download-attachments
```

This downloads the case to `case-04407007.md` and saves all attachments (sosreports, must-gather bundles, logs) to `case-04407007-attachments/`.

### Deep analysis

This is where the AI-native approach really shines. Instead of reading through dozens of comments manually:

```
> /rh-case:analyze 04407007
```

Claude will:
1. Check for exported attachments — if not found, prompt you to export first
2. Analyze sosreports, must-gather bundles, and logs for root cause evidence
3. Fetch the full case with all comments
4. Produce a structured summary (problem, root cause indicators, timeline, impact)
5. Search KCS for related solutions
6. Search for similar support cases
7. Look up referenced Jira bugs and search for related ones (if Jira MCP is configured)
8. Suggest next steps
9. Save the full analysis to `case-04407007-analysis.md`

The analysis file is updated on re-analysis while preserving any notes you've added.

You can then have a conversation about the results:

```
> is this the same issue as OCPBUGS-12345?
> what workaround did the engineer suggest?
> summarize the timeline in bullet points for my manager
```

### Search knowledge base

```
> /rh-case:search oslat OOMKilled memory limit
> /rh-case:search --type kcs etcd leader election timeout
```

Or just ask:

```
> are there any KCS articles about PTP sync failures on E825?
> search for solutions related to node NotReady after upgrade
```

### Add a comment

```
> /rh-case:comment 04407007 Tested with the suggested workaround, issue is resolved.
```

Or conversationally:

```
> post a comment on case 04407007 saying we applied the fix and it works
> update case 04407007 that we need more time to test
```

### Export a case

```
> /rh-case:export 04407007
> /rh-case:export 04407007 --download-attachments
```

Exports the full case (details, comments, attachments list) to a local markdown file. With `--download-attachments`, all case attachments (sosreports, must-gather, logs) are saved to `case-04407007-attachments/`.

## Combining with Jira

If you have the Jira MCP server configured (see README), the analyze command automatically:

- Extracts Jira issue keys (e.g., `OCPBUGS-80952`) from case comments
- Fetches their current status, assignee, and summary
- Searches Jira for similar bugs using keywords from the case

You can also query Jira directly in the conversation:

```
> what's the status of OCPBUGS-80952?
> search jira for oslat memory limit bugs in OCPBUGS project
> are there any open bugs related to this case?
```

## Workflow Example: Triaging a New Case

A typical AI-native workflow for handling a new support case:

```
> /rh-case:list open cases waiting on Red Hat

  (Claude shows a table of cases)

> /rh-case:export 04407007 --download-attachments

  (Claude exports the case and downloads sosreports, must-gather, etc.)

> /rh-case:analyze 04407007

  (Claude analyzes attachments, case data, searches KCS/Jira, saves to case-04407007-analysis.md)

> draft a customer response summarizing our findings and the workaround

  (Claude drafts a response based on the analysis)

> /rh-case:comment 04407007 <paste or let Claude post the draft>
```

## Workflow Example: Investigating a Pattern

```
> /rh-case:search etcd leader changed

  (Claude finds matching cases)

> show me cases 04401234 and 04405678

  (Claude fetches both)

> are these two cases hitting the same issue? compare the error patterns

  (Claude cross-references the case data and gives you an answer)

> export both cases for the team meeting

  (Claude exports to markdown files)
```

## Tips

- **Be conversational** — You don't need exact command syntax. Claude understands intent.
- **Follow up** — After any command, ask Claude to dig deeper, reformat, compare, or draft responses.
- **Combine data sources** — Ask Claude to cross-reference case data with KCS articles, Jira bugs, or even external docs.
- **Stay in context** — Once a case is loaded, Claude remembers it. You can ask follow-up questions without repeating the case number.
