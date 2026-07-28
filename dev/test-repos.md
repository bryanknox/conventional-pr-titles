# Test Repos (maintainer-scope)

Lifecycle procedures for the REAL GitHub repos used to test the two
conventional-commits skills. Grounded in
`dev-info/skill-testing-repos.md` and the Testing strategy in
`dev-info/conventional-commits-skills-plan.md` (step 6). The eval
`setup` fields in `dev/evals/*/evals.json` reference the scenarios
defined here by id (S1-S5, P1-P5).

Why real repos: Skill A's footprint (merge settings, rulesets,
required checks) and Skill B's check-polling are server-side GitHub
state; they cannot be faked locally. GitHub workflow development
(the pr-title template itself) also happens ONLY in these test
repos, never in this dev repo, so workflow run histories do not
muddy development repos.

All helpers below are documented `gh` one-liners, run from a
POSIX shell (the Bash tool; `--jq`/`xargs` forms assume it).
Promote them to `dev/scripts/` only if the rule of three fires.

## Base repo (READ-ONLY)

`bryanknox/k0x-workbench` -- https://github.com/bryanknox/k0x-workbench

Every test repo is created FROM this base. Never mutate the base:
no pushes, no settings changes, no rulesets, no workflows, no PRs.
Nothing in the procedures below targets it except `git clone`.

## Naming convention

All test repos: `k0x-test-cc-<suffix>`, in the `bryanknox`
personal account.

