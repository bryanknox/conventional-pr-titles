---
name: dev-test-repo-lifecycle
description: >-
  Use this skill in the conventional-pr-titles repository to create,
  stage, reset, or tear down the k0x-test-cc test repositories that
  tier-2 evals run against: create one from the k0x-workbench base,
  stage scenario S1-S6, O1, O5, or P1-P8, install or remove the
  skill under test, take the pre-run snapshot, reset k0x-test-cc-pr
  between P runs, or list and delete leftover test repos. Stops at
  every human checkpoint and reads back every mutation.
  Maintainer-only: does NOT run either skill under test, does NOT
  grade a run or run the repo-state check, does NOT run gh repo
  delete, grant scopes, or switch gh accounts (it hands those over
  and reads the result back), does NOT touch the base repo, and does
  NOT absorb campaigns or cut a release.
---

# Test-Repo Lifecycle (create, stage, reset, tear down)

Every tier-2 content eval runs against a real GitHub repository,
because merge settings, rulesets, and status checks are server-side
state that cannot be faked. Getting a repository into a scenario's
starting state is the step with every human checkpoint in this
repository, and the step where an improvised command re-breaks a
correction that was paid for once already. This skill takes a test
repository to "ready to run", resets it, and tears it down.

`docs/devs/test-repos.md` is the authority for this procedure; this
skill is the enforcement. Where the two disagree the page wins --
stop and say so rather than reconciling them here.

Boundaries: this skill does NOT run either skill under test, does
NOT grade a run, and does NOT run
`tests/evals/check-repo-state.sh check` -- grading is the
maintainer's, and the run itself must happen in a fresh session. It
does NOT run `gh repo delete`, does NOT grant or drop a gh scope, and
does NOT switch gh accounts. Each of those is handed over as a
command, and the result is read back. It never mutates
`bryanknox/k0x-workbench`.

## Who can run this

| | |
|---|---|
| Intended user | The maintainer, working in this repository |
| Runs how often | Before each content eval run, between P runs, and once at the end of a campaign |
| Mutates | `bryanknox/k0x-test-cc-*` and `test-bryanknox/k0x-test-cc-*` repositories, and local clones under the parent directory the maintainer names |
| Does not touch | `bryanknox/k0x-workbench`, the `test-bryanknox` organization itself, this repository's tracked files, gh auth state, any token, anything under `skills/` |
| On no parent directory stated | Stop and ask -- never pick one |

## The commands are corrections

The `gh` and `git` commands below are copied from test-repos.md, and
several of them carry a correction that the obvious version of the
command re-breaks:

- `git remote rename origin base` before `gh repo create --source .`,
  which fails if `origin` exists. Every push afterwards names
  `origin`, never `base`.
- Squash title and message PATCHed together, or the API answers
  `invalid_squash_commit_setting_combo`.
- A ruleset bypass actor of type `RepositoryRole`, not `RepoRole`.
- `--remove-scopes` to drop a scope. `-s` only ever adds.

Use them as written. Do not substitute an equivalent.

## Human checkpoints

Numbered as in test-repos.md, "Human checkpoints (consolidated)".

| # | Checkpoint | Who acts | This skill |
|---|---|---|---|
| 1 | Every `gh repo create` | The maintainer approves | Asks at step 2, one create per approval |
| 2 | The `delete_repo` grant, and each deletion | The maintainer runs them | Hands over each command, one repository at a time, and reads back |
| 4 | S5 and O5: the invite, the switch to `bryanknoxbits`, the switch back. P8: the two switches, no invite | The maintainer switches | Sends the invite after approval, hands over both switches |
| 5 | Skill A's own approval gate in a run | The maintainer, in the run | Out of scope -- it never runs a skill under test |
| 6 | Creating `test-bryanknox` | The maintainer, in the browser | Never creates or deletes it; a missing org stops O1 and O5 at step 1 |
| 7 | S6: minting the `repo`-only PAT, and revoking it | The maintainer, in the browser | Never sees the token; hands over the launch line and the revoke |

