# M153: Plain-English pass over the roxygen surface

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M151
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — the roxygen blocks that become `man/`.
- **Branch/PR:** m153-plain-english-roxygen

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

- AC1 → T1, T2, T3, T4, T6
- AC2 → T1, T2, T3, T4, T6
- AC3 → T1, T2, T3, T4
- AC4 → T4, T5, T6

## Tasks

- [ ] T1: Rewrite the `R/icc.R` roxygen outside `@param ci_method`, `@return` and the Details sections that `mpl-doc-claims.tsv` rows key (list those rows first, by `R/icc.R` line).
- [ ] T2: Rewrite the `@param ci_method`, `@return` and keyed Details sections of `R/icc.R`; re-key each moved `mpl-doc-claims.tsv` row with `assertion` and `disposition` preserved; re-point `width_templates()`/`residual_template()` anchors.
- [ ] T3: Rewrite the roxygen of `R/d-study.R` (remove the `M9` reference at line 66 by stating the open question in plain words), `R/choose-icc.R`, `R/data.R`, `R/autoplot.R`, `R/icc-methods.R`, `R/intraclass-package.R` and `R/reexports.R`.
- [ ] T4: R6 hunk audit per `prose-style.md` step 5 over every hunk of T1 to T3; repair widenings in place; run `devtools::document()`, the ruler, `check-mpl-doc-claims.py`, and the AC2/AC3 greps; add the NEWS bullet.
- [ ] T5: Verify: `devtools::test()`, every `--self-test` checker, `tests/spelling.R`, `devtools::check()` raw Status line read for the spelling NOTE; check `git status` for `Rplots.pdf` after any example run.
- [x] T6: Teach `data-raw/prose-profile.py` that an `@examplesIf` block is an examples block and `data-raw/prose-terms.py` to read an `.R` file in roxygen mode, each with a self-test case planted red on the old tool; re-record the pass baseline.

## Work log

- 2026-09-16: created by /milestone-plan; survey and audit record in M151's work log. Plan gate chose excluding `@noRd` blocks over sweeping every `#'` line because they never render to `man/` and a user-facing promise over them is disproportionate; falsified by a `@noRd` block's text reaching a user through a rendered message.
- 2026-09-16: implement gate: AC1 amended (substantive). `R/icc.R` carries the three `width_templates()` clauses twice, the flat clause 32 words with no sentence break, and `test-occasions-vocabulary.R` pins three help-page sentences of 30 to 35 words verbatim. The user adopted M152's AC1 shape extended to the `expect_says()` patterns. The wording is held for the fresh reader's re-audit before it is written. Two tool fixes accepted as T6, a minor amendment with the task appended: the ruler read an `@examplesIf` block as prose and `prose-terms.py` read an `.R` file as markdown. The `glance.icc()` bullet is split into sentences inside one bullet. The tracking edits tripped the user's `simple-english` lint hook over pre-existing record text. The records were left as they are, since they are append-only or gated sections.
- 2026-09-16: T6 done. Both self-tests pass. The planted `@examplesIf` case counts 2 sentences on the old ruler and 1 on the new. The planted roxygen case exits 1 on the old term checker and 0 on the new. Baseline re-recorded after the ruler change: `R/*.R` 571 sentences, 86 over 25 (87 before, the dropped one being `R/autoplot.R`'s example block), 5 dashes. The eight in-scope files: `R/icc.R` 412/64, `R/d-study.R` 88/16, `R/choose-icc.R` 31/2, `R/data.R` 27/3, `R/autoplot.R` 4/1, `R/icc-methods.R` 6/0, `R/intraclass-package.R` 1/0, `R/reexports.R` 2/0.

## Decisions

## Review
