# File Operations and Repository Root

All file creation and modification operations MUST be relative to the git repository root.

1. Run `git rev-parse --show-toplevel` to identify the repository root.
2. Create files relative to that root.
3. Run `git status` to confirm files are tracked.

Files outside the repository boundary will not be version controlled.
