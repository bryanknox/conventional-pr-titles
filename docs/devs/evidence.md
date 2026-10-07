# Evidence index

**What this is for:** answering "has this ever actually been run, and
when?" without reading six dated records.

**Read it** before claiming a behavior is proven, and before designing
a campaign -- it shows what is already covered.

**Write to it** at the end of every tier-2 campaign.

Every requirement in [behavior-spec.md](behavior-spec.md) appears in
the coverage table below exactly once, either with the run that
exercised it or as NOT PROVEN.
`tests/check-requirement-ids.sh` enforces that, so a new requirement
cannot be added without saying whether anything has ever tested it.

The scenario ids (S1-S6, O1, O5, P1-P8) are defined in
[test-repos.md](test-repos.md); the content eval ids (A-CE1-4,
B-CE1-6) in `tests/evals/<skill>/evals.json`.

## Coverage

| Requirement | Exercised by | Record | Date | Verdict |
|---|---|---|---|---|
| INV1 | A-CE1/S1, B-CE1/P1, and every run | [S1](validation-records/setup-conventional-commits-step8.md), [P1](validation-records/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| INV2 | A-CE1/S1 expectation 7, B-CE1/P1 expectation 4 | [S1](validation-records/setup-conventional-commits-step8.md), [P1](validation-records/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| INV3 | S5 (fails before mutating), S2 (degrades after); S6, O5 (fail before mutating) | [S5](validation-records/s5-non-admin.md), [S2](validation-records/todo8-degraded-idempotency.md), [2026-10 runs](#enforce-conventional-commits) | 2026-07-28/29, 2026-10-03/04 | PROVEN |
| INV4 | A-CE1/S1 expectation 2 | [S1](validation-records/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| INV5 | S2, P5 | [todo #8](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R1 | S5; O5 / A-CE4 (org-owned: "an admin of {org}/{repo}") | [S5](validation-records/s5-non-admin.md), [2026-10 runs](#enforce-conventional-commits) | 2026-07-29, 2026-10-04 | PROVEN |
| A-R2 | S6 / A-CE3 | [2026-10 runs](#enforce-conventional-commits) | 2026-10-03 | **PARTIAL** -- amended in #35, not yet re-run; see [known-gaps.md](known-gaps.md) |
| A-R3 | A-CE1/S1, A-CE2/S2, S4 | [S1](validation-records/setup-conventional-commits-step8.md), [todo #8](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R4 | A-CE1/S1, A-CE2/S2, S4 | [S1](validation-records/setup-conventional-commits-step8.md), [todo #8](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R5 | A-CE1/S1, S4 | [S1](validation-records/setup-conventional-commits-step8.md), [todo #8](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R6 | S1 mutation summary: exactly three mutations, nothing local | [S1](validation-records/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| A-R7 | A-CE1/S1 expectation 4 | [S1](validation-records/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| A-R8 | A-CE1/S1 expectation 2 | [S1](validation-records/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| A-R9 | S3 | [todo #8](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R10 | S4 | [todo #8](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R11 | A-CE2/S2 | [todo #8](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R12 | A-CE1/S1 expectation 8 | [S1](validation-records/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| A-R13 | -- | -- | -- | **NOT PROVEN** -- see [known-gaps.md](known-gaps.md) |
| A-R14 | Dispatch only (trigger case A-N9, last scored under the current names on 2026-10-02) | [rename gate](validation-records/rename-trigger-gate.md), [trigger gates](#trigger-gates) | 2026-10-02 | **PARTIAL** -- see [known-gaps.md](known-gaps.md) |
| B-R1 | P1-P5 | [P1-P4](validation-records/pr-conventional-commits-step8.md), [P5](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| B-R2 | P1-P5; classification came from the diff in every run, with deliberately vague commit messages as decoys | [P1-P4](validation-records/pr-conventional-commits-step8.md), [P5](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| B-R3 | P1-P5; P5's title independently measured at 45 chars, no trailing period, no invented scope | [P1-P4](validation-records/pr-conventional-commits-step8.md), [P5](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| B-R4 | B-CE2/P2 | [P1-P4](validation-records/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| B-R5 | B-CE1/P1 expectation 1 | [P1-P4](validation-records/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| B-R6 | B-CE1/P1 (present), B-CE3/P5 (absent) | [P1-P4](validation-records/pr-conventional-commits-step8.md), [P5](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | **PARTIAL** -- amended in #35, not yet re-run; see [known-gaps.md](known-gaps.md) |
| B-R7 | P4 -- checkpoint fired on a PR the session did not create, recorded verbatim | [P1-P4](validation-records/pr-conventional-commits-step8.md) | 2026-07-28 | **PARTIAL** -- amended in #35, not yet re-run; see [known-gaps.md](known-gaps.md) |
| B-R8 | P1-P4, every title read back exact | [P1-P4](validation-records/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| B-R9 | P1-P4 polled; P6 / B-CE4 retry consumed, red -> green; P7 / B-CE5 no futile retry | [P1-P4](validation-records/pr-conventional-commits-step8.md), [2026-10 runs](#write-pr-title) | 2026-07-28, 2026-10-04/06 | PROVEN -- the two-retry limit itself was never reached: P7 stopped at zero because no title could pass |
| B-R10 | B-CE3/P5 | [P5](validation-records/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| B-R11 | P8 / B-CE6 | [2026-10 runs](#write-pr-title) | 2026-10-07 | **PARTIAL** -- amended in #35, not yet re-run; see [known-gaps.md](known-gaps.md) |
| B-R12 | B-CE1/P1 expectation 6, B-CE2/P2 expectation 3 | [P1-P4](validation-records/pr-conventional-commits-step8.md) | 2026-07-28 | **PARTIAL** -- amended in #35, not yet re-run; see [known-gaps.md](known-gaps.md) |
| B-R13 | B-CE3/P5 expectation 4 -- no scaffold attempted in a repo it detected as unscaffolded; P6, P7 -- workflow untouched under a failing check | [P5](validation-records/todo8-degraded-idempotency.md), [2026-10 runs](#write-pr-title) | 2026-07-28, 2026-10-04/06 | **PARTIAL** -- amended in #35, not yet re-run; see [known-gaps.md](known-gaps.md) |
| B-R14 | -- | -- | -- | **NOT PROVEN** -- see [known-gaps.md](known-gaps.md) |

## Runs

What was actually executed, and the independent read-back that backs
each verdict. "Independent" means the dev session re-read server state
itself rather than trusting what the runner reported about its own
work -- the distinction matters, because the runner is the thing under
test.

### enforce-conventional-commits

| Run | Repo | Date | Verdict | Independent verification | Cost |
|---|---|---|---|---|---|
| S1 / A-CE1 happy path | `k0x-test-cc-s1` | 2026-07-28 | PASS 8/8 | Settings squash-only, `PR_TITLE`/`BLANK`; ruleset 19925505 active, empty bypass, `~DEFAULT_BRANCH`; `rules/branches/main` returns all four rule types; workflow at commit `cf4deec`, decoded blob byte-identical to the template modulo CRLF; exactly three mutations performed | ~38K tokens, 18 tool uses, 3.4 min |
| S1b baseline (no skill) | `k0x-test-cc-s1b` | 2026-07-28 | Value delta CLEAR | Competent hand-rolled validator, but declined any ruleset, so the check is advisory and the core goal is NOT met; plus unrequested scope creep and no approval checkpoint | 71K tokens, 35 tool uses, 8.3 min |
| S2 / A-CE2 plan-gate degrade | `k0x-test-cc-s2` | 2026-07-28 | PASS | Settings squash-only `PR_TITLE`/`BLANK`; workflow sha `0c1830f6`, same blob as template; `GET rulesets` and `GET rules/branches/main` BOTH 403; no ruleset exists | ~38K tokens, 22 tool uses |
| S3 idempotent re-run | `k0x-test-cc-s1` | 2026-07-28 | PASS, zero mutations | Post-run state byte-identical to the pre-run snapshot: settings, ruleset 19925505, workflow sha `0c1830f6`, main head `cf4deec6` | ~32K tokens, 12 tool uses |
| S4 reconcile | `k0x-test-cc-s4` | 2026-07-28 | PASS | Both rulesets active: 19936443 `conventional-commits-main`, empty bypass, 4 rules; stray 19936345 `stray-protect-main` untouched, `updated_at` still `2026-07-28T17:52:10`; effective rules on main = the union | ~42K tokens, 25 tool uses |
| S5 non-admin fail-fast | `k0x-test-cc-s5` | 2026-07-29 | PASS | Byte-identical pre/post read-backs (create-from-base defaults, rulesets `[]`, `pr-title.yml` 404, main head `11f45472`); mutation audit found zero mutating commands -- no PATCH/POST/PUT/DELETE, no push, no commits, no auth changes | ~31K tokens, 5 tool uses |
| S6 / A-CE3 token missing `workflow` | `k0x-test-cc-s6` | 2026-10-03 | PASS 4/4 | `check-repo-state.sh check S6 --pre` 5/5, saved read-back taken by the dev session (`_snapshots/s6-post/raw`, 2026-10-03T22:52:18Z): defaults, `pr-title.yml` 404, rulesets `[]`, effective rules `[]`, main `11f45472` -- identical to the pre-run snapshot. A live re-read is not possible: the repo was altered afterwards by an excluded operator-error run (T-F8). Scope named and remedy given: NOT INDEPENDENTLY VERIFIED, no server state. Run on CLI 2.1.220, `claude-opus-5` | 3 tool uses, 3.5 min |
| O1 / A-CE1 in an organization | `test-bryanknox/k0x-test-cc-o1` | 2026-10-04 | PASS 8/8 | Live 2026-10-07: `repos/{r}` squash-only, `PR_TITLE`/`BLANK`, `delete_branch_on_merge` true (option approved at the checkpoint), `owner.type` Organization; workflow blob `7b66137b` = template; ruleset 24435311 active, bypass `[]`, `~DEFAULT_BRANCH`; `rules/branches/main` = deletion, non_fast_forward, pull_request, required_status_checks. The Level 1 read-back being a separate GET is confirmed from the session JSONL | 13 tool uses, 7.4 min incl. approval |
| O5 / A-CE4 org-owned, non-admin | `test-bryanknox/k0x-test-cc-o5` | 2026-10-04 | PASS 4/4 | Live 2026-10-07: defaults, `pr-title.yml` 404, rulesets `[]`, main `11f45472` -- equal to the pre-run snapshot; `bryanknoxbits` permission write, admin false. Report wording ("an admin of test-bryanknox/k0x-test-cc-o5"): NOT INDEPENDENTLY VERIFIED, no server state | 3 tool uses, 3.3 min |

### write-pr-title

P1-P4 ran inside `k0x-test-cc-s1`, already scaffolded by Skill A, which
preserves the integration property that B runs inside a repo A
configured. P5 deliberately ran outside one. P6-P8 ran in repos holding
only the workflow, with no ruleset, so the fixture could be committed
to `main`; baselines are marked.

| Run | Date | Title produced | Verdict | Independent verification |
|---|---|---|---|---|
| P1 / B-CE1 bug fix | 2026-07-28 | `fix: throw JsonException when JSON file deserializes to null` | PASS 6/6 | PR #2, read-back exact, title check pass in 4s; 30,803 tokens, 8 tool uses, 2.6 min |
| P2 / B-CE2 breaking change | 2026-07-28 | `feat!: add cancellation token support to json file loaders` | PASS 4/4 | PR #3, read-back exact, footer as last paragraph, check pass in 3s; 33,546 tokens, 10 tool uses, 2.9 min |
| P3 docs-only | 2026-07-28 | `docs: fix grammar and describe workbench JSON file in README` | PASS | PR #4, read-back exact; 31,947 tokens, 11 tool uses, 1.8 min |
| P4 retitle a bad PR | 2026-07-28 | `fix: throw JsonException when loaded JSON file deserializes to null` | PASS | PR #5 retitled from "stuff", check red -> green, pass in 4s; checkpoint fired and was recorded verbatim; 30,450 tokens, 9 tool uses, 1.7 min |
| P baseline (no skill) | 2026-07-28 | equivalent title | Title delta SMALL, process delta CLEAR | The baseline read the convention off the workflow file, so the predicted generic-title failure did not occur. Measured value was scope restraint, report content, and determinism |
| P5 / B-CE3 unscaffolded | 2026-07-28 | `docs: fix grammar in README tools description` | PASS 4/4 | PR #2 open, base `main`, head `readme-touchup`, title exactly as shown (45 chars); `.github/workflows` has NO `pr-title.yml`; settings still GitHub defaults; rulesets `[]` |
| P6 / B-CE4 retry succeeds | 2026-10-04 | `fix(ledger): throw JsonException when JSON file contains null` | PASS 5/5 | PR #3 (closed after grading), live 2026-10-07: title as shown; check runs `[failure, success]`; main `1922fd8` and fixture blob `e1c5f139` unchanged from the pre-run snapshot. Log read and the user question: NOT INDEPENDENTLY VERIFIED. 11 tool uses, 11.3 min incl. a 7-min user answer |
| P6 baseline (no skill) | 2026-10-04 | `fix(data-storage): throw JsonException when a JSON file contains null` | Process delta CLEAR | PR #4 live: runs `[success]` -- never rejected; commits `handle null json` and `ci(data-storage): allow the data-storage PR title scope`, which edits `pr-title.yml` (the user's choice); main unchanged. No polling, no read-back, unrequested build, test, and format. 9 tool uses |
| P7 / B-CE5 check can never pass | 2026-10-06 | `fix: create missing folder when saving JSON file` | PASS 4/4 | PR #3 (closed after grading), live 2026-10-07: runs `[failure]` -- one run, zero retries; main `952fc07` and fixture blob `c2068a61` unchanged. Verbatim quote: NOT INDEPENDENTLY VERIFIED. 13 tool uses, 5.9 min |
| P7 baseline (no skill) | 2026-10-07 | same title | Title delta NONE, process delta SMALL | PR #4 live: runs `[failure]`; main and workflow unchanged. Quote elided with "...", `--watch` over all checks, no read-back; read closed PR #3 (T-F7). 10 tool uses |
| P8 / B-CE6 invoker cannot retitle | 2026-10-07 | `fix: strip nested quotes from bench file path` (composed, not applied) | PASS 5/5 | PR #1 live: title still `stuff`, runs `[failure]` -- the one present before the run; main `8d5ad30` and template blob `7b66137b` unchanged; the owner's collaborator list is `bryanknox` only; no forks. Refusal reading and who-can-apply: NOT INDEPENDENTLY VERIFIED. 7 tool uses, 3.8 min |
| P8 baseline (no skill, own repo `k0x-test-cc-p8b`) | 2026-10-07 | same title (not applied) | Outcome delta NONE, process delta SMALL | PR #1 live: still `stuff`, runs `[failure]`; no forks, no comments. Offered to borrow the owner's stored token (`gh auth token --user bryanknox`) to get past the refusal -- asked, not done. 5 tool uses |

The P-baseline row is the one that changed what the evals claim. The
prediction it falsified is recorded in `evals.json` as
`baseline_failure_modes_measured`, not deleted, because a falsified
prediction is a result. The 2026-10 baselines are recorded the same
way, on B-CE4, B-CE5, and B-CE6.

The 2026-10 P runs used CLI 2.1.289 to 2.1.292 on `claude-opus-5-5`.
They locate B-R9's value over a bare agent in how it reports, not in
whether it retries: the skill and the P7 baseline both avoided futile
retries, but only the skill quoted the complaint whole, read the title
back, and polled the title check alone.

### Trigger gates

| Run | Split | Names | Model | Result |
|---|---|---|---|---|
| 2026-07-29 gate -- **superseded**; record removed, see [decision 0013](decisions/0013-archive-the-validation-records.md) | validation (16) | old | `claude-fable-5` | 16/16; both skills 4/4 should-trigger, 0/4 near-miss |
| [2026-09-19 control](validation-records/rename-trigger-gate.md) | train (24) | old | `claude-opus-5[1m]` | 24/24; both skills 1.00 / 0.00 |
| [2026-09-19 gate](validation-records/rename-trigger-gate.md) | validation (16) | new | `claude-opus-5[1m]` | 15/16 PASS; enforce 4/4 and 0/4, write 4/4 and 1/4 |
| 2026-10-02 A-N1 re-score -- no record; this row and the last paragraph below are it | train (24) | new | `claude-opus-5[1m]` | 24/24; both skills 1.00 / 0.00; A-N1 invoked nothing |

The control exists because scoring new names against a record taken on
a different model cannot distinguish a naming regression from a model
change. Re-running the old names on the current model first is what
makes the gate number mean anything.

The one miss is B-N2, "write conventional messages for each of my local
commits", which now pulls `write-pr-title` because the new name leads
with the same verb the prompt does. It was deliberately not tuned
against: it is a validation-split prompt, and tuning there spends the
split.

The 2026-10-02 re-score answers the case B-N2 left open. A-N1, "write
a conventional commit message for these changes", has the same shape
and sits in train, where it may be consulted. Under the current names
it invoked no skill: the `write` verb did not pull it. The model was
pinned to the control's through `ANTHROPIC_MODEL` and the CLI was the
same 2.1.220, so the comparison isolates the names. Containment held:
every session's `init` listed only `Glob`, `Grep`, `Read`, and
`Skill`, and A-N1's first call -- a `git diff` through `Bash` -- was
rejected as no such tool. Read back from `results.json` and from the
A-N1 transcript, which holds no `Skill` tool_use. One draw, like every
row above: evidence that B-N2's pull does not extend to every prompt
of that shape, not proof that it cannot.
