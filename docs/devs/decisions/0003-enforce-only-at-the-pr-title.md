# 0003 - Enforce only at the pull request title

**Decision:** the pull request title at squash-merge time is the
only enforcement point. Commits on branches are never checked. No
git hooks, no commit-message linter, no tooling installed in
anyone's clone.

Originates directly in
[the original requirements](0001-original-requirements.md):
"Enforce the PR title, not individual commits."

## Why it works

Squash is configured as the only merge method, so every pull request
becomes exactly one commit on the default branch, and that commit's
message is the pull request title. Linting the title is therefore
identical to linting the history -- there is no gap between them.

## What is given up

Conventional commit messages on branches. In a squash-merge
repository nobody reads those after the merge, so the loss is close
to theoretical.

## What is gained

- **Server-side enforcement.** It cannot be bypassed by a
  contributor with a misconfigured clone, and it applies to
  everyone automatically, including people who have never heard of
  this repository.
- **Zero local setup.** No dependency added to the project, nothing
  to install, nothing to keep in sync, nothing that breaks for
  someone on a different operating system.
- **Nothing to maintain.** A commit-hook toolchain is a thing that
  rots. This is three settings, one ruleset, and a workflow file.

## The absence of a fourth level

Skill A's documentation names three levels and then explicitly says
there is no Level 4. That statement is load-bearing: without it,
"add commit hooks" reads as an obvious missing feature rather than a
decision. Anyone proposing local commit tooling should reverse this
decision deliberately, not incidentally.

## Known residual weakness

GitHub's merge box lets whoever clicks Merge hand-edit the final
squash message, and nothing validates that edit. The prefilled text
is the title the check approved.

This is unfixable within the approach and is documented rather than
hidden -- Skill A names it in its final report, and
[the user guide](../../users/conventional-commits-guide.md) repeats
it. If it ever becomes a real problem, that is the signal to
reconsider this decision, not to bolt on a partial fix.

### What changes under PR_BODY

Level 1's target state sets `squash_merge_commit_message=BLANK`, so
the commit body is empty and the only text the merge box offers to
edit is one subject line. Users may instead choose `PR_BODY`, which
is what lets a `BREAKING CHANGE:` footer reach the commit. That
choice does not add a second weakness; it widens this one.

The merge box exposes an editable body field either way -- the
setting decides only what is prefilled into it.

- Under `BLANK`, the risk is text being **added** at merge time to
  a commit body that was meant to be empty.
- Under `PR_BODY`, the risk is text being **lost**. The footer that
  makes the change a MAJOR version bump arrives prefilled in an
  editable box, and deleting it is one keystroke away from a merger
  who reads the body as noise.

Two consequences of the same fact, worth stating plainly because
they are easy to assume away:

- The body reaching the merge box is the pull request body **as of
  merge**, not as of the check. Editing the body does re-run the
  Level 3 workflow -- `edited` fires for body edits too -- but that
  workflow lints the title. The body is validated by nothing, under
  either setting.
- A `BREAKING CHANGE:` footer is therefore advisory. The `!` in the
  title is the half enforcement covers, which is why the user guide
  tells authors to mark breaking changes both ways rather than
  relying on the footer alone.

Two fixes were considered and rejected. A title/body consistency
check in the Level 3 workflow is straightforward to write, but it
narrows the gap rather than closing it: the merge-box edit happens
after every check has reported. Ruleset commit-metadata
restrictions do not help either -- they are gated to GitHub
Enterprise organizations, and under squash they validate every
commit on the branch, which is the enforcement model this decision
exists to reject.
