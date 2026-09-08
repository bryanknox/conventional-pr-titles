# Releasing

How a change to a skill reaches the people using it.

## What "done" means

A skill change is not done because it reads well. The gates, in the
order they get cheaper to run:

**1. Structural checks.** Frontmatter, naming, ASCII, wrapping,
self-containment, and the plugin manifests. Enforced by CI on every
pull request; run the same checks locally with the commands in
[testing.md](testing.md).

**2. Trigger checks, if the description changed.** Any edit to a
`description` can change which prompts invoke the skill without
changing a word of its behavior. Re-score the validation split.

**3. A real run, if behavior changed.** Against a real GitHub
repository, with the outcome verified by reading state back --
not by trusting the transcript. Procedures in
[test-repos.md](test-repos.md).

**4. A baseline run, for anything substantial.** The same task
without the skill installed. If the results are indistinguishable,
the change is not earning its place.

Wording-only edits need 1. Description edits need 1 and 2. Behavior
changes need all four.

## How users get it

This repository is a Claude Code plugin and its own marketplace. Two
manifests, both in `.claude-plugin/`:

- `plugin.json` -- what ships. `skills/` at the repository root is
  already the layout it expects, so the manifest names no paths and
  no files moved to create it.
- `marketplace.json` -- the catalog, listing this plugin with
  `"source": "./"`.

Users add the marketplace once and install from it; see
[the install guide](../users/install.md) for the commands. Updates
then arrive through `claude plugin update` rather than by copying
folders.

Copying the skill folder by hand still works and is documented as
the fallback, because a marketplace entry pointing at a private
repository resolves only for someone who can already read it. That
constraint is [decision 0009](decisions/0009-stay-private-for-now.md),
not a property of the packaging.

## Cutting a release

**1. Bump `version` in `plugin.json` and in the matching
`marketplace.json` entry.** Both, to the same value -- the manifest
check and `claude plugin tag` each refuse a mismatch. What size of
bump is the table below.

An unbumped version is the one failure that is silent end to end:
installed copies stay cached no matter what else changed, and new
commits alone reach nobody. The reasoning for declaring a version
at all, rather than dodging that trap by omitting the field, is
[decision 0010](decisions/0010-declare-a-plugin-version.md).

**2. Validate both manifests with the real thing.**

```
claude plugin validate .claude-plugin/plugin.json
claude plugin validate .claude-plugin/marketplace.json --strict
```

Name the plugin manifest explicitly. Passing the directory
(`claude plugin validate .`) checks the *marketplace* manifest
instead, because that is what the command prefers when both are
present -- so the plugin manifest goes unchecked and the command
still says it passed.

That first command is deliberately not `--strict`. It emits one
warning: `CLAUDE.md at the plugin root is not loaded as project
context`. The warning is correct and inapplicable -- this
repository is both the plugin and the workspace that develops it,
and `CLAUDE.md` is maintainer instructions that are deliberately
not shipped as context. Read the warning list rather than
silencing it; a *second* warning appearing there is a real signal.

CI does not run these. It runs
[`tests/check-plugin-manifests.sh`](../../tests/check-plugin-manifests.sh),
which is offline and covers the couplings this repository owns --
see [testing.md](testing.md) for why the split is drawn there.

**3. Merge, then tag.**

```
claude plugin tag . --push
```

That creates `skills-thrill--v{version}`, after checking that the
manifests agree and the tree is clean.

## Versioning the skills

Semantic versioning against the *user-visible contract*, which for a
skill means what it does and when it triggers -- not how the body is
worded.

| Change | Bump |
|---|---|
| Rewording that leaves behavior and triggers alone | patch |
| A new capability, or a widened description | minor |
| A removed capability, a narrowed description, or a changed default | major |

A **narrowed description is a breaking change** even though nothing
about the behavior changed. Prompts that used to invoke the skill
stop doing so, which is indistinguishable from removal for the
people relying on it.

One version covers both skills, because one plugin ships both. A
patch to one skill therefore bumps the number the other skill's
users see too. That is the cost of a single package, and it is the
right trade while the two skills are released together; splitting
into two plugins is the fix if it ever stops being.

## Notes for later

Deferred deliberately, recorded so the reasoning is not lost:

- **A separate marketplace repository.** Worth doing once there is a
  second unrelated plugin or an outside collaborator. Until then a
  self-catalogued repository is simpler, and the migration is cheap
  because the plugin layout does not change. A marketplace entry can
  point at another repository pinned by tag or commit, which makes
  "publish a vetted version" a one-line diff.
- **Other harnesses.** The skills are already portable; only
  distribution is Claude Code specific. `.agents/skills/` covers
  Cursor, Codex, and Copilot, so it is a two-directory install
  rather than four.
- **Going public.** Currently private, which blocks this repository
  from getting its own ruleset and limits installation to accounts
  that can already read it. The reasoning, and the ordered steps
  for reversing it, are in
  [decision 0009](decisions/0009-stay-private-for-now.md).
