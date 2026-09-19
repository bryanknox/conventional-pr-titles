# 0013 - Archive the validation records rather than maintain them

**Decision:** `docs/devs/validation/` becomes
`docs/devs/validation-records/` and is framed, in every place that
points at it, as an archive rather than as documentation. Each record
carries a banner saying so. The superseded 2026-07-29 trigger-eval
record and the four "Disposition and follow-ups" sections were
removed.

**Status:** accepted 2026-09-19.

## Context

[Decision 0012](0012-harvest-records-into-durable-artifacts.md) put
the durable content into four maintained documents and left the
records as the dated evidence those documents cite. That was right,
and it left the records filed as though they were living
documentation while being, correctly, frozen evidence. Four things
followed from the mismatch.

**The records read as unfinished work.** Each of the four campaign
records ended in a "Disposition and follow-ups" section --
`k0x-test-cc-s1b` awaiting operator deletion, which gh account to
switch back to, "Remaining plan todo: #9", a `delete_repo` scope to
drop when convenient. Every item was resolved long ago. None of it
said so. It is the most actionable-looking prose in the repository
and all of it is inert.

**One record existed only to say it was obsolete.** `trigger-evals.md`
carried two stacked supersession banners over a table of skill names
that no longer exist, measured on a model no longer in use.

**The name collided.** "validation" is also the name of the
`train`/`validation` eval split, so a grep for it, or an instruction
mentioning it, could land in either place.

**[README.md](../README.md) contradicted itself.** The folder appeared
in the "Start here" orientation list -- an invitation -- but in no row
of the task-routing table and nowhere in the development-flow diagram.
The flow was right. The bullet was the thing sending people somewhere
the flow never needs them to go.

At the time of the change the folder was about a quarter of
`docs/devs/` by volume, and roughly 1.6 times the size of the three
registers harvested out of it.

## Why delete a record, when 0012 chose preservation

Because `trigger-evals.md` was wholly contained elsewhere. Its result
-- 16/16 on the pre-rename descriptions, on `claude-fable-5` -- is a
row in the trigger-gates table in [evidence.md](../evidence.md), and
that row remains. What the file added beyond that row was a per-prompt
table keyed to names the repository no longer uses.

This narrows 0012 rather than reversing it. The rule is still that a
record is kept; the exception is a record whose every claim already
lives in a maintained document and whose detail is keyed to a
vocabulary that no longer resolves.

The same test is what kept the other five. Their structural-lint
snapshots, environment facts, and per-run narratives are not
duplicated anywhere, and could not be reconstructed without spending
real repositories again.

## Why a record's body was edited

`rename-trigger-gate.md` linked to `trigger-evals.md` in markdown, and
`check-links.sh` checks every relative link under `docs/`. Deleting
the target left two options: a red check, or an edit inside a record.

The link was turned into plain prose -- "the 2026-07-29 record" -- and
the surrounding paragraph rewrapped. Nothing it claims changed.

So the standing rule, that editing a record to keep its links green
would falsify it, now has one stated exception: **a link whose target
this repository deliberately deleted may be de-linked in place.** The
rule still forbids the case it was written for, which is silently
repointing a record at a renamed file so that the record appears to
have been written against the current layout. That is why the
pre-refactor paths in the other records are still wrong on purpose,
and still carried by a translation table in
[the folder README](../validation-records/README.md) instead.

## Why the follow-up sections went rather than getting a banner

A banner would have been the consistent choice, and it would have left
the most convincingly actionable text in the repository sitting under
it. The sections were operational sequencing -- which repository to
delete next, which numbered todo ran after this one -- not evidence of
what a skill did. Removing them takes nothing away from a disputed
verdict. Each record keeps a stub naming what was removed and the
commit that still has it.

## Consequences

The one forward-looking item in the folder moved out. The A-N1 watch
case, noted in `rename-trigger-gate.md` and nowhere else, is now a
method gap in [known-gaps.md](../known-gaps.md), which is a document
somebody reads before designing a campaign. Nothing in the archive is
now a live thread.

`tests/evals/write-pr-title/evals.json` cites a record by path inside
a prose string. That path is checked by `check-requirement-ids.sh`
rather than by `check-links.sh`, because the link checker reads
markdown only. A rename of this folder has to update it, and the
failure surfaces in a check whose name does not suggest links.

## Reversing it

To restore the folder as it stood, including `trigger-evals.md` and
the four follow-up sections:

    git checkout 671d6bd -- docs/devs/validation

That commit is the last one before this change. It restores to the old
path, so the rename has to be undone as well:

    git rm -r docs/devs/validation-records

Then repoint the citations: 36 links in `evidence.md`, one each in
`design-process.md`, `README.md`, `testing.md`, decisions 0009, 0010
and 0011, and the path string in
`tests/evals/write-pr-title/evals.json`.

To restore only the deleted record:

    git show 671d6bd:docs/devs/validation/trigger-evals.md

Nothing depends on it. The `evidence.md` row it backed states the
result in full.
