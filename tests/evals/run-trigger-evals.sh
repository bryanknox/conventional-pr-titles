#!/usr/bin/env bash
#
# Run a trigger-eval split against the skills in skills/ and score
# dispatch. This is the procedure docs/devs/testing.md describes
# under "Tier 2: trigger evals" -- an earlier campaign discarded its
# runner and left only prose, which cost the next person the whole
# thing. Keep this file.
#
# Usage: bash tests/evals/run-trigger-evals.sh <split> <outdir>
#   <split>   train | validation
#   <outdir>  where transcripts, cases.tsv and results.json land
#
# This costs real model calls and is deliberately not in CI.

set -u

err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

SPLIT="${1:-}"
OUTDIR="${2:-}"
[ -n "$SPLIT" ]  || err "usage: $0 <train|validation> <outdir>"
[ -n "$OUTDIR" ] || err "usage: $0 <train|validation> <outdir>"
case "$SPLIT" in
  train|validation) ;;
  *) err "split must be 'train' or 'validation', got '$SPLIT'" ;;
esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)" || err "cannot resolve repository root"
cd "$ROOT" || err "cannot cd to $ROOT"
[ -d skills ] || err "no skills/ directory at $ROOT"

SCORER="tests/evals/score-trigger-evals.py"
[ -f "$SCORER" ] || err "$SCORER not found"

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

command -v claude >/dev/null 2>&1 || err "claude CLI not found on PATH"
command -v git    >/dev/null 2>&1 || err "git not found on PATH"

mkdir -p "$OUTDIR" || err "cannot create $OUTDIR"
OUTDIR="$(cd "$OUTDIR" && pwd)" || err "cannot resolve $OUTDIR"
FIXTURE="$OUTDIR/fixture"

# A throwaway repository -- README and one commit, no remote -- with
# BOTH skills installed repo-scoped. Both, deliberately: a near-miss
# prompt belonging to the sibling has to be able to dispatch to it,
# because that is a pass, and it cannot be observed if the sibling is
# not installed.
rm -rf "$FIXTURE"
mkdir -p "$FIXTURE/.claude/skills" || err "cannot create fixture"
(
  cd "$FIXTURE" || exit 1
  git init -q . || exit 1
  printf '# scratch\n\nThrowaway repository for trigger-eval dispatch testing.\n' > README.md
  git add README.md || exit 1
  git -c user.email=eval@local -c user.name=eval commit -qm "initial" || exit 1
) || err "fixture git setup failed"

for dir in skills/*/; do
  cp -r "$dir" "$FIXTURE/.claude/skills/" || err "cannot install $dir into fixture"
done

printf 'root:     %s\n' "$ROOT"
printf 'fixture:  %s\n' "$FIXTURE"
printf 'skills:   %s\n' "$(ls "$FIXTURE/.claude/skills" | tr '\n' ' ')"

CASES="$OUTDIR/cases.tsv"
"$PY" "$SCORER" cases "$SPLIT" > "$CASES" || err "failed to extract cases"
TOTAL="$(wc -l < "$CASES" | tr -d ' ')"
printf 'split:    %s (%s cases)\n\n' "$SPLIT" "$TOTAL"

n=0
while IFS="$(printf '\t')" read -r skill_dir cid expected prompt; do
  [ -n "${cid:-}" ] || continue
  n=$((n + 1))
  out="$OUTDIR/${cid}.jsonl"
  printf '[%2d/%s] %-7s %-11s %s\n' "$n" "$TOTAL" "$cid" "$expected" "$prompt"
  (
    cd "$FIXTURE" || exit 1
    claude -p "$prompt" \
      --output-format stream-json --verbose \
      --max-turns 4 \
      --allowedTools "Skill,Read,Glob,Grep" \
      < /dev/null > "$out" 2>"$OUTDIR/${cid}.err"
  )
  # A non-zero exit is expected when the turn cap trips: the dispatch
  # decision is already recorded by then. An empty transcript is the
  # real failure, and the scorer reports it rather than skipping it.
  if [ ! -s "$out" ]; then
    printf '        WARNING: empty transcript for %s\n' "$cid" >&2
  fi
done < "$CASES"

printf '\nscoring...\n'
"$PY" "$SCORER" score "$OUTDIR" "$SPLIT" || err "scoring failed"
