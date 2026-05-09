---
paths:
  - "**/.claude/settings.json"
  - "**/.claude/settings.local.json"
---

# Claude Code Permissions

Non-destructive permissions useful across all repositories (global CLI tools like `git`, `gh`, `vercel`, `direnv`, MCP server operations, read-only web fetches, universal skills) belong in `~/.claude/settings.json` at the user level.

Repo or org-level `settings.local.json` files should only contain permissions specific to that project: destructive operations, project-specific domains, or tooling not used workspace-wide.

When a permission prompt arises for a non-destructive command that seems globally useful, ask whether to put it at user level or scope it to the current directory.

Keep permissions sorted alphabetically within each file.
