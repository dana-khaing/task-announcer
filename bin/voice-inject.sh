#!/usr/bin/env bash
# Speaks-to-types: records your voice, transcribes it locally, and types the
# result into whichever app was frontmost when this script started (pressing
# Return to submit) — turning spoken instructions into a live Claude Code
# session's input, exactly as if typed by hand.
#
# Requires: sox (`rec`), whisper-cpp (`whisper-cli`), a downloaded ggml
# model, and this terminal app granted Accessibility permission. See README.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

MODEL="${VOICE_INJECT_MODEL:-$REPO_ROOT/models/ggml-base.en.bin}"
SILENCE_SECS="${VOICE_INJECT_SILENCE_SECS:-3.0}"

for bin in rec whisper-cli osascript; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "voice-inject: missing required command '$bin' — see README for install steps." >&2
    exit 1
  fi
done

if [ ! -f "$MODEL" ]; then
  echo "voice-inject: model not found at $MODEL — see README for the download step." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
TMP_WAV="$TMP_DIR/voice-inject.wav"
cleanup() {
  rm -rf "$TMP_DIR"
  echo ""
  echo "voice-inject: stopped."
}
trap cleanup EXIT INT TERM

TARGET_APP="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)"
if [ -z "$TARGET_APP" ]; then
  echo "voice-inject: couldn't determine the frontmost app — is Accessibility permission granted to this terminal? See README." >&2
  exit 1
fi

echo "voice-inject: listening. Speech will be typed into: $TARGET_APP"
echo "voice-inject: press Ctrl+C here to stop."
echo ""

# Escapes a string for safe interpolation into an AppleScript double-quoted
# string literal (backslash and double-quote are the two characters that
# matter there).
escape_for_applescript() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

while true; do
  rm -f "$TMP_WAV"
  rec -q "$TMP_WAV" silence 1 0.1 3% 1 "$SILENCE_SECS" 3% 2>/dev/null

  TEXT="$(whisper-cli -m "$MODEL" -f "$TMP_WAV" -nt -np 2>/dev/null | tr -s '[:space:]' ' ' | sed -E 's/^ +| +$//g')"

  if [ -z "$TEXT" ]; then
    continue
  fi

  echo ">>> $TEXT"

  ESCAPED_TEXT="$(escape_for_applescript "$TEXT")"
  ESCAPED_APP="$(escape_for_applescript "$TARGET_APP")"

  osascript \
    -e "tell application \"System Events\" to set frontmost of process \"${ESCAPED_APP}\" to true"
  sleep 0.3

  if ! osascript \
    -e "tell application \"System Events\" to keystroke \"${ESCAPED_TEXT}\"" \
    -e 'tell application "System Events" to key code 36'; then
    echo "voice-inject: keystroke injection failed — is Accessibility permission granted to this terminal app? See README." >&2
  fi
done
