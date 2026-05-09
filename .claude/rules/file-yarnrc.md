---
paths:
  - "**/.yarnrc.yml"
  - "**/yarn.lock"
---

# Yarn Install Warnings

`yarn install` may produce warnings. All warnings MUST be resolved before closing any PR. Investigate the cause and fix it (e.g. add or remove a `packageExtensions` entry in `.yarnrc.yml`, pin a transitive dependency, or update the offending package).
