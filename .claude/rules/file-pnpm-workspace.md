---
paths:
  - "**/pnpm-workspace.yaml"
---

# Required `pnpm-workspace.yaml` Settings

Any repo with a `pnpm-workspace.yaml` MUST declare this baseline at the workspace root. When touching the file for any reason, add missing keys rather than leaving them for later.

```yaml
savePrefix: ''
strictPeerDependencies: true
autoInstallPeers: false
engineStrict: true
strictDepBuilds: true
minimumReleaseAge: 7200 # minutes; keep <= Dependabot cooldown default-days
```

## Why each

- **`savePrefix: ''`** — exact versions, no caret. Upgrades are explicit and reviewable.
- **`strictPeerDependencies: true`** — fail on invalid peers instead of warning. Default is `false`.
- **`autoInstallPeers: false`** — default `true` silently installs missing non-optional peers, so `strictPeerDependencies` alone never reports them. Both are required to fail on a missing peer.
- **`engineStrict: true`** — refuse to install a package incompatible with the current Node version. Default is `false`.
- **`strictDepBuilds: true`** — fail when a dependency has an unreviewed build script. Approve deliberately via `allowBuilds`.
- **`minimumReleaseAge: 7200`** — 5 days. Supply-chain hardening. MUST stay at or below Dependabot's cooldown `default-days` in `.github/dependabot.yml`, or Dependabot opens PRs for versions pnpm refuses and frozen-lockfile CI breaks. Exempt individual packages with `minimumReleaseAgeExclude`, never by lowering the floor.

## Placement

As of pnpm 11, `.npmrc` is for authentication only. Every non-sensitive setting belongs in `pnpm-workspace.yaml`. A repo carrying `save-exact`, `strict-peer-dependencies`, `engine-strict`, or `use-node-version` in `.npmrc` MUST have them migrated here.

Removed in pnpm 11, do not add: `onlyBuiltDependencies`, `onlyBuiltDependenciesFile`, `neverBuiltDependencies`, `ignoredBuiltDependencies`, `ignoreDepScripts` (all replaced by `allowBuilds`), and `managePackageManagerVersions`, `packageManagerStrict`, `packageManagerStrictVersion` (replaced by `pmOnFail`). The `pnpm` field in `package.json` is inert; `overrides`, `packageExtensions`, and `patchedDependencies` MUST live in this file.
