# M135: Vignette prose pass — the method articles

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M134
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m135-vignette-prose-method-articles`

## Goal

Apply M134's style rules to the five method articles, the ones whose prose is
watched by five separate guards, without moving any pinned claim.

## Scope

Surface tier: **user-facing** — published articles; D-029 carve-out, as M134.

**In:** `vignettes/engines.Rmd`, `vignettes/comparison-with-other-packages.Rmd`,
`vignettes/d-studies-and-replicates.Rmd`, `vignettes/multilevel-designs.Rmd`,
`vignettes/interval-methods.Rmd`, rewritten against rules R1–R6 of
`cairn/doctrine/prose-style.md` (M134).

Baseline at `9eae24d`, measured with the `data-raw/prose-profile.py` that M134
shipped: these five hold 386 sentences, 61 over 35 words, 160 dash occurrences.
`interval-methods.Rmd` is the worst file in the package (119 sentences, 22 over
35 words, 45 dashes) and the only one fenced by four guards:
`tests/testthat/test-vignette-claims.R`, `test-vignette-transcripts.R` (M129
engine transcripts), `test-doc-skew-caveat.R`, `data-raw/check-mpl-doc-claims.py`
(`VIGNETTE = "vignettes/interval-methods.Rmd"`, `check-mpl-doc-claims.py:46`) and
`data-raw/m117-width-pin-mutations.R:330`.

**Out:** the style standard itself → M134 owns it, this milestone only applies
it. Roxygen and `README.Rmd` → M136. Numeric targets for R4/R5 → not gated
(M134 Scope). Any change to what a pinned claim asserts → refused here; a claim
found wrong goes to `/hotfix` or its own milestone, never into a style edit.

## Acceptance criteria

- [ ] AC1 `python3 data-raw/prose-profile.py '<file>' --verbose` run against each
      of the five files named in Scope reports a nonzero sentence count and 0
      dash-as-punctuation occurrences. For `interval-methods.Rmd` it reports at
      most one sentence over 35 words; if one is reported, `--verbose` shows it
      is the sentence carrying the clause `residual_template()` in
      `tests/testthat/test-doc-skew-caveat.R` requires verbatim, which admits no
      sentence break because the test matches it with `fixed = TRUE` and the
      clause begins lower-case with no internal sentence end. For the other four
      it reports 0 sentences over 35 words.
- [ ] AC2 For every hunk of `git diff <base> -- vignettes/` in this milestone
      whose added **or** removed lines match
      `\b(any|each|every|all|only|both|exactly|never|always|full)\b`, the added
      text's claim domain is equal to or narrower than the text it replaced.
- [ ] AC3 `python3 data-raw/check-mpl-doc-claims.py` exits 0 in live mode
      against the edited `interval-methods.Rmd`, and every
      `data-raw/mpl-doc-claims.tsv` row whose key changes carries the edited
      quote verbatim with its `assertion` and `disposition` columns unchanged,
      in the same commit as the prose edit.
- [ ] AC4 `Rscript data-raw/m117-width-pin-mutations.R` exits 0 against the
      edited `interval-methods.Rmd`.
- [ ] AC5 `devtools::test()` clean (including `test-vignette-claims.R`,
      `test-vignette-transcripts.R`, `test-doc-skew-caveat.R`);
      `devtools::check()` raw `Status:` line 0 errors / 0 warnings (NOTEs
      justified); `devtools::document()` no diff;
      `python3 data-raw/check-record-claims.py` exits 0 in live mode.

## Coverage

- AC1 → T1, T2, T3, T4, T5
- AC2 → T6
- AC3 → T5, T7
- AC4 → T5, T7
- AC5 → T8

## Tasks

- [x] T1 Rewrite `vignettes/engines.Rmd` against R1–R6.
- [x] T2 Rewrite `vignettes/comparison-with-other-packages.Rmd` against R1–R6.
- [x] T3 Rewrite `vignettes/d-studies-and-replicates.Rmd` against R1–R6.
- [x] T4 Rewrite `vignettes/multilevel-designs.Rmd` against R1–R6.
- [x] T5 Rewrite `vignettes/interval-methods.Rmd` against R1–R6, holding every
      sentence the four guards quote byte-stable unless T7 re-keys it. Record
      each exempted sentence's word count and its pinned clause's in the work
      log, per the R1/R2 exemption in `cairn/doctrine/prose-style.md`.
- [x] T6 Run the AC2 grep over added and removed diff lines; repair any widening.
- [x] T7 Re-key `data-raw/mpl-doc-claims.tsv` for every quote T5 edited, keeping
      `assertion` and `disposition` unchanged; run both `interval-methods`
      guards live before the commit that carries the prose edit.
- [x] T8 Run the AC5 verify block.

## Work log

- 2026-08-24: T8 verify block — `devtools::test()` FAIL 0 / WARN 3 (expected) / SKIP 2 / PASS 8861; `devtools::check()` `Status: 1 NOTE`, the NOTE being the testthat suite's 23m elapsed time, which is what this suite costs (D-011); `devtools::document()` no diff; `python3 data-raw/check-record-claims.py` 6 claims re-derived, 0 failures.
- 2026-08-24: T8 discovered repair, outside this milestone's Scope and flagged for review: `check-record-claims.py` was already red on `main` before this branch was cut. Its `roadmap-terminal-rows` row still expected `M129\nM130\nM131\nM132\nM133` while the table reads `M134\nM130\nM131\nM132\nM133`, because M134's archive pass rotated the table without rotating the row; the row's prose was staler still, naming M128 and a 2026-08-22 rotation. Corrected in place with the correction marked, per the rule for a record proven false. It is a records edit with no runtime surface, and it sits on this branch rather than the default branch so the merge gate sees it.
- 2026-08-24: T8 open concern for review, not repaired: `R CMD check` reports a `tests/spelling.Rout.save` mismatch — the saved output expects "All Done!" and the run lists ~30 words. Every word listed comes from `icc.Rd`, `NEWS.md`, `glossary.Rmd` or wording this pass did not introduce, so the mismatch predates this branch; it produces no ERROR, WARNING or NOTE, and `Status:` is 1 NOTE.
- 2026-08-24: T5 `interval-methods.Rmd` rewritten — ruler 22 over-35 and 45 dashes down to 1/0 (165 sentences, max 78). The residue is the sentence beginning "What `"burch"` does against `"searle"` depends on what the residual is drawn from": 78 words, carrying the 58-word clause `residual_template()` pins with `fixed = TRUE` (R1/R2 exemption). The three remaining semicolons are two citation separators and one inside that same pinned family's `flat` width template.
- 2026-08-24: T5 kept the width block's three `width_templates()` clauses and the `grid_total` shape "59 of 64 cells of the larger grid" byte-stable, and added `"burch"` to two sentences so the margin statement stays one contiguous width run (`width_expected_runs` = 1); "by level medians" stayed lower-case so `argmax_cut` consumes it rather than `argmax_bare` firing. "A third grid now measures that case here" became "that residual case here" so the residual statement stays one run too.
- 2026-08-24: T5 side effect, disclosed: the width-neighbourhood claim count drops by one (123 → 122 assertions in `test-doc-skew-caveat.R`). The lost item is the `citation` shape "(2013)", which left run #3 when the sentence before the mpl heading was split; no measured figure lost coverage and the anti-vacuity floor (>= 10) holds at 106.
- 2026-08-24: T6 scope-word grep run over the added and removed lines of all five files, case-insensitively (wider than AC2's literal lower-case regex, which misses sentence-initial capitals such as "All three are optional" and "Every coefficient matches"). Every `any`/`each`/`every`/`all`/`only`/`both`/`exactly`/`never`/`always`/`full` is preserved one-for-one; no hunk widens its claim domain, so no repair was needed.
- 2026-08-24: T7 re-keyed three `data-raw/mpl-doc-claims.tsv` rows whose claim sentences changed (`e6451ef204bb`→`3fe46e9bfb3f`, `41e4c69d7afd`→`9613de486205`, `b6b220daac63`→`93240bdb40e9`), quotes verbatim and `assertion`/`disposition` untouched; `e50b57c2c557` was left alone because its sentence is byte-stable. `check-mpl-doc-claims.py`: 47 candidates, 12 settled, 0 failures — the same 47 as before the edit, so no candidate was created or lost.
- 2026-08-24: T7 discovered sub-task (minor amendment): `data-raw/m117-width-pin-mutations.R` carries the article line-anchor "of the larger grid, but how much narrower depends" twice as an insertion point for two mutations; the split moved it to "of the larger grid. How much narrower depends". Re-pointed both. It is a pointer, not a claim; the mutations insert at the same line in the same neighbourhood. Harness exit 0, every prose mutation refused, control clean.
- 2026-08-24: T5 verify — `devtools::test()`: FAIL 0, WARN 3 (expected), SKIP 2, PASS 8861.
- 2026-08-24: amendment (Substantive, AC1, user-selected at a mini gate): AC1 now allows `interval-methods.Rmd` at most one sentence over 35 words — the one carrying the clause `residual_template()` pins verbatim — and names `--verbose`, a nonzero sentence count, and "the other four"; the work-log recording moved from AC1 to T5. The other four files stay at 0/0.
- 2026-08-24: criteria audit of the amended AC1 ran in FULL mode (user-facing tier) via a fresh-context [O] reader that authored none of it. Six findings with one clear right answer each, all applied: the bare command names counts not identities (`--verbose` added); "exactly one" rejected strictly better outcomes ("at most one"); the work-log recording was a recording-act property bound as a criterion (moved to T5); "admits no sentence break" had the sentence as antecedent where only the clause qualifies (re-attached, with the `fixed = TRUE` reason); no anti-vacuity on the zeros (nonzero sentence count added); "in four of them" named no four ("the other four"). One two-sided finding — whether to keep the 58-word clause figure in the criterion — dissolved by the recording fix, which moves both figures to the work log.
- 2026-08-23: created by /milestone-plan.
- 2026-08-23: T4 `multilevel-designs.Rmd` rewritten — ruler 11 over-35 and 33 dashes down to 0/0 (127 sentences, max 34 words). Scope-word grep shows no widening; the 0.431/0.429 Design-2 figures are byte-stable. `devtools::test()`: FAIL 0, PASS 8862.
- 2026-08-23: T3 `d-studies-and-replicates.Rmd` rewritten — ruler 13 over-35 and 28 dashes down to 0/0 (92 sentences, max 33 words). Scope-word grep shows no widening. `devtools::test()`: FAIL 0, PASS 8862.
- 2026-08-23: T2 `comparison-with-other-packages.Rmd` rewritten — ruler 3 over-35 and 30 dashes down to 0/0 (71 sentences, max 33 words); the capability matrix's `—` "not provided" cells became `❌`, which the ruler does not count and which reads against the table's own `✅`. Scope-word grep (case-insensitive, wider than AC2's literal regex) shows no widening. `devtools::test()`: FAIL 0, PASS 8862.
- 2026-08-23: T1 `engines.Rmd` rewritten — ruler 12 over-35 and 24 dashes down to 0/0 (68 sentences, max 31 words); scope-word grep over the added and removed lines shows every `every`/`only`/`full`/`exactly`/`any`/`both` preserved one-for-one. `devtools::test()`: FAIL 0, PASS 8862.
- 2026-08-23: plan-gate criteria audit ran in FULL mode; the record and its 13 findings are in M134's work log — this file's AC2/AC3 carry the F5 and F12 repairs, and its AC5 the F4 live-mode repair.
- 2026-08-23: amendment (Substantive, Scope, user-selected at the implement question gate): the Scope baseline is re-measured at `9eae24d` with the shipped ruler — 386 / 61 / 160 for the five, 119 / 22 / 45 for `interval-methods.Rmd`; the plan's 281 / 88 / 188 came from a draft ruler M134's review then changed.
- 2026-08-23: implement question gate chose to carry `interval-methods.Rmd` in this milestone rather than pre-split it; the plan's split trigger stands.
- 2026-08-23: plan gate chose to fold `interval-methods.Rmd` into this milestone over giving it its own because its four guards are re-run once for the whole file family rather than twice; falsified by T5 plus T7 overrunning a working session, which is the split's trigger.

## Decisions

## Review
