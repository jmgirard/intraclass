#!/usr/bin/env python3
"""Re-derive every registered claim in `data-raw/record-claims.tsv` (M102).

WHY THIS EXISTS
---------------
A figure transcribed out of an artifact and into tracking prose -- a count, a
worst-case step, an inventory -- drifts silently. Nothing re-runs the artifact,
so a sentence can be read by five successive review passes and re-derived by
none of them (M100 passes 1-5). This checker closes that gap for figures whose
author *registers* them: the ledger pairs each claim with the command that
settles it and the output that command must produce, and CI re-runs every pair.

REGISTRATION, NOT DETECTION
---------------------------
The checker's only inputs are ledger rows and `[claim:<id>]` citations found in
the scope files. It never scans prose for unregistered figures. Ground: a
detector over free prose either misses the claim classes nobody thought to
pattern-match or floods the author with candidates, and both failure modes end
with the detector switched off; a registered row is instead a promise its
author made, which CI then keeps. The cost is stated rather than hidden -- an
unregistered figure is unchecked, and this tool will never tell you one exists.

ROW GRAMMAR
-----------
`data-raw/record-claims.tsv` is tab-separated. Its header names exactly these
columns, in this order, and a row that violates any rule below exits non-zero:

  column: id -- lowercase slug (`[a-z][a-z0-9-]*`), unique across the ledger
  column: record -- path of the record stating the claim; must exist
  column: kind -- `presence` or `absence`; author-declared, never inferred
  column: shape -- one of the command shapes below
  column: claim -- what the record asserts, in the author's own words
  column: command -- the command that settles it
  column: expected_rc -- the exit status the command must return (0-255)
  column: expected_match -- a Python regex the command's stdout must fullmatch
  column: falsifier_command -- required when `kind = absence`; `-` otherwise
  column: disposition -- `cited` (a citation is required) or `uncited`
  column: reason -- required when `disposition = uncited`

Each command runs from the repo root under a bounded per-row timeout. Its
stdout is stripped and matched with `re.fullmatch(expected_match, out, DOTALL)`.
A differing exit status, a non-matching output, or a timeout exits non-zero.

COMMAND SHAPES
--------------
A command is tokenized with `shlex.split` and executed directly -- there is no
shell, so a pipeline, a redirection, a substitution or a chained second command
is not merely discouraged but inexpressible. The leading token must be the
shape's program (and its subcommand, where the shape names one). Everything
here runs on the `check-references` runner, which has `python3`, the POSIX
utilities and a working-tree `git`, and has neither R nor network access:

  shape: ls -- list committed paths; tokens containing `*`/`?` are globbed
  shape: grep -- search a file's text, usually with `-c` for a count
  shape: awk -- arithmetic or field selection over a committed table
  shape: python3 -- a `-c` predicate, or a helper script under `data-raw/`
  shape: git-grep -- `git grep` over the working tree (never over history)

REFUSED COMMAND FORMS
---------------------
The CI checkout is depth-1 and has no `main` ref, so a command that reads
repository history would pass locally and fail there for reasons that have
nothing to do with the claim. A `git` command naming any of these is refused
with its reason before it is ever run:

  refused: git-history-subcommand -- a `log`, `blame`, `rev-list` or `show`
  refused: rev-range -- a `<rev>..<rev>` or `<rev>...<rev>` range
  refused: non-head-ref -- a ref other than `HEAD` (`origin/...`, `refs/...`,
    `main`, `master`, or an `@{...}` reflog form)

Refusal is scoped to `git` commands, so a `grep` pattern containing `..` is
untouched; a `git grep` pattern that needs `..` writes it as `\\.\\.` or moves to
the `grep` shape.

FAILURE ROUTES
--------------
Every way this checker reaches a non-zero exit carries a route id. `--self-test`
holds a probe per route, drives each to its failure on constructed input against
a passing control, and then excises each route's sentinel-delimited block from a
temp copy of this script to confirm exactly that route's own probe goes quiet:

  route: grammar -- a header or row violating the grammar above
  route: unknown-shape -- a shape with no dispatch, or a command that is not it
  route: refused-form -- a command naming a refused history-dependent form
  route: rc-mismatch -- an exit status differing from `expected_rc`
  route: match-mismatch -- stdout not fullmatching `expected_match`
  route: timeout -- a command exceeding the per-row timeout
  route: unresolved-citation -- a `[claim:<id>]` citation with no ledger row
  route: uncited-row -- a `cited` row that no scope file cites
  route: absence-no-falsifier -- an `absence` row carrying no falsifier
  route: kind-misregistered -- an absence-shaped expectation declared `presence`
  route: falsifier-passes -- a falsifier that meets the row's own expectation
  route: shape-parity -- the docstring's shape list disagreeing with dispatch
  route: refused-parity -- the docstring's refused list disagreeing with dispatch
  route: route-parity -- the docstring's route list disagreeing with the probes
  route: scope-parity -- the decision entry's scope list disagreeing with SCOPE
  route: rule-probe-unknown -- a decision rule naming a probe id that is absent

Usage (from the repo root):
    python3 data-raw/check-record-claims.py             # re-derive every row
    python3 data-raw/check-record-claims.py --probes    # per-route probe report
    python3 data-raw/check-record-claims.py --self-test # probes + excision
"""

