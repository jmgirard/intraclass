#!/usr/bin/env python3
"""Enumerate the CI-reducer aborts whose remedy bullets name a `ci_method` (M100).

An abort's remedy bullets tell a user what to do instead. When a bullet names an
alternative `ci_method`, it makes a claim: that method works on the data that
just reached this abort. M93 T1 measured that claim false at
`R/ci-bootstrap.R`'s refit-convergence guard -- the site fires only on degenerate
data (0/90 across six boundary geometries at the sigma^2 -> 0 boundary), and on
the degenerate data that does reach it the named Monte-Carlo default aborts too.
The one remedy it offers is the one that cannot work.

This script is the *enumeration* half of fixing that: a re-runnable search that
finds every site making such a claim, so no site is fixed by hand-listing and
none is silently skipped when a new abort is added. It does NOT decide whether a
claim is true -- only `data-raw/sweep-abort-remedies.R` does that, by running the
named method on data that reaches the abort.

Scope is `R/ci-*.R`, the reducer stage. `icc()`'s own pre-dispatch fences are out
by construction: they refuse a *design* before any data-dependent computation, so
the default they name is not being asked to survive degenerate data.

Not every reducer-stage site is data-triggered either -- some are argument or
capability fences that happen to live in a reducer. The committed ledger
`data-raw/abort-remedy-sites.tsv` records the disposition of every enumerated
site (`sweep` = data-triggered, the sweep must measure it; `fence` = not
data-triggered, with the reason), and `--check` fails when a site carries no row.
That is the completeness gate: a new `ci_method`-naming abort cannot reach a
release without someone classifying it.

Ledger keys are `<file>:<sha1(leading message line)[:10]>`. The leading line is
the stable identifier here by construction: the milestone that rewrites these
remedies is required to leave every leading line unchanged, so a re-keying can
only follow a genuine change of what the abort says it is.

Usage (run from the repo root):
    python3 data-raw/enumerate-ci-method-remedies.py            # print the enumeration
    python3 data-raw/enumerate-ci-method-remedies.py --emit     # write it to disk
    python3 data-raw/enumerate-ci-method-remedies.py --check    # completeness gate
    python3 data-raw/enumerate-ci-method-remedies.py --self-test

`--check` fails on an unclassified site, on a ledger row matching no site, and on
a committed enumeration that is not this run's own output.
"""

import glob
import hashlib
import os
import re
import sys

R_GLOB = "R/ci-*.R"
LEDGER = "data-raw/abort-remedy-sites.tsv"
ENUMERATION = "data-raw/abort-remedy-enumeration.txt"

ABORT_RE = re.compile(r"^\s*(abort_[a-z_]+|cli::cli_abort|cli_abort)\(")
BULLET_RE = re.compile(r"^\s*i = ")
# A `ci_method` value named in R source. The R string literal escapes its inner
# quotes, so the file bytes carry backslash-quote: ci_method = \"montecarlo\".
METHOD_RE = re.compile(r'ci_method\s*=\s*\\"([a-z]+)\\"')
CLASS_RE = re.compile(r'class\s*=\s*"([a-z_]+)"')
IF_RE = re.compile(r"^\s*(if|\} else if)\s*\(")


def _slice_call(lines, start):
    """Return the line range [start, end] of a call opening on line `start`.

    Balances parentheses, ignoring those inside R string literals (which may
    carry escaped quotes) so a message containing `(` does not truncate it.
    """
    depth = 0
    i = start
    while i < len(lines):
        in_str = False
        prev = ""
        for ch in lines[i]:
            if in_str:
                if ch == '"' and prev != "\\":
                    in_str = False
            elif ch == '"':
                in_str = True
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    return start, i
            prev = "" if (prev == "\\" and ch == "\\") else ch
        i += 1
    return start, len(lines) - 1


def _encloses(lines, if_line, abort_line):
    """Does the `if` block opening at `if_line` still be open at `abort_line`?

    An early-return guard (`if (ok) { return(...) }`) sits ABOVE the abort but
    closes before it, so it does not trigger the abort -- reading it as the
    trigger reports the condition INVERTED (`npb_guard_sb_pole()` aborts when
    `any(denom < 0)`, above which sits `if (!any(denom < 0)) return(...)`).
    """
    depth = 0
    opened = False
    for i in range(if_line, abort_line + 1):
        for ch in lines[i]:
            if ch == "{":
                depth += 1
                opened = True
            elif ch == "}":
                depth -= 1
        if opened and depth <= 0 and i < abort_line:
            return False
    return opened and depth > 0


