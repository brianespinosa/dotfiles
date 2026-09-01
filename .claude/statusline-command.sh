#!/usr/bin/env bash
# Claude Code status line — based on gnzh oh-my-zsh theme
#
# Setup (one-time, after stow):
#   Ensure settings.json points to this script:
#     "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
#
# Usage stats are read from a shared cache written by the vu1-claude-token-usage
# poller (~/Library/Caches/claude-usage/usage.json, its own repo/ADR-0018).
# This script is a pure reader: no network calls and no credentials here. If
# the poller isn't running, the cache is missing/stale/malformed, or the
# schema version doesn't match, the usage segment is silently omitted.

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

# Claude usage stats (from the shared vu1-claude-token-usage cache; no
# network calls or credentials at render time — see the path-scoped rule
# for the full cache contract)
usage_part=""
usage_cache="$HOME/Library/Caches/claude-usage/usage.json"
cost_mode_file="$HOME/.claude/statusline-cost-mode"
cost_mode="pct"
[ -f "$cost_mode_file" ] && cost_mode="$(cat "$cost_mode_file")"
if [ -f "$usage_cache" ]; then
  usage_text=$(python3 - "$usage_cache" "$cost_mode" <<'PYEOF'
import sys, json
from datetime import datetime

cost_mode = sys.argv[2]

# 3x the poller's 300s poll cadence (ADR-0018 in vu1-claude-token-usage) —
# past this, a healthy-looking cached number is more likely stale than
# current, so treat it the same as an explicit rate-limit warning.
STALE_THRESHOLD_SECONDS = 900

def coerce_float(value):
    # Mirrors the vu1-claude-token-usage poller's own guard
    # (usage_cache._coerce_float). bool is an int subclass in Python, so
    # it must be rejected explicitly before accepting int/float — otherwise
    # a boolean field (e.g. a malformed remaining_dollars: true) silently
    # renders as 1.0.
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    return None

def clamp_pct(pct):
    return max(0, min(100, pct))

try:
    with open(sys.argv[1]) as f:
        data = json.load(f)

    version = data.get('version') if isinstance(data, dict) else None
    # Require an exact int 2: loose equality would also accept True (bool
    # is an int subclass) and 2.0 (float), neither of which is the schema
    # version the writer actually emits. Bumped from 1 to 2 by the
    # vu1-claude-token-usage poller's ADR-0021 (limits-array cutover):
    # the max section's five_hour/seven_day keys became session/week.
    valid_version = (
        isinstance(data, dict)
        and isinstance(version, int)
        and not isinstance(version, bool)
        and version == 2
    )
    if not valid_version:
        raise ValueError('missing or unsupported cache schema version')

    active_plan = data.get('active_plan')
    rate_limited = data.get('rate_limited', False)

    # The poller is now the only freshness signal: unlike the old
    # independent 480s-interval fetcher, a dead/unloaded poller or an
    # auth error (not just a 429) leaves this cache untouched forever, so
    # rate_limited alone isn't enough to catch "quietly gone stale".
    # updated_at is written by the poller on every successful publish AND
    # on rate-limit marks, so its age is a reliable liveness check. A
    # doc that is otherwise valid but has an absent/unparseable
    # updated_at is treated as stale too, since the writer always sets it.
    stale = True
    updated_at = data.get('updated_at')
    if isinstance(updated_at, str):
        try:
            ts = datetime.fromisoformat(updated_at.replace('Z', '+00:00'))
            if ts.tzinfo is not None:
                age_seconds = (datetime.now(ts.tzinfo) - ts).total_seconds()
                stale = age_seconds > STALE_THRESHOLD_SECONDS
        except ValueError:
            stale = True

    dim = rate_limited or stale

    # All budget metrics count down from 100% remaining to 0%, like ctx does.
    def color_for_remaining(pct):
        if dim:
            # Either explicitly rate-limited or stale past the threshold
            # above — dim rather than colored, so it's distinct from the
            # orange/red "actually low on budget" signal.
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
    if active_plan == 'max':
        max_section = data.get('max')
        if max_section is not None:
            session = max_section.get('session')
            if session is not None:
                session_util = coerce_float(session.get('utilization'))
                if session_util is not None:
                    session_remaining = clamp_pct(round(100 - session_util))
                    add_part(parts, session_remaining, '5h: {}%'.format(session_remaining))
            week = max_section.get('week')
            if week is not None:
                week_util = coerce_float(week.get('utilization'))
                if week_util is not None:
                    week_remaining = clamp_pct(round(100 - week_util))
                    add_part(parts, week_remaining, '7d: {}%'.format(week_remaining))
            fable = max_section.get('fable')
            if fable is not None:
                fable_util = coerce_float(fable.get('utilization'))
                if fable_util is not None:
                    fable_remaining = clamp_pct(round(100 - fable_util))
                    add_part(parts, fable_remaining, '🤓 {}%'.format(fable_remaining))
    elif active_plan == 'enterprise':
        enterprise_section = data.get('enterprise')
        if enterprise_section is not None:
            spend = enterprise_section.get('spend')
            if spend is not None:
                remaining_dollars = coerce_float(spend.get('remaining_dollars'))
                percent = coerce_float(spend.get('percent'))
                if remaining_dollars is not None and percent is not None:
                    pct_remaining = clamp_pct(round(100 - percent))
                    if cost_mode == 'dollar':
                        add_part(parts, pct_remaining, '💰 ${:.2f}'.format(remaining_dollars))
                    else:
                        add_part(parts, pct_remaining, '💰 {}%'.format(pct_remaining))
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
    marker=${in_worktree:+🌲 }
    colorize branch_colored 33 "‹${branch}›"
    git_branch=" ${marker}${branch_colored}"
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
  colorize ctx_colored "$ctx_code" "[🧠 ${rounded}%]"
  ctx_part=" ${ctx_colored}"
fi

# Model
model_part=""
if [ -n "$model" ]; then
  colorize model_colored 35 "[${model}]"
  model_part=" ${model_colored}"
fi

printf "%s %s%s%s%s%s" \
  "$user_host" "$dir_part" "$git_branch" "$model_part" "$ctx_part" "$usage_part"
