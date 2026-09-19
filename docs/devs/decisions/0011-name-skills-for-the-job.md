# 0011 - Name the skills for the job, not the convention

**Decision:** ship `enforce-conventional-commits` and
`write-pr-title`, in a repository and plugin both called
`conventional-pr-titles`.

**Status:** accepted 2026-09-19. Supersedes the names frozen at
commit `ad811d5`.

## Context

The repository was `skills-thrill`, which says nothing. The skills
were `setup-conventional-commits` and `pr-conventional-commits`,
which name the convention rather than the job -- and the second
names no verb at all, so it reads as a topic rather than an action.

The first proposal was `setup-pr-titles` and `write-pr-title`. It
was not adopted, for a measured reason.

## The name is a dispatch token

A skill is invoked because the request matched its name and
description together. These skills are also installed standalone,
copied as folders into `.claude/skills/`, so the plugin namespace
is not available to separate them. Each name has to work alone.

Scoring each token by how often it appears in one skill's
should-trigger prompts versus the other's, across the 40 prompts in
`tests/evals/`:

| Token | Skill A | Skill B | Separation |
|---|---|---|---|
| `main` | 6 | 0 | +6 |
| `commit` | 6 | 3 | +3 |
| `conventional` | 5 | 3 | +2 |
| `repo` | 3 | 1 | +2 |
| `check` | 2 | 3 | -1 |
| `title` | 4 | 6 | -2 |
| `pr` | 4 | 8 | -4 |

`pr` and `title` are the two weakest discriminators in the set.
`setup-pr-titles` is built from both, and drops `conventional` and
`commit`. It hooks 4 of Skill A's 10 should-trigger prompts and 9
of Skill B's -- it matches the sibling's prompts more often than
its own, losing "scaffold conventional commits in this repo",
"enforce conventional commits on main", and "configure this new
.NET repo for conventional commits".

It also undersells the skill. Skill A sets squash-merge settings, a
branch ruleset, and a workflow. "Set up PR titles" sounds like it
adds a title check.

`write-pr-title` has the opposite profile: 9 of its own, 4 of the
sibling's, against `pr-conventional-commits` at 8 and 8. Skill B's
rename was well supported by the same measurement that rejected
Skill A's.

The adopted pair shares no token at all. A is named for what it
achieves, B for what it produces.

## Consequences

Measured on the validation split, recorded in
[the rename gate record](../validation-records/rename-trigger-gate.md):
**gate PASS, 15/16**, both skills 4/4 on should-trigger, against a
control of 24/24 on the train split under the old names.

"add a PR title check" -- the coin-flip case the previous record
flagged -- still dispatches to Skill A.

One case got worse. "write conventional messages for each of my
local commits" now pulls `write-pr-title`, because the name leads
with the same verb the prompt does. It is inside the gate
threshold and was deliberately not tuned against, since it is a
validation prompt and tuning there spends the split.

Prompts naming the old skills stop resolving, which is a breaking
change; the plugin goes to 2.0.0. The GitHub slug redirects from
the old name, but the plugin name does not, so an existing
marketplace entry has to be removed and re-added.

## Alternatives

**`setup-conventional-main` / `write-pr-title`** scored best of
everything tested (+5 and +5), because `main` is the one token
Skill B's prompts never use. Rejected on prose: it hard-codes a
branch name the skill actually reads from the repository.

**Rename Skill B only**, leaving `setup-conventional-commits`.
Defensible -- it ships only what the evidence supported -- but
leaves the pair reading inconsistently, and the adopted Skill A
name matched the control's separation anyway.

**Keep both names.** The trigger evidence for the old pair was
fine. The argument against is not dispatch, it is that a reader
cannot tell from `pr-conventional-commits` what the skill does.

## Caution about the table above

It is a pre-screen, not a prediction. The old pair scored +2 and 0
and still dispatched 16/16, because the description carries most of
the load. It is also computed from the prompts in `tests/evals/`,
so it measures the prompt set as much as the name. It is for
deciding what a trigger-eval run should compare -- never for
skipping one.
