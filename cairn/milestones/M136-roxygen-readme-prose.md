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

**In:** every `#'` block under `R/*.R` (1053 lines at `72f9cc2`, 668 of them in
`R/icc.R`) and `README.Rmd` (25 sentences, 6 over 35 words, 30 dashes),
rewritten against rules R1–R6 of `cairn/doctrine/prose-style.md` (M134).

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
      dash-as-punctuation occurrences and 0 sentences over 35 words across the
      `#'` lines outside `@examples`, and the same for `README.Rmd`.
- [ ] AC2 `python3 data-raw/check-mpl-doc-claims.py` exits 0 in live mode
      against the edited `R/icc.R`, and every `data-raw/mpl-doc-claims.tsv` row
      whose key changes carries the edited quote verbatim with its `assertion`
      and `disposition` columns unchanged, in the same commit as the edit.
- [ ] AC3 For every hunk of `git diff <base> -- R/ README.Rmd` in this
      milestone whose added **or** removed lines match
      `\b(any|each|every|all|only|both|exactly|never|always|full)\b`, other than
      the `@param design` hunk AC4 governs, the added text's claim domain is
      equal to or narrower than the text it replaced.
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
- [ ] T3 Rewrite `README.Rmd` against R1–R6.
- [ ] T4 Re-key `data-raw/mpl-doc-claims.tsv` for every quote T1 edited, keeping
      `assertion` and `disposition` unchanged; run the checker live before the
      commit carrying the roxygen edit.
- [ ] T5 Run the AC3 grep over added and removed diff lines; repair any widening
      outside the `@param design` hunk.
- [ ] T6 `devtools::document()`, `devtools::build_readme()`, then the AC6 verify
      block; drop the stray `Rplots.pdf` if an example run leaves one (M131).

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan-gate criteria audit ran in FULL mode; the record and its 13 findings are in M134's work log — this file carries the F2 (glob over hand-list), F3 (live MPL checker AC), F11 (design occasions listed, hunk exempted) and F13 (`git diff --exit-code`) repairs.
- 2026-08-23: plan gate chose to absorb the M132-review `@param design` candidate over leaving it on the ROADMAP because that row's own promotion trigger is "the next pass over `?icc`'s multilevel prose", which this is; falsified by the alignment edit widening a claim AC3 would otherwise have caught.
- 2026-08-23: plan gate chose to leave the `cli` abort and hint strings out over folding them in because they are condition text with pinned renderings (M93, M127) and a separate guard, not documentation prose; falsified by a user reporting an abort remedy as unreadable in the same way the docs were.

## Decisions

## Review
