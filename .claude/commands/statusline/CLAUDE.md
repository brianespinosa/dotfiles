# commands/statusline

Slash commands for controlling `statusline-command.sh` display behavior. Scripts that
support these commands live here alongside them and are private to this namespace.

## Cost display mode

`statusline-toggle-cost.sh` flips `~/.claude/statusline-cost-mode` between `pct` and
`dollar`. This file is runtime state, not repo config — it is not tracked by git or stowed.
`statusline-command.sh` reads it to decide whether the enterprise budget segment renders
as a percentage or a dollar amount.