import glob
import os
import re
import shlex
import subprocess
import sys
import tempfile

LEDGER = "data-raw/record-claims.tsv"
DECISIONS = "cairn/DECISIONS.md"
D_ENTRY = "### D-020"
DEFAULT_TIMEOUT = 60

# The files whose `[claim:<id>]` citations this checker reads. All four are
# current knowledge under D-045 -- a figure proven wrong in them is corrected
# where it sits. History (decision entries, work logs, archives) is excluded
# because IP4 forbids editing it: a citation could not be added later, and a
# drifted figure could never be repaired. Asserted equal to the list the
# decision entry states, so the artifact under test cannot pick its own scope.
SCOPE = (
    "cairn/ROADMAP.md",
    "cairn/LESSONS.md",
    "cairn/DESIGN.md",
    "data-raw/README.md",
)

# id -> (program, required subcommand or None, glob its arguments)
SHAPES = {
    "ls": ("ls", None, True),
    "grep": ("grep", None, False),
    "awk": ("awk", None, False),
    "python3": ("python3", None, False),
    "git-grep": ("git", "grep", False),
}

CITATION_RE = re.compile(r"\[claim:([a-z][a-z0-9-]*)\]")
ABSENCE_PATTERNS = {"^$", "^0$", "0", "^0+$", "^\\s*$"}

# One command per refused form, each constructing that form and nothing else.
# These are what `--self-test` runs to show every stated form is really
# detected, and what the refused-form parity check derives its coded set from:
# a form stated in the docstring but detected by no sample is a dead rule.
REFUSED_SAMPLES = {
    "git-history-subcommand": "git log --oneline",
    "rev-range": "git grep -c token main..HEAD",
    "non-head-ref": "git grep -c token origin/main",
}


# --------------------------------------------------------------------------
# Docstring parsing -- the checker's stated contract, read back as data
# --------------------------------------------------------------------------


def doc_list(kind, doc=None):
    """Ids stated in the docstring as `<kind>: <id> -- ...`, in document order."""
    text = __doc__ if doc is None else doc
    return [m.group(1) for m in re.finditer(rf"^\s*{kind}:\s*(\S+)\s+--", text, re.M)]


COLUMNS = doc_list("column")


# --------------------------------------------------------------------------
# Refused command forms
# --------------------------------------------------------------------------


def refused_hits(command):
    """(form-id, why) for every refused history-dependent form in `command`."""
    try:
        argv = shlex.split(command)
    except ValueError:
        return []
    if not argv or argv[0] != "git":
        return []
    hits = []
    if len(argv) > 1 and argv[1] in ("log", "blame", "rev-list", "show"):
        hits.append(
            ("git-history-subcommand", f"`git {argv[1]}` reads repository history")
        )
    revs = []
    for tok in argv[2:]:
        if tok == "--":
            break
        if not tok.startswith("-"):
            revs.append(tok)
    for tok in revs:
        if re.search(r"\w\.\.\.?\w", tok):
            hits.append(("rev-range", f"{tok!r} is a revision range"))
        if (
            tok.startswith("origin/")
            or tok.startswith("refs/")
            or tok in ("main", "master")
            or "@{" in tok
        ):
            hits.append(("non-head-ref", f"{tok!r} names a ref other than HEAD"))
    return hits


