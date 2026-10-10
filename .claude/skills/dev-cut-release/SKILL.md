---
name: dev-cut-release
description: >-
  Use this skill in the conventional-pr-titles repository to cut a
  release of the plugin: bump the version, prepare or open the
  release PR, or tag a merged release. Reads what shipped under
  skills/ since the last tag, reports which release gates apply,
  bumps version in plugin.json and marketplace.json together, runs
  tier 1 and claude plugin validate on each manifest by name, and
  opens the bump PR. The maintainer must state the bump size.
  Maintainer-only: does NOT choose the bump, does NOT run evals, does
  NOT run claude plugin tag (it hands the command over and reads the
  tag back), and does NOT absorb campaigns or touch test
  repositories.
---

# Cut a Release (version bump, PR, tag read-back)

A skill change reaches nobody until the version moves. An unbumped
version is the one failure that is silent end to end: installed
copies stay cached no matter what else changed. This skill performs
the bump and everything around it that a session gets wrong when it
summarises.

`docs/devs/release.md` is the authority for this procedure; this
skill is the enforcement. Where the two disagree the page wins --
stop and say so rather than reconciling them here.

Boundaries: this skill does NOT decide the bump size, does NOT run
evals or decide whether a gate has been met, and does NOT run
`claude plugin tag`. It does not merge the PR. Each of those is the
maintainer's, because each is either a judgement or a one-way step.

## Who can run this

| | |
|---|---|
| Intended user | The maintainer, working in this repository |
| Runs how often | Twice per release: once to open the bump PR, once after it merges |
| Mutates | The `version` field in both manifests, a `release/v{new}` branch, one PR |
| Does not touch | Anything under `skills/`, the registers, the tag, GitHub settings, the test repos |
| On a bump size not stated | Stop and ask, with the evidence -- never default to one |

## Two phases, chosen by reading state

The same request -- "cut a release" -- means different work before
and after the bump PR merges. Do not ask which phase it is. Read it.

### Step 0 - Detect the phase (read-only)

```
git fetch origin
git tag --list 'conventional-pr-titles--v*' --sort=-v:refname
git show origin/main:.claude-plugin/plugin.json | grep '"version"'
git show origin/main:.claude-plugin/marketplace.json | grep '"version"'
```

The first line of the tag list is the last release. Its version is
the part after `--v`.

| What the reads show | Phase |
|---|---|
| Both manifests equal the last tag's version | Prepare (steps 1 to 10) |
| Both manifests agree and are higher than the last tag | Tag (steps T1 to T3) |
| The manifests disagree, or are lower than the last tag | Stop and report -- something edited them by hand |

## Prepare phase

Every fact comes from a `git` or `gh` read made now. Run each
command on its own, never chained with `&&` and never under
`set -e`: a non-zero exit is an answer here, and chaining throws
away every read after the first. Nothing is written before the
checkpoint in step 6 is approved.

### Step 1 - Preflight (read-only)

```
git status --porcelain
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD origin/main
gh auth status
claude --version
gh pr list --state open --search 'release in:title' --json number,title,headRefName
```

Required: an empty status, `main` checked out, `HEAD` equal to
`origin/main`, and no open release PR. Any miss stops the run with
the read that failed. Record the `claude --version` output; a
validate result is only comparable to another taken on the same CLI.

### Step 2 - Read what shipped since the tag

```
git log --oneline {tag}..HEAD -- skills/ .claude-plugin/plugin.json
git diff --stat {tag}..HEAD -- skills/ .claude-plugin/plugin.json
git log --oneline {tag}..HEAD -- docs/devs/behavior-spec.md docs/users/
git ls-tree --name-only {tag} skills/
git ls-tree --name-only HEAD skills/
```

If the first command prints nothing, stop: nothing that ships has
changed, and there is nothing to release.

For each skill directory, compare the frontmatter `description` at
the tag with the one at `HEAD`:

