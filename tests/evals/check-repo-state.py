"""Repo-state checker for the content evals.

Driven by check-repo-state.sh. Two subcommands:

  snapshot <owner/repo> <outdir> [--pr N]
  check <scenario> <owner/repo> <outdir> [--pr N] [--pre DIR]
        [--expect-title TITLE]

`snapshot` reads the server state a scenario is graded on and saves
it: the raw output of every read under <outdir>/raw/, and a digest
in <outdir>/snapshot.json. `check` takes a fresh snapshot, then
asserts the scenario's expected state against it. S3, S4 and S5 need
a snapshot taken BEFORE the skill ran, passed as --pre.

This settles the repo-state half of the eval expectations only. The
transcript half -- checkpoint ordering, read-back after each
mutation, report content -- stays with the human grader, and every
expectation this script does not settle is listed at the end of a
run as left to the grader.

Every read is a GET. Nothing here mutates a repository.
"""

import argparse
import base64
import datetime
import glob
import json
import os
import re
import subprocess
import sys
import urllib.parse

import yaml

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TEMPLATE = os.path.join(
    ROOT, "skills", "enforce-conventional-commits", "assets", "pr-title-workflow.yml")
EVALS_GLOB = os.path.join(ROOT, "tests", "evals", "*", "evals.json")

WORKFLOW_PATH = ".github/workflows/pr-title.yml"
RULESET_NAME = "conventional-commits-main"
RULE_TYPES = {"deletion", "non_fast_forward", "pull_request", "required_status_checks"}

# The eval expectation each assertion settles, as "<eval>#<n>" with n
# 1-based into that eval's `expectations` array. The second element
# says whether server state settles the WHOLE expectation (False) or
# only its state half (True) -- e.g. "the check is polled and reported
# as passing": state shows it passed, only the transcript shows it was
# polled. Every ref is resolved against evals.json before anything
# runs; one that stops resolving is an error, not a skipped check.
CITES = {
    "L1": ("A-CE1#3", False),
    "L2": ("A-CE1#5", False),
    "L3": ("A-CE1#6", False),
    "ORDER": ("A-CE1#4", False),
    "S2_L12": ("A-CE2#2", True),
    "S2_GATE": ("A-CE2#3", True),
    "TITLE": ("B-CE1#3", True),
    "READBACK": ("B-CE1#4", True),
    "CHECK": ("B-CE1#5", True),
    "P2_BANG": ("B-CE2#1", False),
    "P2_FOOTER": ("B-CE2#2", False),
    "P2_CHECK": ("B-CE2#4", True),
    "P5_TITLE": ("B-CE3#1", True),
    "P5_NOPOLL": ("B-CE3#2", True),
    "P5_NOSCAFFOLD": ("B-CE3#4", True),
}

SCENARIOS = ("S1", "S2", "S3", "S4", "S5", "P1", "P2", "P3", "P4", "P5")
NEEDS_PRE = ("S3", "S4", "S5")
NEEDS_PR = ("P1", "P2", "P3", "P4", "P5")


class Fatal(Exception):
    pass


# --- reading the eval files and the template --------------------------

def load_evals():
    """Return {eval_prefix: (scenario_or_None, [expectations])}."""
    found = {}
    for path in sorted(glob.glob(EVALS_GLOB)):
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        for ev in data.get("evals", []):
            prefix = ev.get("name", "").split(" ")[0]
            m = re.search(r"\bScenario (S\d+|P\d+)\b", ev.get("setup", ""))
            found[prefix] = (m.group(1) if m else None, ev.get("expectations", []))
    if not found:
        raise Fatal("no evals found under %s" % EVALS_GLOB)
    return found


def resolve_cites(evals):
    bad = []
    for key, (ref, _) in sorted(CITES.items()):
        prefix, _, n = ref.partition("#")
        exps = evals.get(prefix, (None, []))[1]
        if not n.isdigit() or not 1 <= int(n) <= len(exps):
            bad.append("%s -> %s" % (key, ref))
    if bad:
        raise Fatal("eval citations no longer resolve against evals.json: "
                    + ", ".join(bad))


