# Authoring conventions

Rules a `SKILL.md` in this repository follows, with the reason for
each. Most are load-bearing; where a rule is only cosmetic, it says
so.

The mechanical ones are enforced by `tests/lint-skills.sh`; run it
before opening a pull request. See [testing.md](testing.md).

## Frontmatter

**Only `name` and `description`. Nothing else.**

```yaml
---
name: pr-conventional-commits
description: >-
  Use this skill when ...
---
```

This is not stylistic. `name` plus `description` is the exact
intersection of what Claude Code, Cursor, Codex, and GitHub Copilot
all accept. Adding `allowed-tools`, `model`, or `target` -- all of
which some harnesses support -- would make the skill non-portable
for the sake of a marginal gain.

The repository currently targets Claude Code only, but the skills
remain portable, so adding another harness later is a packaging
change rather than a rewrite. **One lint rule is the entire cost of
keeping that true.** Do not add a frontmatter key without deciding
to give this up.

**`name` must equal the directory name.** Harnesses differ on which
one wins when they disagree; keeping them identical means the
question never comes up.

## The description is the dispatch surface

A skill is invoked because its description matched what someone
asked for. The description is not a summary -- it is the trigger.

Both current descriptions run about 640 characters and contain four
things:

1. **When to use it**, in the phrasing users actually type.
2. **Indirect triggers** -- the situations that imply the skill
   without naming it ("protect main", "the PR Title check is
   failing").
3. **What it does**, concretely enough to distinguish it.
4. **What it does NOT do**, naming the sibling skill.

That fourth part earns its space. In trigger testing, the prompt
"add a PR title check" was the coin-flip risk between the two
skills; it dispatched correctly, and the boundary sentence appears
to be what carried it.

Changing a description means re-running the trigger evals. It is the
one edit that can silently break a skill without changing a word of
its behavior.

## Body conventions

| Rule | Why |
|---|---|
| ASCII only | Harnesses, terminals, and diff tools all handle it identically. Cosmetic, but free. |
| LF endings, final newline | Matches `.editorconfig`. Cosmetic. |
| No trailing whitespace | Cosmetic. |
| Prose wrapped at 72 columns | Readable diffs: a reworded sentence changes one line, not a paragraph. |

**The wrap rule applies to prose only.** Markdown table rows and
fenced code blocks are exempt -- a `gh api` invocation cannot be
wrapped without breaking it, and splitting a table row is not
possible. Of the 28 lines currently over 72 columns across both
skills, 27 are table rows or fenced commands.

The lint checks prose only, for exactly this reason. It found one
real violation when it was first run -- an 88-column line in
`setup-conventional-commits` -- which is now fixed.

## Self-containment

Everything a skill needs lives inside its own folder. No skill reads
a file outside its directory, and no skill reads another skill's
files.

Skills are distributed by copying one folder. A reference that
points outside it works in this repository and breaks the moment
someone installs the skill. That failure is invisible here, which is
what makes the rule worth stating.

The corollary: deliberate duplication between skills is correct when
the alternative is a cross-skill dependency. See
[decision 0005](decisions/0005-duplicate-the-type-list.md).

## Behavioral rules

These are properties of what the skill *does*, and they are the ones
worth being strict about.

**Read, do not remember.** Every fact about a repository, branch, or
pull request comes from a `git` or `gh` read at the moment it is
needed. Never from memory, never from earlier in the conversation.

**Verify every mutation.** After every change, read the state back
and confirm it. An API call returning success is not evidence the
intended thing happened.

**Fail before mutating, not during.** Check permissions and
preconditions in a preflight pass. A skill that gets halfway through
and stops has left the repository in a state nobody chose.

**One approval, covering everything.** Present the whole change as
one reviewable diff and wait. Do not ask per step -- a skill that
asks repeatedly trains people to approve without reading.

**Degrade with a report, do not guess.** When something is blocked,
do what remains possible, then say exactly what did not happen and
what would unblock it.

## Current sizes

Not limits, but the numbers to notice a jump from. Every line of a
skill body is context cost paid on each invocation.

| | Lines | Bytes | Description |
|---|---|---|---|
| `setup-conventional-commits/SKILL.md` | 346 | 14,952 | 641 chars |
| `pr-conventional-commits/SKILL.md` | 199 | 8,374 | 645 chars |
| `references/type-guide.md` | 65 | 2,454 | n/a, loaded on demand |

Skill A is larger because it carries API request shapes that have to
be exact. Skill B is deliberately lean: it runs on every pull
request, so its body is paid far more often.

Material a skill needs only *sometimes* belongs in a separate file
it reads on demand, the way the type guide is. That keeps the cost
off the common path.

## What does not belong in `skills/`

Evals, test procedures, validation records, and planning documents
are maintainer material. They have no runtime consumer, and shipping
them means every user pays context for them and the dispatcher sees
text that was never meant to be a trigger.

See
[decision 0008](decisions/0008-maintainer-material-outside-skill-folders.md).
