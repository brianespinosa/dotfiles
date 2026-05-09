---
paths:
  - "**/dotfiles*/**"
---

# Dotfiles Repo Conventions

## Commits

Commit messages are a single emoji character, nothing more. Pick whichever emoji feels appropriate for the commit. This overrides the Conventional Commits convention from the workspace CLAUDE.md.

## Sync

Edits affect `$HOME` immediately via symlinks but don't propagate to other machines without commit + push. After making changes, remind the user that the working tree is dirty and offer to commit and push.
