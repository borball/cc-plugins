#!/usr/bin/env bash
# rh-case-export.sh — Export a Red Hat support case to markdown
# Usage: rh-case-export.sh CASE_NUMBER [--output FILE] [--no-comments] [--no-attachments] [--download-attachments]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/rh-case-common.sh"
load_config

CASE_NUMBER=""
OUTPUT=""
INCLUDE_COMMENTS=true
INCLUDE_ATTACHMENTS=true
DOWNLOAD_ATTACHMENTS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)                OUTPUT="$2"; shift 2 ;;
    --no-comments)           INCLUDE_COMMENTS=false; shift ;;
    --no-attachments)        INCLUDE_ATTACHMENTS=false; shift ;;
    --download-attachments)  DOWNLOAD_ATTACHMENTS=true; shift ;;
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

# Default output file
if [[ -z "$OUTPUT" ]]; then
  OUTPUT="case-${CASE_NUMBER}.md"
fi

# Build the export by calling rh-case-show.sh with all flags
SHOW_ARGS=("$CASE_NUMBER")
if [[ "$INCLUDE_COMMENTS" == true ]]; then
  SHOW_ARGS+=(--comments)
fi
if [[ "$INCLUDE_ATTACHMENTS" == true ]]; then
  SHOW_ARGS+=(--attachments)
fi

{
  echo "# Red Hat Support Case $CASE_NUMBER"
  echo ""
  echo "_Exported on $(date '+%Y-%m-%d %H:%M:%S')_"
  echo ""
  "$SCRIPT_DIR/rh-case-show.sh" "${SHOW_ARGS[@]}"
} > "$OUTPUT"

echo "Case $CASE_NUMBER exported to $OUTPUT"

# Download attachments if requested
if [[ "$DOWNLOAD_ATTACHMENTS" == true ]]; then
  ATTACH_DIR="case-${CASE_NUMBER}-attachments"
  mkdir -p "$ATTACH_DIR"

  ATTACHMENTS_RAW=$(rh_api GET "/support/v1/cases/$CASE_NUMBER/attachments")
  ATTACHMENTS=$(echo "$ATTACHMENTS_RAW" | jq -r '
    if type == "array" then .
    elif .attachments then .attachments
    else []
    end')

  COUNT=$(echo "$ATTACHMENTS" | jq 'length')
  if [[ "$COUNT" == "0" ]]; then
    echo "No attachments to download."
    rmdir "$ATTACH_DIR" 2>/dev/null
  else
    echo "Downloading $COUNT attachment(s) to $ATTACH_DIR/..."
    echo "$ATTACHMENTS" | jq -r '.[] | [.link, .fileName, (.size // 0 | tostring)] | @tsv' | \
    while IFS=$'\t' read -r link filename size; do
      # Human-readable size
      if [[ "$size" -gt 1048576 ]]; then
        hsize="$((size / 1048576))MB"
      elif [[ "$size" -gt 1024 ]]; then
        hsize="$((size / 1024))KB"
      else
        hsize="${size}B"
      fi
      echo "  Downloading $filename ($hsize)..."
      if rh_download "$link" "$ATTACH_DIR/$filename"; then
        echo "  ✓ $filename"
      else
        echo "  ✗ Failed: $filename" >&2
      fi
    done
    echo "Attachments saved to $ATTACH_DIR/"
  fi
fi
