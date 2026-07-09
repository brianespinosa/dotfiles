#!/usr/bin/env bash
# gh-tidy-user-notifications.sh — mark non-actionable notifications as done
# Usage:
#   gh-tidy-user-notifications.sh
# Output:
#   One line per notification acted on: <repo> — <title> — <reason> — <url>
#   Final count, or "Nothing to tidy." if inbox was already clean.

set -euo pipefail

SEMVER_RE='^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
marked=0

GH_USER=$(gh api /user --jq '.login')

declare -A team_cache

# Returns space-separated team slugs for the current user in $1 (org login),
# fetching once and caching for subsequent calls.
user_teams_in_org() {
  local org="$1"
  if [[ -z "${team_cache[$org]+_}" ]]; then
    team_cache[$org]=$(gh api '/user/teams?per_page=100' --paginate \
      --jq --arg org "$org" '.[] | select(.organization.login == $org) | .slug' \
      2>/dev/null | tr '\n' ' ')
  fi
  echo "${team_cache[$org]}"
}

mark_done() {
  gh api --method DELETE "/notifications/threads/${1}" > /dev/null
}

while IFS=$'\t' read -r thread_id type title subject_url repo reason; do
  case "$type" in
    Release)
      result=$(gh api "$subject_url" --jq '[.tag_name // "", .html_url // ""] | @tsv' 2>/dev/null) || continue
      IFS=$'\t' read -r tag_name html_url <<< "$result"
      [[ -z "$tag_name" ]] && continue
      # Monorepos tag releases as <pkg>@<version>, e.g.
      # @tanstack/react-query@5.101.0 — the version is after the last '@'.
      # Plain tags (v1.2.3) have no '@' and pass through unchanged.
      version="${tag_name##*@}"
      if [[ ! "$version" =~ $SEMVER_RE ]]; then
        mark_done "$thread_id"
        printf '%s — %s — marked done (non-semver tag: %s) — %s\n' "$repo" "$title" "$tag_name" "$html_url"
        marked=$((marked + 1))
      fi
      ;;
    PullRequest)
      result=$(gh api "$subject_url" --jq '[.state // "", .html_url // ""] | @tsv' 2>/dev/null) || continue
      IFS=$'\t' read -r state html_url <<< "$result"
      [[ -z "$state" ]] && continue
      if [[ "$state" == "closed" ]]; then
        mark_done "$thread_id"
        printf '%s — %s — marked done (closed PR) — %s\n' "$repo" "$title" "$html_url"
        marked=$((marked + 1))
      elif [[ "$reason" == "review_requested" && "$state" == "open" ]]; then
        org="${repo%%/*}"
        user_teams=$(user_teams_in_org "$org")

        reviewer_data=$(gh api "$subject_url" --jq '
          [(.requested_reviewers // [] | .[].login),
           (.requested_teams    // [] | .[].slug)]
        ' 2>/dev/null) || continue

        directly_requested=$(echo "$reviewer_data" | jq --arg u "$GH_USER" 'contains([$u])')

        team_requested="false"
        for team in $user_teams; do
          if echo "$reviewer_data" | jq --exit-status --arg t "$team" 'contains([$t])' > /dev/null 2>&1; then
            team_requested="true"
            break
          fi
        done

        if [[ "$directly_requested" != "true" && "$team_requested" != "true" ]]; then
          mark_done "$thread_id"
          printf '%s — %s — marked done (review not assigned to you or your teams) — %s\n' "$repo" "$title" "$html_url"
          marked=$((marked + 1))
        fi
      fi
      ;;
    Issue)
      result=$(gh api "$subject_url" --jq '[.state // "", .html_url // ""] | @tsv' 2>/dev/null) || continue
      IFS=$'\t' read -r state html_url <<< "$result"
      [[ -z "$state" ]] && continue
      if [[ "$state" == "closed" ]]; then
        mark_done "$thread_id"
        printf '%s — %s — marked done (closed issue) — %s\n' "$repo" "$title" "$html_url"
        marked=$((marked + 1))
      fi
      ;;
  esac
done < <(gh api '/notifications?all=true' --paginate \
  --jq '.[] | [.id, .subject.type, .subject.title, .subject.url, .repository.full_name, .reason] | @tsv')

if (( marked == 0 )); then
  echo "Nothing to tidy."
else
  printf '\n%d notification(s) marked done.\n' "$marked"
fi