def _condition(lines, abort_line):
    """Source text of the `if (` that actually guards this abort, or '' if none."""
    for i in range(abort_line - 1, max(-1, abort_line - 40), -1):
        if IF_RE.match(lines[i]) and _encloses(lines, i, abort_line):
            first, last = _slice_call(lines, i)
            text = " ".join(x.strip() for x in lines[first : last + 1])
            return re.sub(r"\s+", " ", text).strip()
    return ""


def _leading_line(body):
    """The abort's first message string, normalized (its stable identity).

    The leading message is the first string literal inside the message vector,
    i.e. everything from the first quote up to the first `i = ` bullet.
    """
    text = []
    for raw in body:
        if BULLET_RE.match(raw):
            break
        text.append(raw.strip())
    joined = " ".join(text)
    quoted = re.findall(r'"((?:[^"\\]|\\.)*)"', joined)
    if not quoted:
        return ""
    lead = quoted[0]
    lead = lead.replace("\\\\", " ").replace('\\"', '"')
    return re.sub(r"\s+", " ", lead).strip()


def enumerate_sites():
    """Every `R/ci-*.R` abort whose REMEDY bullets name a `ci_method` value."""
    sites = []
    for path in sorted(glob.glob(R_GLOB)):
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
        for idx, line in enumerate(lines):
            if not ABORT_RE.match(line):
                continue
            first, last = _slice_call(lines, idx)
            body = lines[first : last + 1]
            # Only bullets are remedies. A leading line naming its own method
            # ("`ci_method = \"mpl\"` is calibrated at ...") states what failed,
            # it does not send the user anywhere, so it is not a claim about
            # another method surviving this data.
            bullet_text = []
            seen_bullet = False
            for raw in body:
                if BULLET_RE.match(raw):
                    seen_bullet = True
                if seen_bullet:
                    bullet_text.append(raw)
            methods = sorted(set(METHOD_RE.findall("\n".join(bullet_text))))
            if not methods:
                continue
            cls = CLASS_RE.search("\n".join(body))
            lead = _leading_line(body)
            sites.append(
                {
                    "file": path,
                    "line": first + 1,
                    "class": cls.group(1) if cls else "(default)",
                    "condition": _condition(lines, first),
                    "methods": methods,
                    "lead": lead,
                    "key": "%s:%s"
                    % (path, hashlib.sha1(lead.encode("utf-8")).hexdigest()[:10]),
                }
            )
    return sites


def read_ledger():
    if not os.path.exists(LEDGER):
        return {}
    rows = {}
    with open(LEDGER, encoding="utf-8") as fh:
        for raw in fh:
            if not raw.strip() or raw.startswith("#"):
                continue
            parts = raw.rstrip("\n").split("\t")
            if len(parts) < 3:
                continue
            rows[parts[0]] = {"disposition": parts[1], "reason": parts[2]}
    return rows


def render(sites, ledger):
    """The enumeration text. Line numbers are deliberately absent: they churn on
    every unrelated edit above a site, and the key already identifies it."""
    out = [
        "# Generated by data-raw/enumerate-ci-method-remedies.py -- do not hand-edit.",
        "# Regenerate: python3 data-raw/enumerate-ci-method-remedies.py --emit",
        "",
    ]
    for s in sites:
        row = ledger.get(s["key"])
        disp = row["disposition"] if row else "UNCLASSIFIED"
        out.append("%s  [%s]  %s" % (s["file"], disp, s["class"]))
        out.append("    key:       %s" % s["key"])
        out.append("    names:     %s" % ", ".join(s["methods"]))
        out.append("    trigger:   %s" % (s["condition"] or "(unguarded)"))
        out.append("    leading:   %s" % s["lead"])
        if row:
            out.append("    reason:    %s" % row["reason"])
        out.append("")
    return "\n".join(out)


