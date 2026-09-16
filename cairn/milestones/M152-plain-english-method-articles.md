# M152: Plain-English pass over the method articles

- **Status:** planned
- **Priority:** normal
- **Depends on:** M151
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — five vignettes that users read.
- **Branch/PR:** —

## Goal

Apply R1 to R8 of `cairn/doctrine/prose-style.md` to `engines.Rmd`, `comparison-with-other-packages.Rmd`, `d-studies-and-replicates.Rmd`, `multilevel-designs.Rmd` and `interval-methods.Rmd`, and reshape `interval-methods.Rmd` so each method section opens in plain words.

## Scope

**In:** the five method articles rewritten under R1 to R8 with the ruler M151 froze. `interval-methods.Rmd` restructured: each method section opens with a paragraph on what the method is for and when to choose it, the figures following. Guard surfaces re-keyed where the rewrite moves them: `data-raw/mpl-doc-claims.tsv`, `tests/testthat/test-doc-skew-caveat.R` templates, `test-vignette-claims.R`, `data-raw/m117-width-pin-mutations.R` anchors. One NEWS Documentation bullet.

**Out:** `NEWS.md` → candidate row; the roxygen surface → M153; dropping or re-deriving any simulation figure → not this milestone, every figure stays (AC4); a mechanical no-widening certificate → "Three prose-apparatus deferrals" candidate row; the `comparison-with-other-packages.Rmd` capability matrix's cell contents → unchanged (M135 settled them).

## Acceptance criteria

- [ ] AC1: `python3 data-raw/prose-profile.py --limit 25` over the five method articles reports 0 dash-as-punctuation in each file, and every sentence it reports over 25 words contains verbatim the clause `residual_template()` in `tests/testthat/test-doc-skew-caveat.R` returns.
- [ ] AC2: For each `term` row of `data-raw/glossary-terms.tsv`, a grep of `pattern` over the prose of each of the five articles (prose as `prose-profile.py` defines it) finds, per article, no occurrence or a first occurrence whose sentence contains the row's `gloss` text verbatim or a link to that heading's anchor.
- [ ] AC3: `grep -E` for the R8 lexical markers `cairn/doctrine/prose-style.md` lists, and for the record-identifier patterns M151 AC4 states, over the five articles' prose returns no match.
- [ ] AC4: Every heading present in `vignettes/interval-methods.Rmd` at the branch base is present at the branch head, and the multiset of numeric literals in the article's prose (prose as `prose-profile.py` defines it, code chunks excluded) at the branch head is a superset of the multiset at the branch base.
- [ ] AC5: `Rscript -e 'devtools::test()'` reports FAIL 0; `python3 data-raw/check-mpl-doc-claims.py` reports 0 failures; each `data-raw/` script `grep -l -- '--self-test' data-raw/*` lists exits 0 under `--self-test`.

## Coverage

- AC1 → T1, T2, T3, T4, T5
- AC2 → T1, T2, T3, T4, T5
- AC3 → T1, T2, T3, T4, T5
- AC4 → T4
- AC5 → T5, T6

## Tasks

- [ ] T1: Rewrite `vignettes/engines.Rmd` and `vignettes/comparison-with-other-packages.Rmd` under R1 to R8; in the comparison article, say in one plain sentence what each compared package is before the matrix.
- [ ] T2: Rewrite `vignettes/d-studies-and-replicates.Rmd`.
- [ ] T3: Rewrite `vignettes/multilevel-designs.Rmd`; define "Design 1/2/3" in plain words where the labels first appear.
- [ ] T4: Restructure and rewrite `vignettes/interval-methods.Rmd`: record the base heading list and the base prose-numeral multiset first, write each method section's plain opening paragraph, then rewrite the rest; re-check both sets against the head.
- [ ] T5: R6 hunk audit per `prose-style.md` step 5 over every hunk of T1 to T4; repair widenings in place; re-key the moved guard surfaces (ledger rows, `width_templates()`/`residual_template()` anchors, `m117` anchors); run `check-mpl-doc-claims.py` and the ruler; add the NEWS bullet.
- [ ] T6: Verify: `devtools::test()`, every `--self-test` checker, `tests/spelling.R`, the AC2 to AC4 greps; check `git status` for `figure/` after any knit.

## Work log

- 2026-09-16: created by /milestone-plan; survey and audit record in M151's work log. Plan gate chose restructuring `interval-methods.Rmd` with plain openings over a sentence-level pass because the survey rates it the worst newcomer read; falsified by a plain opening that recommends a method its section's figures do not support.

## Decisions

## Review
