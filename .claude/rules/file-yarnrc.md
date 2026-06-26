---
paths:
  - "**/.yarnrc.yml"
  - "**/yarn.lock"
---

# Yarn Install Warnings

`yarn install` may produce warnings. All warnings MUST be resolved before closing any PR.

## Resolution order

Try fixes in this order. Stop at the first one that applies.

1. **Declare a missing dep.** If a workspace is missing a peer dep that is actually used, add it to that workspace's `package.json` `dependencies`. If a transitive's required range does not include the workspace's pin, bump the pin (or the upstream package if the pin is current).

2. **`packageExtensions`** in `.yarnrc.yml` for upstream metadata that misdeclares optional peers. Each entry MUST have a comment naming the warning code (e.g. `YN0002`) it resolves.
   - CAN: add missing `dependencies`, `peerDependencies`, or `peerDependenciesMeta`.
   - CANNOT: widen or narrow an existing peer range. `peerDependenciesMeta.<name>.optional: true` only suppresses missing-provider warnings, not version-mismatch warnings.

3. **`yarn patch <package>`** when steps 1-2 cannot fix it. Patches commit under `.yarn/patches/` and are reproducible.
   - CANNOT change peer-dep ranges used by the resolver. The patch updates the extracted `package.json` in `node_modules` but yarn keeps the original peer metadata in the lockfile and uses that for peer-requirement validation. Use `yarn patch` only for package source or runtime files.

4. **Narrow `text` `logFilter`** with `level: discard` as a last resort, only when steps 1-3 cannot fix the warning (genuine upstream metadata bug). Match the exact warning text — text matching is literal, not glob/regex. Add a comment naming the offending package, the upstream issue, and why steps 1-3 do not apply.
   - NEVER widen by upgrading a `code:` filter to `level: discard` — that hides every future warning of that code. Filter by `text:` only.
