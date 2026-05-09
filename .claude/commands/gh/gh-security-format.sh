#!/usr/bin/env bash
# Format NDJSON from gh-security-alerts.sh into a markdown security report.
# Usage: gh-security-alerts.sh user brianespinosa | gh-security-format.sh
#        gh-security-alerts.sh org myorg | gh-security-format.sh

set -euo pipefail

SEVERITY_ORDER=(critical high medium low)

DISABLED=()
FOUND=false

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  status=$(printf '%s' "$line" | jq -r '.status')
  repo=$(printf '%s' "$line" | jq -r '.repo')

  if [[ "$status" == "disabled" ]]; then
    is_fork=$(printf '%s' "$line" | jq -r '.fork // false')
    DISABLED+=("${repo}|${is_fork}")
    continue
  fi

  [[ "$status" != "alerts" ]] && continue

  FOUND=true
  total=$(printf '%s' "$line" | jq -r '.total')

  printf '\n**[%s](https://github.com/%s/security/dependabot)** — %s alerts\n\n' \
    "$repo" "$repo" "$total"
  printf '| Severity | Count | Packages (alerts) |\n'
  printf '|---|---|---|\n'

  for sev in "${SEVERITY_ORDER[@]}"; do
    label="$(tr '[:lower:]' '[:upper:]' <<< "${sev:0:1}")${sev:1}"

    printf '%s' "$line" | jq -r \
      --arg sev "$sev" \
      --arg label "$label" '
      .alerts as $all |
      [ $all[] | select(.severity == $sev) ] as $rows |
      if ($rows | length) == 0 then empty
      else
        ($rows | length) as $count |
        ($rows | group_by(.package) | map({p: .[0].package, n: length}) | sort_by(-.n)) as $pkgs |
        ($pkgs | map("`\(.p)` (\(.n))") | join(", ")) as $packages |
        "| **\($label)** | \($count) | \($packages) |"
      end
    '
  done

  printf '\n---\n'
done

if [[ "$FOUND" == false ]]; then
  printf '\nNo open Dependabot alerts found.\n'
fi

if [[ ${#DISABLED[@]} -gt 0 ]]; then
  printf '\n### Alerts not enabled\n\n'
  for entry in "${DISABLED[@]}"; do
    repo="${entry%|*}"
    is_fork="${entry#*|}"
    if [[ "$is_fork" == "true" ]]; then
      printf '[%s](https://github.com/%s) (fork)\n' "$repo" "$repo"
    else
      printf '[%s](https://github.com/%s)\n' "$repo" "$repo"
    fi
  done
fi
