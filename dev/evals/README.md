# Evals (maintainer-scope)

Evals for the two conventional-commits skills. This directory is
OUTSIDE the skill folders on purpose: nothing here ships with a
skill (bundle-leakage / dispatch-contamination guard). Source of
truth for what these evals must cover: the EVALS PLAN in
`dev-info/conventional-commits-skills-plan.md` (step 6).

```
evals/setup-conventional-commits/evals.json
evals/pr-conventional-commits/evals.json
```

Each `evals.json` has two sections:

## Content evals (`evals` key)

Format follows the skill-creator `evals.json` schema (id, prompt,
expected_output, expectations), extended with `setup` (the test-repo
scenario required, see `dev/test-repos.md`) and
`baseline_failure_modes` (what the without-skill run is expected to
get wrong).

Run each eval twice in the described setup: once with the skill
installed (repo-scoped in the test repo), once without. Grade the
`expectations` list against the transcript and outputs. If the
with-skill and without-skill runs are indistinguishable, the skill
is not adding value -- that is a finding, not a pass.

These need REAL GitHub test repos (settings, rulesets, and checks
are server-side). Repo lifecycle, reset procedures, and the human
checkpoints (repo creation/deletion, `delete_repo` scope) are
defined in `dev/test-repos.md`.

## Trigger evals (`trigger_evals` key)

~20 prompts per skill: half should-trigger, half near-miss, split
60/40 into `train` and `validation` (stratified). Procedure: present
each prompt to a fresh session with the skill installed and record
whether the dispatcher invokes the skill.

- `train` is for iterating on the skill name/description.
- `validation` is the ship gate (plan todo #9), scored only after
  wording is frozen: should-trigger hit rate >= 0.5 AND near-miss
  trigger rate < 0.5. If the gate fails, adjust the description (or
  the fallback names recorded in the plan, step 5 LOW findings) and
  re-freeze before re-scoring validation.

Near-miss entries carry a `note` when the prompt legitimately
belongs to the sibling skill -- a "miss" that triggers the sibling
is correct dispatch, not a failure of that sibling.
