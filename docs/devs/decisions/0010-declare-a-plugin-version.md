# 0010 - Declare a plugin version, and bump it every release

**Decision:** `.claude-plugin/plugin.json` carries an explicit
`version`, starting at `1.0.0`, and every release bumps it. The
alternative -- omitting the field and letting the resolved commit be
the version -- was considered and rejected.

## The trap this avoids

A declared `version` that is not bumped means installed copies stay
cached no matter what else changed. New commits alone do not reach
anyone. Someone reads a fix on `main`, updates, and gets nothing,
with no error to explain it.

That failure mode is why omitting the field is tempting: without a
version there is nothing to forget to bump.

## Why declare it anyway

The thing the copy-a-folder install could never answer was *which
copy do I have*. An omitted version keeps that unanswerable -- users
would have a commit hash, which is not something anyone compares
against a changelog or a decision record.

A version also makes the [semver table in
release.md](../release.md) mean something. That table maps a
widened description to a minor bump and a narrowed one to a major,
which is only useful if there is a number to bump.

And it is what the tooling expects: `claude plugin tag` builds a
`{name}--v{version}` git tag and refuses when `plugin.json` and the
marketplace entry disagree. Without a version there is no tag and no
agreement to check.

## Starting at 1.0.0, not 0.1.0

Both skills passed their ship gates before this was ever published:
scenarios S1-S5 and P1-P5 against real repositories, plus the
trigger-eval gate on frozen descriptions, all recorded in
[validation/](../validation/). The user-visible contract is not a
draft.

`0.x` would also have made the semver table decorative, since a
breaking change below 1.0 has no agreed encoding.

## Holding to it

Forgetting the bump is the whole risk, so it is checked rather than
remembered. [`tests/check-plugin-manifests.sh`](../../../tests/check-plugin-manifests.sh)
asserts the field exists, is semver, and matches the marketplace
entry. It cannot tell that a *changed* skill needed a bump -- no
offline check can -- so that part stays a release step in
[release.md](../release.md).

## Reversing it

Dropping to an omitted version is cheap mechanically and expensive
socially: anyone who installed a numbered version loses the ability
to tell what they have. If it happens, do it deliberately, and
delete the version assertions from the manifest check at the same
time so the two do not contradict each other.
