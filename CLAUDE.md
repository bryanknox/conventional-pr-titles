# CLAUDE.md

Guidance for Claude Code working in this repository. It covers what
the files do not say on their own; everything else is in
[docs/devs/](docs/devs/).

## What this repository is

Two agent skills that enforce Conventional Commits through pull
request titles: `enforce-conventional-commits` configures a GitHub
repository, `write-pr-title` writes the title. Both live
in `skills/`, which is the source of truth and the only thing that
ships.

They ship as one Claude Code plugin, catalogued by this repository
itself: `.claude-plugin/plugin.json` and
`.claude-plugin/marketplace.json`. Neither manifest names a path --
`skills/` at the root is the layout a plugin already expects.

Nothing outside `skills/` is ever distributed. Docs, tests, evals,
and validation records are maintainer material -- do not move any
of it into a skill folder to make it "available".

## Using the skills in this repository

```
claude --plugin-dir .
```

`skills/<name>/SKILL.md` is already the plugin layout, so both
load as `conventional-pr-titles:<name>` with no second copy. Do
**not** mirror `skills/` into `.claude/skills/`; a mirror there is
gitignored precisely so nothing can drift. That directory is not
empty, though -- see below.

`--plugin-dir` is for working *here*. It is wrong for evals,
because the `conventional-pr-titles:` namespace changes the
dispatch surface the trigger evals measure -- those copy the
folder into a test repository instead.

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

## Maintainer-only dev skills

Repetitive maintainer procedures are packaged as agent skills too,
and they live in `.claude/skills/` with a `dev-` prefix. Today that
is `dev-absorb-campaign`, which absorbs a tier-2 campaign into the
registers. Cutting a release and the test-repo lifecycle are named
as candidates in [decision
0014](docs/devs/decisions/0014-dev-skills-outside-skills-dir.md) and
are not built.

**They never go in `skills/`**, for two independent reasons, and the
second fails silently:

- Everything in `skills/` ships. Neither manifest names a path, so a
  folder added there reaches every installer with no further step.
- `tests/evals/run-trigger-evals.sh` copies every `skills/*/` into
  its fixture, so a third skill silently joins the dispatch surface
  the trigger evals measure, and the score moves for a reason nobody
  would look for.

`tests/check-skill-inventory.sh` now enforces both directories:
`skills/` is an **exact** set, so an extra directory there is a
failure; `.claude/skills/` is a **required** set, so a missing dev
skill is a failure while an unlisted directory is only reported --
third-party installs such as `genesis` live there legitimately and
are never committed. Adding a dev skill means adding it to
`DEV_SKILLS` in that script.

The `dev-` prefix is load-bearing rather than decorative: `.gitignore`
ignores everything under `.claude/skills/` except `dev-*`, so a dev
skill misnamed without the prefix is silently ignored by git and
vanishes on the next clone.

Dev skills are held to the same lint as the shipped ones, which is
why tier 1 runs it twice. They carry no requirement ids, no
`behavior-spec.md` entry, and no evals -- accepted deliberately in
0014 on the grounds that they are internal tooling with a human
reading every result. If a dev skill ever starts being trusted
rather than read, that reasoning has expired.

## Where the contract lives

[docs/devs/behavior-spec.md](docs/devs/behavior-spec.md) states what
the two skills must do, as numbered requirements (`INV*`, `A-R*`,
`B-R*`). SKILL.md is the instruction set that achieves it. Where the
two disagree, one of them is wrong and the evals decide which -- do
not reconcile them by editing the spec.

Three registers are keyed by those ids and are maintained, not
historical: [evidence.md](docs/devs/evidence.md) (what has been run),
[findings.md](docs/devs/findings.md) (what running it found), and
[known-gaps.md](docs/devs/known-gaps.md) (what has never been
proven). `tests/check-requirement-ids.sh` fails if a citation stops
resolving, or if a requirement exists that `evidence.md` says nothing
about.

[docs/devs/README.md](docs/devs/README.md) has the development flow
and a table routing each kind of task to the files it touches.
[docs/devs/concepts.md](docs/devs/concepts.md) defines the terms
those pages assume -- campaign, register, read-back, gate -- and
every id scheme.

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

**Tier 1** is free and deterministic. Run all seven before opening
a pull request; CI runs the same seven.

```
bash tests/lint-skills.sh
bash tests/lint-skills.sh .claude/skills 'dev-*'
bash tests/check-links.sh
bash tests/check-workflow-template.sh
bash tests/check-plugin-manifests.sh
bash tests/check-requirement-ids.sh
bash tests/check-skill-inventory.sh
```

`check-workflow-template.sh` needs PyYAML (`python -m pip install
pyyaml`). The `dev-*` glob on the second command is load-bearing --
see "Maintainer-only dev skills" below. A green tier 1 says a skill
is well-formed. It says nothing about whether it works.

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

## Releasing

`version` in `plugin.json` and in the marketplace entry must match
and must be bumped on every release -- an unbumped version leaves
installed copies cached, silently.
`tests/check-plugin-manifests.sh` catches the mismatch but cannot
know that a changed skill needed a bump. The full sequence, and
why `claude plugin validate` is a release step rather than a CI
step, is in [docs/devs/release.md](docs/devs/release.md).

## Platform

Development happens on Windows; CI runs on ubuntu. The checks are
Bash so that one implementation covers both -- run them through Git
Bash locally. Do not add a PowerShell equivalent.

## Pull requests

This repository follows its own convention. The pull request title
is a Conventional Commits message and becomes the commit on `main`
at squash-merge time. `enforce-conventional-commits` has been run
here: merge is squash-only with the PR title as the commit subject,
and `.github/workflows/pr-title.yml` validates that title.

The branch ruleset is not in place -- ruleset endpoints are
plan-gated on a private free-plan repository -- so the title check
is advisory, not required. Direct pushes to `main` remain
possible; using PRs here is a choice, not enforcement. Making the
repository public and re-running the skill adds only the ruleset.
