"""Case extraction and dispatch scoring for the trigger evals.

Driven by run-trigger-evals.sh. Two subcommands:

  cases <split>            emit "<skill_dir>\t<id>\t<expected>\t<prompt>"
  score <outdir> <split>   score the transcripts in <outdir>

The scoring predicate, unchanged from the 2026-07-29 campaign: a
case counts as a trigger of skill X if and only if a Skill(X)
tool_use appears in the transcript.
"""

import glob
import json
import os
import sys


def emit_cases(split):
    rows = 0
    pattern = os.path.join("tests", "evals", "*", "evals.json")
    for path in sorted(glob.glob(pattern)):
        skill_dir = os.path.basename(os.path.dirname(path))
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        for item in data.get("trigger_evals", {}).get(split, []):
            prompt = " ".join(item["prompt"].split())
            line = "\t".join([skill_dir, str(item["id"]), item["expected"], prompt])
            sys.stdout.write(line + "\n")
            rows += 1
    if rows == 0:
        sys.stderr.write("ERROR: no cases found for split '%s'\n" % split)
        return 1
    return 0


def read_transcript(path):
    """Return (skills_invoked, first_tool, model, result_subtype)."""
    found, first, model, result = [], None, None, None
    if not os.path.exists(path):
        return found, first, model, result
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except ValueError:
                continue
            if obj.get("type") == "system" and obj.get("subtype") == "init":
                model = obj.get("model") or model
            if obj.get("type") == "result":
                result = obj.get("subtype")
            content = (obj.get("message") or {}).get("content") or []
            for chunk in content:
                if not isinstance(chunk, dict) or chunk.get("type") != "tool_use":
                    continue
                if first is None:
                    first = chunk.get("name")
                if chunk.get("name") == "Skill":
                    name = (chunk.get("input") or {}).get("skill")
                    if name and name not in found:
                        found.append(name)
    return found, first, model, result


def score(outdir, split):
    cases_path = os.path.join(outdir, "cases.tsv")
    if not os.path.exists(cases_path):
        sys.stderr.write("ERROR: %s not found\n" % cases_path)
        return 1

    cases, models, empty = [], set(), []
    with open(cases_path, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line:
                continue
            skill_dir, cid, expected, prompt = line.split("\t", 3)
            transcript = os.path.join(outdir, cid + ".jsonl")
            found, first, model, result = read_transcript(transcript)
            if model:
                models.add(model)
            if not os.path.exists(transcript) or os.path.getsize(transcript) == 0:
                empty.append(cid)
            # Strip any plugin namespace; skills are scored by bare name.
            bare = [s.split(":")[-1] for s in found]
            hit = skill_dir in bare
            correct = hit if expected == "trigger" else not hit
            cases.append(dict(
                skill=skill_dir, id=cid, expected=expected, prompt=prompt,
                invoked=bare, sibling=[s for s in bare if s != skill_dir],
                hit=hit, correct=correct, first_tool=first, result=result,
            ))

    print("")
    header = "%-7s %-11s %-8s %-30s %s"
    print(header % ("case", "expected", "verdict", "invoked", "prompt"))
    print("-" * 104)
    for c in cases:
        print(header % (
            c["id"], c["expected"], "PASS" if c["correct"] else "FAIL",
            ",".join(c["invoked"]) or "(none)", c["prompt"][:46],
        ))

    print("")
    summary = {}
    for skill in sorted({c["skill"] for c in cases}):
        rows = [c for c in cases if c["skill"] == skill]
        trig = [c for c in rows if c["expected"] == "trigger"]
        near = [c for c in rows if c["expected"] == "no-trigger"]
        th = sum(1 for c in trig if c["hit"])
        nh = sum(1 for c in near if c["hit"])
        tr = float(th) / len(trig) if trig else 0.0
        nr = float(nh) / len(near) if near else 0.0
        ok = tr >= 0.5 and nr < 0.5
        summary[skill] = dict(
            should_trigger="%d/%d" % (th, len(trig)), should_trigger_rate=round(tr, 3),
            near_miss="%d/%d" % (nh, len(near)), near_miss_rate=round(nr, 3),
            gate="PASS" if ok else "FAIL",
        )
        print("%s: should-trigger %d/%d (%.2f >= 0.5), near-miss %d/%d (%.2f < 0.5) -> %s"
              % (skill, th, len(trig), tr, nh, len(near), nr, "PASS" if ok else "FAIL"))

    correct = sum(1 for c in cases if c["correct"])
    print("")
    print("overall: %d/%d correct" % (correct, len(cases)))
    print("model(s): %s" % (", ".join(sorted(models)) or "UNKNOWN"))
    if empty:
        print("WARNING: empty transcripts: %s" % ", ".join(empty))
    if split == "train":
        print("NOTE: train split -- tuning only. This is not the ship gate.")
    else:
        gates = [v["gate"] for v in summary.values()]
        print("SHIP GATE: %s" % ("PASS" if all(g == "PASS" for g in gates) else "FAIL"))

    results = os.path.join(outdir, "results.json")
    with open(results, "w", encoding="utf-8") as fh:
        json.dump(dict(split=split, models=sorted(models), summary=summary,
                       correct=correct, total=len(cases), empty=empty,
                       cases=cases), fh, indent=2)
    print("wrote %s" % results)
    return 0


def main(argv):
    if len(argv) < 2:
        sys.stderr.write(__doc__)
        return 2
    cmd = argv[1]
    if cmd == "cases" and len(argv) == 3:
        return emit_cases(argv[2])
    if cmd == "score" and len(argv) == 4:
        return score(argv[2], argv[3])
    sys.stderr.write(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