def workflow_facts(text):
    doc = yaml.safe_load(text) or {}
    # PyYAML parses the bare key `on` as the boolean True.
    triggers = doc.get("on", doc.get(True, {})) or {}
    pr = triggers.get("pull_request") or {}
    jobs = (doc.get("jobs") or {}).values()
    steps = [s for j in jobs for s in (j.get("steps") or [])]
    types = [(s.get("with") or {}).get("types", "") for s in steps
             if (s.get("with") or {}).get("types")]
    return dict(
        trigger_types=list(pr.get("types") or []),
        job_names=[j.get("name", "") for j in jobs],
        uses=[s.get("uses") for s in steps if s.get("uses")],
        # A block scalar, one type per line: one string, not a list.
        types=types[0].split() if types else [],
        perm_pr=(doc.get("permissions") or {}).get("pull-requests", ""),
    )


def load_template():
    with open(TEMPLATE, encoding="utf-8") as fh:
        text = fh.read().replace("\r\n", "\n")
    facts = workflow_facts(text)
    action = [u for u in facts["uses"] if "action-semantic-pull-request" in u]
    if len(facts["job_names"]) != 1 or not action or not facts["types"]:
        raise Fatal("cannot read job name, action, and types from %s" % TEMPLATE)
    return dict(text=text, job_name=facts["job_names"][0], action=action[0],
                types=facts["types"], perm_pr=facts["perm_pr"])


# --- snapshot ------------------------------------------------------------

def run(args):
    proc = subprocess.run(args, capture_output=True, encoding="utf-8",
                          errors="replace")
    return proc.returncode, proc.stdout, proc.stderr


class Snapshotter:
    def __init__(self, outdir):
        self.raw = os.path.join(outdir, "raw")
        os.makedirs(self.raw, exist_ok=True)

    def save(self, name, status, body):
        with open(os.path.join(self.raw, name + ".json"), "w",
                  encoding="utf-8", newline="\n") as fh:
            fh.write(body)
        with open(os.path.join(self.raw, name + ".status"), "w",
                  encoding="utf-8", newline="\n") as fh:
            fh.write("%d\n" % status)

    def api(self, name, path):
        """GET path; return (status, parsed body). 4xx is data, not failure."""
        code, out, err = run(["gh", "api", path])
        if code == 0:
            status = 200
        else:
            m = re.search(r"\(HTTP (\d{3})\)", err)
            if not m:
                raise Fatal("gh api %s failed without an HTTP status: %s"
                            % (path, err.strip()))
            status = int(m.group(1))
        self.save(name, status, out)
        try:
            body = json.loads(out) if out.strip() else None
        except ValueError:
            raise Fatal("gh api %s returned non-JSON output" % path)
        return status, body


