# Setup Guide for Conventional Commits

Guide for setting up conventional commits in a GitHub repo for a .NET application. Based on [Desires for Conventional Comments](./desires-for-conventional-commits.md).

The whole footprint: three GitHub repo settings toggles, one GitHub repo ruleset, one ~20-line YAML GitHub workflow file.

## Level 1: GitHub Repo settings

GitHub Repo → Settings → General → Pull Requests

- Uncheck "Allow merge commits"
- Uncheck "Allow rebase merging"
- Check "Allow squash merging," and set its default commit message to "Pull request title" (or "Pull request title and description" if you want the PR body as the commit body — nice for context, and BREAKING CHANGE: footers can live there)

This alone makes squash the only possible merge method for every PR, on any plan. Optionally also enable "Automatically delete head branches" for tidiness.

## Level 2: GitHub Repo Ruleset on main

GitHub Repo → Settings → Rules → Rulesets

Create a ruleset targeting main with:

- Restrict deletions and Block force pushes (usually on by default)

- **Require a pull request before merging**
  -  This is what prevents direct pushes.
  -  Required approvals can be 0 since it's your repo; the PR just has to exist.

- **Require status checks to pass**
  -  Add the PR title check (workflow) from Level 3 by its job name (it appears in the picker once it has run at least once). This is what makes the title lint binding rather than advisory.

- **Bypass list: empty**
  -  Since you no longer want to push directly, don't add yourself — that keeps you honest too. (If you ever need an escape hatch, you can add Repository admin later or temporarily set the ruleset to "Evaluate.")

You can skip the ruleset's merge-method rule — with only squash enabled at the repo level, it's redundant.

**Plan reminder:**
- This ruleset works free on public personal repos;
  -  A private personal repo needs GitHub Pro.

## Level 3: GitHub Actions Workflow

One workflow file in the repo.

```yaml
.github/workflows/pr-title.yml:
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
       -  uses: amannn/action-semantic-pull-request@v6
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

The edited trigger matters: when someone fixes a bad title, the check re-runs immediately instead of leaving a stale failure.

The action's defaults follow the Conventional Commits type set. You can pin allowed types and scopes in a `with:` block if you want to constrain it further (e.g., only feat, fix, chore, docs, refactor, test, build, ci).

Then merge that workflow, let it run once on any PR, and go back to the ruleset to select `Validate conventional PR title` as the required check.

## Level 4 (local git repo): nothing

No Husky.Net, no hooks, no dotnet tools. Contributors — including you — commit however they like on branches, and the only gate is the PR title at merge time.

## One residual soft spot

- The merge box in the PR lets the merger hand-edit the final squash message, and nothing validates that edit. As the sole merger, that's just "don't touch the prefilled message."
