#!/usr/bin/env bash
#
# Verifies the requirement-id traceability between the behavior spec,
# the evals, the scenario definitions, and the three registers.
#
# docs/devs/behavior-spec.md defines numbered requirements (INV*, A-R*,
# B-R*). Other files cite them: the eval files say which requirements a
# content eval exercises, test-repos.md says which a scenario covers,
# and evidence.md / findings.md / known-gaps.md are keyed by them.
#
# A citation scheme with no integrity check rots. The specific failure
# it rots into is the one this whole structure was built to remove:
# information that is present but unreachable. So two rules are
# mechanical rather than aspirational.
#
#   1. Every cited id resolves. A renamed or deleted requirement
#      cannot leave dangling citations behind.
#   2. Every defined id appears in evidence.md. Adding a requirement
#      forces an explicit statement about whether anything has ever
#      tested it -- with evidence, or as NOT PROVEN. Silence is the
#      thing being prevented.
#
# It also resolves doc paths cited from inside the eval JSON.
# check-links.sh only reads markdown, so a stale path in a .json file
# went unnoticed until it was found by hand; see decision 0012.
#
# Fails loudly: a check that cannot run is an error, not a skip.

set -uo pipefail

SPEC="${SPEC:-docs/devs/behavior-spec.md}"
EVIDENCE="${EVIDENCE:-docs/devs/evidence.md}"

# Files that may cite requirement ids. The spec is included so that
# its own cross-references are checked too.
CITING_MD="
$SPEC
$EVIDENCE
docs/devs/findings.md
docs/devs/known-gaps.md
docs/devs/test-repos.md
"

CITING_JSON="
tests/evals/enforce-conventional-commits/evals.json
tests/evals/write-pr-title/evals.json
"

errors=0
err() { printf 'FAIL  %s\n' "$*" >&2; errors=$((errors + 1)); }
ok()  { printf 'ok    %s\n' "$*"; }

# Resolve a python interpreter by RUNNING each candidate rather than
# trusting the name. Windows ships a `python3` that resolves on PATH,
# prints an advert for the Microsoft Store, and exits 49; probing by
# name alone picks that stub and fails on a working machine.
PYTHON=""
for candidate in python3 python py; do
    command -v "$candidate" >/dev/null 2>&1 || continue
    if "$candidate" -c 'import sys; sys.exit(0)' >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    err "no working python interpreter found (cannot parse the eval files)"
    exit 1
fi

for f in $CITING_MD $CITING_JSON; do
    if [ ! -f "$f" ]; then
        err "missing file: $f"
        exit 1
    fi
done

# Ids are DEFINED by a table row in the spec whose first cell is the
# id and nothing else. Prose mentions elsewhere in the spec are
# citations, not definitions.
defined=$(grep -oE '^\| *(INV|A-R|B-R)[0-9]+ *\|' "$SPEC" \
          | tr -d '| ' | sort)

if [ -z "$defined" ]; then
    err "$SPEC: defines no requirement ids (expected rows like '| A-R1 |')"
    exit 1
fi

dupes=$(printf '%s\n' "$defined" | uniq -d)
if [ -n "$dupes" ]; then
    for d in $dupes; do
        err "$SPEC: requirement $d is defined more than once"
    done
fi

defined=$(printf '%s\n' "$defined" | uniq)
count=$(printf '%s\n' "$defined" | wc -l | tr -d ' ')
ok "$SPEC defines $count requirement ids"

# Rule 1: every cited id resolves to a definition.
dangling=0
for f in $CITING_MD $CITING_JSON; do
    cited=$(grep -oE '(INV|A-R|B-R)[0-9]+' "$f" | sort -u)
    [ -n "$cited" ] || continue
    for id in $cited; do
        if ! printf '%s\n' "$defined" | grep -qx "$id"; then
            err "$f: cites $id, which $SPEC does not define"
            dangling=$((dangling + 1))
        fi
    done
done
[ "$dangling" -eq 0 ] && ok "every cited requirement id resolves"

# Rule 2: every defined id is accounted for in the evidence index.
evidenced=$(grep -oE '(INV|A-R|B-R)[0-9]+' "$EVIDENCE" | sort -u)
missing=0
for id in $defined; do
    if ! printf '%s\n' "$evidenced" | grep -qx "$id"; then
        err "$EVIDENCE: says nothing about $id (needs evidence or NOT PROVEN)"
        missing=$((missing + 1))
    fi
done
[ "$missing" -eq 0 ] && ok "every defined requirement appears in $EVIDENCE"

# Doc paths cited from inside the eval JSON must resolve. These are
# invisible to check-links.sh, which reads markdown only.
#
# The `tr -d` strips CR: python's text-mode stdout turns LF into CRLF
# on Windows, and a path carrying a trailing CR never matches -e. Same
# family of trap as the `grep -U` note in the other checks.
badpaths=0
for f in $CITING_JSON; do
    if ! "$PYTHON" -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>/dev/null; then
        err "$f: does not parse as JSON"
        continue
    fi
    paths=$("$PYTHON" - "$f" <<'PY' | tr -d '\r'
import json, re, sys

pattern = re.compile(r'(?:docs|tests|skills)/[A-Za-z0-9._/-]+\.(?:md|json|ya?ml|sh)')
found = set()


def walk(node):
    if isinstance(node, dict):
        for value in node.values():
            walk(value)
    elif isinstance(node, list):
        for value in node:
            walk(value)
    elif isinstance(node, str):
        found.update(pattern.findall(node))


walk(json.load(open(sys.argv[1])))
for path in sorted(found):
    print(path)
PY
)
    for p in $paths; do
        if [ ! -e "$p" ]; then
            err "$f: references $p, which does not exist"
            badpaths=$((badpaths + 1))
        fi
    done
done
[ "$badpaths" -eq 0 ] && ok "every doc path cited from the eval files resolves"

if [ "$errors" -gt 0 ]; then
    printf '\n%d problem(s) found.\n' "$errors" >&2
    exit 1
fi

printf '\nRequirement-id traceability intact.\n'
