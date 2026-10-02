# 0006 - Apply the workflow before the ruleset

**Decision:** Skill A applies merge settings, then the PR-title
workflow, then the default-branch ruleset -- Levels 1, 2, 3.

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

## How the levels are numbered

This decision originally kept a conceptual numbering -- 2 the
ruleset, 3 the workflow -- and applied the levels in the order 1,
3, 2. [Decision 0015](0015-number-levels-in-apply-order.md)
renumbered them to match the apply order. The order itself did not
change.

## Do not reorder

If a future change makes it look like the ruleset should land first,
check whether that change also removes the need to commit anything
to the default branch. If it does not, the deadlock is still there.
