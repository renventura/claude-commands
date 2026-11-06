#!/bin/sh
# Append work to the running EOD log, read and cleared by /eod.
# Usage: log-issue.sh <ISSUE-KEY> "<brief summary>"
#        log-issue.sh --no-issue "<project>" "<brief summary>"
# Line format (tab-separated): <UTC ISO timestamp>	<ISSUE-KEY>	<summary>
# Work with no Linear issue is logged with the key "-" and a fourth column,
# the project it belongs to (e.g. "Telemetry"), since there is no issue to
# look the project up from.

usage() {
  echo "usage: $0 <ISSUE-KEY> \"<brief summary>\"" >&2
  echo "       $0 --no-issue \"<project>\" \"<brief summary>\"" >&2
  exit 1
}

clean() { printf '%s' "$1" | tr '\t\n\r' '   '; }

if [ "$1" = "--no-issue" ]; then
  [ $# -ge 3 ] && [ -n "$2" ] && [ -n "$3" ] || usage
  key="-"
  summary=$(clean "$3")
  project=$(clean "$2")
else
  [ $# -ge 2 ] && [ -n "$1" ] && [ "$1" != "-" ] || usage
  key=$(printf '%s' "$1" | tr -d '\t\n\r')
  summary=$(clean "$2")
  project=""
fi

dir="$HOME/.claude/eod"
mkdir -p "$dir"

if [ -n "$project" ]; then
  printf '%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$key" "$summary" "$project" >> "$dir/linear-log.tsv"
else
  printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$key" "$summary" >> "$dir/linear-log.tsv"
fi
