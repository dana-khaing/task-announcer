#!/usr/bin/env bash
# Stop hook: speaks and shows a notification when Claude Code finishes responding.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/text-utils.sh
source "$SCRIPT_DIR/lib/text-utils.sh"

LEAD_IN="${TASK_ANNOUNCER_LEAD_IN:-Claude has finished the task.}"
VOICE_ENABLED="${TASK_ANNOUNCER_VOICE:-1}"
NOTIFY_ENABLED="${TASK_ANNOUNCER_NOTIFY:-1}"
SAY_VOICE="${TASK_ANNOUNCER_SAY_VOICE:-}"
SAY_RATE="${TASK_ANNOUNCER_SAY_RATE:-190}"
MAX_SPEECH_CHARS="${TASK_ANNOUNCER_MAX_CHARS:-420}"
MAX_NOTIFY_CHARS=180
DEBUG="${TASK_ANNOUNCER_DEBUG:-0}"
DEBUG_LOG="$HOME/.claude/task-announcer-debug.log"

INPUT="$(cat)"

if [ "$DEBUG" = "1" ]; then
  {
    echo "=== $(date -u +%FT%TZ) ==="
    echo "payload: $INPUT"
  } >> "$DEBUG_LOG"
fi

# Loop guard: a Stop hook must check stop_hook_active and bail out if true,
# otherwise it can re-trigger itself into Claude Code's 8x block cap.
STOP_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

SUMMARY=""
if command -v jq >/dev/null 2>&1; then
  # The Stop hook payload includes the final response text directly — no
  # need to parse the transcript ourselves in the common case.
  SUMMARY="$(printf '%s' "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)"
fi

if [ -z "$SUMMARY" ] && command -v jq >/dev/null 2>&1; then
  # Fallback for older Claude Code versions without last_assistant_message:
  # parse the transcript JSONL for the last assistant message's text blocks.
  TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
  if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    SUMMARY="$(jq -rs '
      [ .[] | select(.type == "assistant") ] | last
      | (.message.content // [])
      | map(select(.type == "text") | .text)
      | join(" ")
    ' "$TRANSCRIPT_PATH" 2>/dev/null)"
  fi
fi

if [ -n "$SUMMARY" ]; then
  CLEAN_SUMMARY="$(clean_text "$SUMMARY")"
  SPEECH_TEXT="${LEAD_IN} $(truncate_text "$CLEAN_SUMMARY" "$MAX_SPEECH_CHARS")"
  NOTIFY_TEXT="$(truncate_text "$CLEAN_SUMMARY" "$MAX_NOTIFY_CHARS")"
else
  SPEECH_TEXT="$LEAD_IN"
  NOTIFY_TEXT="Task complete."
fi

if [ "$DEBUG" = "1" ]; then
  echo "summary: $SUMMARY" >> "$DEBUG_LOG"
  echo "speech: $SPEECH_TEXT" >> "$DEBUG_LOG"
fi

# Speak and notify in the background so the hook returns immediately instead
# of blocking on ~15-20s of speech playback.
if [ "$VOICE_ENABLED" = "1" ] && command -v say >/dev/null 2>&1; then
  if [ -n "$SAY_VOICE" ]; then
    ( say -v "$SAY_VOICE" -r "$SAY_RATE" "$SPEECH_TEXT" & )
  else
    ( say -r "$SAY_RATE" "$SPEECH_TEXT" & )
  fi
fi

if [ "$NOTIFY_ENABLED" = "1" ] && command -v osascript >/dev/null 2>&1; then
  ESCAPED_NOTIFY="$(printf '%s' "$NOTIFY_TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  ( osascript -e "display notification \"${ESCAPED_NOTIFY}\" with title \"Claude Code\" subtitle \"Task complete\"" & )
fi

exit 0
