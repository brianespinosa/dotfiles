# Worktree Workflow

Worktrees live at `.claude/worktrees/<branch-name>/` relative to the repository root, created via `claude --worktree <name>` or `git worktree add`. They share a git object store with the root checkout but do NOT share installed dependencies.

## Branch naming

Worktree branches MUST use the prefix `wktr-<issueNumber>-<oneToThreeWordDesc>` (e.g. `wktr-42-fix-tenant-layout`).

## Creating a worktree

```bash
git worktree add .claude/worktrees/wktr-<issue>-<desc> -b wktr-<issue>-<desc>
cd .claude/worktrees/wktr-<issue>-<desc>
pnpm install  # or the repo's package manager — check the lock file
```

## Per-worktree dependencies

Always run install inside the worktree after creation. Check the lock file (`pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`) to determine the package manager.

NEVER symlink `node_modules/` back to the root checkout. It silently corrupts state across worktrees via lockfile drift, concurrent install races, shared `node_modules/.cache/`, and watcher confusion.
