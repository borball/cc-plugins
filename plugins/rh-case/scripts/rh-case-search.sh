#!/usr/bin/env bash
# rh-case-search.sh — Search Red Hat support cases and KCS knowledge base
# Usage: rh-case-search.sh [--type cases|kcs|solutions|articles] QUERY...

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/rh-case-common.sh"
load_config

SEARCH_TYPE="cases"
ROWS=20
QUERY_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) SEARCH_TYPE="$2"; shift 2 ;;
    --rows) ROWS="$2"; shift 2 ;;
    *)      QUERY_ARGS+=("$1"); shift ;;
  esac
done

QUERY="${QUERY_ARGS[*]}"

if [[ -z "$QUERY" ]]; then
  echo "ERROR: Search query is required." >&2
  echo "Usage: rh-case-search.sh [--type cases|kcs|solutions|articles] QUERY..." >&2
  exit 1
fi

case "$SEARCH_TYPE" in
  cases)
    # Search cases via Hydra
    EXPRESSION="sort=case_lastModifiedDate desc&fl=case_number,case_summary,case_status,case_severity,case_product,case_lastModifiedDate"

    BODY=$(jq -n \
      --arg q "$QUERY" \
      --argjson start 0 \
      --argjson rows "$ROWS" \
      --arg expression "$EXPRESSION" \
      '{q: $q, start: $start, rows: $rows, partnerSearch: false, expression: $expression}')

    RESPONSE=$(rh_hydra_api POST "/hydra/rest/search/v2/cases" "$BODY")

    NUM_FOUND=$(echo "$RESPONSE" | jq -r '.response.numFound // 0')
    echo "## Case Search: \"$QUERY\" ($NUM_FOUND found)"
    echo ""

    if [[ "$NUM_FOUND" == "0" ]]; then
      echo "No cases found."
      exit 0
    fi

    printf "| %-10s | %-8s | %-14s | %-55s |\n" "Case #" "Severity" "Status" "Summary"
    printf "|%-12s|%-10s|%-16s|%-57s|\n" "------------" "----------" "----------------" "---------------------------------------------------------"

    echo "$RESPONSE" | jq -r '.response.docs[] |
      [
        .case_number,
        (.case_severity // "—"),
        (.case_status // "—"),
        ((.case_summary // "—") | if length > 53 then .[:53] + ".." else . end)
      ] | @tsv' | while IFS=$'\t' read -r num sev status summary; do
        printf "| %-10s | %-8s | %-14s | %-55s |\n" "$num" "$sev" "$status" "$summary"
    done
    ;;

  kcs)
    # Search KCS (solutions + articles)
    BODY=$(jq -n \
      --arg q "$QUERY" \
      --argjson rows "$ROWS" \
      --argjson start 0 \
      '{q: $q, rows: $rows, start: $start}')

    RESPONSE=$(rh_api POST "/support/search/v2/kcs" "$BODY")

    NUM_FOUND=$(echo "$RESPONSE" | jq -r '.response.numFound // 0')
    echo "## KCS Search: \"$QUERY\" ($NUM_FOUND found)"
    echo ""

    if [[ "$NUM_FOUND" == "0" ]]; then
      echo "No KCS articles/solutions found."
      exit 0
    fi

    echo "$RESPONSE" | jq -r '.response.docs[] |
      "### " + (.documentKind // "Article") + ": " + (.allTitle // .publishedTitle // "Untitled") +
      "\n" + (.view_uri // "") +
      "\n\n" + (.abstract // "(no abstract)") + "\n"'
    ;;

  solutions)
    # Filter KCS results to solutions only (fetch extra to compensate for filtering)
    FETCH_ROWS=$((ROWS * 5))
    BODY=$(jq -n \
      --arg q "$QUERY" \
      --argjson rows "$FETCH_ROWS" \
      --argjson start 0 \
      '{q: $q, rows: $rows, start: $start}')

    RESPONSE=$(rh_api POST "/support/search/v2/kcs" "$BODY")

    NUM_FOUND=$(echo "$RESPONSE" | jq -r '[.response.docs[] | select(.documentKind == "Solution")] | length')
    echo "## Solutions: \"$QUERY\" ($NUM_FOUND found)"
    echo ""

    if [[ "$NUM_FOUND" == "0" ]]; then
      echo "No solutions found."
      exit 0
    fi

    echo "$RESPONSE" | jq -r '.response.docs[] | select(.documentKind == "Solution") |
      "### " + (.allTitle // .publishedTitle // "Untitled") +
      "\n" + (.view_uri // "") +
      "\n\n" + (.abstract // "(no abstract)") + "\n"'
    ;;

  articles)
    # Filter KCS results to articles only (fetch extra to compensate for filtering)
    FETCH_ROWS=$((ROWS * 5))
    BODY=$(jq -n \
      --arg q "$QUERY" \
      --argjson rows "$FETCH_ROWS" \
      --argjson start 0 \
      '{q: $q, rows: $rows, start: $start}')

    RESPONSE=$(rh_api POST "/support/search/v2/kcs" "$BODY")

    NUM_FOUND=$(echo "$RESPONSE" | jq -r '[.response.docs[] | select(.documentKind == "Article")] | length')
    echo "## Articles: \"$QUERY\" ($NUM_FOUND found)"
    echo ""

    if [[ "$NUM_FOUND" == "0" ]]; then
      echo "No articles found."
      exit 0
    fi

    echo "$RESPONSE" | jq -r '.response.docs[] | select(.documentKind == "Article") |
      "### " + (.allTitle // .publishedTitle // "Untitled") +
      "\n" + (.view_uri // "") +
      "\n\n" + (.abstract // "(no abstract)") + "\n"'
    ;;

  *)
    echo "ERROR: Unknown search type '$SEARCH_TYPE'. Use: cases, kcs, solutions, articles" >&2
    exit 1
    ;;
esac
