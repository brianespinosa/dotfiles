---
paths:
  - "**/tsconfig*.json"
  - "**/jsconfig*.json"
  - "**/pyproject.toml"
  - "**/go.mod"
  - "**/Cargo.toml"
  - "**/Gemfile"
  - "**/composer.json"
  - "**/pom.xml"
  - "**/build.gradle"
  - "**/build.gradle.kts"
  - "**/Package.swift"
---

# Language Servers

This language MUST use an official Claude Code LSP plugin if one exists. Find it with
`/plugin` → Discover → search `lsp`; schema and current plugins are at
<https://code.claude.com/docs/en/plugins-reference>.

Install the language server binary separately; plugins configure the connection only.

If no official plugin covers the language, say so and stop. Do not use a third-party
marketplace or a hand-written `.lsp.json` unless asked.
