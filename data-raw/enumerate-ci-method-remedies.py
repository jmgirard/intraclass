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

Ledger keys are `<file>:<sha1(leading message line)[:10]>`. No milestone is under
any obligation this script can assert; what the key gives is a mechanical
consequence. Changing an abort's leading line RE-KEYS its site, so its committed
ledger row matches no site and `--check` fails on both counts (UNCLASSIFIED for
the new key, STALE for the old) until someone renews the row. Reworded guidance
below the leading line costs nothing; a changed leading line costs a decision.

What the predicate does NOT match
--------------------------------
PROBED LIMITS: 6 predicate shapes (L1-L6), 5 unreported splice shapes; file
scope stated, no probe.

That line is parsed by `--self-test`, which compares its two counts against
`len(_limit_shapes())` and `len(_unreported_splices())` and fails on a
divergence, so this record cannot drift from the probes that back it. The
identical line appears in the ledger header and is parsed there too.

This is a line-oriented scanner over R source, not an R parser, so its reach has
edges. Each of the six edges below is a STATED LIMIT with a probe in
`--self-test` that constructs the shape and shows it unmatched (`_limit_shapes`),
because the recurring failure in this area has been a record claiming a gate
catches more than it does. A site written in any of these shapes carries a
`ci_method` name past the gate:

  L1  a bullet written as a single-quoted R string -- the method matcher wants
      the backslash-escaped inner quotes a double-quoted R string produces;
  L2  a NAMED splice, `i = cause`, where the bullets are built elsewhere;
  L3  a bullet whose name is quoted, `"i" = ` -- only a bare `i = ` at the start
      of a line is read as a bullet, and everything before the first one is
      treated as the leading message;
  L4  the method named without the literal `ci_method = "value"` adjacency, e.g.
      `{.val "montecarlo"}` beside `{.arg ci_method}`;
  L5  an abort raised by something outside this scanner's wrapper list, e.g. a
      bare `rlang::abort()`;
  L6  an abort call that does not OPEN its line, e.g. assigned or nested.

File scope is a limit too, and it is the one limit here that NO probe
demonstrates: only `R/ci-*.R` is read, so a `ci_method` named by an abort
anywhere else in the package is out of the enumeration. A probe would have to
construct a file outside the glob and show it unread, which is a property of the
glob rather than of the predicate; it is stated and left unprobed, and it is not
counted among the six.

