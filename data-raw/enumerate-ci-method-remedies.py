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
# `abort_unsupported()` and friends set the condition class INSIDE the wrapper
# (R/abort.R), so a call site carrying no `class =` still raises a classed
# condition. Reading only the call site printed `(default)` for 5 of 6 sites that
# actually carry `intraclass_unsupported` — committed evidence with a wrong
# column (review finding B5). The wrapper's own class is resolved from R/abort.R
# so this map cannot drift from it silently.
ABORT_R = "R/abort.R"
IF_RE = re.compile(r"^\s*(if|\} else if)\s*\(")

# The four degeneracy guards `data-raw/sweep-abort-remedies.R` measures, each
# anchored on a fragment of its own `if (...)` condition. Anchoring on the
# condition rather than a line number or a message string survives the file
# moving and the message being reworded, and reds if the guard's own test
# changes -- which is the event that would invalidate the sweep evidence.
MEASURED_GUARDS = (
    ("R/ci-bootstrap.R", "n_ok < min_frac", "bootstrap refit-convergence"),
    ("R/ci-classical.R", "ss$mse == 0", "classical_guard_observed"),
    ("R/ci-npbootstrap.R", "se_ij_logf == 0", "npbootstrap observed-data"),
    ("R/ci-npbootstrap.R", "n_bad > 0", "npbootstrap degenerate-resample"),
)

# Three of the five `fence` sites, anchored the same way, so a predicate change
# that dropped the non-degenerate half of the enumeration is caught too.
FENCE_GUARDS = {
    "R/ci-bootstrap.R": ["is.null(engine$simulate_refit)"],
    "R/ci-mpl.R": ["n_r %in% r_nodes", "n_s < min(s_nodes)"],
}


# Aborts whose message vector deliberately splices a variable rather than listing
# its bullets inline. `mc_ci()`'s `hint` is the runtime-verified boundary hint
# (M93/M97, governed by D-018): it is BUILT by `boundary_method_hint()`, which
# names methods only after running them, so it is out of this static gate's remit
# by design. Anything else spliced is a gap — see `spliced_message_sites()`.
SPLICE_ALLOWED = {("R/ci-montecarlo.R", "hint")}


def spliced_message_sites():
    """Aborts whose bullets are NOT inline, which this enumerator cannot see.

    The scanner reads bullets out of the abort call itself. That assumption held
    until M100 refactored two guards to build their bullets in a `cause <- if
    (...)` variable — after which re-adding a `ci_method` name to either passed
    both `--check` and `--self-test` (review finding F3), while the ledger, the
    self-test and D-020 all advertised that it would fail.

    Rather than leave the assumption silent, this makes it CHECKED: any abort
    splicing a bare symbol into its message vector is reported, so the gap
    announces itself instead of being discovered by a reviewer. Extending the
    scanner to resolve such a variable would be the alternative; refusing the
    shape is cheaper and keeps one way to write these messages.
    """
    out = []
    for path in sorted(glob.glob(R_GLOB)):
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
        for idx, line in enumerate(lines):
            if not ABORT_RE.match(line):
                continue
            first, last = _slice_call(lines, idx)
            for raw in lines[first : last + 1]:
                stripped = raw.split("#")[0].strip().rstrip(",")
                # A bare identifier on its own line inside the message vector:
                # not a string, not `name = value`, not punctuation.
                if re.fullmatch(r"[a-zA-Z._][a-zA-Z0-9._]*", stripped):
                    if stripped in ("c", "call"):
                        continue
                    if (path, stripped) in SPLICE_ALLOWED:
                        continue
                    out.append((path, first + 1, stripped))
    return out


