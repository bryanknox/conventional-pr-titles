# Contributing

This repository develops, publishes, and supports two agent skills
for enforcing Conventional Commits through pull request titles.

If you want to *use* the skills, you want
[the user documentation](../users/) instead.

## Repository map

| Path | What it holds |
|---|---|
| `skills/` | The skills themselves. The only thing that ships. |
| `docs/users/` | Documentation for people using the skills |
| `docs/devs/` | This. Documentation for people changing the skills. |
| `docs/devs/decisions/` | Why things are the way they are |
| `dev/` | Evals and test-repo procedures. Moves into `tests/` and here in phase 4. |

Nothing outside `skills/` is ever distributed. That boundary is
deliberate and is enforced by review -- see
[decision 0008](decisions/0008-maintainer-material-outside-skill-folders.md).

## Start here

- [architecture.md](architecture.md) -- what the two skills are,
  why there are two, and where the line between them sits.
- [authoring.md](authoring.md) -- the conventions a `SKILL.md` in
  this repo has to follow, and why each one exists.
- [design-process.md](design-process.md) -- how a new skill gets
  designed before anyone writes prose.
- [release.md](release.md) -- what "done" means, and how the skills
  reach users.
- [decisions/](decisions/) -- the decisions worth not re-litigating.

Testing lives in `dev/evals/README.md` and `dev/test-repos.md`
until phase 4 of [refactor-plan.md](refactor-plan.md) moves it here.

## Working on a skill

**Use the skills in this repository** without copying anything:

```
claude --plugin-dir .
```

`skills/<name>/SKILL.md` at the repo root is already the layout
Claude Code expects from a plugin, so both skills load as
`skills-thrill:setup-conventional-commits` and
`skills-thrill:pr-conventional-commits`. Do **not** mirror `skills/`
into `.claude/skills/` -- that path is gitignored precisely so no
second copy can drift from the first.

**Editing a skill** means editing `skills/<name>/SKILL.md` and
whatever it carries alongside it. Read [authoring.md](authoring.md)
first; several of the conventions there are load-bearing rather than
cosmetic.

**Before opening a pull request**, check your change against the
conventions in [authoring.md](authoring.md). Phase 4 turns those
checks into a script that runs in CI; until then they are a manual
read.

**Changing behavior** -- as opposed to wording -- means the change
needs a real run against a real GitHub repository before it is
believable. Repository settings, rulesets, and status checks are
server-side state that cannot be faked locally. The procedures are
in `dev/test-repos.md`.

## Commit and pull request titles

This repository follows its own convention: the pull request title
is a Conventional Commits message, and it becomes the commit on
`main` at squash-merge time. See
[the user guide](../users/conventional-commits-guide.md) for the
format.

Enforcement is being applied to this repository in phase 6. Until
then the convention is followed by hand.

## The current refactor

[refactor-plan.md](refactor-plan.md) tracks a restructuring in
progress. It records the decisions taken, where each existing file
ends up, and what is deliberately deferred. Delete it when the
phases are done.
