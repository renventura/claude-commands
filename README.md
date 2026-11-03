# claude-commands

Shared [Claude Code](https://claude.com/claude-code) slash commands and skills for the team. Add more as they come up.

## Installing a command

Copy (or symlink) the file you want into your own `~/.claude/commands/` directory:

```sh
cp commands/<name>.md ~/.claude/commands/<name>.md
```

Some commands come with an installer for their supporting files (see `/eod` below).

Claude Code picks up anything in that directory as a `/command-name` slash command — no restart needed.

## Commands

### `/eod`

Builds an end-of-day report covering everything since your last `/eod` run and saves it as a Slack **draft** (never auto-sent) in `#software-eod`. It pulls from:
- a log of Linear issues Claude records as you work on them
- your local Claude Code session transcripts
- substantial Slack conversations you took part in
- your Google Calendar meetings

The report is grouped by project under TODAY, FLAGS and NEXT.

`/eod` needs a logging script and a CLAUDE.md rule alongside the command, so install it with the installer rather than copying the file:

```sh
./eod/install.sh
```

The installer symlinks the command and script into `~/.claude` and appends the logging rule to `~/.claude/CLAUDE.md`. It backs up any file it replaces and is safe to re-run. Then merge the permissions from `eod/settings.sample.json` into `~/.claude/settings.json`.

Requirements: macOS, and the Slack, Google Calendar and Linear connectors (`/mcp`). It resolves your Slack user ID at runtime, so it's safe to use as-is. The target channel (`#software-eod`) is hardcoded; change the `channel_id` in the command if you adapt it for another team. See [`eod/README.md`](eod/README.md) for details, including runtime state and how to reset the report window.

## Skills

Skills live in `skills/`. Each is a folder with a `SKILL.md`. Install one by symlinking (or copying) its folder into `~/.claude/skills/`:

```sh
ln -s "$PWD/skills/candidate-interview-prep" ~/.claude/skills/candidate-interview-prep
```

Claude Code uses a skill automatically when your request matches it, or you can invoke it as `/skill-name`.

### `candidate-interview-prep`

Prepares you to interview an engineering candidate. Give it the candidate's resume, cover letter and any other files, plus the job posting (link or file). It produces:
- a PDF with a scored fit assessment, strengths and concerns, an interview plan, and questions tailored to the candidate, each with example answers
- an interactive HTML version with a sidebar for picking questions, taking notes and tracking what you've asked during the interview

Supports a per-person interviewer profile (your specialty, interview length, output folder). Requires Google Chrome and `python3`. See [`skills/candidate-interview-prep/README.md`](skills/candidate-interview-prep/README.md) for setup and details.
