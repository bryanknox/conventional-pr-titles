# 0001 - The original requirements

The requirements the two skills were built against, preserved
because later decisions only make sense against them.

Original context: setting up GitHub repositories for a .NET
application, in a personal account.

## What was wanted

- Prevent pushes directly to `main`.
- Enforce squash-merge pull requests, where the pull request title
  becomes the conventional commit message on `main`.
- **Enforce the pull request title, not individual commits.** No
  conventional-commit enforcement on branches.
- Keep tooling in .NET where tooling was needed at all.

## Constraints

- The skills would be used in repositories under **personal**
  GitHub accounts.
- **Public** repositories in personal accounts: fully supported.
- **Private** repositories in personal accounts: accommodate where
  possible, and accept that some settings, rulesets, and
  enforcement mechanisms may be unavailable.

## What this shaped

The "enforce the title, not the commits" requirement is the origin
of [decision 0003](0003-enforce-only-at-the-pr-title.md), and
through it the absence of any local tooling.

The private-repository constraint is why Skill A detects the
GitHub Pro ruleset gate and degrades rather than failing. That
turned out to matter more than expected: the gate is absolute, not
partial. Every ruleset endpoint returns 403 on a free-plan private
personal repository.

The "keep tooling in .NET" preference became moot. The design that
satisfied the other requirements needs no project-level tooling at
all, in any language -- the whole footprint is GitHub settings, one
ruleset, and one workflow file. Nothing in either skill is
.NET-specific; .NET appears in Skill A's description only as an
indirect trigger phrase.
