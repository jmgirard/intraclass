#!/usr/bin/env python3
"""Enumerate the generalizing claims in the references corpus (M74).

A *generalizing claim* is a statement about a source table stated more broadly
than the cells it cites — a range ("the ratio runs 1.7-4x"), a count ("the four
lowest cells"), a superlative ("the narrowest ratios are extreme concave"), or a
universal quantifier ("all three tables") applied to a table's cells. M74
re-derives each such claim the repo *relies on* over the FULL source table and
confirms, narrows, or corrects it in place, recording the derivation basis.

This differs from M73's dated-observation checker by design (D-009 scope fence:
"Generalizing claims about a source's table are M74's — they need full-table
recomputation, NOT an exit code"). So this script does NOT decide whether a claim
is TRUE — only recomputation, recorded inline in the note, does that. What it
mechanizes is AC1: the *enumeration* is a recorded, re-runnable search, so a
later reader can confirm no candidate was skipped. It is a finder plus a
completeness gate over a committed triage ledger, never a claim-truth oracle.

The candidate regex is a deliberately wide recall net; the committed triage
ledger `data-raw/generalizing-claims-triage.tsv` classifies every candidate as
IN scope or OUT (with a reason), and for IN claims points at where the
recomputation lives. `--check` asserts every current candidate is classified in
the ledger and exits non-zero otherwise — an enumeration-completeness gate, not
a statement about any claim's correctness.

Usage (run from the repo root):
    python3 data-raw/enumerate-generalizing-claims.py            # list candidates
    python3 data-raw/enumerate-generalizing-claims.py --check    # completeness gate
    python3 data-raw/enumerate-generalizing-claims.py --self-test
"""
import hashlib
import os
import re
import subprocess
import sys

REF_DIR = "cairn/references"
LEDGER = "data-raw/generalizing-claims-triage.tsv"

# The recall net: a superlative, a universal quantifier, or a range/ratio shape,
# on a line that also carries a digit (a claim ABOUT numbers). Deliberately wide
# — false positives are cheap (triaged OUT with a reason); a missed claim is the
# failure AC1 exists to prevent.
SUPERLATIVE = (
    r"lowest|highest|smallest|largest|narrowest|widest|worst|best|steepest|"
    r"closest|furthest|farthest|maximal|minimal|\bmost\b|\bleast\b|"
    r"monoton|\bU-shaped\b"
)
QUANTIFIER = (
    r"all [0-9]|all (three|four|five|six|seven|eight|nine|ten|the)\b|"
    r"every one|every cell|every case|every dose|each of the|none of|no cell|"
    r"both sit|both are|both halves|throughout|across all|in every|at every|"
    r"at all (three|four|five|six)"
)
RANGE = (
    r"(runs|ranges? from|between)\s+.*[0-9].*[–-].*[0-9]|"
    r"[0-9](\.[0-9]+)?\s*[–-]\s*[0-9](\.[0-9]+)?\s*(×|x\b|%|fold|-fold)|"
    r"from\s+[0-9][0-9.]*\s+to\s+[0-9]|"
    r"(decay|fall|rise|grow|climb|drop)[a-z]*\s+from\s+[0-9]"
)
CANDIDATE = re.compile(
    rf"(?i)\b({SUPERLATIVE}|{QUANTIFIER})\b|{RANGE}"
)
HAS_DIGIT = re.compile(r"[0-9]")

# A bare "NUM-NUM" range with no ×/%/from-to cue (e.g. "731-862", "0.51-0.87")
# still generalizes over a table. Two firing rules, tuned to catch value ranges
# without drowning in citation page ranges (a bibliography is nothing but
# "Journal, 19, 3-11"):
#   * a DECIMAL-DECIMAL range always fires — ICC / coverage / ratio values carry
#     a decimal point; journal volumes and pages do not. This is the main win.
#   * a bare INTEGER-INTEGER range fires only when the line also carries a table
#     cue (cell/condition/coverage/across/...) — catching "731-862 ... nine
#     cells" while ignoring citation "762-765" and equation "16-18".
# Year ranges and p./pp./Eq. prefixes are excluded on both paths.
BARE_RANGE = re.compile(r"(\d+(?:\.\d+)?)\s*[–-]\s*(\d+(?:\.\d+)?)")
RANGE_EXCLUDE_PRE = re.compile(
    r"(?i)(pp?\.|pages?|eqs?\.|tables?|figs?\.|figures?|§|chap|ch\.|"
    r"nn?os?\.|grades?|steps?|vol\.)\s*\(?\s*$"
)
YEAR = re.compile(r"^(19|20)\d\d$")
TABLE_CUE = re.compile(
    r"(?i)\b(cells?|conditions?|coverage|rates?|×1000|x1000|across|"
    r"tabulat|cases?|settings?|combinations?)\b"
)


def has_bare_range(line):
    """True if the line carries a value range that is not a page/eq/year ref."""
    has_cue = bool(TABLE_CUE.search(line))
    for m in BARE_RANGE.finditer(line):
        lo, hi = m.group(1), m.group(2)
        if YEAR.match(lo) and YEAR.match(hi):
            continue
        if RANGE_EXCLUDE_PRE.search(line[: m.start()]):
            continue
        is_decimal = "." in lo or "." in hi
        if is_decimal or has_cue:
            return True
    return False


