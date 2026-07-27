# Desires for Conventional Comments Setup

## Top-level desires

Top-level desires for conventional commits in a GitHub repos for a .NET application.

- Try to keep tooling in .NET
- Prevent push to main
- Enforce Squash-merge PRs
  - The PR title becomes the conventional commit message on main
	- Enforce the PR title, not individual commits.
- So, no conventional commits enforcement on branches

## Desired agent skills to develop

1. Skill: Scaffolding a GitHub repo for a .NET app to use conventional commits.
2. Skill: Create or update a GitHub PR to use conventional commits
	 - The PR title becomes the conventional commit message on main
   - Used in squash merge scenarios

## Constraints

- The agent skills and workflows developed will be used in GitHub repos within personal accounts.
- We want to support public repos in personal accounts.
- But accomodate private repos in personal accounts where we can. Even if gaps or limiations in available settings, rulesets, and other enforcement mechanisms may be missing.