def snapshot(repo, outdir, pr, tpl):
    s = Snapshotter(outdir)
    base = "repos/" + repo
    snap = {}

    code, login, err = run(["gh", "api", "user", "--jq", ".login"])
    if code != 0:
        raise Fatal("cannot read the authenticated gh account: " + err.strip())
    _, ver, _ = run(["gh", "--version"])
    snap["meta"] = dict(
        repo=repo, login=login.strip(), gh=(ver.splitlines() or ["?"])[0],
        taken_at=datetime.datetime.now(datetime.timezone.utc)
        .strftime("%Y-%m-%dT%H:%M:%SZ"),
    )

    status, body = s.api("repo", base)
    if status != 200:
        raise Fatal("cannot read %s (HTTP %d)" % (base, status))
    keys = ("default_branch", "visibility", "allow_squash_merge",
            "allow_merge_commit", "allow_rebase_merge",
            "squash_merge_commit_title", "squash_merge_commit_message",
            "delete_branch_on_merge")
    snap["repo"] = {k: body.get(k) for k in keys}
    default = body["default_branch"]

    status, body = s.api("workflow", base + "/contents/" + WORKFLOW_PATH)
    wf = dict(status=status, sha=None, content=None)
    if status == 200:
        wf["sha"] = body.get("sha")
        wf["content"] = base64.b64decode(body.get("content", "")) \
            .decode("utf-8", "replace").replace("\r\n", "\n")
    elif status != 404:
        raise Fatal("unexpected HTTP %d reading %s" % (status, WORKFLOW_PATH))
    snap["workflow"] = wf

    snap["workflow_commit"] = None
    if status == 200:
        st, body = s.api("workflow-commit",
                         base + "/commits?path=" + WORKFLOW_PATH + "&per_page=1")
        if st == 200 and body:
            snap["workflow_commit"] = dict(
                sha=body[0]["sha"], date=body[0]["commit"]["committer"]["date"])

    status, body = s.api("rulesets", base + "/rulesets")
    items = []
    if status == 200:
        for entry in body or []:
            st, detail = s.api("ruleset-%s" % entry["id"],
                               "%s/rulesets/%s" % (base, entry["id"]))
            if st != 200:
                raise Fatal("cannot read ruleset %s (HTTP %d)" % (entry["id"], st))
            items.append({k: detail.get(k) for k in (
                "id", "name", "enforcement", "conditions", "bypass_actors",
                "rules", "created_at", "updated_at")})
    elif status not in (403, 404):
        raise Fatal("unexpected HTTP %d reading rulesets" % status)
    snap["rulesets"] = dict(status=status, items=items)

    status, body = s.api("effective-rules", "%s/rules/branches/%s"
                         % (base, urllib.parse.quote(default, safe="")))
    snap["effective"] = dict(
        status=status,
        types=sorted({r.get("type") for r in body or []}) if status == 200 else [])

    status, body = s.api("head", "%s/branches/%s"
                         % (base, urllib.parse.quote(default, safe="")))
    if status != 200:
        raise Fatal("cannot read branch %s (HTTP %d)" % (default, status))
    snap["head"] = body["commit"]["sha"]

    snap["pr"] = None
    snap["check_runs"] = []
    if pr is not None:
        code, out, err = run(["gh", "pr", "view", str(pr), "-R", repo, "--json",
                              "number,title,body,state,baseRefName,headRefName,headRefOid"])
        if code != 0:
            raise Fatal("cannot read PR %s: %s" % (pr, err.strip()))
        s.save("pr", 200, out)
        snap["pr"] = json.loads(out)
        status, body = s.api("check-runs", "%s/commits/%s/check-runs?check_name=%s&filter=all"
                             % (base, snap["pr"]["headRefOid"],
                                urllib.parse.quote(tpl["job_name"])))
        if status != 200:
            raise Fatal("cannot read check-runs (HTTP %d)" % status)
        runs = [{k: r.get(k) for k in ("id", "status", "conclusion",
                                       "started_at", "completed_at")}
                for r in body.get("check_runs", [])]
        snap["check_runs"] = sorted(runs, key=lambda r: r["started_at"] or "")

    with open(os.path.join(outdir, "snapshot.json"), "w",
              encoding="utf-8", newline="\n") as fh:
        json.dump(snap, fh, indent=2)
        fh.write("\n")
    return snap


# --- assertions ------------------------------------------------------------

class Report:
    def __init__(self):
        self.rows = []
        self.cited = {}

    def check(self, cond, key, text):
        ref = CITES[key][0] if key else None
        if key:
            partial = CITES[key][1]
            self.cited[ref] = self.cited.get(ref, True) and partial
        self.rows.append(dict(ok=bool(cond), ref=ref, text=text))
        print("%-5s %-8s %s" % ("ok" if cond else "FAIL", ref or "-", text))
        return bool(cond)

    def info(self, text):
        self.rows.append(dict(ok=None, ref=None, text=text))
        print("info  %-8s %s" % ("", text))


def parse_time(value):
    return datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))


