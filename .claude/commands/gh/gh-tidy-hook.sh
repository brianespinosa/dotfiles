#!/bin/sh
# gh-tidy-hook.sh: SessionStart/SessionEnd wrapper for gh-tidy-user-notifications.sh
#
# #!/bin/sh deliberately: hooks run under /bin/sh with a minimal PATH, and
# this wrapper must not depend on Homebrew bash being resolvable.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
CACHE_DIR="$HOME/Library/Caches/gh-tidy-notifications"
LOG="$CACHE_DIR/tidy.log"
SCRIPT="$HOME/.claude/commands/gh/gh-tidy-user-notifications.sh"

# A hook must never error loudly into Claude Code's hook output.
mkdir -p "$CACHE_DIR" || exit 0

if [ -f "$LOG" ]; then
  size=$(stat -f %z "$LOG" 2>/dev/null || echo 0)
  if [ "$size" -gt 1048576 ]; then
    mv "$LOG" "$LOG.1" 2>>"$LOG" || true
  fi
fi

if command -v direnv >/dev/null 2>&1; then
  nohup direnv exec "$DIR" "$SCRIPT" </dev/null >>"$LOG" 2>&1 &
else
  nohup "$SCRIPT" </dev/null >>"$LOG" 2>&1 &
fi

exit 0
