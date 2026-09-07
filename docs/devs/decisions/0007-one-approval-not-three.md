# 0007 - One approval, not one per level

**Decision:** Skill A presents its entire three-level change as a
single reviewable diff and asks for approval once, before any
mutation. It does not ask before each level.

## Why

The three levels are one change. Approving the merge settings but
not the ruleset produces a half-configured repository that nobody
wanted -- there is no useful decision to make between the levels, so
asking is a question with only one sensible answer.

**Repeated prompting trains people not to read.** A skill that asks
three times gets three reflexive approvals. One prompt that presents
the complete change is more likely to actually be reviewed, which is
the entire point of having a checkpoint.

The checkpoint sits before *all* mutations, so declining leaves the
repository untouched. That is only true because it comes first;
per-level checkpoints would mean declining the third one leaves two
already applied.

## What the checkpoint has to contain

Enough to make approval meaningful:

- Each level's current state and target state.
- Anything unexpected -- a pre-existing ruleset, a workflow file
  that differs from the template.
- Any gap that will not be closeable, such as the ruleset being
  blocked on a free-plan private repository.

Two things must always be acknowledged explicitly rather than
happening silently: overwriting something that already exists, and
proceeding when a level is known to be blocked.

## Where a second approval is correct

Skill B has a checkpoint on a narrower trigger: retitling a pull
request that it did not write this session, or that belongs to
someone else. That is not a per-step prompt -- it is a different
kind of consent, for touching another person's work.

Naming the pull request explicitly is itself the approval. "Fix the
title on PR 5" already contains the decision, and asking again would
be the reflexive-approval problem in miniature.