def wrapper_classes():
    """Map each `abort_*` wrapper to the condition class it sets internally.

    Parsed from R/abort.R rather than hardcoded, so a wrapper that changes its
    class cannot leave this enumeration quietly stale.
    """
    out = {}
    if not os.path.exists(ABORT_R):
        return out
    with open(ABORT_R, encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    current = None
    for line in lines:
        m = re.match(r"(abort_[a-z_]+)\s*<-\s*function", line)
        if m:
            current = m.group(1)
            continue
        if current:
            m = CLASS_RE.search(line)
            if m and "c(class," not in line.replace(" ", ""):
                out[current] = m.group(1)
                current = None
            elif re.match(r"^\}", line):
                current = None
    return out


def _slice_call(lines, start):
    """Return the line range [start, end] of a call opening on line `start`.

    One scanner, carrying string state ACROSS lines, because both things it must
    ignore span lines in this codebase:

    - String literals. A message containing `(` must not close the call, and an
      R string continues across lines via a trailing `\\`.
    - Comments. Balancing over raw comment text let an unmatched `(` swallow the
      following abort into one site, which then inherited the first site's ledger
      row and passed `--check` (review finding B1) — and M100 itself added prose
      comments inside three abort calls.

    A line-local comment stripper is NOT sufficient and was the first attempt's
    bug: `R/ci-mpl.R`'s level fence carries the literal `(#5)` on a CONTINUATION
    line of a string, so stripping per line truncated mid-string, unbalanced the
    slice, and merged two mpl sites into one.
    """
    depth = 0
    in_str = False
    i = start
    while i < len(lines):
        prev = ""
        for ch in lines[i]:
            if in_str:
                if ch == '"' and prev != "\\":
                    in_str = False
            elif ch == '"':
                in_str = True
            elif ch == "#":
                break  # comment runs to end of line; strings are handled above
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
    wrappers = wrapper_classes()
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
            wrapper = ABORT_RE.match(line).group(1)
            cls = CLASS_RE.search("\n".join(body))
            lead = _leading_line(body)
            sites.append(
                {
                    "file": path,
                    "line": first + 1,
                    "class": (
                        cls.group(1)
                        if cls
                        else wrappers.get(wrapper, "(default)")
                    ),
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
    spliced = spliced_message_sites()
    for path, line, sym in spliced:
        print(
            "SPLICED %s:%d builds its bullets in `%s` rather than inline -- this "
            "scanner cannot see them, so a `ci_method` named there would escape "
            "the gate. Inline the bullets, or extend the scanner and add the site "
            "to SPLICE_ALLOWED with a reason." % (path, line, sym),
            file=sys.stderr,
        )
    if missing or stale or spliced:
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
    #    rather than a line number so the probe survives the file moving.
    #
    #    MEASURED_GUARDS is the load-bearing half. `data-raw/sweep-abort-remedies.R`
    #    measures exactly these four sites, and every verdict this milestone records
    #    is a verdict about one of them. A predicate that quietly stopped matching
    #    one of them would leave that site unswept and unclassified while `--check`
    #    still printed OK, so the enumeration is anchored on each guard's own
    #    condition text: the four are found, or the self-test fails.
    for path, needle, label in MEASURED_GUARDS:
        conditions = " || ".join(s["condition"] for s in by_file.get(path, []))
        if needle not in conditions:
            fails.append(
                "the swept %s guard is NOT enumerated: no site in %s guards on "
                "%r, so the sweep measures a site this enumeration does not cover"
                % (label, path, needle)
            )
    for path, needles in FENCE_GUARDS.items():
        conditions = " || ".join(s["condition"] for s in by_file.get(path, []))
        for needle in needles:
            if needle not in conditions:
                fails.append("no enumerated site in %s guards on %r" % (path, needle))

    # 2b. The two `_slice_call` hazards, probed directly on synthetic source
    #     because both were live defects rather than hypotheses: an unmatched
    #     paren in a COMMENT used to swallow the next abort into this one
    #     (review B1), and a line-local fix for that then truncated a STRING
    #     continuation carrying `(#5)` and merged two mpl sites.
    commented = [
        "    abort_intraclass(",
        "      c(",
        '        "Leading.",',
        "        # a comment with an unmatched paren :-(",
        '        i = "Use {.code ci_method = \\"searle\\"}."',
        "      ),",
        "      call = call",
        "    )",
        "    more_code()",
    ]
    if _slice_call(commented, 0) != (0, 7):
        fails.append(
            "_slice_call spans past the call when a comment holds an unmatched "
            "paren: got %r, want (0, 7)" % (_slice_call(commented, 0),)
        )
    continued = [
        "    abort_unsupported(",
        "      c(",
        '        "Leading.",',
        '        i = "calibrated per level and not interpolated across \\\\',
        '             levels (#5); use {.code ci_method = \\"montecarlo\\"}."',
        "      ),",
        "      call = call",
        "    )",
    ]
    if _slice_call(continued, 0) != (0, 7):
        fails.append(
            "_slice_call truncates on a string continuation carrying '(#5)': "
            "got %r, want (0, 7)" % (_slice_call(continued, 0),)
        )

    # 2c. Wrapper classes resolve, or the `class` column is decoration. The
    #     committed enumeration printed `(default)` for every `abort_unsupported`
    #     site until this was wired through R/abort.R (review B5).
    wc = wrapper_classes()
    if wc.get("abort_unsupported") != "intraclass_unsupported":
        fails.append(
            "abort_unsupported's class did not resolve from %s: got %r"
            % (ABORT_R, wc.get("abort_unsupported"))
        )
    if any(s["class"] == "(default)" for s in sites):
        fails.append(
            "a site still reports class '(default)': %s"
            % [s["key"] for s in sites if s["class"] == "(default)"]
        )

    # 2d. The scanner's own assumption, checked rather than assumed (review F3).
    for path, line, sym in spliced_message_sites():
        fails.append(
            "%s:%d splices `%s` into its message vector; bullets there are "
            "invisible to this enumerator" % (path, line, sym)
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
