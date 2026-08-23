# task-announcer

A [Claude Code](https://claude.com/claude-code) plugin that speaks and
visually announces when Claude finishes responding, on macOS.

## What it does

- Hooks the `Stop` event (fires once Claude finishes responding to a turn).
- Speaks a short announcement via macOS `say`: a lead-in phrase
  ("Claude has finished the task.") followed by Claude's own final
  response for that turn — cleaned of markdown and trimmed to a
  speech-friendly length, not a canned generic phrase.
- Shows a matching native macOS notification banner with the same text.
- Falls back to a generic "Claude has finished the task" announcement if
  `jq` is missing or the response text can't be read, rather than erroring.

## Requirements

- macOS (uses `say` and `osascript`, both stock).
- [`jq`](https://jqlang.org) — used to parse the hook's JSON payload.
  Without it, the plugin still works but only speaks/shows the generic
  fallback phrase instead of the real response summary.
  ```
  brew install jq
  ```

## Install

```
/plugin marketplace add dana-khaing/task-announcer
/plugin install task-announcer@dana-khaing-plugins
```

## One-time manual setup: macOS notification permission

The notification banner is shown through `osascript`, running inside
whichever terminal app is running Claude Code (Terminal.app, iTerm2, etc).
The first time it fires, macOS may silently drop the banner and require you
to grant permission under **System Settings → Notifications → [your
terminal app]**. This can't be granted programmatically by the plugin —
enable it once, manually, after the first task completes. Voice
announcements don't need this permission and work regardless.

## Configuration

All optional, set as environment variables before starting Claude Code:

| Variable | Default | Purpose |
|---|---|---|
| `TASK_ANNOUNCER_VOICE` | `1` | Set to `0` to disable speech |
| `TASK_ANNOUNCER_NOTIFY` | `1` | Set to `0` to disable the notification banner |
| `TASK_ANNOUNCER_LEAD_IN` | `Claude has finished the task.` | Spoken lead-in phrase |
| `TASK_ANNOUNCER_SAY_VOICE` | (system default) | A macOS voice name, e.g. `Samantha` |
| `TASK_ANNOUNCER_SAY_RATE` | `190` | Speech rate in words per minute |
| `TASK_ANNOUNCER_MAX_CHARS` | `420` | Max characters spoken from the response |
| `TASK_ANNOUNCER_MAX_NOTIFY_CHARS` | `180` | Max characters shown in the notification banner |
| `TASK_ANNOUNCER_DEBUG` | `0` | Set to `1` to log payload + parsed summary to `~/.claude/task-announcer-debug.log` |
| `TASK_ANNOUNCER_PRESET` | (none) | Set to `jarvis` for a friendlier, varied lead-in phrase (see below) |

### The `jarvis` preset

```
TASK_ANNOUNCER_PRESET=jarvis
```

Swaps the fixed "Claude has finished the task." lead-in for a random pick
from a small pool of friendlier phrases ("All done!", "All set. Let me
know what's next.", etc.) — a different one each time, so it doesn't get
repetitive. `TASK_ANNOUNCER_LEAD_IN`, if also set, still wins over the
preset.

The preset deliberately does **not** change the voice. macOS Siri voices
are the closest thing to an actual Jarvis-style voice, but they're only
selectable as your Mac's system default voice (System Settings →
Accessibility → Spoken Content → Manage Voices → download a "Siri Voice
N" under English) — they can't be picked by name via `say -v`. So: set
your System Voice to a Siri voice yourself if you want that sound, and
leave `TASK_ANNOUNCER_SAY_VOICE` unset — the plugin will pick it up
automatically since it only overrides the voice when you explicitly set
`TASK_ANNOUNCER_SAY_VOICE`.

## Local development

Test without installing:

```
claude --plugin-dir /path/to/task-announcer
```

## Roadmap

See [ROADMAP.md](ROADMAP.md) — periodic "Claude is still working on X"
voice updates during long-running tasks are planned as a follow-up feature.

## License

MIT — see [LICENSE](LICENSE).
