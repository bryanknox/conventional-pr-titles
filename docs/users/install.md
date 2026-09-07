# Installing

These skills currently target **Claude Code**. Support for Cursor,
Codex, and GitHub Copilot is planned but not built; nothing in either
skill is Claude-specific, so adding it later is a packaging change
rather than a rewrite.

## What to copy

Each skill is one folder. Copy the whole folder -- the skills read
their own bundled files at runtime, so a lone `SKILL.md` will not
work.

```
skills/setup-conventional-commits/
  SKILL.md
  assets/pr-title-workflow.yml        <- committed into your repo

skills/pr-conventional-commits/
  SKILL.md
  references/type-guide.md            <- read when a type is ambiguous
```

## Where to put it

Claude Code loads skills from two places that matter here.

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

## Copy commands

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

## Checking that it worked

Claude Code watches its skill directories and picks up changes during
a session, so you usually do not need to restart.

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

If nothing happens, confirm the folder name matches the `name` in the
`SKILL.md` frontmatter, and that `SKILL.md` sits directly inside the
skill folder rather than in a subdirectory.

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

If you are developing these skills rather than using them, do not copy
them into `.claude/skills/`. See the
[contributor documentation](../devs/) instead.
