# Testing

Testing here splits into two tiers that differ by more than
thoroughness. Tier 1 is free, deterministic, and runs on every
commit. Tier 2 costs money, needs real GitHub repositories and human
participation, and runs when behavior changes.

Confusing the two is the main way this gets expensive or, worse,
skipped.

| | Tier 1 | Tier 2 |
|---|---|---|
| What | Structural lint | Content and trigger evals |
| Cost | Free | Model calls, real repos, your time |
| Determinism | Total | Sampled |
| Runs | Every commit, in CI | When behavior or a description changes |
| Catches | Malformed, non-portable, or self-inconsistent skills | Skills that do the wrong thing, or run at the wrong time |

A green tier 1 says a skill is well-formed. It says nothing about
whether it works.

## Tier 1: the checks CI runs

Four scripts, all exiting non-zero on any violation. Run them
before opening a pull request; `.github/workflows/ci.yml` runs the
same four on every pull request and every push to `main`.

```
bash tests/lint-skills.sh
bash tests/check-links.sh
bash tests/check-workflow-template.sh
bash tests/check-plugin-manifests.sh
```

One prerequisite: `check-workflow-template.sh` needs PyYAML.

```
python -m pip install pyyaml
```

It is a required dependency rather than an optional extra -- the
script says so and stops, rather than skipping the check.

### lint-skills.sh

Every rule is explained in [authoring.md](authoring.md); the script
is the enforcement, that page is the reasoning.

What it checks:

- Frontmatter parses, and contains `name` and `description` --
  **and nothing else.** That last part is the portability guard. A
  `model` or `allowed-tools` key would work in Claude Code and break
  the skill elsewhere, so the lint refuses it.
- `name` matches the directory, is hyphen-case, and is at most 64
  characters.
- The description is within its ceiling.
- Every markdown file in a skill bundle is ASCII, LF, ends with a
  newline, and has no trailing whitespace.
- Prose wraps at 72 columns. Table rows and fenced code blocks are
  exempt, because neither can be wrapped without breaking.
- References into a skill's own bundle resolve. Absolute paths and
  references that escape the folder fail.
- The eval files parse as JSON.

### check-links.sh

Every relative markdown link in `docs/`, the root README, and
`CLAUDE.md` resolves to something that exists. Anchors are not
checked.

This exists because moving files breaks links quietly. During the
repository refactor this check caught broken links three times, each
after a rename.

### check-workflow-template.sh

Targeted invariant checks on
`skills/enforce-conventional-commits/assets/pr-title-workflow.yml` --
the one artifact that lands in other people's repositories and
becomes their enforcement.

It asserts the file parses, and then the five couplings that would
otherwise break silently:

- **The job name is exactly `Validate conventional PR title`.** The
  ruleset the skill creates requires this status check *by name
  string*. Rename the job and enforcement stops working with no
  error anywhere.
- **`edited` is in the trigger types.** Without it, a corrected
  title leaves the old failure sitting there.
- **The action is pinned to `@v6`.**
- **The `with: types:` list is exactly the de-facto ten.** The
  template pins the allowed types rather than inheriting the
  action's defaults; consumers edit their own copy, but what ships
  has to match the list SKILL.md, `write-pr-title`, and
  the user guide all name.
- **`permissions.pull-requests` is `read`.**

These are deliberately not a generic workflow linter. The failure
that matters here is not a YAML error -- it is a rename, which a
general-purpose linter cannot see.

### check-plugin-manifests.sh

Checks `.claude-plugin/plugin.json` and
`.claude-plugin/marketplace.json`: that both parse, that the plugin
has a name, a description, and a semver `version`, that the
marketplace entry for this plugin exists and agrees with
`plugin.json` on that version, that the entry's `source` resolves to
something with a plugin manifest in it, and that `skills/` still
holds at least one `<name>/SKILL.md`.

The version agreement is the one worth naming. An unbumped version
means installed copies stay cached no matter what changed, and a
version that disagrees between the two files is refused by
`claude plugin tag` and silent everywhere else. See
[decision 0010](decisions/0010-declare-a-plugin-version.md).

