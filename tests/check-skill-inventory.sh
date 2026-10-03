#!/usr/bin/env bash
#
# Asserts which skills exist, and where.
#
# Two directories hold SKILL.md files and they are governed by
# different rules, because getting them confused is what decision
# 0014 exists to prevent:
#
#   skills/          -- what ships. EXACT set.
#   .claude/skills/  -- maintainer-only dev skills. REQUIRED set.
#
# skills/ is exact because an extra directory there is invisible and
# expensive. Neither plugin manifest names a path, so a folder added
# there ships to everyone who installs. Worse,
# tests/evals/run-trigger-evals.sh builds its fixture with
# `for dir in skills/*/`, so a third skill silently joins the dispatch
# surface the trigger evals measure -- and the score moves for a
# reason nobody would look for. Nothing else catches this:
# lint-skills.sh would lint the new skill and pass it, and
# check-plugin-manifests.sh asserts only that skills/ holds at least
# one. See docs/devs/decisions/0014-dev-skills-outside-skills-dir.md.
#
# .claude/skills/ is a required set rather than an exact one because
# third-party skills installed for development (e.g. genesis) live
# there legitimately and are never committed. A missing dev skill is
# an error; an extra directory is reported and nothing more.
#
# Adding a skill means adding it to the right list below. That is the
# point: the lists are the declaration, and this check is what makes
# the declaration load-bearing rather than a comment.
#
# Fails loudly: a check that cannot run is an error, not a skip.

set -uo pipefail

SKILLS_DIR="${1:-skills}"
DEV_SKILLS_DIR="${2:-.claude/skills}"

# What ships. Exactly these, no more and no fewer.
SHIPPABLE_SKILLS="enforce-conventional-commits
write-pr-title"

# Maintainer-only dev skills. These must exist; anything else under
# DEV_SKILLS_DIR is a third-party install and is only reported.
DEV_SKILLS="dev-absorb-campaign
dev-cut-release"

errors=0
checks=0
err()  { printf 'FAIL  %s\n' "$*" >&2; errors=$((errors + 1)); }
ok()   { printf 'ok    %s\n' "$*"; checks=$((checks + 1)); }
info() { printf '      %s\n' "$*"; }

# Directory names holding a SKILL.md, one per line. A directory
# without a SKILL.md is not a skill and is reported as an error by
# the callers below rather than silently ignored.
list_dirs() {
    local root=$1 d
    for d in "$root"/*/; do
        [ -d "$d" ] || continue
        d="${d%/}"
        basename "$d"
    done
}

has_line() {
    printf '%s\n' "$2" | grep -qx -- "$1"
}

# ---------------------------------------------------------------- #
# skills/ -- exact

printf '%s/ (exact)\n' "$SKILLS_DIR"

if [ ! -d "$SKILLS_DIR" ]; then
    err "no such directory: $SKILLS_DIR"
else
    found=$(list_dirs "$SKILLS_DIR")

    while IFS= read -r want; do
        [ -n "$want" ] || continue
        if [ ! -d "$SKILLS_DIR/$want" ]; then
            err "$SKILLS_DIR/$want: required skill directory is missing"
        elif [ ! -f "$SKILLS_DIR/$want/SKILL.md" ]; then
            err "$SKILLS_DIR/$want: no SKILL.md"
        else
            ok "$want"
        fi
    done <<EOF
$SHIPPABLE_SKILLS
EOF

    while IFS= read -r got; do
        [ -n "$got" ] || continue
        has_line "$got" "$SHIPPABLE_SKILLS" && continue
        err "$SKILLS_DIR/$got: not a shippable skill -- everything in" \
            "$SKILLS_DIR/ ships and joins the trigger-eval dispatch" \
            "surface. Maintainer-only skills belong in" \
            "$DEV_SKILLS_DIR/ with a dev- prefix; see decision 0014."
    done <<EOF
$found
EOF
fi

printf '\n'

# ---------------------------------------------------------------- #
# .claude/skills/ -- required

printf '%s/ (required)\n' "$DEV_SKILLS_DIR"

if [ ! -d "$DEV_SKILLS_DIR" ]; then
    # Only an error if something is required to be in it.
    if [ -n "$DEV_SKILLS" ]; then
        err "no such directory: $DEV_SKILLS_DIR (required dev skills:" \
            "$(printf '%s' "$DEV_SKILLS" | tr '\n' ' '))"
    else
        info "absent, and nothing is required in it"
    fi
else
    found=$(list_dirs "$DEV_SKILLS_DIR")

    while IFS= read -r want; do
        [ -n "$want" ] || continue
        if [ ! -d "$DEV_SKILLS_DIR/$want" ]; then
            err "$DEV_SKILLS_DIR/$want: required dev skill is missing"
        elif [ ! -f "$DEV_SKILLS_DIR/$want/SKILL.md" ]; then
            err "$DEV_SKILLS_DIR/$want: no SKILL.md"
        else
            ok "$want"
        fi
    done <<EOF
$DEV_SKILLS
EOF

    # Everything else is a third-party install. Reported so a dev
    # skill that was never added to DEV_SKILLS is visible here rather
    # than only when someone notices it is not in git.
    while IFS= read -r got; do
        [ -n "$got" ] || continue
        has_line "$got" "$DEV_SKILLS" && continue
        info "also present, not required: $got"
    done <<EOF
$found
EOF
fi

printf '\n%d checks passed, %d failed\n' "$checks" "$errors"
[ "$errors" -eq 0 ] || exit 1