def assert_l1(rep, snap, key):
    r = snap["repo"]
    rep.check(r["allow_squash_merge"] is True, key, "allow_squash_merge is true")
    rep.check(r["allow_merge_commit"] is False, key, "allow_merge_commit is false")
    rep.check(r["allow_rebase_merge"] is False, key, "allow_rebase_merge is false")
    rep.check(r["squash_merge_commit_title"] == "PR_TITLE", key,
              "squash_merge_commit_title is PR_TITLE (found %s)"
              % r["squash_merge_commit_title"])
    rep.info("squash_merge_commit_message is %s, delete_branch_on_merge is %s"
             % (r["squash_merge_commit_message"], r["delete_branch_on_merge"]))


def assert_l2(rep, snap, tpl, key):
    wf = snap["workflow"]
    if not rep.check(wf["status"] == 200, key,
                     "%s exists (HTTP %d)" % (WORKFLOW_PATH, wf["status"])):
        return
    try:
        facts = workflow_facts(wf["content"])
    except yaml.YAMLError:
        rep.check(False, key, "%s parses as YAML" % WORKFLOW_PATH)
        return
    rep.check(tpl["job_name"] in facts["job_names"], key,
              "job name is '%s'" % tpl["job_name"])
    rep.check("edited" in facts["trigger_types"], key,
              "pull_request types include 'edited'")
    rep.check(tpl["action"] in facts["uses"], key, "action pinned to " + tpl["action"])
    rep.check(facts["perm_pr"] == tpl["perm_pr"], key,
              "permissions.pull-requests is %s" % tpl["perm_pr"])
    if facts["types"] == tpl["types"]:
        rep.info("allowed types are the template's: " + ",".join(facts["types"]))
    else:
        rep.info("allowed types CUSTOMIZED: %s -- permitted, and the final "
                 "report must record it" % ",".join(facts["types"]))
    rep.info("workflow content %s the template (CRLF-normalized), sha %s"
             % ("is byte-identical to" if wf["content"] == tpl["text"]
                else "differs from", wf["sha"]))


def ours(snap):
    return [r for r in snap["rulesets"]["items"] if r["name"] == RULESET_NAME]


def assert_l3(rep, snap, tpl, key):
    rs = snap["rulesets"]
    if not rep.check(rs["status"] == 200, key,
                     "rulesets are readable (HTTP %d)" % rs["status"]):
        return
    mine = ours(snap)
    if not rep.check(len(mine) == 1, key,
                     "exactly one ruleset named %s (found %d)" % (RULESET_NAME, len(mine))):
        return
    r = mine[0]
    rep.info("ruleset %s, created %s" % (r["id"], r["created_at"]))
    rep.check(r["enforcement"] == "active", key,
              "enforcement is active (found %s)" % r["enforcement"])
    include = ((r.get("conditions") or {}).get("ref_name") or {}).get("include") or []
    branch = "refs/heads/" + snap["repo"]["default_branch"]
    rep.check("~DEFAULT_BRANCH" in include or branch in include, key,
              "targets the default branch (include: %s)" % include)
    rep.check(r["bypass_actors"] == [], key,
              "bypass list is empty (found %d)" % len(r["bypass_actors"] or []))
    types = {x.get("type") for x in r["rules"] or []}
    rep.check(RULE_TYPES <= types, key,
              "rules include %s" % ", ".join(sorted(RULE_TYPES)))
    params = {x.get("type"): x.get("parameters") or {} for x in r["rules"] or []}
    rep.check(params.get("pull_request", {}).get("required_approving_review_count") == 0,
              key, "pull_request requires 0 approvals")
    contexts = [c.get("context") for c in params.get("required_status_checks", {})
                .get("required_status_checks", [])]
    rep.check(contexts == [tpl["job_name"]], key,
              "required status check is exactly '%s' (found %s)"
              % (tpl["job_name"], contexts))


def assert_effective(rep, snap, key, want=RULE_TYPES):
    eff = snap["effective"]
    if rep.check(eff["status"] == 200, key,
                 "effective rules are readable (HTTP %d)" % eff["status"]):
        missing = sorted(set(want) - set(eff["types"]))
        rep.check(not missing, key, "effective rules on %s include %s%s"
                  % (snap["repo"]["default_branch"], ", ".join(sorted(want)),
                     " (missing %s)" % ", ".join(missing) if missing else ""))


