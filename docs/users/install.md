# Installing

These skills currently target **Claude Code**. Support for Cursor,
Codex, and GitHub Copilot is planned but not built; nothing in either
skill is Claude-specific, so adding it later is a packaging change
rather than a rewrite.

Two ways in. Install the plugin unless you have a reason not to --
it is one command, it names a version, and it updates.

## Install the plugin

This repository is its own marketplace. Add it once:

```
claude plugin marketplace add bryanknox/skills-thrill
claude plugin install skills-thrill@skills-thrill
```

The repeated name is not a typo: the marketplace and the plugin
inside it share the repository's name. `claude plugin install
skills-thrill` also works while no other marketplace offers a plugin
by that name.

The same two steps are available inside a session as
`/plugin marketplace add bryanknox/skills-thrill` and
`/plugin install`, which lists what the marketplace offers rather
than making you type the name.

Both skills arrive together -- one plugin, two skills -- and they
are available in every project, not just the one you were in.

`--scope project` on the install writes the choice into the
repository's settings instead of your user settings, so anyone who
clones it is offered the same plugin.

### It is a private repository

Installation resolves the marketplace by cloning it, so it works
only for an account that can already read
`bryanknox/skills-thrill`. If the clone fails with a not-found
error, that is what it means -- the repository is not missing, you
are not on the list. Check with:

```
gh repo view bryanknox/skills-thrill
```

Copying the folders, below, needs the same access. There is no
install path that does not.

### Updating

```
claude plugin update skills-thrill
```

Restart the session to pick it up. Updates arrive when the version
in the plugin's manifest changes, so a release that forgot to bump
it will not reach you -- there is no way to tell that apart from
"nothing changed" from this side.

`claude plugin list` shows what you have installed and at which
version.

## Or copy the folders

Nothing about the skills requires the plugin. Each is one folder,
and Claude Code reads them straight off disk.

Copy the **whole** folder -- the skills read their own bundled files
at runtime, so a lone `SKILL.md` will not work.

```
skills/setup-conventional-commits/
  SKILL.md
  assets/pr-title-workflow.yml        <- committed into your repo

skills/pr-conventional-commits/
  SKILL.md
  references/type-guide.md            <- read when a type is ambiguous
```

### Where to put it

| Scope | Path | Available in | Shared with |
|---|---|---|---|
| Personal | `~/.claude/skills/<name>/` | all your projects | just you |
| Project | `<repo>/.claude/skills/<name>/` | that one repository | anyone who clones it, if committed |

If both exist with the same name, the personal copy wins.

**Personal** is the right choice for `pr-conventional-commits`: you
open pull requests in many repositories and want it everywhere.

**Project** is the right choice when you want everyone working in a
repository to have the skill without installing anything -- commit
`.claude/skills/pr-conventional-commits/` and it travels with the
clone.

`setup-conventional-commits` runs once per repository and only an
admin can use it, so personal scope is usually enough.

### Copy commands

Clone or download this repository first, then from its root:

PowerShell:

```powershell
$dest = "$HOME\.claude\skills"
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item -Recurse -Force skills\pr-conventional-commits $dest
Copy-Item -Recurse -Force skills\setup-conventional-commits $dest
```

Bash:

```bash
dest=~/.claude/skills
mkdir -p "$dest"
cp -r skills/pr-conventional-commits "$dest"
cp -r skills/setup-conventional-commits "$dest"
```

For project scope, use `<your-repo>/.claude/skills` as the
destination instead.

A copy has no version and no update path. When something here
changes, you find out by noticing, and you fix it by copying again.
That is the trade for taking one skill rather than two.

## Checking that it worked

Claude Code watches its skill directories and picks up changes during
a session, so a copied skill usually needs no restart. A plugin
install or update does.

Neither skill has a command you type. They dispatch on the
description matching what you ask for, so the test is to ask for
something in the skill's territory and see whether it engages:

```
what type should this change be, feat or fix?
```

should invoke `pr-conventional-commits`, and:

```
set this repo up for conventional commits with squash merges
```

should invoke `setup-conventional-commits`.

If nothing happens after a plugin install, check `claude plugin list`
shows `skills-thrill` enabled. If nothing happens after a copy,
confirm the folder name matches the `name` in the `SKILL.md`
frontmatter, and that `SKILL.md` sits directly inside the skill
folder rather than in a subdirectory.

## Prerequisites

Both skills drive the GitHub CLI. You need `gh` installed and
authenticated:

```
gh auth status
```

- `pr-conventional-commits` works with gh's default `repo` scope.
- `setup-conventional-commits` also needs `workflow`, because it
  commits a workflow file. If it is missing, the skill stops before
  changing anything and tells you to run
  `gh auth refresh -h github.com -s repo,workflow`.

## Working on the skills themselves

If you are developing these skills rather than using them, do not
install or copy them. See the
[contributor documentation](../devs/) instead.
