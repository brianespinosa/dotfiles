# @bje - BJE Enterprise

This directory contains repositories for the **bje** GitHub enterprise (billing contact `b@bje.co`).
It is a personal enterprise used to consolidate several orgs and projects under one roof so
management, policy, and automation are shared across many repositories.

Unlike `@momentive_emu`, this enterprise is **not** an EMU with a separate managed user. Membership
is held by the normal personal `brianespinosa` account, so credentials are inherited from the root
`~/Code/.envrc` and no enterprise-level `.envrc` exists here.

## Orgs

| Org directory      | GitHub org       | Notes                                                      |
| ------------------ | ---------------- | ---------------------------------------------------------- |
| `@bje-co/`         | `bje-co`         | Primary org (`blocks`, `bje.co`, `cm`, `.github`)          |
| `@bork-ltd/`       | `bork-ltd`       | No repos yet                                                |
| `@arsenalamerica/` | `arsenalamerica` | Arsenal America; has its own `.envrc` for `VERCEL_TEAM_ID` |

## Directory Structure

Org directories use the `@` prefix and match the GitHub org login exactly, the same convention as
`@momentive_emu`. When cloning a repo for org `bje-co`, the target path is
`@bje/@bje-co/<repo-name>`.

Orgs with no repos still get a directory so the enterprise layout stays complete and clone targets
are obvious.

## Migration from `@brianespinosa`

Most repos currently under `~/Code/@brianespinosa/` (the personal user namespace) are expected to
move into an org inside this enterprise over time. Forks are the likely exception -- they stay on
the personal user account. When a repo is transferred, move the local checkout to the matching
`@bje/@<org>/` directory rather than leaving it under `@brianespinosa/`.

## GitHub Credentials

Inherited from `~/Code/.envrc` (personal `brianespinosa` account, `~/.config/gh/personal`). No
per-enterprise override. `@arsenalamerica/.envrc` uses `source_up` and only adds Vercel config; it is
stowed from `@brianespinosa/dotfiles-private`.
