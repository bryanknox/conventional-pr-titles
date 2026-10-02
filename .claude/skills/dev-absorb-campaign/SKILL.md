---
name: dev-absorb-campaign
description: >-
  Use this skill in the conventional-pr-titles repository after a
  tier-2 eval campaign has produced a verdict, to absorb it: write up
  a campaign, log a finding, update evidence.md, findings.md or
  known-gaps.md, record what a run proved, or close a known gap. Fans
  the result across the four maintained registers in docs/devs/ in a
  fixed order, continues the per-skill A-F / B-F / T-F numbering,
  records a falsified prediction rather than deleting it, and runs
  check-requirement-ids.sh as the backstop. Refuses to write an
  independent read-back it did not obtain from a live command.
  Maintainer-only: does NOT run evals, does NOT create or delete test
  repositories, and does NOT cut a release.
---

# Absorb a Tier-2 Campaign (registers fan-out)

A tier-2 campaign is not done when it produces a verdict. It is done
when the verdict has been absorbed. This skill performs that
absorption: a mechanical fan-out across four maintained registers, in
an order that matters, ending in a check that fails on a citation
that stopped resolving.

`docs/devs/testing.md`, under "Finishing a campaign", is the
authority for this procedure; this skill is the enforcement. Where
the two disagree the page wins -- stop and say so rather than
reconciling them here.

Boundaries: this skill does NOT run evals, does NOT create, reset, or
delete test repositories, and does NOT cut a release. It also does
not decide a verdict. Whether a run passed, and whether a baseline
and a skill run are distinguishable, are judgements the maintainer
makes, because they are judgements about the session under test.

## Who can run this

| | |
|---|---|
| Intended user | The maintainer, working in this repository |
| Runs how often | Once per tier-2 campaign, after it produces a verdict |
| Mutates | Four files under `docs/devs/`, and both `evals.json` files |
| Does not touch | GitHub, the test repos, anything under `skills/` |
| On a missing read-back | Record NOT INDEPENDENTLY VERIFIED and why -- never a plausible sentence |

## The four write targets

The order is not cosmetic. Target 3 depends on what target 2 now
says, and target 4 is the only one that re-arms release gates.

| # | File | Operation | What goes in |
|---|---|---|---|
| 1 | `docs/devs/findings.md` | append | one row per finding, continuing the per-skill numbering |
| 2 | `docs/devs/evidence.md` | edit and append | the coverage row for every requirement exercised, plus one runs row |
| 3 | `docs/devs/known-gaps.md` | settle or add | a closed gap MOVES to evidence.md; a revealed gap stays |
| 4 | `docs/devs/behavior-spec.md` and both `evals.json` | if the contract moved, or a prediction was falsified | a spec row and the `requirements` arrays; or a `baseline_failure_modes_measured` entry |

## Process

Follow the steps in order. Every fact about a register comes from
reading it now -- never from memory, never from earlier in the
conversation, and never from the campaign's own transcript. Nothing
is written to disk before the checkpoint in step 4 is approved.

### Step 1 - Read the campaign result and the registers (read-only)

```
grep -n '^| A-F\|^| B-F\|^| T-F' docs/devs/findings.md
grep -n '^| INV\|^| A-R\|^| B-R' docs/devs/evidence.md
grep -n '^| INV\|^| A-R\|^| B-R' docs/devs/behavior-spec.md
sed -n '/^## Untested requirements/,$p' docs/devs/known-gaps.md
```

Establish by reading, not by asking:

- The highest existing id in EACH findings section separately.
  Numbering is per skill and continues across campaigns, so the
  A-F, B-F, and T-F series each have their own high-water mark.
- Which requirement ids the campaign exercised, and what
  `evidence.md` says about each one today.
- Which known gaps the campaign touched.

Requirement ids are deliberately not listed in this skill.
`tests/check-requirement-ids.sh` does not scan this folder, so an id
transcribed here would be a citation nothing resolves -- in a
repository whose whole argument is that an unchecked citation scheme
rots. Read them from the registers every time.

### Step 2 - Obtain the independent read-back (does not delegate)

This is the step the skill exists for. Everything else is clerical.

"Independent" means a SECOND source. The campaign transcript is the
first source. Restating it is not a read-back.

**Never write an Independent verification cell from the run
transcript.** A session that has just watched a run will write the
read-back from the transcript, because the transcript says what
happened and saying it again reads as confirmation. It is not. The
cell exists to be a second source, and substituting the first one
produces a register that looks complete and proves nothing. Nothing
downstream can detect the substitution afterwards -- not
`check-requirement-ids.sh`, not review, not a later reader.

So run the reads now, in this session, against live state, and paste
the literal output. Run them as independent commands, never chained
with `&&` and never under `set -e`: `gh api` exits non-zero on
outcomes that are expected here, such as a 404 for an absent workflow
or a 403 for a plan gate, and chaining throws away every read after
the first.