# --------------------------------------------------------------------------
# Ledger
# --------------------------------------------------------------------------


def read_ledger(path=LEDGER, text=None):
    """Return (rows, header-level failures). Rows are dicts keyed by column."""
    if text is None:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    lines = [ln for ln in text.splitlines() if ln.strip() and not ln.startswith("#")]
    fails = []
    if not lines:
        fails.append(("grammar", f"{path}: no rows"))
        return [], fails
    header = lines[0].split("\t")
    # --- route:grammar ---
    if header != COLUMNS:
        fails.append(
            ("grammar", f"{path}: header {header} does not match the stated grammar "
             f"{COLUMNS}")
        )
    # --- /route:grammar ---
    rows = []
    seen = set()
    for offset, ln in enumerate(lines[1:], 2):
        parts = ln.split("\t")
        # --- route:grammar ---
        if len(parts) != len(COLUMNS):
            fails.append(
                ("grammar", f"{path}:{offset}: {len(parts)} fields, expected "
                 f"{len(COLUMNS)}")
            )
            continue
        # --- /route:grammar ---
        row = dict(zip(COLUMNS, parts))
        row["_line"] = offset
        # --- route:grammar ---
        if row["id"] in seen:
            fails.append(("grammar", f"{path}:{offset}: duplicate id {row['id']!r}"))
        # --- /route:grammar ---
        seen.add(row["id"])
        rows.append(row)
    return rows, fails


def absence_shaped(row):
    """Would this row pass on an empty/zero result? (a classifier, not a rule)"""
    rc = row.get("expected_rc", "0")
    if rc.isdigit() and int(rc) != 0:
        return True
    pat = (row.get("expected_match") or "").strip()
    return pat in ABSENCE_PATTERNS or pat.startswith("(?!")


def validate_row(row, shapes=None):
    """Grammar, shape and registration checks that need no command run."""
    shapes = SHAPES if shapes is None else shapes
    tag = f"{LEDGER}:{row.get('_line', '?')}"
    fails = []
    # --- route:grammar ---
    if not re.fullmatch(r"[a-z][a-z0-9-]*", row.get("id") or ""):
        fails.append(("grammar", f"{tag}: id {row.get('id')!r} is not a lowercase slug"))
    if row.get("kind") not in ("presence", "absence"):
        fails.append(("grammar", f"{tag}: kind {row.get('kind')!r} is not presence|absence"))
    if not (row.get("claim") or "").strip():
        fails.append(("grammar", f"{tag}: empty claim"))
    if not (row.get("command") or "").strip():
        fails.append(("grammar", f"{tag}: empty command"))
    rc = row.get("expected_rc") or ""
    if not rc.isdigit() or int(rc) > 255:
        fails.append(("grammar", f"{tag}: expected_rc {rc!r} is not 0-255"))
    pat = (row.get("expected_match") or "").strip()
    if not pat:
        fails.append(("grammar", f"{tag}: empty expected_match"))
    else:
        try:
            re.compile(pat)
        except re.error as exc:
            fails.append(("grammar", f"{tag}: expected_match does not compile: {exc}"))
    if row.get("disposition") not in ("cited", "uncited"):
        fails.append(
            ("grammar", f"{tag}: disposition {row.get('disposition')!r} is not cited|uncited")
        )
    if row.get("disposition") == "uncited" and not (row.get("reason") or "").strip():
        fails.append(("grammar", f"{tag}: disposition uncited with no reason"))
    rec = row.get("record") or ""
    if not rec or not os.path.exists(rec):
        fails.append(("grammar", f"{tag}: record {rec!r} does not exist"))
    # --- /route:grammar ---
    spec = shapes.get(row.get("shape"))
    # --- route:unknown-shape ---
    if spec is None:
        fails.append(
            ("unknown-shape", f"{tag}: shape {row.get('shape')!r} is not one of "
             f"{sorted(shapes)}")
        )
    # --- /route:unknown-shape ---
    for col in ("command", "falsifier_command"):
        cmd = (row.get(col) or "-").strip()
        if cmd in ("", "-"):
            continue
        try:
            argv = shlex.split(cmd)
        except ValueError:
            argv = None
        # --- route:unknown-shape ---
        if argv is None:
            fails.append(("unknown-shape", f"{tag}: {col} does not tokenize: {cmd!r}"))
        elif spec is not None and (
            not argv
            or argv[0] != spec[0]
            or (spec[1] is not None and argv[1:2] != [spec[1]])
        ):
            fails.append(
                ("unknown-shape", f"{tag}: {col} is not shape {row.get('shape')!r}: {cmd!r}")
            )
        # --- /route:unknown-shape ---
        # --- route:refused-form ---
        for form, why in refused_hits(cmd):
            fails.append(("refused-form", f"{tag}: {col} refused ({form}) -- {why}"))
        # --- /route:refused-form ---
    # --- route:absence-no-falsifier ---
    if row.get("kind") == "absence" and (row.get("falsifier_command") or "-").strip() in ("", "-"):
        fails.append(
            ("absence-no-falsifier", f"{tag}: kind=absence with no falsifier_command -- "
             "a certifying command that cannot be shown to fail certifies nothing")
        )
    # --- /route:absence-no-falsifier ---
    # --- route:kind-misregistered ---
    if row.get("kind") == "presence" and absence_shaped(row):
        fails.append(
            ("kind-misregistered", f"{tag}: expectation is absence-shaped "
             f"(rc={row.get('expected_rc')!r}, match={row.get('expected_match')!r}) "
             "but kind=presence")
        )
    # --- /route:kind-misregistered ---
    return fails


