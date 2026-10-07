# Test Repos (maintainer-scope)

Lifecycle procedures for the REAL GitHub repos used to test the two
conventional-commits skills. The eval `setup` fields in
`tests/evals/*/evals.json` reference the scenarios defined here by id
(S1-S6, O1, O5, P1-P8).

Each scenario names the requirements it covers, as a `Covers:` line.
Those ids are defined in [behavior-spec.md](behavior-spec.md), and
`tests/check-requirement-ids.sh` fails if one stops resolving. Which
requirements no scenario covers is [known-gaps.md](known-gaps.md).

Why real repos: Skill A's footprint (merge settings, rulesets,
required checks) and Skill B's check-polling are server-side GitHub
state; they cannot be faked locally. GitHub workflow development
(the pr-title template itself) also happens ONLY in these test
repos, never in this dev repo, so workflow run histories do not
muddy development repos.

All helpers below are documented `gh` one-liners, run from a
POSIX shell (the Bash tool; `--jq`/`xargs` forms assume it).
The read-backs that grade a run have been promoted to
`tests/evals/check-repo-state.sh` -- see [testing.md](testing.md),
"Checking repo state". The setup, reset, and mutation one-liners stay
here as prose. Promote those only if the rule of three fires.

## Driving these procedures from a session

The `gh` one-liners below are Bash-tool work, and a session runs
them well. Hand it the scenario id -- S1-S6, O1, O5, P1-P8 -- and let
it use the commands as written rather than improvising equivalents.
Several of them carry a correction that a reinvented command
re-breaks:
`--remove-scopes` rather than `-s` for dropping a scope, the
`origin`/`base` remote rename, sending both squash fields in one
PATCH to avoid `invalid_squash_commit_setting_combo`. Each of those
is in the text because the obvious version of the command was tried
first and failed.

**Never script a loop over `gh repo delete`.** It is said again
under the delete procedure, and it belongs here too, because "clean
up the test repos" is a reasonable-sounding request and a loop is
the first shape anyone reaches for. Deletion is one confirmed
command per repository.

The account switches and the `delete_repo` grant-and-drop pair are
operator actions. A session can tell you the command and can read
back the result; you run it.

These procedures are packaged as the `dev-test-repo-lifecycle`
skill, in `.claude/skills/`. **This page stays the authority**; the
skill is the enforcement, and where the two disagree this page wins.
It stages one scenario per invocation, so each `gh repo create` is
its own approval. It hands over every deletion, the `delete_repo`
grant and drop, and every account switch, then reads the result
back. It stops at "ready to run": the eval run is a fresh session,
and the post-run `check-repo-state.sh check` is yours. You name the
directory that holds the clones each time. The skill is maintainer
tooling and carries no requirement ids and no evals, so it is read
rather than trusted -- see
[decision 0014](decisions/0014-dev-skills-outside-skills-dir.md)
for why that trade was accepted and when it expires.

**A permission rule is not a checkpoint.**
`.claude/settings.local.json` already allows `Bash(gh repo create:*)`.
That removes a permission *prompt*. It does not remove checkpoint 1
below. The checkpoint is a decision about whether a repository
should exist in the personal account, which no permission setting
can answer -- and since the rule was added there is no longer a
prompt to remind anyone the question exists. That is the point worth
carrying into every one of these procedures: the checkpoints are
answered by a human deciding, not by tooling being allowed.

## Base repo (READ-ONLY)

`bryanknox/k0x-workbench` -- https://github.com/bryanknox/k0x-workbench

Every test repo is created FROM this base. Never mutate the base:
no pushes, no settings changes, no rulesets, no workflows, no PRs.
Nothing in the procedures below targets it except `git clone`.

## Naming convention