```
git show {tag}:skills/{name}/SKILL.md | sed -n '1,/^---$/p'
sed -n '1,/^---$/p' skills/{name}/SKILL.md
```

Read the directory list at both points first. A skill renamed since
the tag has a different `{name}` on each side, and a removed or
added directory is itself a release-relevant change.

Classify, do not judge:

- **Description changed** -- yes or no, per skill, with the diff.
- **Spec or user docs changed** -- yes or no, with the commits that
  changed them. This is a candidate, not a verdict. A restructure
  of the spec moves the file without moving the contract, so a
  "yes" here does not mean the contract moved. Show the commits and
  leave the call to the maintainer.

### Step 3 - Report which gates apply

From "What done means" in `docs/devs/release.md`:

| Gate | Applies when |
|---|---|
| 1 - structural checks | always |
| 2 - trigger checks | a description changed |
| 3 - a real run | the maintainer judges that the contract moved |
| 4 - a baseline run | as gate 3, and the change is substantial |

Gates 3 and 4 depend on a judgement this skill does not make. Report
each one as "applies if the contract moved". Point to the step-2
commits as the place to decide, rather than answering yes or no.

For gates 2 to 4, find the evidence that exists:

```
git log --format='%cs %h %s' {tag}..HEAD -- skills/ | tail -n 1
grep -n '^| ' docs/devs/evidence.md
```

The first line is the earliest commit since the tag that touched
`skills/`. List every runs row in `evidence.md` dated on or after
it, under the gate it bears on. If there are none, say "none
recorded".

Whether those runs satisfy the gate is the maintainer's call, not
this skill's. Present them; do not grade them.

### Step 4 - The bump size

It comes from the maintainer's prompt. If the prompt did not state
patch, minor, or major, stop here: show the step-2 classification,
the step-3 gate table, and the table below, and ask. Never pick one
because it looks obvious.

| Change | Bump |
|---|---|
| Rewording that leaves behavior and triggers alone | patch |
| A new capability, or a widened description | minor |
| A removed capability, a narrowed description, or a changed default | major |

**A narrowed description is a major.** Nothing about the behavior
changed, so nothing in the diff looks breaking -- which is exactly
why a session will not infer it. Prompts that used to invoke the
skill stop doing so, and that is indistinguishable from removal.

Two combinations always go to the checkpoint for explicit
acknowledgment. The stated size is not overridden either way:

- A description changed and the stated bump is patch or minor.
  Name the skill and show the description diff.
- The spec or user docs changed and the stated bump is patch. Ask
  whether the contract moved; do not assume either answer.

### Step 5 - Fail before mutating

Run tier 1, each command separately, and read each summary line.

```
bash tests/lint-skills.sh
bash tests/lint-skills.sh .claude/skills 'dev-*'
bash tests/check-links.sh
bash tests/check-workflow-template.sh
bash tests/check-plugin-manifests.sh
bash tests/check-requirement-ids.sh
bash tests/check-skill-inventory.sh
```

Then validate both manifests with the real thing:

```
claude plugin validate .claude-plugin/plugin.json
claude plugin validate .claude-plugin/marketplace.json --strict
```

**Name the plugin manifest explicitly.** `claude plugin validate .`
validates the marketplace manifest instead and passes, so "validation
passed" becomes a true sentence about a command that never looked at
`plugin.json`.

**Read the warning list, not the verdict.** Exactly one warning is
expected on the first command: that `CLAUDE.md` at the plugin root
is not loaded as project context. Copy the warning list verbatim
into the report. A second warning is the signal, and a summary is
exactly what drops it. Any failure, or any warning other than the
expected one, stops the run here.

### Step 6 - Checkpoint (human approval)

Present everything the run will do as ONE reviewable block, then
wait:

- the old version and the new one
- the two edits: `version` in `.claude-plugin/plugin.json`, and in
  the `conventional-pr-titles` entry of
  `.claude-plugin/marketplace.json`
