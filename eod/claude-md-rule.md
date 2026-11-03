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