All test repos: `k0x-test-cc-<suffix>`, in the `bryanknox`
personal account -- except O1 and O5, which exist to test an
organization and so live in `test-bryanknox`
(https://github.com/test-bryanknox): a free organization owned by
`bryanknox`, created 2026-10-03 for that purpose and holding nothing
else.

| Repo | Scenarios | Lifecycle |
|---|---|---|
| `k0x-test-cc-s1` | S1, then S3 (reuses S1's end state) | recreate |
| `k0x-test-cc-s2` | S2 (private) | recreate |
| `k0x-test-cc-s4` | S4 (pre-dirtied) | recreate |
| `k0x-test-cc-s5` | S5 (non-admin invoker) | recreate |
| `k0x-test-cc-s6` | S6 (token missing `workflow`) | recreate |
| `test-bryanknox/k0x-test-cc-o1` | O1 (S1 in an organization) | recreate |
| `test-bryanknox/k0x-test-cc-o5` | O5 (S5 in an organization) | recreate |
| `k0x-test-cc-pr` | P1-P4 (scaffolded once by Skill A) | reuse + reset |
| `k0x-test-cc-p5` | P5 (never scaffolded) | recreate |
| `k0x-test-cc-p6` | P6 (check rejects the first title) | recreate |
| `k0x-test-cc-p7` | P7 (check can never pass) | recreate |
| `k0x-test-cc-p8` | P8 (invoker cannot retitle) | recreate |

**A without-skill baseline gets its own repository**: the scenario's
repo name plus `b` -- `k0x-test-cc-p6b`, or `k0x-test-cc-prb` for a
P1-P4 baseline, scaffolded the same way. Stage it exactly as the
scenario and do not install the skill. Never run a baseline in the
with-skill run's repo, even after closing that run's pull request:
closed PRs and pushed branches stay readable, and in 2026-10 the P7
baseline found the with-skill run's closed PR with
`gh pr list --state all` and read its check history (finding T-F7 in
[findings.md](findings.md)).

Find leftovers after a test session, in both owners:

    gh repo list bryanknox --json name --jq '.[].name' | grep '^k0x-test-cc-'
    gh repo list test-bryanknox --json name --jq '.[].name' | grep '^k0x-test-cc-'

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

Use `--private` instead of `--public` for S2, and `test-bryanknox/`
instead of `bryanknox/` for O1 and O5. The remote rename is
required: `gh repo create --source .` adds a remote named `origin`
and fails if one exists. After this, `origin` is the test repo and
`base` still points at the read-only base -- double-check any push
names `origin`, never `base`.

A fresh create-from-base repo has GitHub defaults: all three merge
methods enabled, no rulesets, no workflows. That is exactly the S1
starting state; scenario-specific setup below starts from there.

**Expect Dependabot pull requests.** The base ships
`.github/dependabot.yml`, so within minutes of a public create
Dependabot opens dependency PRs, and they run the base's CI. Leave
them alone: they are not the skill's, and closing them is not part of
any scenario. They do not touch a verdict -- the repo-state checker
reads check runs by the graded PR's head commit -- but they do appear
in an unfiltered `gh pr list`, which a session under test may read.
The P1-P4 reset closes them along with everything else, which is
harmless.

## Installing a skill under test

Repo-scoped install into the test repo clone -- never user-scoped,
so the skill under test cannot leak into other sessions:

    mkdir -p .claude/skills
    cp -r <dev-repo>/skills/<skill-name> .claude/skills/<skill-name>

`.claude/skills/` is the Claude Code repo-scoped path (the first
concrete 7b target); bind a different path for other harnesses. Do
NOT commit the copied skill to the test repo: it is not part of the
scenario state, and keeping it untracked means resets and diffs
never see it. Confirm that with
`git ls-files .claude/skills/<skill-name>`, which must print nothing.
Not `git ls-files .claude`: the base tracks its own `.claude/`
content -- an agent, a rule, and a `normalize-bench-file` skill -- so
that lists three files on every clone. Those base files also load in
every test session, alongside the skill under test.

Start a FRESH session in the test repo clone for each eval run
(trigger evals especially: dispatch must be observed from a cold
session). Name the clone's full path in the handoff, and check that
the session header shows that directory before typing the prompt. In
2026-10 a run started in the wrong clone and configured a repository
that had already been graded (T-F8).

A without-skill baseline runs in its own repository (see "Naming
convention"), so there is nothing to remove: stage it and skip this
install. In a clone that ever held the skill, remove it first:

    rm -rf .claude/skills/<skill-name>

## Skill A scenarios (recreate per scenario)

Assert outcomes with the repo-state checker, after the run:

    bash tests/evals/check-repo-state.sh check <S1|S2> bryanknox/k0x-test-cc-<suffix> <outdir>

S3, S4, and S5 compare against the state before the run, so take a
snapshot first, then pass it to the check after the run with
`--pre <pre-dir>`:

    bash tests/evals/check-repo-state.sh snapshot bryanknox/k0x-test-cc-<suffix> <pre-dir>

It reads the same endpoints the skill itself uses: `repos/{o}/{r}`
for merge settings,
`repos/{o}/{r}/contents/.github/workflows/pr-title.yml` for the
workflow, and `repos/{o}/{r}/rulesets` and
`repos/{o}/{r}/rules/branches/<default>` to tell ruleset existence
apart from active enforcement. The expectations it settles are cited
from the eval `expectations`
(`tests/evals/enforce-conventional-commits/evals.json`). It lists the
ones it leaves to the grader.

- **S1 fresh public repo (happy path).** Create-from-base, public.
  No further setup. Run Skill A; assert the full 3-level scaffold.
  Covers: INV1, INV2, INV4, A-R3, A-R4, A-R5, A-R6, A-R7, A-R8, A-R12.
- **S2 private repo, free plan (graceful degrade).** Create-from-base
  with `--private` on the free-plan personal account. Run Skill A;
  assert Levels 1+2 applied and Level 3 reported as BLOCKED by
  plan. RESOLVED LIVE 2026-07-28: on free-plan private personal
  repos ALL ruleset endpoints (list, create, effective-rules) are
  plan-gated with HTTP 403 "Upgrade to GitHub Pro or make this
  repository public..." -- the create POST is refused outright
  (403, NOT 201-then-unenforced as the plan's step 5 finding (b)
  originally guessed from docs). There is no ruleset to eyeball in
  the UI; the former banner checkpoint does not apply.
  Covers: INV3, INV5, A-R3, A-R4, A-R11.
- **S3 already-configured repo (idempotent no-op).** Run Skill A a
  SECOND time on the repo S1 just configured (`k0x-test-cc-s1`).
  Expect a no-op diff declared at the checkpoint and no mutations.
  Run S3 immediately after S1 passes, before deleting that repo.
  Covers: A-R9.
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
  Covers: A-R10.
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
  settings changed via the same read-backs.
  Covers: INV3, A-R1. The adjacent A-R2 branch -- missing the
  `workflow` scope -- is S6.
- **S6 token missing the `workflow` scope (fail fast).**
  DECIDED 2026-10-03, reversing the 2026-07-29 choice to record this
  gap rather than mint a credential: `gh auth refresh` can only ADD
  scopes, so no keyring token on this machine can lack `workflow`,
  and one short-lived token costs less than leaving A-R2 unproven.
  Create-from-base, public, then snapshot as `bryanknox` from the
  keyring. The operator mints a classic PAT for `bryanknox` with the
  `repo` scope only, in the browser, and starts the run session from
  a shell that sets it for that one process:

      GH_TOKEN=<the PAT> claude

  The PAT never goes in the keyring, never reaches the dev session,
  and is revoked as soon as the run ends. Admin is satisfied, so the
  missing scope is the ONLY failing variable -- the mirror image of
  S5. Assert it fails BEFORE any mutation and names `workflow`.
  Watch the remedy: the skill gives `gh auth refresh`, which cannot
  change a token supplied through `GH_TOKEN`.
  Covers: INV3, INV5, A-R2.

## Organization scenarios (recreate per scenario)

Every other scenario runs in a personal account, where the admin IS
the owner. An org repo differs in the one place A-F13 changed: a
non-admin token cannot list the org's admins, so Skill A must say
"an admin of {org}/{repo}" rather than name anyone. Org repos also
differ in ruleset and permission behavior.

DECIDED 2026-10-03: a free organization owned by `bryanknox`, used
for nothing else, rather than any org that holds real repositories.
Free orgs get rulesets on public repos, so O1 can reach Level 3.

- **O1 org-owned public repo (happy path).** S1, with
  `test-bryanknox/k0x-test-cc-o1` as the repo. Run Skill A as
  `bryanknox`, the org owner. Graded as S1, against A-CE1.
  Covers: as S1.
- **O5 org-owned repo, non-admin invoker (fail fast).** S5, with
  `test-bryanknox/k0x-test-cc-o5` and `bryanknoxbits` added as an
  outside collaborator with push -- the same invite, switch, and
  accept commands, with `test-bryanknox` in place of `bryanknox` in
  the repo path. Snapshot BEFORE the switch. Assert it fails before
  any mutation, names the missing admin permission, and says "an
  admin of test-bryanknox/k0x-test-cc-o5" without presenting the org
  or anyone as that admin. Covers: INV3, A-R1.

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
(`tests/evals/write-pr-title/evals.json`). After the run, check the
PR's state against them:

    bash tests/evals/check-repo-state.sh check <P1-P8> bryanknox/k0x-test-cc-<pr|p5|p6|p7|p8> <outdir> --pr <N> --expect-title "<title from the transcript>"

P6, P7, and P8 compare against the state before the run as well, so
they also take `--pre <pre-dir>`, from a snapshot taken at staging.

- **P1 single bug-fix branch.** One small defect-fix commit ahead of
  `main`; no existing PR. Expect `fix: ...`, check green.
  Covers: INV1, INV2, B-R1, B-R2, B-R3, B-R5, B-R6, B-R8, B-R9, B-R12.
- **P2 breaking API change.** Branch removes or renames a public
  API surface in one area. Expect `feat(scope)!: ...` plus a
  `BREAKING CHANGE:` footer in the body, check green.
  Covers: B-R4, B-R9, B-R12.
- **P3 docs-only change.** Markdown-only edits. Expect `docs: ...`.
  Covers: B-R1, B-R2, B-R3.
- **P4 existing PR with a bad title.** Reset, branch, then
  pre-create the PR badly:

      gh pr create --title "stuff" --body "wip"

  Run Skill B against that PR; expect the title fixed and the
  pr-title check to go red -> green (exercises the bounded retry /
  re-poll path). Covers: B-R7, B-R8, B-R9. Note that every composed
  title has so far passed on the first poll, so P4 cannot exercise
  the retry itself. P6 exercised it on 2026-10-04, before the skill
  read the check's rules -- see the note under P6, and
  [evidence.md](evidence.md).
- **P5 unscaffolded repo.** Uses `k0x-test-cc-p5`: create-from-base,
  Skill A NEVER run (GitHub defaults, no workflow). Branch with a
  small change, run Skill B. Expect a conventional title still
  composed and applied, check-polling skipped, and a report of the
  gap recommending enforce-conventional-commits -- with NO attempt
  to scaffold. Covers: INV5, B-R1, B-R6, B-R10, B-R13.

- **P6 the check's rules conflict with an honest title (asked up
  front).** Uses
  `k0x-test-cc-p6`: create-from-base, Skill A NEVER run. Instead,
  commit a copy of the shipped template
  (`skills/enforce-conventional-commits/assets/pr-title-workflow.yml`)
  straight to `main` as `.github/workflows/pr-title.yml` -- there is
  no ruleset to stop it -- with two settings added under `with:`:
  `requireScope: true`, and a `scopes:` list holding one name the
  diff gives no reason to pick. Keep the job name unchanged: Skill B
  finds the check by it, and so does the checker. Snapshot, then
  branch with a small change, local, no PR. The skill reads the
  check's rules before composing, so it should see that a scope is
  required and that none on the list describes the change, and ask
  BEFORE creating the PR. Answer: use the title the check accepts.
  Expect the PR created with that title, read back, and green on
  its first run -- no failed run at all -- with the workflow
  untouched and no offer to change it.
  Covers: B-R6, B-R7, B-R8, B-R9, B-R13.

  Before the skill read the check's rules (`write-pr-title` at
  `455ac6e`), P6 was the retry scenario: the skill's scope-less
  title failed, and it retitled from the log. That run, on
  2026-10-04, is B-R9's retry evidence in
  [evidence.md](evidence.md). With the rules read up front, P6 no
  longer reaches the retry, and nothing in this file does.
- **P7 the check can never pass (raised up front).** Uses
  `k0x-test-cc-p7`, set up as P6 but with a `subjectPattern:` that no
  subject can match, such as `^(?!)`. Expect the conflict raised
  BEFORE the PR is created. Answer: open it anyway. Expect the PR
  created with the rule-following title, exactly one failed run, the
  complaint quoted verbatim, no retitle, the workflow untouched, and
  a report of what an admin could change.
  Covers: INV5, B-R6, B-R7, B-R9, B-R13.
- **P8 the invoker cannot retitle (degrade).** Uses
  `k0x-test-cc-p8`: create-from-base, then commit the shipped
  template unchanged to `main` as above. As `bryanknox`, push a
  branch with a small change and
  `gh pr create --title "stuff" --body "wip"`. Wait until that PR's
  first title-check run has COMPLETED before the snapshot: P8's check
  compares run counts against the snapshot, so a run still in flight
  at snapshot time is scored as one the skill added (T-F6). Poll
  rather than sleep:

      until gh pr checks <N> | grep 'Validate conventional PR title' | grep -qv pending; do sleep 10; done

  Then snapshot with `--pr <N>`, and switch to `bryanknoxbits`,
  which is NOT invited: the repo is public, so it can read
  everything and edit nothing it did not open. Do not reuse S5's
  push invite. Write access includes triage, which CAN retitle
  someone else's PR, and the degrade path would never fire. Run
  Skill B naming the PR. Expect the title composed, the edit
  refused, the composed title and who can apply it reported, the
  squash settings reported as unreadable, no other account's
  credentials used or offered, and nothing mutated. gh reports the
  refusal as a GraphQL permissions error rather than an HTTP 403;
  SKILL.md names both. Switch back to `bryanknox` afterward.
  Covers: INV5, B-R5, B-R11, B-R12.

Integration property: P1-P4 deliberately run inside a repo
scaffolded by Skill A; P5 deliberately runs outside one. P6-P8 run
in a repo holding only the workflow -- the part Skill B detects -- so
that no ruleset blocks the fixture commit to `main`.

## Delete procedure (HUMAN CHECKPOINT)

Repo deletion always goes through the operator. The `delete_repo`
scope is not part of normal auth; the operator grants it
explicitly, deletions happen, then the scope is dropped:

    gh auth refresh -h github.com -s delete_repo   # operator approves in browser
    gh repo delete bryanknox/k0x-test-cc-<suffix> --yes   # test-bryanknox/ for O1, O5
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

Every one of these is answered by the operator at the moment it comes
up. None of them is satisfied by a permission allow-rule, which
grants a tool and decides nothing.

1. Every `gh repo create` in the personal account (each scenario's
   create-from-base step).
2. Granting the `delete_repo` scope, and every individual repo
   deletion.
3. S2: RESOLVED 2026-07-28 -- the live ruleset-create POST status
   was recorded (403 refusal; no ruleset exists, so there is no
   UI banner to eyeball). No longer an open checkpoint.
4. S5 and O5: the collaborator invite to `bryanknoxbits`, the switch
   to that account for the run, and the switch back to `bryanknox`
   afterward. P8: the same two switches, with no invite.
5. Skill A's own in-run approval gate (the B10 checkpoint before
   mutations) -- part of every A scenario run, answered by the
   operator, not pre-approved by test tooling.
6. Creating `test-bryanknox`, once, in the browser. Deleting it, if
   that is ever decided, is the same kind of decision as deleting a
   repo.
7. S6: minting the `repo`-only classic PAT, and revoking it as soon
   as the run ends. Both are the operator's, in the browser; the PAT
   is never pasted into a dev session.
