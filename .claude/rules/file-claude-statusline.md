---
paths:
  - "**/.claude/statusline-command.sh"
  - "**/.claude/usage-cache.sh"
---

# Claude Code Statusline Usage Data

`usage-cache.sh` fetches `https://api.anthropic.com/api/oauth/usage` and caches a subset of fields for `statusline-command.sh` to render. This is an internal/undocumented endpoint, not a published, versioned API — its response schema can change without notice (fields renamed, removed, retyped, or reshaped) and there is no changelog or deprecation notice to watch for. Field names in that response are also not self-explanatory:

- `cinder_cove` is a one-time promotional credit grant, not the org's recurring budget. Its `resets_at` is an *expiration* date for that single grant — it does not indicate when the overall org spend/credits (the `spend`/`extra_usage` fields backing the `💰` indicator) reset. That reset cadence is not exposed by the API; if it's ever needed, it must be found out of band and hardcoded, not inferred from `resets_at`.
- After `resets_at` passes, the API is expected to null out `cinder_cove` rather than remove the key (same pattern as other unused fields in the response, e.g. `five_hour`/`tangelo`/`amber_ladder` when not applicable). `usage-cache.sh` only writes `cinder_cove` into the cache when the API actually returns a non-null object, so a null/missing value drops the field from the statusline instead of freezing on a stale value.
- If `cinder_cove` is confirmed to have permanently stopped appearing in the live API response, remove its handling from both `usage-cache.sh` and `statusline-command.sh` entirely.

Before trusting any other field's name or assumed semantics (reset cadence, whether it's per-org vs per-grant, whether absence means zero vs not-applicable), verify against a live response (`curl` with the OAuth token from the `Claude Code-credentials` keychain item) rather than inferring from the field name.

If either script starts erroring, silently stops showing a value, or the statusline output looks wrong, the schema changing underneath us is a real, likely possibility — not just a bug in these scripts. Pull a fresh live response and diff it against what the code expects before assuming the bug is local:

```bash
token=$(security find-generic-password -s "Claude Code-credentials" -w | python3 -c "import sys,json; print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])")
curl -s -H "Authorization: Bearer $token" -H "anthropic-beta: oauth-2025-04-20" "https://api.anthropic.com/api/oauth/usage" | python3 -m json.tool
```
