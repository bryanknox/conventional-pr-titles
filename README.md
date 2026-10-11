# conventional-pr-titles

Agent skills for enforcing
[Conventional Commits](https://www.conventionalcommits.org/) through
pull request titles.

> Enforcing conventional commits on the default branch via conventional
PR tiles promote freedom of commit message expression on other
branches. Avoiding the tyranny of pre-commits and other mechanisms
that suppress developer flow.

Two skills, used together or separately:

- **enforce-conventional-commits** configures a GitHub repository so
  squash is the only merge method and the pull request title (which
  becomes the commit message on the default branch) has to be a
  valid conventional commit. This skill is only run once in the repo
  by an admin.
- **write-pr-title** writes that title, from the actual
  branch diff. Run on every pull request, by anyone.

Commits on other branches stay unconstrained. No hooks, no
commit-message tooling, nothing needs to be installed in when devs
clone the repo. The PR title at merge time is the only gate enforced.

## Install

```
claude plugin marketplace add bryanknox/conventional-pr-titles

claude plugin install conventional-pr-titles@conventional-pr-titles
```

Both skills arrive together. Copying a single skill folder also
works -- see [the install guide](docs/users/install.md) for that,
and for what to do if the marketplace will not resolve.

## Documentation

- **[Using the skills](docs/users/README.md)** -- what they do, how to
  install them, and the convention itself if you would rather apply
  it by hand.
- **[Contributing](docs/devs/README.md)** -- architecture, authoring
  conventions, testing, and the decisions behind them.

## Status

Currently targets Claude Code, and ships as a Claude Code plugin
catalogued by this repository. The skills themselves are
harness-portable; only the install path is specific, so other
harnesses are a packaging change rather than a rewrite.

This repository is public, so anyone can install from it.
