# Step 8 validation record: todo #8 campaign (S2, S3, S4, P5)

Status: COMPLETE (2026-07-28). Four unattended real runs -- S3
idempotency, S2 private-repo degrade, S4 reconcile (all Skill A),
and P5 unscaffolded repo (Skill B, folded in from todo #7) -- ALL
PASS on independently read-back-verified server state. One major
factual finding (F5) overturned the plan's step 5 finding (b);
fixes F5-F10 applied to Skill A, two fixes to Skill B, eval A-CE2
rewritten, test-repos.md corrected. Raw traces:
`traces/s2-s3-s4-p5-traces.md`.

Repo-creation authorization: the operator's instruction to proceed
with plan todo #8 was taken as approval for the three repo creates
its documented procedure names (`k0x-test-cc-s2`, `-s4`, `-p5`);
each create used the standard create-from-base procedure and the
read-only base was never written to.

## Results

| Scenario | Repo | Outcome | Independent verification |
|---|---|---|---|
| S3 idempotent re-run | k0x-test-cc-s1 | PASS: all three levels declared no-op at Step 2, run stopped, ZERO mutations | post-run state byte-identical to pre-run snapshot (settings, ruleset 19925505, workflow sha 0c1830f6, main head cf4deec6) |
| S2 private free-plan degrade | k0x-test-cc-s2 | PASS (degrade path): L1+L3 applied+verified; gap surfaced at checkpoint BEFORE mutation; L2 create refused HTTP 403; no crash; report names gap+remedy | settings squash-only PR_TITLE/BLANK; workflow blob = template; rulesets + effective-rules endpoints both 403; no ruleset exists |
| S4 reconcile | k0x-test-cc-s4 | PASS: checkpoint showed correct per-field reconcile diff, surfaced stray ruleset by name/rules/bypass with explicit coexist-vs-overwrite options; coexist chosen; 3 levels applied+verified | both rulesets active; stray 19936345 untouched (updated_at unchanged); effective rules = union; settings + workflow at target |
| P5 unscaffolded (Skill B) | k0x-test-cc-p5 | PASS 4/4 B-CE3: conventional `docs:` title composed from diff (plain commit message ignored as truth source), check polling skipped, gap reported with recommendation to run Skill A, NO scaffold attempted | PR #2 open, exact title, no pr-title.yml, settings at GitHub defaults, rulesets [] |

## Major finding

**F5 (defect, FIXED): free-plan private personal repos BLOCK
ruleset creation outright -- there is no create-then-unenforced
state.** Plan step 5 finding (b) predicted (from docs) that the
create succeeds and enforcement is silently off, with the empty
effective-rules read-back as detector. Observed live: list,
create, AND effective-rules ruleset endpoints all return HTTP 403
"Upgrade to GitHub Pro or make this repository public to enable
this feature." The todo #8 residual (201 vs 403) is resolved:
**403, not created**. Consequences applied:

- SKILL.md Step 1: rulesets-read 403 documented as the DEFINITIVE
  plan-gate detector (better than the scope-limited plan read);
  added to the expected-nonzero-exit list.
- Step 4 checkpoint bullet: "ruleset will be created but inactive"
  -> "Level 2 blocked: cannot be created until upgrade/public".
- Step 7: skip the POST when the gate was confirmed at preflight;
  403-at-POST handled (report, no retry, no abort); read-back text
  updated (endpoint 403s too; empty-result branch retained for
  org-owned/non-active cases).
- Step 8 template: third Level-2 state `blocked by plan (403, not
  created)`.
- Eval A-CE2: expectations 3-4 and expected_output rewritten to
  the 403 reality (the old ones were unachievable).
- test-repos.md S2 + human-checkpoint list: UI-banner eyeball
  removed (no ruleset exists to eyeball); live status recorded.

## Other findings (all FIXED 2026-07-28)

- F6 (Skill A, S3+S4): Step 2 now says compare only
  skill-specified fields (server-populated ruleset defaults are
  not conflicts) and that a level can be `conflict` AND `apply`
  at once.
- F7 (Skill A, S3): Target state Level 1 now includes
  `squash_merge_commit_message=BLANK` (was only in Step 5).
- F8 (Skill A, S3): no-op path clarified -- the no-op diff doubles
  as the final report; optional read-only action-version check
  noted.
- F9 (Skill A, S4): checklist filename now repo-scoped
  (`cc-setup-checklist-{repo}.md`) after a live collision with a
  stale checklist from the concurrent S2 run.
- F10 (Skill A, S4): explicit COEXIST default for pre-existing
  rulesets (union semantics; old bypass applies only to its own
  rules; delete/modify requires explicit approval).
- Skill B F7 (P5): Step 2 now explains `COMMIT_OR_PR_TITLE`
  (PR title used only for multi-commit PRs; single-commit PRs
  squash with the commit's own message) -- report, never change.
- Skill B F8 (P5): `gh pr create` snippet gains
  `--base {default_branch}`.
- Not fixed (cosmetic, recorded only): Skill B Step 8 template has
  no head/base fields; `gh pr create` warns about the untracked
  installed skill dir; S4 runner's own $TMPDIR glitch.
- test-repos.md S4 dirtying: fresh create-from-base repos are
  already in the conflicting merge-settings state; PATCH step
  dropped (and its single-field form 422s --
  `invalid_squash_commit_setting_combo`); stray-ruleset example
  corrected to `RepositoryRole` (not `RepoRole`).

## Environment facts (2026-07-28)

- gh active account was already `bryanknox` (per the standing
  note in test-repos.md); scopes `repo, workflow`; no
  `delete_repo`.
- Pre-campaign leftovers: `k0x-test-cc-s1` (kept for S3, per plan)
  and `k0x-test-cc-s1b` (still awaiting operator deletion).
- Run costs: S3 ~32K tokens/12 uses; S2 ~38K/22; S4 ~42K/25;
  P5 ~30K/12. Campaign total ~142K subagent tokens + dev-session
  orchestration.

## Disposition and follow-ups

- Test repos now existing, ALL awaiting operator deletion decision
  (delete procedure = human checkpoint, `delete_repo` scope):
  `k0x-test-cc-s1` (recommend KEEP until todo #9 trigger evals --
  its clone is a ready scaffolded environment), `k0x-test-cc-s1b`,
  `k0x-test-cc-s2`, `k0x-test-cc-s4`, `k0x-test-cc-p5` (PR #2
  left open by design).
- S5 (non-admin invoker) remains the one unexecuted Skill A
  scenario; it needs human admin participation (second account or
  scoped-down token) and was never part of todo #8.
- Remaining plan todo: #9 trigger-eval validation gate on the
  final descriptions (descriptions unchanged by this campaign).
