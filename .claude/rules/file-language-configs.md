---
paths:
  - "**/tsconfig*.json"
  - "**/jsconfig*.json"
  - "**/pyproject.toml"
  - "**/pyrightconfig.json"
  - "**/go.mod"
  - "**/go.work"
  - "**/Cargo.toml"
  - "**/Gemfile"
  - "**/composer.json"
  - "**/pom.xml"
  - "**/build.gradle"
  - "**/build.gradle.kts"
  - "**/Package.swift"
---

# Language Servers

Touching one of these config files requires the matching LSP plugin in `enabledPlugins` in the
project's committed `.claude/settings.json`, so the whole team gets it. Not `settings.local.json`,
and not user settings. If it is missing, add it in the same change.

| Config file | Plugin |
| --- | --- |
| `tsconfig*.json`, `jsconfig*.json` | `typescript-lsp` |
| `pyproject.toml`, `pyrightconfig.json` | `pyright-lsp` |
| `go.mod`, `go.work` | `gopls-lsp` |
| `Cargo.toml` | `rust-analyzer-lsp` |
| `Gemfile` | `ruby-lsp` |
| `composer.json` | `php-lsp` |
| `pom.xml`, `build.gradle` | `jdtls-lsp` |
| `build.gradle.kts` | `kotlin-lsp` |
| `Package.swift` | `swift-lsp` |

All are in the built-in marketplace, so enable them as `<plugin>@claude-plugins-official` with no
`extraKnownMarketplaces` entry. Install the language server binary separately; plugins configure
the connection only.

Do not use a third-party marketplace or a hand-written `.lsp.json` unless asked.
