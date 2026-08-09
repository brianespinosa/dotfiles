---
description: >
  Mark noisy, non-actionable notifications as read for the current gh user
  session. Operates on the active gh authentication context (personal or work,
  determined automatically by direnv based on the current directory). Cleans
  four categories: (1) release notifications where the tag name is not strict
  semver MAJOR.MINOR.PATCH — catching canary, alpha, beta, rc, next, nightly,
  dev, and any other pre-release or non-standard tag (monorepo tags like
  `pkg@1.2.3` are checked on the version after the last `@`); (2) pull request
  notifications where the PR is closed (merged or closed-unmerged); (3)
  review-requested PR notifications where you are not a direct or team
  reviewer; (4) issue notifications where the issue is closed. All other
  notification types are left untouched. Also runs automatically on session
  start and end, windowed to notifications since the last run.
allowed-tools: Bash
---

Mark non-actionable notifications as read: pre-release/canary releases, closed PRs, review requests not assigned to you, and closed issues.

The script also runs automatically on Claude Code SessionStart and SessionEnd, throttled to
once per 5 minutes per gh account, windowed to notifications updated since the last run. A
full pass (scanning the entire inbox instead of the window) happens automatically when no
prior run is cached or the last full pass is more than 7 days old, since the window can miss
state changes that don't touch thread activity (e.g. an issue closed by an external tool).

## Step 1 — Run

```bash
$HOME/.claude/commands/gh/gh-tidy-user-notifications.sh --force
```

`--force` bypasses the 5-minute throttle for a manual run; it does not force a full pass.

## Step 2 — Report

Print the script output verbatim. If it reports "Nothing to tidy.", confirm the inbox is
already clean. If it reports "Another tidy run is already in progress; skipping.", report
that this run was skipped because a concurrent run holds the lock, not that the inbox is
clean.
