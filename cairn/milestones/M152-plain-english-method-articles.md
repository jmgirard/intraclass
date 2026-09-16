# M152: Plain-English pass over the method articles

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M151
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — five vignettes that users read.
- **Branch/PR:** `m152-plain-english-method-articles`

## Goal

Apply R1 to R8 of `cairn/doctrine/prose-style.md` to `engines.Rmd`, `comparison-with-other-packages.Rmd`, `d-studies-and-replicates.Rmd`, `multilevel-designs.Rmd` and `interval-methods.Rmd`, and reshape `interval-methods.Rmd` so each method section opens in plain words.

## Scope

**In:** the five method articles rewritten under R1 to R8 with the ruler M151 froze. `interval-methods.Rmd` restructured: each method section opens with a paragraph on what the method is for and when to choose it, the figures following. Guard surfaces re-keyed where the rewrite moves them: `data-raw/mpl-doc-claims.tsv`, `tests/testthat/test-doc-skew-caveat.R` templates, `test-vignette-claims.R`, `data-raw/m117-width-pin-mutations.R` anchors. One NEWS Documentation bullet.

**Out:** `NEWS.md` → candidate row; the roxygen surface → M153; dropping or re-deriving any simulation figure → not this milestone, every figure stays (AC4); a mechanical no-widening certificate → "Three prose-apparatus deferrals" candidate row; the `comparison-with-other-packages.Rmd` capability matrix's cell contents → unchanged (M135 settled them).

## Acceptance criteria

- [ ] AC1: `python3 data-raw/prose-profile.py --limit 25 --verbose` over the five method articles reports a nonzero `sent` count and 0 dash-as-punctuation for each file, and every sentence its listing reports over 25 words contains verbatim one clause `tests/testthat/test-doc-skew-caveat.R` pins (the clause `residual_template()` returns, or one of the three clauses `width_templates()` returns) and has at most 10 words outside that clause, counted as the ruler counts words (whitespace tokens with an alphanumeric character, after its markdown normalization).
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

- [x] T1: Rewrite `vignettes/engines.Rmd` and `vignettes/comparison-with-other-packages.Rmd` under R1 to R8; in the comparison article, say in one plain sentence what each compared package is before the matrix.
- [x] T2: Rewrite `vignettes/d-studies-and-replicates.Rmd`.
- [x] T3: Rewrite `vignettes/multilevel-designs.Rmd`; define "Design 1/2/3" in plain words where the labels first appear.
- [x] T4: Restructure and rewrite `vignettes/interval-methods.Rmd`: record the base heading list and the base prose-numeral multiset first, write each method section's plain opening paragraph, then rewrite the rest; re-check both sets against the head.
- [x] T5: R6 hunk audit per `prose-style.md` step 5 over every hunk of T1 to T4; repair widenings in place; re-key the moved guard surfaces (ledger rows, `width_templates()`/`residual_template()` anchors, `m117` anchors); run `check-mpl-doc-claims.py` and the ruler; add the NEWS bullet.
- [ ] T6: Verify: `devtools::test()`, every `--self-test` checker, `tests/spelling.R`, the AC2 to AC4 greps; check `git status` for `figure/` after any knit.

## Work log

