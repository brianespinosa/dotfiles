# @brianespinosa: Personal User Repos

This directory is **not** a git repository and must never be initialized as one. Each subdirectory
is its own independent repo owned by the `brianespinosa` GitHub user.

Most repos here are migrating into orgs under the `@bje` enterprise (see `@bje/CLAUDE.md`); `bork`
and the 3D printing repos go to `@bje/@bork-ltd/`. Long term, only forks stay here.

## Security

Dependabot security alerts are enabled for every repo except forks of open source projects. Forks
have alerts disabled; security issues there are the upstream project's responsibility.

## Repository settings

GitHub repo settings are managed as code in the `settings` repo via the probot/settings app. A
consumer repo's `.github/settings.yml` holds a single `_extends` (e.g.
`brianespinosa/settings:nextjs.yml`). Change settings in `settings`, not in the consumer repo or
the GitHub UI. See `settings/README.md`.

## GitHub Actions repos

`release-action` holds the shared reusable release workflow. Its consumers
(`checkout-setup-node-install`, `job-root-cache`, `next-build-cache`) must stay identical in:

- `.github/workflows/release.yml`, which calls `release-action@v1`
- `.github/dependabot.yml`, covering `.github/workflows/` plus any directory with an `action.yml`
- Repo settings: squash merge on, merge commits and rebase merges off

When changing `.github/` structure or settings in one consumer, apply the same change to all.

## Web app repos

`career` is the reference implementation for toolchain standards. Use it as the source of truth for
dependency versions and configuration when planning work on `kandb.co`, `resume`, or
`zacharyscorner`. `tacomawedge` and `tacoma.fyi` are Astro sites; only the framework-agnostic parts
(Biome, Playwright + axe, Lefthook, Knip, CI structure) apply to them.
