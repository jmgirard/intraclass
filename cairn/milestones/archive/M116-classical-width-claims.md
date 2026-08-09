# M116: Correct the falsified `"searle"`/`"burch"` width claims

**Status:** done (2026-08-09, PR #125 https://github.com/jmgirard/intraclass/pull/125)

**Goal:** Replace the shipped claim that `"burch"` is wider than `"searle"` — falsified by both committed classical grids and contradicted by Burch (2011) — with a bounded statement of what the package measured.

**Outcome:** The width ranking is withdrawn from all six user-facing sites (`?icc`/`man/icc.Rd`, both vignettes, `NEWS.md`, `boundary_fenced_hint()`'s runtime blurb, the `R/ci-classical.R` header) and replaced with the measured direction — burch narrower in 16/16 M76 and 59/64 M113 cells, median ratios 0.9430 and 0.9614, no family reversing on its median — bounded by the subject-effect-only DGP and by Burch's own symmetric-leptokurtic reversal, which neither grid tests.
New `data-raw/m116-classical-width-comparison.R` + `.tsv` recompute it from the two committed fixtures behind an AST fence over both sweep scripts' generators.
`cairn/references/searle1971.md` is added (the interval is Ch. 9 §9d / Table 9.14 / eq. 60, with no length claim anywhere in Ch. 9); `burch2011.md` gains the §3/§5 expected-length section and `mcgraw1996.md` records the same absence; the `Searle 1971 eq. 4/6` citation is corrected, those being ohyama's equation numbers.
`test-doc-skew-caveat.R` grows from one claim pattern to six, each mutation-verified.

**Decisions:** D-012 Amendment 1 — two of D-012's width clauses are wrong against its own sweep, corrected with the GO/NO-GO verdict untouched.
D-029 — D-021's door governs records-verification apparatus, not corrections to what the package tells its users.

**Review:** Two passes, 38 findings, five actioned. Pass 1 returned on AC4: the vignette named gaussian, t5 and chisq1 as non-reversing while five cells in exactly those families reverse (F2, 90), plus a pooled "about 4%" figure (F1, 85) and a `skip_if()` aborting a whole `test_that` (F19, 80).
Pass 2 actioned B2 (82), restoring Burch's "symmetric" qualifier at three sites. Defect returns: 1.
Graduated to a ROADMAP candidate: burch's width edge is not flat in the true ICC.
