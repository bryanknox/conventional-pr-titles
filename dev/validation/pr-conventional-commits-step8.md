# Step 8 validation record: pr-conventional-commits (plan todo #7)

Status: COMPLETE (2026-07-28). Structural lint PASSED (one defect
F1 found and fixed pre-run); real runs P1-P4 all PASSED with
independent read-back verification (P1: 6/6 B-CE1 expectations,
P2: 4/4 B-CE2); without-skill baseline run showed a real but
process-level value delta (see "Run results"). Findings F1-F6
fixed in SKILL.md. Raw traces: `traces/p1-p4-with-skill-traces.md`,
`traces/p-baseline-trace.md`.

Per plan todo #7, P1-P4 ran in `k0x-test-cc-s1` (already
scaffolded by Skill A in todo #6) rather than a separate
`k0x-test-cc-pr` repo -- no new repo-create checkpoint needed, and
the integration property (B runs inside a repo scaffolded by A)
still holds. The repo was restored to its clean S1 end state
afterward for S3 (todo #8).

## Structural lint (PASS, 2026-07-28)

| Check | Result |
|---|---|
| name regex + matches parent dir | PASS (`pr-conventional-commits`) |
| description <= 1024 chars | PASS (645 chars) |
| body <= 500 lines / <= 5000 tokens | PASS (180 lines pre-revision, 194 post; ~1.7K tokens est.) |
| ASCII only (SKILL.md + type-guide.md) | PASS (re-checked post-revision) |
| Interface sketch match (packet step 6) | PASS: S7 reads -> scaffold detection (B2) -> classify w/ lazy type guide (C1) -> compose -> conditional B10 checkpoint -> apply + read-back (S4) -> scaffolded ? poll check w/ bounded retry : skip + gap report -> report |
| Portability (`common-only`) | PASS: frontmatter is name + description only |
| Phantom-dependency check | PASS: setup-conventional-commits named as companion recommendation only; no runtime dependency |
| Lazy-reference trigger | PASS: explicit load trigger for references/type-guide.md ("more than one type or none cleanly") |
| Cost checklist (B13) | PASS: no timestamps/volatile facts in body; volatile state via git/gh reads |
| Job-name coupling | PASS: Step 7 job name `Validate conventional PR title` matches Skill A's workflow asset |

Lint defect found: F1 (below). Fixed BEFORE the real runs, so
P1-P4 exercised the corrected body.

## Findings (all FIXED in SKILL.md, 2026-07-28)

- **F1 (defect, lint):** Step 4 branches on the repo's squash
  MESSAGE setting (`PR_BODY` vs other) and eval B-CE2 asserts on
  it, but Step 2's read fetched only `squash_merge_commit_title`
  -- the skill as drafted never read `squash_merge_commit_message`.
  Fix: field added to the Step 2 read. P1/P2 then used it
  correctly (footer-ride note grounded in the actual `BLANK`
  value).
- **F2 (friction, P1-P3):** Step 7 was silent about unrelated
  checks; every runner inferred title-check-only scope but flagged
  the ambiguity, and P3 used `gh pr checks --watch`, which waits
  on ALL checks (only worked because the title check finished
  first). Fix: title check is the only gate; ignore other checks;
  avoid `--watch`, re-poll the plain command.
- **F3 (friction, P1+P3):** Step 8 report template had no PR URL
  slot; runners appended one ad hoc. Fix: `PR: {url}` line added.
- **F4 (ceremony, P4):** the Step 5 checkpoint fired even though
  the user had explicitly asked to retitle that exact PR -- the
  request already was the approval. Fix: explicit
  retitle-this-PR requests skip the checkpoint; show old -> new
  in the report instead.
- **F5 (gap, P4+P2):** edit-path body handling was unstated
  (runner had to decide to replace the placeholder body "wip"),
  and footer-vs-attribution-trailer ordering was unspecified (P2
  runner reasoned it out correctly). Fix: Step 4 now says refresh
  the body on edits, keep meaningful content, and the
  `BREAKING CHANGE:` footer stays the LAST paragraph with
  trailers above it.
- **F6 (token thrift + robustness, P2+P3):** scaffold-detection
  read returned the whole base64 file payload (`--jq .name` added)
  and assumed the exact filename `pr-title.yml` (fallback added:
  on 404, list `.github/workflows` for any PR-title-linting
  workflow).
- Observed, no action: untracked repo-scoped skill dir in the
  clone triggers a harmless `gh pr create` "1 uncommitted change"
  warning -- artifact of the test install method, not shipped
  behavior. `git log {default_branch}..HEAD` in Step 1 also
  matched runners' use of `origin/main` interchangeably; harmless.

## Environment facts (2026-07-28)

- gh active account was already `bryanknox` (the standing default
  per dev/test-repos.md); scopes `gist, read:org, repo, workflow`.
  No switch needed, none performed.
- `k0x-test-cc-s1` pre-run state verified intact from todo #6:
  squash-only + PR_TITLE + BLANK, all four rules enforced on
  `main`, workflow present. One leftover open Dependabot PR (#1,
  actions bump -- the base repo ships a Dependabot config) was
  closed as part of the first reset.

## Run results (2026-07-28)

All four with-skill runs by fresh subagents against the
repo-scoped skill copy; every claim independently re-verified from
the dev session via `gh pr view` / `gh pr checks`.

| Run | Setup | Title produced | Check | Verdict |
|---|---|---|---|---|
| P1 | null-check bug fix, vague commit msg, unpushed branch | `fix: throw JsonException when JSON file deserializes to null` | pass | PASS 6/6 B-CE1 |
| P2 | required CancellationToken on public interface | `feat!: add cancellation token support to json file loaders` + footer as last paragraph | pass | PASS 4/4 B-CE2 |
| P3 | README-only grammar fix + bullet | `docs: fix grammar and describe workbench JSON file in README` | pass | PASS |
| P4 | pre-created PR #5 titled "stuff" (check red) | `fix: throw JsonException when loaded JSON file deserializes to null` | red -> green | PASS |

Notable behaviors: classification came from the diff in every run
(commit messages were deliberately vague hints); no scope was ever
invented; unpushed branches were pushed unprompted; P4's Step 5
checkpoint fired correctly and was recorded verbatim; the P4
composed title passed first try, so the bounded-retry loop (max 2)
exists but was not consumed -- acceptable, since the red -> green
re-poll path it guards was exercised. Costs: 30.4-33.5K subagent
tokens, 8-11 tool uses, 1.7-2.9 min per run -- within the packet's
Skill B projection (input 10-50K, output 1-4K).

**Without-skill baseline (B-CE1 setup, identical change +
prompt): title-level delta SMALL, process-level delta CLEAR.**
The baseline agent found `pr-title.yml` in the scaffolded repo,
read it, and produced an equivalent conventional title -- the
predicted "generic title" failure mode did NOT occur, because in
a repo scaffolded by Skill A the workflow file itself teaches the
convention. The skill's measured value in scaffolded repos:

- scope restraint: baseline ran unrequested `dotnet test` +
  `dotnet format` and watched ALL CI checks (2x tool uses, ~45%
  more wall clock, ~19% more tokens);
- report content: baseline gave no type rationale and no
  squash-settings analysis;
- determinism: the baseline's success depended on it choosing to
  explore `.github/`; the skill makes the path unconditional.

Evals-gate conclusion: outputs distinguishable -- ship. Honest
caveat carried forward: the title-level delta concentrates in
UNSCAFFOLDED repos (B-CE3/P5, deliberately outside todo #7; runs
with todo #8's campaign or standalone) and in the breaking-change
bookkeeping baseline agents typically miss (B-CE2's footer
placement was flawless with the skill; not baselined). The
`baseline_failure_modes` prediction for B-CE1 in
`dev/evals/pr-conventional-commits/evals.json` remains plausible
for unscaffolded repos and weaker agents but should not be
expected in scaffolded ones.

## Disposition and follow-ups

- `k0x-test-cc-s1` KEPT and restored to clean S1 end state (no
  open PRs, only `main`, scaffold untouched) -- S3/S4 (todo #8)
  run next; delete only after todo #8 per test-repos.md.
- PRs #1-#6 closed (not merged), branches deleted; closed-PR
  history is inert for S3.
- gh active account remains `bryanknox` (normal state; no
  restore step).
- P5 (unscaffolded repo, `k0x-test-cc-p5`) NOT run here: todo #7
  scoped to P1-P4. It needs one repo create (human checkpoint);
  fold into todo #8's campaign.
- Residuals unchanged: S2 live POST status (todo #8);
  trigger-eval validation gate on final descriptions (todo #9 --
  description text did not change in this todo, so todo #6/#7
  wording is what the gate will test).
