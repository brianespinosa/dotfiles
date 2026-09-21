---
paths:
  - "**/CLAUDE.md"
  - "**/README.md"
  - "**/.claude/**/*.md"
---

# Instruction Documents

Covers CLAUDE.md, README.md, and everything under `.claude/` (rules, skills, agents, commands).
Official guidance: <https://code.claude.com/docs/en/memory> and
<https://code.claude.com/docs/en/best-practices>.

- **Removal test.** Cut any line that would not change an agent's output. Bloat buries the rules
  that matter and costs context on every load.
- **Current state only.** Describe how things are now. No changelogs, migration notes, "previously",
  or dated entries. Git holds history.
- **No meta.** Nothing about maintaining the file itself: no ownership, review cadence, or
  instructions for updating it.
- **No tutorials.** State the rule and the command. Explain *why* only when the reasoning is itself
  a rule to apply. Link external docs instead of restating them.
- **No code duplication.** Reference code by `file:line` instead of pasting snippets that rot.
- **Distributed over monolithic.** Prefer per-directory CLAUDE.md files, or path-scoped rules in
  `.claude/rules/`, over growing the root file.
- **README.md vs CLAUDE.md.** README.md is user-facing (what the code does, how to use it).
  CLAUDE.md is agent-facing (gotchas, safe-edit guidance, `file:line` references). CLAUDE.md
  references README.md rather than duplicating it.

## Before finalizing

- **Rot.** Verify the claims already in the file against the current repo: paths, `file:line`
  references, commands, versions, and tool behavior. Suggest fixes for whatever no longer holds.
- **Redundancy.** Check content against active rules in `~/.claude/rules/` and project
  `.claude/rules/`. Suggest removing what a rule already covers.
- **Extraction.** Move content that fits better as a rule. See `path-claude-rules.md` for prefix
  conventions.
