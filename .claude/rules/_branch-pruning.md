# Branch Pruning on Default Branch Switch

When you switch back to the default branch (`main` or `master`) and pull, check for local branches and worktrees whose work has already landed and remove them.

1. Run `git branch -vv` and `git worktree list` to see what exists. Branches whose upstream shows `[origin/<name>: gone]` are candidates.
2. Confirm the work has landed before deleting. `git branch --merged` does not catch squash merges. Use `gh pr list --state merged --search "head:<branch-name>" --json number,title,mergedAt`; a result confirms it merged.
3. Remove the artifacts: `git worktree remove <path>`, then `git branch -d <name>` (or `-D` if the squash merge means git does not recognize it as merged).

Do not delete a branch on a `gone` upstream alone. A pruned remote can also mean the branch was abandoned without merging. When in doubt, ask.