```
gh api repos/{owner}/{repo}                                          # merge settings
gh api repos/{owner}/{repo}/contents/.github/workflows/pr-title.yml  # 404 = absent
gh api repos/{owner}/{repo}/rulesets                                 # the object exists
gh api repos/{owner}/{repo}/rules/branches/{default_branch}          # it is ENFORCED
gh pr view {number} --json title,body,baseRefName,headRefName        # title read-back
cat {outdir}/results.json                                            # trigger evals
claude --version                                                     # for a gate row
```

Both ruleset reads are needed. The first answers whether the object
exists; the second returns only rules that are actively enforced. An
empty second result after a successful create means the ruleset
exists and is doing nothing.

If a read-back cannot be obtained -- the repo was deleted, the
account was switched, the run happened elsewhere -- write
NOT INDEPENDENTLY VERIFIED and the reason in the cell, and carry it
into the report. That is a worse register and an honest one.

A claim about behavior that leaves no server state -- a request the
skill declined, a question it asked -- has no second source at all.
Mark it NOT INDEPENDENTLY VERIFIED for that reason. Do not restate
the transcript and call it confirmed.

If a read-back CONTRADICTS the transcript -- the runner reported one
value and the live read returns another -- the cell asserts the live
value and names the runner's value beside it. Do not change the
verdict, and do not decide the cause: the runner may be wrong, or the
state may have changed since the run. Both are judgements about the
session under test. The mismatch goes to the checkpoint as an item
that needs acknowledgment, and whether it becomes a finding is the
maintainer's call.

**Scope this refusal.** The `Cost` column is tokens, tool uses, and
wall time. It legitimately comes from the run itself, there is no
second source for it, and none is needed. Do not mark cost cells
unverified.

### Step 3 - Draft all four targets

Draft, do not write. Compose every row against the shapes in steps 5
to 8, using the ids read in step 1 and the output captured in step 2.
Nothing reaches disk until the checkpoint clears.

### Step 4 - Checkpoint (human approval)

Present all four targets as ONE reviewable diff: every row to be
appended, every row to be edited with its before and after, and every
row to be removed from `known-gaps.md`. Then wait.

One approval covering everything, not one per target. A skill that
asks repeatedly trains people to approve without reading.

Two things ALWAYS require explicit acknowledgment, never silent
action:

- Any independent-verification cell marked NOT INDEPENDENTLY
  VERIFIED, and any read-back that contradicts the transcript.
- Any change under target 4, stating which kind it is. A change to
  `behavior-spec.md` or to a `requirements` array moves the contract:
  it re-arms release gates 3 and 4 and is a semver event. A
  `baseline_failure_modes_measured` entry on its own does not move
  the contract. Say so, so the reader does not have to work it out.

### Step 5 - Target 1 of 4: findings.md

Append one row per finding, under the section for the skill it bears
on. The per-skill sections carry seven columns:

```
| {A-F|B-F}{n} | {defect|friction|ceremony|gap|thrift} | {date} | {req id or --} | {what it found} | {what changed} | {FIXED|OPEN} |
```

The "Tooling and procedure" section is for findings against the test
procedures or the eval harness rather than against either skill, and
it has SIX columns -- there is no requirement column:

```
| T-F{n} | {type} | {date} | {what it found} | {what changed} | {FIXED|OPEN} |
```

Rules. The type comes from the five the register's own header
defines; do not invent a sixth. The what-changed cell names the
concrete edit -- which file, what moved -- never "updated the skill".
If nothing has changed yet the status is OPEN, and since the register
closes by saying nothing in it is open, an OPEN row is a claim being
made on purpose. Append only: never renumber, never reuse an id, and
never edit an existing row except its status.

The register's closing section, "What is still open", lists what is
open. Edit it in the same change whenever that set changes -- an
OPEN row added, or the last OPEN row closed -- because otherwise the
last paragraph of the register contradicts its tables.

Verify: re-read the section and confirm the new ids are consecutive
with what step 1 found.

### Step 6 - Target 2 of 4: evidence.md

Two tables, two different operations.

**Coverage** -- every requirement appears exactly ONCE. Edit the
existing row in place; never append a second row for a requirement.
`check-requirement-ids.sh` does not catch a duplicate, and the
register becomes ambiguous.

```
| {id} | {exercised by} | {record} | {date} | {PROVEN | PARTIAL | NOT PROVEN, the last two linked to known-gaps.md} |
```

**Runs** -- append under the right section. Each section has its own
column set, so read the header above the table rather than assuming:

```
| Run | Repo | Date | Verdict | Independent verification | Cost |     <- enforce-conventional-commits
| Run | Date | Title produced | Verdict | Independent verification |  <- write-pr-title
| Run | Split | Names | Model | Result |                              <- trigger gates
```

The independent-verification cell carries the step-2 output, trimmed
to the fields actually asserted, and NAMES the endpoint or command it
came from so a later reader can re-run it. That is what makes the
verdict checkable later.

