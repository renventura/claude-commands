---
name: eod
disable-model-invocation: true
description: Build the EOD report (everything since the last /eod run) from the Linear issue log and local Claude Code sessions and create a Slack draft in #software-eod
---

Generate an end-of-day report covering everything since the previous successful `/eod` run (so work done the night before, after the last report, is picked up). It uses two sources: the local Linear issue log, and the Claude Code session transcripts across every project on this machine. Then create a Slack **draft** (never send) in the #software-eod channel.

State lives in `~/.claude/eod/`:
- `last-run`: one line, the UTC ISO timestamp (e.g. `2026-11-02T22:10:00Z`) of the start of the last successful run. It may not exist yet.
- `linear-log.tsv`: tab-separated lines `<UTC ISO timestamp>\t<ISSUE-KEY>\t<brief summary>`, appended during normal work by `~/.claude/eod/log-issue.sh`. It may not exist or may be empty.

## Step 0 — Verify required connections

This report needs two live MCP connections: Slack (to create the draft and notify you) and Google Calendar (to pull meetings in Step 3). Check both before doing any other work:

- Look for each server's real (non-auth) tools — e.g. `mcp__claude_ai_Google_Calendar__` tools beyond `authenticate`/`complete_authentication`, and `mcp__claude_ai_Slack__` tools beyond its own auth tools. If only the auth tools show up for a server, it isn't connected yet.
- Google Calendar's OAuth can't be completed from inside this skill — calling `authenticate` here just returns instructions to use `/mcp` instead. So if Calendar isn't connected: tell the user to run `/mcp`, select "claude.ai Google Calendar", and complete sign-in there — then stop this run without doing Steps 1+. They can re-run `/eod` once it's connected.
- If Slack isn't connected, same treatment (stop, point to `/mcp` for "claude.ai Slack") — the report can't be delivered without it.
- Once Slack is confirmed connected, call `mcp__claude_ai_Slack__slack_read_user_profile` with no `user_id` (it defaults to the current user) and keep the returned user ID for Step 6 — never hardcode a specific person's ID here, since this command is shared across the team and must notify whoever is running it.
- Only proceed to Step 1 once both are confirmed connected.

## Step 1 — Resolve the report window and find sessions

Capture the run's start time and the window start. All timestamps are UTC (the JSONL message `timestamp` fields are UTC — never use local time, to avoid drift):

```
RUN_START=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOCAL_MIDNIGHT=$(date -u -r "$(date -j -f '%Y-%m-%d %H:%M:%S' "$(date +%Y-%m-%d) 00:00:00" +%s)" +%Y-%m-%dT%H:%M:%SZ)
WINDOW_START=$(cat ~/.claude/eod/last-run 2>/dev/null || echo "$LOCAL_MIDNIGHT")
```

Keep `RUN_START` for Step 7. The report window is `WINDOW_START` to `RUN_START`. If there's no `last-run` file yet (first run), the window falls back to local midnight today, expressed in UTC. Never use the UTC date for "today": after 7–8pm Eastern it's already tomorrow in UTC.

Then find *candidate* transcripts, excluding subagent transcripts and the project corresponding to the user's own home directory (that's where this EOD tooling itself lives, not client/work content — derive it from `$HOME` rather than hardcoding a username, since this command runs under different accounts). Use the `last-run` file's own mtime as the candidate cutoff when it exists, since a transcript can't contain new lines without being modified after it:

```
HOME_PROJECT=$(echo "$HOME" | sed 's/\//-/g')
if [ -f ~/.claude/eod/last-run ]; then AGE="-newer $HOME/.claude/eod/last-run"; else AGE="-mtime -2"; fi
find ~/.claude/projects -name "*.jsonl" $AGE -not -path "*/subagents/*" -not -path "*${HOME_PROJECT}*"
```

