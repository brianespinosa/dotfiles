#!/usr/bin/env bash
# gh-tidy-user-notifications.sh — mark non-actionable notifications as done
# Usage:
#   gh-tidy-user-notifications.sh [--force]
# Output:
#   One line per notification acted on: <repo> — <title> — <reason> — <url>
#   Final count, or "Nothing to tidy." if inbox was already clean.
#
# Windows each run with `since=<last_run>` (per-account cache) instead of
# paging the full notification history. --force bypasses the 5-minute
# throttle only, not the window. A full pass runs automatically when no
# cache exists, the cache fails to parse, or the last full pass is more
# than 7 days old (since misses state changes with no new thread activity).

set -euo pipefail

CACHE_DIR="$HOME/Library/Caches/gh-tidy-notifications"
CACHE_VERSION=1
THROTTLE_SECS=300
LOCK_STALE_SECS=1800
SINCE_OVERLAP_SECS=300
FULL_PASS_MAX_AGE=$((7 * 86400))

SEMVER_RE='^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
TEAM_FETCH_FAILED='__FETCH_FAILED__'
marked=0
skipped=0
CACHE_TMP=""

force=0
if [[ "${1:-}" == "--force" ]]; then
  force=1
fi

GH_USER=$(gh api /user --jq '.login')
[[ -n "$GH_USER" && "$GH_USER" != "null" ]] || { echo "ERROR: could not resolve gh login" >&2; exit 1; }

declare -A team_cache

mkdir -p "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/$GH_USER.json"

# A missing file, parse failure, or version mismatch all yield empty,
# which is treated as "no prior run" further down.
last_run_epoch=""
last_full_run_epoch=""
if [[ -f "$CACHE_FILE" ]]; then
  last_run_epoch=$(jq -r --argjson v "$CACHE_VERSION" 'select(.version == $v) | .last_run_epoch // empty' "$CACHE_FILE" 2>/dev/null) || last_run_epoch=""
  last_full_run_epoch=$(jq -r --argjson v "$CACHE_VERSION" 'select(.version == $v) | .last_full_run_epoch // empty' "$CACHE_FILE" 2>/dev/null) || last_full_run_epoch=""
fi
# Anything other than a bare integer (float, string, multi-doc parse) is treated as no prior run.
[[ "$last_run_epoch" =~ ^[0-9]+$ ]] || last_run_epoch=""
[[ "$last_full_run_epoch" =~ ^[0-9]+$ ]] || last_full_run_epoch=""

# Captured before listing so notifications updated mid-run land in the next window.
run_start_epoch=$(date +%s)

if [[ -n "$last_run_epoch" ]]; then
  elapsed=$((run_start_epoch - last_run_epoch))
  if (( elapsed < 0 )); then
    # Future-dated cache (clock stepped back): not a valid prior run.
    last_run_epoch=""
  elif [[ $force -ne 1 ]] && (( elapsed < THROTTLE_SECS )); then
    echo "Throttled (last run ${elapsed}s ago; retry after ${THROTTLE_SECS}s total). Use --force to override."
    exit 0
  fi
fi

# Fatal signals don't run the EXIT trap by themselves; route them through it
# so a killed detached run still releases the lock.
trap 'exit 129' HUP INT TERM

LOCK_DIR="$CACHE_DIR/$GH_USER.lock"
LOCK_BUSY_MSG="Another tidy run is already in progress; skipping."
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  lock_mtime=$(stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0)
  lock_age=$(( $(date +%s) - lock_mtime ))
  reclaimed=0
  if (( lock_age > LOCK_STALE_SECS )); then
    # Rename-then-remove: of two concurrent contenders, only one mv can win,
    # so only one reclaims the lock. Plain rmdir+mkdir would race both through.
    if mv "$LOCK_DIR" "$LOCK_DIR.reclaim.$$" 2>/dev/null; then
      rmdir "$LOCK_DIR.reclaim.$$" 2>/dev/null || true
      mkdir "$LOCK_DIR" 2>/dev/null && reclaimed=1
    fi
  fi
  if (( reclaimed == 1 )); then
    echo "Reclaimed stale lock (${lock_age}s old)." >&2
  else
    echo "$LOCK_BUSY_MSG"
    exit 0
  fi
fi
trap 'rm -f "${CACHE_TMP:-}"; rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

notifications_url="/notifications?all=true"
is_full_pass=1
if [[ -n "$last_run_epoch" && -n "$last_full_run_epoch" ]] \
  && (( run_start_epoch - last_full_run_epoch < FULL_PASS_MAX_AGE )); then
  since_epoch=$((last_run_epoch - SINCE_OVERLAP_SECS))
  since_iso=$(date -u -r "$since_epoch" +%Y-%m-%dT%H:%M:%SZ)
  notifications_url="${notifications_url}&since=${since_iso}"
  is_full_pass=0
fi

