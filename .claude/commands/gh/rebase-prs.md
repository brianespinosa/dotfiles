---
description: >
  Find all open PRs that are behind their target branch and rebase them via
  `gh pr update-branch --rebase`. Scope is detected from the working directory:
  running inside a repo directory rebases that repo's PRs; running in an org or
  user directory rebases PRs across all repos for that org/user. EMU accounts
  are not supported.
allowed-tools: Bash
---

Rebase all open PRs that are behind their target branch.

## Step 1 — Detect context

```bash
pwd
```

Apply the same `@`-path detection used by `gh:security-alerts`.

Find the **nearest (deepest) `@`-prefixed segment** in the path, then inspect what follows it:

| Nearest `@` segment | Followed by | Context | Variables |
|---|---|---|---|
| `@<name>` | `<repo>/...` | Repo | `OWNER/REPO` = `<name>/<repo>` |
| `@<name>` | nothing (cwd is org root) | Org or user | `TARGET` = `<name>` without `@` |

If the **nearest** `@`-segment ends with `_emu` → print "EMU accounts are not supported" and stop. Do not check any other `@`-segments in the path.

## Step 2 — Run

**Repo context:**
```bash
$HOME/.claude/commands/gh/gh-rebase-prs.sh repo OWNER/REPO
```

**Org/user context:**
```bash
$HOME/.claude/commands/gh/gh-rebase-prs.sh org TARGET
```

## Step 3 — Report

Print the script output verbatim. If nothing was rebased, say so.
