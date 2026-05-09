# ~/Code — Workspace Root

## GitHub Credentials

This workspace uses **direnv** + **gh CLI** to automatically configure the correct GitHub account per directory. No credentials are hardcoded anywhere.

### Directory → Account Mapping

| Directory pattern | GitHub account | Notes |
|---|---|---|
| `@momentive_emu/@mntv-*/` | `bespinosa_mntv` (work) | Inherits from `@momentive_emu/.envrc` |
| `@SurveyMonkey/` | `brianespinosa` (personal) | `source_up` from root `.envrc` + Bedrock settings |
| `@arsenalamerica/` | `brianespinosa` (personal) | Inherits from root `.envrc` |
| `@bjeco/` | `brianespinosa` (personal) | Inherits from root `.envrc` |
| `@brianespinosa/` | `brianespinosa` (personal) | Inherits from root `.envrc` |
| Everything else | `brianespinosa` (personal) | Inherits from root `.envrc` |

### Environment Variables Set by direnv

> *Do not* set these variables manually. They will already be present in the environment.

- `GH_CONFIG_DIR` — points `gh` CLI to the correct stored auth session
- `GITHUB_PAT` — fetched dynamically via `gh auth token` from the active session
- `GIT_CONFIG_GLOBAL` — points `git` to the correct per-profile global config

### Using gh in subdirectories

`GH_CONFIG_DIR` is always exported in every `~/Code` subdirectory by direnv. Never prefix `gh` commands with `GH_CONFIG_DIR=...` — it is redundant and obscures intent. Run `gh <subcommand>` directly; it uses the correct account for the current directory automatically.

If `gh` ever picks the wrong account, the fix is to verify direnv is loaded (`direnv status`), not to override the env var inline.

### Auth Sessions / Config Files

| Tool | Personal | Work |
|---|---|---|
| `gh` | `~/.config/gh/personal/` | `~/.config/gh/work/` |
| `git` | `~/.config/git/personal` | `~/.config/git/work` |

Both git profiles include `~/.config/git/base` for shared settings.

### GitHub MCP

MCP config lives per-repo in `.mcp.json` (committed). See `@brianespinosa/career/.mcp.json` as the reference. Local opt-in via each repo's `.claude/settings.local.json`.

## Workspace Structure

| Directory | Purpose |
|---|---|
| `@momentive_emu/` | SurveyMonkey internal/private repos (EMU) -- uses `bespinosa_mntv` account |
| `@SurveyMonkey/` | SurveyMonkey open source repos (public org) -- uses `brianespinosa` account |
| `@brianespinosa/` | Personal repos -- uses `brianespinosa` account |
| `@arsenalamerica/` | Arsenal America repos -- uses `brianespinosa` account |
| `@bjeco/` | BJECo repos -- uses `brianespinosa` account |

Each org directory has its own `CLAUDE.md` with org-specific context (git workflow, toolchain, worktree conventions).

### Adding New Directories

- **New SurveyMonkey internal (`@mntv-*`) repo:** Place it inside `@momentive_emu/` -- inherits work credentials automatically.
- **New SurveyMonkey open source repo:** Clone it into `@SurveyMonkey/` -- inherits personal credentials from root automatically.
- **New personal `@*` directory:** No action -- inherits personal credentials from root automatically.

