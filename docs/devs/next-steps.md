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
| 1 | Exercise `dev-absorb-campaign` on a real campaign | nothing -- see below |
| 2 | Re-score A-N1 on the train split | [known-gaps.md](known-gaps.md), "Method gaps" |
| 3 | Load both skills once in Cursor and in Codex | [known-gaps.md](known-gaps.md), "Untested configurations" |
| 4 | Automate the repo-state half of the content evals | [known-gaps.md](known-gaps.md), "Method gaps" |
| 5 | Build the release dev skill, then the test-repo one | [decision 0014](decisions/0014-dev-skills-outside-skills-dir.md) |
| 6 | Close B-R9, B-R11, A-R2, and the org-repo gap | [known-gaps.md](known-gaps.md), "Untested requirements" |
| 7 | Decide whether to go public and re-run for Level 3 | [decision 0009](decisions/0009-stay-private-for-now.md) |

Cheapest first, roughly. Items 2 and 3 cost one session each; item 4
is the one that makes every later tier-2 run cheaper; item 6 needs
setup before it needs a session.

## The one item no register owns

**Exercising `dev-absorb-campaign`.** It has never been run. Its ten
steps, its human checkpoint, and its two refusals -- no independent
read-back it did not obtain from a live command, and no eval running,
repo creation, or releasing -- are all unexercised.

There is no register row to point at, and that is a consequence of
[decision 0014](decisions/0014-dev-skills-outside-skills-dir.md)
rather than an oversight: a dev skill deliberately carries no
requirement ids, no [behavior-spec.md](behavior-spec.md) entry, and
no evals, on the grounds that it is internal tooling with a human
reading every result. So the only thing that can record its state is
a line like this one.

Nothing needs to be run for its own sake. The next real campaign is
the test, and the thing to watch is whether a human reading every
result is still what actually happens -- because 0014's reasoning
expires the moment a dev skill starts being trusted rather than read.
