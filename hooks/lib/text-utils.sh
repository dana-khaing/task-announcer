#!/usr/bin/env bash
# Sourced by announce-completion.sh. Provides clean_text() and truncate_text().

# Strips markdown noise so `say` doesn't read out literal asterisks,
# backticks, headers, or list dashes, and collapses whitespace/newlines.
clean_text() {
  printf '%s' "$1" \
    | tr '\n' ' ' \
    | sed -E 's/```[a-zA-Z]*//g; s/`//g; s/\*\*//g; s/\*//g; s/^#+ //g; s/#+//g' \
    | sed -E 's/\[([^]]*)\]\(([^)]*)\)/\1/g' \
    | sed -E 's/^[[:space:]]*[-•][[:space:]]+//g' \
    | tr -s ' '
}

# Truncates $1 to at most $2 characters, cutting at the nearest word
# boundary rather than mid-word.
truncate_text() {
  local text="$1" max="$2"
  if [ "${#text}" -le "$max" ]; then
    printf '%s' "$text"
  else
    printf '%s' "${text:0:$max}" | sed -E 's/[[:space:]]+[^ ]*$//'
  fi
}