**File mtime is only a candidate filter, never proof of work in the window — treat it as unreliable.** A session file can be touched (resume, indexing, compaction) without any new conversation happening, so its mtime can read as recent while its actual content is days old, or a single file can mix old and new content together. The ONLY source of truth for "did this happen in the window" is each JSON line's own `timestamp` field (e.g. `"timestamp":"2026-07-29T20:15:00.000Z"`) — a line only counts if that timestamp is at or after `WINDOW_START` and before `RUN_START`.

Group candidate files by project directory.

Also read the Linear issue log now: keep only lines of `~/.claude/eod/linear-log.tsv` whose timestamp is at or after `WINDOW_START` and before `RUN_START`, then group them by issue key. Each key's entries are direct evidence that the ticket was actively worked in the window. Use them in Step 4.

If, after the per-message timestamp check in Step 2, zero transcript lines fall in the window, the log has no entries in the window, **and** Step 2b found no qualifying Slack conversations, create the Slack draft with a single line: `No sessions logged since the last report.`, then continue to Steps 6 and 7.

## Step 2 — Summarize each project in parallel

For each project directory with one or more candidate transcripts, launch a background `Agent` (subagent_type: general-purpose) with the resolved `WINDOW_START` and `RUN_START` strings, instructed to:

- Read the full transcript(s) for that project (include any `subagents/*.jsonl` files nested under a session if they add necessary context).
- **Filter to only JSON lines whose `timestamp` is at or after `WINDOW_START` and before `RUN_START`.** Ignore every other line in the file, even if it's most of the file — a file being a "candidate" does not mean its content is in the window.
- If a transcript has zero lines in the window, report nothing for that file/project.
- Base the summary below only on the in-window lines.

Return **only**:

- A one-line (<15 words) plain-language summary per distinct task/issue *actually worked on* in the window, written for someone skimming a status channel — not an implementation writeup. Describe the substance of the work (what was built, fixed, decided or found), not housekeeping actions like opening/merging a PR, closing an issue or changing its status. Never mention repo names, counts of repos or counts of PRs. If the only thing done for a task in the window was housekeeping, report nothing for it.
- The associated Linear ticket key, but **only if the user actively worked that ticket in this session** (wrote/reviewed code, investigated, commented, posted findings) — not a ticket that was merely mentioned, searched, cross-referenced, or came up as related/prior context while working on something else. If no ticket was actively worked, or you're not certain, say "no ticket" rather than guessing.
- A project label for each item: a short, plain name for the product or initiative the work belongs to (e.g. "Telemetry"), never a repo slug or directory name. This is only a fallback; Step 4 prefers the Linear project name when the item has a ticket.
- If the session surfaced a blocker, open question, or something explicitly waiting on someone else, one line describing it plus the ticket key (same actively-worked rule applies).

Explicitly tell each agent: no file names, no code details, no step-by-step of what was tried, no repo names or counts — just the outcome and the ticket key. A ticket key is a claim of fact; if it can't be directly pointed to in the transcript as something worked on today, leave it out rather than infer it. Launch the Step 2b agent at the same time as these. Wait for all agents to finish before continuing.

## Step 2b — Review Slack activity

Work done in Slack counts too, like helping debug or troubleshoot something that isn't the user's own Linear issue. Launch one more background `Agent` (subagent_type: general-purpose) alongside the Step 2 agents, passing it the user ID from Step 0 and the window as Unix timestamps:

```
SLACK_AFTER=$(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$WINDOW_START" +%s)
SLACK_BEFORE=$(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$RUN_START" +%s)
```

Instruct it to:

