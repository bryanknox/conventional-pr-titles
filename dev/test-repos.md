# Test Repos (maintainer-scope)

Lifecycle procedures for the REAL GitHub repos used to test the two
conventional-commits skills. The eval `setup` fields in
`dev/evals/*/evals.json` reference the scenarios defined here by id
(S1-S5, P1-P5).

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
  assert Levels 1+3 applied and Level 2 reported as BLOCKED by
  plan. RESOLVED LIVE 2026-07-28: on free-plan private personal
  repos ALL ruleset endpoints (list, create, effective-rules) are
  plan-gated with HTTP 403 "Upgrade to GitHub Pro or make this
  repository public..." -- the create POST is refused outright
  (403, NOT 201-then-unenforced as the plan's step 5 finding (b)
  originally guessed from docs). There is no ruleset to eyeball in
  the UI; the former banner checkpoint does not apply.
- **S3 already-configured repo (idempotent no-op).** Run Skill A a
  SECOND time on the repo S1 just configured (`k0x-test-cc-s1`).
  Expect a no-op diff declared at the checkpoint and no mutations.
  Run S3 immediately after S1 passes, before deleting that repo.
- **S4 partially/conflictingly configured repo (reconcile).**
  Create-from-base, then dirty it before the run. Observed
  2026-07-28: a fresh create-from-base repo is ALREADY in the
  conflicting merge-settings state (all three merge methods
  enabled, `squash_merge_commit_title=COMMIT_OR_PR_TITLE`), so no
  settings PATCH is needed -- and PATCHing squash title/message
  fields individually can 422 (`invalid_squash_commit_setting_combo`;
  send both together if a PATCH is ever needed). Only the stray
  ruleset must be added:

      gh api -X POST repos/bryanknox/k0x-test-cc-s4/rulesets \
        --input stray-ruleset.json

  (Any stray ruleset works -- e.g. a `main` ruleset with only a
  `deletion` rule and a non-empty bypass list; bypass actor type
  is `RepositoryRole` (id 5 = repo admin), NOT `RepoRole`. Keep
  the JSON ad hoc; it is scenario fodder, not a maintained
  asset.) Run Skill A;
  assert the checkpoint shows a correct reconcile diff (merge
  methods corrected, stray ruleset surfaced, overwrite/coexist
  decision made explicit) rather than a blind re-apply.
- **S5 non-admin invoker (fail fast).** Needs HUMAN ADMIN
  participation. DECIDED 2026-07-29: use the second gh account
  already on this machine (`bryanknoxbits`, keyring; its token has
  both `repo` and `workflow` scopes) as a plain push collaborator,
  NOT a scoped-down PAT. Rationale: zero credential setup (both
  accounts are already logged in); it exercises the
  `permissions.admin: false` fail-fast branch, the one whose
  report must name who CAN run the skill (with a scoped token the
  invoker IS the admin, so that half of the assertion degenerates);
  it leaves the standing `bryanknox` token -- including the
  `delete_repo` grant state -- untouched; and since the
  collaborator token has both scopes, missing admin access is the
  ONLY failing variable. Setup after create-from-base:

      gh api -X PUT \
        repos/bryanknox/k0x-test-cc-s5/collaborators/bryanknoxbits \
        -f permission=push
      gh auth switch -h github.com -u bryanknoxbits
      gh api user/repository_invitations \
        --jq '.[] | [.id, .repository.full_name] | @tsv'
      gh api -X PATCH user/repository_invitations/<id>

  Run Skill A as `bryanknoxbits`; assert it fails BEFORE any
  mutation and names the missing permission and who can run the
  skill (the repo owner). Then
  `gh auth switch -h github.com -u bryanknox` and verify no
  settings changed via the same read-backs. KNOWN GAP: the
  missing-`workflow`-scope fail-fast branch stays untested --
  `gh auth refresh` can only ADD scopes, so only a purpose-made
  classic PAT (`repo` without `workflow`) could exercise it;
  record the gap in the S5 validation record rather than minting
  one.

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
    gh auth refresh -h github.com --remove-scopes delete_repo

CORRECTED 2026-07-29: the drop step formerly used
`-s repo,workflow`, but `-s` only ADDS scopes -- it never removes
any, so that command left `delete_repo` granted (observed live:
the scope survived the todo #8 deletion session). Only
`--remove-scopes` removes a scope; `repo`, `read:org`, and `gist`
are gh's un-removable minimum and need not be re-listed.

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
3. S2: RESOLVED 2026-07-28 -- the live ruleset-create POST status
   was recorded (403 refusal; no ruleset exists, so there is no
   UI banner to eyeball). No longer an open checkpoint.
4. S5: the collaborator invite to `bryanknoxbits`, the switch to
   that account for the run, and the switch back to `bryanknox`
   afterward.
5. Skill A's own in-run approval gate (the B10 checkpoint before
   mutations) -- part of every A scenario run, answered by the
   operator, not pre-approved by test tooling.
