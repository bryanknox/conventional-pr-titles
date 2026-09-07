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

## The records

| File | What it covers |
|---|---|
| [setup-conventional-commits-step8.md](setup-conventional-commits-step8.md) | Skill A validation: S1 happy path, baseline comparison, four fixes found by running it |
| [pr-conventional-commits-step8.md](pr-conventional-commits-step8.md) | Skill B validation: P1-P4, baseline comparison, six fixes from run friction |
| [todo8-degraded-idempotency.md](todo8-degraded-idempotency.md) | S2 private-plan degrade, S3 idempotent no-op, S4 reconcile, P5 unscaffolded |
| [s5-non-admin.md](s5-non-admin.md) | Non-admin invoker fails before mutating; one known untested branch |
| [trigger-evals.md](trigger-evals.md) | The dispatch ship gate: 16/16 correct on frozen descriptions |
| [traces/](traces/) | Raw session transcripts behind the records above |

## Findings worth remembering

Three results here changed the skills rather than just confirming
them:

**Free-plan private repositories refuse ruleset creation outright.**
Every ruleset endpoint returns 403, including the create. The
earlier reading of the documentation had assumed the ruleset would
be created but left unenforced. The skill's degrade path is built
around the confirmed behavior, not the assumed one.

**`GET /user` omits the plan without the `user` scope**, which gh's
default auth does not request. An empty result means unknown, not
free -- so the preflight 403 is the definitive detector and the plan
read is only corroboration.

**Skill B's value in a configured repository is process, not
titles.** The baseline produced comparable titles because it could
read the convention off the workflow file.

## Known gap

The missing-`workflow`-scope fail-fast branch is untested.
Exercising it needs a purpose-made token with `repo` but not
`workflow`, and `gh auth refresh` can only add scopes, never remove
them. Recorded in [s5-non-admin.md](s5-non-admin.md) rather than
worked around.

## A note on encoding

Two files under `traces/` contain non-ASCII bytes. The structural
lint covers `skills/` only, so this does not fail CI, and it is
deliberate: normalizing the bytes of a captured transcript makes it
a less faithful record.