For a trigger-gate row, record the CLI version and the model. A score
is comparable only to another score taken on the same model.

Verify: grep the coverage table and confirm each touched id still
appears exactly once.

### Step 7 - Target 3 of 4: known-gaps.md

**This is the easy step to skip and the expensive step to skip.**
Nothing breaks when it is skipped. An untested branch and a tested
one look identical in the source, so a gap nobody wrote down is a gap
nobody will find. Run this step even when the campaign opened and
closed nothing, and say so in the report rather than saying nothing.

A gap the campaign CLOSED moves: delete its row here, and what would
have closed it becomes the exercised-by cell in the coverage row from
step 6. Do not leave it in both -- a gap listed in both places is a
register contradicting itself.

A gap the campaign TOUCHED without closing keeps its row. Edit its
"What is unproven" cell to say what was observed and why that does
not close it. A method gap whose wording the campaign made
inaccurate -- a count of runs, a list of baselines -- is edited the
same way.

A gap the campaign REVEALED gets a new row with every cell filled,
and what would close it must be an executable sentence naming the
scenario, account, or artifact it needs. Not "test it".

Three tables; pick by kind. A requirement id goes under "Untested
requirements". A whole configuration never tried goes under "Untested
configurations". A limit on what any evidence can claim goes under
"Method gaps".

When a gap closes, grep `docs/devs/test-repos.md` for its id. That
file mentions gaps in its prose, so closing one can leave a sentence
there saying the behavior is untested. It is not a write target, so
do not edit it: name each stale sentence in the step-10 report.

Verify: no id appears both in a known-gaps row and as PROVEN in the
step-6 coverage table. Run it; do not check by eye:

```
ids=$(grep -oE '^\| (INV|A-R|B-R)[0-9]+ \|' docs/devs/known-gaps.md | tr -d '| ')
echo "known-gaps requirement rows: $(echo $ids | wc -w)"
for id in $ids; do
  grep -E "^\| $id \|.*\| PROVEN[^|]*\|$" docs/devs/evidence.md >/dev/null && echo "CONFLICT: $id"
done
```

Any CONFLICT line is a failure. So is a row count that does not
match the number of rows in "Untested requirements": that means the
pattern stopped matching, and a loop over zero ids would print
nothing and look clean.

### Step 8 - Target 4 of 4: behavior-spec.md and the eval requirements

This target has two independent triggers. The spec and the
`requirements` arrays change only if the contract MOVED -- if what
must be true changed, not if the wording did. A falsified prediction
is recorded whether or not the contract moved; see the end of this
step.

Requirement ids are stable. Add a new id, or mark an existing one
withdrawn. Never renumber and never reuse: `evidence.md`,
`known-gaps.md`, `test-repos.md`, and both eval files cite by id, and
the backstop fails on a citation that stops resolving. A new id is
DEFINED by a table row whose first cell is the bare id; a mention in
prose elsewhere is a citation, not a definition.

Then update the `requirements` array of every content eval the
campaign ran, so it cites the ids actually exercised.

**A falsified prediction is recorded, not deleted.** Leave
`baseline_failure_modes` as written and add or extend
`baseline_failure_modes_measured` with the date, what was measured
false, and what the value turned out to be instead. A falsified
prediction is a result, and it is only legible when the prediction is
left in place beside the measurement.

Verify: both eval files still parse.

```
bash tests/lint-skills.sh
```

### Step 9 - Backstop

```
bash tests/check-requirement-ids.sh
bash tests/check-links.sh
```

Run the second only if a markdown link was added or changed.

Verify by reading the summary line yourself. A run with no summary
line is a run you did not see -- do not report the campaign absorbed
on anything else.

If the check fails, fix the register, never the check. Widening a
check is a one-line edit that turns the output green and deletes the
guarantee.

This backstop is real rather than ceremonial: it fails on a citation
that stops resolving, and on a requirement the evidence register has
gone quiet about. It cannot detect a fabricated read-back. Step 2 is
the only defence against that one.

### Step 10 - Report

```markdown
## Campaign absorbed: {name}, {date}

| Target | Rows | Detail |
|---|---|---|
| findings.md | {n} | {ids | none} |
| evidence.md | {n} coverage, {n} runs | {ids} |
| known-gaps.md | {n closed, n opened | none opened or closed} | {ids} |
| spec and evals | {n | the contract did not move} | {ids} |

Independent verification: {obtained live this session | NOT OBTAINED
for {ids} -- {why}}

    {per requirement: the command, then its output verbatim}

Read-back contradictions: {none | per field: runner said X, live
read returned Y}

Backstop: check-requirement-ids.sh -> {verbatim summary line}
Falsified predictions: {none | eval {id}, recorded as
baseline_failure_modes_measured}
Stale outside the targets: {none | file: the sentence and why}
Release impact: {none | the contract moved -- gates 3 and 4 re-arm,
and the next release is at least a {minor | major}}
```
