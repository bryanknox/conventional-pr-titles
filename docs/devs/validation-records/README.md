# Archived validation records

Dated records of what was actually run against real GitHub
repositories, and what it found. These are **evidence, not
instructions** -- read [testing.md](../testing.md) for how to run
things now. Nothing in here is a to-do list, and nothing in here is
outstanding work.

They are kept because they cost real repositories, real API calls,
and real money to produce, and because several of them record
findings that contradict what documentation implied.

## You probably want one of these instead

Everything durable in these records has been lifted into artifacts
that are maintained. Come here for the dated detail behind a claim;
go there for the claim itself.

| Question | Where it is answered |
|---|---|
| What must the skills do? | [behavior-spec.md](../behavior-spec.md) |
| Has this ever actually been run, and when? | [evidence.md](../evidence.md) |
| What did running it find, and was it fixed? | [findings.md](../findings.md) |
| What has never been proven? | [known-gaps.md](../known-gaps.md) |

## When a record is worth opening

The registers above are maintained and answer the common questions;
these records are neither maintained nor common. What they hold that
nothing else does is the dated narrative -- what the runner actually
ran, what GitHub actually answered, and what surprised them. Four
situations make that worth the read.

**A register row is disputed, or looks wrong.** Every verdict in
`evidence.md` compresses a campaign into one line. The record behind
it carries the read-backs that line was drawn from -- ruleset ids,
workflow blob and commit SHAs, byte-identical pre/post snapshots,
exact PR titles and numbers -- which is how you tell a mistaken
summary from a mistaken run.

**You are about to undo something that looks like ceremony.** Most of
the odd-looking instructions in a `SKILL.md` are there because a run
found something. [findings.md](../findings.md) names the change in a
sentence; the record shows what forced it. A-F5 is the case to know:
Skill A's free-plan handling reads as over-cautious until you find
that every ruleset endpoint returned HTTP 403 where the documentation
had promised a created-but-unenforced ruleset.

**You need an observed fact about `gh` or the GitHub API rather than
a documented one.** These records are where this repository watched
the real thing answer: `gh api user` returning no `plan` key under
gh's default scopes, `gh pr checks --watch` waiting on every check
rather than the one that gates, `gh auth refresh -s` adding scopes
and never removing them. Each contradicted what had been assumed or
read, and none of them can be re-derived from the skills.

**You are designing a campaign that repeats one of these runs.** The
record is the closest thing to a rehearsal: which eval expectations
turned out unachievable and were rewritten, where the harness
measured the wrong thing, what the test-repo state actually was, and
what the runner had to guess. Re-running S2 or S5 without reading its
record pays for the same discoveries twice.

Outside those four, the maintained document is the better answer, and
a record will only tell you what was true on the day it was written.

## Paths inside these records are pre-refactor

These files were written between 2026-07-28 and 2026-07-29, against
the repository layout of the time. They are preserved verbatim
rather than rewritten, because editing a record to keep its links
green would falsify it.

Where a record mentions a path, translate:

| Written as | Now |
|---|---|
| `dev/test-repos.md` | `docs/devs/test-repos.md` |
| `dev/evals/<skill>/evals.json` | `tests/evals/<skill>/evals.json` |
| `dev/evals/README.md` | `docs/devs/testing.md` |
| `dev/validation/` | `docs/devs/validation-records/` (here) |
| `dev-info/conventional-commits-skills-plan.md` | Removed. Harvested into `architecture.md` and `decisions/`. |
| `traces/<anything>` | Removed. See below. |

The skills and the repository were renamed on 2026-09-19. The
records name them as they were called at the time; translate:

| Written as | Now |
|---|---|
| `setup-conventional-commits` | `enforce-conventional-commits` |
| `pr-conventional-commits` | `write-pr-title` |
| `skills-thrill` | `conventional-pr-titles` |

[rename-trigger-gate.md](rename-trigger-gate.md) is the exception to
both tables. It was written after the rename, so its names and paths
are current and need no translation.

## The records

| File | What it covers | Fed forward into |
|---|---|---|
| [setup-conventional-commits-step8.md](setup-conventional-commits-step8.md) | Skill A validation: S1 happy path, baseline comparison, four fixes found by running it | A-F1 to A-F4; S1 and S1b rows in `evidence.md` |
| [pr-conventional-commits-step8.md](pr-conventional-commits-step8.md) | Skill B validation: P1-P4, baseline comparison, six fixes from run friction | B-F1 to B-F6; P1-P4 and P-baseline rows in `evidence.md` |
| [todo8-degraded-idempotency.md](todo8-degraded-idempotency.md) | S2 private-plan degrade, S3 idempotent no-op, S4 reconcile, P5 unscaffolded | A-F5 to A-F10, B-F7, B-F8, T-F1; S2/S3/S4/P5 rows |
| [s5-non-admin.md](s5-non-admin.md) | Non-admin invoker fails before mutating; one known untested branch | A-F11 to A-F13; the S5 row; the A-R2 gap |
| [rename-trigger-gate.md](rename-trigger-gate.md) | The 2026-09-19 rename gate: 15/16, plus a harness defect that was under-measuring dispatch | T-F3; the control and gate rows; cited as evidence by [decision 0011](../decisions/0011-name-skills-for-the-job.md) |

## What was removed

Three things are named in these records but are no longer in the
working tree. All of them remain in git.

**The raw traces.** Six session transcripts used to sit in `traces/`,
and the four campaign records above still name them in their status
lines. They were removed once their durable content had been lifted
into [evidence.md](../evidence.md) -- specifically the independent
dev-session read-backs that back each verdict: ruleset ids, workflow
blob and commit SHAs, byte-identical pre/post snapshots, exact PR
titles and numbers, and the S5 mutation audit. What was lost is the
step-by-step command logs and the verbatim runner reports. What was
kept is every read-back that a disputed verdict would be checked
against. Recorded as
[decision 0012](../decisions/0012-harvest-records-into-durable-artifacts.md).

    git show da6936d:docs/devs/validation/traces/s1-with-skill-trace.md

**The 2026-07-29 trigger-eval gate record.** `trigger-evals.md` scored
16/16 on the descriptions as they stood before the rename. It was
superseded by `rename-trigger-gate.md` and removed once its result was
in the trigger-gates table in [evidence.md](../evidence.md); what
remained was a table of skill names that no longer exist, measured on
a model no longer in use.

**The "Disposition and follow-ups" sections** at the end of the four
campaign records. They tracked test-repo lifecycle and plan-todo
sequencing -- which repositories were awaiting deletion, which gh
account to switch back to, which numbered todo ran next. All of it was
resolved long ago, and it read like outstanding work.

Both removals are recorded as
[decision 0013](../decisions/0013-archive-the-validation-records.md).

    git show 671d6bd:docs/devs/validation/trigger-evals.md
