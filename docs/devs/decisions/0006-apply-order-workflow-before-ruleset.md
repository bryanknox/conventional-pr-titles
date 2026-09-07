# 0006 - Apply the workflow before the ruleset

**Decision:** Skill A applies its three levels in the order 1, 3, 2
-- merge settings, then the PR-title workflow, then the
default-branch ruleset. Not in numerical order.

## Why

The ruleset requires that changes to the default branch arrive
through a pull request. The workflow file has to be committed *to*
the default branch.

Create the ruleset first and the skill blocks itself: the very next
step is a direct commit that the ruleset it just created now
forbids. Recovering means opening a pull request mid-run, or
temporarily weakening the ruleset -- both turn a single-pass setup
into something messy and hard to make idempotent.

Committing the workflow first avoids the deadlock entirely, and the
whole setup stays one pass.

## Why the levels are still numbered 1, 2, 3

The numbering follows the *conceptual* layering used throughout the
documentation -- settings, then protection, then the check -- which
is how people think about the footprint. The apply order is an
implementation constraint.

Renumbering to match execution order would make the documentation
and the manual setup guide disagree with each other for no benefit.
The order is instead stated explicitly wherever it matters, and the
constraint is written down so it is not mistaken for an oversight.

## Do not reorder

If a future change makes it look like the ruleset should land first,
check whether that change also removes the need to commit anything
to the default branch. If it does not, the deadlock is still there.
