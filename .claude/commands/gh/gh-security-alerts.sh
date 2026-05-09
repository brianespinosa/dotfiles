#!/usr/bin/env bash
# Fetch GitHub Dependabot security alerts for a user or org.
# Usage: gh-security-alerts.sh user <login>
#        gh-security-alerts.sh org <org-name>
#        gh-security-alerts.sh repo <owner/repo>
# Output: NDJSON — one JSON object per repo
#   {"repo":"owner/repo","status":"alerts","total":N,"alerts":[{"severity":"high","package":"pkg"},...]}
#   {"repo":"owner/repo","status":"clean"}
#   {"repo":"owner/repo","status":"disabled","fork":true}

set -euo pipefail

TYPE="${1:-}"
NAME="${2:-}"

if [ -z "$TYPE" ] || [ -z "$NAME" ]; then
  printf '{"error":"Usage: gh-security-alerts.sh user <login> | org <org-name> | repo <owner/repo>"}\n' >&2
  exit 1
fi

# Org-alerts: single paginated call for all open alerts in an org — used by EMU context.
# Returns only repos with open alerts (no disabled/clean entries).
if [ "$TYPE" = "org-alerts" ]; then
  gh api "/orgs/$NAME/dependabot/alerts?state=open&per_page=100" --paginate \
    | jq -c '
        group_by(.repository.full_name) | .[] |
        {
          repo:   .[0].repository.full_name,
          status: "alerts",
          total:  length,
          alerts: [.[] | {severity: .security_advisory.severity, package: .dependency.package.name}]
        }
      ' 2>/dev/null
  exit 0
fi

# Fetch repo list as JSON array of {full_name, fork} objects
if [ "$TYPE" = "user" ]; then
  REPOS=$(gh api '/user/repos?type=owner' --paginate --jq '[.[] | {full_name, fork}]' 2>/dev/null)
elif [ "$TYPE" = "org" ]; then
  REPOS=$(gh api "/orgs/$NAME/repos" --paginate --jq '[.[] | {full_name, fork}]' 2>/dev/null)
elif [ "$TYPE" = "repo" ]; then
  REPOS=$(gh api "/repos/$NAME" --jq '[{full_name, fork}]' 2>/dev/null)
else
  printf '{"error":"Unknown type: %s — use user, org, org-alerts, or repo"}\n' "$TYPE" >&2
  exit 1
fi

if [ -z "$REPOS" ] || [ "$REPOS" = "[]" ]; then
  exit 0
fi

# Fetch alerts for all repos in parallel, writing one result file per repo
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

while IFS= read -r repo_entry; do
  [ -z "$repo_entry" ] && continue
  repo=$(printf '%s' "$repo_entry" | jq -r '.full_name')
  is_fork=$(printf '%s' "$repo_entry" | jq -r '.fork')
  safe=$(printf '%s' "$repo" | tr '/' '_')
  (
    response=$(gh api "/repos/$repo/dependabot/alerts?state=open&per_page=100" 2>&1) || true
    if printf '%s' "$response" | grep -q '"Dependabot alerts are disabled'; then
      printf '{"repo":"%s","status":"disabled","fork":%s}\n' "$repo" "$is_fork"
    else
      printf '%s' "$response" | jq -c --arg repo "$repo" '
        if type == "array" and length > 0 then
          {
            repo: $repo,
            status: "alerts",
            total: length,
            alerts: [.[] | {severity: .security_advisory.severity, package: .dependency.package.name}]
          }
        else
          {repo: $repo, status: "clean"}
        end
      ' 2>/dev/null || printf '{"repo":"%s","status":"clean"}\n' "$repo"
    fi
  ) > "$WORK/${safe}.json" &
done < <(printf '%s' "$REPOS" | jq -c '.[]')

wait
cat "$WORK"/*.json 2>/dev/null || true
