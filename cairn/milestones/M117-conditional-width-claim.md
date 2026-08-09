# M117: State the `"burch"`/`"searle"` width relationship conditionally

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP1, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m117-conditional-width-claim · https://github.com/jmgirard/intraclass/pull/126   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal

Replace the pooled "about 6% / about 4% narrower" width figure with the
conditional statement the committed grids actually support — the advantage
shrinks in the true ICC and in the subject count, reaching parity near ρ = 0.6.

## Scope

**In:** the per-factor breakdown of `data-raw/m116-classical-width-comparison.tsv`
(ρ and subject count, per grid, from the committed per-cell rows); rewriting the
width statement at every doc surface a widened sweep reports as carrying one;
widening `test-doc-skew-caveat.R`'s two surface legs from six hand-listed paths
to a directory walk; recomputed (not transcribed) pins for every figure stated;
the ledger re-triage the changed sentences force.

**Out:** re-running either sweep or adding cells — the fixture is sufficient and
its sources are committed. A rater-count width claim → left unstated (the
marginal contrast is confounded; the milestone records why). Burch's untested
leptokurtic reversal → ROADMAP candidate (both-components-non-normal grid).
Extending the skew battery to the other `ci_method` values → ROADMAP candidate.
A new doc-claim checker → barred by D-029; this extends the M115 instrument.

## Acceptance criteria

- [ ] AC1 The generator emits one summary row per (grid, factor, level) for
      factor ∈ {ρ, subject count `k`}, by the same width-ratio arithmetic as
      the per-cell rows, and the `.tsv` is regenerated to carry them. Each new
      `stopifnot` pin is mutation-verified against a perturbation large enough
      to change the sentence the prose states — including, at every level whose
      median lies within 0.01 of parity, one crossing ratio 1 (the existing
      rounding-bucket idiom, `R:224-233`, does not red on that by itself).
- [ ] AC2 Every width figure any rewritten site states is recomputed by
      `test-doc-skew-caveat.R` from the fixture's per-cell rows and asserted to
      match at the prose's own rounding. The numeral-enumeration leg is
      extended to each roxygen block and each `###` vignette section that AC5's
      sweep reports as carrying a burch/searle width sentence — the anchors are
      what the sweep returns, not a remembered list (the two existing anchors,
      `@section Confidence intervals:` and `^### When the default under-covers`,
      cover none of the width sites).
- [ ] AC3 At every site AC5's sweep reports as carrying a width statement, that
      statement names how the ratio moves with ρ and with the subject count, and
      no site states a rater-count width effect. A test asserts from the per-cell
      rows the fact that licenses the omission: `n = 2` occurs only at `k = 10`,
      so the *marginal* rater contrast is confounded with subject count. It
      asserts nothing about separability at fixed `k`, where a rater contrast
      does exist and points the other way. The runtime hint stays width-silent,
      as `test-doc-skew-caveat.R:424-425` already pins.
- [ ] AC4 Every per-ρ figure stated is computed from the M113 rows alone, and no
      figure pools over ρ or over `k` within a grid. A test asserts the two
      grids' `(ρ, k, n)` design-combination sets stand in the containment
      M76 ⊂ M113 that made the pooled figure misread as a between-grid
      difference.
- [ ] AC5 `test-doc-skew-caveat.R`'s installed-surface and source-tree legs
      resolve their targets by directory walk — every `R/*.R`, every
      `vignettes/*.Rmd`, `NEWS.md`, plus the installed Rd database, installed
      vignettes and installed `NEWS.md` — replacing the six hand-listed paths,
      each leg carrying an anti-vacuity assertion, with 0 skips in that file
      confirmed under `testthat::test_file("tests/testthat/test-doc-skew-caveat.R",
      package = "intraclass", load_package = "installed")` on a
      `build_vignettes = TRUE` install.
- [ ] AC6 Each pattern added to `claim_patterns` is two-sided verified — zero
      hits over the surfaces AC5's sweep walks, at least one hit on the
      pre-correction tree. Scoped to those surfaces, never the repo: the
      withdrawn phrasings survive legitimately in `DECISIONS.md`, `LESSONS.md`
      and `milestones/archive/`, which D-020 rule 4 excludes because IP4 forbids
      editing history.