**This is not a reimplementation of `claude plugin validate`.** That
command is the richer check and is a release step, documented in
[release.md](release.md). It stays out of CI on purpose: it needs
the Claude Code CLI, so a warning added in a future release would
turn this repository red without anyone changing a file here. What
runs in CI is offline and covers the couplings this repository owns.

### The checks are written to fail loudly

A missing tool is an error, not a skip. This is deliberate: an
earlier ad-hoc version of these checks reported a clean pass because
`grep -P` was unavailable in Git Bash, and the check simply never
ran. A lint that can silently do nothing is worse than no lint,
because it is trusted.

The same principle applies to *finding* tools. Three of the scripts
resolve a Python interpreter by running each candidate, not by
checking that the name exists on `PATH`. Windows ships a `python3`
that resolves fine, prints an advert for the Microsoft Store, and
exits 49; probing by name picks that stub and fails on a working
machine.

It applies to a tool's *defaults* too. Both line-ending checks pass
`grep -U`, because Git Bash's grep otherwise treats the file as text
and strips CR before matching. Without it, a SKILL.md that was CRLF
from end to end linted clean -- on the one platform most likely to
produce one. Same shape as the `grep -P` bug: the check ran, found
nothing, and was believed.

If you add a check, make its failure path the loud one, and prove it
by breaking the thing it guards.

### What it does not cover

The lint runs against `skills/` only, since that is the only thing
distributed. Documentation and validation records are not linted --
apart from their links, the two plugin manifests, and the
requirement-id citations that `check-requirement-ids.sh` resolves.

Nothing checks that a requirement in
[behavior-spec.md](behavior-spec.md) is actually *implemented* by the
SKILL.md that claims it. That is what tier 2 is for; tier 1 can only
confirm the citation resolves.

## Tier 2: content evals

The eval files are `tests/evals/<skill>/evals.json`. Each has an
`evals` key (content) and a `trigger_evals` key (dispatch), in a
schema borrowed from skill-creator, extended with `setup` naming the
required scenario and `baseline_failure_modes` recording what a run
without the skill is expected to get wrong.

Run each eval **twice** in the described setup: once with the skill
installed, once without. Grade the `expectations` against the
transcript and the resulting repository state.

**If the two runs are indistinguishable, that is a finding, not a
pass.** A skill that does not beat the baseline is not earning its
context.

This has already paid off once. Skill B's *titles* in an
already-configured repository turned out to be only marginally
better than the baseline, because the baseline could read the
convention off the workflow file. The value was real but elsewhere:
process discipline, no unrequested test runs, waiting on the right
check. Knowing precisely where the value is not is worth as much as
knowing where it is.

These need **real** GitHub repositories. Merge settings, rulesets,
and status checks are server-side state that cannot be faked
locally. Lifecycle, reset procedures, and the human checkpoints are
in [test-repos.md](test-repos.md).

## Tier 2: trigger evals

Roughly twenty prompts per skill: half that should invoke it, half
near misses. Split 60/40 into `train` and `validation`.

- **`train`** is for iterating on the name and description.
- **`validation`** is the ship gate, scored only after the wording
  is frozen. It passes at a should-trigger rate of at least 0.5 and
  a near-miss rate below 0.5.

Present each prompt to a **fresh** session with the skill installed,
and record whether the skill was invoked. Cold sessions matter:
dispatch is the thing under test, and a warm session has already
been primed.

Some near-miss prompts legitimately belong to the *sibling* skill.
Those carry a `note`, and a miss that dispatches to the sibling is
correct behavior, not a failure. Score it accordingly.

Any edit to a `description` invalidates these results. That is the
one change that can alter a skill's behavior without altering a word
of its instructions.

### How to run it

```
bash tests/evals/run-trigger-evals.sh train <outdir>
bash tests/evals/run-trigger-evals.sh validation <outdir>
```

