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

The scenario ids (S1-S5, P1-P5) are defined in
[test-repos.md](test-repos.md); the content eval ids (A-CE1/2,
B-CE1/2/3) in `tests/evals/<skill>/evals.json`.

## Coverage

| Requirement | Exercised by | Record | Date | Verdict |
|---|---|---|---|---|
| INV1 | A-CE1/S1, B-CE1/P1, and every run | [S1](validation/setup-conventional-commits-step8.md), [P1](validation/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| INV2 | A-CE1/S1 expectation 7, B-CE1/P1 expectation 4 | [S1](validation/setup-conventional-commits-step8.md), [P1](validation/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| INV3 | S5 (fails before mutating), S2 (degrades after) | [S5](validation/s5-non-admin.md), [S2](validation/todo8-degraded-idempotency.md) | 2026-07-28/29 | PROVEN |
| INV4 | A-CE1/S1 expectation 2 | [S1](validation/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| INV5 | S2, P5 | [todo #8](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R1 | S5 | [S5](validation/s5-non-admin.md) | 2026-07-29 | PROVEN |
| A-R2 | -- | -- | -- | **NOT PROVEN** -- see [known-gaps.md](known-gaps.md) |
| A-R3 | A-CE1/S1, A-CE2/S2, S4 | [S1](validation/setup-conventional-commits-step8.md), [todo #8](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R4 | A-CE1/S1, A-CE2/S2, S4 | [S1](validation/setup-conventional-commits-step8.md), [todo #8](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R5 | A-CE1/S1, S4 | [S1](validation/setup-conventional-commits-step8.md), [todo #8](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R6 | S1 mutation summary: exactly three mutations, nothing local | [S1](validation/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| A-R7 | A-CE1/S1 expectation 4 | [S1](validation/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| A-R8 | A-CE1/S1 expectation 2 | [S1](validation/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| A-R9 | S3 | [todo #8](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R10 | S4 | [todo #8](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R11 | A-CE2/S2 | [todo #8](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| A-R12 | A-CE1/S1 expectation 8 | [S1](validation/setup-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| A-R13 | -- | -- | -- | **NOT PROVEN** -- see [known-gaps.md](known-gaps.md) |
| A-R14 | Dispatch only (trigger case A-N9) | [rename gate](validation/rename-trigger-gate.md) | 2026-09-19 | **PARTIAL** -- see [known-gaps.md](known-gaps.md) |
| B-R1 | P1-P5 | [P1-P4](validation/pr-conventional-commits-step8.md), [P5](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| B-R2 | P1-P5; classification came from the diff in every run, with deliberately vague commit messages as decoys | [P1-P4](validation/pr-conventional-commits-step8.md), [P5](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| B-R3 | P1-P5; P5's title independently measured at 45 chars, no trailing period, no invented scope | [P1-P4](validation/pr-conventional-commits-step8.md), [P5](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| B-R4 | B-CE2/P2 | [P1-P4](validation/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| B-R5 | B-CE1/P1 expectation 1 | [P1-P4](validation/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| B-R6 | B-CE1/P1 (present), B-CE3/P5 (absent) | [P1-P4](validation/pr-conventional-commits-step8.md), [P5](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| B-R7 | P4 -- checkpoint fired on a PR the session did not create, recorded verbatim | [P1-P4](validation/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| B-R8 | P1-P4, every title read back exact | [P1-P4](validation/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| B-R9 | P1-P4 polled; P4 exercised red -> green | [P1-P4](validation/pr-conventional-commits-step8.md) | 2026-07-28 | **PARTIAL** -- the retry loop was never consumed; see [known-gaps.md](known-gaps.md) |
| B-R10 | B-CE3/P5 | [P5](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
| B-R11 | -- | -- | -- | **NOT PROVEN** -- see [known-gaps.md](known-gaps.md) |
| B-R12 | B-CE1/P1 expectation 6, B-CE2/P2 expectation 3 | [P1-P4](validation/pr-conventional-commits-step8.md) | 2026-07-28 | PROVEN |
| B-R13 | B-CE3/P5 expectation 4 -- no scaffold attempted in a repo it detected as unscaffolded | [P5](validation/todo8-degraded-idempotency.md) | 2026-07-28 | PROVEN |
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

### write-pr-title

P1-P4 ran inside `k0x-test-cc-s1`, already scaffolded by Skill A, which
preserves the integration property that B runs inside a repo A
configured. P5 deliberately ran outside one.

| Run | Date | Title produced | Verdict | Independent verification |
|---|---|---|---|---|
| P1 / B-CE1 bug fix | 2026-07-28 | `fix: throw JsonException when JSON file deserializes to null` | PASS 6/6 | PR #2, read-back exact, title check pass in 4s; 30,803 tokens, 8 tool uses, 2.6 min |
| P2 / B-CE2 breaking change | 2026-07-28 | `feat!: add cancellation token support to json file loaders` | PASS 4/4 | PR #3, read-back exact, footer as last paragraph, check pass in 3s; 33,546 tokens, 10 tool uses, 2.9 min |
| P3 docs-only | 2026-07-28 | `docs: fix grammar and describe workbench JSON file in README` | PASS | PR #4, read-back exact; 31,947 tokens, 11 tool uses, 1.8 min |
| P4 retitle a bad PR | 2026-07-28 | `fix: throw JsonException when loaded JSON file deserializes to null` | PASS | PR #5 retitled from "stuff", check red -> green, pass in 4s; checkpoint fired and was recorded verbatim; 30,450 tokens, 9 tool uses, 1.7 min |
| P baseline (no skill) | 2026-07-28 | equivalent title | Title delta SMALL, process delta CLEAR | The baseline read the convention off the workflow file, so the predicted generic-title failure did not occur. Measured value was scope restraint, report content, and determinism |
| P5 / B-CE3 unscaffolded | 2026-07-28 | `docs: fix grammar in README tools description` | PASS 4/4 | PR #2 open, base `main`, head `readme-touchup`, title exactly as shown (45 chars); `.github/workflows` has NO `pr-title.yml`; settings still GitHub defaults; rulesets `[]` |

The P-baseline row is the one that changed what the evals claim. The
prediction it falsified is recorded in `evals.json` as
`baseline_failure_modes_measured`, not deleted, because a falsified
prediction is a result.

### Trigger gates

| Run | Split | Names | Model | Result |
|---|---|---|---|---|
| [2026-07-29 gate](validation/trigger-evals.md) -- **superseded** | validation (16) | old | `claude-fable-5` | 16/16; both skills 4/4 should-trigger, 0/4 near-miss |
| [2026-09-19 control](validation/rename-trigger-gate.md) | train (24) | old | `claude-opus-5[1m]` | 24/24; both skills 1.00 / 0.00 |
| [2026-09-19 gate](validation/rename-trigger-gate.md) | validation (16) | new | `claude-opus-5[1m]` | 15/16 PASS; enforce 4/4 and 0/4, write 4/4 and 1/4 |

The control exists because scoring new names against a record taken on
a different model cannot distinguish a naming regression from a model
change. Re-running the old names on the current model first is what
makes the gate number mean anything.

The one miss is B-N2, "write conventional messages for each of my local
commits", which now pulls `write-pr-title` because the new name leads
with the same verb the prompt does. It was deliberately not tuned
against: it is a validation-split prompt, and tuning there spends the
split.
