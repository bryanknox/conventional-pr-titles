# Behavior specification

**What this is for:** the single statement of what the two skills must
do, as numbered requirements other files can cite.

**Read it** before changing behavior, and when you need to know whether
something is contractual or incidental.

**Write to it** when the contract itself moves -- which is a behavior
change, so see [testing.md](testing.md) for what that costs.

## Authority

This file states *what must be true*. It does not say how.

| Artifact | Role |
|---|---|
| `docs/devs/behavior-spec.md` | The contract. What must be true. |
| `skills/<name>/SKILL.md` | The instructions that achieve it. The only thing that ships. |
| `docs/users/*` | The same contract in user language. `release.md` judges semver against these pages. |
| `tests/evals/<skill>/evals.json` | The test. Each content eval cites the requirements it exercises. |

Where this file and a `SKILL.md` disagree, that is a bug, not a
hierarchy question -- one of the two is wrong and the evals are what
decide which. Do not "fix" a disagreement by editing this file to match
the skill without running the eval that covers the requirement.

Requirement ids are stable. Retire one by marking it withdrawn rather
than renumbering, because [evidence.md](evidence.md),
[known-gaps.md](known-gaps.md), `test-repos.md`, and both `evals.json`
files cite them by id, and `tests/check-requirement-ids.sh` fails on a
citation that no longer resolves.

## Shared invariants

Both skills obey all five. These are the properties that make the
skills trustworthy and the easiest things to break by accident; the
reasoning is in [architecture.md](architecture.md) and
[authoring.md](authoring.md).

| Id | Requirement |
|---|---|
| INV1 | Every fact about a repository, branch, or pull request comes from a `git` or `gh` read at the moment it is needed -- never from memory or conversation history. |
| INV2 | Every mutation is verified by reading the state back. An API call returning success is not evidence. |
| INV3 | Failure lands before any mutation or after all of them, never in the middle. |
| INV4 | At most one human approval, covering the whole change. Never one per step. |
| INV5 | On anything blocked, do what remains possible, then report exactly what did not happen and what would unblock it. Never guess, never silently skip. |

## enforce-conventional-commits

### Preconditions

| Id | Requirement |
|---|---|
| A-R1 | Requires `admin` on the target repo. Without it, fail before any mutation, naming the missing permission and who can run the skill. |
| A-R2 | Requires gh token scopes `repo` AND `workflow`. Without either, fail before any mutation, naming the missing scope and a remedy that works for the credential in use: `gh auth refresh` for a keyring login, a new token or an unset variable for a token supplied through the environment. |

### Target state

The complete footprint. There are three levels and no fourth.

| Id | Requirement |
|---|---|
| A-R3 | **Level 1, merge settings:** `allow_squash_merge=true`, `allow_merge_commit=false`, `allow_rebase_merge=false`, `squash_merge_commit_title=PR_TITLE`, `squash_merge_commit_message=BLANK`. `PR_BODY` instead of `BLANK`, and auto-delete head branches, are permitted user options. |
| A-R4 | **Level 2, workflow:** `.github/workflows/pr-title.yml` matching `assets/pr-title-workflow.yml`. Job name exactly `Validate conventional PR title`; `pull_request` trigger including the `edited` type; `amannn/action-semantic-pull-request@v6` pinned; `with: types:` stating `feat,fix,docs,style,refactor,perf,test,build,ci,chore`; `permissions.pull-requests: read`. A user-supplied type list is permitted, and the deviation is recorded in the final report. |
| A-R5 | **Level 3, ruleset:** one ruleset named `conventional-commits-main` targeting the default branch, enforcement `active`, **empty** bypass list, rules `deletion`, `non_fast_forward`, `pull_request` (0 required approvals), and `required_status_checks` whose context equals the Level 2 job name exactly. |
| A-R6 | There is no Level 4. No git hooks, no local commit tooling, nothing installed in a clone. Branch commits stay unconstrained. |

A-R4 and A-R5 are coupled through one string. The ruleset requires the
status check *by name*; renaming the job without renaming the required
context silently disables enforcement while leaving both objects
present and apparently healthy. `tests/check-workflow-template.sh`
asserts that string in the template and in this file.

### Process

