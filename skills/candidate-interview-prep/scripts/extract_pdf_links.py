#!/usr/bin/env python3
"""Print the hyperlink URLs embedded in PDFs (the Read tool shows only link text).

Usage: python3 -I extract_pdf_links.py <file.pdf> [more.pdf ...]
Handles uncompressed link annotations (/URI (...)), which is how most resume tools write them.
"""
import re
import sys

URI = re.compile(rb"/URI\s*\(((?:\\.|[^\\)])*)\)")
for path in sys.argv[1:]:
    data = open(path, "rb").read()
    seen = []
    for m in URI.finditer(data):
        url = re.sub(rb"\\(.)", rb"\1", m.group(1)).decode("latin-1").strip()
        if url and url not in seen:
            seen.append(url)
    print(f"# {path}" + ("" if seen else "  (no links found; they may be in compressed streams)"))
    for url in seen:
        print(url)
