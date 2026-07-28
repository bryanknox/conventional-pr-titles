---
name: setup-conventional-commits
description: >-
  Use this skill when the user wants to set up, scaffold, or
  configure a GitHub repository to use Conventional Commits enforced
  at squash-merge time: squash-only merge settings, a main-branch
  ruleset requiring PRs and a PR-title check, and a PR-title lint
  workflow. Also use when the user asks to "protect main", "prevent
  direct pushes", "enforce commit message format on main", or is
  setting up a new .NET (or any) app repo that should keep a clean
  conventional history. Configures the repo via gh CLI. Requires
  ADMIN access to the target repo. Does NOT create the repo or app
  code, and does NOT write PR titles (see pr-conventional-commits).
---

# Setup Conventional Commits (squash-merge enforcement)

Configure an EXISTING GitHub repository so that the only path to
the default branch is a squash-merged PR whose title is a valid
Conventional Commits message. The whole footprint is three levels:

- Level 1 - repo merge settings: squash-only; default squash
  message = PR title.
- Level 2 - a default-branch ruleset: require a PR, require the
  PR-title status check, block force pushes and deletions, empty
  bypass list.
- Level 3 - a PR-title lint workflow
  (`assets/pr-title-workflow.yml`, using
  amannn/action-semantic-pull-request).

There is no Level 4: no local git hooks, no commit tooling.
Branch commits stay unconstrained by design; the PR title at merge
time is the only gate.

Boundaries: this skill does NOT create the repo, does NOT scaffold
application code, and does NOT compose PR titles (companion skill:
`pr-conventional-commits`).

## Who can run this

| | |
|---|---|
| Intended user | Repo owner / admin (personal account: the owner) |
| GitHub permission | `admin` on the target repo |
| gh token scopes | `repo` AND `workflow` |
| Runs how often | Once per repo; re-runs are idempotent no-ops |
| On missing permission | Fail fast BEFORE any mutation |

## Process

Follow the steps in order. Every fact about the repo comes from a
`gh` read, never from memory or conversation history. Every
mutation is followed by a read-back verification. Do not start
mutating before the checkpoint in step 4 is approved.

### Step 1 - Preflight (read-only)

Identify the target repo (default: the `origin` remote of the
current directory; otherwise ask). Then gather facts:

```
gh auth status                          # authenticated? scopes include repo, workflow?
gh api repos/{owner}/{repo}             # permissions.admin, visibility, default_branch,
                                        #   allow_squash_merge, allow_merge_commit,
                                        #   allow_rebase_merge, squash_merge_commit_title,
                                        #   delete_branch_on_merge
gh api user --jq .plan.name             # owner's plan (personal accounts); EMPTY unless
                                        #   the token has the user scope (gh default
                                        #   auth does not) -> treat empty as unknown
gh api repos/{owner}/{repo}/rulesets    # existing rulesets
gh api repos/{owner}/{repo}/contents/.github/workflows/pr-title.yml
                                        # existing workflow? (404 = absent)
```

Use `default_branch` from the repo read everywhere this skill says
"main".

Fail fast (before ANY mutation) when:

- `permissions.admin` is false: report that only a repo admin (in
  personal accounts, the account owner) can run this skill, and
  name them if known.
- Token lacks `repo` or `workflow` scope: report the missing scope
  and the remedy: `gh auth refresh -h github.com -s repo,workflow`.

Detect the private-plan gap: if `visibility` is `private` AND the
owner's plan is `free`, rulesets can be created but are NOT
enforced (GitHub Pro is required for rulesets on private personal
repos). The plan read is best-effort: `GET /user` includes `plan`
only when the token has the `user` scope, which gh's default auth
does not -- an empty result means UNKNOWN, not `free`. Do not
abort in either case: Levels 1 and 3 work on any plan, and the
plan is to still create the ruleset so it activates automatically
if the repo goes public or the plan is upgraded. On a private
repo, carry the gap (plan `free`) or the uncertainty (plan
unknown) into the checkpoint; the Level 2 read-back is the
definitive enforcement detector either way.

### Step 2 - Compute the diff

Compare current state against the target state (see "Target state
per level" below) and classify each level: `apply` (change
needed), `no-op` (already configured), or `conflict` (something
different exists, e.g. a stray ruleset targeting the default
branch, or a pr-title.yml with different content).

If all three levels are `no-op`, say so and stop after presenting
the (empty) diff; re-running on a configured repo must not mutate
anything.

### Step 3 - Write the checklist

