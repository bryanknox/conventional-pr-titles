# 0012 - Harvest the validation records into durable artifacts

**Decision:** the durable content of the validation records lives in
four maintained documents -- [behavior-spec.md](../behavior-spec.md),
[evidence.md](../evidence.md), [findings.md](../findings.md), and
[known-gaps.md](../known-gaps.md). The records stay as the dated
evidence those documents cite. The six raw session transcripts under
`validation/traces/` were removed.

**Status:** accepted 2026-09-19.

## Context

The records were framed as "evidence, not instructions", which was
correct and had an unintended cost: everything durable they discovered
was reachable only by reading dated prose. A maintainer could not
answer "what must this skill do?", "has this ever been run?", or "what
have we never tested?" without reading all six.

The harvest was in fact already happening, invisibly. `test-repos.md`
had absorbed live findings inline. Decision 0011 cited a record as its
evidence. `run-trigger-evals.sh` carried a harness defect from one as a
comment. `evals.json` recorded a falsified prediction. None of that was
discoverable from the records themselves, and none of it was complete.

## Why a separate spec, when SKILL.md already says what the skill does

Because SKILL.md says it in the imperative, to a model, interleaved
with how. There was no statement of the contract that a test could cite
and a reviewer could diff. Requirements were spread across seven
places, one of which -- decision 0001 -- opens by calling itself
historical.

The real cost is that a spec can drift from the skill it describes.
Three things hold it:

- The authority rule is stated in the spec itself. It states what must
  be true; SKILL.md is the instructions that achieve it. A disagreement
  is a bug in one of them, not a question of which wins, and the evals
  decide which.
- `check-workflow-template.sh` asserts the load-bearing literals -- the
  job name, the action pin, the type list -- in the template *and* in
  the spec, so the one string that couples A-R4 to A-R5 cannot drift in
  one place only.
- `check-requirement-ids.sh` fails if anything cites a requirement that
  does not exist, or if a requirement exists that `evidence.md` does
  not say has or has not been tested.

That last rule is what keeps the scheme from rotting into the state it
was built to fix. Adding a requirement forces a statement about whether
anything has ever proven it.

## Why the traces went

They existed so a disputed verdict could be checked rather than taken
on trust. Reading them showed that the property they were protecting
lives almost entirely in the independent dev-session read-backs -- the
ruleset ids, blob and commit SHAs, byte-identical pre/post snapshots --
and those are short. They are now in `evidence.md`, alongside the
handful of specifics that existed only in the traces: S4's second
ruleset id and its untouched `updated_at`, P5's exact 45-character
title, S5's mutation audit.

What was given up is the step-by-step command logs and the verbatim
runner reports. That is the part with real recovery value if a skill's
behavior is ever disputed at the command level, which is why this is a
decision and not a cleanup.

## Consequences

The records are no longer self-sufficient: four of them name
`traces/...` files in their status lines that are not in the working
tree. They were not edited, because editing a record to keep its
references green would falsify it -- the same rule that already governs
their pre-refactor paths. `validation-records/README.md` carries the
translation, as it already did for the renamed skills and the old
directory layout.

`docs/devs/` went from nine documents to thirteen, which is why the
README now leads with a flow diagram and a task-routing table rather
than a flat list.

## Reversing it

To restore the traces:

    git checkout da6936d -- docs/devs/validation/traces

That path is pre-rename and correct as written: the folder became
`docs/devs/validation-records/` in
[decision 0013](0013-archive-the-validation-records.md), after the
commit named here. That commit is the last one that touched them.
Nothing else needs undoing; `evidence.md` duplicates their
verification content rather than depending on it.

To retire the spec, delete `check-requirement-ids.sh` first, then the
`requirements` arrays in both `evals.json` files, then the `Covers:`
lines in `test-repos.md` -- in that order, or the check fails on
citations it can no longer resolve. Before doing it, note what goes
back to being unanswerable: `evidence.md` and `known-gaps.md` are both
keyed by requirement id, so they lose their spine, and the six untested
requirements they currently name become invisible again.
