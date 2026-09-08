# Conventional commits skills

Two agent skills that keep a GitHub repository's history readable by
making every commit on the default branch a valid
[Conventional Commits](https://www.conventionalcommits.org/) message.

They work as a pair and ship as one plugin, but each is useful
on its own and neither needs the other at runtime.

## The idea in one paragraph

The repository is configured so squash is the only merge method, and
the pull request title becomes the commit message on the default
branch. That makes the PR title the single enforcement point. Commits
on your branch stay completely unconstrained -- no hooks, no commit
linting, no tooling in your local clone. Write whatever you like while
you work; the title at merge time is the only thing that has to be
correct.

## Which one do you want?

| | [setup-conventional-commits](setup-conventional-commits.md) | [pr-conventional-commits](pr-conventional-commits.md) |
|---|---|---|
| Does | Configures a repository to enforce conventional PR titles | Writes the PR title, from the actual diff |
| For | The repository owner or an admin | Anyone who opens pull requests |
| Needs | `admin` on the repo; `gh` with `repo` + `workflow` scopes | Push access; `gh` with the default `repo` scope |
| Run | Once per repository | Every pull request |

If you are joining a repository someone else already configured, you
only need **pr-conventional-commits**. Installing the plugin brings
both; the one you do not need costs you nothing, because a skill
that is never triggered is never read.

If you are setting up your own repository, run
**setup-conventional-commits** once, then use
**pr-conventional-commits** from then on.

## Getting started

1. [Install](install.md) -- one plugin, currently Claude Code
   only. Copying a single skill folder also works.
2. Read the page for the skill you need (linked in the table above).
3. Ask for what you want in plain language. Both skills are triggered
   by description matching, not by a command you have to memorize:
   "set this repo up for conventional commits", "open a PR for this
   change", "what type should this be, feat or fix?"

## Doing it without the skills

The skills automate a setup you can also do by hand, and a convention
you can also follow by hand. Both are written up in
[the conventional commits guide](conventional-commits-guide.md):
the three levels of repository configuration, the ten commit types,
how they map to semantic versioning, and how to mark breaking
changes.

Read that guide if you want to understand what the skills are doing,
review what they changed, or follow the convention in a repository
where the skills are not installed.