def check(sites, ledger):
    missing = [s for s in sites if s["key"] not in ledger]
    stale = set(ledger) - {s["key"] for s in sites}
    for s in missing:
        print(
            "UNCLASSIFIED %s:%d names %s -- add a row to %s"
            % (s["file"], s["line"], ", ".join(s["methods"]), LEDGER),
            file=sys.stderr,
        )
    for key in sorted(stale):
        print(
            "STALE ledger row %s matches no current site -- the abort moved, "
            "changed its leading line, or stopped naming a ci_method" % key,
            file=sys.stderr,
        )
    if missing or stale:
        return 1
    # The committed enumeration must be this run's own output, or it is a
    # hand-list wearing a generated file's name.
    fresh = render(sites, ledger)
    committed = None
    if os.path.exists(ENUMERATION):
        with open(ENUMERATION, encoding="utf-8") as fh:
            committed = fh.read()
    if committed != fresh:
        print(
            "%s is stale or absent -- regenerate with "
            "`python3 %s --emit`" % (ENUMERATION, sys.argv[0]),
            file=sys.stderr,
        )
        return 1
    swept = [s for s in sites if ledger[s["key"]]["disposition"] == "sweep"]
    print(
        "OK %d ci_method-naming reducer aborts, all classified "
        "(%d sweep, %d fence); %s current"
        % (len(sites), len(swept), len(sites) - len(swept), ENUMERATION)
    )
    return 0


def self_test():
    """The parser must find what a hand-read of the sources finds, and must
    separate a remedy bullet from a leading line that names its own method."""
    fails = []
    sites = enumerate_sites()
    by_file = {}
    for s in sites:
        by_file.setdefault(s["file"], []).append(s)

    # 1. Every enumerated site really does carry its methods in a BULLET. Probe
    #    the inverse: an abort whose only `ci_method` is in the leading line must
    #    not be enumerated. `mpl_kappa_lookup()`'s level abort has both, so it is
    #    enumerated for "montecarlo" and must NOT be enumerated for "mpl".
    for s in sites:
        if "mpl" in s["methods"] and s["file"] == "R/ci-mpl.R":
            fails.append(
                "leading-line method leaked into remedies at %s:%d"
                % (s["file"], s["line"])
            )

    # 2. Two-sided, because a finder that finds nothing passes a one-sided probe.
    #    Sites that DO name a method must be found, anchored on their guard text
    #    rather than a line number so the probe survives the file moving...
    wanted = {
        "R/ci-npbootstrap.R": ["n_bad > 0"],
        "R/ci-bootstrap.R": ["is.null(engine$simulate_refit)"],
        "R/ci-mpl.R": ["n_r %in% r_nodes"],
    }
    for path, needles in wanted.items():
        conditions = " || ".join(s["condition"] for s in by_file.get(path, []))
        for needle in needles:
            if needle not in conditions:
                fails.append("no enumerated site in %s guards on %r" % (path, needle))

    # ...and sites that name NO method must stay out. M100 de-named these three
    # because no method survived their trigger class; if one silently regains a
    # `ci_method` bullet, this probe fails and the ledger demands a re-measurement.
    unwanted = {
        "R/ci-bootstrap.R": ["n_ok < min_frac"],
        "R/ci-classical.R": ["ss$mse == 0"],
        "R/ci-npbootstrap.R": ["se_ij_logf == 0"],
    }
    for path, needles in unwanted.items():
        conditions = " || ".join(s["condition"] for s in by_file.get(path, []))
        for needle in needles:
            if needle in conditions:
                fails.append(
                    "%s guards on %r and names a ci_method again -- M100 removed "
                    "that name for want of evidence; re-measure before restoring"
                    % (path, needle)
                )

    # 3. Keys are stable and unique -- a collision would let one ledger row
    #    silently classify two sites.
    keys = [s["key"] for s in sites]
    if len(keys) != len(set(keys)):
        fails.append("duplicate ledger keys: %s" % keys)

    # 4. Every site has a non-empty leading line, or its key is meaningless.
    for s in sites:
        if not s["lead"]:
            fails.append("empty leading line at %s:%d" % (s["file"], s["line"]))

    for f in fails:
        print("SELF-TEST FAIL: %s" % f, file=sys.stderr)
    if not fails:
        print("self-test OK (%d sites enumerated)" % len(sites))
    return 1 if fails else 0


def main():
    args = sys.argv[1:]
    if "--self-test" in args:
        return self_test()
    sites = enumerate_sites()
    ledger = read_ledger()
    if "--check" in args:
        return check(sites, ledger)
    text = render(sites, ledger)
    if "--emit" in args:
        with open(ENUMERATION, "w", encoding="utf-8") as fh:
            fh.write(text)
        print("wrote %s (%d sites)" % (ENUMERATION, len(sites)))
        return 0
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
