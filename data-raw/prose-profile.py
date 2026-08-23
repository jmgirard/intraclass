#!/usr/bin/env python3
"""Profile documentation prose against the house style standard.

This is the *ruler* for the prose passes: it counts the two trope classes
`cairn/doctrine/prose-style.md` gates (R1 dash-as-punctuation, R2 sentence
length) plus the two it leaves to judgment (R4 long parentheticals, R5
semicolons), so a pass can be measured rather than asserted.

It is a one-shot ruler, deliberately not wired to CI (cairn D-021 bars a
records-apparatus CI job; D-029's carve-out covers correcting the prose
itself, not standing machinery over it).

Usage
-----
    python3 data-raw/prose-profile.py 'vignettes/*.Rmd'
    python3 data-raw/prose-profile.py 'R/*.R'
    python3 data-raw/prose-profile.py vignettes/glossary.Rmd R/icc.R

Arguments are file paths or shell globs (quoted globs are expanded here, so
the caller does not need the shell to match them).

What counts as prose
--------------------
`.Rmd` mode strips, in order: the YAML front matter, fenced code chunks,
HTML comments, markdown table *rules* (the `|---|---|` separator row), and
list-marker/blockquote prefixes.  Headings and table *cells* stay in: they
are prose the reader reads, so a dash or an overlong clause there counts.
A heading becomes one fragment; a table row becomes one fragment per cell.
Link targets are dropped (`[text](url)` -> `text`), emphasis markers are
dropped, and each inline code span collapses to a single word.

`.R` mode reads only roxygen comment lines (`#'`), and only those outside an
`@examples` block (an `@examples` tag suppresses lines until the next `#' @`
tag).  The `#'` prefix and any leading `@tag` token are stripped; what is
left is run through the same prose pipeline.

The counted classes
-------------------
R1 dash-as-punctuation -- an occurrence of `---`, an em dash, or a
standalone `--`, EXCEPT: dashes flanked with no space by digits on both
sides (numeric and page ranges), and dashes flanked with no space by word
characters whose right-hand side begins with a capital (proper-noun joins
such as `Spearman--Brown`).  YAML delimiters and table rules never reach the
scanner, having been stripped above.

R2 sentence length -- a prose sentence of more than 35 words.  Sentences are
split on `.`/`!`/`?` followed by whitespace, holding back a list of
abbreviations and single-letter initials.  A word is a whitespace-separated
token containing at least one alphanumeric character.

R4 long parentheticals -- a `(...)` span of more than 15 words.

R5 semicolons -- a `;` in prose text.
"""

from __future__ import annotations

import glob
import re
import sys

SENTENCE_LIMIT = 35
PARENTHETICAL_LIMIT = 15

# Abbreviations whose trailing period never ends a sentence.
ABBREVIATIONS = {
    "e.g.",
    "i.e.",
    "cf.",
    "vs.",
    "etc.",
    "al.",
    "eq.",
    "fig.",
    "no.",
    "p.",
    "pp.",
    "ch.",
    "sec.",
    "dr.",
    "prof.",
    "st.",
    "mr.",
    "ms.",
    "mrs.",
}

RE_YAML = re.compile(r"\A---\n.*?\n---\n", re.DOTALL)
RE_HTML_COMMENT = re.compile(r"<!--.*?-->", re.DOTALL)
RE_FENCE = re.compile(r"^\s*(```|~~~)")
RE_HEADING = re.compile(r"^\s*#{1,6}\s+")
RE_TABLE_ROW = re.compile(r"^\s*\|")
RE_TABLE_RULE = re.compile(r"^\s*\|[\s:|-]*\|\s*$")
RE_LIST_MARKER = re.compile(r"^\s*(?:[-*+]\s+|\d+[.)]\s+)")
RE_BLOCKQUOTE = re.compile(r"^\s*>+\s?")
RE_LINK = re.compile(r"\[([^\]]*)\]\([^)]*\)")
RE_IMAGE = re.compile(r"!\[([^\]]*)\]\([^)]*\)")
RE_AUTOLINK = re.compile(r"<https?://[^>]*>")
RE_CODE_SPAN = re.compile(r"`[^`]*`")
RE_EMPHASIS = re.compile(r"(\*\*|\*|__|_)")
RE_ROXYGEN = re.compile(r"^\s*#'\s?")
RE_ROXYGEN_TAG = re.compile(r"^\s*@(\w+)")
RE_PARENTHETICAL = re.compile(r"\([^()]*\)")

