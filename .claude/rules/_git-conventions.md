# Git Conventions

## Conventional Commits

Use [Conventional Commits](https://www.conventionalcommits.org/) syntax for commit messages and PR titles. Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`. Many repos use squash merges, so the PR title becomes the resulting commit message.

Keep messages brief.

## Hook bypass

NEVER commit with `--no-verify`. If a pre-commit hook fails, fix the underlying issue before committing.

## PR descriptions

Keep PR descriptions focused on technical changes, testing, and references.