# --------------------------------------------------------------------------
# Execution
# --------------------------------------------------------------------------


def _expand(argv, root):
    """Expand `*`/`?` tokens against the repo root (the `ls` shape only)."""
    base = root or "."
    out = [argv[0]]
    for tok in argv[1:]:
        if "*" not in tok and "?" not in tok:
            out.append(tok)
            continue
        hits = sorted(glob.glob(os.path.join(base, tok)))
        if hits:
            out.extend(os.path.relpath(h, base) for h in hits)
        else:
            out.append(tok)
    return out


def execute_row(row, timeout=DEFAULT_TIMEOUT, root=None, command=None):
    """Run one row's command and compare exit status and stdout."""
    tag = f"{LEDGER}:{row.get('_line', '?')} [{row.get('id')}]"
    cmd = row["command"] if command is None else command
    spec = SHAPES.get(row.get("shape"))
    argv = shlex.split(cmd)
    if spec is not None and spec[2]:
        argv = _expand(argv, root)
    fails = []
    timed_out = False
    rc, out = None, ""
    try:
        proc = subprocess.run(
            argv, cwd=root, capture_output=True, text=True, timeout=timeout
        )
        rc, out = proc.returncode, proc.stdout
    except subprocess.TimeoutExpired:
        timed_out = True
    except OSError as exc:
        fails.append(("rc-mismatch", f"{tag}: command not runnable: {exc}"))
        return fails
    # --- route:timeout ---
    if timed_out:
        fails.append(("timeout", f"{tag}: exceeded the {timeout}s per-row timeout"))
    # --- /route:timeout ---
    if timed_out:
        return fails
    # --- route:rc-mismatch ---
    if rc != int(row["expected_rc"]):
        fails.append(
            ("rc-mismatch", f"{tag}: exit {rc}, expected {row['expected_rc']} -- {cmd!r}")
        )
    # --- /route:rc-mismatch ---
    # --- route:match-mismatch ---
    if not re.fullmatch(row["expected_match"], out.strip(), re.DOTALL):
        fails.append(
            ("match-mismatch", f"{tag}: stdout {out.strip()!r} does not match "
             f"{row['expected_match']!r} -- the record's figure and the artifact "
             "disagree; fault the record, not the run")
        )
    # --- /route:match-mismatch ---
    return fails


def check_falsifiers(rows, timeout=DEFAULT_TIMEOUT, root=None):
    """Every absence row's falsifier must FAIL that row's own expectation."""
    fails = []
    for row in rows:
        if row.get("kind") != "absence":
            continue
        fc = (row.get("falsifier_command") or "-").strip()
        if fc in ("", "-"):
            continue
        res = execute_row(row, timeout=timeout, root=root, command=fc)
        # --- route:falsifier-passes ---
        if not res:
            fails.append(
                ("falsifier-passes", f"row {row.get('id')!r}: falsifier_command MET the "
                 "row's expectation, so the row would pass over its own violation")
            )
        # --- /route:falsifier-passes ---
    return fails


