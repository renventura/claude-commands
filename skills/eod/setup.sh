#!/bin/sh
# Extra setup for the eod skill, run by the repo's install.sh after it links
# the skill into ~/.claude/skills/eod:
#   - links the scripts to ~/.claude/eod/ (log-issue.sh, record-run.sh)
#   - moves aside an old /eod slash command, which would clash with the skill
#   - adds the EOD issue log rule to ~/.claude/CLAUDE.md if it isn't there yet
# Safe to re-run.
set -e

here=$(cd "$(dirname "$0")" && pwd)
claude="$HOME/.claude"

mkdir -p "$claude/eod"
for name in log-issue.sh record-run.sh; do
  src="$here/scripts/$name"
  dest="$claude/eod/$name"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok      $dest"
  else
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      mv "$dest" "$dest.bak"
      echo "backup  $dest.bak"
    fi
    ln -s "$src" "$dest"
    echo "linked  $dest -> $src"
  fi
done

old="$claude/commands/eod.md"
if [ -L "$old" ]; then
  rm "$old"
  echo "removed $old (old slash command link; /eod is now a skill)"
elif [ -e "$old" ]; then
  mv "$old" "$old.bak"
  echo "backup  $old.bak (old slash command; /eod is now a skill)"
fi

if grep -q '^## EOD issue log' "$claude/CLAUDE.md" 2>/dev/null; then
  echo "ok      $claude/CLAUDE.md already has the EOD issue log rule"
else
  printf '\n' >> "$claude/CLAUDE.md"
  cat "$here/claude-md-rule.md" >> "$claude/CLAUDE.md"
  echo "added   EOD issue log rule to $claude/CLAUDE.md"
fi
