#!/usr/bin/env python3
"""Worst downward step in kappa_m along the subject axis, per conf_level (M102).

The ROADMAP's MPL monotone-envelope candidate row states three figures -- the
largest decrease in the calibrated kappa_m between two adjacent subject counts
at a fixed rater count, one per confidence level. They were transcribed there
by hand from the committed calibration tables and never re-derived since. This
script re-derives them from those tables so `data-raw/record-claims.tsv` can
register the row's figures against a command rather than against a reader.

The tables live in two fixtures because they were calibrated by two milestones:
the shipped 0.95 table in `m88-kappa-table.rds`, and the 0.90 and 0.99 tables
in `m90-kappa-tables.rds`. Both are parsed with M94's stdlib RDS reader (loaded
out of `check-mpl-doc-claims.py`), because the CI job that runs this has no R.

Prints one `<level> <step>` line per level, ascending, each rounded to three
decimals -- the precision the ROADMAP row states.

Usage (from the repo root):
    python3 data-raw/record-claims-kappa-steps.py
"""

import gzip
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
M88 = os.path.join(HERE, "m88-kappa-table.rds")
M90 = os.path.join(HERE, "m90-kappa-tables.rds")


def _reader():
    spec = importlib.util.spec_from_file_location(
        "mpl_doc_claims", os.path.join(HERE, "check-mpl-doc-claims.py")
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read_rds(path, module):
    with open(path, "rb") as fh:
        raw = fh.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return module._pyify(module._Reader(raw).read())


def worst_downward_step(table):
    """Most negative kappa_m difference between adjacent n_s at fixed n_r."""
    rows = sorted(zip(table["n_r"], table["n_s"], table["kappa_m"]))
    worst = 0.0
    for prev, cur in zip(rows, rows[1:]):
        if prev[0] != cur[0]:
            continue
        step = cur[2] - prev[2]
        if step < worst:
            worst = step
    return worst


def main():
    module = _reader()
    tables = {
        "0.90": read_rds(M90, module)["tables"]["0.90"],
        "0.95": read_rds(M88, module)["kappa_m_table"],
        "0.99": read_rds(M90, module)["tables"]["0.99"],
    }
    for level in ("0.90", "0.95", "0.99"):
        print(f"{level} {worst_downward_step(tables[level]):.3f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
