#!/bin/bash
# Convert a self-contained HTML file to PDF with headless Chrome.
# Usage: html_to_pdf.sh <input.html> [output.pdf]
set -euo pipefail

in="${1:?usage: html_to_pdf.sh <input.html> [output.pdf]}"
out="${2:-${in%.html}.pdf}"

chrome=""
for c in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "$(command -v google-chrome 2>/dev/null || true)" \
  "$(command -v chromium 2>/dev/null || true)"; do
  if [ -n "$c" ] && [ -x "$c" ]; then chrome="$c"; break; fi
done
[ -n "$chrome" ] || { echo "error: Chrome/Chromium not found" >&2; exit 1; }

abs_in="$(cd "$(dirname "$in")" && pwd)/$(basename "$in")"
case "$out" in /*) abs_out="$out" ;; *) abs_out="$(pwd)/$out" ;; esac

profile="$(mktemp -d)"
trap 'rm -rf "$profile"' EXIT

"$chrome" --headless=new --disable-gpu --no-first-run --user-data-dir="$profile" \
  --no-pdf-header-footer --print-to-pdf-no-header \
  --print-to-pdf="$abs_out" "file://$abs_in" >/dev/null 2>&1

[ -s "$abs_out" ] || { echo "error: PDF was not created" >&2; exit 1; }
echo "$abs_out"
