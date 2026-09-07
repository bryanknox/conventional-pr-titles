# Releasing

How a change to a skill reaches the people using it.

Much of this is forward-looking: the publishing mechanism arrives in
phase 8 of [refactor-plan.md](refactor-plan.md). What is true today
is marked as such.

## What "done" means

A skill change is not done because it reads well. The gates, in the
order they get cheaper to run:

**1. Structural checks.** Frontmatter, naming, ASCII, wrapping,
self-containment. Currently a manual read against
[authoring.md](authoring.md). Enforced by CI on every pull request;
run the same checks locally with the commands in
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

## How users get it today

By copying the skill folder, as described in
[the install guide](../users/install.md). There is no version
number, no update mechanism, and no way to tell an installed copy
from a newer one.

That is acceptable while the audience is the author, and it is the
main thing phase 8 fixes.

## How users will get it

Phase 8 makes this repository a Claude Code plugin and its own
marketplace. Two files:

- `.claude-plugin/plugin.json` -- the plugin manifest. `skills/` at
  the repository root is already the layout it expects, so no files
  move.
- `.claude-plugin/marketplace.json` -- a catalog listing the plugin,
  with `"source": "./"`.

Users then run `/plugin marketplace add bryanknox/skills-thrill`
once, and `/plugin install` from it. Updates arrive without anyone
copying folders.

### The versioning trap

If `plugin.json` declares a `version` and it is not bumped, users
keep their cached copy no matter what else changed. New commits
alone do not reach them.

So: **bump `version` on every release, or omit the field entirely**
and let the resolved commit be the version. Picking one and holding
to it matters more than which one.

### Validate before publishing

```
claude plugin validate .
```

Add `--strict` to treat warnings as errors. Worth wiring into CI
alongside the structural lint once the manifests exist.

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
