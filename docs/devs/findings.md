# Findings register

**What this is for:** everything a real run found, what it changed, and
whether it is settled.

**Read it** before re-investigating something that looks broken -- it
may already be a known, fixed, or deliberately-unfixed finding.

**Write to it** at the end of every tier-2 campaign, appending to the
existing numbering.

Each row compresses a campaign finding to a sentence. When that is not
enough -- most often when an instruction in a `SKILL.md` looks like
ceremony and the row does not make the case for it -- the dated record
behind the finding is in [validation-records/](validation-records/),
whose README maps finding ids back to records and says when opening
one is worth it.

Findings are numbered per skill and the numbering continues across
campaigns. The records use bare `F1`, `F2`, ...; this register prefixes
them `A-F*` and `B-F*` because both skills have an `F1`. The
`Requirement` column names what in
[behavior-spec.md](behavior-spec.md) the finding bears on, where it
bears on one.

Types: **defect** (the skill was wrong), **friction** (it worked but
the runner had to guess), **ceremony** (it did something correct and
unnecessary), **gap** (behavior was unstated), **thrift** (cost or
robustness).

## enforce-conventional-commits

| Id | Type | Date | Requirement | What it found | What changed | Status |
|---|---|---|---|---|---|---|
| A-F1 | defect | 2026-07-28 | A-R11 | Plan detection could never work as written. `gh api user` with gh's default scopes returns no `plan` key at all -- GitHub includes it only with the `user` scope -- so `--jq .plan.name` yields empty on a normal install and the free-plan gap could never be detected proactively. | Preflight reads empty as UNKNOWN, not `free`; the plan read became best-effort; the Level 3 read-back named as the definitive detector; eval A-CE2 expectation 1 updated. | FIXED |
| A-F2 | friction | 2026-07-28 | -- | Step 3's checklist location was ambiguous ("session's working area"); the runner had to decide not to drop it in the repo. | Body now says a scratch area OUTSIDE the repo working tree. | FIXED |
| A-F3 | friction | 2026-07-28 | -- | `gh api` exits nonzero on EXPECTED preflight outcomes (404 for an absent workflow, an empty `--jq` plan read), breaking `&&` chains and `set -e`. | Body now says to run preflight reads as independent commands. | FIXED |
| A-F4 | friction | 2026-07-28 | -- | The Step 7 `<<'JSON'` heredoc is POSIX-only; on the Windows host it required the Bash tool. | Body names the POSIX-shell requirement and the `--input <temp file>` alternative. | FIXED |
| A-F5 | defect | 2026-07-28 | A-R11 | **Overturned the documented prediction.** Free-plan private personal repos block ruleset creation outright: list, create, AND effective-rules all return HTTP 403 "Upgrade to GitHub Pro or make this repository public". There is no create-then-unenforced state, which is what the plan had guessed from the docs. | Step 1 documents the 403 as the definitive plan-gate detector; Step 4's checkpoint bullet changed from "created but inactive" to "blocked: cannot be created"; Step 7 skips the POST when the gate is confirmed; Step 8 gained a third Level-2 state; eval A-CE2 expectations 3-4 rewritten (the old ones were unachievable); `test-repos.md` S2 and the checkpoint list corrected. | FIXED |
| A-F6 | defect | 2026-07-28 | A-R9, A-R10 | Step 2 compared server-populated ruleset defaults as if they were conflicts. | Compare only skill-specified fields; a level can be `conflict` AND `apply` at once. | FIXED |
| A-F7 | defect | 2026-07-28 | A-R3 | Target state for Level 1 omitted `squash_merge_commit_message=BLANK`; it appeared only in Step 5. | Added to the Level 1 target state. | FIXED |
| A-F8 | friction | 2026-07-28 | A-R9 | The no-op path did not say what to report. | The no-op diff doubles as the final report; optional read-only action-version check noted. | FIXED |
| A-F9 | defect | 2026-07-28 | -- | Live collision: a stale checklist from a concurrent S2 run was picked up by the S4 run. | Checklist filename is now repo-scoped, `cc-setup-checklist-{repo}.md`. | FIXED |
| A-F10 | gap | 2026-07-28 | A-R10 | Behavior against a pre-existing stray ruleset was unstated. | Explicit COEXIST default: union semantics, the old bypass applies only to its own rules, delete or modify requires explicit approval. | FIXED |
| A-F11 | friction | 2026-07-29 | A-R1, A-R2 | Step 1 did not say when to evaluate each fail-fast condition; the runner had to guess (it guessed correctly). | Evaluate each condition as soon as it becomes knowable -- scopes from `gh auth status`, admin from the repo read -- and stop at the first hit. | FIXED |
| A-F12 | gap | 2026-07-29 | A-R1 | The fail-fast path had no prescribed report content; only the success and partial paths had a Step 8 template. | Prescribed: state that setup aborted at preflight with NOTHING changed, name the failed condition and who can run the skill, give the remedy. | FIXED |
| A-F13 | gap | 2026-07-29 | A-R1 | "Name them if known" was too vague to act on. | Made concrete: personal-account repo -> the owner from the repo slug or `owner.login`; org-owned repo -> "an admin of {org}/{repo}", since a non-admin token cannot list admins. | FIXED |
| A-F14 | friction | 2026-10-03 | A-R2 | S6: the only remedy SKILL.md gives, `gh auth refresh -h github.com -s repo,workflow`, cannot change a token supplied through `GH_TOKEN`. The runner said so and gave "unset `GH_TOKEN`, or regenerate the PAT with both scopes" instead -- correct, but reasoned past the text. This falsified the predicted wrong remedy. | Step 1 gives the remedy for the credential `gh auth status` reports: `gh auth refresh` for a keyring login, a token with both scopes or an unset variable for `GH_TOKEN`/`GITHUB_TOKEN`. A-R2 and `docs/users/install.md` say the same. | FIXED |
| A-F15 | defect | 2026-10-03 | INV1 | S6: the fail-fast report asserted "this repo is private, so Level 3 ... may hit the GitHub Pro plan gate" with no repo read -- it stopped before that read. The repo is public. O5 did the opposite and said which reads it had not made. | The fail-fast report now states only what was read: a fact the stopped preflight never reached is unknown, not inferred. | FIXED |

