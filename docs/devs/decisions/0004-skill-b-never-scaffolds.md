# 0004 - Skill B never configures a repository

**Decision:** `pr-conventional-commits` detects whether a repository
has the conventional-commits setup, and changes its own behavior
accordingly -- but never performs the setup, and never invokes
Skill A to do it. It reports the gap and recommends that an admin
run `setup-conventional-commits`.

This is the decision most likely to be eroded by a well-meaning
change, because auto-fixing looks helpful.

## Why not auto-fix

**Permission asymmetry.** Skill B's audience is contributors, who
usually do not have admin rights on the repository. For most of the
people who would hit this path, attempting the setup fails -- so the
"helpful" behavior is mostly an error message with extra steps.

**Scope escalation.** For the minority who *do* have admin rights,
it is worse. Someone asked for a pull request title and silently got
their repository's merge settings changed, a workflow committed, and
a branch ruleset created. Those are consequential, hard-to-notice
changes that nobody asked for.

**Boundary erosion.** Each skill's description names the other as
its boundary, and that sentence is part of what makes dispatch work
correctly. A skill whose stated boundary is not real is worse than
one with no stated boundary.

## What detection is actually for

The result branches Skill B's own behavior, which is legitimate:

- **Configured:** poll the PR-title check after applying the title,
  with a bounded retry.
- **Not configured:** skip the polling entirely -- there is no check
  to wait for -- and note the gap in the report with a
  recommendation.

Either way the title still gets composed and applied. A conventional
title is worth having in a repository that does not enforce one.

## Verified

Scenario P5 runs Skill B deliberately in a repository Skill A never
touched. The expected result, confirmed: a conventional title
composed from the diff and applied, check polling skipped, the gap
and recommendation reported, and **no attempt to scaffold**.
