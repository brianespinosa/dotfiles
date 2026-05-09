#!/usr/bin/env bash
# gh-rebase-prs.sh — rebase all open PRs that are BEHIND their target branch
# Usage:
#   gh-rebase-prs.sh repo  OWNER/REPO
#   gh-rebase-prs.sh org   ORG_OR_USER_LOGIN

set -euo pipefail

MODE="${1:?usage: gh-rebase-prs.sh <repo|org> <target>}"
TARGET="${2:?}"

rebase_behind_prs() {
  local repo="$1"
  local owner="${repo%%/*}"
  local name="${repo##*/}"

  local behind
  behind=$(gh api graphql \
    -f query='query($owner:String!,$name:String!){
      repository(owner:$owner,name:$name){
        pullRequests(first:100,states:[OPEN]){
          nodes{ number title isDraft mergeStateStatus }
        }
      }
    }' \
    -f owner="$owner" -f name="$name" \
    --jq '.data.repository.pullRequests.nodes[]
          | select(.isDraft==false and .mergeStateStatus=="BEHIND")
          | "\(.number)\t\(.title)"' 2>/dev/null) || return 0

  [[ -z "$behind" ]] && return 0

  while IFS=$'\t' read -r number title; do
    printf '%s #%s — %s — https://github.com/%s/pull/%s\n' "$repo" "$number" "$title" "$repo" "$number"
    if gh pr update-branch --rebase "$number" --repo "$repo" 2>&1; then
      printf '  ✓ rebased\n'
    else
      printf '  ✗ failed\n'
    fi
  done <<< "$behind"
}

case "$MODE" in
  repo)
    rebase_behind_prs "$TARGET"
    ;;
  org)
    while IFS= read -r repo; do
      rebase_behind_prs "$repo"
    done < <(gh repo list "$TARGET" --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 1
    ;;
esac

echo "Done."
