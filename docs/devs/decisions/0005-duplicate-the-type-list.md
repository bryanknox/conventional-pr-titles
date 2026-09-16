# 0005 - Duplicate the type list rather than share it

**Decision:** the ten conventional commit types appear in both
skills rather than in a shared file both reference.

## Why not share

Skills are distributed by copying one folder into a consumer's
repository. A shared file living beside the skill folders has two
possible outcomes, both bad:

- The user installs one skill. The shared file is not there, and the
  skill breaks at runtime, in the consumer's repository, in a way
  that is invisible from this repository.
- The skills are forced to always install together, so someone who
  only ever opens pull requests has to take repository-administration
  content they will never use -- which undoes
  [decision 0002](0002-two-skills-not-one.md).

## Why duplication is cheap here

The list is ten short words. It is anchored to the Angular
convention, which has been stable for years and is not a thing this
project controls or expects to change. The drift risk is close to
zero, and the failure mode if it ever did drift is mild -- a
suggested commit type that is slightly off, not a broken skill.

## The general rule

Between self-containment and DRY, self-containment wins in a skill
folder. A skill must work when copied alone into a repository that
contains nothing else from here.

This applies to any content shared between skills, not just the type
list. If two skills need the same paragraph, both get the paragraph.

## Where the deeper material lives

The full decision guide -- tie-breakers, ambiguous cases -- is
`references/type-guide.md` inside `pr-conventional-commits`, which
is the only skill that needs it, and it is read on demand rather
than carried in the body.

The user-facing version of the same material, including the semantic
versioning mapping deliberately left out of the skill reference, is
[the conventional commits guide](../../users/conventional-commits-guide.md).
Three copies exist on purpose, with different owners and audiences:
the skill body has the short list, the skill reference has the
decision rules, and the user guide has the explanation.

A fourth copy is not documentation at all. `assets/pr-title-workflow.yml`
pins the same ten in a `with: types:` block, so the enforcing copy
sits in the consumer's repository where they can edit it -- the list
they are allowed to change has to be a list they can see. That one is
guarded: `tests/check-workflow-template.sh` fails if the shipped
template drifts from the ten, because a template that silently
accepted a different set would contradict every copy above it.
