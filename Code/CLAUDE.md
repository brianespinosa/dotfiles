# ~/Code: Workspace Root

Not a git repository. Each org directory has its own `CLAUDE.md` with org-specific context.

## Directories and GitHub accounts

**direnv** + **gh CLI** select the GitHub account per directory. No credentials are hardcoded.

| Directory         | Contents                                                        | GitHub account             | `.envrc`                                          |
| ----------------- | --------------------------------------------------------------- | -------------------------- | ------------------------------------------------- |
| `@momentive_emu/` | SurveyMonkey internal/private repos (EMU), in `@mntv-*/` orgs   | `bespinosa_mntv` (work)    | Own `.envrc` sets the work account                |
| `@SurveyMonkey/`  | SurveyMonkey open source repos (public org)                     | `brianespinosa` (personal) | `source_up` from root, adds non-GitHub vars only  |
| `@sm-incubator/`  | SurveyMonkey incubator repos (public org, not in the EMU)       | `brianespinosa` (personal) | `source_up` from root, adds non-GitHub vars only  |
| `@bje/@*/`        | `bje` enterprise orgs (not an EMU). See `@bje/CLAUDE.md`        | `brianespinosa` (personal) | Inherits root                                     |
| `@brianespinosa/` | Personal user repos; long term, forks only                      | `brianespinosa` (personal) | Inherits root                                     |
| Everything else   |                                                                 | `brianespinosa` (personal) | Inherits root                                     |

## direnv variables

Already present in every `~/Code` subdirectory. Do not set them manually.

- `GH_CONFIG_DIR`: points `gh` at the correct stored auth session
- `GITHUB_PAT`: fetched via `gh auth token` from the active session
- `GIT_CONFIG_GLOBAL`: points `git` at the correct per-profile global config

Never prefix `gh` commands with `GH_CONFIG_DIR=...`. Run `gh <subcommand>` directly. If `gh` picks
the wrong account, verify direnv is loaded (`direnv status`) instead of overriding the variable.

| Tool  | Personal                 | Work                 |
| ----- | ------------------------ | -------------------- |
| `gh`  | `~/.config/gh/personal/` | `~/.config/gh/work/` |
| `git` | `~/.config/git/personal` | `~/.config/git/work` |

Both git profiles include `~/.config/git/base` for shared settings.

## Cloning and new directories

- Clone into the directory matching the repo's org: `@momentive_emu/@<org>/<repo>`,
  `@bje/@<org-login>/<repo>`, `@SurveyMonkey/<repo>`, `@sm-incubator/<repo>`. Credentials are
  inherited automatically.
- Org directories use the `@` prefix and match the GitHub org login exactly.
- A new `bje` org gets a `@bje/@<org-login>/` directory even if it has no repos yet.
- Forks stay under `@brianespinosa/`; they do not move into `@bje`.
