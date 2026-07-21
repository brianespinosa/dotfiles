# Dotfiles

This repo is managed with [GNU Stow](https://www.gnu.org/software/stow/). Files are symlinked
to `$HOME` via the `.stowrc` target setting.

## Changes must be committed and pushed

Any edit to a file in this repo takes effect immediately via symlinks, but does not propagate
to other machines until committed and pushed to `main`. After making changes, always commit
and push before closing the session.

## New files must be stowed

Adding a new file to this repo does not automatically create a symlink in `$HOME`. After
adding a new file or directory, run stow from the repo root to create the symlink:

```bash
stow .
```

Verify the symlink was created with `ls -la ~/<path-to-file>`.
