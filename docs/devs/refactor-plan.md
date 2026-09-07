# Repo refactor plan

Working plan for restructuring this repo around three jobs:
developing the conventional-commits skills, publishing them, and
supporting the people who use them.

Delete this file when the phases below are done.

## Decisions taken

| Decision | Choice | Consequence |
|---|---|---|
| Vendored `genesis` skill | Drop it entirely | -62 files, ~1 MB, and the junction/symlink maintenance policy goes away. A short note in `docs/devs/design-process.md` records what it was for and how to get it back. |
| Repo visibility | Stay private | The Level 2 ruleset stays blocked (free-plan private personal repos return 403 on every ruleset endpoint). Dogfooding gets Levels 1 + 3. |
| Harness support | Claude Code only, for now | No `dist/` mirroring, no per-harness install matrix. The portability *property* is preserved for free by one lint rule; the machinery is deferred. |

### Why Claude Code only is cheap to reverse

Both SKILL.md files already use `name` + `description` frontmatter
only, which is the common denominator across Claude Code, Cursor,
Codex, and Copilot. Nothing in either skill body is
Claude-specific. So supporting the other three later is a
distribution change, not a rewrite.

To keep that true without building anything now, the structural
lint (phase 4) rejects harness-specific frontmatter keys
(`allowed-tools`, `model`, `target`). That one rule is the whole
cost of keeping the door open.

When the other harnesses are wanted, this is the mapping:

| Harness | Project skill directories read |
|---|---|
| Claude Code | `.claude/skills/` |
| Cursor | `.cursor/skills/`, `.agents/skills/` |
| Codex | `.agents/skills/` |
| Copilot | `.github/skills/`, `.claude/skills/`, `.agents/skills/` |

`.agents/skills/` covers three of the four, so it is a
two-directory copy, not four.

## Target structure

```
skills-thrill/
|- README.md                    overview + links only
|- CLAUDE.md                    agent instructions (phase 7)
|- skills/                      UNCHANGED - source of truth
|  |- setup-conventional-commits/
|  \- pr-conventional-commits/
|- docs/
|  |- users/
|  |  |- README.md                       what these do; which one you want
|  |  |- install.md                      Claude Code install
|  |  |- setup-conventional-commits.md   what it changes, who can run, gaps
|  |  |- pr-conventional-commits.md
|  |  \- conventional-commits-guide.md   the convention itself, tool-free
|  \- devs/
|     |- README.md              contributor entry point + repo map
|     |- architecture.md        the two-skill split and its boundaries
|     |- authoring.md           SKILL.md conventions, budgets, portability
|     |- testing.md             tier 1 + tier 2
|     |- test-repos.md          real-repo lifecycle procedures
|     |- design-process.md      how new skills get designed (+ genesis note)
|     |- release.md             versioning and publishing
|     |- decisions/             one file per decision worth remembering
|     \- validation/            paid-for run evidence, kept as-is
|- tests/
|  |- lint-skills.sh
|  \- evals/
\- .github/workflows/
   |- ci.yml
   \- pr-title.yml
```

`dev/` and `dev-info/` both disappear.

## Where the existing content goes

