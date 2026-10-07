# Next steps

**What this is for:** the order to work in, and nothing else. Each
item is one line pointing at the document that owns it. The registers
hold what a thing is and what would close it; this page holds only
which one to pick up next.

**Read it** at the start of a session, to find where the last one
left off.

**Write to it** when something becomes worth doing next, and delete
the row when it is done. A completed item leaves no trace here --
that is deliberate. What it proved belongs in
[evidence.md](evidence.md), what it found belongs in
[findings.md](findings.md), and git history holds the rest.

**The rule that keeps this file honest:** an item whose substance
lives only here is in the wrong file. Move the substance to the
register that owns it and leave the pointer.
[Decision 0013](decisions/0013-archive-the-validation-records.md)
deleted four "Disposition and follow-ups" sections for being the most
actionable-looking prose in the repository while every item in them
was inert. A backlog that restates its registers becomes that on its
own, because only one of the two copies gets updated -- and
`dev-absorb-campaign` updates the register.

Nothing here is a commitment, and the order is a judgement that the
next session is free to disagree with.

## The list

| # | Next step | Owned by |
|---|---|---|
| 1 | Decide whether to go public and re-run for Level 3 | [decision 0009](decisions/0009-stay-private-for-now.md) |
| 2 | Load both skills once in Cursor and in Codex | [known-gaps.md](known-gaps.md), "Untested configurations" |

Item 2 costs one session.

Not ranked, because it waits on an event rather than a turn: absorb
the next real tier-2 campaign with `dev-absorb-campaign`, whenever
one produces a verdict. See below.

## What no register owns

**Exercising `dev-test-repo-lifecycle` on a real campaign.** Only
its read-only inventory has run: once, on 2026-10-03, from a cold
headless session that dispatched to it and made exactly the two
preflight reads. Stage, reset, and teardown need a real repository
and have never run. Their first real use is the setup for item 1.
The thing to watch is the one test-repos.md warns about: that each
checkpoint is still answered by a human deciding, and not approved
straight through because the skill asked politely. That matters most
at a `gh repo create`, which no permission prompt guards any more.

**Exercising `dev-cut-release` on a real release.** It has never
run on one. One is already due:
`skills/enforce-conventional-commits/SKILL.md` has changed since
`conventional-pr-titles--v2.0.0` (#25), and nothing has bumped the
version since. Whether that change is worth releasing yet is the
maintainer's call. The skill does not make it. When it runs, the
things to watch are the two places release.md says a session misleads
by summarising: the manifest named on validate, and the warning list
copied rather than reduced to a verdict.

**Exercising `dev-absorb-campaign` on a real campaign.** It has been
run once, on a synthetic, discardable campaign: a fictional brief
absorbed in a throwaway worktree, graded against a checklist the
runner never saw, then deleted. Nothing reached the registers. The
brief was built to reach every branch -- a planted wrong read-back, a
run on a repo that no longer exists, a falsified prediction, and an
out-of-scope request. The skill passed, and the four places that
worked only because the runner improvised were fixed in PR #24.

What a dry run cannot show is how the skill does on a real campaign's
transcript against live repositories, and whether a human still reads
every result once the novelty is gone.

There is no register row to point at, and that is a consequence of
[decision 0014](decisions/0014-dev-skills-outside-skills-dir.md)
rather than an oversight: a dev skill deliberately carries no
requirement ids, no [behavior-spec.md](behavior-spec.md) entry, and
no evals, on the grounds that it is internal tooling with a human
reading every result. So the only thing that can record its state is
a line like this one.

Nothing more needs to be run for its own sake. The next real campaign
is the test, and the thing to watch is whether a human reading every
result is still what actually happens -- because 0014's reasoning
expires the moment a dev skill starts being trusted rather than read.
