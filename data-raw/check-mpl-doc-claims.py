#!/usr/bin/env python3
"""Settle the MPL interpolation doc claims against the M92 fixture (M94).

The exported MPL documentation (`@param conf_level` / `@param ci_method` in
R/icc.R, plus its NEWS.md bullet) makes universal and negative claims about the
cells `data-raw/m92-interp-sweep.rds` validated ("no validated cell ...", "only
the rater and subject counts vary", "each clears ..."). The M71 lesson
(cairn/LESSONS.md): such claims about the repo's own fixture fail
verification-by-reading in a way transcribed values do not, so each one must
carry the check that settles it. This script is that check, made mechanical:

  1. it parses the fixture with a self-contained, stdlib-only RDS reader (the
     CI job that runs it is deliberately R-free — no R, no pip installs);
  2. it enumerates every universal/negative claim candidate in the doc scope
     (wide recall net, one candidate per sentence carrying a trigger token);
  3. it requires the committed ledger `data-raw/mpl-doc-claims.tsv` to cover
     every candidate (settle: an assertion evaluated against the fixture;
     out: a reason why the fixture cannot settle it), and every ledger row to
     bind to a claim actually present — both directions, so a claim with no
     row and a row with no claim each fail;
  4. `absent` rows are refusal patterns that must match nowhere in the scope
     (the claim M92's review found false — "nothing isolates the rater axis" —
     is refused outright: E2 and E3 differ only in rater count).

Exit status 0 iff every candidate is covered, every settle assertion holds,
every quote binds, and every refusal pattern is absent.

Usage (from the repo root):
    python3 data-raw/check-mpl-doc-claims.py               # run the check
    python3 data-raw/check-mpl-doc-claims.py --list        # list candidates + keys
    python3 data-raw/check-mpl-doc-claims.py --fixture F   # settle against F
    python3 data-raw/check-mpl-doc-claims.py --self-test   # mutation harness
"""

import gzip
import hashlib
import re
import struct
import sys

FIXTURE = "data-raw/m92-interp-sweep.rds"
COLLIDED = "data-raw/m92-interp-sweep-run1-collided.rds"
LEDGER = "data-raw/mpl-doc-claims.tsv"
ICC_R = "R/icc.R"
NEWS = "NEWS.md"

# --------------------------------------------------------------------------
# Minimal RDS (version 2/3, XDR) reader — only the object shapes the M92
# fixture uses: NULL, symbols, pairlists, character/logical/integer/real
# vectors, generic vectors (lists), attributes, references, and the ALTREP
# wrappers R may emit for them. Anything else raises.
# --------------------------------------------------------------------------

NILVALUE, REFSXP, ALTREP = 254, 255, 238
SYMSXP, LISTSXP, CHARSXP = 1, 2, 9
LGLSXP, INTSXP, REALSXP, STRSXP, VECSXP = 10, 13, 14, 16, 19
NA_INT = -2147483648


class RObj:
    """An R value plus its attributes (names, class, ...)."""

    def __init__(self, value, attrs=None):
        self.value = value
        self.attrs = attrs or {}


