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

## Install

```
claude plugin marketplace add bryanknox/skills-thrill
claude plugin install skills-thrill@skills-thrill
```

Both skills arrive together. Copying a single skill folder also
works -- see [the install guide](docs/users/install.md) for that,
and for what to do if the marketplace will not resolve.

## Documentation

- **[Using the skills](docs/users/)** -- what they do, how to
  install them, and the convention itself if you would rather apply
  it by hand.
- **[Contributing](docs/devs/)** -- architecture, authoring
  conventions, testing, and the decisions behind them.

## Status

Currently targets Claude Code, and ships as a Claude Code plugin
catalogued by this repository. The skills themselves are
harness-portable; only the install path is specific, so other
harnesses are a packaging change rather than a rewrite.

This repository is private, so installing from it works only for an
account that can read it.

A [refactor](docs/devs/refactor-plan.md) of this repository's
structure is in progress.
