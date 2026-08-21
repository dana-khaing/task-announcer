# Diary

## 2026-08-20 — Repo scaffold

Set up the repo: `git init`, an empty bootstrap commit on `main` to
establish the default branch (there's no clean way to open a "first PR"
against a `main` with zero commits, so this one bootstrap commit is pure
git mechanics, not a feature), then the actual scaffold — `plugin.json`,
a self-hosted `marketplace.json` (the repo catalogs its own plugin via
`source: "./"`, no separate marketplace repo needed), MIT `LICENSE`,
`.gitignore`, and a README skeleton — went through a proper
`repo-scaffold` branch and PR (#1), merged locally with a backdated merge
commit per the date-per-feature convention this project follows.

Also set repository topics (`claude-code`, `claude-code-plugin`, `macos`,
`hooks`, `text-to-speech`, `productivity`) for discoverability.

## 2026-08-21 — Completion announcement

Built the real feature: the `Stop` hook (`hooks/hooks.json` →
`hooks/announce-completion.sh`), with markdown-cleaning/truncation
helpers in `hooks/lib/text-utils.sh`.

Notable decision, found through actually testing against a real headless
session (`claude --plugin-dir ... -p "..."`) rather than trusting the
docs alone: the `Stop` hook's JSON payload includes a `last_assistant_message`
field directly — Claude's final response text for the turn, already
extracted. I'd originally planned to parse the session's transcript JSONL
myself (and still do, as a fallback for older Claude Code versions
without that field), but using the payload field directly is simpler and
more robust than reaching into the transcript file. Confirmed this by
running a real session with the plugin loaded and inspecting the actual
Stop payload — it's not something the design should have assumed without
checking, since `transcript_path` and its parsing was the documented,
not-necessarily-current, approach.

Also confirmed empirically: `${CLAUDE_PLUGIN_ROOT}` is genuinely injected
into the hook's environment by the plugin runtime (the script wouldn't
have executed at all otherwise, since `hooks.json` references it) — no
fallback path resolution was needed.

Ran a full live test with real speech and a real notification banner —
confirmed by hand that both fired correctly (voice + visual, in that
session).

Wrote the full README (requirements, install, the manual macOS
notification-permission step, configuration table) and ROADMAP.md, which
documents the periodic "still working" progress-announcement idea as a
design only — deliberately not implemented yet, since it has a real
architectural blind spot (no hook fires during a long stretch of pure
text generation with no tool calls) that's worth thinking through
properly rather than rushing.
