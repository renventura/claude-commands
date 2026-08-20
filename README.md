# claude-commands

Shared [Claude Code](https://claude.com/claude-code) slash commands for the team. Add more as they come up.

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
