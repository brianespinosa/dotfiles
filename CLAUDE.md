# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/); files are symlinked to `$HOME` via the
`.stowrc` target setting.

- Edits take effect immediately through the symlinks but do not reach other machines until
  committed and pushed to `main`. After making changes, tell the user the tree is dirty and offer
  to commit and push.
- Adding a file does not create its symlink. Run `stow .` from the repo root after adding one and
  `stow -R .` after a rename or delete, then verify with `ls -la ~/<path-to-file>`.
- The repo-root `CLAUDE.md` is not stowed (`.stowrc` ignores `^CLAUDE\.md$`); at `~/CLAUDE.md` it
  would load as an ancestor in every session under `$HOME`. Nested `CLAUDE.md` files are stowed.
- `~/.claude/settings.json` is a real file, not a symlink (`.stowrc --ignore`), because Claude Code
  writes runtime state into it. `.claude/settings.json` here is the curated baseline: commit only
  deliberate opt-ins (plugins, permissions, hooks, statusLine), never runtime churn (`model`,
  `effortLevel`, theme). Deliberate changes made in `~/.claude/settings.json` must be copied here
  manually.
