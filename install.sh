#!/bin/sh
# Install skills from this repo into ~/.claude/skills by symlinking them, so a
# `git pull` updates them in place. Skills with a setup.sh get it run afterwards
# for anything extra they need (scripts, CLAUDE.md rules, ...).
#
# Usage: ./install.sh              install every skill in skills/
#        ./install.sh eod ...      install only the named skills
#
# Safe to re-run. Anything already at a skill's install path that isn't a link
# to this repo is moved to ~/.claude/skills-backup/ first.
set -e

repo=$(cd "$(dirname "$0")" && pwd)
skills_dir="$HOME/.claude/skills"
backup_dir="$HOME/.claude/skills-backup"
mkdir -p "$skills_dir"

if [ $# -eq 0 ]; then
  set -- $(cd "$repo/skills" && ls -d */ | tr -d /)
fi

for name in "$@"; do
  src="$repo/skills/$name"
  dest="$skills_dir/$name"
  if [ ! -f "$src/SKILL.md" ]; then
    echo "skip    $name (no skills/$name/SKILL.md)" >&2
    continue
  fi

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok      $dest"
  else
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      # Back up outside ~/.claude/skills so Claude Code doesn't load the copy.
      mkdir -p "$backup_dir"
      bak="$backup_dir/$name-$(date +%Y%m%d%H%M%S)"
      mv "$dest" "$bak"
      echo "backup  $bak"
    fi
    ln -s "$src" "$dest"
    echo "linked  $dest -> $src"
  fi

  if [ -f "$src/setup.sh" ]; then
    sh "$src/setup.sh"
  fi
done
