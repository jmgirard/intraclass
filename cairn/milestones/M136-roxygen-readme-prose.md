# M136: Roxygen and README prose pass

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M134
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m136-roxygen-readme-prose`

## Goal

Apply M134's style rules to every roxygen block and to `README.Rmd`, and make
`?icc`'s `design` blurb name the same occasions the multilevel article does.

## Scope

Surface tier: **user-facing** — `?icc` and the GitHub landing page; D-029
carve-out, as M134.

**In:** every `#'` line outside `@examples` under `R/*.R`, and `README.Rmd`,
rewritten against rules R1–R6 of `cairn/doctrine/prose-style.md` (M134). R1 and
R2 are gated by the ruler (AC1); R6 is certified over the census's domain only
(AC3); R3–R5 are the doctrine's step-3 read-through, recorded in the work log.
The baseline is what `python3 data-raw/prose-profile.py` reports over those two
arguments at `$(git merge-base main HEAD)`, extracted with `git archive`.

Also in: the standing candidate row from the M132 review ([O] finding 3) — the
`@param design` blurb (`R/icc.R:243-249`) names one occasion for declaring a
design, missing cells making the pattern ambiguous, while
`vignettes/multilevel-designs.Rmd:112-117` names two. The article is the
authoritative surface; the blurb adopts its pair:

1. the rater *labels* do not mean what the crossing pattern implies (a complete
   table whose rater labels repeat across clusters), and
2. missing cells leave the pattern genuinely ambiguous between crossed and nested.

That edit changes meaning by design, so its hunk is named in AC4 and exempt
from AC3.

`data-raw/check-mpl-doc-claims.py` scopes `R/icc.R`, `NEWS.md` and
`interval-methods.Rmd`, and 45 of the 54 `data-raw/mpl-doc-claims.tsv` rows
quote `R/icc.R` — a roxygen edit re-keys them (M130 lesson).

**Out:** vignettes → M134, M135. `cli` abort and hint strings in `R/abort.R`
and `R/boundary-hint.R` → stay a candidate row: same D-029 class, but they are
condition text with their own guard
(`data-raw/check-abort-remedy-verdicts.R`) and their own pinned renderings
(M93, M127), so they want their own gate. `@examples` code → untouched.

## Acceptance criteria

- [ ] AC1 `python3 data-raw/prose-profile.py 'R/*.R'` reports 0
      dash-as-punctuation occurrences in its TOTAL row, a nonzero sentence
      count in its `R/icc.R` row, and 0 sentences over 35 words in every other
      row. The same command over `README.Rmd` reports 0 dashes, a nonzero
      sentence count, and 0 sentences over 35 words. For `R/icc.R` the count of
      sentences over 35 words equals the count of its `#'` sentences outside
      `@examples` that contain, verbatim, the clause `residual_template()`
      returns. Such a clause admits no sentence break:
      `tests/testthat/test-doc-skew-caveat.R` matches it with `fixed = TRUE`,
      and it begins lower-case with no internal sentence end.
- [ ] AC2 `python3 data-raw/check-mpl-doc-claims.py` exits 0 in live mode
      against the edited `R/icc.R`, and every `data-raw/mpl-doc-claims.tsv` row
      whose key changes carries the edited quote verbatim with its `assertion`
      and `disposition` columns unchanged, in the same commit as the edit.
- [ ] AC3 Census: over `git diff -U0 $(git merge-base main HEAD)...HEAD -- R/
      README.Rmd`, attribute each content line (`^[+-][^+-]`) to the `^@@` hunk
      above it, and select a hunk when any of its content lines matches
      `grep -iE '\b(any|each|every|all|only|both|exactly|never|always|full)\b'`.
      Widen each selected hunk to its smallest enclosing paragraph — for
      roxygen, the run of `#'` lines bounded by a blank `#'` line or the next
      `@tag`; for `README.Rmd`, the blank-line paragraph — reporting any
      selected hunk lying in neither for hand adjudication. The census selects
      at least one hunk in `R/icc.R` and at least one in `README.Rmd`, and in
      every widened unit it selects other than the one holding `@param design`
      (AC4 governs that): where the unit has removed lines, its added text
      states a claim whose domain is equal to or narrower than the removed
      text; where it has none, the added text either repeats a claim the
      unchanged lines of that same unit already state, or contains verbatim a
      clause `residual_template()` or `width_templates()` returns. The census
      decides nothing about a claim-domain change carrying none of those ten
      words.
