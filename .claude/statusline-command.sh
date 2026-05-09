#!/usr/bin/env bash
# Claude Code status line — based on gnzh oh-my-zsh theme

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Show only the current directory name with a leading slash
short_cwd="/${cwd##*/}"

# GitHub account from GH_CONFIG_DIR (no gh CLI calls)
gh_account=""
if [[ "$GH_CONFIG_DIR" == *"gh-work"* ]]; then
  gh_account="$(printf '\033[32m')@bespinosa_mntv$(printf '\033[0m') "
elif [[ "$GH_CONFIG_DIR" == *"gh-personal"* ]]; then
  gh_account="$(printf '\033[32m')@brianespinosa$(printf '\033[0m') "
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

# Context remaining
ctx_part=""
if [ -n "$remaining" ]; then
  rounded=$(printf '%.0f' "$remaining")
  tick=$(( $(date +%s) % 2 ))
  if [ "$rounded" -le 10 ]; then
    # Cycle between yellow and red
    [ "$tick" -eq 0 ] && ctx_color='\033[33m' || ctx_color='\033[31m'
  elif [ "$rounded" -le 20 ]; then
    # Cycle between cyan and yellow
    [ "$tick" -eq 0 ] && ctx_color='\033[36m' || ctx_color='\033[33m'
  else
    ctx_color='\033[36m'  # cyan (steady)
  fi
  ctx_part=" $(printf "$ctx_color")[ctx: ${rounded}%]$(printf '\033[0m')"
fi

# Model
model_part=""
if [ -n "$model" ]; then
  model_part=" $(printf '\033[35m')[${model}]$(printf '\033[0m')"
fi

printf "%s$(printf '\033[1;34m')%s$(printf '\033[0m')%s%s%s" \
  "$gh_account" "$short_cwd" "$git_branch" "$ctx_part" "$model_part"
