# Roadmap

## Shipped

- **Completion announcement** — voice (`say`) + visual (`osascript`)
  announcement when Claude finishes responding, via the `Stop` hook. See
  [README.md](README.md).

## Planned: periodic "still working" progress announcements

The idea: while a long-running task is still in progress, periodically
speak something like "Claude is still working — currently editing
`foo.py`," so you don't have to keep checking the terminal.

### Why this isn't built yet

There is no Claude Code hook that fires purely on "time has passed while
Claude is still generating." The closest available signal is
`PostToolUse`, which fires after each individual tool call — there's
nothing that fires during a long stretch of pure text generation with no
tool calls in between. That's a real blind spot this design doesn't
solve, not an oversight.

### Design sketch (not yet implemented)

- A rate-limited `PostToolUse` hook (`hooks/announce-progress.sh`).
- Per-session state file at `~/.claude/state/task-announcer/<session_id>.json`
  tracking `last_announce_epoch` and `calls_since_last`.
- Only announce once **both** a minimum elapsed time (default 60s) and a
  minimum tool-call count (default 3) have passed since the last
  announcement — a dual gate that avoids spamming on a rapid burst of
  tool calls in a single second, while still not waiting arbitrarily long
  if calls are infrequent.
- Base the announcement on the most recent tool call's name/target (e.g.
  file path or command) rather than assistant prose — tool-call metadata
  is a more reliable "what is Claude doing right now" signal than text,
  which can lag behind actual actions during agentic loops.
- No visual banner on every progress tick — that would spam Notification
  Center. Reserve the visual banner for actual completion.
- Clean up the session's state file on `Stop` (reusing the hook already
  wired up for completion announcements), so state doesn't accumulate
  across sessions indefinitely.

### Open questions before implementing

- Whether `session_id` is present and stable in the `PostToolUse` payload
  the same way it is in `Stop` (confirmed present there) — needs
  verifying empirically, not assumed.
- Right defaults for the elapsed-time / tool-call-count gates — will
  likely need to ship as configurable env vars, same pattern as the
  completion-announcement feature, since there's no universally-right
  interval.
- A heavier alternative (a detached background poller started on session
  start, killed on session end) would close the "no tool calls" blind
  spot but introduces real orphaned-process risk if Claude Code exits
  before cleanup runs. Not worth the complexity unless the `PostToolUse`
  approach's blind spot proves to matter in practice.
