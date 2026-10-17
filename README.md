# dotfiles

Install `brew`

```
brew install stow
```

Symlink files

```
stow --adopt .
```

> [!TIP]
> Re-run `stow .` after new files are added (locally or via `git pull`).

## Claude Code

`.claude/` holds the user-level Claude Code files that stow symlinks into `~/.claude/`:
`CLAUDE.md`, `rules/`, `commands/`, `skills/`, the status line and `hooks/`.
`.claude/settings.json` is a template only: stow ignores it (`.stowrc`), because Claude Code
rewrites the live `~/.claude/settings.json` itself. Mirror a hook or permission change in both.

`hooks/direnv-env.sh` runs on `SessionStart` and appends the working directory's
`direnv export` to `CLAUDE_ENV_FILE`, so the Bash tool, hooks and subagents see the same
per-directory variables a terminal does (`GH_CONFIG_DIR`, `GIT_CONFIG_GLOBAL`, ...). It is
silent when direnv or an `.envrc` is absent, and warns once when the `.envrc` is blocked.
