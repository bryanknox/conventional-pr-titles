# Designing a new skill

What worked when designing the two skills in this repository,
written as guidance rather than ceremony. If you are changing an
existing skill, [authoring.md](authoring.md) is the more useful
page.

## Decide the boundary before writing anything

The single most consequential decision is what the skill is *not*.
Both skills here are defined as much by their refusals as their
behavior, and those refusals are what make them dispatch correctly.

Two questions worth answering on paper first:

**Does this want to be one skill or two?** If the one-sentence
description needs an "and" joining two different verbs, it is
probably two skills. Check whether the halves change for different
reasons and run at different frequencies -- if so, splitting is
right. If they only *sound* separable, keep them together; a split
that has to be reassembled at runtime is worse than either.

**What is the adjacent thing it must not do?** Name it explicitly in
the description. It costs a sentence and it is what stops the
dispatcher from firing on a neighbor's territory.

## Write the description as a trigger, not a summary

See [authoring.md](authoring.md) for the anatomy. The point worth
repeating during design: you are writing the text that decides
whether the skill runs at all. Draft it early and treat later edits
as behavioral changes.

## Test the triggers, including the near misses

Before shipping, collect roughly twenty prompts per skill: half that
should invoke it, half that should not. Split them, tune the
description against one half only, and score the other half once the
wording is frozen.

**The near-miss half is where the information is.** Anyone can write
prompts that trigger their own skill. The prompts that reveal
problems are the ones that *nearly* match: a sibling skill's job, an
adjacent tool, a related question that deserves a plain answer. A
skill that fires on those is worse than one that occasionally misses.

Some near misses should correctly dispatch to a *sibling* skill.
That is a pass, not a failure -- note it in the eval so nobody
scores it wrong later.

The procedure is in [testing.md](testing.md); the results for the
current skills are in [evidence.md](evidence.md), under "Trigger
gates". The record behind the current numbers is
[the rename gate record](validation-records/rename-trigger-gate.md),
and it is worth reading for one reason beyond its result: the harness
was under-measuring dispatch, and a harness that under-measures is
indistinguishable from a description that stopped working. The
documented remedy for the latter is to edit the description, which
would have turned a measurement error into a real regression.

## Design the process spine before the prose

Write the ordered steps before writing any instructions, and check
each one against these:

- Where does it read state, and is every fact read rather than
  recalled?
- Where does it mutate, and is each mutation read back?
- Where can it fail, and does that failure land before any mutation
  or after all of them, rather than in the middle?
- Where does a human approve, and is it once?

Ordering constraints often fall out of this. Skill A's
workflow-before-ruleset order exists because writing the steps down
made the deadlock obvious -- the ruleset would have blocked the
commit that has to come next.

## Prove it against reality

A skill that has only ever been reasoned about is a draft. For
anything touching server-side state, that means a real run against a
real repository -- settings, rulesets, and checks cannot be faked
locally.

Run it **without** the skill too, on the same task. If the two runs
are indistinguishable, the skill is not adding value, and that is a
finding rather than a pass. The baseline runs for these skills found
exactly this in one place: in an already-configured repository,
Skill B's *titles* were not much better than the baseline, because
the baseline learned the convention from the workflow file. The
value was elsewhere -- in the process discipline -- and knowing that
is more useful than a green check.

Live runs are also where the surprises are. The finding that
free-plan private repositories refuse ruleset creation outright,
rather than creating an unenforced one, came from a real run and
contradicted what the documentation implied.

## About genesis

The two skills here were designed with
[danielmeppiel/genesis](https://github.com/danielmeppiel/genesis)
(Apache-2.0), a design-discipline skill that drives an eight-step
process producing diagrams, an interface sketch, and a written plan
before any prose gets drafted.

It is no longer installed. It was removed once both skills shipped:
its value is episodic, its cost was two thirds of this repository's
files. Re-add it when starting a genuinely new skill design:

```
npx skills add danielmeppiel/genesis
```

That places it at `.agents/skills/genesis/` and mirrors it to
`.claude/skills/genesis/`. Both paths are gitignored, so it cannot
be committed by accident. `.claude/skills/` is only *mostly* ignored
now -- the maintainer-only `dev-*` skills are committed from there --
but genesis stays ignored because it does not carry that prefix.
Keep third-party installs unprefixed and nothing changes.

The copy this repository used was verified
identical to upstream commit
`18e73c35e5cefaf431fbe4e080e8f125ebfece33`.

**Worth knowing before you use it:** genesis is dense and uses a lot
of its own vocabulary. The design work it produced here was
genuinely good, and the eight-step discipline is the reason the
boundaries between these two skills are as clean as they are. But
its output needs translating before it belongs in documentation that
other people read. The guidance on this page is that translation --
the practices, without the terminology.

## The worked example

The two shipped skills are the best reference for what good looks
like here. [architecture.md](architecture.md) explains their
structure, and [decisions/](decisions/) records why each contested
choice went the way it did.
