#!/usr/bin/env bash
# Fetch Claude API usage and write to cache for statusline display.
# Called by launchd (co.bje.claude-statusline-usage) every 5 minutes.
#
# Setup (one-time, after stow):
#   chmod +x ~/.claude/usage-cache.sh
#   launchctl load ~/Library/LaunchAgents/co.bje.claude-statusline-usage.plist
#
# The launchd plist lives at Library/LaunchAgents/co.bje.claude-statusline-usage.plist
# in this dotfiles repo and is symlinked to ~/Library/LaunchAgents/ via stow.
# RunAtLoad=true means the first cache fetch runs immediately on launchctl load.
#
# Reads the Claude Code OAuth token from the macOS keychain item
# "Claude Code-credentials". Uses curl (not urllib) so corporate TLS
# interception on enterprise accounts does not break cert verification.

CACHE_DIR="$HOME/Library/Caches/claude-statusline"
CACHE_FILE="$CACHE_DIR/usage.json"
TS=$(date +%s)

mkdir -p "$CACHE_DIR"

write_unknown() {
  printf '{ "plan": "unknown", "ts": %s }\n' "$TS" > "$CACHE_FILE"
}

# Get OAuth token from keychain
token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])" 2>/dev/null)

if [ -z "$token" ]; then
  write_unknown
  exit 0
fi

# Fetch usage from API (curl uses system cert store; works with corporate TLS interception)
# -s only (no -f): capture error bodies so Python can inspect and skip on rate-limit/auth errors
response=$(curl -s \
  -H "Authorization: Bearer $token" \
  -H "anthropic-beta: oauth-2025-04-20" \
  "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

if [ -z "$response" ]; then
  # Network failure — keep existing cache rather than clobbering with unknown
  [ -f "$CACHE_FILE" ] || write_unknown
  exit 0
fi

# Write response to temp file so python can read it from stdin (heredoc) and argv
TMPFILE=$(mktemp)
printf '%s' "$response" > "$TMPFILE"

python3 - "$CACHE_FILE" "$TS" "$TMPFILE" <<'PYEOF'
import sys, json

cache_file = sys.argv[1]
ts = int(sys.argv[2])
response_file = sys.argv[3]

try:
    with open(response_file) as f:
        data = json.load(f)

    # Rate limit or other error — stamp existing cache with rate_limited flag
    if data.get('error'):
        try:
            with open(cache_file) as f:
                existing = json.load(f)
            existing['rate_limited'] = True
            existing['ts'] = ts
            with open(cache_file, 'w') as f:
                json.dump(existing, f)
                f.write('\n')
        except Exception:
            pass
        sys.exit(0)

    spend = data.get('spend') or {}
    five_hour = data.get('five_hour')

    # The API always returns a `spend` object, even for Max plan accounts —
    # it's just disabled (enabled: false, limit: null). Only treat this as
    # an enterprise/budget account when spend is actually enabled with a
    # real limit; otherwise fall through to the five_hour/seven_day check.
    is_enterprise = bool(spend.get('enabled')) and spend.get('limit') is not None

    if is_enterprise:
        # Enterprise plan: spend tracking enabled with a real limit
        used = spend.get('used') or {}
        limit = spend.get('limit') or {}
        exponent = used.get('exponent', 2)
        spend_used = used.get('amount_minor', 0) / (10 ** exponent)
        spend_limit = limit.get('amount_minor', 0) / (10 ** limit.get('exponent', 2))
        spend_remaining = round(spend_limit - spend_used, 2)
        spend_pct_remaining = round(100 - spend.get('percent', 0))
        cinder_cove = data.get('cinder_cove') or {}
        cinder_pct = round(cinder_cove.get('utilization', 0))
        result = {
            "plan": "enterprise",
            "spend_remaining": spend_remaining,
            "spend_pct_remaining": spend_pct_remaining,
            "cinder_cove": cinder_pct,
            "rate_limited": False,
            "ts": ts
        }
    elif five_hour is not None:
        # Max plan: non-null five_hour field
        five_pct = round(five_hour.get('utilization', 0))
        seven_day = data.get('seven_day') or {}
        seven_pct = round(seven_day.get('utilization', 0))
        result = {
            "plan": "max",
            "five_hour": five_pct,
            "seven_day": seven_pct,
            "rate_limited": False,
            "ts": ts
        }
    else:
        result = {"plan": "unknown", "ts": ts}

    with open(cache_file, 'w') as f:
        json.dump(result, f)
        f.write('\n')

except Exception:
    with open(cache_file, 'w') as f:
        f.write('{{"plan": "unknown", "ts": {}}}\n'.format(ts))
PYEOF

rm -f "$TMPFILE"