# Returns space-separated team slugs for the current user in $1 (org login),
# fetching once and caching for subsequent calls. Caches $TEAM_FETCH_FAILED on
# fetch failure so callers can distinguish "no teams" from "unknown teams".
user_teams_in_org() {
  local org="$1" teams
  if [[ -z "${team_cache[$org]+_}" ]]; then
    # gh api has no --arg; the org is interpolated directly into the jq filter.
    if teams=$(gh api '/user/teams?per_page=100' --paginate \
      --jq ".[] | select(.organization.login == \"$org\") | .slug" 2>/dev/null); then
      team_cache[$org]=$(tr '\n' ' ' <<< "$teams")
    else
      team_cache[$org]="$TEAM_FETCH_FAILED"
    fi
  fi
  echo "${team_cache[$org]}"
}

mark_done() {
  gh api --method DELETE "/notifications/threads/${1}" > /dev/null
}

# Capture the listing up front and gate on its exit status: a failed listing
# (rate limit, network, auth) must not fall through as zero rows processed,
# which would advance the cache as if the run had succeeded.
listing=$(gh api "$notifications_url" --paginate \
  --jq '.[] | [.id, .subject.type, .subject.title, .subject.url, .repository.full_name, .reason] | @tsv') || {
  echo "ERROR: notification listing failed; cache not advanced." >&2
  exit 1
}

if [[ -n "$listing" ]]; then
while IFS=$'\t' read -r thread_id type title subject_url repo reason; do
  case "$type" in
    Release)
      result=$(gh api "$subject_url" --jq '[.tag_name // "", .html_url // ""] | @tsv' 2>/dev/null) || {
        printf 'skip: fetch failed for %s %s\n' "$repo" "$title" >&2
        skipped=$((skipped + 1))
        continue
      }
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
      result=$(gh api "$subject_url" --jq '[.state // "", .html_url // ""] | @tsv' 2>/dev/null) || {
        printf 'skip: fetch failed for %s %s\n' "$repo" "$title" >&2
        skipped=$((skipped + 1))
        continue
      }
      IFS=$'\t' read -r state html_url <<< "$result"
      [[ -z "$state" ]] && continue
      if [[ "$state" == "closed" ]]; then
        mark_done "$thread_id"
        printf '%s — %s — marked done (closed PR) — %s\n' "$repo" "$title" "$html_url"
        marked=$((marked + 1))
      elif [[ "$reason" == "review_requested" && "$state" == "open" ]]; then
        org="${repo%%/*}"
        user_teams=$(user_teams_in_org "$org")

        if [[ "$user_teams" == "$TEAM_FETCH_FAILED" ]]; then
          printf 'skip: team lookup failed for %s %s\n' "$repo" "$title" >&2
          skipped=$((skipped + 1))
          continue
        fi

        reviewer_data=$(gh api "$subject_url" --jq '
          [(.requested_reviewers // [] | .[].login),
           (.requested_teams    // [] | .[].slug)]
        ' 2>/dev/null) || {
          printf 'skip: fetch failed for %s %s\n' "$repo" "$title" >&2
          skipped=$((skipped + 1))
          continue
        }

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
      result=$(gh api "$subject_url" --jq '[.state // "", .html_url // ""] | @tsv' 2>/dev/null) || {
        printf 'skip: fetch failed for %s %s\n' "$repo" "$title" >&2
        skipped=$((skipped + 1))
        continue
      }
      IFS=$'\t' read -r state html_url <<< "$result"
      [[ -z "$state" ]] && continue
      if [[ "$state" == "closed" ]]; then
        mark_done "$thread_id"
        printf '%s — %s — marked done (closed issue) — %s\n' "$repo" "$title" "$html_url"
        marked=$((marked + 1))
      fi
      ;;
  esac
done <<< "$listing"
fi

if (( marked == 0 )); then
  echo "Nothing to tidy."
else
  printf '\n%d notification(s) marked done.\n' "$marked"
fi
if (( skipped > 0 )); then
  printf '%d notification(s) skipped due to fetch failures.\n' "$skipped"
fi

if [[ $is_full_pass -eq 1 ]]; then
  new_full_run_epoch=$run_start_epoch
else
  new_full_run_epoch=$last_full_run_epoch
fi

# A cache write failure must never turn a successful tidy into a script error.
# CACHE_TMP is a global (not local) so the EXIT trap can remove an orphaned
# temp file if the script is killed between mktemp and mv.
write_cache() {
  CACHE_TMP=$(mktemp "$CACHE_DIR/${GH_USER}.XXXXXX") || return 1
  jq -n \
    --argjson version "$CACHE_VERSION" \
    --arg last_run_iso "$(date -u -r "$run_start_epoch" +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson last_run_epoch "$run_start_epoch" \
    --argjson last_full_run_epoch "$new_full_run_epoch" \
    '{version: $version, last_run_iso: $last_run_iso, last_run_epoch: $last_run_epoch, last_full_run_epoch: $last_full_run_epoch}' \
    > "$CACHE_TMP" || { rm -f "$CACHE_TMP"; CACHE_TMP=""; return 1; }
  chmod 600 "$CACHE_TMP"
  mv "$CACHE_TMP" "$CACHE_FILE"
  CACHE_TMP=""
}
write_cache || echo "Warning: failed to update notification cache." >&2
