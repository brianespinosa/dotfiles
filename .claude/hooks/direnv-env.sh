#!/bin/bash
# SessionStart hook: load the working directory's direnv environment into
# the session, so the Bash tool, hooks and subagents see the same variables
# a terminal would (GH_CONFIG_DIR, GIT_CONFIG_GLOBAL, ...).
#
# Claude Code runs the file named by CLAUDE_ENV_FILE before every Bash
# command. direnv prints bash export statements, so they are appended as is.
# The hook is silent and exits 0 whenever it has nothing to do: no
# CLAUDE_ENV_FILE, no direnv, no .envrc, or no cwd in the payload. A blocked
# .envrc gets one systemMessage that names the directory to allow.
set -u

[ -n "${CLAUDE_ENV_FILE:-}" ] || exit 0
command -v direnv >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null || true)
cwd=""
if command -v jq >/dev/null 2>&1; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
fi
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=$PWD

errfile=$(mktemp) || exit 0
trap 'rm -f "$errfile"' EXIT

exports=$(cd "$cwd" && direnv export bash 2>"$errfile")
status=$?

if [ "$status" -ne 0 ]; then
  if grep -q 'is blocked' "$errfile"; then
    msg="direnv: the .envrc for $cwd is blocked, so its variables are not loaded in this session. Run 'direnv allow' there, then start a new session."
    if command -v jq >/dev/null 2>&1; then
      jq -cn --arg m "$msg" '{systemMessage: $m}'
    else
      printf '{"systemMessage":"%s"}\n' "$msg"
    fi
  fi
  exit 0
fi

[ -n "$exports" ] || exit 0
printf '%s\n' "$exports" >> "$CLAUDE_ENV_FILE"
exit 0