`spliced_message_sites()` narrows L2 rather than closing it. It reports exactly
ONE shape -- a whole line that is a bare identifier -- and `_unreported_splices`
probes the five shapes it stays blind to (`i = cause`, `!!!bullets`, a
`paste0()` bullet, a symbol sharing a line, a message vector spliced on the
call's own line). It is not, and must not be described as, a gate on any spliced
variable.

Usage (run from the repo root):
    python3 data-raw/enumerate-ci-method-remedies.py            # print the enumeration
    python3 data-raw/enumerate-ci-method-remedies.py --emit     # write it to disk
    python3 data-raw/enumerate-ci-method-remedies.py --check    # completeness gate
    python3 data-raw/enumerate-ci-method-remedies.py --self-test

`--check` fails on an unclassified site, on a ledger row matching no site, and on
a committed enumeration that is not this run's own output. All three are driven
by probes in `--self-test` (`_check_probes`), against a passing control, rather
than asserted from a hand-mutation someone once ran. A reported splice is a
fourth route to a non-zero exit, probed differently (`_unreported_splices`); see
`check()`'s own docstring for all four.
"""

import contextlib
import glob
import hashlib
import io
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

# Sentinel: "read the committed enumeration from disk". `None` cannot serve,
# because a probe must be able to say "there is no committed enumeration".
_UNREAD = object()


def spliced_in(path, lines):
    """ONE splice shape, named exactly: a WHOLE LINE that is a bare identifier.

    The scanner reads bullets out of the abort call itself, so bullets built
    elsewhere and spliced in are invisible to it. Rather than leave that
    assumption silent, this reports the one splice shape it can recognize.

    What it does NOT recognize is stated here and probed in `--self-test`, so no
    record can call this a general splice gate again: a NAMED splice (`i = cause`)
    passes, and so do `!!!bullets`, a `paste0()` bullet, a bare symbol sharing a
    line with another element, and a spliced whole message vector. Widening the
    match to any of those means resolving the variable, which is a different and
    much larger scanner; refusing to overstate what this one does is the cheap
    half, and it is the half a durable record can safely cite.
    """
    out = []
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


def spliced_message_sites():
    """`spliced_in` over the shipped sources."""
    out = []
    for path in sorted(glob.glob(R_GLOB)):
        with open(path, encoding="utf-8") as fh:
            out.extend(spliced_in(path, fh.read().splitlines()))
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
            sites.extend(sites_in(path, fh.read().splitlines(), wrappers))
    return sites


def sites_in(path, lines, wrappers=None):
    """`enumerate_sites` for one file's lines, so a probe can feed it source.

    The predicate lives here and nowhere else, which is what lets `--self-test`
    demonstrate its LIMITS on constructed source rather than assert them in
    prose. Every shape listed in this module's docstring under "What the
    predicate does not match" has a probe that runs it through this function.
    """
    sites = []
    if wrappers is None:
        wrappers = wrapper_classes()
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


def check(sites, ledger, committed=_UNREAD, spliced=None):
    """The completeness gate. FOUR routes to a non-zero exit:

      1. an UNCLASSIFIED site -- a current site with no ledger row;
      2. a STALE ledger row -- a row matching no current site;
      3. a SPLICED message vector -- an abort whose bullets this scanner cannot
         see, reported by `spliced_message_sites()` for exactly one shape;
      4. a stale committed enumeration -- one that is not this run's own output.

    Routes 1, 2 and 4 are driven on constructed input by `_check_probes()`.
    Route 3 is the narrow one: `_unreported_splices()` probes the five splice
    shapes it does NOT report, so the gate is never described as catching any
    spliced variable.

    `committed` is the enumeration text on disk and `spliced` the splice report;
    both are parameters rather than reads so a probe can drive every branch
    without touching a committed file. They default to the real ones.
    """
    if committed is _UNREAD:
        committed = None
        if os.path.exists(ENUMERATION):
            with open(ENUMERATION, encoding="utf-8") as fh:
                committed = fh.read()
    if spliced is None:
        spliced = spliced_message_sites()
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
    if committed != fresh:
        print(
            "%s is stale or absent -- regenerate with "
            "`python3 %s --emit`" % (ENUMERATION, sys.argv[0]),
            file=sys.stderr,
        )
        return 1
    # `.get`, not `[]`: every site is classified by the time this line runs, but
    # a KeyError here would mask a removed gate as a crash instead of a verdict.
    swept = [
        s for s in sites if ledger.get(s["key"], {}).get("disposition") == "sweep"
    ]
    print(
        "OK %d ci_method-naming reducer aborts, all classified "
        "(%d sweep, %d fence); %s current"
        % (len(sites), len(swept), len(sites) - len(swept), ENUMERATION)
    )
    return 0


def _quiet_check(sites, ledger, committed):
    """`check()` with its diagnostics swallowed -- a probe wants the exit code."""
    buf = io.StringIO()
    with contextlib.redirect_stderr(buf), contextlib.redirect_stdout(buf):
        return check(sites, ledger, committed=committed, spliced=[])


def _probe_site_and_row():
    """One synthetic site and the ledger row that classifies it."""
    lines = [
        "    abort_intraclass(",
        "      c(",
        '        "A probe abort.",',
        '        i = "Use {.code ci_method = \\"montecarlo\\"} instead."',
        "      ),",
        "      call = call",
        "    )",
    ]
    sites = sites_in("R/ci-probe.R", lines, {})
    ledger = {
        s["key"]: {"disposition": "fence", "reason": "probe"} for s in sites
    }
    return sites, ledger


def _check_probes():
    """The three ways `--check` must fail, as (label, sites, ledger, committed).

    Stated in the module docstring and gated here: an unclassified site, a ledger
    row matching no site, and a committed enumeration that is not this run's
    output.
    """
    sites, ledger = _probe_site_and_row()
    current = render(sites, ledger)
    return [
        # `committed` is the enumeration this input really renders, so the
        # freshness branch is SATISFIED and only the unclassified branch can
        # fail. A probe that fails by a second route is evidence about that
        # route -- removing the missing-row branch left this one green until the
        # committed text was matched to the input (caught mutating M3).
        ("a site with no ledger row", sites, {}, render(sites, {})),
        (
            "a ledger row matching no site",
            [],
            {"R/ci-gone.R:0000000000": {"disposition": "fence", "reason": "x"}},
            render([], {}),
        ),
        (
            "a stale committed enumeration",
            sites,
            ledger,
            current + "\n# hand-edited after the fact\n",
        ),
    ]


# The canonical limits line every record about this predicate must carry, parsed
# rather than eyeballed. AC2's failure was a record enumerating SEVEN probed
# shapes where `_limit_shapes()` holds six -- a divergence no gate could see
# because the counts lived in prose. Both records now state the counts in this
# one shape, and `--self-test` binds them to the probe lists below.
PARITY_RE = re.compile(
    r"PROBED LIMITS: (\d+) predicate shapes \(L1-L(\d+)\), (\d+) unreported "
    r"splice shapes; file scope stated, no probe\."
)


def _stated_limit_counts(text):
    """The (predicate, L-range end, splice) counts a record states, or None.

    The record is normalized first -- comment markers dropped and every run of
    whitespace collapsed -- so the line may wrap wherever its record wraps.
    """
    flat = re.sub(r"\s+", " ", re.sub(r"(?m)^\s*#\s?", "", text))
    m = PARITY_RE.search(flat)
    if m is None:
        return None
    return (int(m.group(1)), int(m.group(2)), int(m.group(3)))


def _ledger_header():
    """The ledger's comment header -- the record `--self-test` parses."""
    with open(LEDGER, encoding="utf-8") as fh:
        return "\n".join(ln for ln in fh.read().splitlines() if ln.startswith("#"))


def _limit_shapes():
    """Message shapes carrying a `ci_method` name that the predicate MISSES.

    One entry per limit stated in the module docstring. Each is real R that could
    be written tomorrow; none is matched today.
    """
    return [
        # L1 single-quoted R string: METHOD_RE requires the backslash-escaped
        # inner quotes a double-quoted R string produces.
        (
            "single-quoted bullet string",
            [
                "    abort_intraclass(",
                "      c(",
                "        'A probe abort.',",
                "        i = 'Use {.code ci_method = \"montecarlo\"} instead.'",
                "      ),",
                "      call = call",
                "    )",
            ],
        ),
        # L2 a NAMED splice. `spliced_in` wants a whole line that is a bare
        # identifier, so the `i = ` prefix hides it from both scanners.
        (
            "named bullet splice (`i = cause`)",
            [
                "    abort_intraclass(",
                "      c(",
                '        "A probe abort.",',
                "        i = cause",
                "      ),",
                "      call = call",
                "    )",
            ],
        ),
        # L3 a bullet not written as `i = `. Everything before the first `i = `
        # is read as the leading line, and a leading line's methods are excluded
        # on purpose -- so a method named in a `"i" = ` bullet is simply lost.
        (
            "quoted bullet name (`\"i\" = `)",
            [
                "    abort_intraclass(",
                "      c(",
                '        "A probe abort.",',
                '        "i" = "Use {.code ci_method = \\"montecarlo\\"} instead."',
                "      ),",
                "      call = call",
                "    )",
            ],
        ),
        # L4 an alternate spelling: the argument named and the value quoted
        # apart, which reads identically to a user and not at all to METHOD_RE.
        (
            "method named without the `ci_method = ` adjacency",
            [
                "    abort_intraclass(",
                "      c(",
                '        "A probe abort.",',
                '        i = "Pass {.val \\"montecarlo\\"} to {.arg ci_method}."',
                "      ),",
                "      call = call",
                "    )",
            ],
        ),
        # L5 an abort this scanner does not recognize as one. ABORT_RE lists the
        # package's own wrappers plus cli_abort; a bare rlang::abort() is missed.
        (
            "`rlang::abort()` rather than a package wrapper",
            [
                "    rlang::abort(",
                "      c(",
                '        "A probe abort.",',
                '        i = "Use {.code ci_method = \\"montecarlo\\"} instead."',
                "      ),",
                "      call = call",
                "    )",
            ],
        ),
        # L6 an abort call that does not OPEN its line. ABORT_RE anchors at the
        # start, so a nested or assigned call is invisible.
        (
            "abort call nested inside another expression",
            [
                "    cnd <- abort_intraclass(",
                "      c(",
                '        "A probe abort.",',
                '        i = "Use {.code ci_method = \\"montecarlo\\"} instead."',
                "      ),",
                "      call = call",
                "    )",
            ],
        ),
    ]


def _unreported_splices():
    """Splice shapes `spliced_in` does NOT report, one per stated limit.

    This list is why the gate is described as catching one shape and not "any
    variable spliced into a message vector": that broader claim was made by three
    durable records at once and was false of every shape below.
    """
    return [
        (
            "named splice (`i = cause`)",
            [
                "    abort_intraclass(",
                "      c(",
                '        "A probe abort.",',
                "        i = cause",
                "      ),",
                "      call = call",
                "    )",
            ],
        ),
        (
            "tidy-eval splice (`!!!bullets`)",
            [
                "    abort_intraclass(",
                "      c(",
                '        "A probe abort.",',
                "        !!!bullets",
                "      ),",
                "      call = call",
                "    )",
            ],
        ),
        (
            "bullet built by a call (`paste0(...)`)",
            [
                "    abort_intraclass(",
                "      c(",
                '        "A probe abort.",',
                '        i = paste0("Use ", best_method, " instead.")',
                "      ),",
                "      call = call",
                "    )",
            ],
        ),
        (
            "bare symbol sharing a line with the leading string",
            [
                "    abort_intraclass(",
                '      c("A probe abort.", bullets),',
                "      call = call",
                "    )",
            ],
        ),
        # A message vector spliced on a line of its OWN is reported (the control
        # below relies on that). It escapes only when it shares the call's line,
        # which is how a one-line abort is ordinarily written.
        (
            "the whole message vector spliced on the call's own line",
            ["    abort_intraclass(msg, call = call)"],
        ),
    ]


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

    # 2e. The three `--check` failure modes, driven rather than described. Each
    #     was hand-mutated once at an implement gate and then asserted in prose,
    #     which is a claim about a run nobody can repeat. Here `check()` is called
    #     on constructed inputs and its exit code read.
    for label, probe_sites, probe_ledger, committed in _check_probes():
        rc = _quiet_check(probe_sites, probe_ledger, committed)
        if rc == 0:
            fails.append(
                "`--check` returns 0 on %s; that failure mode is not gated" % label
            )
    ok_sites, ok_ledger = _probe_site_and_row()
    rc = _quiet_check(ok_sites, ok_ledger, render(ok_sites, ok_ledger))
    if rc != 0:
        fails.append(
            "`--check` returns %d on a classified site with a current "
            "enumeration; the gate rejects the passing case" % rc
        )

    # 2f. What the predicate does NOT match. Each shape below is listed in this
    #     module's docstring as a stated limit, and each is CONSTRUCTED here and
    #     shown unmatched, so a record can never claim coverage the code does not
    #     have. A limit that gets fixed makes its probe fail -- which is the
    #     prompt to delete the limit from the docstring, not to loosen the probe.
    for label, lines in _limit_shapes():
        found = sites_in("R/ci-probe.R", lines, {})
        if found:
            fails.append(
                "the documented limit %r is no longer a limit: the predicate now "
                "matches it (%r). Remove it from the docstring." % (label, found)
            )
    #     ...and the splice shapes `spliced_in` does not report, which is the
    #     narrower claim replacing "any abort that splices a variable".
    for label, lines in _unreported_splices():
        if spliced_in("R/ci-probe.R", lines):
            fails.append(
                "the documented splice limit %r is reported after all; the "
                "docstring understates the gate" % label
            )
    #     ...against a positive control, or the probes above pass by the reporter
    #     being broken rather than by the shape being exotic.
    control = [
        "    abort_intraclass(",
        "      c(",
        '        "Leading.",',
        "        bullets",
        "      ),",
        "      call = call",
        "    )",
    ]
    if not spliced_in("R/ci-probe.R", control):
        fails.append("spliced_in reports nothing on a bare-symbol splice")

    # 2g. The RECORDS about those probes must state the set the probes
    #     demonstrate. Pass 4's AC2 failure was exactly this gap: the ledger
    #     header and a milestone Decisions entry each enumerated SEVEN probed
    #     shapes -- L1-L6 plus file scope -- where `_limit_shapes()` holds six
    #     and no probe constructs a file outside the glob. Both counts are read
    #     out of the records here and compared with the probe lists, so a record
    #     claiming more (or fewer) probed limits than exist fails the gate rather
    #     than surviving another review.
    want = (len(_limit_shapes()), len(_limit_shapes()), len(_unreported_splices()))
    for label, text in (
        ("the module docstring", __doc__),
        ("the ledger header (%s)" % LEDGER, _ledger_header()),
    ):
        got = _stated_limit_counts(text)
        if got is None:
            fails.append(
                "%s states no PROBED LIMITS line; the record cannot be tied to "
                "the probe lists" % label
            )
        elif got != want:
            fails.append(
                "%s states %d predicate shapes (L1-L%d) and %d splice shapes; "
                "the probes demonstrate %d and %d" % ((label,) + got + (want[0], want[2]))
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
