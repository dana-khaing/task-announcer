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

## 2026-08-22 — Refactor & refine pass

Surveyed the repo before its initial release. It's small (~110 lines
across the hook script and its helper), so I stayed strict about only
fixing things with a real, evidenced cost rather than manufacturing
busywork on a codebase this size. Two things qualified:

- `text-utils.sh` had a dead regex — an anchored `s/^#+ //g` that never
  fired anything the following unanchored `s/#+//g` didn't already
  cover. Confirmed by re-checking the actual markdown-cleanup output
  from Day 2's live test before removing it.
- `MAX_NOTIFY_CHARS` was the one hardcoded value in
  `announce-completion.sh` that didn't follow the `TASK_ANNOUNCER_*`
  env-var pattern every other setting uses — inconsistent with itself
  and with the README's config table. Made it configurable
  (`TASK_ANNOUNCER_MAX_NOTIFY_CHARS`) and documented it.

Also folded in a small duplicate `command -v jq` check while touching
that block. Re-ran the same real-transcript regression test used on Day
2 afterward — output was identical, confirming none of this changed
observable behavior.
