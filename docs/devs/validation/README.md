# Validation records

Dated records of what was actually run against real GitHub
repositories, and what it found. These are **evidence, not
instructions** -- read [testing.md](../testing.md) for how to run
things now.

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
| `dev/validation/` | `docs/devs/validation/` (here) |
| `dev-info/conventional-commits-skills-plan.md` | Removed. Harvested into `architecture.md` and `decisions/`. |
| `traces/<anything>` | Removed. See below. |

The skills and the repository were renamed on 2026-09-19. The
records name them as they were called at the time; translate:

| Written as | Now |
|---|---|
| `setup-conventional-commits` | `enforce-conventional-commits` |
| `pr-conventional-commits` | `write-pr-title` |
| `skills-thrill` | `conventional-pr-titles` |

## The records

| File | What it covers | Fed forward into |
|---|---|---|
| [setup-conventional-commits-step8.md](setup-conventional-commits-step8.md) | Skill A validation: S1 happy path, baseline comparison, four fixes found by running it | A-F1 to A-F4; S1 and S1b rows in `evidence.md` |
| [pr-conventional-commits-step8.md](pr-conventional-commits-step8.md) | Skill B validation: P1-P4, baseline comparison, six fixes from run friction | B-F1 to B-F6; P1-P4 and P-baseline rows in `evidence.md` |
| [todo8-degraded-idempotency.md](todo8-degraded-idempotency.md) | S2 private-plan degrade, S3 idempotent no-op, S4 reconcile, P5 unscaffolded | A-F5 to A-F10, B-F7, B-F8, T-F1; S2/S3/S4/P5 rows |
| [s5-non-admin.md](s5-non-admin.md) | Non-admin invoker fails before mutating; one known untested branch | A-F11 to A-F13; the S5 row; the A-R2 gap |
| [trigger-evals.md](trigger-evals.md) | The dispatch ship gate: 16/16 correct on frozen descriptions. **Superseded** by the record below for the current names | The 2026-07-29 gate row |
| [rename-trigger-gate.md](rename-trigger-gate.md) | The 2026-09-19 rename gate: 15/16, plus a harness defect that was under-measuring dispatch | T-F3; the control and gate rows; cited as evidence by [decision 0011](../decisions/0011-name-skills-for-the-job.md) |

## The raw traces were removed

Six session transcripts used to sit in `traces/`, and the four
campaign records above still name them in their status lines. They
were removed once their durable content had been lifted into
[evidence.md](../evidence.md) -- specifically the independent
dev-session read-backs that back each verdict: ruleset ids, workflow
blob and commit SHAs, byte-identical pre/post snapshots, exact PR
titles and numbers, and the S5 mutation audit.

What was lost is the step-by-step command logs and the verbatim
runner reports. What was kept is every read-back that a disputed
verdict would be checked against.

They remain in git. To read one:

    git show da6936d:docs/devs/validation/traces/s1-with-skill-trace.md

Recorded as
[decision 0012](../decisions/0012-harvest-records-into-durable-artifacts.md).
