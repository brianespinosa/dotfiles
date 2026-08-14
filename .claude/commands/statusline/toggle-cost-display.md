---
description: >
  Toggle the statusline's enterprise budget segment between percentage
  remaining and dollar amount remaining.
allowed-tools: Bash(*/.claude/commands/statusline/statusline-toggle-cost.sh)
---

Run the toggle script and report the new mode:

```bash
$HOME/.claude/commands/statusline/statusline-toggle-cost.sh
```

Print its output verbatim. The next statusline render (up to 1s later, per the
configured `refreshInterval`) will reflect the new mode.