# Longest-first so `---` is never scanned as `--` plus a stray `-`.
RE_DASH = re.compile(r"---|—|--")
RE_SENTENCE_BREAK = re.compile(r"(?<=[.!?])[\"')\]]*\s+")


def strip_rmd(text: str) -> str:
    """Return the prose of an `.Rmd` file: chunks, YAML, and tables removed."""
    text = RE_YAML.sub("", text)
    text = RE_HTML_COMMENT.sub("", text)
    kept: list[str] = []
    in_fence = False
    for line in text.split("\n"):
        if RE_FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if RE_TABLE_RULE.match(line):
            continue
        if RE_HEADING.match(line):
            # A heading is one fragment, fenced off from its neighbours.
            kept.extend(["", RE_HEADING.sub("", line), ""])
            continue
        if RE_TABLE_ROW.match(line):
            # One fragment per cell, so a long cell is a long "sentence".
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            kept.extend(["", ". ".join(c for c in cells if c), ""])
            continue
        kept.append(line)
    return "\n".join(kept)


def strip_roxygen(text: str) -> str:
    """Return the roxygen prose of an `.R` file, minus every `@examples` block."""
    kept: list[str] = []
    in_examples = False
    for line in text.split("\n"):
        if not RE_ROXYGEN.match(line):
            in_examples = False
            continue
        body = RE_ROXYGEN.sub("", line)
        tag = RE_ROXYGEN_TAG.match(body)
        if tag is not None:
            in_examples = tag.group(1) == "examples"
            if in_examples:
                continue
            body = body[tag.end() :].lstrip()
        if in_examples:
            continue
        kept.append(body)
    return "\n".join(kept)


def normalize(text: str) -> str:
    """Drop markdown decoration so word counts measure prose, not markup."""
    text = RE_IMAGE.sub(r"\1", text)
    text = RE_LINK.sub(r"\1", text)
    text = RE_AUTOLINK.sub("url", text)
    text = RE_CODE_SPAN.sub("code", text)
    text = RE_EMPHASIS.sub("", text)
    return text


def paragraphs(text: str) -> list[str]:
    """Split prose into blank-line-separated paragraphs, one line of text each."""
    out: list[str] = []
    buf: list[str] = []
    for raw in text.split("\n"):
        line = RE_BLOCKQUOTE.sub("", raw)
        line = RE_LIST_MARKER.sub("", line)
        if line.strip() == "":
            if buf:
                out.append(" ".join(buf))
                buf = []
            continue
        buf.append(line.strip())
    if buf:
        out.append(" ".join(buf))
    return out


def words(text: str) -> list[str]:
    """Whitespace tokens carrying at least one alphanumeric character."""
    return [tok for tok in text.split() if any(ch.isalnum() for ch in tok)]


def ends_sentence(chunk: str) -> bool:
    """False when a break candidate follows an abbreviation or an initial."""
    tail = chunk.split()[-1] if chunk.split() else ""
    tail = tail.strip("\"')]")
    if tail.lower() in ABBREVIATIONS:
        return False
    # A single capital letter plus a period is an initial ("A. Author").
    if re.fullmatch(r"[A-Z]\.", tail):
        return False
    return True


def sentences(paragraph: str) -> list[str]:
    """Split a paragraph into sentences, holding abbreviations together."""
    pieces = RE_SENTENCE_BREAK.split(paragraph)
    out: list[str] = []
    pending = ""
    for piece in pieces:
        candidate = (pending + " " + piece).strip() if pending else piece
        if ends_sentence(candidate):
            out.append(candidate)
            pending = ""
        else:
            pending = candidate
    if pending:
        out.append(pending)
    return [s for s in out if words(s)]


