# CLAUDE.md

Guidance for Claude Code working in this repository. It covers what
the files do not say on their own; everything else is in
[docs/devs/](docs/devs/).

## What this repository is

Two agent skills that enforce Conventional Commits through pull
request titles: `setup-conventional-commits` configures a GitHub
repository, `pr-conventional-commits` writes the title. Both live
in `skills/`, which is the source of truth and the only thing that
ships.

Nothing outside `skills/` is ever distributed. Docs, tests, evals,
and validation records are maintainer material -- do not move any
of it into a skill folder to make it "available".

## Using the skills in this repository

```
claude --plugin-dir .
```

`skills/<name>/SKILL.md` is already the plugin layout, so both load
as `skills-thrill:<name>` with no second copy. Do **not** mirror
`skills/` into `.claude/skills/`; that path is gitignored precisely
so nothing can drift.

`--plugin-dir` is for working *here*. It is wrong for evals,
because the `skills-thrill:` namespace changes the dispatch surface
the trigger evals measure -- those copy the folder into a test
repository instead.

## Editing a SKILL.md

- **Frontmatter is `name` and `description` and nothing else.**
  That is the intersection of what Claude Code, Cursor, Codex, and
  Copilot accept. `allowed-tools`, `model`, and `target` are
  rejected by the lint on purpose: one rule is the entire cost of
  keeping the skills portable. Do not add a key without deciding to
  give that up.
- `name` must equal the directory name.
- ASCII only, LF endings, final newline, no trailing whitespace.
- Prose wraps at 72 columns. Table rows and fenced code blocks are
  exempt -- neither can be wrapped without breaking.
- Self-contained: no skill reads a file outside its own folder, and
  no skill reads another skill's files. A path that escapes the
  folder works here and breaks on install, which is what makes the
  rule worth stating. Deliberate duplication between the two skills
  beats a cross-skill dependency.
- **The description is the dispatch surface, not a summary.**
  Editing it changes which prompts invoke the skill without
  changing a word of behavior, so it is a behavioral change and
  invalidates the trigger evals.

Reasoning for each of these is in
[docs/devs/authoring.md](docs/devs/authoring.md).

## Rules the skills themselves obey

Easy to erode by a well-meaning edit:

- **Read, do not remember.** Every fact about a repository, branch,
  or pull request comes from a `git` or `gh` read at the moment it
  is needed.
- **Verify every mutation** by reading the state back. An API call
  returning success is not evidence.
- **Fail before mutating, not during.**
- **One approval** covering the whole change, never one per step.
- **Degrade with a report.** Do what remains possible, then say
  exactly what did not happen and what would unblock it.
- **Skill B never configures a repository**, even when it detects
  the configuration is missing. It reports the gap and recommends
  Skill A. Auto-fixing looks helpful and is not: most of Skill B's
  users lack admin rights.

## Testing is two tiers, and they are not interchangeable

**Tier 1** is free and deterministic. Run all three before opening
a pull request; CI runs the same three.

```
bash tests/lint-skills.sh
bash tests/check-links.sh
bash tests/check-workflow-template.sh
```

`check-workflow-template.sh` needs PyYAML (`python -m pip install
pyyaml`). A green tier 1 says a skill is well-formed. It says
nothing about whether it works.

**Tier 2** -- content and trigger evals in `tests/evals/` -- costs
model calls, needs real GitHub repositories, and has human
checkpoints. It is deliberately not in CI, and it is not something
to start unprompted. Behavior changes need it; wording-only edits
do not. See [docs/devs/testing.md](docs/devs/testing.md).

Checks are written to **fail loudly**: a missing tool is an error,
not a skip. An earlier version reported a clean pass because
`grep -P` was unavailable and the check never ran. If you add a
check, make its failure path the loud one, and resolve interpreters
by running candidates rather than testing for the name on `PATH`.

## Platform

Development happens on Windows; CI runs on ubuntu. The checks are
Bash so that one implementation covers both -- run them through Git
Bash locally. Do not add a PowerShell equivalent.

## Pull requests

This repository follows its own convention. The pull request title
is a Conventional Commits message and becomes the commit on `main`
at squash-merge time. `setup-conventional-commits` has been run
here: merge is squash-only with the PR title as the commit subject,
and `.github/workflows/pr-title.yml` validates that title.

The branch ruleset is not in place -- ruleset endpoints are
plan-gated on a private free-plan repository -- so the title check
is advisory, not required. Direct pushes to `main` remain
possible; using PRs here is a choice, not enforcement. Making the
repository public and re-running the skill adds only the ruleset.

## Refactor in progress

[docs/devs/refactor-plan.md](docs/devs/refactor-plan.md) tracks a
restructuring. Progress is the merged PR list, one PR per phase.
Delete the plan when the phases are done.
