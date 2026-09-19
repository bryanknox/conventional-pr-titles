# Contributing

This repository develops, publishes, and supports two agent skills
for enforcing Conventional Commits through pull request titles.

If you want to *use* the skills, you want
[the user documentation](../users/README.md) instead.

## Repository map

| Path | What it holds |
|---|---|
| `skills/` | The skills themselves. The only thing that ships. |
| `.claude-plugin/` | The plugin manifest and the marketplace catalog |
| `CLAUDE.md` | Instructions for Claude Code working in this repo |
| `docs/users/` | Documentation for people using the skills |
| `docs/devs/` | This. Documentation for people changing the skills. |
| `docs/devs/decisions/` | Why things are the way they are |
| `docs/devs/validation-records/` | Archived evidence: what was run against real repositories, and when |
| `tests/` | The structural lint, and the eval definitions |

Nothing outside `skills/` is ever distributed. That boundary is
deliberate and is enforced by review -- see
[decision 0008](decisions/0008-maintainer-material-outside-skill-folders.md).

## The development flow

```mermaid
flowchart TD
    SPEC[behavior-spec.md - what must be true]
    SKILL[skills/*/SKILL.md - make it so]
    T1[tier 1 - is it well-formed?]
    T2[tier 2 on real repos - does it work?]
    REG[evidence / findings / known-gaps]
    REL[release]

    SPEC --> SKILL
    SKILL --> T1
    T1 -->|wording only| REL
    T1 -->|behavior or description changed| T2
    T2 --> REG
    REG -->|the contract moved| SPEC
    REG --> REL
```

The part worth internalising is that it is a **cycle**, not a
pipeline. A campaign is not finished when it produces a verdict; it is
finished when the registers and the spec have absorbed what it found.
Several of this repository's sharpest facts arrived that way -- a
predicted failure mode that turned out false, an API that refused
where the documentation said it would silently succeed, a test harness
that was measuring the wrong thing. None of those were visible before
something real was run.

The four cheapest things to get wrong, in order:

- Editing a `description` is a behavior change. It decides which
  prompts invoke the skill, without changing a word of what the skill
  does.
- A green tier 1 says a skill is well-formed. It says nothing about
  whether it works.
- An untested branch and a tested one look identical in the source.
  That is what [known-gaps.md](known-gaps.md) exists to fix.
- An unbumped plugin version leaves installed copies cached, silently.

## Which files for which task

| Task | Read | Run | Then update |
|---|---|---|---|
| Reword a SKILL.md | [authoring.md](authoring.md) | tier 1 | nothing |
| Change a description | [authoring.md](authoring.md) | tier 1, then the trigger evals | [evidence.md](evidence.md) |
| Change behavior | [behavior-spec.md](behavior-spec.md), then [authoring.md](authoring.md) | tier 1, then content evals and a real run | [findings.md](findings.md), [evidence.md](evidence.md), [known-gaps.md](known-gaps.md), and the spec if the contract moved |
| Design a new skill | [design-process.md](design-process.md) | -- | [decisions/](decisions/) |
| Settle a contested choice | [decisions/README.md](decisions/README.md) | -- | a new ADR |
| Check whether something was ever proven | [evidence.md](evidence.md) | -- | -- |
| Find what still needs proving | [known-gaps.md](known-gaps.md) | -- | -- |
| Set up or reset a test repository | [test-repos.md](test-repos.md) | -- | -- |
| Cut a release | [release.md](release.md) | all four gates | the version in both manifests |

## Start here

**Orientation**

- [The user documentation](../users/README.md) -- you need to know
  what the skills do and how they are used before you can change them.
- [architecture.md](architecture.md) -- what the two skills are, why
  there are two, and where the line between them sits.
- [behavior-spec.md](behavior-spec.md) -- what they must do, as
  numbered requirements everything else cites.

**Doing the work**

- [authoring.md](authoring.md) -- the conventions a `SKILL.md` here
  has to follow, and why each one exists.
- [design-process.md](design-process.md) -- how a new skill gets
  designed before anyone writes prose.
- [testing.md](testing.md) -- the two testing tiers, what each
  catches, and how to run them.
- [test-repos.md](test-repos.md) -- lifecycle procedures for the real
  GitHub repositories the skills are tested against.

**The record**

- [decisions/](decisions/) -- the decisions worth not re-litigating.
- [evidence.md](evidence.md) -- what has actually been run, and the
  independent read-back behind each verdict.
- [findings.md](findings.md) -- what running it found, and what
  changed as a result.
- [known-gaps.md](known-gaps.md) -- what has never been proven.
- [validation-records/](validation-records/) -- archive. The dated
  records the three registers above were harvested from. Read the
  registers first; open a record to check a disputed claim, to see
  what forced an instruction that now looks like ceremony, or before
  repeating a campaign it already covered.

**Shipping**

- [release.md](release.md) -- what "done" means, and how the skills
  reach users.

## Working on a skill

**Use the skills in this repository** without copying anything:

```
claude --plugin-dir .
```

`skills/<name>/SKILL.md` at the repo root is already the layout
Claude Code expects from a plugin, so both skills load as
`conventional-pr-titles:enforce-conventional-commits` and
`conventional-pr-titles:write-pr-title`. Do **not** mirror `skills/`
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
bash tests/check-requirement-ids.sh
```

CI runs the same five. See [testing.md](testing.md) for what each
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

`enforce-conventional-commits` has been run against this repository.
Merge is squash-only with the PR title as the commit subject, and
[`pr-title.yml`](../../.github/workflows/pr-title.yml) validates
that title on every pull request.

The branch ruleset that would make the check *required* could not
be created: ruleset endpoints are plan-gated on a private
free-plan repository. So the check is advisory, direct pushes to
`main` are still possible, and using PRs here is a choice rather
than enforcement.
