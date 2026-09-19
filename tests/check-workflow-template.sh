#!/usr/bin/env bash
#
# Verifies the PR-title workflow template that
# enforce-conventional-commits installs into other people's
# repositories.
#
# This file has the highest blast radius in the repo: it is the one
# artifact that lands in a consumer's repository and becomes their
# enforcement. A mistake here is a broken check in someone else's
# project.
#
# These are targeted invariant checks rather than a generic workflow
# linter, because the failure that actually matters here is not a YAML
# error. It is a rename. The ruleset created by the skill requires the
# status check BY JOB NAME STRING -- change the job name and
# enforcement silently stops working, with no error anywhere. A
# general-purpose linter cannot see that; this can.
#
# Fails loudly: a check that cannot run is an error, not a skip.

set -uo pipefail

TEMPLATE="skills/enforce-conventional-commits/assets/pr-title-workflow.yml"

# The job name the skill's ruleset requires as a status check context.
# Keep in sync with SKILL.md step 7 and the eval expectations.
REQUIRED_JOB_NAME="Validate conventional PR title"

# The action, pinned deliberately. The skill reports a newer major as
# a lag rather than following it silently.
REQUIRED_ACTION="amannn/action-semantic-pull-request@v6"

# The allowed commit types, pinned in the template rather than left to
# the action's defaults. Consumers are invited to edit their copy; this
# asserts what SHIPS, which must stay the de-facto ten that SKILL.md,
# write-pr-title, and the user guide all name. A drift here
# would hand consumers a type set no document in this repo describes.
REQUIRED_TYPES="feat,fix,docs,style,refactor,perf,test,build,ci,chore"

errors=0
err()  { printf 'FAIL  %s\n' "$*" >&2; errors=$((errors + 1)); }
ok()   { printf 'ok    %s\n' "$*"; }

# Resolve a python interpreter by RUNNING each candidate rather than
# trusting the name. Windows ships a `python3` that is a Microsoft
# Store stub: it resolves on PATH, prints an install advert, and exits
# 49. Probing by name alone picks the stub.
PYTHON=""
for candidate in python3 python py; do
    command -v "$candidate" >/dev/null 2>&1 || continue
    if "$candidate" -c 'import sys; sys.exit(0)' >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    err "no working python interpreter found (need python3 or python)"
    exit 1
fi

# PyYAML is a real dependency of this check, not an optional extra.
# Say so with a remedy rather than skipping: a check that quietly does
# nothing is the failure mode this suite exists to avoid.
if ! "$PYTHON" -c 'import yaml' >/dev/null 2>&1; then
    err "PyYAML not available for $PYTHON"
    err "  install it with: $PYTHON -m pip install pyyaml"
    exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
    err "template not found: $TEMPLATE"
    exit 1
fi

# Parse once, emit the facts we assert on. Any parse failure is fatal.
facts=$("$PYTHON" - "$TEMPLATE" <<'PY'
import shlex
import sys

import yaml


def emit(key, value):
    # Shell-quote: several of these values contain spaces (the job
    # name is a sentence), and an unquoted assignment would be
    # word-split by eval into a command.
    print("{}={}".format(key, shlex.quote(str(value))))


with open(sys.argv[1]) as fh:
    doc = yaml.safe_load(fh)

# PyYAML parses the bare key `on` as the boolean True.
triggers = doc.get("on", doc.get(True, {})) or {}
pr = triggers.get("pull_request") or {}
types = pr.get("types") or []

jobs = doc.get("jobs") or {}
names = [j.get("name", "") for j in jobs.values()]
uses = [
    step.get("uses", "")
    for j in jobs.values()
    for step in (j.get("steps") or [])
    if step.get("uses")
]
# `types` is a block scalar, one type per line, so it arrives as one
# string with trailing newline -- not a list.
types_in = [
    (step.get("with") or {}).get("types", "")
    for j in jobs.values()
    for step in (j.get("steps") or [])
    if (step.get("with") or {}).get("types")
]
allowed = types_in[0].split() if types_in else []
perms = doc.get("permissions") or {}

emit("TRIGGER_TYPES", ",".join(types))
emit("JOB_NAMES", "|".join(names))
emit("USES", "|".join(uses))
emit("ALLOWED_TYPES", ",".join(allowed))
emit("PERM_PR", perms.get("pull-requests", ""))
emit("HAS_PULL_REQUEST", "yes" if pr else "no")
PY
) || { err "$TEMPLATE: does not parse as YAML"; exit 1; }

eval "$facts"
ok "$TEMPLATE parses as YAML"

case "$JOB_NAMES" in
    *"$REQUIRED_JOB_NAME"*)
        ok "job name is '$REQUIRED_JOB_NAME'" ;;
    *)
        err "job name must be '$REQUIRED_JOB_NAME' (found: '$JOB_NAMES')"
        err "  the skill's ruleset requires this status check by name;" \
            "renaming it silently disables enforcement" ;;
esac

if [ "$HAS_PULL_REQUEST" != "yes" ]; then
    err "$TEMPLATE: no pull_request trigger"
else
    ok "triggers on pull_request"
fi

case ",$TRIGGER_TYPES," in
    *,edited,*)
        ok "pull_request types include 'edited'" ;;
    *)
        err "pull_request types must include 'edited' (found: $TRIGGER_TYPES)"
        err "  without it, a corrected title leaves the old failure" \
            "in place until something else re-runs the check" ;;
esac

case "$USES" in
    *"$REQUIRED_ACTION"*)
        ok "action pinned to $REQUIRED_ACTION" ;;
    *)
        err "action must be pinned to $REQUIRED_ACTION (found: '$USES')" ;;
esac

if [ "$ALLOWED_TYPES" = "$REQUIRED_TYPES" ]; then
    ok "allowed types pinned to the de-facto ten"
else
    err "allowed types must be pinned to: $REQUIRED_TYPES"
    err "  (found: '$ALLOWED_TYPES')"
    err "  an unpinned list inherits the action's defaults silently;"
    err "  a different list contradicts SKILL.md and the type guide"
fi

if [ "$PERM_PR" = "read" ]; then
    ok "permissions.pull-requests is read"
else
    err "permissions.pull-requests must be 'read' (found: '$PERM_PR')"
fi

# The same literals must appear in the behavior spec. The spec is the
# contract these constants implement, and A-R4 is coupled to A-R5 by
# one string: the ruleset requires the status check BY NAME, so a job
# renamed in only one place leaves both objects present, apparently
# healthy, and enforcing nothing. Asserting the strings in both files
# keeps that couple from drifting half-way.
SPEC="docs/devs/behavior-spec.md"
if [ ! -f "$SPEC" ]; then
    err "missing $SPEC (the contract this template implements)"
else
    for literal in "$REQUIRED_JOB_NAME" "$REQUIRED_ACTION" "$REQUIRED_TYPES" "conventional-commits-main"; do
        if grep -qF "$literal" "$SPEC"; then
            ok "spec states: $literal"
        else
            err "$SPEC must state: $literal"
            err "  template and contract have drifted apart"
        fi
    done
fi

printf '\n%d failed\n' "$errors"
[ "$errors" -eq 0 ] || exit 1
