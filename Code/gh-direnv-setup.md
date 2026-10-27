# Multi-User GitHub CLI via direnv

How `~/Code` gives each directory tree its own GitHub account and git identity, with no hardcoded tokens.

## Problem

Two GitHub accounts share this machine: personal (`brianespinosa`) and work (`bespinosa_mntv`, in the `momentive_emu` EMU). The `gh` CLI defaults to one active user, and switching it is global. `gh` and git both need credentials that differ per directory tree.

## How it works

- **direnv** loads the nearest `.envrc` on `cd`, so env vars follow the directory.
- **`GH_CONFIG_DIR`** points `gh` at one account's config directory.
- **`gh auth token`** returns that account's OAuth token, which `.envrc` exports as `GITHUB_PAT`.
- **`GIT_CONFIG_GLOBAL`** points git at that account's global config, which sets the commit identity and routes GitHub credentials through `gh`.
- The root `~/Code/.envrc` sets the personal account. `@momentive_emu/.envrc` overrides it with work.

`GH_CONFIG_DIR` is process-scoped, so two terminals in different trees use different accounts at once. `gh auth switch` was rejected because it changes the active user for every terminal. Hardcoded PATs were rejected because they need manual rotation and sit in plaintext.

## Directory structure

```
~/Code/
├── .envrc                    ← personal (root default)
├── @brianespinosa/           ← inherits root → personal
├── @bje/@*/                  ← inherits root → personal
│   └── @arsenalamerica/
│       └── .envrc            ← source_up + VERCEL_TEAM_ID
├── @SurveyMonkey/
│   └── .envrc                ← source_up (personal) + work Claude Code token
├── @sm-incubator/
│   └── .envrc                ← source_up (personal) + Claude Code settings
└── @momentive_emu/
    └── .envrc                ← work: gh, git, AWS and CodeArtifact
```

`@SurveyMonkey` and `@sm-incubator` are public orgs outside the EMU, so they use the personal account.

## Which repo provides each file

All three dotfiles repos stow into `$HOME` and own separate paths.

| File | Repo |
|---|---|
| `~/Code/.envrc` | `brianespinosa/dotfiles` |
| `~/.config/git/base`, `ignore`, `personal` | `brianespinosa/dotfiles` |
| `~/Code/@bje/@arsenalamerica/.envrc` | `brianespinosa/dotfiles-private` |
| `~/Code/@momentive_emu/.envrc` | `bespinosa_mntv/dotfiles` |
| `~/Code/@SurveyMonkey/.envrc`, `~/Code/@sm-incubator/.envrc` | `bespinosa_mntv/dotfiles` |
| `~/.config/git/work` | `bespinosa_mntv/dotfiles` |
| `~/.config/gh/*` | None: written by `gh auth login` (see below) |

`~/.config/git/` must be a real directory, not a symlink, because two repos link files into it. The same goes for `~/.config`, `~/Code/@SurveyMonkey` and `~/Code/@sm-incubator`. If one of them is missing when you run `stow`, stow folds it into a single link to one repo, and anything written there later lands inside that repo. Create the directory first.

## Setup

### 1. Log in each account to its own config directory

```bash
GH_CONFIG_DIR=~/.config/gh/personal gh auth login \
  --scopes "read:packages,notifications,security_events,project"

GH_CONFIG_DIR=~/.config/gh/work gh auth login \
  --scopes "read:packages,notifications,security_events,project"
```

`--scopes` adds to gh's default scopes (`repo`, `read:org`, `gist`, `workflow`).

Each login writes `config.yml` and `hosts.yml` into its directory and stores the token in the macOS login Keychain (service `gh:github.com`, account set to the GitHub username). Neither file holds the token.

If the directories are lost but the Keychain entries remain, you can recreate the two files instead of logging in again. `config.yml`:

```yaml
version: "1"
git_protocol: https
```

`hosts.yml`, with the account's username:

```yaml
github.com:
    git_protocol: https
    users:
        bespinosa_mntv:
    user: bespinosa_mntv
```

Then check with `GH_CONFIG_DIR=~/.config/gh/work gh auth status`. macOS may ask to let `gh` use the Keychain.

### 2. Root `.envrc` (personal)

```bash
export GH_CONFIG_DIR=~/.config/gh/personal
export GITHUB_PAT=$(gh auth token)
export GIT_CONFIG_GLOBAL=~/.config/git/personal
```

### 3. Work `.envrc` (`@momentive_emu/`)

```bash
export GH_CONFIG_DIR=~/.config/gh/work
export GITHUB_PAT=$(gh auth token)
export GIT_CONFIG_GLOBAL=~/.config/git/work
```

It also sets the AWS profile and CodeArtifact values. See `~/Code/CLAUDE.md`.

### 4. Allow each `.envrc`

`cd` into each directory that has one and run `direnv allow`. direnv blocks a new or changed `.envrc` until it is allowed again.

## Git profiles

`~/.config/git/personal` and `~/.config/git/work` each set `user.name` and `user.email`, and both include `~/.config/git/base` for shared settings. Each one resets the credential helper for `https://github.com` and hands it to `gh auth git-credential`. Without the reset, Apple's git runs `osxkeychain` first and can return the other account's token.

## How direnv inheritance works

direnv loads the nearest `.envrc` above the current directory and stops there. It goes further up only when that file calls `source_up`. So:

- Repos in `@momentive_emu/@mntv-*/` load `@momentive_emu/.envrc` (work), and never the root.
- Repos in `@SurveyMonkey/` load `@SurveyMonkey/.envrc`, whose `source_up` loads the root (personal) first.
- Repos in `@brianespinosa/` and `@bje/` load the root (personal).

## Security notes

- No `.envrc` holds a secret. Tokens are read when direnv loads the file, from `gh` or the Keychain.
- `~/Code` is not a git repository. The `.envrc` files are symlinks into the dotfiles repos, which commit no secret.
- `direnv allow` stores a hash of each `.envrc`, so an edited file does nothing until approved.

## Token freshness

`gh auth token` runs when direnv loads the `.envrc`, on `cd`. OAuth tokens from `gh auth login` last until revoked. `direnv reload` re-reads them.