| Current file | Disposition |
|---|---|
| `.agents/skills/genesis/`, `.claude/skills/genesis/` | Delete. Both are plain directories on this machine (the installer's junction is not present), so a normal recursive delete is safe. |
| `skills-lock.json` | Delete. Its provenance (upstream repo + verified commit `18e73c35`) moves into `docs/devs/design-process.md`. |
| `dev-info/README.md` | Dissolve. Toolchain note into `design-process.md`; index links into `docs/devs/README.md`. |
| `dev-info/conventional-commits-skills-plan.md` | Harvest, then delete. The two-skill split and boundary rules into `architecture.md`; the `HUMAN_RATIONALE` entries into `decisions/`. The step 1-6 design scaffolding and the TODOS table (all nine closed) are history, not reference. |
| `dev-info/desires-for-conventional-commits-setup.md` | Into `decisions/0001-original-requirements.md`. |
| `dev-info/setup-guide-for-conventional-commits.md` | Into `docs/users/conventional-commits-guide.md`. This is the manual equivalent of what Skill A automates, and it is user-facing. |
| `dev-info/type-guide-for-conventional-commits.md` | Split, then delete. The shipped trimmed copy at `skills/pr-conventional-commits/references/type-guide.md` stays authoritative. The SemVer / version-bump narrative that was deliberately cut from it goes to `docs/users/conventional-commits-guide.md`. |
| `dev-info/conventional-commits-info-links.md` | Into the references section of `docs/users/conventional-commits-guide.md`. |
| `dev-info/skill-testing-repos.md` | Into the principles section of `docs/devs/testing.md`. |
| `dev/evals/README.md` | Into the tier 2 section of `docs/devs/testing.md`. |
| `dev/evals/*/evals.json` | Into `tests/evals/` unchanged. |
| `dev/test-repos.md` | Into `docs/devs/test-repos.md`, near-verbatim. |
| `dev/validation/` | Into `docs/devs/validation/` unchanged. Real repos and real money produced these; they are the evidence behind the ship gates. |
| `README.md` | Rewrite as an overview with links to both doc sets. |

## Testing, in two tiers

**Tier 1 - runs in CI.** Free, deterministic, no model calls.
Today these checks exist only as prose assertions inside the plan's
TODOS table ("288 lines, ASCII, description 642 chars, name =
dir"). Phase 4 turns them into `tests/lint-skills.sh`:

- frontmatter parses; `name` and `description` present
- `name` equals the directory name; hyphen-case, 64 chars or fewer
- description within the budget recorded in `authoring.md`
  (both skills are around 640 characters today)
- ASCII only, LF endings, final newline, lines 72 columns or fewer
- no harness-specific frontmatter keys - the portability guard
- every relative reference resolves inside the skill folder, and no
  absolute paths - mechanizes the "nothing ships that is not in the
  folder" rule
- `evals.json` parses and matches its schema
- `actionlint` over `assets/pr-title-workflow.yml`

Write it in Bash, not PowerShell: one implementation runs on the
ubuntu runner and locally through Git Bash.

**Tier 2 - manual campaign.** Costs money, needs real GitHub repos
and human checkpoints: content evals S1-S5 and P1-P5, baseline
deltas, trigger evals. Fully specified already in
`docs/devs/test-repos.md` and the tier 2 section of
`docs/devs/testing.md`. These do not belong in CI.

## Using the skills inside this repo

Claude Code loads project skills from `.claude/skills/`, not from
`skills/`. Rather than mirroring the folder and inviting the same
drift problem genesis had, run:

    claude --plugin-dir .

`skills/<name>/SKILL.md` at the repo root is already the plugin
layout, so both skills load as
`skills-thrill:setup-conventional-commits` and
`skills-thrill:pr-conventional-commits` with no duplicated files.

## Phases

One PR each, titled conventionally - the refactor is its own
worked example.

| # | Phase | PR title |
|---|---|---|
| 0 | Tag `pre-refactor`; land this plan | `docs: add repo refactor plan` |
| 1 | Delete genesis and the lock file | `chore: remove vendored genesis skill` |
| 2 | Build `docs/users/` | `docs: add user documentation` |
| 3 | Build `docs/devs/`; delete `dev-info/` | `docs: add contributor documentation` |
| 4 | `tests/` + tier 1 lint; delete `dev/` | `test: add structural lint for skills` |
| 5 | `ci.yml` | `ci: add lint and validation workflow` |
| 6 | Run `setup-conventional-commits` on this repo | `ci: enforce conventional PR titles` |
| 7 | `CLAUDE.md` via `/init` | `docs: add agent instructions` |
| 8 | Publish as a Claude Code plugin | `feat: publish as installable plugin` |

### Phase 6 notes

Running Skill A here is also a live re-run of scenario S2, so it
doubles as regression coverage. Expect: Level 1 and Level 3
applied and verified, Level 2 reported as blocked by plan.

Because the ruleset is blocked, nothing mechanically forces changes
through a PR - direct pushes to `main` stay possible and the
PR-title check is advisory rather than required. Using PRs is a
choice here, not an enforcement. Going public later unblocks Level
2, and re-running the skill is idempotent: it adds only the
ruleset.

One distinction to keep straight in the docs: `test-repos.md` says
GitHub workflow development never happens in this repo. That rule
is about the pr-title.yml *template under development*, and it
still holds. This repo running its own CI is a different thing.

### Phase 7 notes

Run `/init` after the structure is final, or it documents a layout
that is about to change. Set `CLAUDE_CODE_NEW_INIT=1` for the
reviewable-proposal flow. Then hand-trim to what Claude cannot work
out from the files: the ASCII and 72-column SKILL.md conventions,
the tier 1 / tier 2 testing split, `claude --plugin-dir .` for
using the skills here, and the rule that nothing harness-specific
enters skill frontmatter.

If the other harnesses are added later, move the content to
`AGENTS.md` and reduce `CLAUDE.md` to an `@AGENTS.md` import plus
any Claude-specific lines. Claude Code reads `CLAUDE.md` and does
not read `AGENTS.md`; the other three read `AGENTS.md`.

## Deferred, deliberately

- Multi-harness distribution (Cursor, Codex, Copilot). Door kept
  open by the frontmatter lint rule; no machinery built.
- Making the repo public, and with it the Level 2 ruleset.
- Publishing to a separate marketplace repo. Phase 8 makes this
  repo its own marketplace; splitting that out is worth doing only
  once there is a second unrelated plugin or an outside
  collaborator.
