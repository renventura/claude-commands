#!/bin/sh
# Extra setup for the eod skill, run by the repo's install.sh after it links
# the skill into ~/.claude/skills/eod:
#   - links the scripts to ~/.claude/eod/ (log-issue.sh, record-run.sh)
#   - moves aside an old /eod slash command, which would clash with the skill
#   - adds the EOD issue log rule to ~/.claude/CLAUDE.md, or updates an older copy
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

# The rule is the "## EOD issue log" section, up to the next "## " heading.
# An older copy is replaced in place, so re-running setup updates it.
rule="$here/claude-md-rule.md"
md="$claude/CLAUDE.md"
if ! grep -q '^## EOD issue log' "$md" 2>/dev/null; then
  printf '\n' >> "$md"
  cat "$rule" >> "$md"
  echo "added   EOD issue log rule to $md"
else
  awk -v rule="$rule" '
    /^## EOD issue log/ { while ((getline line < rule) > 0) print line; skip = 1; next }
    skip && /^## / { skip = 0; print "" }
    !skip { print }
  ' "$md" > "$md.tmp"
  if cmp -s "$md" "$md.tmp"; then
    rm "$md.tmp"
    echo "ok      $md already has the current EOD issue log rule"
  else
    mv "$md.tmp" "$md"
    echo "updated EOD issue log rule in $md"
  fi
fi
