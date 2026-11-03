# /eod

The `/eod` Claude Code command: builds an end-of-day report covering everything since the previous `/eod` run, then saves it as a Slack **draft** in #software-eod for review. It never sends the report itself.

The report pulls from four sources:

- **Linear issue log:** issues Claude logs as it works on them during the day, in any project.
- **Claude Code session transcripts:** every project on the machine except the home-directory project.
- **Slack:** substantial conversations the user took part in (debugging, support, decisions), DMs included.
- **Google Calendar:** meetings held during the report window.

It's grouped by project under three sections: TODAY, FLAGS and NEXT.

## Layout

| Path | Installed to | What it is |
|---|---|---|
Paths are relative to the repo root.

| Path | Installed to | What it is |
|---|---|---|
| `commands/eod.md` | `~/.claude/commands/eod.md` | The `/eod` command itself |
| `eod/log-issue.sh` | `~/.claude/eod/log-issue.sh` | Appends a Linear issue to the running log |
| `eod/claude-md-rule.md` | appended to `~/.claude/CLAUDE.md` | The rule telling Claude to log Linear work as it happens |
| `eod/settings.sample.json` | merge into `~/.claude/settings.json` | Permissions the command uses, so it runs without prompts |
| `eod/install.sh` | | Links the files above into `~/.claude` and adds the CLAUDE.md rule |

## Install

```
./eod/install.sh
```

This symlinks `~/.claude/commands/eod.md` and `~/.claude/eod/log-issue.sh` to this repo, so edits here go live immediately. It appends the logging rule to `~/.claude/CLAUDE.md` only if it isn't there yet. Any existing file it would replace is moved to `<file>.bak` first. It's safe to re-run.

`install.sh` doesn't touch `settings.json`. Merge the `permissions.allow` entries from `eod/settings.sample.json` into `~/.claude/settings.json` by hand.

## Requirements

- macOS (the date conversions use BSD `date -j`).
- These claude.ai connectors, connected via `/mcp`:
  - **Slack:** drafts the report, reads your profile and searches your messages.
  - **Google Calendar:** lists meetings.
  - **Linear:** looks up each issue's project name, read-only.

## Runtime state

`/eod` keeps its state in `~/.claude/eod/`, outside this repo:

- `linear-log.tsv`: tab-separated `<UTC timestamp>\t<ISSUE-KEY>\t<summary>` lines, appended by `log-issue.sh`.
- `last-run`: the UTC timestamp of the last successful run. The file's mtime is also used as the transcript cutoff.

After a draft is created, `/eod` writes a new `last-run` and drops log entries older than it. If the draft can't be created, nothing is cleared, so the next run covers the same window.

To set the window start by hand, e.g. to 4:20pm local today:

```
date -u -r "$(date -j -f '%Y-%m-%d %H:%M:%S' "$(date +%Y-%m-%d) 16:20:00" +%s)" +%Y-%m-%dT%H:%M:%SZ > ~/.claude/eod/last-run
touch -t "$(date +%Y%m%d)1620.00" ~/.claude/eod/last-run
```