**A permission rule is not a checkpoint.**
`.claude/settings.local.json` allows `Bash(gh repo create:*)`, so no
permission prompt will appear before a create. Ask anyway. The
question is whether a repository should exist in the personal
account, and an allow-rule grants a tool without deciding that.

**One scenario per invocation.** A run stages at most one scenario
and creates at most one repository. That is what keeps checkpoint 1
a per-create decision while the run still asks for one approval.

## Step 0 - Which operation, which repository

The operation comes from the maintainer's prompt. If it is
ambiguous, ask.

| Operation | What it does |
|---|---|
| inventory | Steps 1 and the leftover list. Read-only, no checkpoint |
| stage {scenario} | Steps 1 to 7 for one scenario |
| stage {scenario} baseline | Steps 1 to 7 in the baseline's own repository, skipping the install |
| install or remove {skill} | Steps 1, 2, and 5 against an existing clone |
| reset | Steps 1, 2, and the reset, against `k0x-test-cc-pr` |
| teardown | Steps 1, 2, and the teardown |

From the naming table in test-repos.md. `{owner}` is `bryanknox`
except where the table says `test-bryanknox`, the test organization.

| Scenario | Owner | Repository | Visibility | Lifecycle |
|---|---|---|---|---|
| S1 | bryanknox | `k0x-test-cc-s1` | public | create |
| S2 | bryanknox | `k0x-test-cc-s2` | private | create |
| S3 | bryanknox | `k0x-test-cc-s1` | public | reuse S1's end state; no create |
| S4 | bryanknox | `k0x-test-cc-s4` | public | create |
| S5 | bryanknox | `k0x-test-cc-s5` | public | create |
| S6 | bryanknox | `k0x-test-cc-s6` | public | create |
| O1 | `test-bryanknox` | `k0x-test-cc-o1` | public | create |
| O5 | `test-bryanknox` | `k0x-test-cc-o5` | public | create |
| P1-P4 | bryanknox | `k0x-test-cc-pr` | public | create and scaffold once, then reset per run |
| P5 | bryanknox | `k0x-test-cc-p5` | public | create; never scaffold |
| P6 | bryanknox | `k0x-test-cc-p6` | public | create; fixture workflow, never scaffold |
| P7 | bryanknox | `k0x-test-cc-p7` | public | create; fixture workflow, never scaffold |
| P8 | bryanknox | `k0x-test-cc-p8` | public | create; template workflow, never scaffold |

A baseline's repository is the scenario's with `b` appended --
`k0x-test-cc-p6b`, or `k0x-test-cc-prb` for P1-P4 -- staged exactly
as the scenario, with the same change, and with no skill installed.
Never stage a baseline in the with-skill run's repository: closed
pull requests and pushed branches stay readable, and a baseline that
reads them is not a baseline.

Which requirements each scenario covers is deliberately not listed
here. `tests/check-requirement-ids.sh` does not scan this folder, so
an id transcribed here would be a citation nothing resolves. Read the
`Covers:` lines in test-repos.md if the maintainer asks.

Every operation except inventory needs the parent directory that
holds the local clones, stated by the maintainer. The clone is
`{parent}/k0x-test-cc-{suffix}`. If the parent was not stated, stop
and ask.

## Step 1 - Preflight (read-only)

Run each command on its own, never chained with `&&` and never under
`set -e`. `gh api` and `gh repo view` exit non-zero on answers that
are expected here -- a 404 for an absent repository or workflow, a
403 for a plan gate -- and chaining throws away every read after the
first.

```
gh auth status
gh repo list bryanknox --json name --jq '.[].name' | grep '^k0x-test-cc-'
gh repo list test-bryanknox --json name --jq '.[].name' | grep '^k0x-test-cc-'
gh repo view {owner}/k0x-test-cc-{suffix} --json name,visibility
ls -d {parent}/k0x-test-cc-{suffix}
gh api repos/bryanknox/k0x-workbench --jq .pushed_at
```

Required:

- `bryanknox` is the active account. If another account is active,
  hand over `gh auth switch -h github.com -u bryanknox` and wait.
  Do not run it.
