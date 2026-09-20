# Trigger-eval gate record for the 2026-09-19 rename

> **Record of the current trigger gate** (2026-09-19). Names and
> paths are current; no translation needed. The aggregate is in
> [evidence.md](../evidence.md) under "Trigger gates".

Status: COMPLETE (2026-09-19). GATE PASS for both skills on the
renamed `enforce-conventional-commits` / `write-pr-title` -- 15/16
validation-split prompts dispatched correctly.

- enforce-conventional-commits: should-trigger 4/4 (1.00 >= 0.5),
  near-miss 0/4 (0.00 < 0.5) -> PASS
- write-pr-title: should-trigger 4/4 (1.00 >= 0.5), near-miss 1/4
  (0.25 < 0.5) -> PASS

Claude Code CLI 2.1.220, model `claude-opus-5[1m]`. Run with
`tests/evals/run-trigger-evals.sh`, which is the same procedure
[testing.md](../testing.md) describes.

## Why a control run came first

The previous gate (the 2026-07-29 record, 16/16) was taken on
`claude-fable-5`. Scoring new names against a record taken on a
different model cannot distinguish a naming regression from a model
change, so the old names were re-scored on the train split first, on
the current model.

| Run | Split | Names | Result |
|---|---|---|---|
| Control | train (24) | old | 24/24, both skills 1.00 / 0.00 |
| Gate | validation (16) | new | 15/16, PASS |

The control is the number the rename had to hold, and it is a
stronger baseline than the 2026-07-29 record: 24/24 with perfect
boundary discipline in both directions.

## The harness was measuring the wrong thing

The first control attempt scored 20/24 and put Skill B at exactly
0.50, the gate threshold. That was not a regression. It was the
containment recipe failing on the current CLI.

`--allowedTools` is a permission allowlist. It does not remove
other tools from the session, so `Bash` remained available.
Sessions used it: they investigated the repository and spent the
whole `--max-turns 4` cap before ever calling a skill. One session
found the installed `SKILL.md` with `find` and read its frontmatter
with `head` -- reading the skill instead of invoking it.

Three Skill B prompts (B-T2, B-T8, B-T9) scored as dispatch
failures on that basis. Re-run with `--tools`, which restricts what
exists rather than what is permitted, all three dispatched the
skill as their **first** tool call, and the control went to 24/24.

This is the dangerous shape of defect for this repository. A
harness that under-measures dispatch is indistinguishable from a
skill whose description stopped working, and the documented remedy
for the latter is to edit the description -- which would have
turned a measurement error into a real regression. The flag and the
failure mode are now recorded in
[testing.md](../testing.md).

## Results (2026-09-19, validation split, new names)

| Case | Prompt | Expected | Invoked | Verdict |
|---|---|---|---|---|
| A-T3 | protect main so the PR title becomes the commit message | trigger | enforce-conventional-commits | PASS |
| A-T5 | configure this new .NET repo for conventional commits | trigger | enforce-conventional-commits | PASS |
| A-T7 | add a PR title check | trigger | enforce-conventional-commits | PASS |
| A-T10 | require pull requests and a conventional title check before anything lands on main | trigger | enforce-conventional-commits | PASS |
| A-N2 | fix the failing PR title check on my PR | no-trigger | write-pr-title | PASS (correct sibling dispatch, per eval note) |
| A-N5 | rebase my branch onto main | no-trigger | (none) | PASS |
| A-N7 | what does the ruleset on main do? | no-trigger | (none) | PASS |
| A-N10 | what are conventional commits and why would I use them? | no-trigger | (none) | PASS |
| B-T3 | what type should this change be, feat or fix? | trigger | write-pr-title | PASS |
| B-T5 | the semantic-pull-request check is failing | trigger | write-pr-title | PASS |
| B-T7 | open a PR for this breaking change | trigger | write-pr-title | PASS |
| B-T10 | the PR Title check went red after I edited the PR -- fix the title | trigger | write-pr-title | PASS |
| B-N2 | write conventional messages for each of my local commits | no-trigger | write-pr-title | **FAIL** |
| B-N5 | why did the CI build fail? | no-trigger | (none) | PASS |
| B-N7 | generate release notes from the commit history | no-trigger | (none) | PASS |
| B-N10 | set up semantic-release to publish versions from conventional commits | no-trigger | (none) | PASS |

## Observations

**A-T7 still dispatches correctly.** "add a PR title check" was the
pre-run coin-flip in the 2026-07-29 record, and the concern going
into the rename was that it would get worse, because the token
scoring put `pr` at -4 and `title` at -2 as discriminators. It went
to `enforce-conventional-commits` as intended. Naming Skill A for
what it achieves rather than for PR titles appears to have held the
boundary.

**B-N2 is a new failure, and it is attributable to the name.**
"write conventional messages for each of my local commits" pulled
`write-pr-title`. The old name `pr-conventional-commits` has no
verb; the new one leads with `write`, and the prompt leads with
"write". The prompt is about local commit messages, which neither
skill does.

The gate passes anyway -- one near-miss in four is 0.25 against a
0.5 bar -- but this is a real cost of the rename, not noise, and it
should be recorded as such rather than rounded away.

**It was deliberately not tuned against.** B-N2 is a *validation*
prompt. The split rule is that only train may be consulted while
adjusting a name or description; tuning against a validation prompt
spends the split and leaves nothing to gate with. The fix, if this
matters later, is to add prompts of this shape to *train*, tune the
boundary sentence there, and re-score.

**A related case to watch.** A-N1, "write a conventional commit
message for these changes", is the same shape and sits in Skill A's
train near-miss list. It scored `(none)` in the control, under the
old names. It has not been re-scored under the new ones. If the
"write" verb is systematically attracting commit-message prompts,
A-N1 is where it would show up next.

## Single-run caveat

One run per prompt, as in the previous campaign. Rates are point
estimates, not repeated trials. The should-trigger margins (1.00
against a 0.5 bar) are wide enough that re-sampling could not flip
them. The B-N2 near-miss result is a single observation and could
be sampling noise rather than a stable effect; the shape of the
explanation is what makes it worth recording, not the one data
point.