- [ ] AC7 `check-mpl-doc-claims.py`, `check-reference-observations.py`,
      `enumerate-generalizing-claims.py --check` and `check-record-claims.py`
      each exit 0 on the final tree, with `mpl-doc-claims.tsv` re-triaged for
      every sentence changed inside the blocks it keys, and
      `cairn/references/classical-oneway-comparison.md` recording the per-factor
      breakdown under a D-009 dated observation.
- [ ] AC8 The profile's verify slot is clean: `air format --check`,
      `lintr::lint_package()`, and the installed-package suite at
      `NOT_CRAN=true CI=true`.

## Coverage

- AC1 → T1
- AC2 → T3, T5
- AC3 → T3, T5
- AC4 → T3, T5
- AC5 → T2
- AC6 → T6
- AC7 → T7
- AC8 → T8

## Tasks

- [x] T1 Extend `data-raw/m116-classical-width-comparison.R`: per-factor
      summary rows for ρ and `k` per grid (reuse `summarize_grid`'s arithmetic,
      `R:178-189`), regenerate the `.tsv`, add the pins, mutation-verify each.
      Sequence with T7: the D-009 directive at
      `cairn/references/classical-oneway-comparison.md:126` reads the summary
      block's first row positionally.
- [x] T2 Widen the two surface legs of `tests/testthat/test-doc-skew-caveat.R`
      (`:217-250`, `:253-274`) to directory walks with per-leg anti-vacuity
      assertions; confirm 0 skips in the file on an installed run.
- [x] T3 Tests first, red: the recompute-and-match assertions for the figures
      T5 will state, the marginal-confounding assertion, the M76 ⊂ M113
      containment assertion.
- [x] T4 Run the widened sweep to enumerate the sites carrying a width
      statement; record the list as evidence (it, not memory, scopes T5).
- [x] T5 Rewrite the width statement at each site T4 reports — `R/icc.R`
      `@param ci_method` (`:404-407`) and `@details` (`:570-572`),
      `R/ci-classical.R:17-23`, `vignettes/interval-methods.Rmd:146-169`,
      `vignettes/glossary.Rmd:40-42`, `NEWS.md:60-66` — then
      `devtools::document()`.
- [x] T6 Add and two-sided verify the new `claim_patterns` entries against the
      pre-correction tree.
- [x] T7 Ledgers: `mpl-doc-claims.tsv` re-triage, the D-009 dated observation on
      `classical-oneway-comparison.md`, all four data-raw checkers green.
- [x] T8 Full gate: air, lintr, `pkgdown::check_pkgdown()`, installed-package
      suite at `NOT_CRAN=true CI=true`; PR and CI matrix.

## Work log

