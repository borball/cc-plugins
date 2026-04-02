---
description: "Configure Red Hat API credentials for support case access"
argument-hint: ""
---

## Name
rh-case:init

## Synopsis
```
/rh-case:init
```

## Description
Set up Red Hat Customer Portal API credentials. This command collects the user's offline token and optional account number, writes them to a `.env` file, and verifies connectivity.

## Implementation

### Step 1: Check for existing credentials

First, check if `${CLAUDE_PLUGIN_DATA}/.env` already exists. If it does, run the auth-status script to verify:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-auth-status.sh
```

If authentication succeeds, tell the user credentials are already configured and working. Ask if they want to reconfigure. If not, stop here.

### Step 2: Collect credentials (only if needed)

1. **Collect the offline token** (REQUIRED)
   - Direct the user to https://access.redhat.com/management/api
   - Click "Generate Token" to get an offline token
   - This is used to authenticate with the Red Hat Customer Portal API

2. **Collect the account number** (optional)
   - Used to filter cases to a specific account by default

### Step 3: Write credentials

Write to `${CLAUDE_PLUGIN_DATA}/.env`:
```bash
mkdir -p ${CLAUDE_PLUGIN_DATA}
```
File contents:
```
RH_OFFLINE_TOKEN=<the token>
RH_ACCOUNT_NUMBER=<optional account number>
```

### Step 4: Verify

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rh-case-auth-status.sh
```

If authentication succeeds, confirm setup is complete and suggest running `/rh-case:list` to see cases.

**IMPORTANT**: Never echo or log the offline token in output. Treat it as a secret.

## Examples

```
/rh-case:init
```
