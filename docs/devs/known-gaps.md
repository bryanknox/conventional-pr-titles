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
| A-R13 | That the skill does not create the repository or scaffold application code. | No scenario asks it to. Every test repo already exists before the run. | A scenario that prompts for setup in a directory with no `origin`, or asks for repo creation outright, asserting it declines and says why. |
| A-R14 | That the skill does not compose PR titles. Dispatch is covered -- trigger case A-N9 correctly routes "open a PR with a conventional commit title" away -- but behavior is not. | Boundary requirements are only exercised by prompts that try to cross them, and no content eval does. | A content eval whose prompt asks Skill A for a PR title mid-run, asserting it declines and names the sibling. |
| B-R14 | That the skill never rewrites, squashes, or lints branch commits. | All runs left branch commits alone, but no run tempted it. The P1 setup came closest -- a deliberately vague commit message -- and the skill correctly used it only as a hint. | A prompt that explicitly asks for the branch commits to be cleaned up as well, asserting it declines and explains that branch commits are unconstrained by design. |

## Untested configurations

| Gap | Why it matters | What would close it |
|---|---|---|
| **Org-owned private repositories.** O1 and O5 ran on public org repos. | Skill A's plan read, `gh api user`, reports the invoker's personal plan, but a private org repo's ruleset gate depends on the organization's plan. Only the 403 detector has been exercised, and only on a personal repo (S2). | An S2 equivalent in `test-bryanknox`: a private repo on the free organization plan, asserting the rulesets read answers 403 at preflight and Level 3 is reported BLOCKED with a remedy that fits an organization. |
| **Harnesses other than Claude Code.** `authoring.md` restricts frontmatter to `name` and `description` because that is the intersection Claude Code, Cursor, Codex, and Copilot all accept, and `lint-skills.sh` enforces it. | The claim is asserted and linted but never executed. The skills have only ever been run in Claude Code. | Install each skill in Cursor and Codex and run one scenario. Even a single load confirming the frontmatter parses would retire most of the risk. |
| **A user-supplied type list.** A-R4 permits one and requires the deviation be recorded in the final report. | Never exercised; every run took the default ten. | An S1 variant whose prompt names a reduced type list. |

## Method gaps

These limit what any of the evidence can claim.

**Content evals have no runner for the transcript half.** The
repo-state half is now `tests/evals/check-repo-state.sh`. It reads
back server state for S1-S6, O1, O5, and P1-P8, asserts the expected
values, and saves the raw reads as citable read-backs -- see
[testing.md](testing.md), "Checking repo state". What it cannot see
is still graded by hand against the transcript: one checkpoint before
any mutation, a read-back after every mutation, the content of the
final report, imperative mood in a title, and the with-skill against
without-skill comparison. Driving the sessions themselves is manual
too. The checker was proven read-only against this repository, which
is in the S2 end state, and was first used in a real campaign in
2026-10 (S6, O1, O5, P6-P8 and their baselines).

**Trigger results are single-run point estimates.** Each prompt was
presented once per gate. Dispatch is sampled behavior, not
deterministic, so a 15/16 is one draw and a repeat run could land
differently near the threshold. The gate thresholds (>= 0.5 and < 0.5)
are set wide enough to tolerate this, but no confidence interval
exists and none is claimed.

**Baselines were single runs too.** Every value-delta measurement --
S1b, the P baseline, and the P6, P7, and P8 baselines -- is one run
each. The P baseline already showed how much that matters: it
falsified a predicted failure mode, and one more run might have
falsified a different one. Same-repo baselines are not independent
draws either: the P7 baseline read the with-skill run's closed pull
request (T-F7).

## Gaps in this repository's own setup

**The PR-title check here is advisory, not required.** Ruleset
endpoints are plan-gated on a private free-plan repository, which is
finding A-F5 applied to this repo itself. `enforce-conventional-commits`
has been run here and Levels 1 and 2 are in place, but Level 3 is
blocked, so direct pushes to `main` remain possible and using pull
requests is a choice rather than enforcement. Making the repository
public and re-running the skill adds only the ruleset. See
[decision 0009](decisions/0009-stay-private-for-now.md).