- 2026-08-09: created by /milestone-plan (promotes the M116 re-review candidate row).
- 2026-08-09: plan-time criteria audit ([O], fresh context) returned six findings; five with one clear right answer were fixed in the wording before this file was written — AC1's mutation perturbation named (the rounding-bucket pin does not red on a sign flip at ρ=0.6), AC2 bound to sweep-decided anchors, AC4 retargeted from cross-grid to within-grid pooling (its original clause was already true), AC5's "0 skips" scoped from `test_dir` to `test_file`, AC6's domain scoped from "the corrected tree" to the swept surfaces. The sixth went to the gate.
- 2026-08-09: plan gate chose stating ρ and subject count only over also stating the conditional rater contrast, because the marginal and within-`k` rater contrasts point opposite ways and a third conditional would obscure the rule of thumb; falsified by a measured rater effect at fixed `k` large enough that omitting it misleads.
- 2026-08-09: plan gate chose deriving the conditional from the M113 grid alone over reporting both grids per level, because M76 carries only ρ ∈ {0.05, 0.1} and its design is a strict subset of M113's; falsified by a grid whose ρ coverage M113 lacks.
- 2026-08-09: plan gate chose widening the test's source-tree leg to a directory walk over keeping the six hand-listed paths and narrowing the promise, because a recalled path list is the proxy shape that beat M102 three times; falsified by the walk reddening on legitimate width vocabulary it cannot distinguish.
- 2026-08-09: started by /milestone-implement on branch m117-conditional-width-claim.
- 2026-08-09: PR #126 opened; CI matrix pending.
- 2026-08-09: T8 — gate clean. Installed run of `test-doc-skew-caveat.R` (`load_package = "installed"`, `NOT_CRAN=true CI=true`, `build_vignettes = TRUE`): 0 failed, 0 skipped, 709 passed — AC5's zero-skip claim measured on the surface it is about, not inferred from a dev run. Full installed suite: 0 failed, 0 errors, 6563 passed, 23 skipped (all `skip_on_ci`, the brms live-Stan class) and 2 engine fitting warnings in `test-icc-lavaan-multilevel.R` / `test-icc-type-vector.R`, neither touched by this branch. `air format --check`, `lintr::lint_package()` (0 lints), `pkgdown::check_pkgdown()` and `cairn_validate` all clean.
- 2026-08-09: T5–T7 — the six reported sites rewritten; `?icc`'s front door states direction and the parity warning with no percentages (gate choice), the interval-methods article carries per-true-ICC and per-subject-count tables, and `R/ci-classical.R` carries the figures. Both vignette tables land inside one width sentence, so the numeral pin covers every cell — mutation-verified (0.9971 → 0.9972 reds, restore greens). Ledgers: three `mpl-doc-claims.tsv` rows re-triaged (two retired, three added — the sentence-hash key restales on any edit inside the block, M105), one `generalizing-claims-triage.tsv` row added for the new references claim (M85), and a second D-009 dated observation on `classical-oneway-comparison.md` with an exit-coded directive, mutation-verified red on a moved value. All four data-raw checkers exit 0.
- 2026-08-09: T6 pattern verification used SQUASHED text, not `git grep`: line-based counting found 1 pre-correction hit for `pooled_pct_param` where the squashed sweep found 2 — the NEWS occurrence wrapped across lines (M115). Both new patterns: 0 hits corrected, ≥1 pre-correction.
- 2026-08-09: T4 — the widened sweep walks 33 files and reports 6 carrying a burch width sentence: `R/icc.R`, `R/ci-classical.R`, `R/boundary-hint.R`, `vignettes/glossary.Rmd`, `vignettes/interval-methods.Rmd`, `NEWS.md`. That list, not memory, scopes T5.
- 2026-08-09: T3 (red) — new fixture `tests/testthat/fixtures/classical-width-by-cell.tsv` (80 per-cell rows, written by the same generator, re-derivation test guarded on `data-raw/`); tests recompute every level median from the per-cell rows rather than trusting the generator's summary block. Fixture-side blocks green; the three prose-dependent blocks red as intended (10 + 2 + 11 failures). The rater check runs over a ±1-sentence window: the sentence that would carry a rater figure names no method, so the sentence-level filter passed over it vacuously and the window is what gave the check teeth (it went 0 → 2 failures on the unmodified tree).
- 2026-08-09: T2 — both surface legs now walk their own domain (whole Rd database, every installed vignette, installed NEWS; every `R/*.R`, every `vignettes/*.Rmd`, `NEWS.md`), each asserting it still reaches all six retired hand-list paths and strictly more. The vignette-presence assertion moved to its own `test_that` — left above the sweep, its `skip_if` took the Rd and NEWS checks down with it in a dev session (M116). 375 → 423 passing assertions.
- 2026-08-09: minor amendment — T4 (enumerate the sites) runs before T3 (pin the figures); the sweep is what scopes which figures exist to pin. No scope or criterion change.
- 2026-08-09: T1 — generator emits a per-(grid, factor, level) block for rho and subject count, both groupings routed through one `width_summary()` core; 15 new pins, each mutation-verified via a harness that masks `stopifnot` so one mutation reports every pin it trips (10 mutations + an unmutated control that fires none). The rho=0.6 sign-crossing mutation the rounding-bucket idiom cannot see reds the exact pin and the direction pin. The D-009 directive reading the fixture positionally still exits 0.
- 2026-08-09: plan gate read D-012 Amendment 1's reopening clause ("a grid on which Burch's median width exceeds SEARLE's") as not tripped by the ρ=0.6/`k`=50 region's 1.0015 median, the clause being scoped to whole grids and M76 carrying no reversal; no D-012 Amendment 2. Falsified by a whole committed grid whose median ratio exceeds 1.

## Decisions

## Review
