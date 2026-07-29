# dev-info

This folder contains information helpful in the planning and development of agent skills in this repo.

## Dev toolchain

- **genesis** — the design-discipline skill used to produce the
  handoff packet below, and for future skill design work in this
  repo. Installed repo-scoped via `npx skills add danielmeppiel/genesis`
  ([skills.sh](https://skills.sh)), which places it at
  `.agents/skills/genesis/`, mirrors it to `.claude/skills/genesis/`
  via symlink, and pins it by content hash in `skills-lock.json`.
  It is deliberately NOT under `skills/`, so it never ships with the
  skills published from this repo.
  - Source: <https://github.com/danielmeppiel/genesis> (Apache-2.0;
    the installer does not copy `LICENSE`/`NOTICE` — see upstream).
  - Installed content verified identical to upstream commit
    `18e73c35e5cefaf431fbe4e080e8f125ebfece33` (2026-07-29), the
    version used to produce the handoff packet.
  - To update: re-run `npx skills add danielmeppiel/genesis`, then
    refresh the commit hash recorded here.
  - Maintenance policy (contributors): `.agents/skills/genesis/` and
    `.claude/skills/genesis/` are INSTALLER-MANAGED. Never hand-edit
    either folder; the only supported way to change their contents is
    re-running the install command above. Both trees are committed
    and must stay byte-identical in every commit.
    - On Windows the installer mirrors `.claude/skills/genesis/` as a
      directory junction pointing at `.agents/skills/genesis/`, so
      the two stay in sync automatically. The junction itself is not
      recorded in git.
    - On a fresh clone the two folders are independent copies;
      re-running the install command restores the mirror.
    - macOS/Linux caution: there the installer creates a true
      symlink, which git WOULD record — committing from such a
      machine can silently replace the 31 tracked files under
      `.claude/skills/genesis/` with a single symlink entry that
      breaks on Windows checkouts. PR review should reject any diff
      that turns that folder into a symlink or lets the two trees
      drift apart.
- **skill-creator** (<https://github.com/anthropics/skills>) — not
  installed; only its `evals.json` schema convention is borrowed by
  the eval files under `dev/evals/`.

## Plans

- [Conventional Commits Skills Plan (genesis handoff packet)](./conventional-commits-skills-plan.md)

## Dev info for Conventional Commits related skills

- [Conventional Commits Info Links](./conventional-commits-info-links.md)

- [Desires for Conventional Comments Setup](desires-for-conventional-commits-setup.md)

- [Setup Guide for Conventional Commits](./setup-guide-for-conventional-commits.md)

- [Type Guide for Conventional Commits](./type-guide-for-conventional-commits.md)

- [Skill Testing Repos](./skill-testing-repos.md)
