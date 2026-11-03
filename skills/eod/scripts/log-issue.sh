#!/bin/sh
# Append a Linear issue to the running EOD log, read and cleared by /eod.
# Usage: log-issue.sh <ISSUE-KEY> "<brief summary>"
# Line format (tab-separated): <UTC ISO timestamp>	<ISSUE-KEY>	<summary>

if [ $# -lt 2 ] || [ -z "$1" ]; then
  echo "usage: $0 <ISSUE-KEY> \"<brief summary>\"" >&2
  exit 1
fi

dir="$HOME/.claude/eod"
mkdir -p "$dir"

key=$(printf '%s' "$1" | tr -d '\t\n\r')
summary=$(printf '%s' "$2" | tr '\t\n\r' '   ')

printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$key" "$summary" >> "$dir/linear-log.tsv"
