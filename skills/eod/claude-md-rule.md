## EOD issue log

Whenever I work on a Linear issue in any project (create it, write or review
code for it, investigate it, comment on it, or change its status), log it for
`/eod` by running:

```
~/.claude/eod/log-issue.sh <ISSUE-KEY> "<brief summary, under 15 words>"
```

- Log it when the work happens, not at the end of the session. Logging the same
  issue again later in a session is fine; `/eod` groups entries by key.
- The summary says what the issue is about and what was done, in plain words.
  Focus on substance (what was built, fixed, decided or found), not
  housekeeping like closing it or opening a PR. No file names or code details.
- Only log issues actually worked on. An issue that was only mentioned,
  searched, or looked at as related context doesn't count.
- Never edit or clear `~/.claude/eod/linear-log.tsv` by hand. `/eod` clears it.

### Work without a Linear issue

Work with no Linear issue can still belong in the EOD report. When a task has
no issue, always ask what to do, as soon as that's clear (usually at the
start), rather than deciding on my own. The usual answers:

- **Create a Linear issue for it**, then track and log it like any other issue.
- **Log it for EOD without an issue**, by running:

  ```
  ~/.claude/eod/log-issue.sh --no-issue "<project>" "<brief summary, under 15 words>"
  ```

  `<project>` is the plain name of the product or initiative (e.g.
  "Telemetry"), not a repo name. The same summary rules apply.
- **Neither.** Don't log it.

Ask once per task. Small follow-ups to the same task don't need a new question.
