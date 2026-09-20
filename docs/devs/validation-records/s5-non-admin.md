# Step 8 validation record: S5 non-admin invoker (Skill A)

> **Archived record.** Frozen evidence from 2026-07-29, not
> instructions and not a to-do list. Skill names and paths are
> pre-rename -- see [README.md](README.md) for the translation.
> For what is currently true, read
> [evidence.md](../evidence.md) and
> [known-gaps.md](../known-gaps.md).

Status: COMPLETE (2026-07-29). One real run of
setup-conventional-commits as a non-admin push collaborator
(`bryanknoxbits`) on `bryanknox/k0x-test-cc-s5`: PASS -- the skill
failed fast at Step 1 preflight, BEFORE any mutation, and its
report named the missing permission (admin) and who can run the
skill (the repo owner, `bryanknox`). Zero mutations independently
verified by byte-identical pre/post read-backs. Raw trace:
`traces/s5-with-skill-trace.md`.

This closes the last unexecuted Skill A scenario (S1-S4 covered by
plan todos #6 and #8).

## Procedure notes (human admin participation)

Per the DECIDED 2026-07-29 approach in `dev/test-repos.md`: the
second gh account on this machine (`bryanknoxbits`, keyring,
scopes `repo`+`workflow`) served as the non-admin invoker, so
missing admin access was the ONLY failing variable.

- Repo create + collaborator invite were run BY THE OPERATOR in
  their own terminal (the dev session's permission classifier
  blocked `gh repo create`, which is a documented human checkpoint
  regardless). Operator signaled completion in-conversation
  ("set 1 done").
- The dev session performed the account switches
  (`gh auth switch`) and the invite acceptance, bracketed by an
  operator-approved switch window; active account confirmed
  restored to `bryanknox` afterward.
- Skill run executed by an unattended runner subagent in the test
  clone under a no-mutation delegation (record-and-stop if the
  skill proposed any mutation; it never did).

## Result

| Scenario | Repo | Outcome | Independent verification |
|---|---|---|---|
| S5 non-admin invoker | k0x-test-cc-s5 | PASS: fail-fast at Step 1 on `permissions.admin: false`; Steps 2-8 never entered; no checklist, no checkpoint, zero mutating commands; report states nothing changed, names admin permission as missing and owner `bryanknox` as who can run it, gives re-run remedy | post-run state byte-identical to pre-run snapshot (create-from-base defaults: all three merge methods, COMMIT_OR_PR_TITLE/COMMIT_MESSAGES, rulesets [], pr-title.yml 404, main head 11f45472) |

Assertion mapping (test-repos.md S5): fails BEFORE any mutation --
PASS; names the missing permission -- PASS (`admin`, with the
observed `permissions.admin: false` values); names who CAN run the
skill -- PASS (owner `bryanknox`, exercised meaningfully because
the invoker was a distinct collaborator account rather than a
scoped-down owner token).

## KNOWN GAP (recorded per test-repos.md)

The missing-`workflow`-scope fail-fast branch remains UNTESTED.
Both machine accounts hold `repo`+`workflow`, and
`gh auth refresh` can only ADD scopes; only a purpose-made classic
PAT (`repo` without `workflow`) could exercise that branch. Per
the documented decision, the gap is recorded here instead of
minting one. The scope-check code path is adjacent to the tested
admin check (same Step 1 fail-fast block) and its report content
is prescribed by the same instruction.

## Fixes applied from run friction (Skill A, 2026-07-29)

Continuing the F-numbering (F1-F4 todo #6, F5-F10 todo #8):

- F11: Step 1 now says to evaluate each fail-fast condition as
  soon as it becomes knowable (scopes from `gh auth status`, admin
  from the repo read) and stop at the first hit -- the remaining
  preflight reads are unnecessary. (Runner had to guess; it chose
  correctly.)
- F12: the fail-fast path now has prescribed report content: state
  setup was aborted at preflight with NOTHING changed, name the
  failed condition and who can run the skill, give the remedy.
  (Previously only the success/partial path had a Step 8
  template.)
- F13: "name them if known" made concrete: personal-account repo
  -> the owner from the repo slug / `owner.login`; org-owned repo
  -> "an admin of {org}/{repo}" (a non-admin token cannot list
  admins).
- Not fixed (cosmetic, recorded only): the ordering note that the
  scope condition derives from read 1's output is now implied by
  F11's wording; no further change.

Post-fix lint: ASCII-only PASS; SKILL.md grew 336 -> 346 lines.

## Environment facts (2026-07-29)

- `bryanknox` active before and after; its token currently ALSO
  carries `delete_repo` (left granted after the s1b/s2/s4/p5
  deletions; drop per the delete procedure when convenient).
- `bryanknoxbits` scopes: `gist, read:org, repo, workflow`.
- Pre-campaign leftovers: only `k0x-test-cc-s1` (kept for todo #9
  per todo #8's recommendation).
- Runner cost: ~31K subagent tokens / 5 tool uses; plus
  dev-session orchestration.

## Disposition and follow-ups

Removed 2026-09-19: test-repo lifecycle and plan-todo sequencing, all
long since resolved. See
[decision 0013](../decisions/0013-archive-the-validation-records.md).
The original is still in git:

    git show 671d6bd:docs/devs/validation/s5-non-admin.md
