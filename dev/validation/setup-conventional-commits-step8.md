# Step 8 validation record: setup-conventional-commits (plan todo #6)

Status: COMPLETE (2026-07-28). Structural lint PASSED; real run
on scenario S1 PASSED 8/8 A-CE1 expectations with independent
read-back verification; without-skill baseline showed a clear
value delta (see "Run results"). Findings F1-F4 fixed in
SKILL.md. Raw traces: `traces/s1-with-skill-trace.md`,
`traces/s1b-baseline-trace.md`.

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

### F2-F4 (frictions from the S1 trace, FIXED 2026-07-28)

- F2: Step 3 checklist location was ambiguous ("session's working
  area"); the runner had to decide not to drop it in the repo.
  Body now says: scratch area OUTSIDE the repo working tree.
- F3: `gh api` exits nonzero on EXPECTED preflight outcomes (404
  workflow-absent read; empty `--jq` plan read), breaking `&&`
  chains / `set -e`. Body now says: run preflight reads as
  independent commands.
- F4: the Step 7 `<<'JSON'` heredoc is POSIX-only; on the Windows
  host it required the Bash tool. Body now names the POSIX-shell
  requirement and the `--input <temp file>` alternative.
- Observed, no action: the ruleset POST response contains
  server-populated fields beyond the request (e.g.
  `pull_request.allowed_merge_methods`,
  `do_not_enforce_on_create`); harmless because verification uses
  the effective-rules endpoint, not a JSON diff.

## Run results (2026-07-28)

Note on the earlier "blocked" state: the classifier denial of
`gh repo create` was resolved by the operator adding a
`Bash(gh repo create:*)` allow rule; repo creation then proceeded.

**With-skill run (A-CE1, `k0x-test-cc-s1`, public,
create-from-base): PASS 8/8 expectations.** Subagent followed the
installed skill; checkpoint approval was delegated with a
match-the-documented-target condition (unattended run). All three
levels applied in order L1 -> L3 -> L2; exactly one checkpoint
before any mutation; every mutation read-back verified; final
report matched the Step 8 template incl. residual soft spot and
action-version note (latest v6.1.1 = pinned major, no lag).
Independently re-verified from the dev session (not trusting the
runner): merge settings squash-only/PR_TITLE/BLANK; ruleset
19925505 active, empty bypass, `~DEFAULT_BRANCH`;
`rules/branches/main` returns all four rule types; deployed
workflow byte-identical to the template modulo CRLF. Run cost:
~38K subagent tokens, 18 tool uses, ~3.4 min.

**Without-skill baseline (same prompt, `k0x-test-cc-s1b`): value
delta CLEAR.** The baseline configured squash-only merges and
built a competent hand-rolled PR-title check (repo-native pwsh
validator + Pester tests + workflow; even live-tested it via a
throwaway PR), BUT:

- declined any ruleset / branch protection ("owner commits
  directly to main"), so the check is advisory: direct pushes and
  merges with a failing title remain possible -- the core goal
  (only path to main = squash-merged PR with valid title) is NOT
  met. Matches the predicted enforcement-shaped failure band,
  though not the four specific predicted failure modes (those it
  avoided).
- unrequested scope: `delete_branch_on_merge=true`,
  `squash_merge_commit_message=PR_BODY`, PR template, policy doc,
  AGENTS.md edits; ~388 lines of bespoke validator code to
  maintain vs a pinned maintained action.
- no approval checkpoint before mutating; ~2x cost (71K tokens,
  35 tool uses, ~8.3 min).

Evals-gate conclusion: with/without outputs are clearly
distinguishable; the skill's value is enforcement completeness +
checkpoint discipline + scope restraint, not raw competence.

## Disposition and follow-ups

- `k0x-test-cc-s1` KEPT: S3 (idempotent re-run) runs against it
  in plan todo #8, per test-repos.md.
- `k0x-test-cc-s1b` no longer needed: operator deletion per the
  delete procedure (human checkpoint) whenever convenient.
- gh active account restored to `bryanknoxbits` after the
  campaign; switch to `bryanknox` again for todos #7/#8 (note
  added to dev/test-repos.md).
- Residuals unchanged: S2 live POST status (todo #8); trigger-eval
  validation gate (todo #9).