def left_word(text: str, end: int) -> str:
    """The unbroken alphanumeric run ending at `end` (exclusive), or ``""``."""
    start = end
    while start > 0 and text[start - 1].isalnum():
        start -= 1
    return text[start:end]


def count_dashes(text: str) -> int:
    """R1's counted class: dashes standing in for sentence-level punctuation."""
    total = 0
    for match in RE_DASH.finditer(text):
        before = text[match.start() - 1] if match.start() > 0 else ""
        after = text[match.end()] if match.end() < len(text) else ""
        if before.isdigit() and after.isdigit():
            continue  # numeric or page range
        # A proper-noun join is capitalized on BOTH sides (Spearman--Brown).
        # Testing only the right side would excuse `sentence---And`, which is
        # the ordinary unspaced form of the break R1 bans.
        left = left_word(text, match.start())
        if left[:1].isupper() and after.isalnum() and after.isupper():
            continue  # proper-noun join (Spearman--Brown)
        total += 1
    return total


class Profile:
    """Counts for one file, or for a run of files."""

    def __init__(self) -> None:
        self.sentences = 0
        self.long_sentences = 0
        self.dashes = 0
        self.long_parentheticals = 0
        self.semicolons = 0
        self.worst = 0

    def add(self, other: "Profile") -> None:
        self.sentences += other.sentences
        self.long_sentences += other.long_sentences
        self.dashes += other.dashes
        self.long_parentheticals += other.long_parentheticals
        self.semicolons += other.semicolons
        self.worst = max(self.worst, other.worst)


def profile_text(prose: str, verbose: bool, label: str) -> Profile:
    prof = Profile()
    for para in paragraphs(prose):
        para = normalize(para)
        prof.dashes += count_dashes(para)
        prof.semicolons += para.count(";")
        for span in RE_PARENTHETICAL.findall(para):
            if len(words(span)) > PARENTHETICAL_LIMIT:
                prof.long_parentheticals += 1
        for sentence in sentences(para):
            n = len(words(sentence))
            prof.sentences += 1
            prof.worst = max(prof.worst, n)
            if n > SENTENCE_LIMIT:
                prof.long_sentences += 1
                if verbose:
                    print(f"  {label}: {n} words: {sentence[:110]}")
    return prof


def profile_file(path: str, verbose: bool) -> Profile:
    with open(path, encoding="utf-8") as handle:
        raw = handle.read()
    if path.endswith((".Rmd", ".md", ".rmd")):
        prose = strip_rmd(raw)
    elif path.endswith((".R", ".r")):
        prose = strip_roxygen(raw)
    else:
        raise SystemExit(f"prose-profile: unsupported file type: {path}")
    return profile_text(prose, verbose, path)


def expand(patterns: list[str]) -> list[str]:
    paths: list[str] = []
    for pattern in patterns:
        hits = sorted(glob.glob(pattern))
        if not hits:
            raise SystemExit(f"prose-profile: no file matches {pattern!r}")
        paths.extend(hits)
    return paths


def main(argv: list[str]) -> int:
    verbose = "--verbose" in argv
    patterns = [a for a in argv if not a.startswith("--")]
    if not patterns:
        raise SystemExit(__doc__)
    paths = expand(patterns)
    total = Profile()
    header = f"{'file':<44}{'sent':>6}{'>35':>6}{'dash':>6}{'paren':>7}{'semi':>6}{'max':>6}"
    print(header)
    print("-" * len(header))
    for path in paths:
        prof = profile_file(path, verbose)
        total.add(prof)
        print(
            f"{path:<44}{prof.sentences:>6}{prof.long_sentences:>6}"
            f"{prof.dashes:>6}{prof.long_parentheticals:>7}"
            f"{prof.semicolons:>6}{prof.worst:>6}"
        )
    print("-" * len(header))
    print(
        f"{'TOTAL':<44}{total.sentences:>6}{total.long_sentences:>6}"
        f"{total.dashes:>6}{total.long_parentheticals:>7}"
        f"{total.semicolons:>6}{total.worst:>6}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
