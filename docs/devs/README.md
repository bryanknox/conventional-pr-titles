# Contributing

This repository develops, publishes, and supports two agent skills
for enforcing Conventional Commits through pull request titles.

If you want to *use* the skills, you want
[the user documentation](../users/) instead.

## Repository map

| Path | What it holds |
|---|---|
| `skills/` | The skills themselves. The only thing that ships. |
| `.claude-plugin/` | The plugin manifest and the marketplace catalog |
| `CLAUDE.md` | Instructions for Claude Code working in this repo |
| `docs/users/` | Documentation for people using the skills |
| `docs/devs/` | This. Documentation for people changing the skills. |
| `docs/devs/decisions/` | Why things are the way they are |
| `docs/devs/validation/` | Dated records of what was run against real repositories |
| `tests/` | The structural lint, and the eval definitions |

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
- [testing.md](testing.md) -- the two testing tiers, what each
  catches, and how to run them.
- [test-repos.md](test-repos.md) -- lifecycle procedures for the
  real GitHub repositories the skills are tested against.
- [release.md](release.md) -- what "done" means, and how the skills
  reach users.
- [decisions/](decisions/) -- the decisions worth not re-litigating.
- [validation/](validation/) -- dated records of what was actually
  run, and what it found.

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

This loads the working tree, not an installed copy, which is what
you want while editing. It is the same plugin users install from
`.claude-plugin/`; see [release.md](release.md) for how a change
here becomes a release.

**Editing a skill** means editing `skills/<name>/SKILL.md` and
whatever it carries alongside it. Read [authoring.md](authoring.md)
first; several of the conventions there are load-bearing rather than
cosmetic.

**Before opening a pull request**, run the tier 1 checks:

```
bash tests/lint-skills.sh
bash tests/check-links.sh
bash tests/check-workflow-template.sh
bash tests/check-plugin-manifests.sh
```

CI runs the same four. See [testing.md](testing.md) for what each
one covers and its one prerequisite.

**Changing behavior** -- as opposed to wording -- means the change
needs a real run against a real GitHub repository before it is
believable. Repository settings, rulesets, and status checks are
server-side state that cannot be faked locally. The procedures are
in [test-repos.md](test-repos.md), and the two testing tiers are
explained in [testing.md](testing.md).

## Commit and pull request titles

This repository follows its own convention: the pull request title
is a Conventional Commits message, and it becomes the commit on
`main` at squash-merge time. See
[the user guide](../users/conventional-commits-guide.md) for the
format.

`setup-conventional-commits` has been run against this repository.
Merge is squash-only with the PR title as the commit subject, and
[`pr-title.yml`](../../.github/workflows/pr-title.yml) validates
that title on every pull request.

The branch ruleset that would make the check *required* could not
be created: ruleset endpoints are plan-gated on a private
free-plan repository. So the check is advisory, direct pushes to
`main` are still possible, and using PRs here is a choice rather
than enforcement.

## The current refactor

[refactor-plan.md](refactor-plan.md) tracks a restructuring in
progress. It records the decisions taken, where each existing file
ends up, and what is deliberately deferred. Delete it when the
phases are done.