# --------------------------------------------------------------------------
# Citations
# --------------------------------------------------------------------------


def read_scope(scope=None, root=None):
    texts = {}
    for path in scope or SCOPE:
        full = os.path.join(root, path) if root else path
        with open(full, encoding="utf-8") as fh:
            texts[path] = fh.read()
    return texts


def check_citations(rows, scope_texts):
    """Both directions: every citation resolves, every `cited` row is cited."""
    fails = []
    ids = {r.get("id") for r in rows}
    cited = set()
    for fname, text in scope_texts.items():
        for match in CITATION_RE.finditer(text):
            cid = match.group(1)
            cited.add(cid)
            # --- route:unresolved-citation ---
            if cid not in ids:
                fails.append(
                    ("unresolved-citation", f"{fname}: [claim:{cid}] resolves to no "
                     "ledger row")
                )
            # --- /route:unresolved-citation ---
    for row in rows:
        dispo = row.get("disposition")
        # --- route:uncited-row ---
        if dispo == "cited" and row.get("id") not in cited:
            fails.append(
                ("uncited-row", f"ledger row {row.get('id')!r} is cited by no scope "
                 "file and is not dispositioned `uncited`")
            )
        # --- /route:uncited-row ---
    return fails


# --------------------------------------------------------------------------
# Parity between this script, its docstring, and the decision entry
# --------------------------------------------------------------------------


def read_d_entry(path=DECISIONS, anchor=D_ENTRY):
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    start = text.find(anchor)
    if start < 0:
        return ""
    rest = text[start + len(anchor):]
    end = rest.find("\n### D-")
    return anchor + (rest if end < 0 else rest[:end])


def parse_scope(entry):
    """Backticked paths between `Citation scope:` and that rule's first dash.

    The rule states the scope and then argues for it, and the argument names
    excluded paths in backticks too -- so the list ends where the enumeration
    does, at the em dash, not at the end of the line.
    """
    for line in entry.splitlines():
        if "Citation scope:" in line:
            listing = line.split("Citation scope:", 1)[1].split("—", 1)[0]
            return [m.group(1) for m in re.finditer(r"`([^`]+)`", listing)]
    return []


def parse_rule_probes(entry):
    named = set()
    for line in entry.splitlines():
        # The token immediately after `probe:`, not the line's last word: a
        # rule with no probe records its ground after `none`, and that ground
        # is prose, not a route id.
        match = re.search(r"probe:\s*(\S+)", line)
        if match and match.group(1) != "none":
            named.add(match.group(1))
    return named


def check_shape_parity(doc=None, shapes=None):
    fails = []
    stated = set(doc_list("shape", doc))
    coded = set(SHAPES if shapes is None else shapes)
    # --- route:shape-parity ---
    if stated != coded:
        fails.append(
            ("shape-parity", f"docstring shapes {sorted(stated)} != dispatched "
             f"{sorted(coded)}")
        )
    # --- /route:shape-parity ---
    return fails


def refused_detected(samples=None):
    """The forms the detectors actually fire on, over one sample apiece."""
    samples = REFUSED_SAMPLES if samples is None else samples
    return {form for cmd in samples.values() for form, _ in refused_hits(cmd)}


def check_refused_parity(doc=None, forms=None):
    fails = []
    stated = set(doc_list("refused", doc))
    coded = set(forms) if forms is not None else refused_detected()
    # --- route:refused-parity ---
    if stated != coded:
        fails.append(
            ("refused-parity", f"docstring refused forms {sorted(stated)} != detected "
             f"{sorted(coded)}")
        )
    # --- /route:refused-parity ---
    return fails


def check_route_parity(doc=None, probes=None):
    fails = []
    stated = set(doc_list("route", doc))
    coded = set(PROBES if probes is None else probes)
    # --- route:route-parity ---
    if stated != coded:
        fails.append(
            ("route-parity", f"docstring routes {sorted(stated - coded)} have no probe; "
             f"probes {sorted(coded - stated)} are not stated")
        )
    # --- /route:route-parity ---
    return fails


