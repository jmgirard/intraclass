#!/usr/bin/env python3
"""Check the glossary-term rule (R7 of `cairn/doctrine/prose-style.md`).

`data-raw/glossary-terms.tsv` carries one row per `## ` heading of
`vignettes/glossary.Rmd`, with a grep `pattern`, a short plain `gloss`, and a
`disposition` of `term` or `exempt`.  For each `term` row and each checked
file, the first prose sentence matching `pattern` must carry the row's
`gloss` text verbatim, or a link to that heading's anchor in the glossary.
A file with no occurrence passes.

Like `prose-profile.py`, this is a hand-run ruler, not a CI job (cairn D-021
bars standing apparatus over the repo's own records).  Prose is what
`prose-profile.py` defines: the same stripping (`.Rmd` mode, or roxygen mode
for an `.R` file), and a pattern is matched against the normalized sentence,
where a code span is the one word `code`.

Usage
-----
    python3 data-raw/prose-terms.py
    python3 data-raw/prose-terms.py vignettes/getting-started.Rmd README.Rmd
    python3 data-raw/prose-terms.py --self-test

With no file argument the three reader-path files are checked.  Exit status
is 1 when any term's first use is neither glossed nor linked, or when the
table's headings differ from the glossary's.
"""

from __future__ import annotations

import csv
import importlib.util
import os
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
TABLE = os.path.join(HERE, "glossary-terms.tsv")
GLOSSARY = os.path.join(ROOT, "vignettes", "glossary.Rmd")
DEFAULT_FILES = [
    os.path.join(ROOT, "vignettes", "getting-started.Rmd"),
    os.path.join(ROOT, "vignettes", "choosing-an-icc.Rmd"),
    os.path.join(ROOT, "README.Rmd"),
]


