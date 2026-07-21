#!/usr/bin/env bash
# Claude Code status line — based on gnzh oh-my-zsh theme
#
# Setup (one-time, after stow):
#   Ensure settings.json points to this script:
#     "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
#
# Usage stats are read from a cache file written by ~/.claude/usage-cache.sh,
# which is driven by launchd (co.bje.claude-statusline-usage, every 5 min).
# See usage-cache.sh for its own setup steps. No network calls happen here.

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Format path: trim to @org/... if an @ segment exists, otherwise zsh %~
if [[ "$cwd" == */@* ]]; then
  display_cwd="${cwd##*/@}"
  display_cwd="@${display_cwd}"
elif [[ "$cwd" == "$HOME" ]]; then
  display_cwd="~"
elif [[ "$cwd" == "$HOME/"* ]]; then
  display_cwd="~${cwd#$HOME}"
else
  display_cwd="$cwd"
fi

# GitHub @username — derived from GH_CONFIG_DIR (set by direnv); no network call needed
if [[ "$GH_CONFIG_DIR" == *"work"* ]]; then
  gh_user="bespinosa_mntv"
else
  gh_user="brianespinosa"
fi
user_host="$(printf '\033[36m')@$(printf '\033[32m')${gh_user}$(printf '\033[0m')"

# Bold blue current dir (gnzh: %B%F{blue}%~%f%b)
dir_part="$(printf '\033[1;34m')${display_cwd}$(printf '\033[0m')"

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
    if plan == 'max':
        five = data.get('five_hour')
        seven = data.get('seven_day')
        parts = []
        if five is not None:
            parts.append('5h:{}%'.format(five))
        if seven is not None:
            parts.append('7d:{}%'.format(seven))
        if parts:
            print('\033[33m[{}]\033[0m'.format(' '.join(parts)))
    elif plan == 'enterprise':
        remaining = data.get('spend_remaining')
        cinder = data.get('cinder_cove')
        rl = data.get('rate_limited', False)
        orange = '\033[38;5;208m'
        parts = []
        if remaining is not None:
            if remaining <= 0:
                color = '\033[31m'
            elif rl:
                color = orange
            else:
                color = '\033[32m'
            parts.append('{}[💰 ${:.2f}]\033[0m'.format(color, remaining))
        if cinder is not None:
            if cinder >= 100:
                color = '\033[31m'
            elif rl:
                color = orange
            else:
                color = '\033[38;5;147m'
            parts.append('{}[$crd: {}%]\033[0m'.format(color, cinder))
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
    git_branch=" $(printf '\033[33m')‹${branch}›$(printf '\033[0m')"
  fi
fi

# Context remaining — steady cyan above 20%, yellow at 20%, pulses red at 10%
ctx_part=""
if [ -n "$remaining" ]; then
  rounded=$(printf '%.0f' "$remaining")
  tick=$(( $(date +%s) % 2 ))
  if [ "$rounded" -le 10 ]; then
    [ "$tick" -eq 0 ] && ctx_color='\033[33m' || ctx_color='\033[31m'
  elif [ "$rounded" -le 20 ]; then
    ctx_color='\033[33m'
  else
    ctx_color='\033[36m'
  fi
  ctx_part=" $(printf "$ctx_color")[ctx: ${rounded}%]$(printf '\033[0m')"
fi

# Model
model_part=""
if [ -n "$model" ]; then
  model_part=" $(printf '\033[35m')[${model}]$(printf '\033[0m')"
fi

printf "%s %s%s%s%s%s" \
  "$user_host" "$dir_part" "$git_branch" "$ctx_part" "$model_part" "$usage_part"
