#!/usr/bin/env python3
"""Render a JavaScript-heavy job posting page with headless Chrome and print its visible text.

Usage: python3 -I fetch_job_posting.py <url>
"""
import os
import shutil
import subprocess
import sys
import tempfile
from html.parser import HTMLParser

CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    shutil.which("google-chrome") or "",
    shutil.which("chromium") or "",
]

SKIP = {"script", "style", "noscript", "svg", "template", "head"}
BLOCK = {"p", "div", "li", "br", "h1", "h2", "h3", "h4", "h5", "h6", "tr", "section", "ul", "ol"}


class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.skip_depth = 0
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag in SKIP:
            self.skip_depth += 1
        elif tag in BLOCK:
            self.parts.append("\n")
        if tag == "li" and not self.skip_depth:
            self.parts.append("- ")

    def handle_endtag(self, tag):
        if tag in SKIP and self.skip_depth:
            self.skip_depth -= 1
        elif tag in BLOCK:
            self.parts.append("\n")

    def handle_data(self, data):
        if not self.skip_depth:
            self.parts.append(data)

    def text(self):
        lines = [" ".join(line.split()) for line in "".join(self.parts).splitlines()]
        out, blank = [], False
        for line in lines:
            if line:
                out.append(line)
                blank = False
            elif not blank:
                out.append("")
                blank = True
        return "\n".join(out).strip()


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: fetch_job_posting.py <url>")
    url = sys.argv[1]
    if not url.startswith(("http://", "https://")):
        sys.exit("error: expected an http(s) URL")
    chrome = next((c for c in CHROME_CANDIDATES if c and os.access(c, os.X_OK)), None)
    if not chrome:
        sys.exit("error: Chrome/Chromium not found")
    with tempfile.TemporaryDirectory() as profile:
        result = subprocess.run(
            [chrome, "--headless=new", "--disable-gpu", "--no-first-run",
             f"--user-data-dir={profile}", "--virtual-time-budget=15000",
             "--dump-dom", url],
            capture_output=True, text=True, timeout=90,
        )
    if result.returncode != 0 or not result.stdout.strip():
        sys.exit(f"error: Chrome could not render the page (exit {result.returncode})")
    parser = TextExtractor()
    parser.feed(result.stdout)
    text = parser.text()
    if not text:
        sys.exit("error: page rendered but contained no visible text")
    print(text)


if __name__ == "__main__":
    main()