def repo_root():
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, check=True,
    )
    return out.stdout.strip()


def norm(text):
    """Normalize a matched line for stable keying: collapse whitespace, strip."""
    return re.sub(r"\s+", " ", text).strip()


def key(citekey, text):
    """A stable candidate key: citekey + short hash of the normalized text.

    Survives line-number drift as notes are edited; changes only when the claim
    text itself changes (at which point the ledger row is refreshed to match)."""
    h = hashlib.sha1(norm(text).encode("utf-8")).hexdigest()[:10]
    return f"{citekey}:{h}"


def find_candidates(root):
    """Every candidate line across the references corpus, as (key, citekey,
    lineno, text)."""
    out = []
    ref = os.path.join(root, REF_DIR)
    for name in sorted(os.listdir(ref)):
        if not name.endswith(".md"):
            continue
        citekey = name[:-3]
        with open(os.path.join(ref, name), encoding="utf-8") as fh:
            for i, line in enumerate(fh, 1):
                if not HAS_DIGIT.search(line):
                    continue
                if CANDIDATE.search(line) or has_bare_range(line):
                    out.append((key(citekey, line), citekey, i, line.rstrip("\n")))
    return out


def load_ledger(root):
    """The committed triage ledger, keyed by candidate key.

    TSV columns: key, citekey, disposition, reason. Lines starting with # and the
    header row are ignored."""
    path = os.path.join(root, LEDGER)
    ledger = {}
    if not os.path.exists(path):
        return ledger
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#") or not line.strip():
                continue
            cols = line.rstrip("\n").split("\t")
            if cols[0] == "key":
                continue
            ledger[cols[0]] = cols
    return ledger


def cmd_list(root):
    for k, citekey, lineno, text in find_candidates(root):
        print(f"{k}\t{REF_DIR}/{citekey}.md:{lineno}\t{norm(text)[:120]}")


def cmd_check(root):
    """Enumeration-completeness gate: every current candidate must be triaged.

    NOT a claim-truth check (D-009 fence) — it verifies coverage of the
    enumeration, so review can trust no generalizing claim was skipped."""
    candidates = find_candidates(root)
    ledger = load_ledger(root)
    missing = [(k, citekey, lineno, text)
               for (k, citekey, lineno, text) in candidates if k not in ledger]
    print(f"candidates: {len(candidates)}   ledger rows: {len(ledger)}   "
          f"un-triaged: {len(missing)}")
    if missing:
        print("\nUN-TRIAGED candidates (add a ledger row for each):", file=sys.stderr)
        for k, citekey, lineno, text in missing:
            print(f"  {k}  {REF_DIR}/{citekey}.md:{lineno}\n    {norm(text)[:140]}",
                  file=sys.stderr)
        return 1
    print("OK — every enumerated candidate is classified in the triage ledger.")
    print("(This gates enumeration completeness only, never a claim's correctness.)")
    return 0


def self_test():
    """Assert the recall net catches each generalizing shape and the digit
    guard rejects a bare superlative with no number."""
    must_match = [
        "the ratio runs 1.10-4.12 over all 40 cells",
        "the four lowest cells are all at rho = 0.1",
        "GP's two lowest cells are 0.913 and 0.918",
        "every one of the 36 PL cells lands in 0.931-0.950",
        "the ratio decays from 3.77 to 1.10 across phi",
        "sigma_a is highest under concave (2.43) and lowest under convex (0.70)",
    ]
    must_match_bare = [
        "coverage rates range 731-862 across nine cells",   # bare integer range
        "six ICCs range 0.51-0.87 in Table 2",              # bare decimal range
    ]
    must_not = [
        "generalizability theory is the framework",   # domain term, no claim
        "the best available source for this design",  # superlative, no digit
        "results generalize to a population of raters",
    ]
    must_not_bare = [
        "the derivation spans pp. 2247-2248 of the source",  # page range
        "Eqs. 16-18, p. 2258",                               # equation range
        "the preprint's 2021-2022 versions",                 # year range
        "integer grades 0-4 treated as continuous",          # grade range
    ]
    ok = True
    for s in must_match:
        if not (HAS_DIGIT.search(s) and CANDIDATE.search(s)):
            print(f"SELF-TEST FAIL: should match but did not: {s}", file=sys.stderr)
            ok = False
    for s in must_match_bare:
        if not has_bare_range(s):
            print(f"SELF-TEST FAIL: bare range should match: {s}", file=sys.stderr)
            ok = False
    for s in must_not:
        if HAS_DIGIT.search(s) and (CANDIDATE.search(s) or has_bare_range(s)):
            print(f"SELF-TEST FAIL: should NOT match but did: {s}", file=sys.stderr)
            ok = False
    for s in must_not_bare:
        if has_bare_range(s):
            print(f"SELF-TEST FAIL: bare range should NOT match: {s}", file=sys.stderr)
            ok = False
    print("self-test: OK" if ok else "self-test: FAILED")
    return 0 if ok else 1


def main():
    root = repo_root()
    if "--self-test" in sys.argv:
        return self_test()
    if "--check" in sys.argv:
        return cmd_check(root)
    cmd_list(root)
    return 0


if __name__ == "__main__":
    sys.exit(main())
