# Validation records

Dated records of what was actually run against real GitHub
repositories, and what it found. These are **evidence, not
instructions** -- read [testing.md](../testing.md) for how to run
things now.

They are kept because they cost real repositories, real API calls,
and real money to produce, and because several of them record
findings that contradict what documentation implied.

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

The skills and the repository were renamed on 2026-09-19. The
records name them as they were called at the time; translate:

| Written as | Now |
|---|---|
| `setup-conventional-commits` | `enforce-conventional-commits` |
| `pr-conventional-commits` | `write-pr-title` |
| `skills-thrill` | `conventional-pr-titles` |

## The records

| File | What it covers |
|---|---|
| [setup-conventional-commits-step8.md](setup-conventional-commits-step8.md) | Skill A validation: S1 happy path, baseline comparison, four fixes found by running it |
| [pr-conventional-commits-step8.md](pr-conventional-commits-step8.md) | Skill B validation: P1-P4, baseline comparison, six fixes from run friction |
| [todo8-degraded-idempotency.md](todo8-degraded-idempotency.md) | S2 private-plan degrade, S3 idempotent no-op, S4 reconcile, P5 unscaffolded |
| [s5-non-admin.md](s5-non-admin.md) | Non-admin invoker fails before mutating; one known untested branch |
| [trigger-evals.md](trigger-evals.md) | The dispatch ship gate: 16/16 correct on frozen descriptions |

[traces/](traces/) holds the session transcripts behind those five
records. They are kept so that a disputed verdict can be checked
rather than taken on trust: each campaign trace carries a
dev-session verification block of independent read-backs, separate
from what the runner reported about its own work. Nothing outside
this directory depends on them.
