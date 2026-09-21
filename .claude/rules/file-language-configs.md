---
paths:
  - "**/tsconfig*.json"
  - "**/jsconfig*.json"
  - "**/package.json"
  - "**/deno.json"
  - "**/deno.jsonc"
  - "**/pyproject.toml"
  - "**/setup.cfg"
  - "**/requirements*.txt"
  - "**/Pipfile"
  - "**/go.mod"
  - "**/Cargo.toml"
  - "**/Gemfile"
  - "**/composer.json"
  - "**/pom.xml"
  - "**/build.gradle"
  - "**/build.gradle.kts"
  - "**/build.sbt"
  - "**/mix.exs"
  - "**/pubspec.yaml"
  - "**/*.csproj"
  - "**/*.fsproj"
  - "**/*.sln"
  - "**/CMakeLists.txt"
  - "**/*.cabal"
  - "**/stack.yaml"
  - "**/dune-project"
  - "**/Package.swift"
  - "**/*.tf"
---

# Language Servers for Configured Languages

A language config file in the repo means that language is a first-class part of the project.
If an official Claude Code LSP plugin exists for it, the project MUST use it. LSP gives real
diagnostics, definitions, and references instead of grep-based guessing.

## Required steps

1. Check what is available. The official list lives in the marketplace, not here: run
   `/plugin`, open the Discover tab, and search `lsp`. Reference docs, including the
   `.lsp.json` schema and the currently published plugins, are at
   <https://code.claude.com/docs/en/plugins-reference> (section "LSP servers").
2. If an official plugin covers the language, install it and install the language server
   binary separately. Plugins configure the connection only; they do not ship the server.
3. If no official plugin covers the language, say so and stop. Do not substitute a
   third-party marketplace or hand-rolled `.lsp.json` unless explicitly asked.

## Notes

- Never maintain a local list of supported languages or plugin names in this repo. Always
  read the marketplace or the docs page above, since the set changes.
- One extension is handled by one server: when several enabled servers claim the same
  extension, the first registered wins and the rest never start. Do not enable overlapping
  plugins for the same language.
- Verify after install: `/plugin` shows it enabled, and the LSP tool returns diagnostics for
  a file of that language.