- For O1 and O5, `test-bryanknox` exists and `bryanknox` is an
  owner of it: the membership read below answers `admin`. A missing
  org is the maintainer's to create, never this skill's.

  ```
  gh api orgs/test-bryanknox/memberships/bryanknox --jq .role
  ```
- For a create, the repository does not exist and the clone path
  does not exist. Either one present stops the run: a leftover is
  the maintainer's to inspect or delete, never to overwrite.
- For S3, reset, or install, both exist. For S3, also ask whether
  S1 was graded and passed -- S3 runs on S1's end state, before that
  repository is deleted.
- The base's `pushed_at` is recorded. Step 7 reads it again.

For P1-P4, also confirm the scaffold on `k0x-test-cc-pr` with the
four reads from "Checking an enforced repository" in
`docs/devs/README.md` -- the endpoints the skill itself verifies
through, so this check cannot drift from it:

```
gh api repos/bryanknox/k0x-test-cc-pr
gh api repos/bryanknox/k0x-test-cc-pr/contents/.github/workflows/pr-title.yml
gh api repos/bryanknox/k0x-test-cc-pr/rulesets
gh api repos/bryanknox/k0x-test-cc-pr/rules/branches/main
```

Required: squash merge only, `squash_merge_commit_title` is
`PR_TITLE`, the workflow present, and a non-empty effective-rules
answer. A miss stops the run; the remedy is re-running
`enforce-conventional-commits`, which this skill does not do.

For inventory, report the leftover list and stop.

## Step 2 - Checkpoint (human approval)

Present everything the run will do as ONE reviewable block, then
wait:

- the operation, the scenario, the repository, and its visibility
- the clone path
- every mutation in order: the create, the scenario setup, the
  install or removal, the snapshot directory, the local clone to
  remove
- every command handed over to the maintainer, in the order it will
  be asked for

One approval covering everything, not one per step. A skill that
asks repeatedly trains people to approve without reading. The
handed-over commands are not approved here. They are the
maintainer's to run when the skill asks for each one.

## Step 3 - Create from base

Skip for S3 and for any operation that is not a create.

```
git clone https://github.com/bryanknox/k0x-workbench {parent}/k0x-test-cc-{suffix}
cd {parent}/k0x-test-cc-{suffix}
git remote rename origin base
gh repo create {owner}/k0x-test-cc-{suffix} --public --source . --push
```

`--private` instead of `--public` for S2 only. Return to this
repository's root afterwards: every `skills/` and `tests/` path below
is relative to it.

Read back:

```
git -C {parent}/k0x-test-cc-{suffix} remote -v
gh repo view {owner}/k0x-test-cc-{suffix} --json visibility,defaultBranchRef
gh api repos/{owner}/k0x-test-cc-{suffix}
gh api repos/{owner}/k0x-test-cc-{suffix}/contents/.github/workflows/pr-title.yml
gh api repos/{owner}/k0x-test-cc-{suffix}/rulesets
```

Required: `origin` is the test repository and `base` is
k0x-workbench; the visibility is the one approved; all three merge
methods are enabled; the workflow read is a 404; the ruleset list is
empty. For S2 the ruleset read is a 403 naming the plan, which is the
expected answer on a free-plan private repository, not a failure.

Expect Dependabot pull requests within minutes of a public create:
the base ships `.github/dependabot.yml`. They are not the skill's
and not part of any scenario, so never close or count them. Say they
are there in the report, because a session under test may read them
in an unfiltered `gh pr list`.

## Step 4 - Scenario setup

Only what test-repos.md describes for the scenario. Nothing else.

**S1, S2, S3.** None.

**S4 -- a stray ruleset.** Do NOT PATCH the merge settings: a fresh
create-from-base repository is already in the conflicting state the
scenario needs. Write an ad hoc ruleset to the session's scratch
directory -- it is scenario fodder, never committed, never a
maintained asset -- targeting `main`, carrying only a `deletion`
rule, with a non-empty bypass list of actor type `RepositoryRole`
and actor id 5 (repository admin). Then:

```
gh api -X POST repos/bryanknox/k0x-test-cc-s4/rulesets --input {scratch}/stray-ruleset.json
gh api repos/bryanknox/k0x-test-cc-s4/rulesets
```

