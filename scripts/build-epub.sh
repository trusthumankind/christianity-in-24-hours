#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="/tmp/epub-build-$$"
OUT="${1:-christianity-in-24-hours.epub}"

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
    content = re.sub(r'\[([^\]]*)\]\([^)]*\.html\)', r'\1', content)
    content = re.sub(r'\[Table of Contents\]\(\.\./\)', 'Table of Contents', content)
    lines = [l for l in content.split('\n')
             if '· Table of Contents' not in l
             and not l.startswith('Table of Contents ·')]
    while lines and lines[-1].strip() in ('', '---'): lines.pop()
    lines.append('')
    open(f'$BUILD_DIR/{f}', 'w').write('\n'.join(lines))
"

echo "=== Generating cover image ==="
rsvg-convert -w 1600 -h 2560 "$REPO_ROOT/assets/covers/concept-b-revised.svg" | \
  python3 -c "
from PIL import Image
import sys
img = Image.open(sys.stdin.buffer).convert('RGB')
img.save('$BUILD_DIR/cover.jpg', 'JPEG', quality=95)
print(f'  Cover: {img.size[0]}x{img.size[1]}')
"

echo "=== Building EPUB with pandoc ==="
pandoc \
  --metadata-file="$REPO_ROOT/assets/epub-metadata.yaml" \
  --epub-cover-image="$BUILD_DIR/cover.jpg" \
  --toc --toc-depth=1 \
  --split-level=1 \
  --file-scope \
  --section-divs \
  -o "$BUILD_DIR/raw.epub" \
  $(cat "$REPO_ROOT/manuscript/Book.txt" | sed "s|^|$BUILD_DIR/|" | tr '\n' ' ')

echo "=== Post-processing EPUB ==="
python3 "$REPO_ROOT/scripts/postprocess-epub.py" "$BUILD_DIR/raw.epub" "$OUT"

echo "=== Validating ==="
epubcheck "$OUT" 2>&1 | tail -5

echo ""
echo "Output: $OUT"
