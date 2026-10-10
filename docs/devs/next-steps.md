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

Item 2 costs one session. The campaign working logs are outside the
repo, in `../test-repos/` beside this checkout.

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
never run: it belongs to `${REPO_PREFIX}pr`, which no campaign since
2026-07 has needed. Watch the same thing as before -- that each
checkpoint is answered by a human deciding rather than approved
straight through -- and watch reset the first time it runs.

**Exercising `dev-cut-release` on a real release.** It has run once,
for 2.1.0 (#38, tag `conventional-pr-titles--v2.1.0`). It stopped to
ask for the bump size rather than picking one, though #35 being a
`feat` made minor look obvious. It validated each manifest by name
and copied the one expected warning verbatim, before and after the
bump. One checkpoint covered the whole PR. It handed over
`claude plugin tag` and read the tag back against `origin/main`. Two
places improvised: Git Bash mangled `origin/main:path` until
`MSYS_NO_PATHCONV=1` was set, and nothing prompted retiring this
page's row, which is why the tag-phase report now names it. Watch the
same two things as before -- the manifest named on validate, and the
warning list copied rather than reduced to a verdict -- and whether
the bump question is still answered by deciding rather than by
accepting the first option.

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
