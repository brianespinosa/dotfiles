---
paths:
  - "**/dotfiles*/**"
---

# Dotfiles Repo Conventions

## Commits

Use the workspace's Conventional Commits convention (`feat`, `fix`, `docs`, `chore`, etc.), same as any other repo. No repo-specific override.

## Sync

Edits affect `$HOME` immediately via symlinks but don't propagate to other machines without commit + push. After making changes, remind the user that the working tree is dirty and offer to commit and push.
