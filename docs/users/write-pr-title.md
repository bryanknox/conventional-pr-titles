# write-pr-title

The `write-pr-title` skill creates or updates a GitHub pull request so its **title** is a valid
Conventional Commits message, composed from what the branch actually
changed.

Use it on every pull request.

## Who can run it

| | |
|---|---|
| Intended user | Anyone who can open a pull request |
| Permission | Push to a branch or fork. Retitling *someone else's* PR needs `triage` or higher. |
| gh scopes | `repo` -- gh's default, nothing extra |
| If you lack permission | It still composes the title and tells you what it could not apply, and who can |

## What to say

Any of these reach it:

> Open a PR for this change.
>
> The PR Title check is failing -- fix the title.
>
> What type should this change be, feat or fix?

It works from your current branch, or from a pull request number if
you name one.

## What it does

Reads the diff between your branch and the default branch -- not your
commit messages, which it treats as hints rather than truth -- and
classifies the change. Then it writes a title of the form:

```
type(scope)!: description
```

- **type** is one of the ten standard types: `feat`, `fix`, `docs`,
  `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
- **(scope)** is optional, a short noun for the area touched. It is
  omitted rather than invented.
- **!** appears only for breaking changes, which also get a
  `BREAKING CHANGE:` footer as the last paragraph of the PR body.
- **description** is imperative ("add", not "added"), lowercase, no
  trailing period.
- The whole title stays within 72 characters.

Then it creates or updates the PR, reads the title back to confirm it
applied, and -- in a repository that has the PR-title check -- waits
for that check specifically and reports the result.

## What it does not do

- It does not rewrite, squash, or lint the commits on your branch.
  Those stay exactly as you wrote them, by design.
- It does not configure the repository. If it notices the PR-title
  check is missing it says so and suggests an admin run
  [enforce-conventional-commits](enforce-conventional-commits.md), but it
  will not do that itself.
- It waits only for the PR-title check, not your build or tests.

## When it asks before acting

Creating a fresh pull request needs no approval.

It checks with you first when it is about to retitle a pull request
whose title it did not write this session, or one belonging to
someone else. You see the old title, the new title, and a one-line
reason for the type before anything changes.

Naming the PR yourself is itself the approval -- "fix the title on
PR 5" gets applied directly, with the before and after shown in the
report.

## In a repository without the setup

It still works. You get a properly composed title applied to the pull
request; it just skips waiting for a check that does not exist, and
notes in its report that the repository does not enforce titles.

## One thing worth knowing about squash settings

GitHub's default squash setting is `COMMIT_OR_PR_TITLE`, which uses
your PR title only when the PR has **more than one commit**. A
single-commit PR squashes using that commit's own message instead --
so a carefully composed title can be quietly discarded.

[enforce-conventional-commits](enforce-conventional-commits.md) sets this
to `PR_TITLE`, which always uses the title. This skill reads the
setting and tells you which behavior is in effect, but never changes
it -- that is repository configuration, not title authoring.

The same setting decides whether a `BREAKING CHANGE:` footer in the
PR body rides along into the squash commit. It does so only when the
squash message is set to the PR body.

When it does ride along, it rides along editable. The merge box
prefills the commit body from the PR body and lets whoever merges
change it, and no check ever reads a body -- the title workflow
lints the title only. So treat the footer as documentation and the
`!` in the title as the enforced part. That is why the skill writes
both, and why it says which setting is in effect rather than
leaving you to guess whether the footer survived.

## If the check fails

It reads the check's actual complaint, corrects the title, and
re-checks -- up to two attempts. After that it stops and shows you
the complaint verbatim rather than guessing further.

## Choosing a type

For the decision rules, the tie-breakers, and what counts as
breaking, see the
[conventional commits guide](conventional-commits-guide.md). The
skill carries a condensed version of the same rules and consults it
whenever a change fits more than one type or none cleanly.
