# 0014 - Internal dev skills live outside `skills/`

**Decision:** the repetitive maintainer procedures -- absorbing a
campaign, cutting a release, the test-repo lifecycle -- are worth
packaging as agent skills, and those skills never live in `skills/`.
Their home is `.claude/skills/`, with `.gitignore` narrowed to let
them be committed. Nothing is built yet; this records where they go
and why, before the question comes up again with a keyboard in hand.

**Status:** accepted 2026-09-19.

## Context

The development flows in this repository are now documented as
procedures a person drives from a Claude Code session: tier 1 and
the evals in [testing.md](../testing.md), the release in
[release.md](../release.md), the test repositories in
[test-repos.md](../test-repos.md). Writing them down made it obvious
which of them are mechanical enough to package, and packaging a
procedure in this repository means writing a skill -- that is the
thing this repository knows how to do.

The obvious place to put a skill is `skills/`. It is the wrong
place, for two reasons that are independent of each other, and one
of them fails silently.

## Why not `skills/`

**It would ship.** Neither manifest names a path. `skills/` at the
root *is* the plugin, which is what makes the layout so clean. The
same property means a folder added there is published to everyone
who installs, with no further step and no separate decision.

**It would contaminate the trigger evals.** This is the one that
does not announce itself. `tests/evals/run-trigger-evals.sh` builds
its fixture with `for dir in skills/*/`, copying every skill into
the throwaway repository the dispatch prompts run against. That is
deliberate -- a near miss belonging to the sibling skill has to be
able to reach it -- and it means a third skill silently joins the
dispatch surface the evals measure. A near-miss prompt could then be
claimed by a maintainer skill that has no business in the
measurement, and the score would move for a reason nobody would look
for.

Nothing catches this today. `lint-skills.sh` would lint the new
skill and pass it. `check-plugin-manifests.sh` asserts that `skills/`
holds *at least one* `<name>/SKILL.md`, so a third satisfies it.
Asserting the expected set of skill directories there is what would
close the gap, and is worth doing if a dev skill is ever built.

[Decision 0008](0008-maintainer-material-outside-skill-folders.md)
already answers this with its own test: does the skill read this at
runtime, in a user's repository? No, so it stays outside. This
decision is that rule applied to a case 0008 did not anticipate --
it was written about evals and documents, not about skills that are
themselves maintainer tooling.

## Why `.claude/skills/`, despite the ignore

`.gitignore` ignores `.claude/skills/` today, for two stated reasons:
third-party skills installed for development, such as the `genesis`
skill described in [design-process.md](../design-process.md), and
because this repository's own skills need no mirror there --
`claude --plugin-dir .` loads them from `skills/`.

A committed maintainer skill is a third category neither reason
covers. It is not a third-party install and it is not a mirror of
anything. Narrowing the ignore -- by the two shippable names, or by
ignoring everything except a `dev-` prefix -- keeps both original
protections. The comment above those lines has to be updated at the
same time, or the next reader derives the old rule from it and
deletes the new folder.

## Consequences

**They would be the only unproven agent primitives here.** No
requirement ids, no entry in [behavior-spec.md](../behavior-spec.md),
no content or trigger evals. In a repository whose argument is that a
skill is not believable until it has been run against something real,
that is a genuine inconsistency rather than an oversight to wave
through. It is accepted on the grounds that these are internal
tooling with a human reading every result, and that the alternative
-- a spec and an eval campaign for a release helper -- costs more
than the helper saves. If a dev skill ever starts being trusted
rather than read, that reasoning has expired.

**Tier-1 hygiene is nearly free.** `lint-skills.sh` already takes a
directory argument, so `bash tests/lint-skills.sh .claude/skills`
lints them for frontmatter, ASCII, wrapping and self-containment
without a new script. Worth wiring into the tier-1 sequence once
something is there to lint.

**Three procedures, not seven.** Tier 1 is five commands and needs no
skill. The trigger evals already have their automation in
`run-trigger-evals.sh`, and a skill wrapping a script is a second
description of the same procedure that can drift from it -- the
failure [testing.md](../testing.md) already warns about in the
opposite direction. Editing a `SKILL.md` is governed by the lint
rather than by a helper. What is left is the three named above, and
the test-repo one carries every human checkpoint in the repository,
so it is the last of the three to build, not the first.

**"Is this repository still configured?" is not on the list.** Every
command it needs already exists inside
`enforce-conventional-commits`, as its preflight and its read-backs.
A maintainer skill would be a second copy of them. That capability
belongs in the shipped skill, and is recorded as deferred work in
"Notes for later" in [release.md](../release.md).
