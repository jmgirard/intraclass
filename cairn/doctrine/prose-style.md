# Doctrine: house prose style for the documentation surfaces

<!-- Budgets: < 120 lines, < 8,000 bytes. Hand-checked with `wc -l -c` at the
     repo's hygiene passes; over either figure, compress or retire content
     here rather than let the module grow. -->

This page owns the writing standard for every surface a user reads: the
vignettes, the roxygen blocks that become `man/`, `README.Rmd`, and `NEWS.md`.
It states eight rules, R1–R8: two measured by a committed ruler, two swept by
a committed term table and a hand-run grep, four judgment at a read-through.

It does not own status, task lists, or the record of which pass applied it —
those live in `cairn/ROADMAP.md` and the milestone files. It does not reach
`cli` condition text in `R/abort.R` and `R/boundary-hint.R`: that surface is
guarded by `data-raw/check-abort-remedy-verdicts.R` and pinned by
rendered-message tests, and stays a ROADMAP candidate row.

## The rules

- **R1 dash-as-punctuation** — no em dash, `---`, or standalone `--` used as a
  sentence-level break. Not counted: YAML front-matter delimiters, markdown
  table separator rows, dashes flanked by digits, and unspaced dashes joining
  two capitalized words (`Spearman--Brown`). That last is a shape, not a part
  of speech: separating `Spearman--Brown` from `An ICC—Intraclass` would need a
  hand-kept proper-noun list, so a sentence-initial capital or an acronym in
  that position goes uncounted too. A spaced dash is counted whatever flanks it.
- **R2 sentence length** — no prose sentence over 25 words (35 before M151;
  the ruler's `--limit` flag names the threshold a pass is measured at).
- **R3 one idea per sentence** — at most one subordinate clause before the main
  verb.
- **R4 parentheticals** — at most one per sentence, none over 15 words
  (judgment, not gated).
- **R5 semicolons** — no semicolon joining clauses that could be two sentences
  (judgment, not gated).
- **R6 meaning is fixed** — a rewrite never widens or narrows a claim's scope
  (M72/M128).
- **R7 plain vocabulary** — each term in `data-raw/glossary-terms.tsv` is
  glossed or linked at its first prose occurrence in each file: the sentence
  of that occurrence carries the row's `gloss` text verbatim, or a link to the
  glossary heading's anchor. A row marked `exempt` is a heading no reader
  meets as a term (the references list, a see-also entry). The table is built
  from the glossary's `## ` headings and is checked by hand with
  `data-raw/prose-terms.py`, never by CI.
- **R8 no mannered construction** — a hand-run `grep -E` over the prose
  sweeps these lexical markers, and a pass reports none: `which is why`,
  `[Tt]hat is why`, `\bprecisely\b`, `the whole rule`, `\bIn short\b`,
  `half the job`, `\bnot (just|only|merely|simply) [^.]*\bbut\b`. That list
  is the sweep's extent, not a claim about mannered prose in general: a
  reader who meets a rhetorical flourish the list does not name repairs it
  under judgment and may add its marker in a later pass. Headings and
  sentences may end in a question mark (M151 gate).

R1 and R2 are gated: `data-raw/prose-profile.py` counts them, and a pass that
claims to have applied them reports zero. The one exemption is a clause a test
pins verbatim and that admits no sentence break: a pass carrying such a clause
records it with the pass, with the clause's word count and the sentence's. R4
and R5 are counted by the same ruler but carry no target: a zero on either has
no non-arbitrary threshold and would fight readability. R3 and R6 are uncounted;
R7 and R8 are swept as stated above.

R6 is the one that can silently break something. A dash spliced into two
sentences, a clause hoisted out of a parenthesis, an "and" turned into a full
stop: each is an opportunity to promise more than the original did. The repair for an overlong
sentence is to *split* it, never to delete the qualifier that bounded it.

## What the ruler counts as prose

`data-raw/prose-profile.py` is the instrument for R1, R2, R4, and R5. It is a
one-shot ruler run by hand, deliberately not wired to CI: a standing CI job over
the repo's own records is records apparatus, which D-021 bars, and D-029's
carve-out covers correcting what the package tells its users, not building
machinery over it.

The script's header states what it strips and what it keeps. Briefly: `.Rmd`
mode drops front matter, HTML comments, code chunks, table separator rows and
list markers, and keeps headings and table cells (one fragment each); `.R` mode
reads roxygen lines outside `@examples`, dropping any `@noRd` block whole. Link
targets and emphasis go, and a code span collapses to one word. A **word** is a
whitespace token with an alphanumeric character; a **sentence** ends at `.`, `!`
or `?` plus whitespace, abbreviations and initials held back. What the ruler
does **not** see is part of the standard too, since a rule the instrument cannot
reach is judgment, not a target: the header lists six known boundaries under
"What the ruler does not see", and widening any is a ruler change priced by the
frozen-ruler rule below.

Run it over a glob; `--verbose` prints every over-limit sentence with its count,
and `--limit N` sets the threshold (default 35; a pass under R2 runs at 25):

    python3 data-raw/prose-profile.py --limit 25 'vignettes/*.Rmd' --verbose
    python3 data-raw/prose-profile.py 'R/*.R'

## Applying a pass

1. Run the ruler with `--limit 25 --verbose` and work the reported sentences;
   run the R8 grep and the R7 term check, and work those hits too.
2. Split, don't compress. Where a sentence carries two ideas, the second
   becomes its own sentence; where a dash stands in for a colon, use the colon;
   where it stands in for a full stop, use the full stop.
3. Read the file through afterwards for R3, R4, and R5 — the ruler cannot see
   a stacked subordinate clause, and its parenthetical and semicolon counts are
   information, not a target.
4. Re-run the ruler and confirm zero on R1 and R2.
5. Audit for R6 over the diff, every hunk, not a grep's selection. A claim's
   scope is carried by a class of construction, not by a list of words: a
   quantifier or absolute (`any`, `every`, `only`, `never`), a restrictive
   clause, an appositive set off by dashes or parentheses, a frame adverbial
   ("on the one-way design"), a conditional, a hedge. Each is droppable by a
   sentence split, and dropping one widens the claim. A word list cannot
   select that class: M136 closed this rule three times against one and was
   defeated three times, each by a shape the list did not name. Per hunk,
   compare the added text's claim domain against the text it replaced; equal
   or narrower passes, wider is a defect repaired in place.

The ruler is frozen for the duration of a pass. Changing what it counts
mid-pass makes the before and after figures incomparable, so a correction to
the ruler restarts the pass's baseline.
