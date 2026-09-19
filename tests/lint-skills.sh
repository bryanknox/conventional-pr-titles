#!/usr/bin/env bash
#
# Structural lint for the skills in skills/.
#
# Tier 1 of the testing strategy: free, deterministic, no model calls.
# Runs in CI and locally (Git Bash on Windows, bash anywhere else).
#
# Every rule here is explained in docs/devs/authoring.md. If you change
# a rule, change that page too.
#
# Design note: this script is written to FAIL LOUDLY. A missing tool,
# an unreadable file, or a check that cannot run is an ERROR, never a
# silent skip. An earlier ad-hoc version of these checks reported a
# pass when `grep -P` was unavailable, which is exactly the failure
# mode a lint must not have.

set -uo pipefail

SKILLS_DIR="${1:-skills}"

# Description ceiling. Conservative shared limit across harnesses;
# both current descriptions sit near 640 characters.
MAX_DESC=1024

# Prose wrap. Table rows and fenced code are exempt -- see
# docs/devs/authoring.md.
MAX_COL=72

# Frontmatter keys allowed. This list is the portability guard: name
# and description are the intersection of what Claude Code, Cursor,
# Codex and Copilot all accept. Adding a key here gives up
# cross-harness portability -- do it deliberately or not at all.
ALLOWED_KEYS="name description"

errors=0
checks=0

err()  { printf 'FAIL  %s\n' "$*" >&2; errors=$((errors + 1)); }
pass() { checks=$((checks + 1)); }
info() { printf '      %s\n' "$*"; }

# Resolve a python interpreter once, by RUNNING each candidate rather
# than trusting that the name exists. Ubuntu runners ship python3 but
# not always a bare `python`; Windows ships a `python3` that is a
# Microsoft Store stub -- it resolves on PATH, prints an install
# advert, and exits 49. Probing by name alone picks the stub and turns
# a working machine into a false failure.
PYTHON=""
for candidate in python3 python py; do
    command -v "$candidate" >/dev/null 2>&1 || continue
    if "$candidate" -c 'import sys; sys.exit(0)' >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done

# A check that cannot run is a failure, not a skip.
require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "required tool not found: $1 (cannot verify $2)"
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------- #

check_ascii() {
    local f=$1
    require_tool iconv "ASCII encoding" || return
    if ! iconv -f ASCII -t ASCII "$f" >/dev/null 2>&1; then
        err "$f: contains non-ASCII bytes"
        LC_ALL=C grep -n "[$(printf '\200')-$(printf '\377')]" "$f" \
            | head -3 | sed 's/^/        /' >&2
    else
        pass
    fi
}

check_line_endings() {
    local f=$1
    # -U is load-bearing. Without it Git Bash's grep treats the
    # file as text, strips CR before matching, and reports a clean
    # pass on a file that is CRLF from end to end -- on the one
    # platform most likely to produce one.
    if grep -qU $'\r' "$f" 2>/dev/null; then
        err "$f: contains CR (expected LF endings)"
    else
        pass
    fi
}

check_final_newline() {
    local f=$1
    if [ -n "$(tail -c1 "$f")" ]; then
        err "$f: no final newline"
    else
        pass
    fi
}

check_trailing_ws() {
    local f=$1
    local hits
    hits=$(grep -n '[[:space:]]$' "$f" || true)
    if [ -n "$hits" ]; then
        err "$f: trailing whitespace"
        printf '%s\n' "$hits" | head -3 | sed 's/^/        /' >&2
    else
        pass
    fi
}

