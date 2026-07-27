#!/usr/bin/env bash
# Claude Code status line — based on gnzh oh-my-zsh theme
#
# Setup (one-time, after stow):
#   Ensure settings.json points to this script:
#     "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
#
# Usage stats are read from a cache file written by ~/.claude/usage-cache.sh,
# which is driven by launchd (co.bje.claude-statusline-usage, every 8 min).
# See usage-cache.sh for its own setup steps. No network calls happen here.

# jq's @tsv (tab-delimited) can't be used with bash `read` here: bash treats
# tab as IFS whitespace and collapses consecutive delimiters, silently
# dropping empty fields (e.g. a missing model name) and shifting the rest.
# "|" is not IFS whitespace, so empty fields are preserved correctly.
IFS='|' read -r cwd model remaining < <(jq -r '[
  (.workspace.current_dir // .cwd // ""),
  (.model.display_name // ""),
  (.context_window.remaining_percentage // "")
] | join("|")')

# Colorize $text with ANSI code $code, writing into variable $var (no subshell fork)
colorize() { printf -v "$1" '\033[%sm%s\033[0m' "$2" "$3"; }

# In a worktree, the path ends with .claude/worktrees/<branch> — redundant with
# the branch name. Collapse to the repo root so the path shows just the repo.
in_worktree=""
path_for_display="$cwd"
if [[ "$cwd" == */.claude/worktrees/* ]]; then
  in_worktree=1
  path_for_display="${cwd%%/.claude/worktrees/*}"
fi

# Format path: trim to @org/... if an @ segment exists, otherwise zsh %~
if [[ "$path_for_display" == */@* ]]; then
  display_cwd="${path_for_display##*/@}"
  display_cwd="@${display_cwd}"
elif [[ "$path_for_display" == "$HOME" ]]; then
  display_cwd="~"
elif [[ "$path_for_display" == "$HOME/"* ]]; then
  display_cwd="~${path_for_display#$HOME}"
else
  display_cwd="$path_for_display"
fi

# GitHub @username — derived from GH_CONFIG_DIR (set by direnv); no network call needed
if [[ "$GH_CONFIG_DIR" == *"work"* ]]; then
  gh_user="bespinosa_mntv"
else
  gh_user="brianespinosa"
fi
colorize user_colored 32 "$gh_user"
user_host="★${user_colored}"

# Bold blue current dir (gnzh: %B%F{blue}%~%f%b)
colorize dir_part '1;34' "$display_cwd"

# Claude usage stats (from cache; no network calls at render time)
usage_part=""
usage_cache="$HOME/Library/Caches/claude-statusline/usage.json"
if [ -f "$usage_cache" ]; then
  usage_text=$(python3 - "$usage_cache" <<'PYEOF'
import sys, json
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    plan = data.get('plan')
    rate_limited = data.get('rate_limited', False)

    # All budget metrics count down from 100% remaining to 0%, like ctx does.
    def color_for_remaining(pct):
        if rate_limited:
            # Usage endpoint is rate-limited (numbers may be stale) — dim
            # rather than colored, so it's distinct from the orange/red
            # "actually low on budget" signal.
            return '\033[2m'           # dim/muted
        elif pct <= 0:
            return '\033[31m'          # red
        elif pct < 10:
            return '\033[38;5;208m'    # orange
        elif pct < 30:
            return '\033[33m'          # yellow
        else:
            return '\033[32m'          # green

    def add_part(parts, remaining_pct, text):
        parts.append('{}[{}]\033[0m'.format(color_for_remaining(remaining_pct), text))

    parts = []
    if plan == 'max':
        five = data.get('five_hour')
        seven = data.get('seven_day')
        if five is not None:
            five_remaining = 100 - five
            add_part(parts, five_remaining, '5h: {}%'.format(five_remaining))
        if seven is not None:
            seven_remaining = 100 - seven
            add_part(parts, seven_remaining, '7d: {}%'.format(seven_remaining))
    elif plan == 'enterprise':
        remaining = data.get('spend_remaining')
        spend_pct_remaining = data.get('spend_pct_remaining')
        # cinder_cove is a one-time promotional credit, not a recurring
        # budget -- see the longer note in usage-cache.sh. usage-cache.sh
        # omits this key entirely once the API stops returning it, so
        # `cinder is not None` here naturally stops matching; no need to
        # special-case expiration on this side.
        cinder = data.get('cinder_cove')
        if remaining is not None and spend_pct_remaining is not None:
            add_part(parts, spend_pct_remaining, '💰 ${:.2f}'.format(remaining))
        if cinder is not None:
            cinder_remaining = 100 - cinder
            if cinder_remaining > 0:
                add_part(parts, cinder_remaining, '$crd: {}%'.format(cinder))
    if parts:
        print(' '.join(parts))
except Exception:
    pass
PYEOF
  )
  if [ -n "$usage_text" ]; then
    usage_part=" ${usage_text}"
  fi
fi

# Git branch (skip optional locks to avoid conflicts)
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" -c core.hooksPath=/dev/null rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    marker=${in_worktree:+🌲}
    colorize branch_colored 33 "‹${marker}${branch}›"
    git_branch=" ${branch_colored}"
  fi
fi

# Context remaining — steady cyan above 20%, yellow at 20%, pulses red at 10%
ctx_part=""
if [ -n "$remaining" ]; then
  printf -v rounded '%.0f' "$remaining"
  if [ "$rounded" -le 10 ]; then
    tick=$(( $(date +%s) % 2 ))
    [ "$tick" -eq 0 ] && ctx_code=33 || ctx_code=31
  elif [ "$rounded" -le 20 ]; then
    ctx_code=33
  else
    ctx_code=36
  fi
  colorize ctx_colored "$ctx_code" "[ctx: ${rounded}%]"
  ctx_part=" ${ctx_colored}"
fi

# Model
model_part=""
if [ -n "$model" ]; then
  colorize model_colored 35 "[${model}]"
  model_part=" ${model_colored}"
fi

printf "%s %s%s%s%s%s" \
  "$user_host" "$dir_part" "$git_branch" "$ctx_part" "$model_part" "$usage_part"
