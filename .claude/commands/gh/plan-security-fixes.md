---
description: >
  Enter plan mode and create a plan to resolve all open Dependabot security alerts
  for the current repo. Detects the package manager from the lockfile and uses the
  correct field (Yarn: resolutions, npm/pnpm/Bun: overrides). Researches upstream
  tracking issues so the PR description records where to check when each entry can
  be removed.
allowed-tools: Bash, Read, Glob, Grep, Agent, ToolSearch, EnterPlanMode, ExitPlanMode
model: claude-opus-4-6
---

Plan the resolution of all open Dependabot security alerts for the current repository.

## Step 1 — Detect repository context

```bash
pwd
```

Derive `OWNER/REPO` using the same path logic as `/gh:security-alerts` (the `@<name>/<repo>` segment).

## Step 2 — Fetch all open alerts

```bash
gh api "repos/OWNER/REPO/dependabot/alerts?state=open&per_page=100" \
  --jq '.[] | {
    number:   .number,
    severity: .security_advisory.severity,
    package:  .security_vulnerability.package.name,
    range:    .security_vulnerability.vulnerable_version_range,
    fixed_in: .security_vulnerability.first_patched_version.identifier,
    cve:      .security_advisory.cve_id,
    ghsa:     .security_advisory.ghsa_id,
    summary:  .security_advisory.summary
  }'
```

Group results by package. Note the highest fixed-in version for each package.

## Step 3 — Detect package manager

Check for lockfiles (first match wins):

| Lockfile | Package manager | Field to use in package.json |
|---|---|---|
| `yarn.lock` | Yarn | `resolutions` |
| `pnpm-lock.yaml` | pnpm | `pnpm.overrides` |
| `package-lock.json` | npm | `overrides` |
| `bun.lockb` or `bun.lock` | Bun | `overrides` |

```bash
ls yarn.lock pnpm-lock.yaml package-lock.json bun.lockb bun.lock 2>/dev/null
```

## Step 4 — Analyze the dependency chain

For each vulnerable package, find which top-level dependency pulls it in:

- **Yarn**: `yarn why <package>`
- **pnpm**: `pnpm why <package>`
- **npm**: `npm explain <package>`
- **Bun**: `bun pm ls` (no direct `why` — inspect `node_modules/<package>/package.json` for the `_requiredBy` field or check `bun.lock`)

Identify the **direct parent** of each vulnerable package (the package whose package.json lists it as a dep).

## Step 5 — Determine resolution entries

### Yarn — scoped `resolutions`

Yarn supports parent-scoped pinning. Use `"parent/dep"` format to minimise blast radius:

```json
"resolutions": {
  "direct-parent/vulnerable-dep": "^fixedVersion"
}
```

If the same package appears at multiple version ranges (e.g. `picomatch` at both v2 and v4), use separate scoped entries — one per parent — rather than a single flat entry that would force every consumer to the same major.

### npm — nested `overrides`

npm supports parent-scoped overrides via nested objects:

```json
"overrides": {
  "direct-parent": {
    "vulnerable-dep": "^fixedVersion"
  }
}
```

Or flat when there is only one instance: `"dep": "^fixedVersion"`.

### pnpm — flat `pnpm.overrides`

pnpm does not support nested parent-scoped overrides. Use flat entries only:

```json
"pnpm": {
  "overrides": {
    "vulnerable-dep": "^fixedVersion"
  }
}
```

If two incompatible version ranges of the same package exist, pin to the higher fixed version and verify the lower-range consumer still works.

### Bun — flat `overrides`

Same as npm flat format:

```json
"overrides": {
  "vulnerable-dep": "^fixedVersion"
}
```

## Step 6 — Research upstream tracking issues

For each vulnerable package's **direct parent**, search the parent's GitHub repo for open issues or PRs that, once merged, would make the resolution unnecessary:

```bash
gh search issues --repo PARENT_OWNER/PARENT_REPO "VULNERABLE_PACKAGE" --state open --limit 5
gh search prs   --repo PARENT_OWNER/PARENT_REPO "VULNERABLE_PACKAGE" --state open --limit 5
```

Record any found URLs. If an issue was filed but closed as `not_planned`, record that too — it explains why the resolution is needed long-term.

## Step 7 — Enter plan mode and write the plan

Load and call `EnterPlanMode` (use ToolSearch to load it if the schema isn't yet available).

Write the plan to the designated plan file. The plan must include:

**Context section**
- The full dep chain for each vulnerable package (what top-level dep pulls it in, through what intermediaries)
- Why a simple dep update isn't sufficient (e.g. the top-level dep is already at latest, or the SDK pins to an old version)

**Resolutions table**
A table mapping each resolution entry to the CVEs it fixes and the package's current vs fixed version.

**Exact JSON to add to package.json**
The complete `resolutions` / `overrides` / `pnpm.overrides` block, ready to paste.

**Upstream issue references**
For each resolution entry, a "safe to remove when" note linking to the upstream issue or PR found in Step 6. If nothing was found, note the absence and suggest watching the parent package's release notes.

**Implementation steps**
1. Add the field to `package.json`
2. Delete the lockfile (for a clean regeneration that also picks up the latest compatible versions of all transitive deps)
3. Run a fresh install (`yarn install` / `pnpm install` / `npm install` / `bun install`)
4. Verify with `why` commands that the resolved versions satisfy the pinned ranges
5. Run the project's typecheck / lint / test commands to confirm nothing broke
6. Commit and open a PR

**PR title**
`fix(deps): <comma-separated high-severity CVE IDs> (+N more)` following conventional commit syntax.

**PR description draft**
- One-paragraph explanation of the root cause
- Bulleted list of all packages pinned, the version range used, and every CVE/GHSA it covers
- "These resolutions can be removed when:" section with upstream issue links per entry

Call `ExitPlanMode` when the plan is complete and ready for approval.