def check_scope_parity(entry=None, scope=None):
    fails = []
    entry = read_d_entry() if entry is None else entry
    stated = set(parse_scope(entry))
    coded = set(SCOPE if scope is None else scope)
    # --- route:scope-parity ---
    if stated != coded:
        fails.append(
            ("scope-parity", f"{D_ENTRY}'s citation scope {sorted(stated)} != the "
             f"checker's {sorted(coded)}")
        )
    # --- /route:scope-parity ---
    return fails


def check_rule_probes(entry=None, probes=None):
    fails = []
    entry = read_d_entry() if entry is None else entry
    named = parse_rule_probes(entry)
    coded = set(PROBES if probes is None else probes)
    # --- route:rule-probe-unknown ---
    unknown = named - coded
    if unknown:
        fails.append(
            ("rule-probe-unknown", f"{D_ENTRY} names probe(s) {sorted(unknown)} that no "
             "route implements")
        )
    # --- /route:rule-probe-unknown ---
    return fails


# --------------------------------------------------------------------------
# The check
# --------------------------------------------------------------------------


def run_check(timeout=DEFAULT_TIMEOUT, root=None, verbose=True):
    rows, fails = read_ledger()
    fails = list(fails)
    for row in rows:
        row_fails = validate_row(row)
        fails.extend(row_fails)
        if not row_fails:
            fails.extend(execute_row(row, timeout=timeout, root=root))
    fails.extend(check_falsifiers(rows, timeout=timeout, root=root))
    fails.extend(check_citations(rows, read_scope(root=root)))
    fails.extend(check_shape_parity())
    fails.extend(check_refused_parity())
    fails.extend(check_route_parity())
    fails.extend(check_scope_parity())
    fails.extend(check_rule_probes())
    if verbose:
        for route, msg in fails:
            print(f"FAIL [{route}] {msg}")
        print(
            f"{'FAIL' if fails else 'OK'}: {len(rows)} registered claim(s) re-derived, "
            f"{len(fails)} failure(s)"
        )
    return fails


# --------------------------------------------------------------------------
# Probes -- one per route, each driving exactly its own route on constructed
# input. A probe "detects" when a failure carrying its own route id comes back,
# so a constructed input that happens to trip a second route is harmless.
# --------------------------------------------------------------------------


def _row(**kw):
    base = {
        "id": "probe-row",
        "record": "data-raw/README.md",
        "kind": "presence",
        "shape": "grep",
        "claim": "constructed by --probes",
        "command": "grep -c data-raw data-raw/README.md",
        "expected_rc": "0",
        "expected_match": r"[0-9]+",
        "falsifier_command": "-",
        "disposition": "uncited",
        "reason": "constructed by --probes",
        "_line": 0,
    }
    base.update(kw)
    return base


PROBES = {
    "grammar": lambda: validate_row(_row(id="Not A Slug")),
    "unknown-shape": lambda: validate_row(_row(shape="perl")),
    "refused-form": lambda: validate_row(
        _row(shape="git-grep", command="git log --oneline")
    ),
    "rc-mismatch": lambda: execute_row(
        _row(command="grep -c zzz-absent-token data-raw/README.md")
    ),
    "match-mismatch": lambda: execute_row(_row(expected_match=r"zzz-never")),
    "timeout": lambda: execute_row(
        _row(shape="python3", command='python3 -c "import time; time.sleep(9)"'),
        timeout=1,
    ),
    "unresolved-citation": lambda: check_citations(
        [], {"probe": "[claim:no-such-row]"}
    ),
    "uncited-row": lambda: check_citations(
        [_row(id="lonely", disposition="cited")], {"probe": "no citations here"}
    ),
    "absence-no-falsifier": lambda: validate_row(
        _row(kind="absence", falsifier_command="-")
    ),
    "kind-misregistered": lambda: validate_row(_row(kind="presence", expected_rc="1")),
    "falsifier-passes": lambda: check_falsifiers(
        [_row(kind="absence", falsifier_command="grep -c data-raw data-raw/README.md")]
    ),
    "shape-parity": lambda: check_shape_parity(doc="shape: only-one -- probe\n"),
    "refused-parity": lambda: check_refused_parity(doc="refused: only-one -- probe\n"),
    "route-parity": lambda: check_route_parity(doc="route: grammar -- probe\n"),
    "scope-parity": lambda: check_scope_parity(
        entry="1. Citation scope: `cairn/ROADMAP.md`. probe: none -- probe\n"
    ),
    "rule-probe-unknown": lambda: check_rule_probes(
        entry="1. A rule naming a route that does not exist. probe: no-such-route\n"
    ),
}