def assert_order(rep, snap, key):
    commit, mine = snap["workflow_commit"], ours(snap)
    if not commit or len(mine) != 1:
        rep.check(False, key, "workflow committed before the ruleset was created "
                  "(cannot compare: workflow commit or ruleset missing)")
        return
    rep.check(parse_time(commit["date"]) <= parse_time(mine[0]["created_at"]), key,
              "workflow committed (%s) before the ruleset was created (%s)"
              % (commit["date"], mine[0]["created_at"]))


def fingerprint(snap):
    rs = snap["rulesets"]
    return dict(
        settings=snap["repo"],
        workflow=[snap["workflow"]["status"], snap["workflow"]["sha"]],
        rulesets=[rs["status"], sorted([r["id"], r["updated_at"]] for r in rs["items"])],
        effective=[snap["effective"]["status"], snap["effective"]["types"]],
        head=snap["head"],
    )


def assert_unchanged(rep, pre, post):
    a, b = fingerprint(pre), fingerprint(post)
    for k in a:
        was, now = a[k], b[k]
        if isinstance(was, dict):
            changed = sorted(f for f in was if was[f] != now.get(f))
            was = {f: was[f] for f in changed}
            now = {f: now.get(f) for f in changed}
        rep.check(a[k] == b[k], None, "%s unchanged since the pre-run snapshot%s"
                  % (k, "" if a[k] == b[k] else ": %s -> %s"
                     % (json.dumps(was), json.dumps(now))))


TITLE_RE = re.compile(r"^(?P<type>[a-z]+)(\((?P<scope>[^()]+)\))?(?P<bang>!)?: (?P<desc>\S.*)$")


def assert_title(rep, snap, tpl, key, want_type=None, no_scope=False):
    title = snap["pr"]["title"]
    rep.info("PR #%s %s, %s -> %s: %s" % (
        snap["pr"]["number"], snap["pr"]["state"], snap["pr"]["headRefName"],
        snap["pr"]["baseRefName"], title))
    m = TITLE_RE.match(title)
    if not rep.check(m and m.group("type") in tpl["types"], key,
                     "title is type[(scope)][!]: description, type one of the template's"):
        return None
    desc = m.group("desc")
    rep.check(desc[0] == desc[0].lower(), key, "description starts lowercase")
    rep.check(not desc.endswith("."), key, "no trailing period")
    rep.check(len(title) <= 72, key, "title is <= 72 characters (%d)" % len(title))
    if want_type:
        rep.check(m.group("type") == want_type, key,
                  "type is %s (found %s)" % (want_type, m.group("type")))
    if no_scope:
        rep.check(m.group("scope") is None, key, "no scope")
    return m


def assert_check_green(rep, snap, tpl, key):
    runs = snap["check_runs"]
    last = runs[-1] if runs else None
    rep.check(last and last["status"] == "completed" and last["conclusion"] == "success",
              key, "latest '%s' run is completed/success (found %s)"
              % (tpl["job_name"], "%s/%s" % (last["status"], last["conclusion"])
                 if last else "no runs"))


# --- scenarios -------------------------------------------------------------

