#!/usr/bin/env python3
"""Enforce M92's no-restated-figures rule (M92 AC5).

Two independent assertions, both mechanical:

1. **No exported-doc change.** M92 ships no edit to `R/icc.R`, `man/`, `NEWS.md` or
   `README.md`. That surface is M94's, fenced out at M92's re-cut after its prose
   failed review three times. An empty diff cannot be misread the way prose can.

2. **No restated run figure in a file M92 changes.** No file in this milestone's own
   diff, outside three permitted sites, may contain a per-cell coverage/width/miss
   figure from either M92 sweep run. The permitted sites are the comparison note
   (which carries the two-run account), the milestone record (which carries the review
   history), and the ledger.

   The sweep is scoped to the diff deliberately, and that is not a weakening. Values
   like `0.944` and `0.938` are ordinary content across this repo -- published Table I
   coverages in `ukoumunne2003.md`, `xiao2009.md`'s simulation tables, other
   milestones' fixtures -- so a whole-tree value match cannot discriminate an M92
   restatement from a decade of unrelated statistics, and a checker that cries wolf on
   80 pre-existing lines is one nobody runs. M92 can only introduce a restatement into
   a file it edits, which is exactly what AC5 says.

Why this exists. M92 re-ran its sweep on a disjoint seed base, and every figure copied
out to another file went stale. Three hand-written greps each missed a different site,
for a different formatting reason (four decimals vs three, "42 / 14" vs "42 below",
miss counts vs coverages). So the probe set here is derived FROM the two committed
fixtures rather than typed by hand, and non-discriminating tokens are excluded by an
explicit, documented rule rather than by whoever writes the next grep.

Run:  python3 data-raw/check-m92-figure-restatement.py
Exit: 0 clean, 1 on any violation. Add --verbose to see the probe set.
"""

from __future__ import annotations

import subprocess
import sys

EXPORTED_DOC_PATHS = ["R/icc.R", "man/", "NEWS.md", "README.md"]

# The three places an M92 run figure may legitimately appear.
PERMITTED = {
    "cairn/references/mpl-twoway-random-comparison.md",
    "cairn/milestones/M92-mpl-095-interp-probe.md",
    "data-raw/generalizing-claims-triage.tsv",
    # This file: its docstring quotes figures as examples of what it forbids.
    "data-raw/check-m92-figure-restatement.py",
}

FIXTURES = {
    "run2": "data-raw/m92-interp-sweep.rds",
    "run1": "data-raw/m92-interp-sweep-run1-collided.rds",
}

# Values that also occur in the repo for unrelated reasons, so they cannot discriminate
# an M92 restatement from ordinary content. Each is listed with the reason it is
# ambiguous; this list is the ONLY hand-maintained part of the probe set, and every
# entry must name where else the token occurs.
NON_DISCRIMINATING = {
    "1.000": "M91's D3 coverage; M91's near-vacuous 0.99 cell; a README interval bound",
    "1.0000": "same as 1.000",
    "0.000": "trivially common",
    "0.0000": "trivially common",
    "0.900": "M91's D3 median width discussion",
    "0.9000": "same as 0.900",
    # 3-dp only. This collides with the `eps_hi <- 0.999` clamp constant in every sweep
    # generator and with `conf_level = 0.999` in a test grid, so it cannot discriminate.
    # The 4- and 5-dp forms stay in the probe set, so E3's run-2 coverage (0.999) is
    # still protected wherever it is written to the precision the note uses.
    "0.999": "the eps_hi clamp constant in the sweep generators; a conf_level in test-ci-mpl.R:496",
}


def sh(*args: str) -> str:
    return subprocess.run(args, capture_output=True, text=True, check=False).stdout


def fixture_figures() -> set[str]:
    """Per-cell figures from BOTH runs, as every plausible written form.

    Read out of the committed .rds files via Rscript, so the probe set tracks the
    fixtures automatically -- a re-run changes the probe set without anyone editing
    this file, which is the whole point.
    """
    fields = ["coverage", "cp_lo", "cp_hi", "width_med", "width_p90"]
    counts = ["miss_below", "miss_above"]
    expr = f"""
      paths <- c({", ".join(repr(p) for p in FIXTURES.values())})
      out <- character(0)
      for (p in paths) {{
        if (!file.exists(p)) next
        s <- readRDS(p)$summary
        for (f in c({", ".join(repr(f) for f in fields)})) out <- c(out, as.character(s[[f]]))
        for (f in c({", ".join(repr(f) for f in counts)})) out <- c(out, paste0("#", s[[f]]))
      }}
      cat(paste(out, collapse = "\\n"))
    """
    raw = [v for v in sh("Rscript", "-e", expr).strip().split("\n") if v]
    probes: set[str] = set()
    for v in raw:
        if v.startswith("#"):
            # A miss COUNT. Bare integers match everything, so only phrase-anchored
            # and slash-paired forms are probed.
            n = v[1:]
            probes.update({f"{n} below", f"{n} above"})
            continue
        try:
            f = float(v)
        except ValueError:
            continue
        for d in (3, 4, 5):
            probes.add(f"{f:.{d}f}")
    return {p for p in probes if p not in NON_DISCRIMINATING}


def check_exported_docs() -> list[str]:
    base = sh("git", "merge-base", "HEAD", "origin/main").strip() or "origin/main"
    changed = sh("git", "diff", "--name-only", f"{base}..HEAD", "--", *EXPORTED_DOC_PATHS)
    return [f for f in changed.split() if f]


def changed_files() -> list[str]:
    base = sh("git", "merge-base", "HEAD", "origin/main").strip() or "origin/main"
    return [f for f in sh("git", "diff", "--name-only", f"{base}..HEAD").split() if f]


def check_restatements(probes: set[str]) -> list[tuple[str, int, str, str]]:
    targets = [
        f
        for f in changed_files()
        if f not in PERMITTED and not f.endswith((".rds", ".rda", ".png", ".pdf"))
    ]
    hits: list[tuple[str, int, str, str]] = []
    for path in targets:
        try:
            with open(path, encoding="utf-8", errors="ignore") as fh:
                lines = fh.read().split("\n")
        except OSError:
            continue
        for i, line in enumerate(lines, 1):
            for p in probes:
                if p in line:
                    hits.append((path, i, p, line.strip()[:90]))
    return hits


def main() -> int:
    verbose = "--verbose" in sys.argv
    probes = fixture_figures()
    if not probes:
        print("FAIL: derived an empty probe set -- fixtures missing or unreadable?")
        return 1

    failed = False

    exported = check_exported_docs()
    if exported:
        failed = True
        print("FAIL: M92 must ship no exported-doc change; these differ from main:")
        for f in exported:
            print(f"  {f}")
    else:
        print(f"OK  exported docs unchanged ({', '.join(EXPORTED_DOC_PATHS)})")

    hits = check_restatements(probes)
    if hits:
        failed = True
        print(f"FAIL: run figures restated outside the {len(PERMITTED)} permitted sites:")
        for path, line, probe, text in hits:
            print(f"  {path}:{line}  [{probe}]  {text}")
    else:
        print(f"OK  no run figure restated ({len(probes)} probes x changed files)")

    if verbose:
        print("\nprobe set:")
        for p in sorted(probes):
            print(f"  {p}")
        print("\nexcluded as non-discriminating:")
        for p, why in sorted(NON_DISCRIMINATING.items()):
            print(f"  {p}: {why}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
