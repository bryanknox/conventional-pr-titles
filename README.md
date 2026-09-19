# conventional-pr-titles

Agent skills for enforcing
[Conventional Commits](https://www.conventionalcommits.org/) through
pull request titles.

Two skills, used together or separately:

- **enforce-conventional-commits** configures a GitHub repository so
  squash is the only merge method and the pull request title -- which
  becomes the commit message on the default branch -- has to be a
  valid conventional commit. Run once, by an admin.
- **write-pr-title** writes that title, from the actual
  branch diff. Run on every pull request, by anyone.

Commits on branches stay unconstrained. No hooks, no commit-message
tooling, nothing installed in your clone. The title at merge time is
the only gate.

## Install

```
claude plugin marketplace add bryanknox/conventional-pr-titles
claude plugin install conventional-pr-titles@conventional-pr-titles
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