Before mutating anything, write this checklist to a working file
(e.g. `cc-setup-checklist.md` in the session's working area).
Re-read it at the start of each level and update the Status column
after each verification; its header restates the goal and
constraints so they survive a long session.

```markdown
# Conventional commits setup: {owner}/{repo}
Goal: only path to {default_branch} is a squash-merged PR whose
title is a valid Conventional Commits message.
Constraints: empty bypass list; no branch-commit enforcement;
apply order Level 1 -> Level 3 -> Level 2.

| Step | Target | Current | Action | Status |
|---|---|---|---|---|
| L1 merge settings | squash-only, title=PR_TITLE | {found} | {apply/no-op} | pending |
| L3 pr-title workflow | present, action @v6 | {found} | {apply/no-op} | pending |
| L2 ruleset on {default_branch} | active; PR + check required | {found} | {apply/no-op} | pending |
| Read-back verification | all three levels green | - | - | pending |

Gaps: {none | private free-plan repo: ruleset will be created but
not enforced until upgrade or repo goes public}
```

### Step 4 - Checkpoint (human approval)

Present the proposed changes as one reviewable diff: per level,
current -> target, plus any detected gap or conflict. Wait for
approval before mutating. Two things ALWAYS require explicit
acknowledgment, never silent action:

- Overwriting an existing ruleset or an existing pr-title.yml that
  differs from the template.
- Proceeding on a private free-plan repo (ruleset will be created
  but inactive).

### Step 5 - Level 1: merge settings

```
gh api -X PATCH repos/{owner}/{repo} \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F allow_squash_merge=true \
  -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=BLANK
```

Options the user may have chosen at the checkpoint:
`-f squash_merge_commit_message=PR_BODY` (PR body becomes the
commit body; lets `BREAKING CHANGE:` footers ride along), and
`-F delete_branch_on_merge=true` (tidiness).

Verify: re-read `gh api repos/{owner}/{repo}` and confirm each
field patched above. Update the checklist.

### Step 6 - Level 3: PR-title lint workflow

Level 3 lands BEFORE Level 2 so the workflow file can be committed
directly to the default branch without being blocked by the
ruleset this skill is about to create.

First check the action's current major version against the pin in
the template:

```
gh api repos/amannn/action-semantic-pull-request/releases/latest --jq .tag_name
```

If the latest major is newer than `v6`, keep the pinned `v6` (the
pin is deliberate; silent drift would change lint behavior) but
note the lag in the final report.

Commit `assets/pr-title-workflow.yml` from this skill's directory
to the repo as `.github/workflows/pr-title.yml`, base64-encoded
per platform:

```
gh api -X PUT repos/{owner}/{repo}/contents/.github/workflows/pr-title.yml \
  -f message="ci: add conventional PR title check" \
  -f content="{base64 of the workflow file}"
```

When overwriting an existing file (approved at the checkpoint),
include `-f sha={existing file sha}` from the preflight read.

Verify: GET the same contents path, decode, and confirm it matches
the template. Update the checklist.

### Step 7 - Level 2: ruleset on the default branch

Create the ruleset. The required status check is referenced by the
workflow's job name string; no prior workflow run is needed when
creating via the API.

```
gh api -X POST repos/{owner}/{repo}/rulesets --input - <<'JSON'
{
  "name": "conventional-commits-main",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      } },
    { "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [
          { "context": "Validate conventional PR title" }
        ]
      } }
  ]
}
JSON
```

Notes: required approvals stay 0 (personal repos; the PR just has
to exist). The bypass list stays EMPTY unless the user explicitly
asks otherwise. No merge-method rule is needed; Level 1 already
makes squash the only option. If the API returns 422, re-verify
the request shape against the live GitHub REST docs for repository
rulesets; do not adjust field names from recall.

Verify with the effective-rules endpoint, which returns only
ACTIVELY ENFORCED rules:

```
gh api repos/{owner}/{repo}/rules/branches/{default_branch}
```

Expect entries for `deletion`, `non_fast_forward`, `pull_request`,
and `required_status_checks`. An EMPTY result after a successful
create on a private repo (free or unknown plan) confirms the
predicted gap: the ruleset exists but is not enforced. Record it
as inactive in the checklist; do not delete it (it activates on
upgrade or when the repo goes public).

### Step 8 - Final report

Re-read the checklist and confirm every row is resolved, then
report:

```markdown
## Conventional commits setup: {owner}/{repo}
| Level | Before | After | Verified |
|---|---|---|---|
| 1 merge settings | {before} | squash-only, title=PR_TITLE | yes/no |
| 3 pr-title workflow | {before} | .github/workflows/pr-title.yml @v6 | yes/no |
| 2 ruleset | {before} | {active | created but NOT enforced (plan gap)} | yes/no |

Gaps: {none | plan gap details | action version lag}
Residual soft spot: the PR merge box lets the merger hand-edit the
final squash message, and nothing validates that edit. Don't touch
the prefilled message.
Next: open PRs with the companion skill pr-conventional-commits.
```

## Target state per level

- Level 1: `allow_squash_merge=true`, `allow_merge_commit=false`,
  `allow_rebase_merge=false`, `squash_merge_commit_title=PR_TITLE`.
  Optional per user: squash message = PR_BODY; auto-delete head
  branches.
- Level 2: one ruleset targeting the default branch, enforcement
  `active`, empty bypass list, rules: deletion, non_fast_forward,
  pull_request (0 required approvals), required_status_checks with
  context `Validate conventional PR title`.
- Level 3: `.github/workflows/pr-title.yml` matching
  `assets/pr-title-workflow.yml`. The job name is the status-check
  context the ruleset requires; renaming one without the other
  breaks enforcement. If the user wants to pin allowed commit
  types, uncomment the `with: types:` block in the template (the
  de-facto set: feat, fix, docs, style, refactor, perf, test,
  build, ci, chore).
