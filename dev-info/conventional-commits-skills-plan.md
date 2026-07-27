# Handoff Packet: Conventional Commits Agent Skills

Design plan for two agent skills, produced by the `genesis` design
process (steps 1-6). This packet is the source of truth for the
coding step (7a/7b) and for any future refactor. Re-running the
design starts from this packet, not from the emitted skills.

Inputs: `desires-for-conventional-commits-setup.md`,
`setup-guide-for-conventional-commits.md`,
`type-guide-for-conventional-commits.md`,
`conventional-commits-info-links.md`, `skill-testing-repos.md`.

Cost stance: `balanced` (default; operator did not declare).
Cost cap: none declared (projection is informational, not a gate).

---

## Step 1 - Intent + scope

### Skill A: `setup-conventional-commits`

One paragraph: Configure an EXISTING GitHub repository so that the
only path to `main` is a squash-merged PR whose title is a valid
Conventional Commits message. Implements the three-level footprint
from the setup guide: (1) repo merge settings (squash-only, default
squash message = PR title), (2) a `main` ruleset (require PR,
required PR-title status check, block force push / deletion, empty
bypass list), (3) a PR-title lint workflow using
`amannn/action-semantic-pull-request`. No local git tooling (Level
4 = nothing). Boundary: does NOT create the repo, does NOT scaffold
the .NET application, does NOT compose PR titles (that is Skill B).
Nothing in the footprint is .NET-specific; .NET is an indirect
trigger, not a constraint on the skill body.

Constraint handling (from desires): personal accounts; public repos
fully supported; private repos accommodated with a detected,
reported gap (rulesets on private personal repos need GitHub Pro --
skill detects the failure and degrades gracefully, applying Levels
1 and 3 and reporting what is missing).

### Skill B: `pr-conventional-commits`

One paragraph: Create or update a GitHub pull request so its TITLE
is a valid Conventional Commits message, for squash-merge repos
where the PR title becomes the commit message on `main`. Reads the
branch diff and commit history (deterministic tool reads),
classifies the change into the de-facto 10-type set, composes
`type(scope)!: description` plus a body with a `BREAKING CHANGE:`
footer when warranted, applies via `gh pr create` / `gh pr edit`,
and verifies the repo's PR-title check passes (bounded retry).
Boundary: does NOT configure repo settings, rulesets, or workflows
(that is Skill A); does NOT enforce conventional commits on branch
commits (per desires, branches are unconstrained).

### Dispatch descriptions (draft; final wording validated by trigger evals)

Skill A (~640 chars, imperative, intent-first, indirect triggers,
mode BOTH):

> Use this skill when the user wants to set up, scaffold, or
> configure a GitHub repository to use Conventional Commits
> enforced at squash-merge time: squash-only merge settings, a
> main-branch ruleset requiring PRs and a PR-title check, and a
> PR-title lint workflow. Also use when the user asks to "protect
> main", "prevent direct pushes", "enforce commit message format on
> main", or is setting up a new .NET (or any) app repo that should
> keep a clean conventional history. Configures the repo via gh
> CLI. Does NOT create the repo or app code, and does NOT write PR
> titles (see pr-conventional-commits).

Skill B (~600 chars, imperative, intent-first, indirect triggers,
mode BOTH):

> Use this skill when creating or updating a GitHub pull request
> whose title must be a Conventional Commits message -- squash-merge
> repos where the PR title becomes the commit on main. Also use
> when a "PR Title" / semantic-pull-request check is failing, when
> the user asks which commit type (feat, fix, chore, ...) a change
> is, or when opening any PR in a repo set up by
> setup-conventional-commits. Composes type(scope)!: description
> titles and BREAKING CHANGE footers from the actual branch diff.
> Does NOT configure repo settings, rulesets, or workflows (see
> setup-conventional-commits).

---

## Step 2 - Component diagram

```mermaid
flowchart LR
    SA[SKILL setup-conventional-commits]:::new
    SB[SKILL pr-conventional-commits]:::new
    WT[(ASSET workflow template pr-title lint)]:::new
    TG[(ASSET type guide reference)]:::new
    GH[(TOOL gh CLI - S7 bridge, preloaded terminal route)]
    SPEC[(EXTERNAL CORPUS conventionalcommits.org + GitHub REST docs)]

    SA -- INLINE asset --> WT
    SB -- INLINE asset, lazy --> TG
    SA == tool calls ==> GH
    SB == tool calls ==> GH
    SA -. C6 lazy grounding .-> SPEC
    SB -. C6 lazy grounding .-> SPEC

    classDef new stroke-dasharray: 5 5;
    class SA,SB,WT,TG new;
```

