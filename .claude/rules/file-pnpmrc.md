---
paths:
  - "**/pnpm-lock.yaml"
  - "**/pnpm-workspace.yaml"
---

# pnpm Install Warnings

`pnpm install` may produce warnings. All warnings MUST be resolved before closing any PR. Investigate the cause and fix it.

Common warnings:

- **Unmet peer dependencies**: install the missing peer in the consuming workspace; if upstream forgot to declare the peer, add a `pnpm.packageExtensions` entry to `package.json` (the pnpm equivalent of yarn's `packageExtensions`); if a version mismatch is intentional, use `pnpm.peerDependencyRules.allowedVersions`.
- **Deprecated packages**: pin to a non-deprecated version, or use `pnpm.overrides` to force a transitive replacement.
- **Engine mismatch (`Unsupported engine`)**: align the local Node version (e.g. via `.nvmrc`) with the package's `engines` field.
- **Phantom dependencies** (in strict mode): add the missing package to `dependencies` or `devDependencies` instead of relying on hoisting.
- **Outdated lockfile**: run `pnpm install` to update, or use `--frozen-lockfile` in CI to catch drift early.