def load_ruler():
    """Import `prose-profile.py` (a hyphenated name, so not a plain import)."""
    spec = importlib.util.spec_from_file_location(
        "prose_profile", os.path.join(HERE, "prose-profile.py")
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


RULER = load_ruler()

RE_HEADING_LINE = re.compile(r"^## (.+?)\s*$")
RE_MARKUP = re.compile(r"[`*_]|\[([^\]]*)\]\([^)]*\)")


def slug(heading: str) -> str:
    """Pandoc's auto-identifier for a heading (what pkgdown links carry)."""
    text = RE_MARKUP.sub(lambda m: m.group(1) or "", heading).lower()
    text = re.sub(r"[^a-z0-9 _.\-]", "", text)
    text = re.sub(r"\s+", "-", text.strip())
    return re.sub(r"^[^a-z]+", "", text)


def glossary_headings(path: str = GLOSSARY) -> list[str]:
    with open(path, encoding="utf-8") as handle:
        return [
            m.group(1)
            for m in (RE_HEADING_LINE.match(line) for line in handle)
            if m is not None
        ]


def read_table(path: str = TABLE) -> list[dict[str, str]]:
    with open(path, encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    expected = ["heading", "pattern", "gloss", "disposition"]
    if not rows or list(rows[0].keys()) != expected:
        raise SystemExit(f"prose-terms: columns must be {expected}")
    for row in rows:
        if row["disposition"] not in ("term", "exempt"):
            raise SystemExit(
                f"prose-terms: bad disposition {row['disposition']!r} "
                f"for {row['heading']!r}"
            )
    return rows


def raw_sentences(path: str) -> list[str]:
    """Prose sentences with links still in place, so an anchor is visible.

    An `.R` file is read in the ruler's roxygen mode (M153): its prose is the
    `#'` lines outside `@examples` blocks and outside `@noRd` blocks, never
    its code.
    """
    with open(path, encoding="utf-8") as handle:
        raw = handle.read()
    if path.endswith((".R", ".r")):
        prose = RULER.strip_roxygen(raw)
    else:
        prose = RULER.strip_rmd(raw)
    out: list[str] = []
    for para in RULER.paragraphs(prose):
        out.extend(RULER.sentences(para))
    return out


def first_use(sentences: list[str], pattern: str) -> str | None:
    rx = re.compile(pattern, re.IGNORECASE)
    for sent in sentences:
        if rx.search(RULER.normalize(sent)):
            return sent
    return None


def verdict(sentence: str | None, gloss: str, anchor: str) -> str:
    if sentence is None:
        return "absent"
    if gloss in RULER.normalize(sentence):
        return "glossed"
    if f"glossary.html#{anchor}" in sentence or f"(#{anchor})" in sentence:
        return "linked"
    return "MISSING"


def check(
    files: list[str],
    table: list[dict[str, str]],
    headings: list[str],
    quiet: bool = False,
) -> int:
    failures = 0
    got = [row["heading"] for row in table]
    if got != headings:
        print("prose-terms: table headings differ from the glossary's:")
        for h in headings:
            if h not in got:
                print(f"  glossary only: {h}")
        for h in got:
            if h not in headings:
                print(f"  table only:    {h}")
        failures += 1
    for row in table:
        if row["disposition"] == "exempt":
            continue
        anchor = slug(row["heading"])
        for path in files:
            sent = first_use(raw_sentences(path), row["pattern"])
            v = verdict(sent, row["gloss"], anchor)
            label = os.path.relpath(path, ROOT)
            if v == "MISSING":
                failures += 1
                print(f"MISSING  {row['heading']} | {label}: {sent}")
            elif not quiet:
                print(f"{v:<8} {row['heading']} | {label}")
    if failures:
        print(f"prose-terms: {failures} failure(s)")
        return 1
    if not quiet:
        print("prose-terms: every first use is glossed or linked")
    return 0


def self_test() -> int:
    """Plant the defect classes the check claims to catch; require each red."""
    table = [
        {
            "heading": "Estimand",
            "pattern": r"\bestimands?\b",
            "gloss": "the true quantity you are trying to estimate",
            "disposition": "term",
        },
        {
            "heading": "References",
            "pattern": "(?!)",
            "gloss": "the reference list",
            "disposition": "exempt",
        },
    ]
    headings = ["Estimand", "References"]
    cases = {
        # (text, expected exit)
        "glossed": (
            "An estimand is the true quantity you are trying to estimate. "
            "Later the estimand recurs unglossed.",
            0,
        ),
        "linked": (
            "Pick the [estimand](glossary.html#estimand) first. "
            "Later the estimand recurs.",
            0,
        ),
        "absent": ("No term of art appears in this file at all.", 0),
        "bare": (
            "The estimand is what you want. "
            "An estimand is the true quantity you are trying to estimate.",
            1,
        ),
        "code-only": ("Call `estimand()` and read the code.", 0),
    }
    with tempfile.TemporaryDirectory() as tmp:
        for name, (text, want) in cases.items():
            path = os.path.join(tmp, f"{name}.Rmd")
            with open(path, "w", encoding="utf-8") as handle:
                handle.write("---\ntitle: x\n---\n\n" + text + "\n")
            got = check([path], table, headings, quiet=True)
            assert got == want, f"{name}: expected exit {want}, got {got}"
            print(f"PASS {name}: exit {got}")
        # An `.R` file is read as roxygen: the bare `estimand` in the code
        # line and in the `@noRd` block below never count as a first use, so
        # the glossed roxygen sentence is the first one seen.
        r_path = os.path.join(tmp, "roxygen.R")
        with open(r_path, "w", encoding="utf-8") as handle:
            handle.write(
                "\n".join(
                    [
                        "estimand <- function() NULL # the estimand, bare.",
                        "#' The estimand is the bare internal note.",
                        "#' @noRd",
                        "g <- function() NULL",
                        "#' An estimand is the true quantity you are trying"
                        " to estimate.",
                        "#' Later the estimand recurs unglossed.",
                        "h <- function() NULL",
                        "",
                    ]
                )
            )
        got = check([r_path], table, headings, quiet=True)
        assert got == 0, f"roxygen: expected exit 0, got {got}"
        print("PASS roxygen: exit 0")
        # A table whose headings drift from the glossary's reds by itself.
        path = os.path.join(tmp, "absent.Rmd")
        got = check([path], table, ["Estimand"], quiet=True)
        assert got == 1, "heading drift was not reported"
        print("PASS heading-drift: exit 1")
    assert slug("Subject level vs. cluster level") == "subject-level-vs.-cluster-level"
    assert slug("Average-unit ICC: `ICC(*,k)`") == "average-unit-icc-icck"
    print("PASS slug: pandoc identifiers")
    print("prose-terms: self-test passed")
    return 0


def main(argv: list[str]) -> int:
    if "--self-test" in argv:
        return self_test()
    files = [a for a in argv if not a.startswith("--")] or DEFAULT_FILES
    return check(files, read_table(), glossary_headings(), quiet="--quiet" in argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
