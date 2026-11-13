#!/usr/bin/env python3
"""Print a compact digest of Claude Code session activity inside a time window.

Usage: extract-window.py <WINDOW_START> <RUN_START>   (UTC ISO, e.g. 2026-11-04T21:00:30Z)

Replaces having subagents read whole transcripts: only lines whose own
`timestamp` is in [WINDOW_START, RUN_START) count (file mtime is just a
candidate filter), and only human prompts and assistant prose are kept.
Tool calls, tool results, thinking and system noise are dropped, and each
message is truncated. Output is grouped by project (the session's cwd).
Prints NO_ACTIVITY when nothing is in the window.
"""
import glob
import json
import os
import sys
import time
from collections import OrderedDict

MSG_CAP = 500        # chars kept per message
PROJECT_CAP = 12000  # chars kept per project (head and tail are kept)


def text_of(content, role):
    """Return the human-readable text of a message, or ''."""
    if isinstance(content, str):
        parts = [content]
    elif isinstance(content, list):
        parts = [b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"]
    else:
        return ""
    text = " ".join(" ".join(parts).split())
    # Slash-command wrappers, system reminders and other injected markup.
    if not text or text.startswith("<") or text.startswith("[Request interrupted"):
        return ""
    return text[:MSG_CAP] + ("..." if len(text) > MSG_CAP else "")


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    start, end = sys.argv[1], sys.argv[2]
    home = os.path.expanduser("~")
    home_project = home.replace("/", "-")
    last_run = os.path.join(home, ".claude", "eod", "last-run")
    cutoff = os.path.getmtime(last_run) if os.path.exists(last_run) else time.time() - 2 * 86400

    projects = OrderedDict()
    pattern = os.path.join(home, ".claude", "projects", "*", "*.jsonl")
    for path in sorted(glob.glob(pattern)):
        # The home-directory project is where this tooling lives, not work content.
        if os.path.basename(os.path.dirname(path)) == home_project:
            continue
        if os.path.getmtime(path) <= cutoff:
            continue
        lines, cwd = [], None
        with open(path, errors="replace") as fh:
            for raw in fh:
                try:
                    row = json.loads(raw)
                except ValueError:
                    continue
                cwd = cwd or row.get("cwd")
                ts = row.get("timestamp", "")
                if not (start <= ts < end) or row.get("isSidechain") or row.get("isMeta"):
                    continue
                kind = row.get("type")
                msg = row.get("message") or {}
                if kind not in ("user", "assistant") or not isinstance(msg, dict):
                    continue
                text = text_of(msg.get("content"), kind)
                if text:
                    lines.append("[%s] %s: %s" % (ts[11:16], "U" if kind == "user" else "A", text))
        if lines:
            key = os.path.basename((cwd or os.path.basename(os.path.dirname(path))).rstrip("/"))
            projects.setdefault(key, []).extend(lines)

    if not projects:
        print("NO_ACTIVITY")
        return
    for name, lines in projects.items():
        body = "\n".join(lines)
        if len(body) > PROJECT_CAP:
            half = PROJECT_CAP // 2
            body = body[:half] + "\n[... middle of the day trimmed ...]\n" + body[-half:]
        print("## %s\n%s\n" % (name, body))


if __name__ == "__main__":
    main()
