#!/usr/bin/env bash
# rh-case-comment.sh — Add a comment to a Red Hat support case
# Usage: rh-case-comment.sh CASE_NUMBER --message "text" | --file path [--internal]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/rh-case-common.sh"
load_config

CASE_NUMBER=""
MESSAGE=""
FILE=""
IS_PUBLIC=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --message)  MESSAGE="$2"; shift 2 ;;
    --file)     FILE="$2"; shift 2 ;;
    --internal) IS_PUBLIC=false; shift ;;
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
  exit 1
fi

# Get comment text from --message or --file
if [[ -n "$FILE" ]]; then
  if [[ ! -f "$FILE" ]]; then
    echo "ERROR: File not found: $FILE" >&2
    exit 1
  fi
  MESSAGE=$(cat "$FILE")
elif [[ -z "$MESSAGE" ]]; then
  echo "ERROR: Provide --message or --file." >&2
  exit 1
fi

# Build comment payload
BODY=$(jq -n \
  --arg text "$MESSAGE" \
  --argjson public "$IS_PUBLIC" \
  '{text: $text, public: $public}')

RESPONSE=$(rh_api POST "/support/v1/cases/$CASE_NUMBER/comments" "$BODY")

echo "Comment added to case $CASE_NUMBER."
if [[ "$IS_PUBLIC" == false ]]; then
  echo "(Marked as internal/private)"
fi