Observed, no action: the ruleset POST response carries server-populated
fields beyond the request (`pull_request.allowed_merge_methods`,
`do_not_enforce_on_create`), which is harmless because verification uses
the effective-rules endpoint rather than a JSON diff. And O1's report
advised committing the untracked `.claude/skills/` folder through a
pull request; that folder is the repo-scoped install of the skill under
test, so the advice is an artifact of the test install method.

## write-pr-title

| Id | Type | Date | Requirement | What it found | What changed | Status |
|---|---|---|---|---|---|---|
| B-F1 | defect | 2026-07-28 | B-R12 | Found by lint before any run. Step 4 branches on the repo's squash MESSAGE setting and eval B-CE2 asserts on it, but Step 2 fetched only `squash_merge_commit_title` -- the skill never read `squash_merge_commit_message`. | Field added to the Step 2 read. Fixed before the real runs, so P1-P4 exercised the corrected body. | FIXED |
| B-F2 | friction | 2026-07-28 | B-R9 | Step 7 was silent about unrelated checks. Every runner inferred title-check-only scope but flagged the ambiguity, and P3 used `gh pr checks --watch`, which waits on ALL checks -- it only worked because the title check finished first. | The title check is the only gate; ignore other checks; avoid `--watch` and re-poll the plain command. | FIXED |
| B-F3 | friction | 2026-07-28 | -- | The Step 8 report template had no PR URL slot; runners appended one ad hoc. | `PR: {url}` line added. | FIXED |
| B-F4 | ceremony | 2026-07-28 | B-R7 | The Step 5 checkpoint fired even though the user had explicitly asked to retitle that exact PR -- the request already was the approval. | Explicit retitle-this-PR requests skip the checkpoint; the report shows old -> new instead. | FIXED |
| B-F5 | gap | 2026-07-28 | B-R4 | Edit-path body handling was unstated (the runner had to decide to replace the placeholder body "wip"), and footer-vs-trailer ordering was unspecified (the P2 runner reasoned it out correctly). | Step 4 now says to refresh the body on edits, keep meaningful content, and keep the `BREAKING CHANGE:` footer as the LAST paragraph with trailers above it. | FIXED |
| B-F6 | thrift | 2026-07-28 | B-R6 | Scaffold detection returned the whole base64 file payload, and assumed the exact filename `pr-title.yml`. | `--jq .name` added; on 404, fall back to listing `.github/workflows` for any PR-title-linting workflow. | FIXED |
| B-F7 | gap | 2026-07-28 | B-R12 | `COMMIT_OR_PR_TITLE` was unexplained: the PR title is used only for multi-commit PRs, while single-commit PRs squash with the commit's own message. | Step 2 explains it. Report it, never change it. | FIXED |
| B-F8 | defect | 2026-07-28 | -- | The `gh pr create` snippet did not name a base branch. | `--base {default_branch}` added. | FIXED |
| B-F9 | gap | 2026-10-04 | B-R7, B-R9 | P6: the check's complaint could only be met by a scope that misdescribes the change (`ledger`), so complying collides with B-R1's "omit rather than invent". The run asked the user before retrying a PR it had created -- outside Step 7, and outside B-R7's one checkpoint case. Defensible under INV5; SKILL.md is silent on a complaint that conflicts with the title rules. | Steps 4 and 5 define a CONFLICT -- every title the check accepts breaks the title rules -- and make it the second checkpoint case, asked before the PR is created or retitled; Step 7 routes a complaint that only a rule-breaking title satisfies to the same checkpoint. B-R7 amended; eval B-CE4 and scenario P6 rewritten to test it. | FIXED |
| B-F10 | gap | 2026-10-04 | B-R13 | P6: one option at that question was "Fix the workflow too" -- add a scope to `pr-title.yml` in a separate change. Not chosen, so whether the skill would have acted is unknown. P7 declined the same move unprompted ("repo setup, outside this task"). | Steps 5 and 7 say never to change, or offer to change, the workflow or its allowed values, and to say what an admin could change. B-R13 amended. | FIXED |
| B-F11 | gap | 2026-10-04 | B-R6 | Step 2 reads only the workflow's existence (`--jq .name`), not its configuration (`types`, `scopes`, `requireScope`, `subjectPattern`). The P6 and P7 baselines read it up front and anticipated the constraint; the skill learned it from a failed run. Reading it would allow a compliant first title or an up-front question -- and would make B-R9 retries rarer still. | Decided: read the rules. Step 2 reads the workflow raw and notes `types`, `requireScope`, `scopes`, and `subjectPattern`; Step 4 composes within them. B-R6 amended. Consequence: P6 no longer reaches B-R9's retry path -- see the P6 note in `test-repos.md`. | FIXED |
| B-F12 | gap | 2026-10-07 | B-R12 | P8: for an account without push access, `gh api repos/{o}/{r}` returns `allow_squash_merge` and both `squash_merge_commit_*` fields as `null`. Step 2 assumes they are readable, and B-R11's audience is exactly that account. The run reported that it could not see them -- correct, but unstated. | Step 2 treats `null` squash fields as unreadable and reports the effect as unknown. B-R12 amended; eval B-CE6 gains the expectation. | FIXED |

