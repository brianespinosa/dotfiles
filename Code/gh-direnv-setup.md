# Multi-User GitHub CLI + MCP via direnv

A guide for configuring per-directory GitHub credentials on a machine with multiple GitHub accounts, without hardcoded tokens.

## Problem

When working with multiple GitHub accounts (e.g. personal and work), the `gh` CLI defaults to one active user. Switching manually is global and error-prone. The GitHub MCP server needs a `GITHUB_PAT` env var that should differ per directory tree.

## Solution Overview

- **direnv** loads `.envrc` files on `cd`, making env vars directory-aware
- **`GH_CONFIG_DIR`** tells `gh` which stored auth session to use (isolated per-account config dirs)
- **`gh auth token`** dynamically returns the OAuth token for the active account in the given config dir
- One root `.envrc` sets a default account; personal directories override it

## Why GH_CONFIG_DIR?

Alternatives considered and rejected:
- **`gh auth switch`** — changes active user globally across all terminals; two concurrent sessions would stomp each other
- **Hardcoded PATs in a secrets file** — requires manual rotation, plaintext risk
- **macOS Keychain via `security` command** — fragile, ties to implementation details of how gh stores tokens

`GH_CONFIG_DIR` is process-scoped. Each shell gets its own env, so two terminals in different directories simultaneously use different credentials with no conflict.

## Directory Structure

```
~/Web/
├── .envrc                    ← work credentials (root default)
├── @mntv-actions/            ← inherits root .envrc → work ✓
├── @mntv-analysis/           ← inherits root .envrc → work ✓
├── @mntv-web-experience/     ← inherits root .envrc → work ✓
├── @brianespinosa/
│   └── .envrc                ← personal credentials (override) ✓
├── @bjeco/
│   └── .envrc                ← personal credentials (override) ✓
└── @arsenalamerica/
    └── .envrc                ← personal credentials (override) ✓
```

## Setup Steps

### 1. Create per-account gh config directories

```bash
GH_CONFIG_DIR=~/.config/gh/personal gh auth login \
  --scopes "read:packages,notifications,security_events,project"

GH_CONFIG_DIR=~/.config/gh/work gh auth login \
  --scopes "read:packages,notifications,security_events,project"
```

`--scopes` is additive — it adds to gh's default scopes (`repo`, `read:org`, `gist`, `workflow`). The resulting token is more capable, not less.

### 2. Root .envrc (work default)

```bash
export GH_CONFIG_DIR=~/.config/gh/work
export GITHUB_PAT=$(gh auth token)
```

### 3. Personal override .envrc

```bash
export GH_CONFIG_DIR=~/.config/gh/personal
export GITHUB_PAT=$(gh auth token)
```

Place this in each personal `@*` directory. `cd` into each and run `direnv allow`.

## How direnv inheritance works

direnv walks up the directory tree and loads the **nearest** `.envrc` it finds, then stops. It does NOT continue upward unless `source_up` is called explicitly.

This means:
- Repos in `@mntv-actions/` find `~/Web/.envrc` (work) → correct
- Repos in `@brianespinosa/` find `~/Web/@brianespinosa/.envrc` (personal) → correct, root ignored

## Security notes

- `.envrc` files contain no secrets — tokens are evaluated dynamically at shell load time
- `~/.config/gh/personal/` and `~/.config/gh/work/` use macOS Keychain (no plaintext)
- `~/Web/` is not a git repo — `.envrc` files here cannot be accidentally committed
- `direnv allow` stores a hash of each `.envrc`; modifications are blocked until re-approved

## GitHub MCP Integration

Per-repo MCP config lives in `.mcp.json` at the repo root (committed). It references `${GITHUB_PAT}`:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp",
      "headers": {
        "Authorization": "Bearer ${GITHUB_PAT}"
      }
    }
  }
}
```

Local opt-in via `.claude/settings.local.json`:
```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["github"]
}
```

Token scopes required by the MCP: `repo`, `read:org`, `read:packages`, `notifications`, `security_events`, `gist`, `project`.

## Token freshness

`gh auth token` is evaluated when direnv loads the `.envrc` (on `cd`). OAuth tokens from `gh auth login` are long-lived (until revoked). Re-entering a directory forces re-evaluation if needed.
