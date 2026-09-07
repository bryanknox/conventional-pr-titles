#!/usr/bin/env bash
#
# Verifies that every relative markdown link in the repository's
# documentation points at something that exists.
#
# This mechanizes a check that was being run by hand during the repo
# refactor, where it caught broken links three times. Moving files is
# the common cause, and a link that silently rots is worse than one
# that never existed.
#
# Scope: docs/ and the root README. Links inside skills/ bundles are
# checked by lint-skills.sh, which understands the difference between
# a bundled file and a path in the consumer's repository.
#
# Fails loudly: a check that cannot run is an error, not a skip.

set -uo pipefail

errors=0
checked=0
files=0

err() { printf 'FAIL  %s\n' "$*" >&2; errors=$((errors + 1)); }

targets=$(find docs -name '*.md' -type f 2>/dev/null; ls README.md 2>/dev/null)

if [ -z "$targets" ]; then
    err "no documentation found to check (expected docs/ and README.md)"
    exit 1
fi

for f in $targets; do
    [ -f "$f" ] || { err "not a readable file: $f"; continue; }
    files=$((files + 1))
    dir=$(dirname "$f")

    # Markdown inline links: ](target)
    for target in $(grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\(//; s/\)$//'); do
        case "$target" in
            http://*|https://*|mailto:*|\#*) continue ;;
        esac
        # Strip any anchor; anchor validity is not checked.
        path="${target%%#*}"
        [ -z "$path" ] && continue

        checked=$((checked + 1))
        if [ ! -e "$dir/$path" ]; then
            err "$f -> $target"
        fi
    done
done

printf '%d files, %d relative links checked, %d broken\n' \
    "$files" "$checked" "$errors"

[ "$errors" -eq 0 ] || exit 1