Not fixed, cosmetic, recorded only: the Step 8 template has no head or
base fields; `gh pr create` warns about the untracked installed skill
directory (an artifact of the test install method, not shipped
behavior); `git log {default_branch}..HEAD` and `origin/main` were used
interchangeably by runners, harmlessly.

## Tooling and procedure

Findings against the test procedures and the eval harness rather than
against either skill. These matter because two of them made a check or
a measurement report the wrong answer.

| Id | Type | Date | What it found | What changed | Status |
|---|---|---|---|---|---|
| T-F1 | defect | 2026-07-28 | The S4 dirtying procedure was wrong twice over: a fresh create-from-base repo is ALREADY in the conflicting merge-settings state so no PATCH is needed, and the single-field PATCH form 422s with `invalid_squash_commit_setting_combo`. The stray-ruleset example also named a bypass actor type `RepoRole` that does not exist. | `test-repos.md` S4 corrected: PATCH step dropped, actor type corrected to `RepositoryRole`. | FIXED |
| T-F2 | defect | 2026-07-29 | The documented delete procedure dropped the `delete_repo` scope with `gh auth refresh -s repo,workflow`, but `-s` only ADDS scopes. The scope survived the todo #8 deletion session -- observed live. | `test-repos.md` uses `--remove-scopes`, and records that `repo`, `read:org`, and `gist` are gh's un-removable minimum. | FIXED |
| T-F3 | defect | 2026-09-19 | **The trigger-eval harness was under-measuring dispatch.** `--allowedTools` is a permission allowlist; it does not remove other tools from the session, so `Bash` stayed available and one session found the installed `SKILL.md` with `find` and read its frontmatter with `head` -- reading the skill instead of invoking it. Three Skill B prompts were falsely scored as dispatch failures. | `--tools` named as the load-bearing containment flag in `run-trigger-evals.sh` and in `testing.md`; the gate re-run. | FIXED |
| T-F4 | defect | 2026-10-03 | `dev-test-repo-lifecycle` step 5 requires `git ls-files .claude` to print nothing, but k0x-workbench tracks three files under `.claude/` -- an agent, a rule, and the `normalize-bench-file` skill -- so the check fails on every clone. Installs were verified with `git ls-files .claude/skills/{name}` and a `??` status instead. Those base files also load in every test session. | `dev-test-repo-lifecycle` step 5 checks `git ls-files .claude/skills/{name}` plus a `??` status, and says why `ls-files .claude` is never empty; `test-repos.md` "Installing a skill under test" says the same and names the base files that load in every session. | FIXED |
| T-F5 | friction | 2026-10-04 | The base ships `.github/dependabot.yml`, so every public test repo gets Dependabot pull requests that run CI (P6, P7, P8, P8b). The repo-state checker is unaffected -- it reads runs by PR head SHA -- but it is noise and spends Actions minutes. | Documented rather than disabled: `test-repos.md` "Create-from-base procedure" and the lifecycle skill's step 3 say to expect the PRs, never close or count them, and mention them in the stage report. | FIXED |
| T-F6 | defect | 2026-10-07 | P8's checker compares check-run counts against the pre-run snapshot, so a title-check run still in flight at snapshot time would be scored as one added by the skill. The procedure does not say to wait. P8 and P8b were staged by waiting by hand. | `test-repos.md` P8 and the lifecycle skill's P8 setup wait for the first title-check run to complete before the snapshot, with an `until gh pr checks ...` poll. | FIXED |
| T-F7 | defect | 2026-10-07 | Closing the with-skill PR does not isolate a baseline in the same repo: the P7 baseline ran `gh pr list --state all` and read closed PR #3's check history. The P8 baseline ran in its own repo, `k0x-test-cc-p8b`. | A baseline gets its own repository, the scenario's name plus `b`: `test-repos.md` "Naming convention" and "Installing a skill under test", `testing.md` "Tier 2: content evals", and a `stage {scenario} baseline` operation in the lifecycle skill. | FIXED |
| T-F8 | friction | 2026-10-03 | Operator error: the first O1 attempt was launched in the S6 clone and ran Skill A's happy path on `k0x-test-cc-s6` after S6 was graded. It was excluded from evidence. Nothing in the handoff asked for the session's working directory to be checked. | `test-repos.md` "Installing a skill under test" and the lifecycle skill's report both name the clone's full path and say to check the session header shows it before the prompt. | FIXED |
| T-F9 | friction | 2026-10-04 | Terminal scrollback truncates long commands, which hid whether O1's Level 1 read-back was a separate GET. The run session's JSONL under `~/.claude/projects/` holds them untruncated, and grading in the 2026-10 campaign used it. | `testing.md` "Tier 2: content evals" says to grade from the session JSONL under `~/.claude/projects/`, and how to find it. | FIXED |

T-F3 is the dangerous shape of defect for this repository, and the
reason the harness comment exists. A harness that under-measures
dispatch is indistinguishable from a skill whose description stopped
working -- and the documented remedy for the latter is to edit the
description, which would have turned a measurement error into a real
regression.

## What is still open

Nothing in this register is open. What has never been proven at all is
a different question, and it is [known-gaps.md](known-gaps.md).
