# 0016 - Go public

**Decision:** this repository is public, and carries the Level 3
ruleset that being private made impossible. Both status checks --
the PR-title check and `Tier 1 checks` -- are required.

**Status:** accepted 2026-10-10. Supersedes
[decision 0009](0009-stay-private-for-now.md), whose "Reversing
this" steps are the procedure that was followed.

## Why

0009 rested on the audience being the author. That stopped being
true: the plugin is worth installing from outside, and a marketplace
entry pointing at a private repository resolves only for accounts
that can already read it. Going public also lets this repository
obey its own convention mechanically instead of by habit.

## What was done

Following 0009's ordered steps:

1. **History audited.** No token, key, or PAT pattern appears
   anywhere in the history. Older commits do name the test
   environment -- test repositories, the test organization, the
   second account -- which #40 removed from the current files but
   not from history. Publishing those names was accepted rather
   than rewriting history, which would have orphaned the release
   tags and the commit links in merged pull requests. The test
   repositories are torn down after each campaign.
2. **Visibility flipped** to public.
3. **`enforce-conventional-commits` re-run.** Levels 1 and 2 came
   back as no-ops, keeping the two deliberate deviations from the
   defaults (`squash_merge_commit_message=PR_BODY` and
   `delete_branch_on_merge`). It added only the ruleset,
   `conventional-commits-main`.
4. **Your own workflow changes:** with an empty bypass list, direct
   pushes to `main` are refused for the owner too.
5. **`Tier 1 checks` is required as well.** The skill's ruleset
   requires exactly one context; this repository adds the CI job's
   context beside it, so a red tier 1 blocks a merge the same way a
   bad title does. The skill does not make that choice, which is
   why it is recorded here.
6. **The documents that called the check advisory** were updated.

## Verified

2026-10-10, effective rules on `main`, which returns only actively
enforced rules:

```
$ gh api repos/bryanknox/conventional-pr-titles/rules/branches/main
deletion                 ruleset 24841242
non_fast_forward         ruleset 24841242
pull_request             ruleset 24841242
required_status_checks   ruleset 24841242
  contexts: "Validate conventional PR title", "Tier 1 checks"
```

Reduced from the JSON response to type, ruleset id, and contexts.
The ruleset itself reads back as enforcement `active` with an empty
`bypass_actors` list.

## Reversing this

Making the repository private again would put it back behind the
plan gate: the ruleset stays in place but stops being enforced, and
installation narrows to accounts with access. Do not delete the
ruleset if that happens -- it re-activates if the repository goes
public again. What has been public cannot be made unread.
