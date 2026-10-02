# 0015 - Number the levels in the order they are applied

**Decision:** Skill A's levels are numbered in apply order. Level 1
is merge settings, Level 2 the PR-title workflow, Level 3 the
default-branch ruleset.

**Status:** accepted 2026-10-02. Supersedes the numbering section of
[decision 0006](0006-apply-order-workflow-before-ruleset.md); the
apply order 0006 fixes is unchanged.

## Context

The levels used to be numbered by concept -- settings, then
protection, then the check -- so the ruleset was Level 2 and the
workflow Level 3, while 0006 requires the workflow to land first.
0006 kept that numbering on the grounds that renumbering would make
the documentation and the manual setup guide disagree.

## Why renumber

The conceptual numbering cost a caveat everywhere it appeared:
"Level 3 lands before Level 2 deliberately", "apply 1 and 3 before
2", an apply order written `1, 3, 2`. Every reader had to hold the
two orders apart, and `architecture.md` had already slipped: its
list put the workflow second and its prose still called it Level 3.

0006's objection holds only for a partial rename. Renumbered
everywhere at once -- the skill, the spec, the evals, the
maintainer docs, and the user guide together -- nothing disagrees,
and the caveat disappears instead of being repeated.

What 0006 actually protects is the order, not the numbers. With the
numbers matching the order, a reader who applies the levels "in
order" now does the right thing by default.

## What was not renumbered

The archived validation records
([decision 0013](0013-archive-the-validation-records.md)) are
frozen evidence and keep the old numbering: in them, Level 2 or L2
is the ruleset and Level 3 or L3 the workflow. The Level entry in
[concepts.md](../concepts.md) says so.

Requirement ids did not change. A-R4 (workflow) and A-R5 (ruleset)
were already in apply order.