# Prose only: skip fenced code blocks and markdown table rows.
check_wrap() {
    local f=$1 max=$2
    local hits
    hits=$(awk -v max="$max" '
        /^```/       { fence = !fence; next }
        fence        { next }
        /^[[:space:]]*\|/ { next }
        length > max { printf "%d:%d cols: %s\n", NR, length, substr($0,1,50) }
    ' "$f")
    if [ -n "$hits" ]; then
        err "$f: prose lines over $max columns"
        printf '%s\n' "$hits" | sed 's/^/        /' >&2
    else
        pass
    fi
}

# Frontmatter must be the first thing in the file, delimited by ---.
frontmatter() {
    awk 'NR==1 && $0!="---" { exit } NR==1 { next } /^---[[:space:]]*$/ { exit } { print }' "$1"
}

check_frontmatter() {
    local f=$1 dir=$2
    local fm keys name desc

    if [ "$(head -n1 "$f")" != "---" ]; then
        err "$f: does not start with a --- frontmatter block"
        return
    fi
    fm=$(frontmatter "$f")
    if [ -z "$fm" ]; then
        err "$f: frontmatter block is empty or unterminated"
        return
    fi
    pass

    # Top-level keys only (column 0, before the colon).
    keys=$(printf '%s\n' "$fm" | sed -n 's/^\([A-Za-z][A-Za-z0-9_-]*\):.*/\1/p')

    for k in $keys; do
        case " $ALLOWED_KEYS " in
            *" $k "*) : ;;
            *) err "$f: frontmatter key '$k' is not allowed (portability guard; allowed: $ALLOWED_KEYS)" ;;
        esac
    done

    for required in name description; do
        if ! printf '%s\n' "$keys" | grep -qx "$required"; then
            err "$f: frontmatter missing required key '$required'"
        else
            pass
        fi
    done

    name=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)
    if [ "$name" != "$dir" ]; then
        err "$f: frontmatter name '$name' does not match directory '$dir'"
    else
        pass
    fi
    if ! printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
        err "$f: name '$name' is not lowercase hyphen-case"
    else
        pass
    fi
    if [ "${#name}" -gt 64 ]; then
        err "$f: name is ${#name} chars (max 64)"
    else
        pass
    fi

    # Description: everything after 'description:' up to the next
    # top-level key, folded to one line.
    desc=$(printf '%s\n' "$fm" | awk '
        /^description:/ { grab = 1; sub(/^description:[[:space:]]*>?-?[[:space:]]*/, ""); if ($0 != "") print; next }
        grab && /^[A-Za-z][A-Za-z0-9_-]*:/ { grab = 0 }
        grab { print }
    ' | tr -s ' \n' ' ' | sed 's/^ //; s/ $//')

    if [ -z "$desc" ]; then
        err "$f: description is empty"
    elif [ "${#desc}" -gt "$MAX_DESC" ]; then
        err "$f: description is ${#desc} chars (max $MAX_DESC)"
    else
        pass
        info "description: ${#desc} chars"
    fi
}

# Nothing may reference outside its own skill folder: skills are
# distributed one folder at a time, so an outside reference works here
# and breaks in the consumer's repository.
check_self_contained() {
    local f=$1 skilldir=$2
    local refs r

    # Only paths that claim to be part of THIS skill's bundle are
    # checked for existence. A skill legitimately mentions paths in the
    # consumer's repository (`.github/workflows/pr-title.yml` is written
    # BY enforce-conventional-commits, not shipped with it), so existence
    # is asserted only for the bundle subdirectories.
    refs=$(grep -oE '\]\([^)]+\)|`(assets|references|scripts)/[a-zA-Z0-9_./-]+`' "$f" \
           | sed -E 's/^\]\(//; s/\)$//; s/^`//; s/`$//' || true)

    for r in $refs; do
        case "$r" in
            http*|mailto:*|\#*) continue ;;
        esac
        r="${r%%#*}"
        [ -z "$r" ] && continue
        case "$r" in
            /*)
                err "$f: absolute path reference '$r'"
                continue ;;
            ../*)
                err "$f: reference escapes the skill folder: '$r'"
                continue ;;
        esac
        if [ ! -e "$skilldir/$r" ]; then
            err "$f: bundled reference not found: '$r'"
        else
            pass
        fi
    done
}

# ---------------------------------------------------------------- #

printf 'Linting skills in %s/\n\n' "$SKILLS_DIR"

if [ ! -d "$SKILLS_DIR" ]; then
    err "no such directory: $SKILLS_DIR"
    exit 1
fi

found=0
for skilldir in "$SKILLS_DIR"/*/; do
    [ -d "$skilldir" ] || continue
    found=$((found + 1))
    skilldir="${skilldir%/}"
    dir=$(basename "$skilldir")
    skill_md="$skilldir/SKILL.md"

    printf '%s\n' "$dir"

    if [ ! -f "$skill_md" ]; then
        err "$dir: no SKILL.md"
        continue
    fi

    check_frontmatter "$skill_md" "$dir"
    check_self_contained "$skill_md" "$skilldir"

    # Text hygiene applies to every markdown file in the bundle.
    while IFS= read -r f; do
        check_ascii "$f"
        check_line_endings "$f"
        check_final_newline "$f"
        check_trailing_ws "$f"
        check_wrap "$f" "$MAX_COL"
    done < <(find "$skilldir" -name '*.md' -type f | sort)

    printf '\n'
done

if [ "$found" -eq 0 ]; then
    err "no skill directories found under $SKILLS_DIR/"
fi

# Eval files must at least parse.
if [ -d tests/evals ]; then
    printf 'evals\n'
    while IFS= read -r j; do
        if [ -z "$PYTHON" ]; then
            err "no python interpreter found (cannot verify $j parses)"
        elif "$PYTHON" -c "import json,sys; json.load(open(sys.argv[1]))" "$j" 2>/dev/null; then
            pass
        else
            err "$j: does not parse as JSON"
        fi
    done < <(find tests/evals -name '*.json' -type f | sort)
    printf '\n'
fi

printf '%d checks passed, %d failed\n' "$checks" "$errors"
[ "$errors" -eq 0 ] || exit 1