- the branch: `release/v{new}`
- the commit subject and PR title: `chore: release {new}`
- the PR body: the step-2 commit list, the step-3 gate table with
  its evidence, the step-5 warning list verbatim
- any step-4 combination that needs acknowledgment, stated as such

One approval covering everything, not one per step. A skill that
asks repeatedly trains people to approve without reading.

### Step 7 - Bump both manifests

Edit only the `version` value, in both files, to the same string.
Touch nothing else in either file.

### Step 8 - Read back the bump

```
git diff --stat
git diff .claude-plugin/
bash tests/check-plugin-manifests.sh
claude plugin validate .claude-plugin/plugin.json
claude plugin validate .claude-plugin/marketplace.json --strict
```

Required: exactly two files changed, one line each, and both read
the new version. The warning list matches step 5. If anything
differs, stop with the working tree as it is and report -- nothing
has left the machine yet.

### Step 9 - Branch, commit, push, open the PR

```
git switch -c release/v{new}
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: release {new}"
git push -u origin release/v{new}
gh pr create --base main --title "chore: release {new}" --body-file {body}
```

Then read the PR back from GitHub, not from the commands above:

```
gh pr view --json number,url,title,headRefName,baseRefName,files
gh pr diff
```

Required: the title is exactly the one approved, the base is
`main`, and the diff is the two `version` lines and nothing else.

### Step 10 - Report and stop

The merge is the maintainer's. Say that the tag phase is the next
invocation, after the merge, and stop.

## Tag phase

The PR has merged, so `main` carries a version the tags do not.

### Step T1 - Preflight (read-only)

```
git switch main
git pull --ff-only
git status --porcelain
git rev-parse HEAD origin/main
grep '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json
git ls-remote --tags origin 'conventional-pr-titles--v{ver}'
```

Required: a clean tree, `HEAD` equal to `origin/main`, the two
manifests agreeing, and an EMPTY `ls-remote` -- the tag does not
exist yet. If it already exists, stop: someone tagged already, and
step T3 is the only thing left to do.

### Step T2 - Hand over the one-way step

```
claude plugin tag . --push
```

**Do not run it.** Give it to the maintainer with what it will do:
create and push `conventional-pr-titles--v{ver}` at the current
`HEAD`, after checking that the manifests agree and the tree is
clean. A pushed tag is what installers resolve against, and it is
the one step here that is not undone by closing a PR. Wait until
the maintainer says it has run.

### Step T3 - Read back the tag

```
git fetch --tags origin
git ls-remote --tags origin 'conventional-pr-titles--v{ver}'
git rev-parse 'conventional-pr-titles--v{ver}^{commit}'
git rev-parse origin/main
```

Required: the tag exists on the remote and points at the same commit
as `origin/main`. Report the three outputs verbatim. If the tag is
missing or points elsewhere, say so; do not retag.

## Report

```markdown
## Release {prepare | tag}: {old} -> {new}, {date}

Last tag: {tag}    CLI: {claude --version}

Shipped since the tag:
    {step-2 git log --oneline, verbatim}

| Gate | Applies | Evidence recorded since {date} |
|---|---|---|
| 1 | yes | tier 1 this run: {n}/7 green |
| 2 | {yes | no} | {evidence.md rows | none recorded} |
| 3 | {if the contract moved | no} | {evidence.md rows | none recorded} |
| 4 | {if the contract moved | no} | {evidence.md rows | none recorded} |

Bump: {size}, stated by the maintainer
Needs acknowledgment: {none | each step-4 combination}

Tier 1: {each summary line, verbatim}
Validate warnings: {the list, verbatim}

{prepare} PR: {url} -- read back: title, base, and a diff of
two version lines
{tag} Tag: {ls-remote line} -- {matches | does NOT match}
origin/main {sha}

Next: {merge the PR, then invoke again for the tag phase |
remove this release's row from docs/devs/next-steps.md and
update its dev-cut-release note, in a docs PR}
```
