# Trigger-eval validation gate record (plan todo #9)

Status: COMPLETE (2026-07-29). GATE PASS for both skills on the
frozen (post-todo-#8) names/descriptions -- 16/16 validation-split
prompts dispatched correctly. No name/description adjustment
needed.

- setup-conventional-commits: should-trigger 4/4 (1.00 >= 0.5),
  near-miss 0/4 (0.00 < 0.5) -> PASS
- pr-conventional-commits: should-trigger 4/4 (1.00 >= 0.5),
  near-miss 0/4 (0.00 < 0.5) -> PASS

## Procedure (per `dev/evals/README.md`)

Descriptions under test: the SKILL.md frontmatter as of commit
`ad811d5` (wording frozen after todo #8 fixes; only the train
split was consulted during earlier tuning, and no tuning turned
out to be needed).

Each of the 16 `validation`-split prompts (8 per skill, from
`dev/evals/<skill>/evals.json`) ran as a FRESH headless session:

- Harness: `claude -p "<prompt>" --output-format stream-json
  --verbose --max-turns 4 --allowedTools "Skill,Read,Glob,Grep"`,
  Claude Code CLI 2.1.220, model `claude-fable-5` (confirmed in
  every session's init message).
- cwd: a throwaway local git repo (README + one commit, no
  remote) with BOTH skills installed repo-scoped at
  `.claude/skills/` -- both installed so that near-miss prompts
  belonging to the sibling can dispatch to it (correct dispatch,
  per the eval notes).
- Containment: only Skill and read-only tools were allowlisted
  and turns were capped, so sessions could dispatch but not
  mutate anything (Bash/PowerShell attempts were auto-denied;
  several sessions ended `error_max_turns`, which is the cap
  working as intended -- the dispatch decision is recorded
  either way).
- Scoring: a case counts as a trigger of skill X iff a
  `Skill(X)` tool_use appears in the transcript. One run per
  prompt; rates are over the 4 prompts per bucket.

Runner/scorer scripts and raw stream-json transcripts lived in
the session scratchpad (`trigger-eval/{runner,score}.ps1`,
`out/*.jsonl`) -- ephemeral by design; the full dispatch evidence
is the table below.

## Results (2026-07-29)

`invoked` = Skill tool calls observed; blank = no skill invoked.
In every triggered case the Skill call was the FIRST tool call of
the session.

| Case | Prompt | Expected | Invoked | Verdict |
|---|---|---|---|---|
| A-T3 | protect main so the PR title becomes the commit message | trigger | setup-conventional-commits | PASS |
| A-T5 | configure this new .NET repo for conventional commits | trigger | setup-conventional-commits | PASS |
| A-T7 | add a PR title check | trigger | setup-conventional-commits | PASS |
| A-T10 | require pull requests and a conventional title check before anything lands on main | trigger | setup-conventional-commits | PASS |
| A-N2 | fix the failing PR title check on my PR | no-trigger | pr-conventional-commits | PASS (correct sibling dispatch, per eval note) |
| A-N5 | rebase my branch onto main | no-trigger | (none) | PASS |
| A-N7 | what does the ruleset on main do? | no-trigger | (none) | PASS |
| A-N10 | what are conventional commits and why would I use them? | no-trigger | (none) | PASS |
| B-T3 | what type should this change be, feat or fix? | trigger | pr-conventional-commits | PASS |
| B-T5 | the semantic-pull-request check is failing | trigger | pr-conventional-commits | PASS |
| B-T7 | open a PR for this breaking change | trigger | pr-conventional-commits | PASS |
| B-T10 | the PR Title check went red after I edited the PR -- fix the title | trigger | pr-conventional-commits | PASS |
| B-N2 | write conventional messages for each of my local commits | no-trigger | (none) | PASS |
| B-N5 | why did the CI build fail? | no-trigger | (none) | PASS |
| B-N7 | generate release notes from the commit history | no-trigger | (none) | PASS |
| B-N10 | set up semantic-release to publish versions from conventional commits | no-trigger | (none) | PASS |

## Observations

- Boundary discipline held in both directions: A-N2 (a Skill-B
  prompt in Skill A's near-miss list) went to
  pr-conventional-commits and NOT to setup-conventional-commits;
  B-N10 ("set up semantic-release ... from conventional
  commits") triggered NEITHER skill despite the "set up ...
  conventional commits" surface overlap with Skill A's
  description.
- A-T7 ("add a PR title check") was the pre-run coin-flip risk
  (it could plausibly read as a Skill-B "check is failing"
  prompt); it dispatched to Skill A as intended -- the "Does NOT
  write PR titles (see pr-conventional-commits)" boundary
  sentence appears to carry it.
- Single-run-per-prompt caveat: rates are point estimates from
  one deterministic-ish sample each, not repeated trials. The
  margin (1.00 vs the 0.5 bar, 0.00 vs the 0.5 bar) is wide
  enough that re-sampling noise cannot flip either gate verdict.

## Ship-gate status

With todo #9 PASS, all step-8 validation gates for both skills
(structural lint, content evals A-CE1/2 + B-CE1/2/3 across
S1-S5/P1-P5, baseline deltas, and this trigger gate) are
complete.