Required: the list read shows exactly the one stray ruleset.

**S6 -- a token missing `workflow`.** Nothing on the repository.
Take the step-6 snapshot as `bryanknox` from the keyring. The token
is the maintainer's: they mint a classic PAT with the `repo` scope
only, and start the run session from a fresh Git Bash in the clone
with `export GH_TOKEN=<the PAT>`, then `gh auth status`, then
`claude`. The status must show a `bryanknox (GH_TOKEN)` entry with
`'repo'` as its only scope before `claude` is started; the one-line
`GH_TOKEN=<the PAT> claude` form once failed to reach the session.
If the run's own first `gh auth status` shows only keyring logins,
the maintainer must not approve the skill's checkpoint. Never ask for
the token and never run these lines. The report carries the launch
lines, both checks, and the revoke.

**O1.** None; as S1.

**S5 and O5 -- a non-admin invoker.** Take the step-6 snapshot FIRST,
while `bryanknox` is still active. Then:

```
gh api -X PUT repos/{owner}/k0x-test-cc-{suffix}/collaborators/bryanknoxbits -f permission=push
```

Hand over `gh auth switch -h github.com -u bryanknoxbits` and wait.
After the maintainer says it has run:

```
gh auth status
gh api user/repository_invitations --jq '.[] | [.id, .repository.full_name] | @tsv'
gh api -X PATCH user/repository_invitations/{id}
gh api repos/{owner}/k0x-test-cc-{suffix}/collaborators/bryanknoxbits/permission --jq .permission
```

Required: `bryanknoxbits` active, exactly one invitation for
`{owner}/k0x-test-cc-{suffix}` accepted, and the permission reads
`write`. The
switch back to `bryanknox` comes after the eval run, so it goes in
the report as the maintainer's.

**`k0x-test-cc-pr`, the one-time scaffold.** After the create, the
scaffold is a Skill A run, and a skill run is out of scope here.
Install `enforce-conventional-commits` into the clone (step 5), then
hand over: start a fresh session in the clone and run it there. The
next invocation of this skill confirms the scaffold with the step-1
reads.

**P1-P4.** Run the reset below, then create one branch in the clone
with the change the scenario describes, as ad hoc edits to the base
repository's files:

| Scenario | The branch |
|---|---|
| P1 | one small defect-fix commit; no PR |
| P2 | removes or renames a public API surface in one area; no PR |
| P3 | Markdown-only edits; no PR |
| P4 | any small change, pushed, with a badly titled PR |

For P4 only:

```
git -C {parent}/k0x-test-cc-pr push -u origin {branch}
cd {parent}/k0x-test-cc-pr
gh pr create --title "stuff" --body "wip"
gh pr view --json number,title,headRefName,state
```

Required: the PR is open, its title is exactly `stuff`, and its head
is the new branch. Record the PR number; the post-run check needs it.

P1-P3 stay local and unpushed: the eval's setup is a branch ahead of
the default branch with no PR.

Read back for every P branch:

```
git -C {parent}/k0x-test-cc-pr log --oneline main..HEAD
git -C {parent}/k0x-test-cc-pr diff --stat main..HEAD
```

**P5.** After the create, never install or run Skill A. Create one
branch with a small change and leave it local. Read back as for P1-P4,
and confirm the workflow read from step 3 is still a 404.

**P6, P7, P8 -- a workflow without a scaffold.** After the create,
never install or run Skill A. Copy
`skills/enforce-conventional-commits/assets/pr-title-workflow.yml` to
`.github/workflows/pr-title.yml` in the clone. Keep the job name
unchanged. For P6, add under `with:` the two settings test-repos.md
gives -- `requireScope: true` and a `scopes:` list of one name the
branch's change gives no reason to pick. For P7, add the
unsatisfiable `subjectPattern:` instead. For P8, change nothing. Then
commit it straight to `main` and push -- no ruleset exists to stop
it:

