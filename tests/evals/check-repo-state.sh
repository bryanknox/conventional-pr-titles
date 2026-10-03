#!/usr/bin/env bash
#
# Check the repo-state half of a content eval: read back the server
# state a scenario (S1-S5, P1-P5) is graded on, save the raw reads,
# and assert the expected state against them. The scenarios are in
# docs/devs/test-repos.md; how this fits a campaign is in
# docs/devs/testing.md under "Checking repo state".
#
# Usage:
#   bash tests/evals/check-repo-state.sh snapshot <owner/repo> <outdir> [--pr N]
#   bash tests/evals/check-repo-state.sh check <scenario> <owner/repo> <outdir> \
#       [--pr N] [--pre DIR] [--expect-title TITLE]
#
# Read-only: every call is a GET. It never mutates a repository.
# It reads live GitHub state, so it is tier 2 and deliberately not in
# CI. It settles only what server state can show; the transcript half
# of each eval stays with the human grader, and the run ends by
# listing it.
#
# Exit status: 0 all checks passed, 1 a check failed, 2 the check
# could not run (bad usage, a failed read, or an eval citation that no
# longer resolves). A check that cannot run is an error, not a skip.

set -u

err() { printf 'ERROR: %s\n' "$*" >&2; exit 2; }

ROOT="$(cd "$(dirname "$0")/../.." && pwd)" || err "cannot resolve repository root"
CHECKER="$ROOT/tests/evals/check-repo-state.py"
[ -f "$CHECKER" ] || err "$CHECKER not found"

# Resolve the interpreter by running it, not by probing PATH. A name
# that is on PATH but cannot execute is the failure mode that once
# made a check report a clean pass without running.
PY=""
for candidate in python python3 py; do
  if "$candidate" -c "import json, sys" >/dev/null 2>&1; then
    PY="$candidate"
    break
  fi
done
[ -n "$PY" ] || err "no working python interpreter (tried python, python3, py)"

# PyYAML reads the workflow template and the workflow on the server.
# A real dependency, not an optional extra.
"$PY" -c "import yaml" >/dev/null 2>&1 \
  || err "PyYAML not available for $PY; install it with: $PY -m pip install pyyaml"

command -v gh >/dev/null 2>&1 || err "gh CLI not found on PATH"
gh auth status >/dev/null 2>&1 || err "gh is not authenticated; run gh auth status"

exec "$PY" "$CHECKER" "$@"
