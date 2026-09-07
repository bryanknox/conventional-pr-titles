# skills-thrill

Agent skills for enforcing
[Conventional Commits](https://www.conventionalcommits.org/) through
pull request titles.

Two skills, used together or separately:

- **setup-conventional-commits** configures a GitHub repository so
  squash is the only merge method and the pull request title -- which
  becomes the commit message on the default branch -- has to be a
  valid conventional commit. Run once, by an admin.
- **pr-conventional-commits** writes that title, from the actual
  branch diff. Run on every pull request, by anyone.

Commits on branches stay unconstrained. No hooks, no commit-message
tooling, nothing installed in your clone. The title at merge time is
the only gate.

## Documentation

- **[Using the skills](docs/users/)** -- what they do, how to
  install them, and the convention itself if you would rather apply
  it by hand.
- **[Contributing](docs/devs/)** -- architecture, authoring
  conventions, testing, and the decisions behind them.

## Status

Currently targets Claude Code. The skills themselves are
harness-portable; only the install path is specific, so other
harnesses are a packaging change rather than a rewrite.

A [refactor](docs/devs/refactor-plan.md) of this repository's
structure is in progress.
