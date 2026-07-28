# Step 8 validation record: setup-conventional-commits (plan todo #6)

Status: IN PROGRESS (2026-07-28). Structural lint PASSED; one
defect found and fixed pre-run (F1); real run on scenario S1 is
staged but BLOCKED at the repo-creation human checkpoint (see
"Run status" below).

## Structural lint (PASS, 2026-07-28)

| Check | Result |
|---|---|
| name regex + matches parent dir | PASS (`setup-conventional-commits`) |
| description <= 1024 chars | PASS (641 chars) |
| body <= 500 lines / <= 5000 tokens | PASS (295 lines, ~2.7K tokens est.) |
| ASCII only (SKILL.md + workflow asset) | PASS |
| Interface sketch match (packet step 6) | PASS: preflight fail-fast, diff+checklist (B4), single checkpoint (B10), apply order L1->L3->L2, read-back after every mutation (S4), idempotent no-op path, final report with residual soft spot |
| Portability (`common-only`) | PASS: no harness-specific syntax in SKILL.md; frontmatter is name+description only |
| Phantom-dependency check | PASS: pr-conventional-commits is a companion-module recommendation only (description + boundary note); no runtime dependency, none required |
| Bundled scripts | N/A (one asset, no scripts) |
| Cost checklist (B13) | PASS: no timestamps/volatile facts in the body; volatile state arrives via gh reads |
| Job-name coupling | PASS: workflow job name `Validate conventional PR title` == ruleset `required_status_checks.context` in the skill body |

## Findings

### F1 (defect, FIXED): plan detection can never work as written

Observed live (not hypothesized): `gh api user` with gh's default
OAuth scopes (`gist, read:org, repo, workflow`) returns a response
with NO `plan` key at all -- GitHub includes `plan` in `GET /user`
only when the token has the `user` scope, which gh's default auth
does not request. So the drafted preflight
`gh api user --jq .plan.name` yields empty/null on a normal gh
install, and the S2 free-plan gap could never be detected
proactively as drafted.

Revision applied to SKILL.md (2026-07-28):

- Preflight comment now says the field is EMPTY without the `user`
  scope and empty must be read as UNKNOWN, not `free`.
- The private-plan-gap paragraph now treats the plan read as
  best-effort: on a private repo, either the gap (plan `free`) or
  the uncertainty (plan unknown) is carried into the checkpoint,
  and the Level 2 read-back (`rules/branches/{default_branch}`,
  which returns only actively enforced rules) is named the
  definitive enforcement detector.
- Step 7 verify text widened from "private free-plan repo" to
  "private repo (free or unknown plan)".
- Eval A-CE2 expectation 1 updated to accept plan=UNKNOWN at
  preflight (dev/evals/setup-conventional-commits/evals.json).

Plan-doc impact: step 5 finding (b) in
`dev-info/conventional-commits-skills-plan.md` assumed the plan
read works; the S2 scenario (todo #8) should verify the UNKNOWN
path in practice.

## Environment facts (2026-07-28)

- gh had two accounts; active was `bryanknoxbits`. Switched active
  to `bryanknox` for the test campaign (test repos live in the
  `bryanknox` personal account). Both tokens carry
  `repo, workflow`; neither carries `delete_repo` (as documented).
  RESTORE AFTERWARD: `gh auth switch -h github.com -u bryanknoxbits`.
- No leftover `k0x-test-cc-*` repos before the run.

## Run status: S1 staged, blocked at the create checkpoint

Per dev/test-repos.md, `gh repo create` is a human checkpoint; the
harness permission classifier enforced exactly that (denied the
command in the autonomous session). Nothing was mutated on GitHub.

Staged so far (session scratchpad, ephemeral -- redo the staging
steps if resuming in a fresh session):

- Base cloned to `<scratchpad>/k0x-test-cc-s1`, remote `origin`
  renamed to `base` (points at read-only k0x-workbench).
- Revised skill installed repo-scoped at
  `.claude/skills/setup-conventional-commits/` in the clone,
  untracked.

To resume (operator action, then continue todo #6):

    cd <scratchpad>/k0x-test-cc-s1
    gh repo create bryanknox/k0x-test-cc-s1 --public --source . --push

Remaining todo #6 work after the repo exists: with-skill run of
A-CE1 (fresh session in the clone; capture trace), independent
`gh api` read-back assertions, without-skill baseline run of A-CE1
(needs a second fresh repo, suggested name `k0x-test-cc-s1b`),
grade the A-CE1 expectations + baseline delta here, revise the
skill from the trace, then run S3 (idempotent re-run) on the same
repo per test-repos.md before any deletion.