- Find every message the user sent in the window with `mcp__claude_ai_Slack__slack_search_public_and_private`: `filters: "from:<@USER_ID>"`, `after: SLACK_AFTER`, `before: SLACK_BEFORE`, `channel_types: "public_channel,private_channel,mpim,im"` (DMs and group DMs included), `sort: "timestamp"`, `sort_dir: "asc"`, `limit: 20`, `natural_language_query: ""`. Results come 20 at a time; keep passing the returned `cursor` until there are no more pages.
- Skip messages in #software-eod (`C0A9YSM1599`) and in the user's DM with themselves, so the report never counts itself or its notifications.
- Group the messages into conversations: one per thread, and for un-threaded channel or DM messages, one per run of back-and-forth on the same topic. Read the full thread with `mcp__claude_ai_Slack__slack_read_thread` whenever the user's messages alone don't make clear what was being solved.
- A conversation counts only if both of these hold:
  - **Enough involvement:** the user wrote 5 or more messages in it, **or** wrote at least one long, detailed answer (a real explanation, diagnosis, or walkthrough, not a one-liner).
  - **Substance:** it's about technical work, support or troubleshooting, a decision, or another topic of real substance. Judge by content, not channel name. Skip anything social or casual (greetings, jokes, lunch, weekend plans, kudos), plus scheduling, quick acknowledgements and status pings.

Return **only**, per qualifying conversation:

- A one-line (<15 words) summary of the substance, e.g. "Helped debug intermittent checkout timeouts for Support." No quotes, no customer names or account details, no names of people from DMs, no channel names, and no private details. Assume this text will be posted to a shared channel.
- A Linear ticket key only if the conversation names one **and** the user actively worked that issue in it (e.g. diagnosed it, proposed or confirmed a fix). A key that was only mentioned in passing doesn't count. Otherwise "no ticket". Never guess one.
- A project label: the plain name of the product or initiative it relates to, or "Other" if unclear.
- Any blocker or open question the user is waiting on, as one line (same ticket-key rule).

If nothing qualifies, return nothing. If the search tool errors, retry once, then return nothing rather than blocking the report.


## Step 3 — Pull meetings in the window

Get the meetings that started in the report window from Google Calendar. Step 0 already confirmed the connection is live, so just call the tools directly.

The calendar tool wants **local** times with no `Z` and no UTC offset, and it resolves the user's time zone itself. Convert the window from Step 1:

```
to_local() { date -r "$(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s)" +%Y-%m-%dT%H:%M:%S; }
CAL_START=$(to_local "$WINDOW_START")
CAL_END=$(to_local "$RUN_START")
```

- Call `mcp__claude_ai_Google_Calendar__list_events` with `startTime: CAL_START`, `endTime: CAL_END`, `orderBy: "startTime"` and `pageSize: 250`. Always pass both times explicitly: without them the tool defaults to the next 7 days, which returns upcoming events instead of past ones. Don't set `timeZone`. If the response has a `nextPageToken`, keep fetching pages until it doesn't.
- Keep an event only if all of these hold:
  - Its `start` has a `dateTime` (all-day events only have `date`, so drop them).
  - `eventType` is `DEFAULT`. Drop out-of-office, focus-time, working-location and similar blocks.
  - `status` isn't `cancelled`.
  - The user's RSVP isn't `declined`. Their RSVP is the `attendees` entry with `self: true`. If there's no such entry (an event they own with no guests, or one they organized), keep it as long as it has other attendees or a conference link. Drop solo blocks with no attendees and no conference link, since those aren't calls.
- Capture only each qualifying meeting's title (`summary`). No time, attendees or description. If the same recurring meeting shows up more than once in the window, list it once.
- If zero qualifying meetings, carry nothing forward to Step 4.
- **If the call fails** (e.g. "insufficient authentication scopes", a timeout, any other API error), retry it once. A connected server can still error at call time, since Step 0 only confirmed the tools exist. If it fails again, don't block the rest of the report: skip meetings for this run, as in the zero-meetings case, and continue to Step 4.

## Step 4 — Compile into TODAY / FLAGS / NEXT

