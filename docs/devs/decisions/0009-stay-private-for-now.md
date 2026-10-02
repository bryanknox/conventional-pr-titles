# 0009 - Stay private for now

**Decision:** this repository stays private, accepting that the
Level 3 ruleset cannot exist here and that the PR-title check is
therefore advisory rather than required.

## Why

The audience is the author. Nothing here needs an outside reader
yet, and the two skills are useful to their users whether or not
the repository that develops them is visible.

## What it costs

**Level 3 is not merely unset, it is impossible.** On a private
repository under a free personal plan, every ruleset endpoint is
plan-gated. The ruleset cannot be created, so nothing mechanically
forces a change through a pull request: direct pushes to `main`
stay possible and the PR-title check is advisory. Using pull
requests here is a convention held by hand.

**Distribution is limited to accounts with access.** A plugin
marketplace entry pointing at a private repository resolves only
for someone who can already read it. That is fine while the author
is the only user, and it is the constraint to revisit first if
anyone else ever wants to install from here.

## Verified

2026-09-07, while running `enforce-conventional-commits` against
this repository:

```
$ gh api repos/bryanknox/skills-thrill/rulesets
Upgrade to GitHub Pro or make this repository public to enable
this feature. (HTTP 403)
```

The captured command names `skills-thrill`, which is what this
repository was called before the 2026-09-19 rename. It is left as
it was run.

That 403 is the definitive detector, and it is what Skill A keys
on. `GET /user` does not corroborate it: the `plan` field appears
only when the token carries the `user` scope, which gh's default
auth does not, so an empty plan read means *unknown*, never
*free*.

## Reversing this: going public

Ordered, because step 1 is the only one that cannot be undone.

**1. Audit what becomes visible, including history.** Going public
exposes every commit, not just the current tip.
[`validation-records/`](../validation-records/) and
[`test-repos.md`](../test-repos.md) name real repositories and
quote real command output; several files mention tokens and
scopes. Confirm that what they quote is scope *names* and not
scope *values*, and that no test-repository name needs to stay
unpublished. Assume anything that ships public has been read.

**2. Flip visibility to public.**

**3. Re-run `enforce-conventional-commits` against this repository.**
The re-run is idempotent by design: Levels 1 and 2 come back as
no-ops and it adds only the ruleset. Verify with the
effective-rules endpoint, which returns only actively enforced
rules:

```
gh api repos/{owner}/{repo}/rules/branches/main
```

Expect entries for `deletion`, `non_fast_forward`,
`pull_request`, and `required_status_checks`. An empty result
means the ruleset exists but is not enforced -- record that, do
not delete it.

**4. Expect your own workflow to change.** Once the ruleset is
active with an empty bypass list, direct pushes to `main` stop
working for the owner too. That is the point, but it is a surprise
if the habit is to push small doc fixes straight to `main`.

**5. Decide whether `Tier 1 checks` also becomes required.** The
skill's ruleset requires exactly one status-check context,
`Validate conventional PR title`. The CI workflow is deliberately
one job producing one context, so requiring it too is a one-line
addition to the ruleset -- but it is a choice the skill does not
make for you.

**6. Update the documents that currently say the check is
advisory:** the "Pull requests" section of
[`CLAUDE.md`](../../../CLAUDE.md), the "Commit and pull request
titles" section of [`README.md`](../README.md), the "Notes for
later" bullet in [`release.md`](../release.md), and the "What it
costs" section of this file.
