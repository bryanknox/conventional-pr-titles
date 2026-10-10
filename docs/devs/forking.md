# Forking

What a fork changes so it runs as its own project rather than as a
copy of this one. There are two parts: the names the tier-2 evals use,
which live in a local config file, and the repository's published
identity, which is edited by hand.

## The test environment

The tier-2 procedures in [test-repos.md](test-repos.md), and the
`dev-test-repo-lifecycle` skill that runs them, use five GitHub names:
an admin account, a second non-admin account, a test organization,
a base repo, and a test-repo name prefix. None of them is written
into a tracked file. Copy `tests/evals/test-env.example` to
`tests/evals/test-env`, which is gitignored, and fill it in. See
[the config section](test-repos.md#test-environment-config) for what
each key names.

Tier 1 needs none of this. Only tier 2 touches GitHub.

## The published identity

These name the repository that users install from, so they hold real
values and a fork edits them once:

| File | What to change |
|---|---|
| `.claude-plugin/plugin.json` | `author`, `homepage`, `repository` |
| `.claude-plugin/marketplace.json` | `owner`. `owner.name` is required by `tests/check-plugin-manifests.sh` |
| `README.md` | The `marketplace add` slug |
| `docs/users/install.md` | Every `owner/conventional-pr-titles` slug |
| `LICENSE` | Add your copyright line; keep the original |

The plugin and marketplace name, `conventional-pr-titles`, is the
product's identity, not an owner. A fork can keep it.

Bump `version` in both manifests on your first release, or installed
copies stay cached. See [release.md](release.md).

## Names in the records

[evidence.md](evidence.md), [findings.md](findings.md),
[decisions/](decisions/), [validation-records/](validation-records/),
and the `measured` notes in `tests/evals/*/evals.json` record runs
made in the original maintainer's environment. The accounts and
repositories they name are history, not instructions. Leave them as
they are, and record your own runs beside them.

## Keeping it that way

When you write a new procedure or doc, refer to the test environment
by its keys (`$ADMIN_ACCOUNT`, `${REPO_PREFIX}s1`) rather than by
value. No tier-1 check enforces this. A check would have to contain
the names it forbids, or skip in CI when the gitignored file is
absent, and this repository's checks do not skip.