class _Reader:
    def __init__(self, data):
        self.d = data
        self.pos = 0
        self.refs = []

    def _take(self, n):
        b = self.d[self.pos : self.pos + n]
        if len(b) != n:
            raise ValueError("truncated RDS stream")
        self.pos += n
        return b

    def _int(self):
        return struct.unpack(">i", self._take(4))[0]

    def _double(self):
        return struct.unpack(">d", self._take(8))[0]

    def read(self):
        if self._take(2) != b"X\n":
            raise ValueError("not an XDR-format RDS stream")
        version = self._int()
        self._int()  # writer version
        self._int()  # min reader version
        if version >= 3:
            self._take(self._int())  # native encoding string
        return self.item()

    def item(self):
        flags = self._int()
        t = flags & 0xFF
        if t == NILVALUE:
            return RObj(None)
        if t == REFSXP:
            idx = flags >> 8
            if idx == 0:
                idx = self._int()
            return self.refs[idx - 1]
        hasattr_ = bool(flags & 0x200)
        hastag = bool(flags & 0x400)
        if t == SYMSXP:
            sym = RObj(("symbol", self.item().value))
            self.refs.append(sym)
            return sym
        if t == LISTSXP:
            pairs = []
            while True:
                if hasattr_:
                    self.item()  # a pairlist's own attributes: skip
                tag = self.item().value if hastag else None
                tagname = tag[1] if isinstance(tag, tuple) else tag
                pairs.append((tagname, self.item()))
                nxt = self._int()
                t2 = nxt & 0xFF
                if t2 == NILVALUE:
                    return RObj(("pairlist", pairs))
                if t2 != LISTSXP:
                    # CDR is a non-pairlist object (dotted pair): parse inline
                    self.pos -= 4
                    pairs.append((None, self.item()))
                    return RObj(("pairlist", pairs))
                hasattr_ = bool(nxt & 0x200)
                hastag = bool(nxt & 0x400)
        if t == CHARSXP:
            n = self._int()
            return RObj(None if n == -1 else self._take(n).decode("utf-8"))
        if t in (LGLSXP, INTSXP):
            n = self._int()
            vals = [self._int() for _ in range(n)]
            if t == LGLSXP:
                vals = [None if v == NA_INT else bool(v) for v in vals]
            else:
                vals = [None if v == NA_INT else v for v in vals]
            return RObj(vals, self._attrs(hasattr_))
        if t == REALSXP:
            n = self._int()
            return RObj([self._double() for _ in range(n)], self._attrs(hasattr_))
        if t == STRSXP:
            n = self._int()
            return RObj([self.item().value for _ in range(n)], self._attrs(hasattr_))
        if t == VECSXP:
            n = self._int()
            vals = [self.item() for _ in range(n)]
            return RObj(vals, self._attrs(hasattr_))
        if t == ALTREP:
            return self._altrep()
        raise ValueError(f"unsupported SEXP type {t} in fixture")

    def _attrs(self, hasattr_):
        if not hasattr_:
            return {}
        attrs = self.item().value
        out = {}
        if isinstance(attrs, tuple) and attrs[0] == "pairlist":
            for tag, val in attrs[1]:
                out[tag] = val
        return out

    def _altrep(self):
        info = self.item().value  # pairlist: (class, package, sexptype)
        cls = info[1][0][1].value[1] if info and info[0] == "pairlist" else None
        state = self.item()
        self.item()  # attributes slot
        if cls in ("compact_intseq", "compact_realseq"):
            n, start, step = state.value
            seq = [start + i * step for i in range(int(n))]
            if cls == "compact_intseq":
                seq = [int(v) for v in seq]
            return RObj(seq)
        # wrap_* / deferred_string: payload is the CAR of the state pairlist
        if isinstance(state.value, tuple) and state.value[0] == "pairlist":
            return state.value[1][0][1]
        return state


def _pyify(obj):
    """RObj -> plain Python: named list -> dict, data.frame -> dict of columns."""
    v = obj.value
    if isinstance(v, list) and v and isinstance(v[0], RObj):  # VECSXP
        elems = [_pyify(e) for e in v]
        names = obj.attrs.get("names")
        if names is not None:
            return dict(zip(names.value, elems))
        return elems
    if isinstance(v, list):
        return v
    return v


def read_rds(path):
    with open(path, "rb") as fh:
        raw = fh.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    top = _pyify(_Reader(raw).read())
    if not isinstance(top, dict) or "summary" not in top:
        raise ValueError(f"{path}: parsed object has no $summary component")
    return top


# --------------------------------------------------------------------------
# Fixture accessors handed to ledger assertions
# --------------------------------------------------------------------------


def build_env(fx):
    summary = fx["summary"]
    ids = summary["id"]

    def col(name):
        vals = summary[name]
        return [vals[i] for i in range(len(ids))]

    def cell(cid, name):
        return summary[name][ids.index(cid)]

    verdict = fx["verdict"]["0.95"]
    if verdict.get("failed_cells") is None:  # chr(0) parses to scalar None
        verdict = dict(verdict, failed_cells=[])
    # scalar-ify length-1 verdict entries R stored as vectors
    verdict = {
        k: (v[0] if isinstance(v, list) and len(v) == 1 and k not in
            ("cells", "interp_cells", "failed_cells") else (v or []))
        for k, v in verdict.items()
    }
    meta = {k: (v[0] if isinstance(v, list) and len(v) == 1 else v)
            for k, v in fx["meta"].items()}
    safe = {
        "abs": abs, "min": min, "max": max, "all": all, "any": any,
        "len": len, "set": set, "zip": zip, "sorted": sorted, "round": round,
        "sum": sum, "True": True, "False": False, "None": None,
    }
    return {
        "__builtins__": {},
        **safe,
        "col": col,
        "cell": cell,
        "verdict": verdict,
        "meta": meta,
    }


# --------------------------------------------------------------------------
# Doc scope: the two @param blocks + the M94 NEWS bullet
# --------------------------------------------------------------------------


