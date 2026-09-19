# Known gaps

**What this is for:** what is deliberately unproven, and what it would
take to prove it.
**Read it** before designing a tier-2 campaign, and before claiming
coverage in a release.
**Write to it** whenever a run establishes a new gap, and remove a row
when a run closes one -- moving the result to
[evidence.md](evidence.md).

A gap here is not a defect. A defect is something a run found wrong,
and those are in [findings.md](findings.md); this page is the opposite
-- behavior nothing has ever exercised. The distinction matters because
an untested branch and a tested one look identical in the source.

## Untested requirements

Each of these is a requirement in [behavior-spec.md](behavior-spec.md)
that [evidence.md](evidence.md) marks NOT PROVEN or PARTIAL.

| Requirement | What is unproven | Why | What would close it |
|---|---|---|---|
| A-R2 | The missing-`workflow`-scope fail-fast branch. | Both machine accounts hold `repo`+`workflow`, and `gh auth refresh` can only ADD scopes. Recorded rather than worked around, per the decision in [test-repos.md](test-repos.md). | A purpose-made classic PAT with `repo` but not `workflow`, then the S5 procedure against it. The code path is adjacent to the tested admin check -- same Step 1 fail-fast block, same prescribed report content -- so the risk is low but not zero. |
| A-R13 | That the skill does not create the repository or scaffold application code. | No scenario asks it to. Every test repo already exists before the run. | A scenario that prompts for setup in a directory with no `origin`, or asks for repo creation outright, asserting it declines and says why. |
| A-R14 | That the skill does not compose PR titles. Dispatch is covered -- trigger case A-N9 correctly routes "open a PR with a conventional commit title" away -- but behavior is not. | Boundary requirements are only exercised by prompts that try to cross them, and no content eval does. | A content eval whose prompt asks Skill A for a PR title mid-run, asserting it declines and names the sibling. |
| B-R9 | The bounded retry loop. P4 exercised red -> green, but every composed title passed on the first poll, so the retry path has never executed. | Retries only fire on a title the check rejects, and the skill does not produce those. | Deliberately apply an invalid title out of band, then run the skill against that PR. |
| B-R11 | The degrade path when the invoker cannot apply the title. | Needs an account with read-only access to a PR it did not open; the S5 collaborator setup covers Skill A's equivalent but was never pointed at Skill B. | Reuse the S5 second-account procedure against a PR owned by the other account. |
| B-R14 | That the skill never rewrites, squashes, or lints branch commits. | All runs left branch commits alone, but no run tempted it. The P1 setup came closest -- a deliberately vague commit message -- and the skill correctly used it only as a hint. | A prompt that explicitly asks for the branch commits to be cleaned up as well, asserting it declines and explains that branch commits are unconstrained by design. |

## Untested configurations

| Gap | Why it matters | What would close it |
|---|---|---|
| **Org-owned repositories.** Every test repo is in the `bryanknox` personal account. | A-F13 added an org-specific report branch -- "an admin of {org}/{repo}", because a non-admin token cannot list admins -- and that branch has never run. Org repos also have different ruleset and permission behavior. | One S1 and one S5 equivalent in an organization. Needs an org the maintainer controls. |
| **Harnesses other than Claude Code.** `authoring.md` restricts frontmatter to `name` and `description` because that is the intersection Claude Code, Cursor, Codex, and Copilot all accept, and `lint-skills.sh` enforces it. | The claim is asserted and linted but never executed. The skills have only ever been run in Claude Code. | Install each skill in Cursor and Codex and run one scenario. Even a single load confirming the frontmatter parses would retire most of the risk. |
| **A user-supplied type list.** A-R4 permits one and requires the deviation be recorded in the final report. | Never exercised; every run took the default ten. | An S1 variant whose prompt names a reduced type list. |

## Method gaps

These limit what any of the evidence can claim.

**Content evals have no runner.** `tests/evals/<skill>/evals.json`
holds `expectations` arrays that only a human grades against a
transcript and the resulting repo state. `run-trigger-evals.sh` reads
only `trigger_evals`. So tier 2's content half is entirely manual, and
its cost is why it is not run casually. Automating even the
repo-state half of the assertions -- the `gh api` read-backs are
already scripted in `test-repos.md` -- would make re-validation
substantially cheaper.

**Trigger results are single-run point estimates.** Each prompt was
presented once per gate. Dispatch is sampled behavior, not
deterministic, so a 15/16 is one draw and a repeat run could land
differently near the threshold. The gate thresholds (>= 0.5 and < 0.5)
are set wide enough to tolerate this, but no confidence interval
exists and none is claimed.

**Baselines were single runs too.** Both value-delta measurements --
S1b and the P baseline -- are one run each. The P baseline already
showed how much that matters: it falsified a predicted failure mode,
and one more run might have falsified a different one.

## Gaps in this repository's own setup

**The PR-title check here is advisory, not required.** Ruleset
endpoints are plan-gated on a private free-plan repository, which is
finding A-F5 applied to this repo itself. `enforce-conventional-commits`
has been run here and Levels 1 and 3 are in place, but Level 2 is
blocked, so direct pushes to `main` remain possible and using pull
requests is a choice rather than enforcement. Making the repository
public and re-running the skill adds only the ruleset. See
[decision 0009](decisions/0009-stay-private-for-now.md).
