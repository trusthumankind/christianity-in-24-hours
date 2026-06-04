#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$REPO_ROOT/assets/covers/full-wrap-draft.svg"
OUT="${1:-christianity-in-24-hours-cover.pdf}"

if ! command -v rsvg-convert &>/dev/null; then
  echo "Error: rsvg-convert not found. Install with: brew install librsvg"
  exit 1
fi

echo "=== Building cover PDF from SVG ==="
echo "Source: $SVG"

rsvg-convert -f pdf "$SVG" -o "$OUT"

if command -v pdfinfo &>/dev/null; then
  SIZE=$(pdfinfo "$OUT" 2>/dev/null | grep "Page size" | sed 's/.*: *//')
  echo "Page size: $SIZE"
fi

echo "Output: $OUT"
echo "Open with: open \"$OUT\""
