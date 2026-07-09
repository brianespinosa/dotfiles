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
  notification types are left untouched.
allowed-tools: Bash
---

Mark non-actionable notifications as read: pre-release/canary releases, closed PRs, review requests not assigned to you, and closed issues.

## Step 1 — Run

```bash
$HOME/.claude/commands/gh/gh-tidy-user-notifications.sh
```

## Step 2 — Report

Print the script output verbatim. If it reports "Nothing to tidy.", confirm the inbox is already clean.
