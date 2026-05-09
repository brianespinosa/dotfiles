---
description: >
  Show a Dependabot security alert report for the current context. Scope is
  determined automatically from the working directory: running inside a repo
  directory reports alerts for that repo only; running in a user or org
  directory reports alerts across all repos for that user or org; running in
  an EMU directory reports a per-repo count summary for each child org.
allowed-tools: Bash(pwd), Bash(*/.claude/commands/gh/gh-security-*)
---

Fetch and display GitHub Dependabot security alerts for the current workspace.

## Step 1 — Detect context

```bash
pwd
```

Find the **innermost (last/deepest) `@`-prefixed segment** in the path, then check whether there is a non-`@` segment immediately after it:

- An `@<name>_emu` directory (innermost, no non-`@` segment after) → **EMU context**
- `@brianespinosa` (innermost, no non-`@` segment after) → **User context** (login: `brianespinosa`)
- `@brianespinosa/<repo>` (non-`@` segment present after innermost) → **Single-repo context** (`owner/repo` = `brianespinosa/<repo>`)
- Any other `@<name>` (innermost, no non-`@` segment after) → **Org context** (org: `<name>` without the `@`)
- Any other `@<name>/<repo>` (non-`@` segment present after innermost) → **Single-repo context** (`owner/repo` = `<name>/<repo>`)

The innermost `@`-prefixed segment is the last path component starting with `@`. The repo segment is the path component immediately after it that does NOT start with `@` — ignore anything deeper.

## Step 2 — Run

**Single-repo context** (`OWNER/REPO` = derived above):
```bash
$HOME/.claude/commands/gh/gh-security-alerts.sh repo $OWNER/$REPO \
  | $HOME/.claude/commands/gh/gh-security-format.sh
```

**User context:**
```bash
$HOME/.claude/commands/gh/gh-security-alerts.sh user brianespinosa \
  | $HOME/.claude/commands/gh/gh-security-format.sh
```

**Org context** (`ORG` = segment name without `@`):
```bash
$HOME/.claude/commands/gh/gh-security-alerts.sh org $ORG \
  | $HOME/.claude/commands/gh/gh-security-format.sh
```

**EMU context:** Fetch only the orgs the authenticated user has admin access to, then run in parallel:
```bash
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT
while IFS= read -r ORG; do
  ($HOME/.claude/commands/gh/gh-security-alerts.sh org-alerts "$ORG" > "$WORK/$ORG.ndjson") &
done < <(gh api '/user/memberships/orgs?state=active&per_page=100' --paginate \
  --jq '.[] | select(.role == "admin") | .organization.login')
wait
cat "$WORK"/*.ndjson | $HOME/.claude/commands/gh/gh-security-format-emu.sh
```

## Step 3 — Display

Print the script output verbatim as markdown. Do not reformat, summarize, or add commentary.
