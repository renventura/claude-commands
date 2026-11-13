# eod

The `/eod` Claude Code skill: builds an end-of-day report covering everything since the previous `/eod` run, then saves it as a Slack **draft** in #software-eod for review. It never sends the report itself. It only runs when you type `/eod`; Claude won't start it on its own.

The report pulls from four sources:

- **Linear issue log:** issues Claude logs as it works on them during the day, in any project.
- **Claude Code session transcripts:** every project on the machine except the home-directory project, read as a trimmed digest from `extract-window.py` rather than full transcripts.
- **Slack:** substantial conversations the user took part in (debugging, support, decisions), DMs included.
- **Google Calendar:** meetings held during the report window.

It's grouped by project under three sections: TODAY, FLAGS and NEXT.

## Layout

Paths are relative to this folder (`skills/eod/`).

| Path | Installed to | What it is |
|---|---|---|
| `SKILL.md` | `~/.claude/skills/eod` (the folder is linked) | The `/eod` skill itself |
| `scripts/log-issue.sh` | `~/.claude/eod/log-issue.sh` | Appends a Linear issue, or work with no issue (`--no-issue`), to the running log |
| `scripts/extract-window.py` | `~/.claude/eod/extract-window.py` | Prints a compact per-project digest of session activity in the report window (human prompts and assistant replies only), so `/eod` never reads raw transcripts |
| `scripts/record-run.sh` | `~/.claude/eod/record-run.sh` | Records a successful run and clears the log up to it |
| `claude-md-rule.md` | added to `~/.claude/CLAUDE.md` | The rule telling Claude to log Linear work as it happens, and to ask what to do about work with no issue |
| `settings.sample.json` | merge into `~/.claude/settings.json` | Permissions the skill uses, so it runs without prompts |
| `setup.sh` | | Extra setup, run by the repo's `install.sh` (see below) |

## Install

From the repo root:

```
./install.sh eod
```

This links `~/.claude/skills/eod` to this folder, then runs `setup.sh`, which:

- links `~/.claude/eod/log-issue.sh`, `record-run.sh` and `extract-window.py` to the matching files in `scripts/`
- removes an old `~/.claude/commands/eod.md` slash command, which would clash with the skill. A symlink is deleted; a real file is moved to `eod.md.bak`.
- adds the logging rule to `~/.claude/CLAUDE.md`, or replaces it with the current version if an older one is there

Because everything is linked, a `git pull` updates the skill in place. It's safe to re-run.

The installer doesn't touch `settings.json`. Merge the `permissions.allow` entries from `settings.sample.json` into `~/.claude/settings.json` by hand.

## Requirements

- macOS (the date conversions use BSD `date -j`).
- These claude.ai connectors, connected via `/mcp`:
  - **Slack:** drafts the report, reads your profile and searches your messages.
  - **Google Calendar:** lists meetings.
  - **Linear:** looks up each issue's project name, read-only.

## Runtime state

`/eod` keeps its state in `~/.claude/eod/`, outside this repo:

- `linear-log.tsv`: tab-separated `<UTC timestamp>\t<ISSUE-KEY>\t<summary>` lines, appended by `log-issue.sh`. Work with no issue has the key `-` and a fourth column, its project.
- `last-run`: the UTC timestamp of the last successful run. The file's mtime is also used as the transcript cutoff.

After a draft is created, `/eod` runs `record-run.sh`, which writes a new `last-run` and drops log entries older than it. It's a script (allowlisted in `settings.sample.json`) because `~/.claude` is a protected path: inline shell writes or the Write tool there trigger a permission prompt, which silently stalled this step before. If the draft can't be created, nothing is cleared, so the next run covers the same window.

To set the window start by hand, e.g. to 4:20pm local today:

```
date -u -r "$(date -j -f '%Y-%m-%d %H:%M:%S' "$(date +%Y-%m-%d) 16:20:00" +%s)" +%Y-%m-%dT%H:%M:%SZ > ~/.claude/eod/last-run
touch -t "$(date +%Y%m%d)1620.00" ~/.claude/eod/last-run
```