All boxes are NEW except the gh CLI (existing preloaded substrate)
and the external corpora. No personas, no rules, no orchestrators:
each skill is a single-lens procedure and a persona would add no
independent lens. Module types: SA, SB = SKILL (MODULE ENTRYPOINT);
WT, TG = ASSET.

## Step 3 - Thread / sequence diagrams

Pattern selection (tier order):

1. Refactor triggers: repo has no existing skill modules; nothing
   to split/fuse/extract/inline. The A/B two-skill split is a
   legitimate R1 (see step 4).
2. Tier 3: **A9 SUPERVISED EXECUTION (weak form)** for both skills.
   Both name consequential side effects on a system of record
   (GitHub repo settings, rulesets, workflow files, PRs) and facts
   that must be true (current settings, repo visibility, plan
   limits, check outcomes). Weak form because both run in an
   interactive session where the operator is the auditor; no
   trigger surface with capability gating is in play. A2 PIPELINE
   also loosely fits Skill A's staged shape, but the A9 selection
   heuristic resolves it: "pick A9 over plain A2 when at least one
   stage is a consequential side effect" -- every stage here is.
   No matrix consult needed (step 3.1 skipped; no genuine tension).
3. Tier 2: S7 DETERMINISTIC TOOL BRIDGE (route 1, preloaded
   terminal + gh CLI), S4 VALIDATION DECORATOR (read-back verify
   after every mutation; PR-title check status as the gate in B),
   B4 PLAN MEMENTO (Skill A writes a setup checklist artifact
   before mutating; reloaded per level), B8 ATTENTION ANCHOR
   (goal + constraints restated at each level boundary), B10 HUMAN
   CHECKPOINT (Skill A: before applying the settings/ruleset diff
   to a real repo, and before overwriting any existing ruleset or
   workflow; Skill B: before editing a PR title the user did not
   author this session), C1 LAZY ASSET (workflow template, type
   guide), C6 EXTERNAL CORPUS GROUNDING (GitHub REST shapes and
   action version verified live at run time, never from recall).
4. Tier 1 idioms: deferred to step 7b.

Single thread each; no spawns; no shared-sink interlocks needed
(one writer: the session itself).

### Skill A thread

```mermaid
sequenceDiagram
    participant U as Operator
    participant S as Session (skill A)
    participant G as GitHub via gh CLI

    S->>G: preflight reads (auth, visibility, plan, settings, rulesets, workflow)
    G-->>S: current state (facts via tool, not recall)
    S->>S: compute diff current vs target; write checklist (B4)
    S->>U: B10 checkpoint - proposed changes incl. private-plan gap if any
    U-->>S: approve / adjust
    S->>G: Level 1 PATCH merge settings
    G-->>S: read-back verify (S4)
    S->>G: Level 3 commit pr-title workflow to main
    G-->>S: read-back verify (S4)
    S->>G: Level 2 create main ruleset (required check by name)
    G-->>S: read-back verify (S4) or plan-limit error -> report gap
    S->>U: final verification report + residual soft spots
```

Ordering note: Level 3 (workflow file) lands BEFORE Level 2 (the
ruleset that requires a PR), so the workflow can be committed
directly to `main` without being blocked by the ruleset the skill
itself creates. The required status check is added to the ruleset
by name via the REST API (no prior run needed via API -- VERIFY
against live GitHub docs at 7b; C6).

### Skill B thread

```mermaid
sequenceDiagram
    participant U as Operator
    participant S as Session (skill B)
    participant G as GitHub via gh CLI

    S->>G: read branch, diff vs default, commits, existing PR
    G-->>S: facts (S7 reads)
    S->>S: classify type/scope/breaking (type guide lazy-loaded if ambiguous)
    S->>U: B10 checkpoint if editing a title not authored this session
    S->>G: gh pr create / gh pr edit
    G-->>S: read-back title (S4)
    S->>G: poll PR-title check result
    G-->>S: pass -> done; fail -> read check log, fix title, retry (max 2)
    S->>U: report title, type rationale, check status
```

## Step 3.1 - Tradeoff check

Skipped: pattern selection was unambiguous at every slot (recorded
above). No matrix citation required.

## Step 3.2 - Cost check

