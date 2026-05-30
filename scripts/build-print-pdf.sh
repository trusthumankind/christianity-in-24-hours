#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="/tmp/print-build-$$"
OUT="${1:-christianity-in-24-hours-print.pdf}"

cleanup() { rm -rf "$BUILD_DIR"; }
trap cleanup EXIT

echo "=== Preparing manuscript ==="
mkdir -p "$BUILD_DIR"
python3 -c "
import re

for line in open('$REPO_ROOT/manuscript/Book.txt'):
    f = line.strip()
    if not f: continue
    content = open(f'$REPO_ROOT/manuscript/{f}').read()

    # Strip .html links (website navigation)
    content = re.sub(r'\[([^\]]*)\]\([^)]*\.html\)', r'\1', content)
    content = re.sub(r'\[Table of Contents\]\(\.\./\)', 'Table of Contents', content)

    # Remove nav footers
    lines = [l for l in content.split('\n')
             if '· Table of Contents' not in l
             and not l.startswith('Table of Contents ·')]

    # Remove trailing separators and blanks
    while lines and lines[-1].strip() in ('', '---'): lines.pop()

    # Ensure blank line before list items (pandoc requires it)
    fixed = []
    for i, l in enumerate(lines):
        if (l.startswith('- ') or re.match(r'^\d+\. ', l)) and i > 0:
            prev = lines[i-1].strip()
            if prev and not prev.startswith('- ') and not re.match(r'^\d+\. ', prev):
                fixed.append('')
        fixed.append(l)
    lines = fixed

    # Title page: keep only the heading (template renders subtitle/author)
    if f == 'titlepage.md':
        lines = [lines[0]]

    # Part pages: keep only the heading (strip chapter listings, web nav)
    if f.startswith('part'):
        lines = [lines[0]]

    lines.append('')
    open(f'$BUILD_DIR/{f}', 'w').write('\n'.join(lines))

"

echo "=== Building PDF with pandoc + typst ==="
TYPST_FONT_PATHS=~/Library/Fonts pandoc \
  --pdf-engine=typst \
  --template="$REPO_ROOT/assets/print-template.typ" \
  -V mainfont="Crimson Text" \
  -V fontsize="11.5pt" \
  --file-scope \
  --section-divs \
  -o "$OUT" \
  $(cat "$REPO_ROOT/manuscript/Book.txt" | sed "s|^|$BUILD_DIR/|" | tr '\n' ' ')

PAGE_COUNT=$(pdfinfo "$OUT" 2>/dev/null | grep Pages | awk '{print $2}')
echo ""
echo "Output: $OUT"
echo "Pages:  ${PAGE_COUNT:-unknown}"
echo "Open with: open \"$OUT\""
