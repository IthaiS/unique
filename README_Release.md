# Release & Rollback Scripts

This repo ships two helper scripts to streamline versioned releases and safe rollbacks.

- `scripts/release.sh` — bumps versions, updates the changelog, creates and pushes a release tag, and (optionally) creates a GitHub Release.
- `scripts/rollback.sh` — deletes a mistaken tag (local & remote), resets the current branch back _N_ commits, and force-pushes with lease.

> **Tag format**: `vMAJOR.MINOR.PATCH` (e.g., `v1.2.1`)

---

## Table of contents

- [Prerequisites](#prerequisites)
- [Conventions](#conventions)
- [release.sh](#releasesh)
  - [Typical flow](#typical-flow)
  - [Examples](#examples)
  - [What it touches](#what-it-touches)
- [rollback.sh](#rollbacksh)
  - [Examples](#examples-1)
- [CI integration](#ci-integration)
- [Changelog format](#changelog-format)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Bash (Linux/macOS, or Git Bash on Windows)
- Git with write access to the repo’s default remote (`origin` by default)
- A **clean working tree** (no uncommitted changes)
- Standard Unix utilities (`sed`, `awk`, `grep`, `date`)
- Optional: [GitHub CLI](https://cli.github.com/) (`gh`) if you want the script to auto-create GitHub Releases

> If your CI requires tokens/secrets for release jobs, ensure they are configured in GitHub Actions settings.

---

## Conventions

- **Branches**: We typically cut releases from `main`. Hotfixes may come from `main` or a hotfix branch merged back to `main`.
- **Tags**: Annotated tags named `vX.Y.Z`.
- **Version bump locations** (if present):
  - Flutter app: `foodlabel-ai/mobile/pubspec.yaml`
  - Backend (if applicable): a `VERSION` file or similar.  
- **Changelog**: Uses a Keep-a-Changelog-style sectioning (see below).

---

## `release.sh`

Creates a new release with a single command.

```
scripts/release.sh v1.2.1 [options]
```

### Typical flow

1. Verifies:
   - Inside a git repo & on a branch (not detached)
   - Working tree is clean
   - Tag does not already exist
2. Bumps versions in known files (if present).
3. Updates `CHANGELOG.md`:
   - Moves items under **[Unreleased]** into a new `## [vX.Y.Z] - YYYY-MM-DD` section
   - Optionally injects provided release notes
4. Commits the bump, creates an **annotated tag**, and pushes branch + tag.
5. (Optional) Creates a GitHub Release via `gh release create`.

> The script is idempotent per tag; if a step fails after tagging, re-running will stop early when it sees the tag. Use `rollback.sh` to undo.

### Examples

Release `v1.2.1` with interactive confirmation:
```bash
scripts/release.sh v1.2.1
```

Non-interactive (CI/automation):
```bash
scripts/release.sh v1.2.1 --yes
```

Dry run (prints actions but does nothing):
```bash
scripts/release.sh v1.2.1 --dry-run
```

Provide extra notes (inline or from file):
```bash
scripts/release.sh v1.2.1 --notes "Test fixes for backend & frontend"
scripts/release.sh v1.2.1 --notes-file ./notes/1.2.1.md
```

Push to a different remote:
```bash
scripts/release.sh v1.2.1 --remote upstream
```

Create a GitHub Release (requires `gh`):
```bash
scripts/release.sh v1.2.1 --gh-release
```

### What it touches

- **Version bump** in:
  - `foodlabel-ai/mobile/pubspec.yaml` (`version:` field)
  - (Optionally) other known version files if your script is configured to do so
- **CHANGELOG.md**: inserts a section for the new version
- **Git**: makes a commit, creates an annotated tag, and pushes

---

## `rollback.sh`

Safely reverts a release by removing its tag and resetting the branch back by _N_ commits (default: 1), pushing with `--force-with-lease`.

```
scripts/rollback.sh <tag> [--commits N] [--remote origin] [--yes] [--dry-run]
```

- Deletes local tag if present
- Deletes remote tag if present
- `git reset --hard HEAD~N`
- `git push --force-with-lease`

> Uses guards for clean working tree, correct branch, upstream sanity, and prints a clear preview before executing.

### Examples

Roll back `v1.2.1` one commit (with confirmation):
```bash
scripts/rollback.sh v1.2.1
```

Roll back two commits, non-interactive:
```bash
scripts/rollback.sh v1.2.1 --commits 2 --yes
```

Dry run:
```bash
scripts/rollback.sh v1.2.1 --dry-run
```

Use a different remote:
```bash
scripts/rollback.sh v1.2.1 --remote upstream
```

---

## CI integration

- Pushing a tag like `v1.2.1` usually triggers your **release/build** workflows.
- The provided CI YAMLs already include logic to run on tag pushes (and have been updated to include tag steps).
- If you maintain an **infra apply** workflow (Terraform), ensure YAML is valid and gated by appropriate `paths:`/`branches:` filters.

---

## Changelog format

Follow a lightweight Keep-a-Changelog style. Example:

```markdown
# Changelog

## [Unreleased]
- Work in progress

## [v1.2.1] - 2025-09-10
### Fixed
- Backend & frontend test fixes (Owner admin, profiles endpoints, Flutter tests)

## [v1.2.0] - 2025-09-01
### Added
- Owner Administration support
```

During release, items under **[Unreleased]** are moved into the new version section with today’s date (unless you pass custom notes).

---

## Troubleshooting

**The script says the working tree isn’t clean**
- Commit or stash your changes first. Releases/rollbacks require a clean tree.

**Tag already exists**
- If you tagged by mistake, rollback with `scripts/rollback.sh vX.Y.Z --yes`.

**CI didn’t run after tagging**
- Ensure your workflow triggers include `on: push: tags: - 'v*'`.

**Changelog didn’t update**
- Make sure `CHANGELOG.md` exists and has a `## [Unreleased]` section.
- If your release notes are generated elsewhere, pass them via `--notes`/`--notes-file`.

**GitHub Release step failed**
- Install and auth GitHub CLI (`gh auth login`), or skip `--gh-release`.

---

### Quick start

```bash
# Release v1.2.1
scripts/release.sh v1.2.1 --yes

# Roll back v1.2.1 (undo last commit)
scripts/rollback.sh v1.2.1 --yes
```
