#!/bin/sh
# Link the /eod command and its logging script into ~/.claude, and add the
# logging rule to ~/.claude/CLAUDE.md if it isn't there yet.
# Safe to re-run. Existing files are backed up to <file>.bak before linking.
set -e

repo=$(cd "$(dirname "$0")/.." && pwd)
claude="$HOME/.claude"

link() {
  src="$repo/$1"; dest="$claude/$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok      $dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak"
    echo "backup  $dest.bak"
  fi
  ln -s "$src" "$dest"
  echo "linked  $dest -> $src"
}

link commands/eod.md commands/eod.md
link eod/log-issue.sh eod/log-issue.sh

if grep -q '^## EOD issue log' "$claude/CLAUDE.md" 2>/dev/null; then
  echo "ok      $claude/CLAUDE.md already has the EOD issue log rule"
else
  printf '\n' >> "$claude/CLAUDE.md"
  cat "$repo/eod/claude-md-rule.md" >> "$claude/CLAUDE.md"
  echo "added   EOD issue log rule to $claude/CLAUDE.md"
fi