It builds the fixture, runs every prompt in the split, scores
dispatch, and writes `results.json` next to the transcripts.
Budget roughly two minutes per prompt -- 24 for `train`, 16 for
`validation`.

The 2026-07-29 campaign discarded its runner and left only prose,
which cost the next person the entire procedure. The script exists
so that does not happen twice; what it does is below, so the
procedure survives the script too.

Each prompt is a fresh headless session:

```
claude -p "<prompt>" --output-format stream-json --verbose --max-turns 4 --tools "Skill,Read,Glob,Grep" --allowedTools "Skill,Read,Glob,Grep"
```

**cwd.** A throwaway local git repository -- a README and one
commit, no remote -- with **both** skills installed repo-scoped at
`.claude/skills/`. Both, deliberately: a near-miss prompt that
belongs to the sibling has to be able to dispatch to it, because
that is a pass, and it cannot be observed if the sibling is not
installed.

**Containment.** Restrict the session to `Skill` plus read-only
tools and cap the turns. Some sessions still end
`error_max_turns`, which is the cap working as intended -- the
dispatch decision was already made and recorded by then.

`--tools` is the load-bearing flag here, and `--allowedTools` on
its own is not enough. The original record described containment
as "Bash/PowerShell attempts were auto-denied". That is no longer
true. Measured 2026-09-19 on `claude-opus-5[1m]`: under
`--allowedTools` alone, sessions ran Bash successfully, spent all
four turns reading the repository -- in one case `find`-ing and
`head`-ing the installed `SKILL.md` instead of invoking it -- and
never reached a Skill call. Three Skill B prompts scored as
dispatch failures on that basis. Re-run with `--tools`, all three
dispatched the skill as their **first** tool call.

Watch for this failure mode, because it looks exactly like a skill
that stopped triggering. If a skill that used to pass suddenly
drops, re-check containment before touching a description.

**Scoring.** A case counts as a trigger of skill X if and only if
a `Skill(X)` tool_use appears in the transcript. One run per
prompt; the rate is over the prompts in that bucket.

Record the CLI version and the model alongside the results.
Dispatch is a model behavior, so a score is comparable only to
another score taken on the same model.

## Installing a skill under test

Copy the folder into the test repository's `.claude/skills/`, as
described in [test-repos.md](test-repos.md). Do **not** use
`claude --plugin-dir` for evals: that namespaces the skill as
`conventional-pr-titles:<name>`, which changes the dispatch surface the
trigger evals are measuring. `--plugin-dir` is for working *in this
repository*, not for testing.

## What has been run

[evidence.md](evidence.md) is the index: every requirement, the run
that exercised it, and the independent read-back behind each verdict.
Start there rather than in the records -- it answers "has this ever
been run, and when?" directly, and it is maintained.

[known-gaps.md](known-gaps.md) is the other half of the same question:
six requirements have never been exercised, and three configurations
have never been tried at all. Read it before claiming coverage.

[validation/](validation/) holds the dated records themselves: the
step-8 validation of both skills, the degraded-path and idempotency
campaign, the non-admin fail-fast scenario, and the two trigger-eval
gates. They are evidence rather than living documents -- read them for
what was verified and when, not as current instructions.

## Finishing a campaign

A tier-2 campaign is not done when it produces a verdict. It is done
when the verdict has been absorbed:

1. Append every finding to [findings.md](findings.md), continuing the
   existing per-skill numbering, and say what changed as a result.
2. Add or update the run's rows in [evidence.md](evidence.md),
   including the independent read-back -- the read-back is the part
   that makes the verdict checkable later.
3. Settle or add rows in [known-gaps.md](known-gaps.md). A gap the
   campaign closed moves to `evidence.md`; a gap it revealed stays.
4. If the campaign changed what the skills must do, update
   [behavior-spec.md](behavior-spec.md) and the `requirements` arrays
   in the eval files.

Skipping step 3 is the easy one to skip and the expensive one to
skip: an untested branch and a tested one look identical in the
source, so a gap nobody wrote down is a gap nobody will find.
