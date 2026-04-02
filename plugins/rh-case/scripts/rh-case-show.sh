#!/usr/bin/env bash
# rh-case-show.sh — Show details of a Red Hat support case
# Usage: rh-case-show.sh CASE_NUMBER [--comments] [--attachments]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/rh-case-common.sh"
load_config

SHOW_COMMENTS=false
SHOW_ATTACHMENTS=false
CASE_NUMBER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --comments)    SHOW_COMMENTS=true; shift ;;
    --attachments) SHOW_ATTACHMENTS=true; shift ;;
    *)
      if [[ -z "$CASE_NUMBER" ]]; then
        CASE_NUMBER="$1"; shift
      else
        echo "Unknown option: $1" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "$CASE_NUMBER" ]]; then
  echo "ERROR: Case number is required." >&2
  echo "Usage: rh-case-show.sh CASE_NUMBER [--comments] [--attachments]" >&2
  exit 1
fi

# Fetch case details
CASE=$(rh_api GET "/support/v1/cases/$CASE_NUMBER")

echo "## Case $CASE_NUMBER"
echo ""
echo "| Field | Value |"
echo "|-------|-------|"
echo "| **Summary** | $(echo "$CASE" | jq -r '.summary // "—"') |"
echo "| **Status** | $(echo "$CASE" | jq -r '.status // "—"') |"
echo "| **Severity** | $(echo "$CASE" | jq -r '.severity // "—"') |"
echo "| **Product** | $(echo "$CASE" | jq -r '.product // "—"') |"
echo "| **Version** | $(echo "$CASE" | jq -r '.version // "—"') |"
echo "| **Type** | $(echo "$CASE" | jq -r '.type // "—"') |"
echo "| **Account** | $(echo "$CASE" | jq -r '(.accountName // "—") + " (" + (.accountNumber // "—") + ")"') |"
echo "| **Contact** | $(echo "$CASE" | jq -r '(.contactName // "—") + " <" + (.contactEmail // "") + ">"') |"
echo "| **Owner** | $(echo "$CASE" | jq -r '.owner // "—"') |"
echo "| **Created** | $(echo "$CASE" | jq -r '.createdDate // "—"') |"
echo "| **Last Modified** | $(echo "$CASE" | jq -r '.lastModifiedDate // "—"') |"

# Description
DESC=$(echo "$CASE" | jq -r '.description // ""')
if [[ -n "$DESC" ]]; then
  echo ""
  echo "### Description"
  echo ""
  echo "$DESC"
fi

# Comments
if [[ "$SHOW_COMMENTS" == true ]]; then
  echo ""
  echo "### Comments"
  echo ""

  COMMENTS_RAW=$(rh_api GET "/support/v1/cases/$CASE_NUMBER/comments")

  # Handle both array and object response formats
  COMMENTS=$(echo "$COMMENTS_RAW" | jq -r '
    if type == "array" then .
    elif .comments then .comments
    else []
    end')

  COUNT=$(echo "$COMMENTS" | jq 'length')

  if [[ "$COUNT" == "0" ]]; then
    echo "_No comments._"
  else
    echo "$COMMENTS" | jq -r '.[] |
      "---\n**" + (.createdBy // "Unknown") + "** — " + (.createdDate // "—") +
      (if (.public // .isPublic // .casePublic // true) then "" else " [INTERNAL]" end) +
      "\n\n" + (.text // .commentBody // "(empty)") + "\n"'
  fi
fi

# Attachments
if [[ "$SHOW_ATTACHMENTS" == true ]]; then
  echo ""
  echo "### Attachments"
  echo ""

  ATTACHMENTS_RAW=$(rh_api GET "/support/v1/cases/$CASE_NUMBER/attachments")

  ATTACHMENTS=$(echo "$ATTACHMENTS_RAW" | jq -r '
    if type == "array" then .
    elif .attachments then .attachments
    else []
    end')

  COUNT=$(echo "$ATTACHMENTS" | jq 'length')

  if [[ "$COUNT" == "0" ]]; then
    echo "_No attachments._"
  else
    printf "| %-40s | %-12s | %-20s | %-30s |\n" "Filename" "Size" "Uploaded By" "Date"
    printf "|%-42s|%-14s|%-22s|%-32s|\n" "------------------------------------------" "--------------" "----------------------" "--------------------------------"

    echo "$ATTACHMENTS" | jq -r '.[] |
      [
        (.fileName // "—"),
        ((.length // .size // .fileSize // 0) | tostring),
        (.createdBy // "—"),
        ((.createdDate // "—") | split("T")[0])
      ] | @tsv' | while IFS=$'\t' read -r name size by date; do
        # Convert bytes to human-readable
        if [[ "$size" -gt 1048576 ]]; then
          size="$((size / 1048576))MB"
        elif [[ "$size" -gt 1024 ]]; then
          size="$((size / 1024))KB"
        else
          size="${size}B"
        fi
        printf "| %-40s | %-12s | %-20s | %-30s |\n" "$name" "$size" "$by" "$date"
    done
  fi
fi
