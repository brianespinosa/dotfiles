---
paths:
  - "**/pnpm-lock.yaml"
---

# pnpm Install Warnings

`pnpm install` may produce warnings. All warnings MUST be resolved before closing any PR. Investigate the cause and fix it.

Settings and fixes go in `pnpm-workspace.yaml`. As of pnpm 11 the `pnpm` field in `package.json` is inert, so `pnpm.overrides`, `pnpm.packageExtensions`, and `pnpm.peerDependencyRules` there do nothing.

Common warnings:

- **Unmet peer dependencies**: install the missing peer in the consuming workspace; if upstream forgot to declare the peer, add a `packageExtensions` entry; if a version mismatch is intentional, use `peerDependencyRules.allowedVersions`. With the required `strictPeerDependencies: true` these fail the install rather than warn.
- **Deprecated packages**: pin to a non-deprecated version, or use `overrides` to force a transitive replacement. `allowedDeprecatedVersions` only mutes the warning and is a last resort.
- **Engine mismatch (`Unsupported engine`)**: align the local Node version (e.g. via `.nvmrc` or `useNodeVersion`) with the package's `engines` field.
- **Unreviewed build scripts**: approve deliberately per package with `allowBuilds`. Never reach for `dangerouslyAllowAllBuilds`.
- **Phantom dependencies** (under the default `isolated` linker): add the missing package to `dependencies` or `devDependencies` instead of relying on hoisting.
- **Outdated lockfile**: run `pnpm install` to update, or use `--frozen-lockfile` in CI to catch drift early.