def icc_scope(text):
    lines = text.splitlines()
    blocks, current, name = {}, None, None
    for ln in lines:
        m = re.match(r"#' @param (\w+)", ln)
        if m:
            if name in ("conf_level", "ci_method"):
                blocks[name] = current
            name, current = m.group(1), []
        if name and ln.startswith("#'"):
            current.append(ln[2:].strip())
        elif name:
            if name in ("conf_level", "ci_method"):
                blocks[name] = current
            name = None
    if name in ("conf_level", "ci_method"):
        blocks[name] = current
    missing = {"conf_level", "ci_method"} - set(blocks)
    if missing:
        raise ValueError(f"R/icc.R scope blocks not found: {sorted(missing)}")
    return {k: " ".join(v) for k, v in blocks.items()}


def news_scope(text):
    lines = text.splitlines()
    start = None
    for i, ln in enumerate(lines):
        if re.match(r"^\* The `ci_method = \"mpl\"` documentation", ln):
            start = i
            break
    if start is None:
        raise ValueError("NEWS.md: the mpl-documentation bullet was not found")
    body = [lines[start][2:]]
    for ln in lines[start + 1 :]:
        if ln.startswith("* ") or ln.startswith("#") or not ln.strip():
            break
        body.append(ln.strip())
    return " ".join(body)


def normalize(s):
    s = s.replace("—", "--").replace("–", "--")
    s = re.sub(r"[*`]", "", s)
    return re.sub(r"\s+", " ", s).strip()


TRIGGER = re.compile(
    r"\b(no|none|never|nothing|neither|nor|not|every|each|all|only)\b", re.I
)
SENT_SPLIT = re.compile(r"(?<=[.!?])\s+")


def candidates(scopes):
    """Yield (file, sentence, key) for every trigger-bearing sentence."""
    out = []
    for fname, text in scopes.items():
        for sent in SENT_SPLIT.split(normalize(text)):
            sent = sent.strip()
            if sent and TRIGGER.search(sent):
                key = hashlib.sha1(
                    f"{fname}\t{sent}".encode("utf-8")
                ).hexdigest()[:12]
                out.append((fname, sent, key))
    return out


# --------------------------------------------------------------------------
# Ledger
# --------------------------------------------------------------------------


def read_ledger(path=LEDGER):
    rows = []
    with open(path, encoding="utf-8") as fh:
        for lineno, ln in enumerate(fh, 1):
            if not ln.strip() or ln.startswith("#") or ln.startswith("key\t"):
                continue
            parts = ln.rstrip("\n").split("\t")
            if len(parts) != 6:
                raise ValueError(f"{path}:{lineno}: expected 6 tab-separated fields")
            key, fname, disp, quote, assertion, reason = parts
            if disp not in ("settle", "out", "absent"):
                raise ValueError(f"{path}:{lineno}: unknown disposition {disp!r}")
            if not quote.strip():
                # an empty quote would substring-match every sentence and
                # silently disable the enumeration gate for that file
                raise ValueError(f"{path}:{lineno}: empty quote")
            rows.append(
                {"line": lineno, "key": key, "file": fname, "disp": disp,
                 "quote": quote, "assertion": assertion, "reason": reason}
            )
    return rows


def run_check(fixture=FIXTURE, ledger_rows=None, scopes=None, verbose=True):
    """Return a list of failure strings (empty = pass)."""
    failures = []
    fx = read_rds(fixture)
    env = build_env(fx)
    if ledger_rows is None:
        ledger_rows = read_ledger()
    if scopes is None:
        with open(ICC_R, encoding="utf-8") as fh:
            icc = icc_scope(fh.read())
        with open(NEWS, encoding="utf-8") as fh:
            news = news_scope(fh.read())
        scopes = {"R/icc.R": icc["conf_level"] + " " + icc["ci_method"],
                  "NEWS.md": news}
    cands = candidates(scopes)
    if not cands:
        failures.append("vacuity: no claim candidates found in the doc scope")
    covered = set()
    for row in ledger_rows:
        tag = f"ledger:{row['line']} [{row['disp']}]"
        if row["file"] not in scopes:
            # an unrecognized file value would fail open: an absent row's
            # regex can never match an empty scope
            failures.append(f"{tag} unknown file {row['file']!r}")
            continue
        scope_norm = normalize(scopes[row["file"]])
        if row["disp"] == "absent":
            if re.search(row["quote"], scope_norm, re.I):
                failures.append(
                    f"{tag} refused pattern PRESENT in {row['file']}: {row['quote']}"
                )
            continue
        qnorm = normalize(row["quote"]).casefold()
        hits = [
            (f, s, k) for (f, s, k) in cands
            if f == row["file"] and qnorm in s.casefold()
        ]
        if not hits:
            failures.append(
                f"{tag} quote not found in any {row['file']} claim sentence: "
                f"{row['quote']!r} (a ledger row with no claim)"
            )
            continue
        if row["key"] not in {k for (_, _, k) in hits}:
            failures.append(
                f"{tag} stale key {row['key']} (claim sentence changed; "
                f"expected one of {[k for (_, _, k) in hits]}) — re-triage"
            )
        covered.update(k for (_, _, k) in hits)
        if row["disp"] == "settle":
            try:
                ok = bool(eval(row["assertion"], env))  # noqa: S307 — committed ledger
            except Exception as exc:  # noqa: BLE001
                failures.append(f"{tag} assertion raised {exc!r}")
                continue
            if not ok:
                failures.append(
                    f"{tag} assertion FALSE against {fixture}: {row['quote']!r}"
                )
    for fname, sent, key in cands:
        if key not in covered:
            failures.append(
                f"uncovered claim [{key}] in {fname} (a claim with no ledger "
                f"row): {sent!r}"
            )
    if verbose:
        for f in failures:
            print(f"FAIL {f}")
        n_settle = sum(1 for r in ledger_rows if r["disp"] == "settle")
        print(
            f"{'FAIL' if failures else 'OK'}: {len(cands)} claim candidates, "
            f"{n_settle} settled against {fixture}, "
            f"{len(failures)} failure(s)"
        )
    return failures


