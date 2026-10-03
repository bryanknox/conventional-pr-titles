# Tech stack

**What this is for:** what has to be installed to work here, and why
each piece is there.

**Read it** before a first run on a new machine, and before adding a
dependency.

**Write to it** whenever a script, workflow, or procedure gains or
drops a tool. A tool that something calls and this page does not list
is a missing row, not an omission to tolerate.

## What ships

Markdown, and nothing executable. Each skill is a `SKILL.md` plus the
files beside it, and the plugin is two JSON manifests in
`.claude-plugin/`.

The one shipped asset with behavior is
`skills/enforce-conventional-commits/assets/pr-title-workflow.yml`, a
GitHub Actions workflow pinned to
`amannn/action-semantic-pull-request@v6`. It runs in the consumer's
repository, not here.

At run time the skills drive `gh` and `git` on the user's machine.
That is the user's footprint, and it is separate from everything
below, which only maintainers need.

## Maintainer tools

| Tool | Used by | Tier | Notes |
|---|---|---|---|
| Bash | every script in `tests/` | 1 and 2 | Git Bash on Windows, ubuntu in CI. One implementation for both platforms; a PowerShell equivalent is ruled out in [CLAUDE.md](../../CLAUDE.md) |
| Python 3 | `lint-skills.sh`, `check-workflow-template.sh`, `check-plugin-manifests.sh`, `check-requirement-ids.sh`, `run-trigger-evals.sh`, `check-repo-state.sh` | 1 and 2 | Standard library only. Resolved by running each candidate, never by name on `PATH` -- see below. CI pins `3.x` |
| PyYAML | `check-workflow-template.sh`, `check-repo-state.sh` | 1 and 2 | The only third-party package. `python -m pip install pyyaml` |
| `iconv` | `lint-skills.sh`, `check-plugin-manifests.sh` | 1 | The ASCII check |
| `grep` | most tier-1 checks | 1 | `-E` and `-U` only. `-P` is deliberately absent: it was unavailable in Git Bash and a check passed without running |
| `awk`, `sed`, `find` | `lint-skills.sh`, `check-links.sh`, and others | 1 | POSIX forms only |
| `git` | `run-trigger-evals.sh`, the [test-repos.md](test-repos.md) procedures | 2 | The trigger-eval fixture is a throwaway local repository |
| `gh` | `check-repo-state.sh`, the [test-repos.md](test-repos.md) procedures | 2 | Must be authenticated. Two accounts on the maintainer machine; which does what is in test-repos.md. `--jq` is built into gh, so `jq` is not a dependency |
| `claude` CLI | `run-trigger-evals.sh`; `claude plugin validate` and `claude plugin tag` in [release.md](release.md) | 2 and release | Deliberately not in CI -- see [testing.md](testing.md), "check-plugin-manifests.sh" |
| GitHub Actions | `.github/workflows/ci.yml` (tier 1), `.github/workflows/pr-title.yml` (this repo's own title check) | CI | `actions/checkout@v5`, `actions/setup-python@v6` |

## Which tier needs what

- **Tier 1:** Bash, Python 3, PyYAML, and the text tools. Nothing
  needs the network.
- **Tier 2:** all of tier 1, plus `git`, an authenticated `gh`, and the
  `claude` CLI. The [testing.md](testing.md) page says when tier 2 is
  worth its cost.

## Why Bash, and why Python inside it

Every check is a Bash script so that one implementation covers the
Windows machine development happens on and the ubuntu runner CI uses.

Python appears where Bash would otherwise have to parse JSON or YAML,
and nowhere else. The two eval drivers put that Python in a `.py` file
beside the `.sh` wrapper. The tier-1 checks inline it.

Python is found by running each candidate interpreter, not by
testing for the name. Windows ships a `python3`
that resolves on `PATH`, prints a Microsoft Store advert, and exits
49. The full account is in [testing.md](testing.md), "The checks are
written to fail loudly".

## Adding a tool

1. Add its row above, saying what uses it and in which tier.
2. Make its absence fail loudly. Probe it by running it, the way the
   existing scripts probe Python. A missing tool is an error, never a
   skip.
3. If it is a tier-1 dependency, install it in
   `.github/workflows/ci.yml` too, or CI will fail where your machine
   passed.
