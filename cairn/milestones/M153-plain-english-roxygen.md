# M153: Plain-English pass over the roxygen surface

- **Status:** planned
- **Priority:** normal
- **Depends on:** M151
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — the roxygen blocks that become `man/`.
- **Branch/PR:** —

## Goal

Apply R1 to R8 of `cairn/doctrine/prose-style.md` to every `#'` line outside `@examples` and outside `@noRd` blocks under `R/*.R`.

## Scope

**In:** the roxygen prose of `R/icc.R`, `R/d-study.R`, `R/choose-icc.R`, `R/data.R`, `R/autoplot.R`, `R/icc-methods.R`, `R/intraclass-package.R` and `R/reexports.R` rewritten under R1 to R8 with the ruler M151 froze. `R/abort.R`'s `@noRd` blocks are internal and out. The `?d_study` ticket-id leak (`R/d-study.R:66`) removed. `data-raw/mpl-doc-claims.tsv` re-keyed where the rewrite moves its `R/icc.R` rows, and `test-doc-skew-caveat.R` templates re-pointed. `man/` regenerated. One NEWS Documentation bullet.

**Out:** `cli` abort and hint strings → existing candidate row; `NEWS.md` → candidate row; a mechanical no-widening certificate → "Three prose-apparatus deferrals" candidate row; changing what any function computes or returns → nothing here touches code outside `#'` lines.

## Acceptance criteria

- [ ] AC1: `python3 data-raw/prose-profile.py --limit 25 'R/*.R'` reports 0 dash-as-punctuation in each file, and every sentence it reports over 25 words contains verbatim the clause `residual_template()` in `tests/testthat/test-doc-skew-caveat.R` returns.
- [ ] AC2: For each `term` row of `data-raw/glossary-terms.tsv`, a grep of `pattern` over the roxygen prose of each `R/*.R` file (prose as `prose-profile.py` defines it, `@noRd` blocks excluded) finds, per file, no occurrence or a first occurrence whose sentence contains the row's `gloss` text verbatim or a link to that glossary heading's anchor.
- [ ] AC3: `grep -E` for the R8 lexical markers `cairn/doctrine/prose-style.md` lists, and for the record-identifier patterns M151 AC4 states, over the roxygen prose of `R/*.R` outside `@noRd` blocks returns no match.
- [ ] AC4: `Rscript -e 'devtools::document()'` leaves no uncommitted diff under `man/` at the branch head; `Rscript -e 'devtools::test()'` reports FAIL 0; `python3 data-raw/check-mpl-doc-claims.py` reports 0 failures; each `data-raw/` script `grep -l -- '--self-test' data-raw/*` lists exits 0 under `--self-test`.

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T1, T2, T3, T4
- AC3 → T1, T2, T3, T4
- AC4 → T4, T5

## Tasks

- [ ] T1: Rewrite the `R/icc.R` roxygen outside `@param ci_method`, `@return` and the Details sections that `mpl-doc-claims.tsv` rows key (list those rows first, by `R/icc.R` line).
- [ ] T2: Rewrite the `@param ci_method`, `@return` and keyed Details sections of `R/icc.R`; re-key each moved `mpl-doc-claims.tsv` row with `assertion` and `disposition` preserved; re-point `width_templates()`/`residual_template()` anchors.
- [ ] T3: Rewrite the roxygen of `R/d-study.R` (remove the `M9` reference at line 66 by stating the open question in plain words), `R/choose-icc.R`, `R/data.R`, `R/autoplot.R`, `R/icc-methods.R`, `R/intraclass-package.R` and `R/reexports.R`.
- [ ] T4: R6 hunk audit per `prose-style.md` step 5 over every hunk of T1 to T3; repair widenings in place; run `devtools::document()`, the ruler, `check-mpl-doc-claims.py`, and the AC2/AC3 greps; add the NEWS bullet.
- [ ] T5: Verify: `devtools::test()`, every `--self-test` checker, `tests/spelling.R`, `devtools::check()` raw Status line read for the spelling NOTE; check `git status` for `Rplots.pdf` after any example run.

## Work log

- 2026-09-16: created by /milestone-plan; survey and audit record in M151's work log. Plan gate chose excluding `@noRd` blocks over sweeping every `#'` line because they never render to `man/` and a user-facing promise over them is disproportionate; falsified by a `@noRd` block's text reaching a user through a rendered message.

## Decisions

## Review
