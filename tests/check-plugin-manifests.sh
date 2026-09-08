#!/usr/bin/env bash
#
# Verifies the two plugin manifests under .claude-plugin/.
#
# These are how the skills reach anyone who is not the author: the
# plugin manifest names what ships, the marketplace manifest is the
# catalog users add. Both are small, and both fail in ways that are
# invisible until someone tries to install.
#
# The one that bites hardest is the version. A declared `version`
# that is not bumped means installed copies stay cached no matter
# what else changed -- new commits alone do not reach anyone. So
# this asserts the field exists and that the two manifests agree on
# it; see docs/devs/decisions/0010-declare-a-plugin-version.md.
#
# This is deliberately NOT a reimplementation of `claude plugin
# validate`. That command is the richer check and is the release-time
# gate (see docs/devs/release.md). It needs the Claude Code CLI, so
# it is not something CI should depend on: an added warning in a
# future CLI release would turn this repository red without anyone
# changing a file here. What runs in CI is offline, deterministic,
# and about the couplings this repository owns.
#
# Fails loudly: a check that cannot run is an error, not a skip.

set -uo pipefail

PLUGIN="${1:-.claude-plugin/plugin.json}"
MARKET="${2:-.claude-plugin/marketplace.json}"

# The default plugin layout: skills/ at the plugin root. Neither
# manifest names it, so nothing else would notice it going missing.
SKILLS_DIR="skills"

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
    err "no working python interpreter found (cannot parse the manifests)"
    exit 1
fi

for f in "$PLUGIN" "$MARKET"; do
    if [ ! -f "$f" ]; then
        err "missing manifest: $f"
        exit 1
    fi
    if ! "$PYTHON" -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>/dev/null; then
        err "$f: does not parse as JSON"
        exit 1
    fi
    ok "$f parses"
done

# Read one dotted path out of a manifest. Prints nothing and returns
# non-zero when the path is absent, so an unset field and an empty
# one are the same failure -- which is what callers want here.
jget() {
    "$PYTHON" - "$1" "$2" <<'PY'
import json, sys
node = json.load(open(sys.argv[1]))
for part in sys.argv[2].split('.'):
    if isinstance(node, list):
        part = int(part)
    try:
        node = node[part]
    except (KeyError, IndexError, TypeError):
        sys.exit(1)
if node is None or node == '':
    sys.exit(1)
print(node)
PY
}

require() {
    local file=$1 path=$2 value
    if value=$(jget "$file" "$path"); then
        printf '%s' "$value"
        return 0
    fi
    err "$file: missing or empty '$path'"
    return 1
}

# ---------------------------------------------------------------- #
# plugin.json

PLUGIN_NAME=$(require "$PLUGIN" name) || PLUGIN_NAME=""
PLUGIN_VERSION=$(require "$PLUGIN" version) || PLUGIN_VERSION=""
require "$PLUGIN" description >/dev/null || true

if [ -n "$PLUGIN_NAME" ]; then
    if printf '%s' "$PLUGIN_NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
        ok "plugin name '$PLUGIN_NAME' is hyphen-case"
    else
        err "$PLUGIN: name '$PLUGIN_NAME' is not hyphen-case"
    fi
fi

# Semver, so that `claude plugin tag` can build {name}--v{version}
# and so ordering between two releases is decidable.
if [ -n "$PLUGIN_VERSION" ]; then
    if printf '%s' "$PLUGIN_VERSION" \
        | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'; then
        ok "plugin version '$PLUGIN_VERSION' is semver"
    else
        err "$PLUGIN: version '$PLUGIN_VERSION' is not semver"
    fi
fi

# ---------------------------------------------------------------- #
# marketplace.json

require "$MARKET" name >/dev/null || true
require "$MARKET" description >/dev/null || true
require "$MARKET" owner.name >/dev/null || true

if ! jget "$MARKET" plugins.0.name >/dev/null; then
    err "$MARKET: 'plugins' is empty -- the catalog lists nothing"
else
    ok "$MARKET lists at least one plugin"
fi

# The entry for this plugin has to exist, and has to agree with
# plugin.json. Disagreement is what `claude plugin tag` refuses on,
# and it is silent everywhere else.
# Iterate by declared length rather than until the first entry
# without a name, so a malformed entry is reported instead of
# quietly truncating the scan.
n_plugins=$("$PYTHON" -c 'import json,sys; d=json.load(open(sys.argv[1])); p=d.get("plugins"); print(len(p) if isinstance(p,list) else 0)' "$MARKET")

found_entry=0
i=0
while [ "$i" -lt "$n_plugins" ]; do
    if ! entry_name=$(jget "$MARKET" "plugins.$i.name"); then
        err "$MARKET: plugin entry $i has no name"
        i=$((i + 1))
        continue
    fi
    if [ "$entry_name" = "$PLUGIN_NAME" ]; then
        found_entry=1

        entry_version=$(jget "$MARKET" "plugins.$i.version") || entry_version=""
        if [ -z "$entry_version" ]; then
            err "$MARKET: entry '$entry_name' has no version"
        elif [ "$entry_version" = "$PLUGIN_VERSION" ]; then
            ok "marketplace entry version matches plugin.json ($PLUGIN_VERSION)"
        else
            err "version mismatch: $PLUGIN says '$PLUGIN_VERSION'," \
                "$MARKET entry says '$entry_version'"
        fi

        jget "$MARKET" "plugins.$i.description" >/dev/null \
            || err "$MARKET: entry '$entry_name' has no description"

        source=$(jget "$MARKET" "plugins.$i.source") || source=""
        if [ -z "$source" ]; then
            err "$MARKET: entry '$entry_name' has no source"
        else
            base=$(dirname "$MARKET")/..
            if [ -f "$base/$source/.claude-plugin/plugin.json" ]; then
                ok "entry source '$source' resolves to a plugin"
            else
                err "$MARKET: source '$source' has no .claude-plugin/plugin.json"
            fi
        fi
    fi
    i=$((i + 1))
done

if [ "$found_entry" -eq 0 ]; then
    err "$MARKET: no entry named '$PLUGIN_NAME' -- the catalog does not" \
        "list the plugin it sits in"
fi

# ---------------------------------------------------------------- #
# The layout both manifests assume

if [ ! -d "$SKILLS_DIR" ]; then
    err "no $SKILLS_DIR/ directory -- the plugin would ship no skills"
else
    count=$(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md -type f | wc -l)
    if [ "$count" -eq 0 ]; then
        err "$SKILLS_DIR/ contains no <name>/SKILL.md -- the plugin would" \
            "ship no skills"
    else
        ok "$SKILLS_DIR/ holds $count skill(s)"
    fi
fi

# ---------------------------------------------------------------- #
# Text hygiene, same rules the skills follow.

for f in "$PLUGIN" "$MARKET"; do
    if ! command -v iconv >/dev/null 2>&1; then
        err "required tool not found: iconv (cannot verify ASCII in $f)"
    elif ! iconv -f ASCII -t ASCII "$f" >/dev/null 2>&1; then
        err "$f: contains non-ASCII bytes"
    fi

    # -U is load-bearing: without it Git Bash's grep treats the
    # file as text, strips CR before matching, and reports a
    # clean pass on a CRLF file.
    grep -qU $'\r' "$f" 2>/dev/null && err "$f: contains CR (expected LF endings)"
    [ -n "$(tail -c1 "$f")" ] && err "$f: no final newline"
done

printf '\n%d failed\n' "$errors"
[ "$errors" -eq 0 ] || exit 1