- 2026-09-16: created by /milestone-plan; survey and audit record in M151's work log. Plan gate chose restructuring `interval-methods.Rmd` with plain openings over a sentence-level pass because the survey rates it the worst newcomer read; falsified by a plain opening that recommends a method its section's figures do not support.
- 2026-09-16: implement gate: AC1 amended (substantive) because the suite requires `interval-methods.Rmd` to carry the three `width_templates()` clauses verbatim in one run and the flat clause is 32 words with no sentence break, so the `residual_template()`-only exemption was unsatisfiable; the user adopted M151's AC2 wording with the file set swapped. The "method sections" of the interval-methods restructure are read as the five headed sections that name a `ci_method`; the under-coverage and HPDI subsections are not methods.
- 2026-09-16: re-audit: AC1 (full) — nothing (one observation: the pinned clause strings are fixture-derived and AC1 names no command that prints them).
- 2026-09-16: note: `data-raw/prose-terms.py` slugs headings the pandoc way (`fixed-vs.-random-raters`) while the built site and every article link use pkgdown's `fixed-vs--random-raters`, so a link to such a heading is reported unlinked; the pass glosses those terms in the sentence instead. A tool note for the "Three prose-apparatus deferrals" row at hygiene.
- 2026-09-16: T1 done. `engines.Rmd` 102 sentences, `comparison-with-other-packages.Rmd` 94, both 0 over 25 and 0 dashes; every first term use glossed; the R8 and identifier grep empty. The comparison article now says in one sentence what `psych`, `irr` and `irrICC` are; the prior is glossed in the brms intro so the "The prior" heading is not its first use; "map of intent" became "guide to intent" because the term check reads `MAP` case-blind; a sentence ending in "R." was reworded because the ruler holds back single-letter initials. Code chunks and the pasted `#>` blocks are byte-identical; `test-vignette-claims.R` and `test-vignette-transcripts.R` pass.
- 2026-09-16: T2 done. `d-studies-and-replicates.Rmd` 114 sentences, 0 over 25, 0 dashes; every first term use glossed (the variance-component gloss now opens the article so the D-study gloss can name the components); the two `That is why` markers rewritten; the fixed-rater refusal keeps its bold sentence with the gloss inside it. Code chunks unchanged.
- 2026-09-16: T3 done. `multilevel-designs.Rmd` 165 sentences, 0 over 25, 0 dashes; Design 1 defined in plain words where the label first appears (Designs 2 and 3 already were); the cluster-level, conflated, variance-component, fixed-rater and D-study glosses moved into the intro because their first uses were section headings; `That is why` and `precisely` rewritten; "two occasions to reach for it" became "two reasons" and the D-studies link text shortened, both because the term check reads `occasions`/`replicates` as the glossary term. Code chunks unchanged.
- 2026-09-16: T4 done. Base recorded first: 8 headings, 90 prose numerals. `interval-methods.Rmd` now 243 sentences, 2 over 25 (the `width_templates()` flat clause with 3 words outside it, the `residual_template()` clause with 7), 0 dashes; all 8 headings present and the numeral multiset a superset of the base (one `95` added by the credible-interval gloss). Each of the five `ci_method` sections opens with a plain paragraph on what the method is for and when to choose it; every first term use glossed; `which is why` removed and "not a fixed one" reworded to "not constant". Guard surfaces re-keyed with it: three `mpl-doc-claims.tsv` vignette rows (the fences, opt-in and equal-tailed sentences split), two `m117-width-pin-mutations.R` anchors (`span four`, the residual lead-in), and the parity clause re-wrapped so the `, on the one grid reaching that` anchor stays on one line. `check-mpl-doc-claims.py` and its self-test pass; the mutation script refuses every prose mutation with a clean control; `test-doc-skew-caveat.R`, `test-vignette-claims.R`, `test-vignette-transcripts.R` and `test-ci-mpl.R` pass (2 installed-vignette skips). Code chunks and pasted `#>` blocks unchanged.
- 2026-09-16: T5 done. R6 hunk audit delegated to a fresh-context [O] reader over `git diff main...HEAD` of the five articles: 39 hunks read, 7 findings, all repaired in place. Three were widenings in the new interval-methods openings (the `random` restrictor dropped from the npbootstrap and searle/burch openings, `random` and `absolute-agreement` dropped from the mpl opening); one an invented restatement in engines (the prior "on each variance term", now "on each random-effect standard deviation"); one an invented closure ("The reasons are three", dropped); one a dropped qualifier ("specifically", restored); one a detached grid frame on the parity claim ("on that grid" restored). Guard re-keys were done under T4. NEWS Documentation bullet added. After the repairs: ruler 0 over 25 on four articles and 2 pinned on interval-methods, 0 dashes; `prose-terms.py` clean; R8 and identifier grep empty; AC4 probe passes; `check-mpl-doc-claims.py` 0 failures; mutation script refuses every mutation, control clean; spelling clean ("psychometrics" reworded rather than added to `inst/WORDLIST`); all 11 `--self-test` scripts exit 0.
- 2026-09-16: claim audit: 64 claims read, 1 corrected — NEWS.md. The [O] reader read every added line of `git diff main...HEAD -- . ':!cairn/'` against `R/`, the tests and a live run; the one correction was the NEWS count of over-25-word sentences, since a multilevel-designs sentence holding a quoted question is 27 words to a human reader though the ruler splits it at the question mark; the sentence was split and the reader re-read the claim once, now holding.

## Decisions

## Review
