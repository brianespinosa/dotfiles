#!/usr/bin/env bash
# Format combined NDJSON from multiple gh-security-alerts.sh calls into a
# single EMU summary table, one row per org, sorted by total alerts descending.
# Usage: (for each org: gh-security-alerts.sh org $ORG) | gh-security-format-emu.sh

set -euo pipefail

declare -A ORG_CRITICAL=() ORG_HIGH=() ORG_MEDIUM=() ORG_LOW=() ORG_TOTAL=()

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  status=$(printf '%s' "$line" | jq -r '.status')
  [[ "$status" != "alerts" ]] && continue

  repo=$(printf '%s' "$line" | jq -r '.repo')
  org="${repo%/*}"

  crit=$(printf '%s' "$line" | jq '[.alerts[] | select(.severity == "critical")] | length')
  high=$(printf '%s' "$line" | jq '[.alerts[] | select(.severity == "high")] | length')
  med=$(printf '%s'  "$line" | jq '[.alerts[] | select(.severity == "medium")] | length')
  low=$(printf '%s'  "$line" | jq '[.alerts[] | select(.severity == "low")] | length')
  total=$(printf '%s' "$line" | jq '.total')

  ORG_CRITICAL[$org]=$(( ${ORG_CRITICAL[$org]:-0} + crit ))
  ORG_HIGH[$org]=$(( ${ORG_HIGH[$org]:-0} + high ))
  ORG_MEDIUM[$org]=$(( ${ORG_MEDIUM[$org]:-0} + med ))
  ORG_LOW[$org]=$(( ${ORG_LOW[$org]:-0} + low ))
  ORG_TOTAL[$org]=$(( ${ORG_TOTAL[$org]:-0} + total ))
done

if [[ ${#ORG_TOTAL[@]} -eq 0 ]]; then
  printf 'No open alerts.\n'
  exit 0
fi

# Sort orgs by total descending
SORTED=$(for org in "${!ORG_TOTAL[@]}"; do
  printf '%s %s\n' "${ORG_TOTAL[$org]}" "$org"
done | sort -rn)

printf '| Org | Critical | High | Medium | Low | Total |\n'
printf '|-----|----------|------|--------|-----|-------|\n'

while IFS=' ' read -r total org; do
  printf '| [%s](https://github.com/%s) | %s | %s | %s | %s | %s |\n' \
    "$org" "$org" \
    "${ORG_CRITICAL[$org]}" \
    "${ORG_HIGH[$org]}" \
    "${ORG_MEDIUM[$org]}" \
    "${ORG_LOW[$org]}" \
    "$total"
done <<< "$SORTED"