Merge the Step 2 and Step 2b summaries with the in-window Linear log entries from Step 1:
- One bullet per Linear issue key, across every source: the log, all Step 2 summaries from every project and session, and the Step 2b Slack conversations. If several items share the same key, merge them into a single bullet with one slightly longer summary (still one line, roughly 25 words max) covering all of that issue's work, instead of listing the issue more than once. Items with no ticket are not merged by key; keep them as separate bullets unless they're plainly the same task.
- A log key with no matching Step 2 summary still gets a bullet, written from its log summaries. This covers work in projects whose transcripts weren't scanned.
- A Slack conversation (Step 2b) with no ticket is its own bullet. If it's plainly about the same work as another item, fold it into that item's bullet instead.
- Log entries count as "actively worked" evidence, so their keys pass the ticket-key rule below.
- Group every TODAY item under its project. For an item with a ticket key, the project is the Linear issue's project name: look it up with `mcp__claude_ai_Linear__get_issue` (read-only), and fall back to its team name if it has no project. For items without a ticket, use the project label from Step 2 or 2b, reusing the name of a project already in the report when the work plainly belongs to it. Items that fit nowhere go under "Other", and meetings go under "Meetings". If the Linear lookup fails, use the agents' project labels instead.
- Weed out housekeeping. Summaries describe substance: what was built, fixed, decided, investigated or found. Leave out actions like closing an issue, moving its status, opening or merging a PR, or counts of PRs. If an issue has nothing but housekeeping in the window (e.g. only closed, only moved to Done, only shipped with no other work), skip it entirely. Don't give it a bullet.

Write plain Slack mrkdwn. No title, no date heading, no mention that this is automated or written by an assistant — just the three sections. This Slack tool renders standard markdown, so bold is **double** asterisks (`**TODAY**`), not Slack's native single-asterisk bold — using single asterisks here renders as italics, which is wrong. Lists are real markdown lists (`- item`), not a literal bullet character — a `•` glued onto the line is plain text, not a rendered list item:

```
**TODAY**
- <Project name>
  - <brief summary> (<TICKET-KEY>)
  - <brief summary>
- <Another project>
  - ...
- Other
  - <work that fits no project>
- Meetings
  - <meeting title, from Step 3, no ticket key>

**FLAGS**
- <Project name>
  - <blocker/open question> (<TICKET-KEY>)
- <blocker/open question that fits no project>
(if nothing surfaced: a single line reading "None")

**NEXT**
- <Project name>
  - <light, evidence-based guess at a logical next step>
- <next step that fits no project>
```

Rules:
- **TODAY** is a nested list: each project is a top-level bullet (plain text, not bold), and its work items are child bullets indented two spaces. Order projects by how much was done in each, put "Other" and then "Meetings" last, and leave out any group that has no items. FLAGS and NEXT use the same project names as TODAY: group an item under its project when it belongs to one, and put items that don't as plain top-level bullets after the groups (no "Other" heading). If every item in the section is project-less, it's just a flat list.
- **FLAGS** is never omitted — if nothing surfaced, include it with one line: `- None`.
- **NEXT** should be genuinely light — 1-3 short, plain guesses in total across all projects, drawn from anything left blocked or in progress. The user can edit or replace them; it's not a plan.
- Keep the whole message tight; this is a channel draft, not a document.
- Before finalizing, drop any ticket key you cannot justify as "actively worked in the window" (a Step 2 or 2b claim, or a log entry) — when in doubt, cut it rather than include it.
- Before finalizing, drop any bullet that's only housekeeping, and check that no ticket key appears in more than one TODAY bullet. If one does, merge those bullets as described above. A key can still appear once in TODAY and once in FLAGS.
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

## Step 7 — Record the run and clear the log

Only do this if Step 5 created the draft. If Step 5 hit `draft_already_exists` or failed in any other way, skip this step entirely, so the next run still covers the same window and the same log entries.

Write `RUN_START` (from Step 1) as the new `last-run`, then drop every log entry before it. Entries logged after `RUN_START`, while this run was going, are kept for the next report:

```
mkdir -p ~/.claude/eod
printf '%s\n' "$RUN_START" > ~/.claude/eod/last-run
LOG=~/.claude/eod/linear-log.tsv
if [ -f "$LOG" ]; then
  awk -F'\t' -v s="$RUN_START" '$1 >= s' "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi
```