- [ ] AC4 The rendered `man/icc.Rd` `design` argument entry names both
      occasions listed in Scope, in the article's terms.
- [ ] AC5 `Rscript -e 'devtools::build_readme()'` followed by
      `git diff --exit-code README.md` is clean.
- [ ] AC6 `devtools::test()` clean; `devtools::check()` raw `Status:` line 0
      errors / 0 warnings (NOTEs justified); `devtools::document()` no diff;
      `python3 data-raw/check-record-claims.py` exits 0 in live mode.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T4
- AC3 → T5
- AC4 → T2
- AC5 → T6
- AC6 → T6

## Tasks

- [ ] T1 Rewrite the `#'` blocks in `R/icc.R` against R1–R6 (668 lines, the bulk
      of the surface; `@examples` untouched).
- [ ] T2 Rewrite the `#'` blocks in the remaining `R/*.R` files against R1–R6,
      and rewrite `@param design` to name both Scope occasions.
- [x] T3 Rewrite `README.Rmd` against R1–R6.
- [ ] T4 Re-key `data-raw/mpl-doc-claims.tsv` for every quote T1 edited, keeping
      `assertion` and `disposition` unchanged; run the checker live before the
      commit carrying the roxygen edit.
- [ ] T5 Run the AC3 census; repair any widening outside the `@param design`
      unit. Record the total hunk count, the selected count and the
      hand-adjudicated count, and the exempt clause's word count beside each
      carrying sentence's. Probe twice, reverting each: plant a 40-word
      non-clause sentence in `R/icc.R` roxygen and confirm the over-35 count
      rises; delete one bounding qualifier from one roxygen sentence and
      confirm the census selects that hunk.
- [ ] T6 `devtools::document()`, `devtools::build_readme()`, then the AC6 verify
      block; drop the stray `Rplots.pdf` if an example run leaves one (M131).

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan-gate criteria audit ran in FULL mode; the record and its 13 findings are in M134's work log — this file carries the F2 (glob over hand-list), F3 (live MPL checker AC), F11 (design occasions listed, hunk exempted) and F13 (`git diff --exit-code`) repairs.
- 2026-08-23: plan gate chose to absorb the M132-review `@param design` candidate over leaving it on the ROADMAP because that row's own promotion trigger is "the next pass over `?icc`'s multilevel prose", which this is; falsified by the alignment edit widening a claim AC3 would otherwise have caught.
- 2026-08-24: amendment return: AC1 — "the count of sentences over 35 words equals the count of its `#'` sentences outside `@examples` that contain, verbatim, the clause `residual_template()` returns"; AC3 rewritten as a hunk-attributed census widened to the smallest enclosing paragraph; Scope In and T5 amended with it. Accepted at the mini gate 2026-08-24.
- 2026-08-24: two fresh-context [O] criteria audits ran in FULL mode over the amended wording (9 findings, then 12 after repair); all disposed. Decisive ones: AC1 as planned was unsatisfiable (`R/icc.R` must carry the 58-word `residual_template()` clause twice, unsplittable under `fixed = TRUE`); `--verbose` truncates at 110 chars so it cannot exhibit that clause; `R/icc.R`'s roxygen is one 687-line block, so "enclosing roxygen block" was degenerate.
- 2026-08-24: plan gate chose the paragraph-widened census with pure additions certified over M135's added-vs-removed-only shape, because a pure addition is where a new absolute enters a user-facing page; falsified by the added-only branch proving unadjudicable in practice.
- 2026-08-24: T2 part 1: roxygen in `R/abort.R`, `R/choose-icc.R`, `R/d-study.R`, `R/data.R` rewritten; ruler 0 over-35 and 0 dashes on every `R/*.R` file but `R/icc.R`. `@param design` (in `R/icc.R`) still to do.
- 2026-08-24: T3 README.Rmd rewritten; ruler 65 sentences, 0 over-35, 0 dashes (was 40/4/22). `build_readme()` re-knitted README.md.
- 2026-08-23: plan gate chose to leave the `cli` abort and hint strings out over folding them in because they are condition text with pinned renderings (M93, M127) and a separate guard, not documentation prose; falsified by a user reporting an abort remedy as unreadable in the same way the docs were.

## Decisions

## Review
