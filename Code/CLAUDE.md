# ~/Code — Workspace Root

## GitHub Credentials

This workspace uses **direnv** + **gh CLI** to automatically configure the correct GitHub account per directory. No credentials are hardcoded anywhere.

### Directory → Account Mapping

| Directory pattern         | GitHub account             | Notes                                                                                                            |
| ------------------------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `@momentive_emu/@mntv-*/` | `bespinosa_mntv` (work)    | Inherits from `@momentive_emu/.envrc`                                                                            |
| `@SurveyMonkey/`          | `brianespinosa` (personal) | `source_up` from root `.envrc` + work Anthropic Enterprise OAuth token for Claude Code                           |
| `@sm-incubator/`          | `brianespinosa` (personal) | `source_up` from root `.envrc` + work Anthropic Enterprise OAuth token for Claude Code (same as `@SurveyMonkey`) |
| `@bje/@*/`                | `brianespinosa` (personal) | Inherits from root `.envrc` (bje is not an EMU; no enterprise-level `.envrc`)                                    |
| `@brianespinosa/`         | `brianespinosa` (personal) | Inherits from root `.envrc`                                                                                      |
| Everything else           | `brianespinosa` (personal) | Inherits from root `.envrc`                                                                                      |

### Environment Variables Set by direnv

> _Do not_ set these variables manually. They will already be present in the environment.

- `GH_CONFIG_DIR` — points `gh` CLI to the correct stored auth session
- `GITHUB_PAT` — fetched dynamically via `gh auth token` from the active session
- `GIT_CONFIG_GLOBAL` — points `git` to the correct per-profile global config

### Using gh in subdirectories

`GH_CONFIG_DIR` is always exported in every `~/Code` subdirectory by direnv. Never prefix `gh` commands with `GH_CONFIG_DIR=...` — it is redundant and obscures intent. Run `gh <subcommand>` directly; it uses the correct account for the current directory automatically.

If `gh` ever picks the wrong account, the fix is to verify direnv is loaded (`direnv status`), not to override the env var inline.

### Auth Sessions / Config Files

| Tool  | Personal                 | Work                 |
| ----- | ------------------------ | -------------------- |
| `gh`  | `~/.config/gh/personal/` | `~/.config/gh/work/` |
| `git` | `~/.config/git/personal` | `~/.config/git/work` |

Both git profiles include `~/.config/git/base` for shared settings.

## Workspace Structure

| Directory          | Purpose                                                                                                                                                         |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@momentive_emu/`  | SurveyMonkey internal/private repos (EMU) -- uses `bespinosa_mntv` account                                                                                      |
| `@SurveyMonkey/`   | SurveyMonkey open source repos (public org) -- uses `brianespinosa` account                                                                                     |
| `@sm-incubator/`   | SurveyMonkey incubator repos (public org; not in EMU) -- experiments for new products/startups that may later move into the EMU -- uses `brianespinosa` account |
| `@brianespinosa/`  | Personal repos -- uses `brianespinosa` account                                                                                                                  |
| `@bje/`            | `bje` enterprise -- personal orgs consolidated under one enterprise; uses `brianespinosa` account                                                                |

Each org directory has its own `CLAUDE.md` with org-specific context (git workflow, toolchain, worktree conventions).

### The `@bje` Enterprise

`@bje/` is a GitHub enterprise (billing contact `b@bje.co`) consolidating several personal orgs so
policy and automation are managed once across many repositories. It is **not** an EMU -- membership
is the normal personal `brianespinosa` account, so there is no `@bje/.envrc`; everything under it
inherits from the root.

Org directories match the GitHub org login exactly (so `@bjeco/` became `@bje/@bje-co/`), and orgs
with no repos still get a directory. Current orgs: `@bje-settings`, `@bje-actions`, `@bje-co`,
`@bork-ltd`, `@arsenalamerica`.

Org and enterprise GitHub settings are managed as code in `@bje-settings/terraform`, not
through the GitHub UI.

Most repos under `@brianespinosa/` are expected to move into a `@bje` org over time; **forks are the
exception** and stay on the personal user account.

See `@bje/CLAUDE.md`.

### Adding New Directories

- **New SurveyMonkey internal (`@mntv-*`) repo:** Place it inside `@momentive_emu/` -- inherits work credentials automatically.
- **New SurveyMonkey open source repo:** Clone it into `@SurveyMonkey/` -- inherits personal credentials from root automatically.
- **New SurveyMonkey incubator repo:** Clone it into `@sm-incubator/` -- inherits personal GitHub credentials from root, plus the work Anthropic Enterprise OAuth token for Claude Code (via `@sm-incubator/.envrc`, same pattern as `@SurveyMonkey`).
- **New `bje` enterprise org:** Create `@bje/@<org-login>/` -- inherits personal credentials from root automatically. Do this even if the org has no repos yet.
- **New repo in an existing `bje` org:** Clone into `@bje/@<org-login>/<repo-name>`.
- **New personal `@*` directory:** No action -- inherits personal credentials from root automatically.
- **Forks:** Keep under `@brianespinosa/`; they are not moved into `@bje`.
