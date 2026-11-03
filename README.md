# claude-commands

Shared [Claude Code](https://claude.com/claude-code) slash commands and skills for the team. Add more as they come up.

## Installing a command

Copy (or symlink) the file you want into your own `~/.claude/commands/` directory:

```sh
cp commands/eod.md ~/.claude/commands/eod.md
```

Claude Code picks up anything in that directory as a `/command-name` slash command — no restart needed.

## Commands

### `/eod`

Scans today's local Claude Code session transcripts, summarizes what you actually worked on (with Linear ticket keys where applicable), pulls today's calendar meetings, and creates a Slack **draft** (never auto-sent) in `#software-eod`.

Requirements:
- Slack and Google Calendar MCP connections (`/mcp` to connect if missing — the command will tell you if either is missing when you run it).
- It resolves your own Slack user ID at runtime (never hardcoded), so it's safe to use as-is.
- The target channel (`#software-eod`) is hardcoded to this team's shared status channel. If you're adapting this command for a different team/channel, update the `channel_id` in Step 5.

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
