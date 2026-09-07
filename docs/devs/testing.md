# Testing

Testing here splits into two tiers that differ by more than
thoroughness. Tier 1 is free, deterministic, and runs on every
commit. Tier 2 costs money, needs real GitHub repositories and human
participation, and runs when behavior changes.

Confusing the two is the main way this gets expensive or, worse,
skipped.

| | Tier 1 | Tier 2 |
|---|---|---|
| What | Structural lint | Content and trigger evals |
| Cost | Free | Model calls, real repos, your time |
| Determinism | Total | Sampled |
| Runs | Every commit, in CI | When behavior or a description changes |
| Catches | Malformed, non-portable, or self-inconsistent skills | Skills that do the wrong thing, or run at the wrong time |

A green tier 1 says a skill is well-formed. It says nothing about
whether it works.

## Tier 1: structural lint

```
bash tests/lint-skills.sh
```

Exits non-zero on any violation. Every rule is explained in
[authoring.md](authoring.md); the script is the enforcement, that
page is the reasoning.

What it checks:

- Frontmatter parses, and contains `name` and `description` --
  **and nothing else.** That last part is the portability guard. A
  `model` or `allowed-tools` key would work in Claude Code and break
  the skill elsewhere, so the lint refuses it.
- `name` matches the directory, is hyphen-case, and is at most 64
  characters.
- The description is within its ceiling.
- Every markdown file in a skill bundle is ASCII, LF, ends with a
  newline, and has no trailing whitespace.
- Prose wraps at 72 columns. Table rows and fenced code blocks are
  exempt, because neither can be wrapped without breaking.
- References into a skill's own bundle resolve. Absolute paths and
  references that escape the folder fail.
- The eval files parse as JSON.

### It is written to fail loudly

A missing tool is an error, not a skip. This is deliberate: an
earlier ad-hoc version of these checks reported a clean pass because
`grep -P` was unavailable in Git Bash, and the check simply never
ran. A lint that can silently do nothing is worse than no lint,
because it is trusted.

If you add a check, make its failure path the loud one.

### What it does not cover

The lint runs against `skills/` only, since that is the only thing
distributed. Documentation and validation records are not linted.

Two raw trace captures under `validation/traces/` contain non-ASCII
bytes. That is left alone on purpose -- they are recorded output,
and normalizing the bytes of a record makes it less faithful, not
more.

## Tier 2: content evals

The eval files are `tests/evals/<skill>/evals.json`. Each has an
`evals` key (content) and a `trigger_evals` key (dispatch), in a
schema borrowed from skill-creator, extended with `setup` naming the
required scenario and `baseline_failure_modes` recording what a run
without the skill is expected to get wrong.

Run each eval **twice** in the described setup: once with the skill
installed, once without. Grade the `expectations` against the
transcript and the resulting repository state.

**If the two runs are indistinguishable, that is a finding, not a
pass.** A skill that does not beat the baseline is not earning its
context.

This has already paid off once. Skill B's *titles* in an
already-configured repository turned out to be only marginally
better than the baseline, because the baseline could read the
convention off the workflow file. The value was real but elsewhere:
process discipline, no unrequested test runs, waiting on the right
check. Knowing precisely where the value is not is worth as much as
knowing where it is.

These need **real** GitHub repositories. Merge settings, rulesets,
and status checks are server-side state that cannot be faked
locally. Lifecycle, reset procedures, and the human checkpoints are
in [test-repos.md](test-repos.md).

## Tier 2: trigger evals

Roughly twenty prompts per skill: half that should invoke it, half
near misses. Split 60/40 into `train` and `validation`.

- **`train`** is for iterating on the name and description.
- **`validation`** is the ship gate, scored only after the wording
  is frozen. It passes at a should-trigger rate of at least 0.5 and
  a near-miss rate below 0.5.

Present each prompt to a **fresh** session with the skill installed,
and record whether the skill was invoked. Cold sessions matter:
dispatch is the thing under test, and a warm session has already
been primed.

Some near-miss prompts legitimately belong to the *sibling* skill.
Those carry a `note`, and a miss that dispatches to the sibling is
correct behavior, not a failure. Score it accordingly.

Any edit to a `description` invalidates these results. That is the
one change that can alter a skill's behavior without altering a word
of its instructions.

## Installing a skill under test

Copy the folder into the test repository's `.claude/skills/`, as
described in [test-repos.md](test-repos.md). Do **not** use
`claude --plugin-dir` for evals: that namespaces the skill as
`skills-thrill:<name>`, which changes the dispatch surface the
trigger evals are measuring. `--plugin-dir` is for working *in this
repository*, not for testing.

## What has been run

[validation/](validation/) holds the records: the step-8 validation
of both skills, the degraded-path and idempotency campaign, the
non-admin fail-fast scenario, the trigger-eval gate, and the raw
transcripts behind each.

They are dated records rather than living documents. Read them for
evidence of what was verified and when, not as current instructions.