# --------------------------------------------------------------------------
# Self-test (AC4): the check must red when it should
# --------------------------------------------------------------------------


def self_test():
    problems = []
    rows = read_ledger()
    settle_rows = [r for r in rows if r["disp"] == "settle"]
    absent_rows = [r for r in rows if r["disp"] == "absent"]
    if not settle_rows or not absent_rows:
        problems.append("ledger lacks settle rows or absent rows")
    # 0. the live check passes as committed
    if run_check(verbose=False):
        problems.append("live check fails — self-test needs a green baseline")
        _report(problems)
        return problems
    # 1. inverting each settled claim's assertion in turn must red
    for r in settle_rows:
        mutated = [
            dict(x, assertion=f"not ({x['assertion']})") if x is r else x
            for x in rows
        ]
        if not run_check(ledger_rows=mutated, verbose=False):
            problems.append(
                f"inverting ledger:{r['line']} ({r['quote']!r}) did not red"
            )
    # 2. the superseded collided fixture must red
    if not run_check(fixture=COLLIDED, verbose=False):
        problems.append("collided run-1 fixture did not red the check")
    # 3. deleting each settled claim's sentence from the docs must red
    #    (a ledger row whose claim is gone)
    with open(ICC_R, encoding="utf-8") as fh:
        icc = icc_scope(fh.read())
    with open(NEWS, encoding="utf-8") as fh:
        news = news_scope(fh.read())
    scopes0 = {"R/icc.R": icc["conf_level"] + " " + icc["ci_method"],
               "NEWS.md": news}
    for r in settle_rows:
        qnorm = normalize(r["quote"])
        gutted = {
            f: re.sub(re.escape(qnorm), "", normalize(t), flags=re.I)
            if f == r["file"] else t
            for f, t in scopes0.items()
        }
        if not run_check(scopes=gutted, verbose=False):
            problems.append(
                f"deleting the claim of ledger:{r['line']} did not red"
            )
    # 4. injecting a refused pattern must red
    for r in absent_rows:
        injected = dict(
            scopes0,
            **{r["file"]: scopes0[r["file"]] + " nothing here isolates the rater axis."},
        )
        if not run_check(scopes=injected, verbose=False):
            problems.append(f"injected refusal pattern (ledger:{r['line']}) did not red")
    # 5. an unledgered universal claim must red
    injected = dict(scopes0, **{"NEWS.md": scopes0["NEWS.md"] +
                                " No cell anywhere ever misses."})
    if not run_check(scopes=injected, verbose=False):
        problems.append("an unledgered universal claim did not red")
    _report(problems)
    return problems


def _report(problems):
    for p in problems:
        print(f"SELF-TEST FAIL {p}")
    print("self-test: " + ("FAIL" if problems else
                           "OK — every mutation reds, baseline green"))


def main(argv):
    if "--self-test" in argv:
        return 1 if self_test() else 0
    if "--list" in argv:
        with open(ICC_R, encoding="utf-8") as fh:
            icc = icc_scope(fh.read())
        with open(NEWS, encoding="utf-8") as fh:
            news = news_scope(fh.read())
        scopes = {"R/icc.R": icc["conf_level"] + " " + icc["ci_method"],
                  "NEWS.md": news}
        for fname, sent, key in candidates(scopes):
            print(f"{key}\t{fname}\t{sent}")
        return 0
    fixture = FIXTURE
    if "--fixture" in argv:
        fixture = argv[argv.index("--fixture") + 1]
    return 1 if run_check(fixture=fixture) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