| Id | Requirement |
|---|---|
| A-R7 | Apply order is Level 1, then Level 2, then Level 3. Level 3 last because a ruleset requiring pull requests would block the direct commit of the Level 2 workflow to the default branch. |
| A-R8 | Exactly one checkpoint, presenting the full three-level diff, and no mutation before it is approved. |
| A-R9 | A re-run against an already-configured repository is a no-op: the diff comes back empty, the skill says so at the checkpoint, and it changes nothing. |
| A-R10 | A partially or conflictingly configured repository produces a reconcile diff at the checkpoint -- corrected merge methods, stray rulesets surfaced, the overwrite-or-coexist decision made explicit -- rather than a blind re-apply. |
| A-R11 | Where ruleset endpoints are plan-gated (free-plan private personal repos answer HTTP 403 on list, create, and effective-rules), detect it at preflight, state it at the checkpoint before mutating, apply and verify Levels 1 and 2 normally, and report Level 3 as BLOCKED with the remedy. No retry loop, nothing deleted, no abort. |
| A-R12 | The final report shows before/after per level with a verified column, names any deviation, and names the residual soft spot: the merge box lets the merger hand-edit the squash message and nothing validates that edit. |

### Boundaries

| Id | Requirement |
|---|---|
| A-R13 | Does not create the repository and does not scaffold application code. |
| A-R14 | Does not compose pull request titles. That is `write-pr-title`. |

## write-pr-title

### Title form

| Id | Requirement |
|---|---|
| B-R1 | The title is `type(scope)!: description`. Scope is optional and is omitted rather than invented. |
| B-R2 | `type` is lowercase and from the de-facto ten: feat, fix, docs, style, refactor, perf, test, build, ci, chore. It is classified from the **diff**, not from the branch's commit messages, which are hints only. |
| B-R3 | `description` is imperative mood, lowercase start, no trailing period. The whole title is <= 72 characters. |
| B-R4 | A breaking change carries `!` before the colon AND a `BREAKING CHANGE: <explanation>` footer as the last paragraph of the PR body. |

Spec-edge cases -- reverts, multiple footers, unusual formats -- are
verified against https://www.conventionalcommits.org/ rather than
extrapolated.

### Process

| Id | Requirement |
|---|---|
| B-R5 | The branch diff, the existing pull request if any, and the repository's configuration are all read; nothing is recalled. |
| B-R6 | Whether the repository has the enforce-conventional-commits scaffold is detected, not assumed -- and so are the title rules its check enforces (allowed types and scopes, whether a scope is required, any subject pattern), read from the workflow before the title is composed. |
| B-R7 | A checkpoint is presented in two cases only: when retitling a pull request this session did not create, and when every title the repository's check would accept breaks B-R1 to B-R3 -- asked before the PR is created or retitled, even one this session creates. Otherwise creating a PR, or retitling one just created, needs no approval. |
| B-R8 | After creating or editing, the title is read back and confirmed to match exactly. |
| B-R9 | Where the PR-title check exists, poll it and report the result, with at most two retries. |
| B-R10 | In a repository without the scaffold: compose and apply a conventional title anyway, skip check polling entirely, and report that the repository does not enforce PR titles, recommending that an admin run `enforce-conventional-commits`. |
| B-R11 | Without permission to apply the title, compose it anyway and report what could not be applied and who can apply it. Never retry the refused edit, and never use another identity's credentials to get past it. |
| B-R12 | The report gives a one-sentence type rationale. For a breaking change it also states whether the footer will ride into the squash commit, based on the repo's `squash_merge_commit_message` setting, without changing that setting. Where the invoker cannot read the squash settings, the report says their effect is unknown rather than guessing it. |

### Boundaries

| Id | Requirement |
|---|---|
| B-R13 | Never creates or modifies a workflow, repository setting, or ruleset -- **even when it detects the scaffold is missing**, and never offers to. It reports the gap or the conflicting rule and says what an admin could change, recommending the sibling skill where the scaffold is missing. |
| B-R14 | Never rewrites, squashes, or lints the branch's own commits. |

B-R13 is the boundary most likely to be eroded by a well-meaning
change, because auto-fixing looks helpful. It is not: most of this
skill's users lack admin rights, so the helpful path fails for them and
silently escalates a title request into repository administration for
everyone else. See
[decision 0004](decisions/0004-skill-b-never-scaffolds.md).

## Coverage

Which of these have actually been exercised against a real repository,
and which have not, is [evidence.md](evidence.md). The ones that have
not are [known-gaps.md](known-gaps.md). Neither is optional reading
before you claim a change is proven.
