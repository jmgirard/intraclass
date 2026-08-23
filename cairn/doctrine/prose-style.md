# Doctrine: house prose style for the documentation surfaces

<!-- Budgets: < 120 lines, < 8,000 bytes. Hand-checked with `wc -l -c` at the
     repo's hygiene passes; over either figure, compress or retire content
     here rather than let the module grow. -->

This page owns the writing standard for every surface a user reads: the
vignettes, the roxygen blocks that become `man/`, and `README.Rmd`. It states
six rules, R1–R6. Two of them are measured by a committed ruler; the other four
are judgment the writer applies at a read-through.

It does not own status, task lists, or the record of which pass applied it —
those live in `cairn/ROADMAP.md` and the milestone files. It does not reach
`cli` condition text in `R/abort.R` and `R/boundary-hint.R`: that surface is
guarded by `data-raw/check-abort-remedy-verdicts.R` and pinned by
rendered-message tests, and stays a ROADMAP candidate row.

## The rules

- **R1 dash-as-punctuation** — no em dash, `---`, or standalone `--` used as a
  sentence-level break. Not counted: YAML front-matter delimiters, markdown
  table separator rows, dashes flanked by digits (page and numeric ranges), and
  unspaced dashes joining two capitalized words (`Spearman--Brown`). That last
  exclusion is a shape, not a part of speech: the ruler does not separate
  `Spearman--Brown` from `An ICC—Intraclass`, and separating them would need a
  hand-kept list of proper nouns. A capital that follows a capitalized word is
  indistinguishable from a proper-noun join, so a sentence-initial capital or an
  acronym in that position goes uncounted with the proper nouns. A dash with a
  space on either side is counted whatever flanks it.
- **R2 sentence length** — no prose sentence over 35 words.
- **R3 one idea per sentence** — at most one subordinate clause before the main
  verb.
- **R4 parentheticals** — at most one per sentence, none over 15 words
  (judgment, not gated).
- **R5 semicolons** — no semicolon joining clauses that could be two sentences
  (judgment, not gated).
- **R6 meaning is fixed** — a rewrite never widens or narrows a claim's scope
  (M72/M128).

R1 and R2 are gated: `data-raw/prose-profile.py` counts them, and a pass that
claims to have applied them reports zero. R4 and R5 are counted by the same
ruler but carry no target — a zero on either has no non-arbitrary threshold and
would fight readability. R3 and R6 are not counted at all.

R6 is the one that can silently break something. A dash spliced into two
sentences, a clause hoisted out of a parenthesis, an "and" turned into a full
stop — each is an opportunity to promise more than the original did. The repair
for an overlong sentence is to *split* it, never to compress it by deleting the
qualifier that bounded it.

## What the ruler counts as prose

`data-raw/prose-profile.py` is the instrument for R1, R2, R4, and R5. It is a
one-shot ruler run by hand, deliberately not wired to CI: a standing CI job over
the repo's own records is records apparatus, which D-021 bars, and D-029's
carve-out covers correcting what the package tells its users, not building
machinery over it.

In `.Rmd` mode it drops, in order: the YAML front matter, HTML comments, fenced
code chunks, markdown table *rules* (the `|---|---|` separator row), and
list-marker and blockquote prefixes. Headings and table *cells* stay in — they
are prose the reader reads, so a dash or an overlong clause in one counts. A
heading becomes one fragment; a table row becomes one fragment per cell. Link
targets are dropped (`[text](url)` becomes `text`), emphasis markers are
dropped, and each inline code span collapses to a single word.

In `.R` mode it reads only roxygen comment lines (`#'`), and only those outside
an `@examples` block: an `@examples` tag suppresses lines until the next `#' @`
tag. The `#'` prefix and any leading `@tag` token are stripped, and what is left
runs through the same pipeline.

What the ruler does **not** see is as much part of the standard as what it
does, since a rule the instrument cannot reach is judgment, not a target. Four
boundaries, none of them reached by any vignette in this repo today: a table
separator row is recognized only when it starts with `|`, so a pandoc-legal
`---- | ----` row scores as dashes; a `---` alone on a line below the front
matter is counted, since nothing distinguishes it from a spaced break; a run of
list items is joined into one fragment rather than one fragment per item, so a
long unpunctuated list under-reports both its fragment count and its sentence
lengths; and HTML comments are stripped before fences, so a chunk containing the
string `<!--` swallows the prose up to the next real comment. Widening any of
these is a ruler change, which the frozen-ruler rule below prices.

A **word** is a whitespace-separated token carrying at least one alphanumeric
character. A **sentence** is a span ending in `.`, `!`, or `?` followed by
whitespace, with a held-back list of abbreviations (`e.g.`, `i.e.`, `cf.`,
`al.`, `p.`, and the rest in the script) and single-letter initials that never
end one.

Run it over a glob, and add `--verbose` to have every over-35-word sentence
printed with its count:

    python3 data-raw/prose-profile.py 'vignettes/*.Rmd' --verbose
    python3 data-raw/prose-profile.py 'R/*.R'

## Applying a pass

1. Run the ruler with `--verbose` and work the reported sentences.
2. Split, don't compress. Where a sentence carries two ideas, the second
   becomes its own sentence; where a dash stands in for a colon, use the colon;
   where it stands in for a full stop, use the full stop.
3. Read the file through afterwards for R3, R4, and R5 — the ruler cannot see
   a stacked subordinate clause, and its parenthetical and semicolon counts are
   information, not a target.
4. Re-run the ruler and confirm zero on R1 and R2.
5. Audit for R6 over the diff. Grep both added **and** removed lines for the
   scope words — `any`, `each`, `every`, `all`, `only`, `both`, `exactly`,
   `never`, `always`, `full` — because a deleted qualifier widens a claim just
   as surely as an added absolute does. For each hunk the grep returns, compare
   the added text's claim domain against the text it replaced; equal or
   narrower passes, wider is a defect repaired in place.

The ruler is frozen for the duration of a pass. Changing what it counts
mid-pass makes the before and after figures incomparable, so a correction to
the ruler restarts the pass's baseline.
