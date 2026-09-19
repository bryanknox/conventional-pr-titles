# enforce-conventional-commits

The `enforce-conventional-commits` skill configures an existing GitHub repository so the only route to the
default branch is a squash-merged pull request whose title is a valid
Conventional Commits message.

Run it once per repository. Re-running is a no-op.

## Who can run it

| | |
|---|---|
| Intended user | The repository owner or an admin. On a personal account that is the account owner. |
| Permission | `admin` on the target repository |
| gh scopes | `repo` **and** `workflow` |
| If you lack either | The skill stops **before changing anything**, names what is missing and who can run it |

## What to say

> Set this repo up to use conventional commits with squash merges.

It works on the repository your current directory points at. If there
is no `origin` remote it will ask which repository you mean.

## What it changes

Two kinds of change: one file added to your repository, and two
GitHub settings areas configured. Nothing else.

### Repository content it adds

One file, committed directly to the default branch:

| Path | What it is |
|---|---|
| `.github/workflows/pr-title.yml` | A GitHub Actions workflow that checks every pull request title against Conventional Commits |

That is the whole content footprint. No other file in your
repository is added, edited, or deleted: no git hooks, no
commit-message tooling, no dependencies added to your project, no
edits to existing files. If a `pr-title.yml` is already there and
differs from what the skill would write, overwriting it takes your
explicit approval.

The workflow uses `amannn/action-semantic-pull-request`, pinned to
`v6`. It runs on pull request open, edit, synchronize, and reopen
-- the *edit* trigger is what makes a corrected title re-check
immediately instead of leaving a stale failure. The allowed commit
types are written out in the file (`feat`, `fix`, `docs`, `style`,
`refactor`, `perf`, `test`, `build`, `ci`, `chore`) rather than
left to the action's defaults, so your repository states which
types it accepts. Edit that list whenever you like -- it is an
ordinary file in your repository after the skill hands it over.

**The workflow is deterministic.** It is plain GitHub Actions
running a pinned action that matches the title against the fixed
list of types in the file. No model, no judgment call, no
variance: the same title produces the same pass or fail every
time, and the rule being applied is readable in the file itself.

### GitHub repository settings it configures

Neither of these lives in your repository -- both are repository
settings on GitHub, changed through the API.

**Settings -> General -> Pull Requests** (merge settings):

| Setting | Set to |
|---|---|
| Allow merge commits | off |
| Allow rebase merging | off |
| Allow squash merging | **on** -- the only remaining method |
| Default squash commit message: title | the pull request title |
| Default squash commit message: body | blank (optional: the PR body) |
| Automatically delete head branches | optional, only if you ask |

**Settings -> Rules -> Rulesets:** one new ruleset named
`conventional-commits-main`, active, targeting the default branch.
It requires a pull request, requires that title check to pass, and
blocks force pushes and branch deletion. The bypass list is empty
-- nobody gets an exception, including you.

### The order, and why

The workflow file is committed *before* the ruleset is created, on
purpose: once the ruleset requires pull requests, committing the
workflow file directly to the default branch would be blocked.

There is no third kind of change. Commits on branches are
deliberately left alone -- the pull request title at merge time is
the only gate.

## What it does not do

- It does not create the repository or write any application code.
- It does not write pull request titles. That is
  [write-pr-title](write-pr-title.md).
- It does not touch a pre-existing ruleset it did not create. The
  default is to leave it alone and add its own alongside. Deleting or
  modifying yours requires you to say so explicitly.

## What you will be asked

One approval, before anything changes. You get the whole change as a
single diff -- current state to target state for the workflow file,
the merge settings and the ruleset alike, plus anything unusual it
found. Nothing is modified until you approve
it.

After that it runs to completion, reading every change back from
GitHub to confirm it took effect, and finishes with a report showing
before and after for each of the three.

## Known gaps

**Private repositories on a free plan cannot get the ruleset.**
GitHub gates rulesets on private personal repositories behind
GitHub Pro, and the gate is hard: every ruleset endpoint returns
403 `Upgrade to GitHub Pro or make this repository public`, so the
ruleset cannot be created at all.

The skill detects this before making any changes and tells you at the
approval step. It then applies the merge settings and the workflow
normally and reports the ruleset as blocked. You get title *linting*
but not the requirement that changes go through a pull request. Make
the repository public or upgrade to Pro, then run the skill again --
the re-run adds only the missing ruleset.

**The merge box is the residual soft spot.** GitHub lets whoever
clicks Merge hand-edit the final squash message, and nothing
validates that edit. The prefilled message is the title the check
approved. Do not touch it.

It widens if you take the optional squash-message setting `PR_BODY`
at the approval step. The merge box then prefills the commit body
from the pull request body, so the `BREAKING CHANGE:` footer that
setting exists to carry sits in an editable field on its way into
history. Nothing validates it -- the workflow lints the title, never
the body. The default `BLANK` keeps the body empty and the exposure
down to one subject line.

**The action version is pinned deliberately.** If
`amannn/action-semantic-pull-request` has a newer major version, the
skill keeps `v6` and mentions the lag in its report rather than
silently changing how your titles are linted.

## After it runs

Open pull requests with
[write-pr-title](write-pr-title.md). Everyone
contributing to the repository can use that one; they do not need
admin access, and they do not need this skill.
