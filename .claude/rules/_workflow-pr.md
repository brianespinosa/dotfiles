# Workflow and PR State

Do not poll, watch, or wait for the state of PRs, CI runs, or workflow jobs unless I explicitly ask. Polling wastes tokens on information I can read directly from GitHub.

After pushing a branch or creating a PR, report the action and stop. Do not run `gh pr checks --watch`, `gh run watch`, repeated `gh pr checks <pr>` calls, or sleep+poll loops on workflow status. If I want CI confirmation, I will ask.
