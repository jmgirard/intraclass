#!/usr/bin/env python3
"""Enforce the D-007 registry invariant: every asserted oracle has an entry (M79).

`cairn/references/ORACLES.md` states its own invariant — "every oracle value in
the test suite must trace back to an entry here" (PRINCIPLES.md #4/#12, D-007).
M72 T4 found that invariant false: oracle families kept shipping with no registry
entry (M46/M47 cluster-`ck`, the lavaan-multilevel family, the frequentist
fixed/incomplete multilevel oracles, the d-study oracles, ...). This checker makes
the invariant machine-verifiable so it cannot silently regress again.

The rule: every `O-*` oracle label asserted in `tests/testthat/*.R` must be
**covered** — either documented in `ORACLES.md` (as an entry heading or a bolded
inline sub-oracle) or listed in the ALIASES allowlist below with its reason. A
label that is neither is a GAP and fails the check.

Coverage is decided by **exact base-ID match**, never prefix match: `O-SEM` must
not be read as covering the distinct `O-SEM-ML`, or a future oracle that extends
an existing entry's name at a separator would escape detection (the very failure
M79 exists to close). A label's base is the text before its first `/` sub-path;
a curated set of hyphenated sub-check suffixes (`-agree`, `-lme4`, ...) is then
stripped so `O-Bayes-ML-agree` resolves to the entry `O-Bayes-ML`. What remains
must be an ORACLES.md token or an explicit ALIASES key.

Usage (run from the repo root):
    python3 data-raw/check-oracle-registry.py              # check the invariant
    python3 data-raw/check-oracle-registry.py --list       # dump base->coverage
    python3 data-raw/check-oracle-registry.py --self-test  # harness bite
"""
import os
import re
import subprocess
import sys

REGISTRY = "cairn/references/ORACLES.md"
TEST_GLOB_DIR = "tests/testthat"

# An oracle label. The left look-behind stops the regex matching inside a word:
# without it `TWO-WAY` yields a spurious `O-WAY` token.
LABEL = re.compile(r"(?<![A-Za-z0-9])O-[A-Za-z0-9][A-Za-z0-9/-]*")

# Hyphenated sub-check suffixes: a label like `O-Bayes-ML-agree` is the `-agree`
# sub-check of the entry `O-Bayes-ML`, written with a hyphen instead of the modern
# `/` separator. Each is a *verb of checking*, never a segment of any base oracle
# ID (base IDs use ML/OW/NML/FML/ck/FIXED/INC/BOOT/DS/cc/... — none appear here),
# so stripping them cannot conflate two distinct oracles. Applied repeatedly.
SUBCHECK_SUFFIXES = (
    "-agree", "-coverage", "-reduction", "-containment", "-wiring",
    "-lme4", "-sim", "-recovery", "-parity", "-ident", "-point",
)

# Labels that intentionally have no entry of their own, each mapped to the entry
# that covers them and why. This is the audited manifest of deliberate omissions —
# a reviewer reads it to confirm nothing real hides here.
ALIASES = {
    "O-conflated": "O-Conflated (case-only variant of the M17 Slice 1 entry)",
    "O-cc-Eq14": "O-cc (hyphen variant of the O-cc/Eq14-analogue sub-check)",
}


def repo_root():
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, check=True,
    )
    return out.stdout.strip()


def normalize(token):
    """Reduce a raw label to its base oracle ID: drop any `/` sub-path, strip
    trailing punctuation/hyphens (wrap artifacts like `O-Bayes-`, `O-cc-`), then
    peel known sub-check suffixes until none remain."""
    base = token.split("/", 1)[0]
    base = base.rstrip("-.,:;)")
    changed = True
    while changed:
        changed = False
        for suf in SUBCHECK_SUFFIXES:
            if base.endswith(suf) and len(base) > len(suf):
                base = base[: -len(suf)]
                changed = True
    return base


BOLD = re.compile(r"\*\*(.+?)\*\*", re.DOTALL)


def registry_tokens(root):
    """Every distinct base oracle ID that ORACLES.md actually *registers*: one
    named in a `###` entry heading, or defined in a bolded `**...**` span (the
    convention for an inline sub-oracle — `**O-SB (Spearman–Brown)**`). A bare
    prose cross-reference ("ships separately as O-cluster-ck") is deliberately
    NOT coverage — a mention is not an entry, and counting it would let a gap
    hide behind a passing reference to itself."""
    with open(os.path.join(root, REGISTRY), encoding="utf-8") as fh:
        text = fh.read()
    toks = set()
    for line in text.splitlines():
        if line.startswith("###"):
            toks.update(normalize(m.group(0)) for m in LABEL.finditer(line))
    for b in BOLD.finditer(text):
        toks.update(normalize(m.group(0)) for m in LABEL.finditer(b.group(1)))
    return toks


def test_labels(root):
    """Map each asserted base oracle ID to a sorted list of the test files that
    assert it (so a gap report can point at the source)."""
    d = os.path.join(root, TEST_GLOB_DIR)
    out = {}
    for fname in sorted(os.listdir(d)):
        if not fname.endswith(".R"):
            continue
        with open(os.path.join(d, fname), encoding="utf-8") as fh:
            text = fh.read()
        for m in LABEL.finditer(text):
            base = normalize(m.group(0))
            out.setdefault(base, set()).add(fname)
    return {k: sorted(v) for k, v in out.items()}


def gaps(root):
    """Asserted base IDs covered by neither ORACLES.md nor ALIASES."""
    reg = registry_tokens(root)
    labels = test_labels(root)
    return {
        base: files
        for base, files in labels.items()
        if base not in reg and base not in ALIASES
    }, reg, labels


def self_test(root):
    """Harness bite: a label present in no ORACLES.md token and no ALIASES key
    must be reported as a gap. If the coverage logic ever stops catching an
    orphan (a refactor making the checker vacuous), this fails."""
    reg = registry_tokens(root)
    orphan = "O-zzz-no-such-oracle-zzz"
    real = "O-OW"  # a genuine entry heading — must read as covered
    problems = []
    if normalize(orphan) in reg or normalize(orphan) in ALIASES:
        problems.append("orphan token unexpectedly covered: %r" % orphan)
    if normalize(real) not in reg:
        problems.append("known entry read as a gap: %r" % real)
    if problems:
        print("SELF-TEST FAILED:")
        for p in problems:
            print("  " + p)
        return 1
    print("self-test OK: an orphan oracle is flagged, a real entry is covered")
    return 0


def main(argv):
    root = repo_root()

    if "--self-test" in argv:
        return self_test(root)

    missing, reg, labels = gaps(root)

    if "--list" in argv:
        for base in sorted(labels):
            mark = "GAP " if base in missing else "ok  "
            print("%s %s" % (mark, base))
        print(
            "\n%d asserted base oracles · %d registry tokens · %d gaps"
            % (len(labels), len(reg), len(missing))
        )
        return 0

    print("asserted base oracles: %d" % len(labels))
    print("  registry tokens:     %d" % len(reg))
    print("  allowlisted aliases: %d" % len(ALIASES))
    print("  gaps:                %d" % len(missing))

    if missing:
        print("\nGAP — asserted oracles with no ORACLES.md entry (D-007 invariant):")
        for base in sorted(missing):
            print("  %s  (%s)" % (base, ", ".join(missing[base])))

    return 0 if not missing else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
