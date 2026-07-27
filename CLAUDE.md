# Dotfiles

This repo is managed with [GNU Stow](https://www.gnu.org/software/stow/). Files are symlinked
to `$HOME` via the `.stowrc` target setting.

## Changes must be committed and pushed

Any edit to a file in this repo takes effect immediately via symlinks, but does not propagate
to other machines until committed and pushed to `main`. After making changes, always commit
and push before closing the session.

## .claude/settings.json is NOT stowed

`~/.claude/settings.json` is a real file, not a symlink. It is excluded from stow via an
`--ignore` rule in `.stowrc` because Claude Code writes runtime state into it (`model`,
`effortLevel`, and other `/config` changes), which would constantly dirty this repo.

The copy in this repo is the curated baseline. Rules:

- Never commit runtime-state churn (`model`, `effortLevel`, theme, and similar toggles).
- Only commit deliberate opt-ins: enabling plugins, permissions, hooks, statusLine, and
  other configuration meant to sync across machines.
- Because the file is not symlinked, deliberate config changes made to
  `~/.claude/settings.json` must be manually copied into `.claude/settings.json` in this
  repo, then committed and pushed.

## New files must be stowed

Adding a new file to this repo does not automatically create a symlink in `$HOME`. After
adding a new file or directory, run stow from the repo root to create the symlink:

```bash
stow .
```

Verify the symlink was created with `ls -la ~/<path-to-file>`.
