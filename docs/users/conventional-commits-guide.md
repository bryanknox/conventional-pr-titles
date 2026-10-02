# Conventional commits guide

The convention itself, and the repository setup that enforces it,
written so you can follow or apply either one by hand. The two skills
in this repository automate what is described here; nothing below
depends on them.

## The approach

[Conventional Commits](https://www.conventionalcommits.org/) is a
format for commit messages. There are many ways to enforce it. This
one enforces at exactly one point: **the pull request title, at
squash-merge time.**

That choice has consequences worth being explicit about.

- Squash is the only merge method, so every pull request becomes
  exactly one commit on the default branch.
- That commit's message is the pull request title, so linting the
  title is the same as linting the history.
- Commits on branches are never checked. No hooks, no commit-message
  tooling, nothing installed in anyone's clone.

The trade is deliberate: you give up conventional commit messages on
branches, which nobody reads after a squash, and in exchange the
enforcement is server-side, applies to every contributor
automatically, and requires no local setup from anyone.

## Setting up a repository by hand

Three levels, applied in order. The ruleset comes last, or it will
block you from committing the workflow file.

### Level 1: repository settings

**Settings -> General -> Pull Requests**

- Uncheck *Allow merge commits*
- Uncheck *Allow rebase merging*
- Check *Allow squash merging*, and set its default commit message to
  **Pull request title**

Choose *Pull request title and description* instead if you want the
PR body to become the commit body. That is what lets a
`BREAKING CHANGE:` footer ride into the commit.

This alone makes squash the only possible merge, on any plan.
Optionally also enable *Automatically delete head branches*.

### Level 2: the PR-title workflow

One file, `.github/workflows/pr-title.yml`:

```yaml
name: PR Title
on:
  pull_request:
    types: [opened, edited, synchronize, reopened]
permissions:
  pull-requests: read
jobs:
  lint-pr-title:
    name: Validate conventional PR title
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v6
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            docs
            style
            refactor
            perf
            test
            build
            ci
            chore
```

Three details matter:

- The `edited` trigger. Without it, fixing a bad title leaves the
  old failure sitting there until something else re-runs the check.
- The job **name** (`Validate conventional PR title`) is what the
  Level 3 ruleset requires by string. Renaming the job silently
  breaks enforcement.
- The `types:` list. The action's defaults already match the ten
  below, but they are written out anyway so the types your
  repository accepts are visible in your repository rather than
  implied by a version of somebody else's action.

**This list is yours to customize.** Drop the types you will never
use, or add your own -- `revert` is the common addition. Keep
`feat` and `fix`: they are what the specification defines, and what
release tooling reads to decide a version bump. Whatever you keep
is exactly what the check accepts, so narrowing the list makes the
check stricter, not looser.

### Level 3: a ruleset on the default branch

**Settings -> Rules -> Rulesets**

Create a ruleset targeting the default branch with:

- *Restrict deletions* and *Block force pushes*
- *Require a pull request before merging* -- this is what prevents
  direct pushes. Required approvals can be 0; the pull request just
  has to exist.
- *Require status checks to pass*, and add the PR-title check from
  Level 2 by its job name. It appears in the picker once it has run
  at least once.
- **Bypass list: empty.** Do not add yourself. If you ever need an
  escape hatch, set the ruleset to *Evaluate* temporarily rather than
  granting a permanent exception.

You can skip the ruleset's merge-method rule. With only squash
enabled at Level 1 it is redundant.

**Plan limits.** This works free on **public** personal
repositories. A **private** personal repository needs GitHub Pro --
and the gate is absolute, not partial: every ruleset endpoint returns
403 until you upgrade or make the repository public. Levels 1 and 2
work regardless.

### Level 4: nothing

No hooks, no commit tooling, no dependencies. This is a level on
purpose, so its absence reads as a decision rather than an omission.

### The one residual soft spot

GitHub's merge box lets whoever merges hand-edit the final squash
message, and nothing validates that edit. Both fields -- subject
and body -- are editable whichever squash message setting you
chose. The setting only decides what is prefilled.

- With *Pull request title*, the body arrives empty, so the risk is
  something getting **added**.
- With *Pull request title and description*, the body arrives
  prefilled from the pull request, footer and all, so the risk is
  something getting **lost**. Deleting a `BREAKING CHANGE:` footer
  there takes one keystroke and drops a MAJOR version bump, and
  nothing will complain: the check reads the title, never the body.

The prefilled text is what the check approved. Leave both fields
alone.

## Writing the title

```
type(scope)!: description
```

- **type** -- lowercase, from the ten below.
- **(scope)** -- optional; a short noun for the area touched, like
  `api` or `parser`. Omit it rather than invent one.
- **!** -- only for breaking changes.
- **description** -- imperative mood ("add", not "added" or "adds"),
  lowercase start, no trailing period.
- Keep the whole title within 72 characters.

## The ten types

Two come from the specification (`feat`, `fix`); the other eight are
the Angular convention, which became the de-facto standard set.

| Type | Use for | Version impact |
|---|---|---|
| `feat` | A new capability users can interact with or rely on | MINOR |
| `fix` | Correcting incorrect behavior | PATCH |
| `perf` | Same behavior, faster or more efficient | PATCH |
| `refactor` | Restructuring without changing behavior | none |
| `style` | Formatting only: whitespace, semicolons, lint fixes | none |
| `test` | Tests, fixtures, mocks; no production code change | none |
| `docs` | Documentation, including comments that explain behavior | none |
| `build` | Build system or shipped dependencies | none |
| `ci` | Pipelines, workflows, actions | none |
| `chore` | Maintenance fitting none of the above | none |

The version-impact column matters only if you run release tooling
that reads commit types. Nothing in this repository does; the column
is here because it is the reason the type list is worth taking
seriously.

## Choosing a type

Ask in order. First match wins.

1. Does it change behavior users can observe? Broken behavior
   corrected is `fix`; a new capability is `feat`; same behavior but
   faster is `perf`.
2. Does it change production code without changing behavior?
   Restructuring is `refactor`; formatting only is `style`.
3. Tests only is `test`. Documentation only is `docs`.
4. Tooling: build system or shipped dependencies is `build`;
   CI and workflows is `ci`; anything else is `chore`.

### Tie-breakers

- **Dependency bumps** -- `build` when the dependency ships in the
  product, `chore` when it is dev-only tooling.
- **A refactor that fixes a bug along the way** is a `fix`.
- **Tests added alongside a feature or fix** take the feature or fix
  type. `test` is for test-only changes.
- **Comments explaining behavior** are `docs`; deleting
  commented-out code is `refactor` or `chore`.
- **Mixed changes** -- a squash-merged PR becomes one commit, so it
  gets one type. Pick by dominant user impact (`feat` over `fix` over
  `perf` over the rest). If two genuinely unrelated changes share a
  branch, split the pull request instead of blending types.

## Breaking changes

A change is breaking when consumers must change their own code or
configuration: a removed or renamed public API, a changed default, a
schema or config format change.

Any type can be breaking. Mark it **both** ways:

- `!` after the type or scope:
  `feat(api)!: remove deprecated v1 endpoints`
- A `BREAKING CHANGE: <explanation>` footer as the **last** paragraph
  of the pull request body. Attribution and tooling trailers go
  above it.

Breaking changes trigger a MAJOR version bump under semantic
versioning.

Remember that the footer only reaches the squash commit if the
repository's squash message setting is *Pull request title and
description*. Otherwise it lives on the pull request only.

The `!` is the half that enforcement covers. Nothing checks the
footer, and when it does reach the commit it passes through an
editable field in the merge box on the way. That is the reason to
mark breaking changes both ways instead of picking one.

## For anything not settled here

Reverts, multiple footers, and unusual formats are covered by the
specification itself. Check it rather than extrapolating.

## References

- [Conventional Commits specification v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
  -- the official rules.
- [jayeshmepani/conventional-commits-reference](https://github.com/jayeshmepani/conventional-commits-reference/tree/main)
  -- a curated merge of the spec, the Angular convention, extended
  types, and SemVer mapping.
- [Conventional Commits Guide: Rules, Tools and CI/CD Enforcement](https://www.deployhq.com/blog/conventional-commits-a-standardized-approach-to-commit-messages)
  -- practical per-type guidance.
