---
description: Build today's EOD report from local Claude Code sessions and create a Slack draft in #software-eod
---

Generate an end-of-day report by scanning today's Claude Code session transcripts across every project on this machine, then create a Slack **draft** (never send) in the #software-eod channel.

## Step 0 — Verify required connections

This report needs two live MCP connections: Slack (to create the draft and notify you) and Google Calendar (to pull meetings in Step 3). Check both before doing any other work:

- Look for each server's real (non-auth) tools — e.g. `mcp__claude_ai_Google_Calendar__` tools beyond `authenticate`/`complete_authentication`, and `mcp__claude_ai_Slack__` tools beyond its own auth tools. If only the auth tools show up for a server, it isn't connected yet.
- Google Calendar's OAuth can't be completed from inside this skill — calling `authenticate` here just returns instructions to use `/mcp` instead. So if Calendar isn't connected: tell the user to run `/mcp`, select "claude.ai Google Calendar", and complete sign-in there — then stop this run without doing Steps 1+. They can re-run `/eod` once it's connected.
- If Slack isn't connected, same treatment (stop, point to `/mcp` for "claude.ai Slack") — the report can't be delivered without it.
- Once Slack is confirmed connected, call `mcp__claude_ai_Slack__slack_read_user_profile` with no `user_id` (it defaults to the current user) and keep the returned user ID for Step 6 — never hardcode a specific person's ID here, since this command is shared across the team and must notify whoever is running it.
- Only proceed to Step 1 once both are confirmed connected.

## Step 1 — Find today's sessions

Get today's UTC date with `date -u +%Y-%m-%d` (the JSONL message `timestamp` fields are UTC — use this, not local date, to avoid drift). Then find *candidate* transcripts, excluding subagent transcripts and the project corresponding to the user's own home directory (that's where this EOD tooling itself lives, not client/work content — derive it from `$HOME` rather than hardcoding a username, since this command runs under different accounts):

```
HOME_PROJECT=$(echo "$HOME" | sed 's/\//-/g')
find ~/.claude/projects -name "*.jsonl" -mtime -2 -not -path "*/subagents/*" -not -path "*${HOME_PROJECT}*"
```

**File mtime is only a candidate filter, never proof of "today's work" — treat it as unreliable.** A session file can be touched (resume, indexing, compaction) without any new conversation happening, so its mtime can read as recent while its actual content is days old, or a single file can mix yesterday's and today's content together. The ONLY source of truth for "did this happen today" is each JSON line's own `timestamp` field (e.g. `"timestamp":"2026-07-29T20:15:00.000Z"`) — a line only counts if that field's date matches today's UTC date from above.

Group candidate files by project directory.

If, after the per-message date check in Step 2, zero lines anywhere are dated today, create the Slack draft with a single line: `No sessions logged today.` — and stop.

## Step 2 — Summarize each project in parallel

For each project directory with one or more candidate transcripts, launch a background `Agent` (subagent_type: general-purpose) with the resolved today's-UTC-date string, instructed to:

- Read the full transcript(s) for that project (include any `subagents/*.jsonl` files nested under a session if they add necessary context).
- **Filter to only JSON lines whose `timestamp` field's date matches today's UTC date.** Ignore every other line in the file, even if it's most of the file — a file being a "candidate" does not mean its content is from today.
- If a transcript has zero lines dated today, report nothing for that file/project.
- Base the summary below only on the today-dated lines.

Return **only**:

- A one-line (<15 words) plain-language summary per distinct task/issue *actually worked on* that day, written for someone skimming a status channel — not an implementation writeup. For anything involving PRs, state only the count opened/reviewed, never repo names or counts of repos.
- The associated Linear ticket key, but **only if the user actively worked that ticket in this session** (wrote/reviewed code, investigated, commented, posted findings) — not a ticket that was merely mentioned, searched, cross-referenced, or came up as related/prior context while working on something else. If no ticket was actively worked, or you're not certain, say "no ticket" rather than guessing.
- If the session surfaced a blocker, open question, or something explicitly waiting on someone else, one line describing it plus the ticket key (same actively-worked rule applies).

Explicitly tell each agent: no file names, no code details, no step-by-step of what was tried, no repo names or counts — just the outcome and the ticket key. A ticket key is a claim of fact; if it can't be directly pointed to in the transcript as something worked on today, leave it out rather than infer it. Wait for all agents to finish before continuing.

## Step 3 — Pull today's meetings

Get today's meetings from Google Calendar (same today's-UTC-date string resolved in Step 1). Step 0 already confirmed the connection is live, so just call the tools directly.

- List today's events and keep only ones the user accepted or hasn't declined — drop anything with a declined RSVP, and drop all-day/out-of-office/focus-time blocks, since those aren't calls.
- Capture only each qualifying meeting's title — no time, no attendees, no description.
- If zero qualifying meetings, carry nothing forward to Step 4.
- **If the call itself fails for any reason** (e.g. "insufficient authentication scopes", a timeout, any other API error) — a connected server can still error at call time, Step 0 only confirmed the tools exist — don't retry and don't block the rest of the report: skip meetings for this run, same as the zero-qualifying-meetings case, and continue to Step 4.

## Step 4 — Compile into TODAY / FLAGS / NEXT

Write plain Slack mrkdwn. No title, no date heading, no mention that this is automated or written by an assistant — just the three sections. This Slack tool renders standard markdown, so bold is **double** asterisks (`**TODAY**`), not Slack's native single-asterisk bold — using single asterisks here renders as italics, which is wrong. Lists are real markdown lists (`- item`), not a literal bullet character — a `•` glued onto the line is plain text, not a rendered list item:

```
**TODAY**
- <brief summary> (<TICKET-KEY>)
- ...
- <meeting title, from Step 3, no ticket key>

**FLAGS**
- <blocker/open question> (<TICKET-KEY>)
- ...
(if nothing surfaced: a single line reading "None")

**NEXT**
- <1-3 light, evidence-based guesses at logical next steps, drawn from anything left blocked/in-progress today>
```

Rules:
- **FLAGS** is never omitted — if nothing surfaced, include it with one line: `- None`.
- **NEXT** should be genuinely light — short, plain guesses the user can edit or replace, not a plan.
- Keep the whole message tight; this is a channel draft, not a document.
- Before finalizing, drop any ticket key you cannot justify as "actively worked today" — when in doubt, cut it rather than include it.
- Meeting bullets from Step 3 never carry a ticket key — they aren't tied to session work.

## Step 5 — Create the Slack draft

Use `mcp__claude_ai_Slack__slack_send_message_draft` with `channel_id: "C0A9YSM1599"` (#software-eod) and the compiled message as `message`.

If it errors with `draft_already_exists`, do not overwrite or discard anything silently — treat this as the terminal outcome of Step 5 and skip Step 6's "ready" DM in favor of the "blocked" DM described there.

Never call `slack_send_message` to post the report content itself, or to any channel. The **only** permitted use of `slack_send_message` is the one-line self-DM in Step 6 below.

## Step 6 — Notify yourself

Send a Slack DM to yourself via `slack_send_message`, using the current-user ID resolved in Step 0 as `channel_id` (never a hardcoded ID — this must always be whoever is running the command), so you notice the draft is ready to review:

- If Step 5 succeeded: a single short line, e.g. `EOD draft ready for review in #software-eod.` No other content, no repeating the report.
- If Step 5 hit `draft_already_exists`: instead send `EOD draft blocked — an unsent draft is already in #software-eod. Clear or send it, then rerun /eod.`

This DM is a notification only — never put ticket details, summaries, or report content in it, and never send it to any channel other than your own DM (the current-user ID from Step 0).
