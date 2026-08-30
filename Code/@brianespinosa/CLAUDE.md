# @brianespinosa — Claude Code Guidance

All repositories here are owned by the `@brianespinosa` GitHub user. This directory itself is **not** a git repository and must never be initialized as one — each subdirectory is its own independent git repo.

Most repos here are being migrated into orgs under the `@bje` enterprise for easier management. Moving forward, repos at the user level will likely only be forks for doing open source work.

Where possible, the goal is to have repositories in this directory share as much of the same tooling as possible. This file should explicitly call out which groups are sharing similar tooling.

## Security

Dependabot security alerts should be enabled for all repos except forks of open source projects we contribute to. Forks (e.g. `codehike`, `react-textfit`, `Semantic-UI-React`, `setup-node`) should have alerts disabled — security issues in those are the upstream project's responsibility.

## Repository Settings (`settings`)

The **`settings`** repo is the central source of truth for GitHub repository settings across all repo groups, enforced via the [probot/settings](https://github.com/apps/settings) GitHub App.

Settings are organized as:
- `base.yml` — base settings shared by all repos
- `nextjs.yml` — extends base; consumed by Next.js app repos
- `actions.yml` — extends base; consumed by GitHub Actions repos
- `.github/settings.yml` — the settings repo's own settings, extends base

Consumer repos contain a `.github/settings.yml` with a single `_extends` pointing to the appropriate file in this repo (e.g. `_extends: brianespinosa/settings:nextjs.yml`). The probot/settings app resolves the chain recursively, so changes to base propagate to all consumers automatically.

## GitHub Actions Repositories

This directory contains a family of GitHub Actions repos. All consumer repos share identical tooling — when changing `.github/` structure or repo settings in one, apply the same change to all.

**`release-action`** — shared reusable workflow providing automated semver releases, changelog generation, GitHub release creation, and alias tag management. All release logic lives here; consumers call it via a thin wrapper.

Consumer repos:
- **`checkout-setup-node-install`** — checkout, Node/yarn setup, and install
- **`job-root-cache`** — save/restore/cleanup a run-scoped working directory cache across jobs
- **`next-build-cache`** — Next.js build cache for faster CI

Every consumer repo must have identical:
- `.github/workflows/release.yml` — calls `release-action@v1`
- `.github/dependabot.yml` — covers `.github/workflows/` plus any subdirectory containing an `action.yml`
- Repo settings: squash merge on, merge commits off, rebase merges off

## Bork Tools Repositories

> **Temporary section.** All bork and 3D printing repos are moving into the `bork-ltd` org
> (`@bje/@bork-ltd/`) and being split up this week. `shippo-packing-slips` has already moved.
> Once the rest have moved, delete this section.

A set of repositories supporting a 3D printing business. `bork` is always private. Others may be open-sourced as standalone tools or eventually merged into `bork`.

- **`bork`** — private; central repository for filament research, business data, and tooling
- **`prusa-connect-auto-ready`** — webhook handler for Prusa Connect printer state automation
- **`3d-printer-profiles`** — custom slicer profiles for Prusa MK4S

## Next.js App Repositories

Personal Next.js applications. `career` is the reference implementation — all others should be brought up to match its toolchain over time.

- **`career`** — resume and career materials site; **reference repo for toolchain standards**
- **`kandb.co`** — KandB site (currently a static site; needs to be converted back to a Next.js app)
- **`resume`** — resume site (Next.js 14; needs upgrading)
- **`tacomawedge`** — Tacoma Wedge site (Next.js 16; partially aligned)
- **`zacharyscorner`** — Zachary's Corner site (needs upgrading)

**Target toolchain (match `career`):**
- Next.js (latest), React 19, TypeScript
- Biome (replaces ESLint + Prettier)
- Vitest + Testing Library + happy-dom
- Playwright + `@axe-core/playwright`
- Lefthook (pre-commit hooks)
- Knip (dead code detection)
- Same `.github/workflows/ci.yml` structure

When creating issues or planning work on these repos, use `career` as the source of truth for dependency versions and configuration.

## GitHub Profile Repository

- **`brianespinosa`** — [GitHub profile README](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-github-profile/customizing-your-profile/managing-your-profile-readme); the `README.md` in this repo appears at the top of the `@brianespinosa` GitHub profile page

## Other Repositories

- **`Figjam Widgets`** — FigJam widgets in development, not yet published
- **`filter`** — prototype filtering experience (React components: Filter, Flex, Popover, hooks)
- **`google-calendar-health-report`** — Google Apps Script that sends a Slack DM summarizing calendar issues
- **`speaking-contexts`** — materials and LLM context for conference talk proposals
- **`zacharymichaelcruz`** — backup of an old Craft CMS site; kept as a code reference for `zacharyscorner`
