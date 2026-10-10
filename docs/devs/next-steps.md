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
| 1 | Cut the release that ships #35 | [release.md](release.md), "Cutting a release" |
| 2 | Decide whether to go public and re-run for Level 3 | [decision 0009](decisions/0009-stay-private-for-now.md) |
| 3 | Load both skills once in Cursor and in Codex | [known-gaps.md](known-gaps.md), "Untested configurations" |

Item 1's gates are met: #35 moved the contract, and the S6, P6, P7,
and P8 re-runs with their baselines passed and were absorbed
([evidence.md](evidence.md)). What remains is `dev-cut-release` with
the bump the maintainer states. The campaign working logs are outside
the repo, in `../test-repos/` beside this checkout. Item 3 costs one
session.

Not ranked, because it waits on an event rather than a turn: absorb
the next real tier-2 campaign with `dev-absorb-campaign`, whenever
one produces a verdict. See below.

## What no register owns

**Exercising `dev-test-repo-lifecycle` on a real campaign.** Stage
and teardown have now run for real, in the 2026-10 campaign: nine
stagings (S6, O1, O5, P6, P7, P8, and the three P baselines) across
seven created repositories, all seven torn down one confirmed delete
at a time. Every
create and every delete was a decision the maintainer made at the
moment. Real use found four procedure faults, T-F4, T-F5, T-F6, and
T-F7 in [findings.md](findings.md), fixed afterwards. Reset has still
never run: it belongs to `k0x-test-cc-pr`, which no campaign since
2026-07 has needed. Watch the same thing as before -- that each
checkpoint is answered by a human deciding rather than approved
straight through -- and watch reset the first time it runs.

**Exercising `dev-cut-release` on a real release.** It has never
run on one. One is already due:
`skills/enforce-conventional-commits/SKILL.md` has changed since
`conventional-pr-titles--v2.0.0` (#25), and nothing has bumped the
version since. Whether that change is worth releasing yet is the
maintainer's call. The skill does not make it. When it runs, the
things to watch are the two places release.md says a session misleads
by summarising: the manifest named on validate, and the warning list
copied rather than reduced to a verdict.

**Exercising `dev-absorb-campaign` on a real campaign.** It first ran
on a synthetic, discardable campaign, whose four improvised places
were fixed in PR #24. Then it absorbed the real 2026-10 campaign in
PR #33. That run took live read-backs for every server-state claim.
It wrote NOT INDEPENDENTLY VERIFIED for every report-content claim,
and for the one repository a later run had altered it cited the saved
read-back and said why. One approval covered the whole diff.

What one real run cannot show is whether a human still reads every
result once the novelty is gone.

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