```
git -C {parent}/k0x-test-cc-{suffix} add .github/workflows/pr-title.yml
git -C {parent}/k0x-test-cc-{suffix} commit -m "ci: add the PR title check fixture"
git -C {parent}/k0x-test-cc-{suffix} push origin main
gh api repos/{owner}/k0x-test-cc-{suffix}/contents/.github/workflows/pr-title.yml --jq .content
```

Required: the decoded content equals the file in the clone. Then,
for P6 and P7, take the step-6 snapshot and create one branch with a
small change, left local, read back as for P1-P4.

For P8, as `bryanknox`, push a branch with a small change and open
the badly titled PR, exactly as for P4:

```
git -C {parent}/k0x-test-cc-p8 push -u origin {branch}
cd {parent}/k0x-test-cc-p8
gh pr create --title "stuff" --body "wip"
gh pr view --json number,title,headRefName,state
```

Required as for P4. Then wait until the PR's first title-check run
has COMPLETED, polling rather than sleeping:

```
until gh pr checks {n} | grep 'Validate conventional PR title' | grep -qv pending; do sleep 10; done
```

P8 is graded by comparing check-run counts with the snapshot, so a
run still in flight when the snapshot is taken is later scored as
one the skill added. Only then take the step-6 snapshot with
`--pr {n}`.

Do NOT invite `bryanknoxbits`: push access includes triage, which
can retitle the PR, and the scenario needs an invoker who cannot.
Then hand over `gh auth switch -h github.com -u bryanknoxbits`, wait,
and read back:

```
gh auth status
gh api repos/{owner}/k0x-test-cc-p8 --jq .permissions
```

Required: `bryanknoxbits` active, and `push`, `triage`, and `admin`
all false. The switch back to `bryanknox` goes in the report.

## Step 5 - Install or remove the skill under test

Repo-scoped only, never user-scoped, so the skill under test cannot
leak into other sessions. Record exactly which version is going in:

```
git rev-parse HEAD
git status --porcelain skills/{name}
```

A non-empty status means uncommitted edits are being installed. That
is allowed -- it is often the point -- and it goes in the report.

```
mkdir -p {parent}/k0x-test-cc-{suffix}/.claude/skills
cp -r skills/{name} {parent}/k0x-test-cc-{suffix}/.claude/skills/{name}
```

Read back:

```
diff -r skills/{name} {parent}/k0x-test-cc-{suffix}/.claude/skills/{name}
git -C {parent}/k0x-test-cc-{suffix} ls-files .claude/skills/{name}
git -C {parent}/k0x-test-cc-{suffix} status --porcelain
```

Required: the diff prints nothing, `ls-files` prints nothing, and the
status shows the copy as untracked (`??`) -- it is never committed to
the test repository, so resets and diffs never see it. Name the skill
in the `ls-files` path: the base tracks its own `.claude/` files (an
agent, a rule, and a `normalize-bench-file` skill), so
`ls-files .claude` is never empty.

A baseline is staged in its own repository and skips the install.
In a clone that ever held the skill, remove it instead:

```
rm -rf {parent}/k0x-test-cc-{suffix}/.claude/skills/{name}
ls -d {parent}/k0x-test-cc-{suffix}/.claude/skills/{name}
```

Required: the `ls` fails.

Trigger evals are not installed this way: `run-trigger-evals.sh`
builds its own fixture.

## Step 6 - Pre-run snapshot (S3-S6, O5, P6-P8)

These are graded against the state before the run.

```
bash tests/evals/check-repo-state.sh snapshot {owner}/k0x-test-cc-{suffix} {pre-dir}
```

For P8, add `--pr {n}`. The pre-dir is the maintainer's to name, and
it must outlive this session. Read the script's summary line; a run
with exit status 2 did not take the snapshot. For S5, O5, and P8
this runs before the account switch. For S6 it runs as `bryanknox`
from the keyring, never with the PAT.

## Step 7 - Base read-back, then report

```
gh api repos/bryanknox/k0x-workbench --jq .pushed_at
```

Required: identical to the step-1 value. A difference means
something reached the base -- report it first, ahead of everything
else.

Then report, and stop. The eval run is a fresh session, and this
session must not become it.

