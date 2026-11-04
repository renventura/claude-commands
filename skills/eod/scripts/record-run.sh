#!/bin/sh
# Record a successful /eod run: write RUN_START as the new last-run, then drop
# every log entry before it. Entries logged after RUN_START (while the run was
# going) are kept for the next report.
# Usage: record-run.sh <RUN_START, UTC ISO e.g. 2026-11-04T21:00:30Z>

case "$1" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) ;;
  *)
    echo "usage: $0 <RUN_START as YYYY-MM-DDTHH:MM:SSZ>" >&2
    exit 1
    ;;
esac

set -e
dir="$HOME/.claude/eod"
mkdir -p "$dir"

printf '%s\n' "$1" > "$dir/last-run"

log="$dir/linear-log.tsv"
if [ -f "$log" ]; then
  awk -F'\t' -v s="$1" '$1 >= s' "$log" > "$log.tmp"
  mv "$log.tmp" "$log"
fi

echo "last-run: $(cat "$dir/last-run")"
echo "log entries kept: $(wc -l < "$log" 2>/dev/null | tr -d ' ' || echo 0)"