No spawns, so no per-spawn role-class binding. Skills execute in
the session model; on common substrate a MODULE ENTRYPOINT carries
no per-element model binding, so OMIT is the justified B12 action
(rule 3(i): the primitive type cannot carry the binding). Work is
implementer-class shaped in both skills.

| Module | Role class | Prefix size | Output volume | Turns | Cost patterns applied |
|---|---|---|---|---|---|
| setup-conventional-commits | implementer (session) | M | S-M | medium (4-10) | B13, B14 at validation, B15 candidate at 7b |
| pr-conventional-commits | implementer (session) | S-M | S | low-medium (3-6) | B13, B14 at validation, B15 candidate at 7b |

- B13 CACHE-AWARE PREFIX: skill bodies contain no timestamps, no
  dynamic facts; all volatile state (settings, plan, checks)
  arrives via tool results in the variable suffix.
- B15 TOOL SUBSET: at 7b, if the harness supports per-skill
  allowed-tools, restrict to terminal + file edit.
- No B12 router / A12 gradient: single-thread, no fan-out; nothing
  to route. Not CLASS-UNIFORM (that anti-pattern needs a multi-
  module graph).
- Stance mandates for `balanced` are satisfied (B13 always; role
  class per slot; B14 thrift at validation).

## Step 3.5 - Composition decisions

| Box | Mode | Rationale |
|---|---|---|
| Skill A body | new module (skill) | unit of distribution; copied standalone into consumer repos |
| Workflow template (pr-title lint YAML) | INLINE asset in A | unique to A; emitted artifact template; agents pattern-match concrete structure |
| Skill B body | new module (skill) | independent distribution + invocation cadence |
| Type guide reference | INLINE asset (lazy) in B | only B consumes it at runtime; loaded on ambiguous classification |
| 10-type list in A's body (optional `types:` pin in workflow) | INLINE duplication in A | deliberate: skills ship standalone; a cross-skill sibling dep would be PHANTOM DEPENDENCY at install time; the list is ~15 stable tokens anchored to the Angular convention -- drift risk negligible vs self-containment win |
| gh CLI | substrate tool (S7 route 1) | preloaded terminal; not a module |
| conventionalcommits.org, GitHub REST docs, action releases | EXTERNAL CORPUS (C6, lazy, bounded) | authoritative for spec text / API shapes / action versions only |
| Evals, test-repo tooling, dev-info docs | maintainer-scope, OUTSIDE distribution boundary | no runtime consumer; shipping them is BUNDLE LEAKAGE + dispatch contamination risk |

```mermaid
flowchart LR
    A[setup-conventional-commits]
    B[pr-conventional-commits]
    WT[(workflow template)]
    TG[(type guide)]
    DEV[(dev: evals + test tooling)]
    A -- INLINE --> WT
    B -- INLINE --> TG
    DEV -. maintainer-scope, not shipped .-> A
    DEV -. maintainer-scope, not shipped .-> B
```

External modules required: NONE. Distribution mechanism: raw folder
copy of each skill directory into a consumer repo's skill location
(harness-specific path bound at 7b). No module-system adapter
needed at 7b. Skill B's description names Skill A (and vice versa)
as a companion-module recommendation only -- neither depends on the
other at runtime, so no probe is required.

Repo layout (source tree):

```
skills/
  setup-conventional-commits/   SKILL.md + assets/pr-title-workflow.yml
  pr-conventional-commits/      SKILL.md + references/type-guide.md
dev/
  evals/setup-conventional-commits/evals.json
  evals/pr-conventional-commits/evals.json
  test-repos.md                 (test repo lifecycle procedures)
dev-info/                        (existing planning docs, maintainer-scope)
```

## Step 4 - SoC pass

- Split justification (R1): distinct trigger noun-phrases
  (configure repo vs author PR title), divergent change cadence
  (GitHub settings/ruleset/API surface vs commit-type conventions),
  divergent invocation frequency (once per repo vs every PR). Not
  a PREMATURE SPLIT.
- Dispatch collision, between the two: trigger verbs are disjoint
  (set up / configure / protect vs create / update / title / type).
  Each description names the other as its boundary.
