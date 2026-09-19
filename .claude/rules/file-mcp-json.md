---
paths:
  - "**/.mcp.json"
---

# Project `.mcp.json`

Project-scoped MCP servers, committed and shared with all collaborators including cloud environments.

Repos that configure the GitHub remote MCP (`https://api.githubcopilot.com/mcp`) need a `GITHUB_PAT` environment variable with scopes `repo`, `read:org`, `read:packages`, `notifications`, `security_events`, `gist`, `project`. Under `~/Code`, direnv already exports `GITHUB_PAT`.
