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