def run_probes():
    for pid in sorted(PROBES):
        hit = any(route == pid for route, _ in PROBES[pid]())
        print(f"PROBE {pid} {'DETECTED' if hit else 'MISSED'}")
    return 0


# --------------------------------------------------------------------------
# Self-test: probes, control, and per-route excision
# --------------------------------------------------------------------------


def _excise(source, route):
    open_re = re.compile(rf"^\s*# --- route:{re.escape(route)} ---\s*$")
    close_re = re.compile(rf"^\s*# --- /route:{re.escape(route)} ---\s*$")
    out, skipping, seen = [], False, False
    for line in source.splitlines(keepends=True):
        if open_re.match(line):
            skipping, seen = True, True
            continue
        if close_re.match(line):
            skipping = False
            continue
        if not skipping:
            out.append(line)
    return "".join(out), seen


def self_test(root=None):
    problems = []
    root = root or os.getcwd()

    if run_check(root=root, verbose=False):
        problems.append("live check fails -- the self-test needs a green baseline")
        return _report(problems)

    control = validate_row(_row()) + execute_row(_row(), root=root)
    if control:
        problems.append(f"the probe control row is not clean: {control}")

    for pid in sorted(PROBES):
        if not any(route == pid for route, _ in PROBES[pid]()):
            problems.append(f"probe {pid!r} did not drive its route")

    for form, sample in sorted(REFUSED_SAMPLES.items()):
        hits = {f for f, _ in refused_hits(sample)}
        if form not in hits:
            problems.append(
                f"refused form {form!r} was NOT refused on its own sample {sample!r}"
            )
        row = _row(shape="git-grep", command=sample)
        if not any(route == "refused-form" for route, _ in validate_row(row)):
            problems.append(f"a ledger row carrying {sample!r} was not refused")

    stated_routes = set(doc_list("route"))
    if stated_routes != set(PROBES):
        problems.append(
            f"route parity: docstring-only {sorted(stated_routes - set(PROBES))}, "
            f"probe-only {sorted(set(PROBES) - stated_routes)}"
        )
    for check, label in (
        (check_shape_parity(), "shape"),
        (check_refused_parity(), "refused-form"),
        (check_scope_parity(), "scope"),
        (check_rule_probes(), "decision-rule probe"),
    ):
        if check:
            problems.append(f"{label} parity: {check}")

    rows, _ = read_ledger()
    if not any(r.get("kind") == "absence" for r in rows):
        problems.append("the ledger holds no absence row, so no falsifier is exercised")
    if check_falsifiers(rows, root=root):
        problems.append("an absence row's falsifier met that row's expectation")

    with open(__file__, encoding="utf-8") as fh:
        source = fh.read()
    with tempfile.TemporaryDirectory() as tmp:
        for pid in sorted(PROBES):
            mutated, seen = _excise(source, pid)
            if not seen:
                problems.append(f"route {pid!r} has no sentinel-delimited block")
                continue
            path = os.path.join(tmp, "excised.py")
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(mutated)
            proc = subprocess.run(
                [sys.executable, path, "--probes"],
                cwd=root,
                capture_output=True,
                text=True,
                timeout=DEFAULT_TIMEOUT,
            )
            if proc.returncode != 0:
                problems.append(
                    f"excising {pid!r} broke the script: {proc.stderr.strip()[-300:]}"
                )
                continue
            missed = {
                ln.split()[1]
                for ln in proc.stdout.splitlines()
                if ln.startswith("PROBE ") and ln.endswith("MISSED")
            }
            if missed != {pid}:
                problems.append(
                    f"excising route {pid!r} silenced {sorted(missed)}, expected "
                    f"exactly [{pid!r}] -- the probe is not load-bearing for its route"
                )
    return _report(problems)


def _report(problems):
    for problem in problems:
        print(f"SELF-TEST FAIL {problem}")
    print(
        "self-test: "
        + ("FAIL" if problems else "OK -- every route probed, every probe load-bearing")
    )
    return problems


def main(argv):
    if "--probes" in argv:
        return run_probes()
    if "--self-test" in argv:
        return 1 if self_test() else 0
    return 1 if run_check() else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
