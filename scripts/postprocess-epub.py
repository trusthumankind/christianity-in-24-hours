#!/usr/bin/env python3
"""Post-process a pandoc-generated EPUB for KDP compatibility.

Fixes:
  - Remove pandoc's auto-generated title_page.xhtml (our titlepage.md replaces it)
  - Rewrite nav.xhtml: title "Contents", nest Hours under Parts, set bodymatter landmark
  - Rewrite toc.ncx with matching nested structure
  - Remove "Copyright" and "About the Authors" from nav TOC (keep in spine)
  - Add guide reference for start-reading position
"""

from __future__ import annotations

import re
import sys
import uuid
import shutil
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


XHTML_NS = "http://www.w3.org/1999/xhtml"
OPF_NS = "http://www.opf-idpf.org/2007/opf"
DC_NS = "http://purl.org/dc/elements/1.1/"
NCX_NS = "http://www.daisy.org/z3986/2005/ncx/"
EPUB_NS = "http://www.idpf.org/2007/ops"

ET.register_namespace("", XHTML_NS)
ET.register_namespace("epub", EPUB_NS)
ET.register_namespace("opf", OPF_NS)
ET.register_namespace("dc", DC_NS)


PARTS = [
    ("Part I — The Foundation", 6),
    ("Part II — The Story", 6),
    ("Part III — The Life", 6),
    ("Part IV — The Decision", 6),
]


def _find_titlepage_file(opf_text: str) -> str | None:
    """Find the auto-generated title_page item in content.opf."""
    m = re.search(r'id="([^"]*)"[^>]*href="text/title_page\.xhtml"', opf_text)
    return m.group(1) if m else None


def _remove_title_page(opf_text: str) -> str:
    """Remove title_page.xhtml from manifest and spine."""
    opf_text = re.sub(r'\s*<item[^>]*href="text/title_page\.xhtml"[^>]*/>\s*', "\n", opf_text)
    opf_text = re.sub(r'\s*<itemref[^>]*idref="[^"]*title_page[^"]*"[^>]*/>\s*', "\n", opf_text)
    return opf_text


def _build_nav_xhtml(entries: list[dict]) -> str:
    """Build a clean nav.xhtml with Hours nested under Parts."""
    toc_items = []
    skip_titles = {"Copyright", "About the Authors"}

    part_idx = 0
    i = 0
    while i < len(entries):
        e = entries[i]
        title = e["title"]

        if title in skip_titles:
            i += 1
            continue

        if title.startswith("Part "):
            part_info = PARTS[part_idx] if part_idx < len(PARTS) else None
            n_hours = part_info[1] if part_info else 0
            part_idx += 1

            children = []
            for j in range(1, n_hours + 1):
                if i + j < len(entries):
                    child = entries[i + j]
                    children.append(f'          <li><a href="{child["href"]}">{child["title"]}</a></li>')
            child_ol = ""
            if children:
                child_ol = "\n        <ol>\n" + "\n".join(children) + "\n        </ol>"
            toc_items.append(f'      <li><a href="{e["href"]}">{title}</a>{child_ol}\n      </li>')
            i += 1 + n_hours
        else:
            toc_items.append(f'      <li><a href="{e["href"]}">{title}</a></li>')
            i += 1

    preface_href = ""
    for e in entries:
        if e["title"] == "Preface":
            preface_href = e["href"]
            break

    return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="en-US" xml:lang="en-US">
<head>
  <meta charset="utf-8" />
  <title>Christianity in 24 Hours</title>
</head>
<body epub:type="frontmatter">
<nav epub:type="toc" role="doc-toc" id="toc">
  <h1 id="toc-title">Contents</h1>
  <ol>
{chr(10).join(toc_items)}
  </ol>
</nav>
<nav epub:type="landmarks" id="landmarks" hidden="hidden">
  <ol>
    <li><a href="{preface_href}" epub:type="bodymatter">Start of Content</a></li>
    <li><a href="#toc" epub:type="toc">Table of Contents</a></li>
  </ol>
