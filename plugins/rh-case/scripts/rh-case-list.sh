#!/usr/bin/env bash
# rh-case-list.sh — List/filter Red Hat support cases via Hydra search API
# Usage: rh-case-list.sh [--status STATUS] [--severity SEV] [--product PROD] [--account ACCT] [--rows N]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/rh-case-common.sh"
load_config

# Defaults
ROWS=50
STATUS=""
SEVERITY=""
PRODUCT=""
ACCOUNT="${RH_ACCOUNT_NUMBER:-}"
GROUP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status)   STATUS="$2"; shift 2 ;;
    --severity) SEVERITY="$2"; shift 2 ;;
    --product)  PRODUCT="$2"; shift 2 ;;
    --account)  ACCOUNT="$2"; shift 2 ;;
    --group)    GROUP="$2"; shift 2 ;;
    --rows)     ROWS="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Build filter queries
FQ_PARTS=""

if [[ -n "$STATUS" ]]; then
  # Support comma-separated statuses: "Open,Waiting on Red Hat"
  if [[ "$STATUS" == *","* ]]; then
    IFS=',' read -ra STATUSES <<< "$STATUS"
    fq_vals=""
    for s in "${STATUSES[@]}"; do
      s=$(echo "$s" | xargs)  # trim whitespace
      fq_vals="${fq_vals}\"${s}\" OR "
    done
    fq_vals="${fq_vals% OR }"
    FQ_PARTS="${FQ_PARTS}&fq=case_status:(${fq_vals})"
  else
    FQ_PARTS="${FQ_PARTS}&fq=case_status:\"${STATUS}\""
  fi
fi

if [[ -n "$SEVERITY" ]]; then
  FQ_PARTS="${FQ_PARTS}&fq=case_severity:\"${SEVERITY}\""
fi

if [[ -n "$PRODUCT" ]]; then
  FQ_PARTS="${FQ_PARTS}&fq=case_product:\"${PRODUCT}\""
fi

if [[ -n "$ACCOUNT" ]]; then
  FQ_PARTS="${FQ_PARTS}&fq=case_accountNumber:\"${ACCOUNT}\""
fi

if [[ -n "$GROUP" ]]; then
  FQ_PARTS="${FQ_PARTS}&fq=case_groupNumber:\"${GROUP}\""
fi

EXPRESSION="sort=case_lastModifiedDate desc&fl=case_number,case_summary,case_status,case_product,case_version,case_severity,case_owner,case_accountNumber,case_contactName,case_createdDate,case_lastModifiedDate${FQ_PARTS}"

BODY=$(jq -n \
  --arg q "*:*" \
  --argjson start 0 \
  --argjson rows "$ROWS" \
  --arg expression "$EXPRESSION" \
  '{q: $q, start: $start, rows: $rows, partnerSearch: false, expression: $expression}')

RESPONSE=$(rh_hydra_api POST "/hydra/rest/search/v2/cases" "$BODY")

NUM_FOUND=$(echo "$RESPONSE" | jq -r '.response.numFound // 0')
echo "## Red Hat Support Cases ($NUM_FOUND found)"
echo ""

if [[ "$NUM_FOUND" == "0" ]]; then
  echo "No cases found matching the filters."
  exit 0
fi

# Table header
printf "| %-10s | %-8s | %-14s | %-50s | %-20s |\n" "Case #" "Severity" "Status" "Summary" "Last Modified"
printf "|%-12s|%-10s|%-16s|%-52s|%-22s|\n" "------------" "----------" "----------------" "----------------------------------------------------" "----------------------"

echo "$RESPONSE" | jq -r '.response.docs[] |
  [
    .case_number,
    (.case_severity // "—"),
    (.case_status // "—"),
    ((.case_summary // "—") | if length > 48 then .[:48] + ".." else . end),
    ((.case_lastModifiedDate // "—") | split("T")[0])
  ] | @tsv' | while IFS=$'\t' read -r num sev status summary modified; do
    printf "| %-10s | %-8s | %-14s | %-50s | %-20s |\n" "$num" "$sev" "$status" "$summary" "$modified"
done

echo ""
echo "_Showing up to $ROWS results. Use --rows to change._"