- Dispatch collision, vs installed siblings: the operator's
  environment has a `review` skill ("review a GitHub pull
  request") -- different verb space (review vs create/update); no
  collision. No other conventional-commits-adjacent skill installed.
- No duplication of existing modules: repo currently contains no
  skills.
- S7 audit: every consequential side effect (PATCH settings, commit
  workflow, create ruleset, create/edit PR) and every
  fact-that-must-be-true (settings state, visibility, plan, check
  result) crosses the gh CLI bridge. No LLM-asserted state anywhere
  in the design.

## Step 5 - Compliance check

Classic + PROSE + LLM-physics: no BLOCKER, no HIGH.

Open findings:

- MEDIUM: Skill A depends on two GitHub API behaviors that must be
  verified live at 7b, not recalled (C6): (a) required status
  checks can be added to a ruleset by context name via REST without
  a prior workflow run; (b) the exact error shape when creating a
  ruleset on a private free-plan personal repo (needed for the
  graceful-degrade branch). If (a) is false, Skill A becomes a
  two-phase saga (scaffold, first PR runs check, then bind check to
  ruleset) -- the packet's sequence diagram must be revised at that
  point.
- LOW: skill names pending trigger-eval validation; alternatives
  considered: `scaffold-conventional-commits` (A),
  `conventional-commit-pr-title` (B).
- LOW: `amannn/action-semantic-pull-request` pinned at major `v6`
  in the template (pinning-worthy: silent drift would change lint
  behavior). At scaffold time the skill verifies the current major
  via the releases API (C6) and warns if the template lags.

Entrypoint spec compliance (targets for step 8): names match
`[a-z0-9-]` and parent dirs; descriptions < 1024 chars (drafts:
~640 / ~600); bodies budgeted well under 500 lines / 5000 tokens
(A: ~150-250 lines incl. checklist template; B: ~100-180 lines);
overflow (type guide details) already routed to a lazy reference
with an explicit load trigger ("read references/type-guide.md when
the change fits more than one type or none cleanly").

---

## Step 6 - Handoff artifacts

### Interface sketches

**setup-conventional-commits** (SKILL, new, invocation: BOTH)
- Inputs: target repo (defaults to cwd origin); operator approval
  at the B10 checkpoint; optional flags (pin allowed types, enable
  auto-delete-branches, PR body in squash message).
- Outputs: mutated repo settings + ruleset + committed workflow
  file; a verification report (EXTERNAL, normal prose) listing each
  level's before/after state, any plan-limit gaps, and residual
  soft spots (merge-box hand-edit).
- Process spine: preflight reads -> diff + checklist (B4) -> B10
  checkpoint -> apply+verify Level 1 -> apply+verify Level 3 ->
  apply+verify Level 2 -> report (B5 acceptance re-read of the
  checklist).
- Dependencies: assets/pr-title-workflow.yml (INLINE); gh CLI (S7);
  GitHub REST docs + action releases (C6 lazy).
- Idempotency requirement: re-running on a configured repo produces
  a no-op diff and says so at the checkpoint.

**pr-conventional-commits** (SKILL, new, invocation: BOTH)
- Inputs: current branch + working repo; optional existing PR
  number; user intent description if provided.
- Outputs: created/updated PR with conventional title (+ BREAKING
  CHANGE footer in body when warranted); short report of type
  rationale and check status (EXTERNAL, normal prose).
- Process spine: S7 reads (diff, commits, existing PR) -> classify
  (body decision rules; lazy type guide on ambiguity) -> compose
  title/body -> B10 checkpoint when rewriting someone else's title
  -> gh pr create/edit -> verify title + poll check -> bounded
  retry (max 2) -> report.
- Dependencies: references/type-guide.md (INLINE lazy); gh CLI
  (S7); conventionalcommits.org spec (C6, only on spec-edge cases).
- Title rules carried in body: imperative description, lowercase
  type from the 10-type set, optional scope, `!` and/or footer for
  breaking, target <= 72 chars.

### Declared targets

`common-only`. Both skills are designed against the common
substrate; step 7a is expected to confirm no per-harness reach is
needed beyond the adapter binding the skill-folder path and
optional allowed-tools field. First concrete target: the operator's
current harness.

### PER-SPAWN DECLARATION TABLE

No task() spawns in this design. Table empty; audience boundary
reduces to: all emitted reports are EXTERNAL (normal prose), the
B4 checklist is INTERNAL (terse table, no caveman contract needed
since no cross-thread consumer exists).

### HUMAN_RATIONALE (never copied into any spawn brief)

Why two skills and not one: the conjunction test fails immediately
("configure a repo AND title a PR"); frequency asymmetry means the
dispatcher would pay a fat body on every PR for content used once
per repo. Why no panel/fan-out: neither task has independent
lenses; a "security lens / settings lens" split would be
FAN-OUT-IN-NAME-ONLY over one checklist. Why weak-form A9: both
skills run interactively; the operator approves the diff before
mutation; strong-form (buffered outputs, no token) belongs to a
future CI-side variant, out of scope here. Why the type list is
duplicated rather than shared: skills are distributed by folder
copy into arbitrary consumer repos; a shared sibling would either
break on install (missing file) or force always-shipping both
skills together. Why Level 3 before Level 2: the skill must not be
blocked by the ruleset it just created; committing the workflow
first keeps the whole scaffold single-pass. Why B10 sits before
Level 1 (one checkpoint, not three): the three levels are one
reviewable diff; per-level checkpoints would be a CHATTY GATE.

### Development strategy

1. Draft order: Skill A first (Skill B's end-to-end verify needs a
   repo with the PR-title check installed, which A produces).
   Drafting is step 7a/7b of the genesis process: reload this
   packet before drafting each skill.
2. Source of truth for domain content: the four dev-info docs.
   The type guide asset in Skill B is a trimmed copy of
   `type-guide-for-conventional-commits.md` (decision rules +
   per-type one-liners; drop the version-bump narrative).
3. dev-info stays maintainer-scope (outside `skills/`); nothing in
   it ships.
4. Evals live in `dev/evals/` (outside the skill folders) to avoid
   BUNDLE LEAKAGE and dispatch contamination.
5. Each skill is refined against at least one real run in a test
   repo before being called done (step 8 REAL-TASK REFINEMENT).

### Testing strategy

Grounded in `skill-testing-repos.md`; base repo
`bryanknox/k0x-workbench` (READ-ONLY -- never mutated).

- Installation for test: copy `skills/<name>/` into the test
  repo's skill directory (path bound at 7b). Repo-scoped install,
  not user-scoped, so the skill under test cannot leak into other
  sessions.
- Skill A tests need REAL repos (settings + rulesets are
  server-side). Lifecycle: RECREATE per scenario -- clone
  k0x-workbench, `gh repo create bryanknox/k0x-test-cc-<scenario>`
  from it, run the skill, assert via `gh api` read-backs, then
  delete (repo deletion = human checkpoint; needs `delete_repo`
  scope explicitly granted).
  - Scenario S1 fresh public repo: full 3-level happy path.
  - Scenario S2 private repo (free plan): Levels 1+3 applied,
    ruleset gap detected and reported, no crash.
  - Scenario S3 already-configured repo: idempotent no-op.
  - Scenario S4 partially/conflictingly configured repo (e.g.
    merge commits enabled, stray ruleset): correct reconcile diff
    shown at checkpoint.
- Skill B tests REUSE one scaffolded repo (`k0x-test-cc-pr`) with
  reset between runs (close PRs, delete branches) rather than
  recreate.
  - Scenario P1 single bug-fix branch -> `fix: ...`, check green.
  - Scenario P2 breaking API change -> `feat(scope)!: ...` +
    BREAKING CHANGE footer, check green.
  - Scenario P3 docs-only change -> `docs: ...`.
  - Scenario P4 existing PR with bad title -> title fixed, check
    goes red -> green (exercises the bounded retry loop).
  - Integration property: B tested inside a repo scaffolded by A.
- GitHub workflow development (the pr-title.yml template itself)
  is exercised only in test repos, never in this dev repo --
  matching the dev-info guidance that workflow run histories
  should not muddy development repos.
- Human admin participation, named up front: creating/deleting
  repos in the personal account, granting `delete_repo` scope,
  and eyeballing ruleset state in the GitHub UI for S2.
- Reset/recreate helpers start as documented `gh` one-liners in
  `dev/test-repos.md`; promote to `dev/scripts/` only if the rule
  of three fires.

### EVALS PLAN

Content evals (run each prompt with_skill and without_skill; if
outputs are indistinguishable, the skill is not adding value):

- A-CE1: "Set up this repo to use conventional commits with squash
  merges." Expected: all three levels applied in the documented
  order, verification report, residual-soft-spot note. Baseline
  failure modes to beat: missing `edited` trigger on the workflow,
  non-empty bypass list, no read-back verification.
- A-CE2: same prompt on a private free-plan repo. Expected:
  explicit gap report for the ruleset, Levels 1+3 still applied.
- B-CE1: bug-fix branch, "open a PR for this." Expected:
  `fix: <imperative summary>` title; without skill: generic title.
- B-CE2: breaking change branch. Expected: `!` marker + BREAKING
  CHANGE footer; without skill: typically missed.

Trigger evals: ~20 per skill, 60/40 train/val split; validation
split is the ship gate (>= 0.5 hit rate on should-trigger, < 0.5
on near-miss).

- A should-trigger samples: "scaffold conventional commits in this
  repo"; "make main only accept squash merges"; "protect main so
  the PR title becomes the commit message"; "set up commit lint
  for PR titles"; "configure this new .NET repo for conventional
  commits"; "prevent direct pushes to main"; "add a PR title
  check"; "enforce conventional commits on main".
- A near-miss samples (must NOT trigger): "write a conventional
  commit message for these changes"; "fix the failing PR title
  check on my PR" (Skill B); "set up branch naming conventions";
  "add a CI build workflow for .NET"; "rebase my branch onto
  main"; "review this PR"; "what does the ruleset on main do?";
  "squash my local commits".
- B should-trigger samples: "open a PR with a conventional commit
  title"; "update this PR title to pass the check"; "what type
  should this change be, feat or fix?"; "create the PR -- title
  becomes the squash commit"; "the semantic-pull-request check is
  failing"; "retitle PR 42 to conventional format"; "open a PR for
  this breaking change"; "draft a conventional title for this
  diff".
- B near-miss samples: "set up conventional commits in this repo"
  (Skill A); "write conventional messages for each local commit";
  "review PR 42"; "merge PR 42"; "why did CI fail?" (non-title
  check); "rename my branch"; "generate release notes from
  commits"; "configure squash merging".

### COST PROJECTION

Per-module bands (the CONTRACT; step 8 validates):

| Module | Role class | Prefix | Output | Turns |
|---|---|---|---|---|
| setup-conventional-commits | implementer (session) | M | S-M | medium (4-10) |
| pr-conventional-commits | implementer (session) | S-M | S | low-medium (3-6) |

Workflow-level ranges (the PREDICTION; token pass-through anchor at
implementer-class rates ~$3/$15 per Mtok; on subscription-billed
harnesses this is informational only):

- Skill A run: input 30-90K (bulk cacheable), output 2-8K, turns
  4-10 -> roughly $0.15-0.75 per run at the anchor rate.
- Skill B run: input 10-50K (diff size dominates), output 1-4K,
  turns 3-6 -> roughly $0.05-0.35 per run.

Scenarios: S = B on a single-file fix (~$0.05-0.10). M = A on a
fresh public repo (~$0.15-0.40). L = A on a private, partially
configured repo + B on a large refactor PR in the same session
(input up to ~150K, output ~10K, ~$1-2). No cap declared; L is
informational.

Cited cost patterns: B13 (stable skill bodies, volatile facts in
suffix -- guards INVALIDATOR LEAK), B14 (thrift pass at step 8),
B15 (allowed-tools subset if the harness supports it at 7b). B12 /
A12 / R5 not applicable (single thread, no fan-out) -- recorded so
reviewers know the absence is a decision, not an omission.

Declared stance: `balanced`. Cap check: N/A.

### TODOS

| # | Task | Depends on |
|---|---|---|
| 1 | Verify the two MEDIUM C6 facts against live GitHub docs (ruleset check-by-name; private-plan error shape) | packet |
| 2 | Draft `skills/setup-conventional-commits/` (SKILL.md + workflow asset) per interface sketch | 1 |
| 3 | Draft `skills/pr-conventional-commits/` (SKILL.md + type-guide reference) per interface sketch | packet (parallel with 2) |
| 4 | Author `dev/evals/` for both skills (content + trigger, 60/40 split) | 2, 3 |
| 5 | Write `dev/test-repos.md` (create-from-base, reset, delete procedures; human-checkpoint list) | packet |
| 6 | Step 8 validation, Skill A: lint + evals + real run on scenario S1; capture trace; revise | 2, 4, 5 |
| 7 | Step 8 validation, Skill B: lint + evals + real runs P1-P4 in the S1 repo; capture trace; revise | 3, 4, 6 |
| 8 | Degraded-path test S2 (private repo) + idempotency S3/S4 | 6 |
| 9 | Trigger-eval validation split gate on final descriptions; adjust names/descriptions if it fails | 4, 6, 7 |
