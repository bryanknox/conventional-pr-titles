# Trace: baseline (no skill) on bryanknox/k0x-test-cc-s1 (B-CE1)

Date: 2026-07-28. Same setup as P1 (identical null-check fix on
branch `fix-null-json`, vague commit "handle null case", unpushed;
scaffolded repo), same prompt ("Open a PR for this."), same
unattended-run framing -- but `.claude/skills/pr-conventional-commits`
REMOVED first (only the unrelated `normalize-bench-file` skill
remained; runner correctly judged it inapplicable).

## Ordered trace (condensed)

1. Repo state reads; diff read; found no applicable skill.
2. Explored `.github/` -- found `pr-title.yml`, READ IT, plus
   CLAUDE.md / AGENTS.md: learned the conventional-title
   requirement from the scaffold itself.
3. Unrequested pre-flight: `dotnet test` on the touched project
   (9 passed) and `dotnet format whitespace|style
   --verify-no-changes` (clean).
4. Pushed branch; `gh pr create --title "fix: throw JsonException
   when a JSON file contains only null"` -> PR #6.
5. `gh pr checks 6 --watch` -- waited for ALL checks including
   `Format Build and Test` (1m56s).
6. Report: PR link, change summary, pre-flight results, both
   checks green. No type rationale, no squash-setting analysis.

Cost: 36,515 subagent tokens, 16 tool uses, 3.8 min.

## Comparison vs P1 (with skill)

- Title quality: EQUIVALENT -- valid conventional `fix:` title.
  The predicted baseline failure mode ("generic title") did NOT
  occur: in a repo scaffolded by Skill A, the pr-title workflow
  file itself teaches a capable agent the convention.
- Process deltas (where the skill's value actually showed):
  - Baseline ran unrequested `dotnet test`/`dotnet format` and
    watched ALL CI checks -> 2x tool uses (16 vs 8), ~45% more
    wall clock (3.8 vs 2.6 min), ~19% more tokens.
  - Baseline gave no type rationale and no squash-settings
    analysis (PR_TITLE / BLANK implications).
  - Skill runs are deterministic on the same path every time
    (scaffold detection, read-back verify, title-check-only wait,
    templated report); baseline behavior depends on the agent
    choosing to explore `.github/`.
- Caveat recorded honestly: the title-level delta should be
  larger in an UNSCAFFOLDED repo (nothing to learn the convention
  from) -- that is scenario P5 / eval B-CE3, deliberately outside
  todo #7 scope.