def run_scenario(name, rep, snap, pre, tpl, expect_title):
    if name in ("S1", "S3"):
        assert_l1(rep, snap, "L1")
        assert_l2(rep, snap, tpl, "L2")
        assert_l3(rep, snap, tpl, "L3")
        assert_effective(rep, snap, "L3")
        assert_order(rep, snap, "ORDER")
        if name == "S3":
            assert_unchanged(rep, pre, snap)
    elif name == "S2":
        assert_l1(rep, snap, "S2_L12")
        assert_l2(rep, snap, tpl, "S2_L12")
        rep.check(snap["repo"]["visibility"] == "private", None,
                  "repository is private (scenario setup)")
        rep.check(snap["rulesets"]["status"] == 403, "S2_GATE",
                  "rulesets read is plan-gated (HTTP %d)" % snap["rulesets"]["status"])
        rep.check(snap["effective"]["status"] == 403, "S2_GATE",
                  "effective-rules read is plan-gated (HTTP %d)" % snap["effective"]["status"])
    elif name == "S4":
        # S4 has no eval entry, so these settle no expectation by ref.
        assert_l1(rep, snap, None)
        assert_l3(rep, snap, tpl, None)
        post = {r["id"]: r for r in snap["rulesets"]["items"]}
        stray = [r for r in pre["rulesets"]["items"] if r["name"] != RULESET_NAME]
        rep.check(stray, None, "the pre-run snapshot holds a stray ruleset to reconcile")
        for r in stray:
            after = post.get(r["id"])
            rep.check(after and after["updated_at"] == r["updated_at"], None,
                      "stray ruleset %s '%s' untouched (coexist default; updated_at %s)"
                      % (r["id"], r["name"], after and after["updated_at"]))
        union = {x.get("type") for r in snap["rulesets"]["items"]
                 if r["enforcement"] == "active" for x in r["rules"] or []}
        assert_effective(rep, snap, None, want=union)
    elif name == "S5":
        rep.info("pre-run snapshot taken as %s, post-run as %s"
                 % (pre["meta"]["login"], snap["meta"]["login"]))
        assert_unchanged(rep, pre, snap)
    elif name == "P1":
        assert_title(rep, snap, tpl, "TITLE", want_type="fix", no_scope=True)
        assert_check_green(rep, snap, tpl, "CHECK")
    elif name == "P2":
        m = assert_title(rep, snap, tpl, None)
        rep.check(m and m.group("bang"), "P2_BANG", "title carries '!' before the colon")
        body = (snap["pr"]["body"] or "").replace("\r\n", "\n").strip()
        last = re.split(r"\n\s*\n", body)[-1] if body else ""
        rep.check(last.startswith("BREAKING CHANGE: "), "P2_FOOTER",
                  "last body paragraph is a 'BREAKING CHANGE: ' footer")
        rep.info("squash_merge_commit_message is %s -- whether the footer rides "
                 "into the squash commit" % snap["repo"]["squash_merge_commit_message"])
        assert_check_green(rep, snap, tpl, "P2_CHECK")
    elif name == "P3":
        assert_title(rep, snap, tpl, None, want_type="docs")
        assert_check_green(rep, snap, tpl, None)
    elif name == "P4":
        assert_title(rep, snap, tpl, None)
        rep.check(snap["pr"]["title"] != "stuff", None, "title is no longer 'stuff'")
        concl = [r["conclusion"] for r in snap["check_runs"]]
        red = [i for i, c in enumerate(concl) if c == "failure"]
        rep.check(red and "success" in concl[red[0] + 1:], None,
                  "check went red -> green (runs: %s)" % ", ".join(map(str, concl)))
        rep.info("%d failed run(s) before green -- the retry path is exercised only "
                 "by a rejection AFTER the skill retitled" % len(red))
        assert_check_green(rep, snap, tpl, None)
    elif name == "P5":
        assert_title(rep, snap, tpl, "P5_TITLE")
        rep.check(not snap["check_runs"], "P5_NOPOLL",
                  "no '%s' runs exist to poll" % tpl["job_name"])
        r = snap["repo"]
        rep.check(snap["workflow"]["status"] == 404, "P5_NOSCAFFOLD",
                  "%s absent (HTTP %d)" % (WORKFLOW_PATH, snap["workflow"]["status"]))
        rep.check(r["allow_squash_merge"] and r["allow_merge_commit"]
                  and r["allow_rebase_merge"], "P5_NOSCAFFOLD",
                  "merge settings still GitHub defaults (all three methods enabled)")
        rep.check(snap["rulesets"]["status"] == 200 and not snap["rulesets"]["items"],
                  "P5_NOSCAFFOLD", "no rulesets (HTTP %d, %d found)"
                  % (snap["rulesets"]["status"], len(snap["rulesets"]["items"])))
    if expect_title is not None and snap["pr"]:
        rep.check(snap["pr"]["title"] == expect_title, "READBACK",
                  "server title equals the transcript's exactly")