## Reset (P1-P4, between every run)

The ruleset does not block any of this: branch deletion is
remote-branch cleanup, not `main`. The `xargs` lines are the
documented procedure; closing a PR and deleting a branch are not the
one-way step that the loop rule below is about.

```
cd {parent}/k0x-test-cc-pr
gh pr list --state open --json number --jq '.[].number' | xargs -I{} gh pr close {} --delete-branch
gh api repos/bryanknox/k0x-test-cc-pr/branches --jq '.[].name' | grep -v '^main$' | xargs -I{} gh api -X DELETE repos/bryanknox/k0x-test-cc-pr/git/refs/heads/{}
git checkout main
git fetch --prune origin
git reset --hard origin/main
git branch | grep -v '^\* main$' | xargs -r git branch -D
```

Reset does NOT touch settings, the ruleset, or the workflow -- those
are the scaffold. Read back:

```
gh pr list --state open --json number
gh api repos/bryanknox/k0x-test-cc-pr/branches --jq '.[].name'
git -C {parent}/k0x-test-cc-pr status --porcelain
git -C {parent}/k0x-test-cc-pr rev-parse HEAD origin/main
git -C {parent}/k0x-test-cc-pr branch
```

Required: no open PRs, `main` the only remote branch, a clean tree,
`HEAD` equal to `origin/main`, and `main` the only local branch.
Then repeat the step-1 scaffold reads: a reset that damaged the
scaffold is a stop, and the remedy is the maintainer's.

## Teardown

**Never script a loop over `gh repo delete`.** "Clean up the test
repos" sounds like a loop, and a loop is the first shape anyone
reaches for. Deletion is one confirmed command per repository.

1. List the leftovers with the step-1 finder. The maintainer names
   which to delete, in either owner. If `k0x-test-cc-pr` is on the
   list, say that it is long-lived across the P1-P4 campaign and ask
   whether that campaign is finished.
2. Hand over the grant, and wait:
   `gh auth refresh -h github.com -s delete_repo`. The maintainer
   approves it in a browser. Read back `gh auth status` and confirm
   `delete_repo` is among the scopes.
3. For each repository, one at a time: hand over exactly one command,
   `gh repo delete {owner}/k0x-test-cc-{suffix} --yes`, and wait.
   Then read back
   `gh repo view {owner}/k0x-test-cc-{suffix} --json name` and
   require a not-found. Only then name the next one. Never put two
   repositories in one command.
4. Remove each approved local clone, only after its remote read-back
   is a not-found: `rm -rf {parent}/k0x-test-cc-{suffix}`, then
   `ls -d` it and require a failure.
5. Hand over the drop, and wait:
   `gh auth refresh -h github.com --remove-scopes delete_repo`. Read
   back `gh auth status` and require that `delete_repo` is gone. If
   it is still there, say so; it is the failure the old `-s` form of
   this command produced.
6. Run the finder again and report what is left.

## Report

```markdown
## Test repo {inventory | stage | install | remove | reset | teardown}: {scenario}, {date}

Repository: {owner}/k0x-test-cc-{suffix} ({visibility})
Clone: {parent}/k0x-test-cc-{suffix}
gh account at start: {account}

Read-backs:
    {per step: the command, then its output verbatim}

Skill installed: {name} at {sha}, {clean | uncommitted edits: the
status lines} | none | removed for a baseline run
Pre-run snapshot: {pre-dir} | not needed for {scenario}
P4 or P8 PR: #{n} | n/a
Base pushed_at: {before} -> {after}, {unchanged | CHANGED}

Leftover test repos: {the finder output | none}

Still yours:
- {each handed-over command not yet run}
- start a FRESH session in {parent}/k0x-test-cc-{suffix} for the
  eval run, and check the session header names that directory before
  typing the prompt
- after the run: {check command with --pre and --pr as needed}
- {S5, O5, P8: gh auth switch -h github.com -u bryanknox}
- {S6: export GH_TOKEN=<the PAT>; gh auth status shows the
  (GH_TOKEN) entry with repo only; then claude. After the run, unset
  GH_TOKEN and revoke the PAT}
```
