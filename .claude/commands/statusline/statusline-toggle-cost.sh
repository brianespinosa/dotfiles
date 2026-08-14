#!/usr/bin/env bash
# Flip the statusline's enterprise budget segment between percentage and dollar
# display. State lives in ~/.claude/statusline-cost-mode (runtime state, not
# tracked by git or stowed) — statusline-command.sh reads it on every render.
set -euo pipefail

mode_file="$HOME/.claude/statusline-cost-mode"
current="pct"
[ -f "$mode_file" ] && current="$(cat "$mode_file")"

if [ "$current" = "dollar" ]; then
  next="pct"
else
  next="dollar"
fi

printf '%s' "$next" > "$mode_file"
printf 'Statusline cost display: %s\n' "$next"
