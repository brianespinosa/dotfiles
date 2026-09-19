---
paths:
  - "**/.claude/commands/**"
---

# Slash Command Directories

Each `commands/<namespace>/` directory holds the slash commands for one namespace. Scripts that support those commands live alongside them and are private to that namespace. Do not move scripts to a shared location unless intentionally elevating them to global scope.

Do not add `CLAUDE.md` or other non-command `.md` files here; every `.md` in a commands directory registers as a slash command.