| Repo | Scenarios | Lifecycle |
|---|---|---|
| `k0x-test-cc-s1` | S1, then S3 (reuses S1's end state) | recreate |
| `k0x-test-cc-s2` | S2 (private) | recreate |
| `k0x-test-cc-s4` | S4 (pre-dirtied) | recreate |
| `k0x-test-cc-s5` | S5 (non-admin invoker) | recreate |
| `k0x-test-cc-pr` | P1-P4 (scaffolded once by Skill A) | reuse + reset |
| `k0x-test-cc-p5` | P5 (never scaffolded) | recreate |

Find leftovers after a test session:

    gh repo list bryanknox --json name --jq '.[].name' | grep '^k0x-test-cc-'

## Create-from-base procedure

gh account note: this machine has two gh accounts; the standing
default is `bryanknox`, which is also the account the test repos
live in. Verify with `gh auth status` before a campaign; if some
other account happens to be active, run
`gh auth switch -h github.com -u bryanknox`. No switch-back
afterward -- `bryanknox` active IS the normal state.

Creating a repo in the personal account is a HUMAN CHECKPOINT:
confirm with the operator before each `gh repo create`.

    git clone https://github.com/bryanknox/k0x-workbench k0x-test-cc-<suffix>
    cd k0x-test-cc-<suffix>
    git remote rename origin base
    gh repo create bryanknox/k0x-test-cc-<suffix> --public --source . --push

Use `--private` instead of `--public` for S2. The remote rename is
required: `gh repo create --source .` adds a remote named `origin`
and fails if one exists. After this, `origin` is the test repo and
`base` still points at the read-only base -- double-check any push
names `origin`, never `base`.

A fresh create-from-base repo has GitHub defaults: all three merge
methods enabled, no rulesets, no workflows. That is exactly the S1
starting state; scenario-specific setup below starts from there.

## Installing a skill under test

Repo-scoped install into the test repo clone -- never user-scoped,
so the skill under test cannot leak into other sessions:

    mkdir -p .claude/skills
    cp -r <dev-repo>/skills/<skill-name> .claude/skills/<skill-name>

`.claude/skills/` is the Claude Code repo-scoped path (the first
concrete 7b target); bind a different path for other harnesses. Do
NOT commit the copied skill to the test repo: it is not part of the
scenario state, and keeping it untracked means resets and diffs
never see it. Start a FRESH session in the test repo clone for each
eval run (trigger evals especially: dispatch must be observed from
a cold session).

For without-skill baseline runs, remove the folder first:

    rm -rf .claude/skills/<skill-name>

## Skill A scenarios (recreate per scenario)

Assert outcomes via `gh api` read-backs (the same endpoints the
skill itself uses): `repos/{o}/{r}` for merge settings,
`repos/{o}/{r}/contents/.github/workflows/pr-title.yml` for the
workflow, `repos/{o}/{r}/rulesets` and
`repos/{o}/{r}/rules/branches/<default>` for ruleset existence vs
active enforcement. Expected values per scenario live in the eval
`expectations` (`dev/evals/setup-conventional-commits/evals.json`).

- **S1 fresh public repo (happy path).** Create-from-base, public.
  No further setup. Run Skill A; assert the full 3-level scaffold.
- **S2 private repo, free plan (graceful degrade).** Create-from-base
  with `--private` on the free-plan personal account. Run Skill A;
  assert Levels 1+3 applied, ruleset created but reported as NOT
  enforced (`rules/branches/<default>` returns no ruleset rules).
  HUMAN CHECKPOINT: eyeball the ruleset in the GitHub UI and
  confirm the "won't be enforced ... until you upgrade" banner.
  Also record the live POST status for the ruleset create (201 vs
  403) -- the plan's step 5 finding (b) leaves that as the one
  fact only observable here.
- **S3 already-configured repo (idempotent no-op).** Run Skill A a
  SECOND time on the repo S1 just configured (`k0x-test-cc-s1`).
  Expect a no-op diff declared at the checkpoint and no mutations.
  Run S3 immediately after S1 passes, before deleting that repo.
- **S4 partially/conflictingly configured repo (reconcile).**
  Create-from-base, then dirty it before the run:

      gh api -X PATCH repos/bryanknox/k0x-test-cc-s4 \
        -F allow_merge_commit=true -F allow_squash_merge=true \
        -f squash_merge_commit_title=COMMIT_OR_PR_TITLE
      gh api -X POST repos/bryanknox/k0x-test-cc-s4/rulesets \
        --input stray-ruleset.json

  (Any stray ruleset works -- e.g. a `main` ruleset with only a
  `deletion` rule and a non-empty bypass list. Keep the JSON ad
  hoc; it is scenario fodder, not a maintained asset.) Run Skill A;
  assert the checkpoint shows a correct reconcile diff (merge
  methods corrected, stray ruleset surfaced, overwrite/coexist
  decision made explicit) rather than a blind re-apply.
- **S5 non-admin invoker (fail fast).** Needs HUMAN ADMIN
  participation and one of: a second GitHub account added as a
  plain push collaborator on the test repo, or a scoped-down token
  missing the `workflow` scope on the owner account (e.g.
  `gh auth login` with a classic PAT that has `repo` but not
  `workflow`). Run Skill A as that identity; assert it fails
  BEFORE any mutation and names the missing permission and who can
  run the skill. Verify no settings changed afterward via the same
  read-backs. Restore normal auth when done: `gh auth login` /
  `gh auth refresh -s repo,workflow`.

## Skill B repo: scaffold once, reset between runs

One-time setup of `k0x-test-cc-pr`: create-from-base (public),
then run **Skill A** on it (this is also a cheap re-exercise of the
S1 path) so P1-P4 run against real enforcement: squash-only
merges, the pr-title check, and an active `main` ruleset.

**Reset procedure** (between every P run; the ruleset does not
block any of this -- branch deletion is remote-branch cleanup, not
`main`):

    # close open PRs and delete their branches
    gh pr list --state open --json number --jq '.[].number' \
      | xargs -I{} gh pr close {} --delete-branch

    # delete any stray remote branches other than the default
    gh api repos/bryanknox/k0x-test-cc-pr/branches --jq '.[].name' \
      | grep -v '^main$' \
      | xargs -I{} gh api -X DELETE \
          repos/bryanknox/k0x-test-cc-pr/git/refs/heads/{}

    # reset the local clone
    git checkout main
    git fetch --prune origin
    git reset --hard origin/main
    git branch | grep -v '^\* main$' | xargs -r git branch -D

Reset does NOT touch settings, the ruleset, or the workflow --
those are the scaffold, and P1-P4 depend on them. If the scaffold
itself gets damaged, re-run Skill A (idempotent) or recreate the
repo and scaffold again.

## Skill B scenarios

Each P scenario = reset, then create a branch with the described
change (ad hoc edits to the base repo's files), then run Skill B.
Expected titles and check behavior live in the eval `expectations`
(`dev/evals/pr-conventional-commits/evals.json`).

- **P1 single bug-fix branch.** One small defect-fix commit ahead of
  `main`; no existing PR. Expect `fix: ...`, check green.
- **P2 breaking API change.** Branch removes or renames a public
  API surface in one area. Expect `feat(scope)!: ...` plus a
  `BREAKING CHANGE:` footer in the body, check green.
- **P3 docs-only change.** Markdown-only edits. Expect `docs: ...`.
- **P4 existing PR with a bad title.** Reset, branch, then
  pre-create the PR badly:

      gh pr create --title "stuff" --body "wip"

  Run Skill B against that PR; expect the title fixed and the
  pr-title check to go red -> green (exercises the bounded retry /
  re-poll path).
- **P5 unscaffolded repo.** Uses `k0x-test-cc-p5`: create-from-base,
  Skill A NEVER run (GitHub defaults, no workflow). Branch with a
  small change, run Skill B. Expect a conventional title still
  composed and applied, check-polling skipped, and a report of the
  gap recommending setup-conventional-commits -- with NO attempt
  to scaffold.

Integration property: P1-P4 deliberately run inside a repo
scaffolded by Skill A; P5 deliberately runs outside one.

## Delete procedure (HUMAN CHECKPOINT)

Repo deletion always goes through the operator. The `delete_repo`
scope is not part of normal auth; the operator grants it
explicitly, deletions happen, then the scope is dropped:

    gh auth refresh -h github.com -s delete_repo   # operator approves in browser
    gh repo delete bryanknox/k0x-test-cc-<suffix> --yes
    gh auth refresh -h github.com -s repo,workflow  # drop delete_repo again

Never script a loop over `gh repo delete`; delete one repo per
confirmed command. The leftover-finder one-liner under Naming
convention is the pre-delete inventory. `k0x-test-cc-pr` is
long-lived across the P1-P4 campaign -- delete it only when Skill B
validation (plan todo #7) is done.

## Human checkpoints (consolidated)

1. Every `gh repo create` in the personal account (each scenario's
   create-from-base step).
2. Granting the `delete_repo` scope, and every individual repo
   deletion.
3. S2: eyeballing the ruleset's non-enforcement banner in the
   GitHub UI, and recording the live ruleset-create POST status.
4. S5: providing the second account or scoped-down token, and
   restoring normal auth afterward.
5. Skill A's own in-run approval gate (the B10 checkpoint before
   mutations) -- part of every A scenario run, answered by the
   operator, not pre-approved by test tooling.