</nav>
</body>
</html>
"""


def _build_toc_ncx(entries: list[dict], book_uuid: str) -> str:
    """Build toc.ncx with matching nested structure."""
    skip_titles = {"Copyright", "About the Authors"}
    points = []
    nav_id = 0
    part_idx = 0
    i = 0
    while i < len(entries):
        e = entries[i]
        title = e["title"]

        if title in skip_titles:
            i += 1
            continue

        nav_id += 1
        if title.startswith("Part "):
            part_info = PARTS[part_idx] if part_idx < len(PARTS) else None
            n_hours = part_info[1] if part_info else 0
            part_idx += 1
            part_id = nav_id

            children = []
            for j in range(1, n_hours + 1):
                if i + j < len(entries):
                    nav_id += 1
                    child = entries[i + j]
                    children.append(
                        f'      <navPoint id="nav-{nav_id}" playOrder="{nav_id}">\n'
                        f'        <navLabel><text>{child["title"]}</text></navLabel>\n'
                        f'        <content src="{child["href"]}"/>\n'
                        f'      </navPoint>'
                    )

            child_str = "\n".join(children)
            points.append(
                f'    <navPoint id="nav-{part_id}" playOrder="{part_id}">\n'
                f'      <navLabel><text>{title}</text></navLabel>\n'
                f'      <content src="{e["href"]}"/>\n'
                f'{child_str}\n'
                f'    </navPoint>'
            )
            i += 1 + n_hours
        else:
            points.append(
                f'    <navPoint id="nav-{nav_id}" playOrder="{nav_id}">\n'
                f'      <navLabel><text>{title}</text></navLabel>\n'
                f'      <content src="{e["href"]}"/>\n'
                f'    </navPoint>'
            )
            i += 1

    uid = f"urn:uuid:{book_uuid}" if not book_uuid.startswith("urn:") else book_uuid
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="{uid}"/>
    <meta name="dtb:depth" content="2"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle><text>Christianity in 24 Hours</text></docTitle>
  <navMap>
{chr(10).join(points)}
  </navMap>
</ncx>
"""


def _parse_nav_entries(nav_text: str) -> list[dict]:
    """Extract TOC entries from pandoc's nav.xhtml."""
    entries = []
    for m in re.finditer(r'<a href="([^"]+)">([^<]+)</a>', nav_text):
        href = m.group(1)
        title = m.group(2).strip()
        if title == "Christianity in 24 Hours":
            continue
        entries.append({"href": href, "title": title})
    return entries


def _extract_uuid(opf_text: str) -> str:
    """Extract or generate UUID from content.opf."""
    m = re.search(r"urn:uuid:([a-f0-9-]+)", opf_text)
    return m.group(1) if m else str(uuid.uuid4())


def postprocess(input_epub: str, output_epub: str) -> None:
    work = Path(input_epub).parent / "epub-work"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir()

    with zipfile.ZipFile(input_epub, "r") as z:
        z.extractall(work)

    opf_path = work / "EPUB" / "content.opf"
    opf_text = opf_path.read_text("utf-8")
    book_uuid = _extract_uuid(opf_text)

    title_page = work / "EPUB" / "text" / "title_page.xhtml"
    if title_page.exists():
        title_page.unlink()
        opf_text = _remove_title_page(opf_text)
        print("  Removed pandoc title_page.xhtml")

    preface_file = None
    for f in sorted((work / "EPUB" / "text").iterdir()):
        content = f.read_text("utf-8")
        if "Preface" in content and f.name != "cover.xhtml":
            preface_file = f"text/{f.name}"
            break

    if preface_file:
        if "<guide>" in opf_text and 'type="text"' not in opf_text:
            opf_text = opf_text.replace(
                "</guide>",
                f'    <reference type="text" title="Start" href="{preface_file}"/>\n  </guide>',
            )
            print(f"  Added start-reading reference: {preface_file}")
        elif "<guide>" not in opf_text:
            opf_text = opf_text.replace(
                "</package>",
                f'  <guide>\n    <reference type="text" title="Start" href="{preface_file}"/>\n  </guide>\n</package>',
            )
            print(f"  Added guide with start-reading: {preface_file}")

    opf_path.write_text(opf_text, "utf-8")

    nav_path = work / "EPUB" / "nav.xhtml"
    nav_text = nav_path.read_text("utf-8")
    entries = _parse_nav_entries(nav_text)
    print(f"  Found {len(entries)} TOC entries")
    nav_path.write_text(_build_nav_xhtml(entries), "utf-8")
    print("  Rewrote nav.xhtml (Contents, nested Parts)")

    ncx_path = work / "EPUB" / "toc.ncx"
    if ncx_path.exists():
        ncx_path.write_text(_build_toc_ncx(entries, book_uuid), "utf-8")
        print("  Rewrote toc.ncx")

    out = Path(output_epub)
    if out.exists():
        out.unlink()

    import subprocess
    subprocess.run(
        ["zip", "-X", "-0", str(out.resolve()), "mimetype"],
        cwd=work, check=True, capture_output=True,
    )
    subprocess.run(
        ["zip", "-X", "-9", "-r", str(out.resolve()), "META-INF", "EPUB"],
        cwd=work, check=True, capture_output=True,
    )
    print(f"  Packaged: {out}")

    shutil.rmtree(work)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} input.epub output.epub")
        sys.exit(1)
    postprocess(sys.argv[1], sys.argv[2])
