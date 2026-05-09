---
paths:
  - "**/CLAUDE.md"
  - "**/README.md"
---

# Editing CLAUDE.md and README.md files

Apply the official guidance from https://code.claude.com/docs/en/memory and https://code.claude.com/docs/en/best-practices:

- **Distributed over monolithic.** Prefer per-subdirectory CLAUDE.md files, or path-scoped rules in `.claude/rules/`, over expanding the root file. Each subdirectory with significant functionality should have its own.
- **README.md vs CLAUDE.md.** README.md is user-facing (what the code does, how to use it). CLAUDE.md is Claude-facing (gotchas, safe-edit guidance, file:line references). When both exist, CLAUDE.md should reference README.md rather than duplicate it.
- **Conciseness test.** For each line, ask: "Would removing this cause Claude to make mistakes?" If no, cut it. Bloated CLAUDE.md files cause Claude to ignore real instructions because important rules get lost in the noise.
- **No tutorials or long explanations.** State the rule and the command. Do not explain *why* a tool behaves a certain way unless the reasoning is itself a rule Claude needs to apply. Reference external docs by URL instead of restating them.
- **No code duplication.** Reference code by `file:line` instead of pasting snippets. Snippets become a second source of truth that rots.

## Rules evaluation

Before finalizing changes:

- **Redundancy check.** Evaluate existing content against active rules in `~/.claude/rules/` and project `.claude/rules/`. Suggest removing any sections now covered by a rule.
- **Extraction check.** Evaluate whether existing content would fit better as a rule (path-scoped for file-specific guidance, or `_`-prefixed for cross-cutting topics). See `path-claude-rules.md` for prefix conventions.