def left_to_grader(name, evals, rep):
    rows = []
    for prefix, (scenario, exps) in sorted(evals.items()):
        if scenario != name:
            continue
        for i, text in enumerate(exps, 1):
            ref = "%s#%d" % (prefix, i)
            if ref not in rep.cited:
                rows.append((ref, "grader", text))
            elif rep.cited[ref]:
                rows.append((ref, "state half checked", text))
    return rows


def cmd_check(a, tpl, evals):
    if a.scenario in NEEDS_PRE and not a.pre:
        raise Fatal("%s compares against a pre-run snapshot: pass --pre DIR" % a.scenario)
    if a.scenario in NEEDS_PR and a.pr is None:
        raise Fatal("%s grades a pull request: pass --pr N" % a.scenario)
    pre = None
    if a.pre:
        if os.path.abspath(a.pre) == os.path.abspath(a.outdir):
            raise Fatal("--pre and <outdir> must differ; the check overwrites <outdir>")
        with open(os.path.join(a.pre, "snapshot.json"), encoding="utf-8") as fh:
            pre = json.load(fh)
        if pre["meta"]["repo"] != a.repo:
            raise Fatal("--pre snapshot is of %s, not %s" % (pre["meta"]["repo"], a.repo))

    snap = snapshot(a.repo, a.outdir, a.pr, tpl)
    print("scenario: %s   repo: %s   as: %s   at: %s\n" % (
        a.scenario, a.repo, snap["meta"]["login"], snap["meta"]["taken_at"]))
    rep = Report()
    run_scenario(a.scenario, rep, snap, pre, tpl, a.expect_title)

    grader = left_to_grader(a.scenario, evals, rep)
    if grader:
        print("\nleft to the grader (transcript):")
        for ref, how, text in grader:
            print("  %-8s %-19s %s" % (ref, how, text))

    passed = sum(1 for r in rep.rows if r["ok"] is True)
    failed = sum(1 for r in rep.rows if r["ok"] is False)
    with open(os.path.join(a.outdir, "check.json"), "w",
              encoding="utf-8", newline="\n") as fh:
        json.dump(dict(scenario=a.scenario, meta=snap["meta"], passed=passed,
                       failed=failed, rows=rep.rows,
                       left_to_grader=[dict(ref=r, how=h, text=t) for r, h, t in grader]),
                  fh, indent=2)
        fh.write("\n")
    print("\nraw read-backs: %s" % os.path.join(a.outdir, "raw"))
    print("\n%d checks passed, %d failed" % (passed, failed))
    return 1 if failed else 0


def main(argv):
    p = argparse.ArgumentParser(prog="check-repo-state", description=__doc__.split("\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("snapshot")
    s.add_argument("repo")
    s.add_argument("outdir")
    s.add_argument("--pr", type=int)
    c = sub.add_parser("check")
    c.add_argument("scenario", choices=SCENARIOS)
    c.add_argument("repo")
    c.add_argument("outdir")
    c.add_argument("--pr", type=int)
    c.add_argument("--pre")
    c.add_argument("--expect-title")
    a = p.parse_args(argv[1:])
    if not re.match(r"^[\w.-]+/[\w.-]+$", a.repo):
        p.error("repo must be owner/name, got '%s'" % a.repo)

    try:
        evals = load_evals()
        resolve_cites(evals)
        tpl = load_template()
        if a.cmd == "snapshot":
            snap = snapshot(a.repo, a.outdir, a.pr, tpl)
            print("snapshot of %s as %s at %s -> %s" % (
                a.repo, snap["meta"]["login"], snap["meta"]["taken_at"],
                os.path.join(a.outdir, "snapshot.json")))
            return 0
        return cmd_check(a, tpl, evals)
    except Fatal as e:
        sys.stderr.write("ERROR: %s\n" % e)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
