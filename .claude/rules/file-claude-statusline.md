---
paths:
  - "**/.claude/statusline-command.sh"
---

# Claude Code Statusline Usage Data

`statusline-command.sh` is a pure reader of a shared cache file at
`~/Library/Caches/claude-usage/usage.json`. It makes no network calls and
holds no credentials — fetching, OAuth, and the `/api/oauth/usage` endpoint
details all live in the `vu1-claude-token-usage` repo (same owner), whose
poller is the sole writer of this cache (see that repo's ADR-0018 and
`docs/research/` for endpoint-specific knowledge). This repo does not need
to know how the cache is produced, only its contract.

## Cache contract (schema `version: 2`)

```json
{
  "version": 2,
  "active_plan": "max" | "enterprise" | "unknown",
  "rate_limited": false,
  "updated_at": "...",
  "max": {
    "session": {"utilization": 43.5, "resets_at": "..."} | null,
    "week": {"utilization": 12.0, "resets_at": null} | null,
    "fetched_at": "..."
  },
  "enterprise": {
    "spend": {"percent": 25.0, "used_dollars": 20.0, "limit_dollars": 80.0, "remaining_dollars": 60.0} | null,
    "fetched_at": "..."
  }
}
```

- Always check `version == 2` before trusting the rest of the document. A
  missing file, unreadable file, malformed JSON, non-object root, or a
  version other than `2` must all silently produce no usage segment — this
  is also the expected degradation path on any machine that isn't running
  the poller.
- `max` and `enterprise` are independently optional (a plan section is
  absent if it has never been fetched). Within each section, individual
  fields (e.g. `session`, `week`, `spend`) can be `null` — render
  only the parts with non-null data, and skip a plan's segment when its
  section is absent, or when present but every field inside it is null.
- `active_plan == "unknown"` renders no usage segment.
- `rate_limited == true` means the poller's last fetch was rate-limited
  (numbers may be stale) — dim styling overrides the normal color, it does
  not add or remove a segment.
- `updated_at` staleness also dims, with the same styling as
  `rate_limited`. The old fetcher refreshed independently every 480s, so
  its own liveness wasn't a concern; now the reader's only freshness
  signal is this cache, and a dead/unloaded poller or an auth error (not
  just a 429) leaves the file untouched indefinitely with no other
  warning. If `updated_at` is more than 900s old (3x the poller's 300s
  cadence), or missing/unparseable on an otherwise-valid `version: 2`
  document, treat the numbers as stale and dim them. Either `rate_limited`
  or staleness dims; both conditions never remove the segment outright.
- The schema version (`2`) is pinned in two places in this repo: this
  rule doc and the `version` check in `statusline-command.sh`. If the
  vu1-claude-token-usage poller ever bumps its `SCHEMA_VERSION`, both must
  move together. Bumped from `1` to `2` by the poller's ADR-0021
  (limits-array cutover), which also renamed the `max` section's
  `five_hour`/`seven_day` keys to `session`/`week`.

## Rendering gotchas carried over from the old implementation

- All budget metrics count down from 100% remaining to 0%, same convention
  as the `ctx` segment: color thresholds (red/orange/yellow/green) key off
  `100 - utilization` (or `100 - spend.percent`), not the raw utilization.
- The enterprise budget segment renders as a computed percentage
  (`100 - spend.percent`, clamped) by default. `spend.remaining_dollars` is
  read from the cache and displayed instead when the user has toggled
  dollar mode on (see "Cost display toggle" below).
- The one-time `cinder_cove` promotional-credit segment (`$crd: N%`) has
  been removed entirely. It is not part of the shared cache schema and
  should not be reintroduced without a new decision upstream.

If the statusline's usage segment errors, silently stops showing a value,
or looks wrong, first check whether `usage.json` exists and matches the
schema above — most likely causes are the poller not running, or a schema
bump on the writer side — before assuming the bug is in this script.

## Cost display toggle

`~/.claude/statusline-cost-mode` holds `pct` (default, if the file is
missing) or `dollar`. It is runtime state, not repo config — not tracked
by git, not stowed. `/statusline:toggle-cost-display` (backed by
`commands/statusline/statusline-toggle-cost.sh`) flips it. Only the
enterprise budget segment is affected; the max-plan segments always show
percentage.
