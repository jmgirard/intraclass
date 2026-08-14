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

- [x] AC1 The generator emits one summary row per (grid, factor, level) for
      factor ∈ {ρ, subject count `k`}, by the same width-ratio arithmetic as
      the per-cell rows, and the `.tsv` is regenerated to carry them. Each new
      `stopifnot` pin is mutation-verified against a perturbation large enough
      to change the sentence the prose states — including, at every level whose
      median lies within 0.01 of parity, one crossing ratio 1 (the existing
      rounding-bucket idiom, `R:224-233`, does not red on that by itself).
- [x] AC2 At every site AC5's sweep reports as carrying a width statement, each
      figure the declared canonical templates and shapes match is checked
      against the value recomputed from the fixture's per-cell rows at the
      prose's own rounding. A committed prose-mutation leg extends the M117
      harness — each mutation patches a swept surface and requires the scan to
      red, and the leg's coverage assertion fails on any mutation nothing
      reds — with its class list naming each encoded defeat and the review
      return it answers, AC4's three pooled-figure placements among them. The
      scan's file header names the token classes it checks and states that
      tokens outside them are not claimed checked; this criterion claims the
      declared classes only.
- [x] AC3 At every site AC5's sweep reports as carrying a width statement, that
      statement names how the ratio moves with ρ and with the subject count, and
      no site states a rater-count width effect. A test asserts from the per-cell
      rows the fact that licenses the omission: `n = 2` occurs only at `k = 10`,
      so the *marginal* rater contrast is confounded with subject count. It
      asserts nothing about separability at fixed `k`, where a rater contrast
      does exist and points the other way. The runtime hint stays width-silent,
      as `test-doc-skew-caveat.R:424-425` already pins.
- [x] AC4 Each figure the declared per-ρ shapes match on the surfaces AC5's
      sweep walks is computed from the M113 rows alone, asserted by matching it
      against the M113 recomputation and no other grid's. A test asserts the
      two grids' `(ρ, k, n)` design-combination sets stand in the containment
      M76 ⊂ M113 that made the pooled figure misread as a between-grid
      difference. The prose-mutation leg's pooled-figure family varies
      placement, form and grid — before a surface's first table, between
      tables, and in running prose; the 4-decimal ratio, a pooled percentage,
      and a spelled approximation; the larger and the smaller grid's medians —
      each reddening, with no claim beyond the declared classes.
- [x] AC5 `test-doc-skew-caveat.R`'s installed-surface and source-tree legs
      resolve their targets by directory walk — every `R/*.R`, every
      `vignettes/*.Rmd`, `NEWS.md`, plus the installed Rd database, installed
      vignettes and installed `NEWS.md` — replacing the six hand-listed paths,
      each leg carrying an anti-vacuity assertion, with 0 skips in that file
      confirmed under `testthat::test_file("tests/testthat/test-doc-skew-caveat.R",
      package = "intraclass", load_package = "installed")` on a
      `build_vignettes = TRUE` install.
- [x] AC6 Each pattern added to `claim_patterns` is two-sided verified — zero
      hits over the surfaces AC5's sweep walks, at least one hit on the
      pre-correction tree. Scoped to those surfaces, never the repo: the
      withdrawn phrasings survive legitimately in `DECISIONS.md`, `LESSONS.md`
      and `milestones/archive/`, which D-020 rule 4 excludes because IP4 forbids
      editing history.
- [x] AC7 `check-mpl-doc-claims.py`, `check-reference-observations.py`,
      `enumerate-generalizing-claims.py --check` and `check-record-claims.py`
      each exit 0 on the final tree, with `mpl-doc-claims.tsv` re-triaged for
      every sentence changed inside the blocks it keys, and
      `cairn/references/classical-oneway-comparison.md` recording the per-factor
      breakdown under a D-009 dated observation.
- [x] AC8 The profile's verify slot is clean: `air format --check`,
      `lintr::lint_package()`, and the installed-package suite at
      `NOT_CRAN=true CI=true`.
- [x] AC9 At every site the template scan reports carrying the flat-below-0.3
      clause, the clause carries a grid hedge matching the per-grid
      recomputation (the smaller grid's median margin moves the other way
      across its ρ levels). The largest-margin sentence states its cut (level
      medians), with a test pinning both facts: agreement at that cut and the
      11-of-16 paired-cell contradiction that bars the unqualified form. Each
      corrected sentence is covered by an association pin, and the
      prose-mutation leg carries a mutation restoring each pre-correction
      wording that reds.

## Coverage

- AC1 → T1, T17
- AC2 → T3, T5, T9, T10, T11, T14, T15, T18
- AC3 → T3, T5, T10, T11, T15
- AC4 → T3, T5, T9, T10, T11, T14, T15, T18
- AC5 → T2
- AC6 → T6
- AC7 → T7, T12, T16, T19
- AC8 → T8, T13, T17, T20
- AC9 → T19

## Tasks

Shipped (detail in the work log and git):

- [x] T1 Generator: per-factor summary rows for ρ and `k` per grid; regenerate; pins mutation-verified.
- [x] T2 Both surface legs widened to directory walks with per-leg anti-vacuity assertions.
- [x] T3 Tests first, red: recompute-and-match, marginal confounding, M76 ⊂ M113 containment.
- [x] T4 The widened sweep enumerates the sites carrying a width statement; that list scopes T5.
- [x] T5 Width statement rewritten at each reported site; `devtools::document()`.
- [x] T6 New `claim_patterns` entries added and two-sided verified.
- [x] T7 Ledgers re-triaged; D-009 dated observation; four data-raw checkers green.
- [x] T8 Full gate; PR #126 and CI matrix.
- [x] T9 `k_at_n5` cut replacing the confounded marginal `k` rows; pins; mutation harness committed.
- [x] T10 Level↔figure association pin over both legs; per-statement direction pin; rater licensing rule.
- [x] T11 Prose corrected at the six sites; figures moved out of `R/ci-classical.R` into the article.
- [x] T12 D-009 directive extended to every stated figure; ledgers re-triaged.
- [x] T13 Full gate on a rebuilt install; the source leg gated so `covr`'s partial tree skips.

Review return #2 repair (detail in the work log and git):

- [x] T14 Canonical-shape figure scan (eleven declared shapes, each checked against the recomputation; unmatched figure-shaped tokens refused; ratios scanned surface-wide).
- [x] T15 Canonical clause templates for the three directional claims at all six sites; the two return-#2 prose defects fixed.
- [x] T16 Mechanical gaps: unfired-pin mutations, vacuity-safe masked `stopifnot`, hand list folded into AC5's retired paths, D-009 directive extended, source gate rekeyed.
- [x] T17 Full gate and push: air, lintr, `pkgdown::check_pkgdown()`, installed suite at `NOT_CRAN=true CI=true`, CI matrix.

Re-cut (2026-08-13):

- [x] T18 Prose-mutation leg in `data-raw/m117-width-pin-mutations.R`: patch a swept surface → run the scan → require red; coverage assertion; class list naming each review-return defeat, pooled-figure mutations varying placement, form and grid per AC4; fix `width_strip_tables()` (per-table non-greedy match) so all three placements red; scan header states the claimed-classes boundary.
- [x] T19 AC9 corrections: grid hedge at the flat-clause sites carrying none; the largest-margin sentence states its cut; association pins and restoration mutations; ledgers re-triaged.
- [x] T20 Full gate on a rebuilt `build_vignettes = TRUE` install; CI matrix; review evidence refresh.

## Work log

- 2026-08-09: created by /milestone-plan (promotes the M116 re-review candidate row).
- 2026-08-09: plan-time criteria audit ([O], fresh context) returned six findings; five with one clear right answer were fixed in the wording before this file was written — AC1's mutation perturbation named (the rounding-bucket pin does not red on a sign flip at ρ=0.6), AC2 bound to sweep-decided anchors, AC4 retargeted from cross-grid to within-grid pooling (its original clause was already true), AC5's "0 skips" scoped from `test_dir` to `test_file`, AC6's domain scoped from "the corrected tree" to the swept surfaces. The sixth went to the gate.
- 2026-08-09: plan gate chose stating ρ and subject count only over also stating the conditional rater contrast, because the marginal and within-`k` rater contrasts point opposite ways and a third conditional would obscure the rule of thumb; falsified by a measured rater effect at fixed `k` large enough that omitting it misleads.
- 2026-08-09: plan gate chose deriving the conditional from the M113 grid alone over reporting both grids per level, because M76 carries only ρ ∈ {0.05, 0.1} and its design is a strict subset of M113's; falsified by a grid whose ρ coverage M113 lacks.
- 2026-08-09: plan gate chose widening the test's source-tree leg to a directory walk over keeping the six hand-listed paths and narrowing the promise, because a recalled path list is the proxy shape that beat M102 three times; falsified by the walk reddening on legitimate width vocabulary it cannot distinguish.
- 2026-08-09: started by /milestone-implement on branch m117-conditional-width-claim.
- 2026-08-09: PR #126 opened; CI matrix pending.
- 2026-08-09: review return #1 (defect) — four criteria fail as written and are unticked. AC2: the numeral pin is set-membership against a flat 44-value pool, not an association between figure and level, and `R/ci-classical.R`'s seven figures are not selected by the sentence filter at all (its sentence names `searle`, never `burch`); both mutation-verified green by the [O] lens, including a sign-reversing 0.9971 -> 1.0971. AC3: `R/boundary-hint.R` states that the relationship is conditional but never how it moves with the subject count, and the `expect_match(text, "subject")` leg never reds on any of the six sites. AC4: its second clause as written ("no figure pools over rho or over `k` within a grid") is unsatisfiable by any per-factor cut. AC7: the new D-009 directive settles 4 of about 13 stated figures and facts. Separately, four shipped prose claims are wrong or overstated against the fixture (O4 rho non-monotonicity, O5 the both-grids attribution at rho=0.6, O6 the k margin confounded with rater count at k=10, O7 the pooled-difference attribution) — the defect class this milestone exists to remove.
- 2026-08-09: the implement-time AC2 evidence was too weak and was reported as stronger than it was: the mutation run (0.9971 -> 0.9972) only demonstrated that OUT-OF-POOL values red. Any future numeral pin here must be mutation-tested by swapping a real figure to another real figure from the same pool, never by perturbing to an unmeasured value.
- 2026-08-09: CI note — pushing the review-evidence checkpoint mid-run cancelled the three in-flight matrix jobs (cancel-in-progress); they re-ran on the new head. Hold pushes while a measurement CI run is in flight, review phase included (M78).
- 2026-08-09: T8 — gate clean. Installed run of `test-doc-skew-caveat.R` (`load_package = "installed"`, `NOT_CRAN=true CI=true`, `build_vignettes = TRUE`): 0 failed, 0 skipped, 709 passed — AC5's zero-skip claim measured on the surface it is about, not inferred from a dev run. Full installed suite: 0 failed, 0 errors, 6563 passed, 23 skipped (all `skip_on_ci`, the brms live-Stan class) and 2 engine fitting warnings in `test-icc-lavaan-multilevel.R` / `test-icc-type-vector.R`, neither touched by this branch. `air format --check`, `lintr::lint_package()` (0 lints), `pkgdown::check_pkgdown()` and `cairn_validate` all clean.
- 2026-08-09: T5–T7 — the six reported sites rewritten; `?icc`'s front door states direction and the parity warning with no percentages (gate choice), the interval-methods article carries per-true-ICC and per-subject-count tables, and `R/ci-classical.R` carries the figures. Both vignette tables land inside one width sentence, so the numeral pin covers every cell — mutation-verified (0.9971 → 0.9972 reds, restore greens). Ledgers: three `mpl-doc-claims.tsv` rows re-triaged (two retired, three added — the sentence-hash key restales on any edit inside the block, M105), one `generalizing-claims-triage.tsv` row added for the new references claim (M85), and a second D-009 dated observation on `classical-oneway-comparison.md` with an exit-coded directive, mutation-verified red on a moved value. All four data-raw checkers exit 0.
- 2026-08-09: T6 pattern verification used SQUASHED text, not `git grep`: line-based counting found 1 pre-correction hit for `pooled_pct_param` where the squashed sweep found 2 — the NEWS occurrence wrapped across lines (M115). Both new patterns: 0 hits corrected, ≥1 pre-correction.
- 2026-08-09: T4 — the widened sweep walks 33 files and reports 6 carrying a burch width sentence: `R/icc.R`, `R/ci-classical.R`, `R/boundary-hint.R`, `vignettes/glossary.Rmd`, `vignettes/interval-methods.Rmd`, `NEWS.md`. That list, not memory, scopes T5.
- 2026-08-09: T3 (red) — new fixture `tests/testthat/fixtures/classical-width-by-cell.tsv` (80 per-cell rows, written by the same generator, re-derivation test guarded on `data-raw/`); tests recompute every level median from the per-cell rows rather than trusting the generator's summary block. Fixture-side blocks green; the three prose-dependent blocks red as intended (10 + 2 + 11 failures). The rater check runs over a ±1-sentence window: the sentence that would carry a rater figure names no method, so the sentence-level filter passed over it vacuously and the window is what gave the check teeth (it went 0 → 2 failures on the unmodified tree).
- 2026-08-09: T2 — both surface legs now walk their own domain (whole Rd database, every installed vignette, installed NEWS; every `R/*.R`, every `vignettes/*.Rmd`, `NEWS.md`), each asserting it still reaches all six retired hand-list paths and strictly more. The vignette-presence assertion moved to its own `test_that` — left above the sweep, its `skip_if` took the Rd and NEWS checks down with it in a dev session (M116). 375 → 423 passing assertions.
- 2026-08-09: minor amendment — T4 (enumerate the sites) runs before T3 (pin the figures); the sweep is what scopes which figures exist to pin. No scope or criterion change.
- 2026-08-09: T1 — generator emits a per-(grid, factor, level) block for rho and subject count, both groupings routed through one `width_summary()` core; 15 new pins, each mutation-verified via a harness that masks `stopifnot` so one mutation reports every pin it trips (10 mutations + an unmutated control that fires none). The rho=0.6 sign-crossing mutation the rounding-bucket idiom cannot see reds the exact pin and the direction pin. The D-009 directive reading the fixture positionally still exits 0.
- 2026-08-09: status review. CI on `0c43faf`: `format-check`, `lint`, `pkgdown` and `check-references` pass; `ubuntu-latest (release)`, `windows-latest (release)` and `test-coverage` still running after 13 minutes (the matrix runs 17-23 minutes, M78). The status-change commit is deliberately NOT pushed while they are in flight — pushing cancels them and restarts on the new head, which is what happened at the last review checkpoint.
- 2026-08-09: CI caught what the review's local evidence could not: the `test-coverage` job was RED on the branch head (3 failures, `53a0711`) while `R CMD check` was green on every platform. `covr` runs the suite against a built package in a temp dir that carries `NEWS.md` but no `R/*.R` and no `vignettes/` — a PARTIAL source tree, where the walk returns one surface and `skip_if(length(surfaces) == 0L)` does not fire, so every anti-vacuity floor fails instead of skipping. The source leg now gates on `data-raw/` (`.Rbuildignore`d, so present in the source tree and in no built copy). Reproduced in a scratch dir with that exact layout: the pre-fix file reds the same two assertions the CI log names, the fixed file skips cleanly (0 failed, 4 skipped).
- 2026-08-09: parked as `blocked` at the maintainer's decision after review return #3. Blocker: a maintainer call on how far a free-text documentation claim should be mechanically guaranteed — the question three rounds of AC2 failures keep surfacing and that no recorded plan-gate alternative still answers. Nothing merges; PR #126 stays open and is marked draft. The corrected documentation on the branch is verified correct at every site by two independent from-scratch re-derivations, and the full CI matrix is green on `5b55aeb`, so the branch is not abandoned work — it is work whose guard specification is unsettled. Unparks on that decision: re-cut or split via `/milestone-plan`, escalation via `/milestone-brief`, or an explicit override to merge as-is. Two below-bar prose defects would need fixing before any merge: the un-hedged flat-to-0.3 clause at four sites (the smaller grid's margin runs the other way) and the largest-margin-at-0.1 claim (contradicted 11-5 in the paired cells).
- 2026-08-09: review return #3 (defect) — AC2 and AC4 fail, each inside its named procedure's domain. One cause dominates: `width_strip_tables()` matches from a surface's FIRST pipe to its LAST, so it erases 96% of `R/icc.R` and 50% of the article before the surface-wide ratio scan runs; the pooled-ratio sentence return #2 used passes green again, and reds only when placed before a surface's first pipe. Four token classes also pass unchecked (a spelled cardinal with an intervening adjective, a malformed table row, a table under an unrecognized header, any figure equal to an allowlisted value). AC1, AC3, AC5, AC6, AC7 and AC8 verified and ticked; CI fully green on `5b55aeb`, test-coverage included. Thrash trigger (a) fires — third defect return, so no further retry is queued and the milestone routes to `/milestone-plan`. Trigger (b) fires on AC2 for the third time; the plan gate's recorded alternative (narrow the promise) was spent this round and failed on the first unforeseen mechanism, so escalation is offered instead of a fourth round.
- 2026-08-09: T17 — gate clean on a rebuilt `build_vignettes = TRUE` install. `test-doc-skew-caveat.R` at `load_package = "installed"`, `NOT_CRAN=true CI=true`: 0 failed, 0 skipped, 1125 passed. Full installed suite: 0 failed, 0 errors, 6979 passed, 23 skipped (all `skip_on_ci`), the same 2 pre-existing engine fitting warnings. `air format --check`, `lintr::lint_package()` (0 lints), `pkgdown::check_pkgdown()`, `devtools::document()` (no diff) and `cairn_validate` all clean; all four data-raw checkers exit 0.
- 2026-08-09: mutation battery over the corrected tree — every defeat the two reviews found now reds: a swapped table ratio, a swapped level count, a mis-attributed grid total, a grid size, a family count, the largest-margin level, a substituted smaller-grid figure, a free-standing pooled ratio, a reversed template, a paraphrased template, a moved template level, a dropped one-grid hedge, a gutted `@param` block, a rater-count comparison and an affirmative no-rater-effect claim. The unmutated control stays green.
- 2026-08-09: T16 — mechanical gaps closed. Three mutations added for the pins nothing was tripping (a design point the larger grid lacks, the larger grid cut back to the smaller's points, a level removed outright); the masked `stopifnot` now treats a zero-length condition as a trip rather than a pass, so a removed level cannot silence the pins that index into it; and the harness ASSERTS coverage — a pin reddened by no mutation fails the run unless explicitly exempt, which is what caught the first containment mutation reddening nothing. 14 mutations, 38 distinct pins, 12 exempt (M116 input fences no perturbation of the derived frame can reach). The duplicate surface hand list folded into AC5's retired-path list; the source leg regated on `R/*.R` presence so an unpacked source tarball is swept where the `data-raw/` gate skipped it; the D-009 directive extended to the largest-margin level and to the marginal-vs-stratified k comparison on both grids, both mutation-verified.
- 2026-08-09: T15 — the three directional clauses are canonical templates, stated verbatim at all six sites with both true-ICC levels derived from the fixture. A reversal, a paraphrase, a moved level and a dropped one-grid hedge each red now; under the keyword-proximity markers they all passed. The rater rule splits by scope: the forbidden patterns (a rater-count comparison, a confounded rater level, an affirmative "no rater effect") run over every width statement, while the licensed-mention requirement runs only over margin-asserting ones — over all of them it reds on the article's MPL paragraph, whose "fixed raters" is about design, not width. Also fixed the two prose defects: the grids agree closely at two of their sixteen shared design points, so "differ cell by cell" is now "mostly disagree ... agreeing closely at only a couple"; and `NEWS.md` and `R/ci-classical.R` carry the one-grid hedge the other four sites already had.
- 2026-08-09: T14 — the canonical-shape scan. Eleven shapes, each with a checker against the recomputed fixture; a figure-shaped token a width statement carries outside every shape now FAILS instead of passing unchecked, and ratio-shaped tokens are scanned surface-wide rather than inside method-naming sentences. Sentence splitting now protects abbreviations — `eq. 6/13/15/16/17` and `Ch. 9 Table 9.14` were being cut in half, stranding their numerals as apparently-unchecked figures. Grids are identified by size word rather than milestone id, since NEWS and the vignettes are user-facing.
- 2026-08-09: amendment (implement-side, executing the return-#2 gate choice) — AC2 rewritten to "each figure a width statement states sits in one of a fixed set of canonical shapes … A figure-shaped token — decimal, bare integer, or spelled-out cardinal — that a width statement carries outside every canonical shape and outside the declared non-measurement allowlist fails the test rather than passing unchecked"; AC4's unimplemented pooled-ratio clause folded into that scan. The promise inverts: the test now refuses a figure it cannot check, instead of promising to check every figure. Gate flagged that this is AC4's SECOND amendment and the user accepted both rewrites seeing that.
- 2026-08-09: gate chose canonical clause templates for the three directional claims at all six sites over templates on user-facing pages only or keeping the keyword check, because a reversed or paraphrased claim passes the keyword check today (review F2/F3/F4) and the claim has been wrong twice; falsified by a site where the template cannot be stated without distorting the surrounding prose.
- 2026-08-09: review return #2 (defect) — AC1, AC2 and AC4 fail as written, each verified by command with the tree restored. AC1: three M117 `stopifnot` pins fire on no committed mutation (the two containment pins and the `lvl()` guard), so "each new pin is mutation-verified" is false; tick withdrawn. AC2: four stated width figures are asserted by nothing — `five cells` -> `nine cells`, `half a percentage point` -> `five percentage points`, `64-cell` -> `32-cell`, `four distribution families` -> `six` all leave the suite green. AC4: its amended final clause has no implementation — "Pooled over the larger grid the median width ratio is 0.9614." passes, because the sweep selects only sentences carrying the token `burch`. AC3, AC5, AC6, AC7 and AC8 verified and ticked; CI fully green on `0183caf`. Thrash trigger (b) fires on AC2 (second failure, same shape); the plan gate's recorded alternative — narrowing the promise — is the one to reconsider.
- 2026-08-09: T13 — gate clean on a rebuilt `build_vignettes = TRUE` install. `test-doc-skew-caveat.R` at `load_package = "installed"`, `NOT_CRAN=true CI=true`: 0 failed, 0 skipped, 987 passed (AC5's zero-skip claim re-measured on the surface it is about). Full installed suite: 0 failed, 0 errors, 6841 passed, 23 skipped (all `skip_on_ci`, the brms live-Stan class), 2 pre-existing engine fitting warnings in `test-icc-lavaan-multilevel.R` / `test-icc-type-vector.R`, neither touched by this branch. `air format --check`, `lintr::lint_package()` (0 lints), `pkgdown::check_pkgdown()`, `devtools::document()` (no diff) and `cairn_validate` all clean; the two `cairn_validate` advisories are the 8-criterion and 13-task split tripwires, both a review return's repair tasks rather than a mis-sized milestone.
- 2026-08-09: AC6 extended for the claim this return withdraws: `shrinks as either grows` (2 pre-correction hits, 0 corrected) and `at a low true ICC with few subjects` (3 / 0), both counted over squashed text across the swept surfaces.
- 2026-08-09: the installed leg's anti-vacuity set is now DERIVED from the surfaces present rather than a fixed pair, so the floor sits at the measured count instead of below it (review O10).
- 2026-08-09: T12 — the D-009 directive now settles every figure and fact the paragraph states (10 level medians, the five-reversing-cells fact, the n = 2 confounding, the sub-0.6 flatness and its non-monotone peak, and that the marginal and 5-rater k = 10 rows differ), up from 4. Mutation-verified: moving any of three level medians by one digit reds it. Ledgers: two `mpl-doc-claims.tsv` rows re-triaged onto the corrected sentences (the replaced row asserted the margin shrinking in rho, which the fixture falsifies), one `generalizing-claims-triage.tsv` row split into two on the rewritten paragraph. All four data-raw checkers exit 0.
- 2026-08-09: T11 — the six sites rewritten: the rho shape is flat-then-collapse (the margin peaks at 0.1, so the shipped "shrinks as either grows" was false on its own figures), the subject-count figures are the 5-rater ones, rho = 0.6 is attributed to the one grid that reaches it, the grid-containment claim is bounded to "most of the gap", and `R/ci-classical.R`'s seven figures move to the article. Mutation-verified at all seven statements: replacing each with "That margin is conditional on the true ICC and on the subject count" — the shape review O11 found passing — now reds 2 or 3 markers at every one.
- 2026-08-09: T10 — the association pin. Swapping a real figure for another real figure from the same pool now reds (0.9971 -> 0.9769 at rho = 0.6, 0.9154 -> 0.9646 at 10 subjects, `13 of 16` -> `15 of 16`, `59 of 64` -> `61 of 64`), and a free-standing pooled ratio (0.9614 with no level) reds as "stated with no level attached". Pins run over the installed help/vignettes/NEWS as well as the source tree, so they no longer all skip under `R CMD check`. Two defects found while building it: the table-strip regex matched non-overlappingly and left every other cell readable as loose prose, and the article's smaller-grid triple sat in a sentence naming neither method, so its three figures were unpinned (review O3, recurring).
- 2026-08-09: the AC3 pin is keyed per contiguous STATEMENT, not per file: with per-file keying, reverting `?icc`'s `@param` conditional reddened nothing because `@details` still satisfied the file. A run is held to the three direction markers only when it names the margin or the advantage — a NEWS bullet pointing at the correction asserts no margin and is not held to one.
- 2026-08-09: amendment return: AC4 — "no stated figure is a grid-wide median pooling ρ and `k` together — every figure is cut at one level of one factor"; the original second clause forbade pooling over ρ OR over `k`, which every per-factor cut necessarily does (review O15). Gate chose the rewrite over keeping wording no work could satisfy.
- 2026-08-09: gate chose recomputing the subject-count figures at 5 raters (0.9154/0.9646/0.9769 on M113, 0.9017/0.9611/0.9775 on M76) over keeping the marginal ones with a caveat or dropping them, because k = 10 is the only subject count carrying n = 2 and the marginal cut repeats one level down the confounding the milestone used to refuse a rater claim (review O6); falsified by a grid balancing the rater count across subject counts.
- 2026-08-09: gate chose moving the stated figures out of `R/ci-classical.R`'s internal comment into the article over keeping them beside the code, because an internal comment is not in the built package, so every pin over it skips under `R CMD check` (review O13); falsified by a figure that has no installed surface to live on.
- 2026-08-09: T9 — `k_at_n5` factor rows (both grids, 3 levels each) added through the same `width_summary()` core; 12 new pins plus a structural pin that the marginal and 5-rater k cuts coincide at k = 30/50 and differ at k = 10. Mutation harness now committed (`data-raw/m117-width-pin-mutations.R`, review O18): 11 mutations red 33 distinct pins between them, every new pin fires on at least one, unmutated control fires none.
- 2026-08-09: plan gate read D-012 Amendment 1's reopening clause ("a grid on which Burch's median width exceeds SEARLE's") as not tripped by the ρ=0.6/`k`=50 region's 1.0015 median, the clause being scoped to whole grids and M76 carrying no reversal; no D-012 Amendment 2. Falsified by a whole committed grid whose median ratio exceeds 1.
- 2026-08-13: re-cut criteria audit ([O], fresh context) returned 11 findings; those with one clear right answer were fixed in the wording before this amendment — the prose-mutation leg named as NEW (the committed harness carries only fixture-cell mutations, so "the scan reds on every harness mutation" was unsatisfiable as drafted), the pooled placements unified at AC4's three, AC4's lead universal bound to the declared per-ρ shapes on the swept surfaces, the pooled-figure mutations made to vary form and grid rather than placement alone, AC9's quantifier bound to the template scan's reported sites. It also verified AC9's premises on the fixture: m76's median margin runs 5.70% → 5.47% across its ρ levels (opposite m113), and the largest-margin claim holds at m113's level medians while contradicted 11–5 in the paired cells. Judgment calls went to the gate.
- 2026-08-13: re-cut gate chose narrowing the promise over a fourth universal round or Fable escalation — AC2/AC4/AC9 claim exactly the declared classes and committed mutations, with the boundary stated in the test's own header; falsified by a shipped width figure outside the declared classes measurably misleading a user, which reopens the guard-scope question. The same choice records the maintainer's D-029 judgment: the prose-mutation leg extends the existing instrument, not a second checker.
- 2026-08-13: re-cut gate chose amending M117 in place on its existing branch and PR over a superseding fresh milestone, because the branch holds the twice-verified corrections and a green CI matrix; falsified by the amended plan-owned body failing the 150-line cap.
- 2026-08-13: re-cut gate chose having the largest-margin sentence state its cut (level medians, at which it is true) with the 11-of-16 paired-cell contradiction pinned beside it, over restating per grid or withdrawing it; falsified by a user reading the cut-qualified sentence as the per-cell claim anyway.
- 2026-08-13: amendment landed by /milestone-plan (AC2/AC4 rewritten, AC9 and T18–T20 added, coverage updated); the parking blocker is resolved by the recorded guard-scope decision, and status stays `blocked` until `/milestone-implement` resumes it — `in-progress` is that skill's transition to make.
- 2026-08-13: resumed by /milestone-implement (blocked → in-progress; blocker resolved by the re-cut gate's guard-scope decision). No implementation question gate: the same-day plan gate settled the open choices. Remaining: T18–T20.
- 2026-08-13: T18 — `width_strip_tables()` rewritten as a pipe-segment scanner (blanks only runs of ≥2 cell-shaped segments: ≤60 chars, sentence-free), so prose between tables survives to be scanned; the three refusal scans hoisted to named helpers (`width_unchecked_figures`, `width_loose_ratios`, `width_pct_violations`) the harness sources with `test_that` stubbed — one definition, no drift; spelled net allows up to two non-stopword qualifiers; percent figures refused in width sentences (nominal 90/95/99/100 excluded — knitr `out.width = "100%"` and the HPDI 95% were the two legitimate hits); ratio-bearing table rows nothing consumes refused as orphans; claimed-classes boundary declared in the file header. Prose-mutation leg: 15 class-named mutations (placement × form × grid for the pooled family; every review-return defeat encoded), all refused, control clean, coverage asserted. Suite: 0 failed, 945 passed; air + lintr clean (lintr 3.4.0 installed locally — absent from this machine's library).
- 2026-08-13: T19 — the flat template now carries the grid hedge "(on the larger grid; the smaller grid's margin does shrink across its levels)", stated verbatim at all seven sites (`R/icc.R` ×2, `R/ci-classical.R`, `R/boundary-hint.R`, both vignettes, `NEWS.md`) and backed by a direction pin recomputing both facts from the per-cell rows; the article's largest-margin sentence states its cut ("by level medians") with the 11-of-16 paired-cell contradiction beside it, pinned by three new canonical shapes — `argmax_cut` (checked against the medians), `argmax_bare` (the unqualified form fails outright), `paired_cells` (recomputed pairing on (k, n, dist)); `width_cardinal_value()` returns NA on unknown words so a shape matching a non-cardinal fails instead of crashing. Three AC9 restoration mutations added (hedge dropped, cut dropped, paired count swapped) — 18 prose mutations, all refused, control clean. `mpl-doc-claims.tsv` row re-keyed for the hedged `R/icc.R` sentence (full-sentence hash restaled, M105); all four data-raw checkers exit 0. Doc suite 0 failed / 948 passed; `devtools::document()` regenerated `man/icc.Rd`; air + lintr clean.
- 2026-08-13: T20 — gate clean on a rebuilt `build_vignettes = TRUE` install. `test-doc-skew-caveat.R` at `load_package = "installed"`, `NOT_CRAN=true CI=true`: 0 failed, 1177 passed, 0 skipped. Full installed suite: 0 failed, 0 errors, 7031 passed, 23 skipped (all `skip_on_ci`). `pkgdown::check_pkgdown()` clean, `devtools::document()` no diff, `air format --check` clean, `lintr` 0 lints, all four data-raw checkers exit 0, `cairn_validate` green (the two sizing advisories are the accepted re-cut artifact). CI matrix fully green on `572b8ec` via REST polling (M63): both platform checks, test-coverage, lint, format-check, pkgdown, check-references, both codecov checks. Status → review.

## Decisions

## Review

**PR:** https://github.com/jmgirard/intraclass/pull/126 · reviewed 2026-08-09.

### Evidence per criterion (fresh, this session)

- AC1 — the regenerated `.tsv` carries 12 per-(grid, factor, level) rows (m76: rho x2, k x3; m113: rho x4, k x3), computed by the shared `width_summary()` core. Pins re-verified with the mutation harness: 10 targeted mutations fire 53 pin-reds between them, every new pin fires on at least one, and the unmutated control fires none. The rho=0.6 sign-crossing mutation (0.9971 -> 1.0049) reds both the exact pin and the direction pin; the pre-existing rounding-bucket idiom does not see it.
- AC2 — installed-package run of the width blocks green; every stated figure is recomputed from the per-cell rows at test time. Corroborated independently: the [S] blame-history lens re-derived all thirteen quoted medians in a fresh R session and matched every doc site.
- AC3 — green, including the marginal-confounding assertion (`n = 2` occurs only at `k = 10`) and the no-rater-mention check over the heading-bounded window. The runtime hint stays width-silent (pre-existing pin, still green).
- AC4 — green, including the M76 subset-of M113 containment assertion on (rho, k, n). Every per-rho figure stated is M113-only.
- AC5 — `testthat::test_file(..., load_package = "installed")` at `NOT_CRAN=true CI=true` on a `build_vignettes = TRUE` install: **0 failed, 0 skipped, 709 passed**. Both legs walk their domain and assert they still reach all six retired hand-list paths and strictly more.
- AC6 — two-sided over squashed text: `pooled_pct_param` 2 pre-correction / 0 corrected, `pooled_pct_vignette` 1 / 0. All six M116 patterns preserved verbatim.
- AC7 — `check-mpl-doc-claims.py`, `check-reference-observations.py`, `check-record-claims.py`, `enumerate-generalizing-claims.py --check` all exit 0. Ledgers re-triaged; the new D-009 directive mutation-verified (reds on a moved value, greens on restore).
- AC8 — `air format --check` clean, `lintr::lint_package()` 0 lints, full installed suite 0 failed / 0 errors / 6563 passed / 23 skipped (all `skip_on_ci`).

### Independent review — three lenses, scored

[S] prior-review: 0 findings (verified the four lessons M115/M116 taught on these files are not reintroduced; the GitHub inline-comment surface is empty, so the thread walk was correctly skipped). [S] blame-history: 10 items, none scoring >= 80 — nothing M115/M116 built was silently weakened, and it independently re-derived all thirteen quoted medians against the fixture. [O] diff-bug: 20 findings, 12 scoring >= 80.

**Actioned (>= 80), verbatim:**

- O1 (92) — "Every width figure in `R/ci-classical.R` is unpinned — AC2 is falsified." The sentence carrying all seven figures begins "Nor is it a flat margin..." and never contains the token `burch`, so `width_sentences()` does not select it. Mutation-verified: `0.9485 -> 0.9584`, `0.9293 -> 0.7293`, and `0.9971 -> 1.0971` (which reverses the direction the same comment asserts two lines above) all pass green.
- O2 (88) — "The numeral pin is a set-membership test, not an association test." `measured` is a flat 44-value pool; any numeral landing anywhere in it passes regardless of which row it sits in. Mutation-verified green: `| 0.6 | 0.9971 | 11 of 16 |` -> `| 0.6 | 0.9769 | 13 of 16 |`; `| 0.05 | 0.9485 | 16 of 16 |` -> `| 0.05 | 0.9293 | 31 of 32 |`; `59 of 64` -> `43 of 64`.
- O3 (84) — "Most of the vignette's conditional prose is outside any pin." Mutation-verified green: the M76 triple `0.9153, 0.9611, 0.9775 -> 0.7153, 0.7611, 0.7775`; `five cells -> nine cells`; `up to a true ICC of 0.3 -> of 0.9`; NEWS `16 of 16 ... 59 of 64 -> 15 of 16 ... 43 of 64`.
- O4 (85) — "'shrinks as either grows' is false in rho, on the very figures the docs quote." Margins are 5.15% / 5.30% / 5.25% / 0.29% at rho = .05/.1/.3/.6 — the margin GROWS from .05 to .1 and peaks at .1. The pattern is flat-then-collapse. Four shipped sites overstate it; the vignette states it correctly.
- O5 (83) — "The rho=0.6 finding is attributed to 'the two grids', but M76 has no rho=0.6." Three shipped surfaces attribute to both grids a pattern only M113 can show.
- O6 (85) — "The subject-count margin is confounded with the rater count, by the identical design fact used to refuse a rater claim." k=10 is the only k level carrying n=2; at fixed n=5 the k=10 median is 0.9154, so "a fourteenth to a fortieth" becomes "a twelfth to a forty-third". Recurrence of the M115 lesson one level down.
- O7 (85) — "The pooled-difference attribution contradicts the repo's own recorded number." Restricting M113 to M76's footprint gives 0.9490 against 0.9430, leaving about a third of the 0.0184 gap unexplained; the grids also differ in families and disagree by up to 0.0083 at matched design points.
- O9 (84) — "AC3's subject-count assertion is vacuous." Reverting the M117 addition at each of the six sites in turn, `expect_match(text, "subject")` never reddened once — the word already occurs in neighbouring prose.
- O10 (80) — "Anti-vacuity floors are below the known site count." `expect_gte(length(surfaces), 5L)` against six measured sites; the numeral test has no floor at all.
- O11 (85) — "AC3 checks a much weaker property than it states." A site asserting the ratio is INDEPENDENT of rho and subject count would pass. `R/boundary-hint.R` states only THAT the relationship is conditional, never how it moves — a literal AC3 violation.
- O13 (80) — "Every new prose pin skips in CI." Under `R CMD check` the source-tree walk finds no `R/`, `vignettes/` or `NEWS.md`, so the numeral, conditional-statement, no-rater and re-derivation blocks all skip; the installed leg checks only ABSENCE of withdrawn phrases. The file's own comment invokes the M115 lesson this repeats.
- O14 (85) — "The D-009 directive settles a third of its observation." The check command settles 4 of about 13 stated figures and facts.

**Logged, below the action bar (8):** O12 (78, the sentence filter selects two R code blocks as "width sentences"); O15 (68, AC4's literal second clause is unsatisfiable by any per-factor cut — an amendment-shaped finding); O18 (68, the AC1 mutation harness is not committed, against M95 precedent); O19 (65, permissive small-integer allowlist); O8 (62, "about a fortieth" for 1/43.3); O20 (55, AC6's exclusion enumeration omits `cairn/references/`); O16 (50, the new fixture has no provenance header — weakened because a sibling fixture also lacks one); O17 (50, "once the true ICC reaches 0.6" reads as extrapolation).

### Consistency gate

`cairn_validate` exit 0 (one advisory: 8 acceptance criteria against the 7 split tripwire — a justified exceedance, seven substantive plus the template-mandated verify criterion). `devtools::document()` no diff. `pkgdown::check_pkgdown()` clean. `devtools::check(--as-cran)`: **0 errors, 0 warnings, 0 notes**. No `DESIGN.md` principle changed, so `cairn_impact` no-ops.

### Process note

A concurrently-running review subagent wrote perturbed ratio values into `tests/testthat/fixtures/classical-width-by-cell.tsv` mid-review, briefly reddening the two width blocks. The file was restored from git and every criterion re-verified clean. Logged because evidence gathered while subagents share the working tree can be contaminated -- and because the pins reddening on that unplanned perturbation is independent confirmation they detect a moved fixture.

---

## Review — return #2 (2026-08-09)

**PR:** https://github.com/jmgirard/intraclass/pull/126 · CI on `0183caf` fully green (ubuntu 21m24s, windows 23m53s, test-coverage 22m3s, plus format-check, lint, pkgdown, check-references, codecov). The `test-coverage` pass is itself the confirmation that the `covr` partial-source-tree guard works — that job was red on `53a0711`.

### Evidence per criterion (fresh, this session)

- AC1 — **FAIL, tick withdrawn.** Differencing the committed harness's fired-label set against the 48 `stopifnot` labels in the generator: 33 labels fire, and three M117-added pins fire on no mutation at all — `"M76's design is no longer contained in M113's"`, `"M113 no longer carries design points M76 lacks"`, and the `lvl()` guard `"no such (grid, factor, level) row"`. No committed mutation alters a design-combination set or removes a level, so those three cannot fire by construction. AC1 requires each new pin mutation-verified.
- AC2 — **FAIL.** Four width figures the rewritten article states are not asserted to match; each was mutated in the real tree and left the suite green (0 failed, 914 passed, tree restored): `all five cells favouring "searle"` → `all nine cells`; `span under half a percentage point` → `under five percentage points`; `On the 64-cell battery` → `32-cell`; `spanning four distribution families` → `six`. Spelled-out numerals are outside the numeral net entirely, and `32` is in the measured pool as the m113 marginal `k = 10` cell count. The table rows, the per-level counts and the M76 prose triple ARE genuinely associated and recomputed — the failure is the figures outside those two shapes.
- AC3 — **pass.** The shipped statement at each of the six reported sites names the ρ shape and the subject-count direction (marker pins green on both legs), no site states a rater-count width effect, the `n = 2`-only-at-`k = 10` assertion is present, and the runtime hint stays width-silent. Recorded against the criterion as written: it constrains the docs plus one named test, both of which hold. The enforcement gaps found this round are logged as findings, not as an AC3 failure.
- AC4 — **FAIL.** The amended criterion's final clause — "a test asserts … that no swept surface states a grid-wide pooled ratio" — has no implementation. Verified in the real tree: inserting into the article "Pooled over the larger grid the median width ratio is 0.9614." (exactly the m113 grid-wide median) leaves the suite green, because `width_sentences()` selects only sentences carrying the literal token `burch`. The first clause (per-ρ figures from M113 alone) and the containment assertion both hold.
- AC5 — **pass.** `testthat::test_file(..., load_package = "installed")` at `NOT_CRAN=true CI=true` on a `build_vignettes = TRUE` install: **0 failed, 0 skipped, 1087 passed**. Corroborated independently by the [O] lens, which ran it and got the same. Both legs walk their domain and assert they reach all six retired hand-list paths and strictly more.
- AC6 — **pass.** Two-sided over squashed text across the six swept files: `about 6% and about 4%` 2 hits on `main` / 0 now; `about 6% narrower` 1 / 0; `shrinks as either grows` 2 on `c63a5fd` / 0 now; `at a low true ICC with few subjects` 3 / 0. The six M116 patterns are preserved verbatim (the diff adds only a trailing comma).
- AC7 — **pass.** `check-mpl-doc-claims.py`, `check-reference-observations.py`, `check-record-claims.py` and `enumerate-generalizing-claims.py --check` all exit 0; two `mpl-doc-claims.tsv` rows and two `generalizing-claims-triage.tsv` rows re-triaged onto the corrected sentences; the D-009 dated observation records the per-factor breakdown and is mutation-discriminating (three separate one-digit moves in the `.tsv` each red it). F16 below is a quality gap in that directive, not a failure of the criterion as written.
- AC8 — **pass.** `air format --check` clean, `lintr::lint_package()` 0 lints, full installed suite 0 failed / 6841 passed / 23 skipped (all `skip_on_ci`) / 2 pre-existing engine fitting warnings.

### Independent review — three lenses, scored

[O] diff-bug: 17 findings. [S] blame-history: 6 items, of which 3 are negative evidence — every R-file change on the branch is comment-only (`git diff main..HEAD -- R/*.R` has no non-comment line), and an independent re-derivation of every stated figure from the fixture found no mismatch at any site. [S] prior-review: all 12 actioned findings from return #1 verified genuinely fixed by independent re-derivation, not taken from the milestone's self-report; the GitHub inline-comment surface is empty, so the thread walk was correctly skipped. Scored by a fresh [S] scorer holding the diff and the plan: 13 findings at or above 80.

**Actioned (>= 80), verbatim:**

- F13 (90) — "`width_expected_source`/`width_expected_installed()` are hand-coded vectors used as the completeness floor, directly contradicting AC2's explicit clause 'the anchors are what the sweep returns, not a remembered list'."
- F11 (90) — "AC1's 'each new `stopifnot` pin is mutation-verified' is false for three M117-added pins." No mutation alters a design-combination set or removes a level, so the two containment pins and the `lvl()` guard structurally cannot fire.
- F1 (88) — "`vignettes/interval-methods.Rmd` says 'the two are separate simulations that differ cell by cell even at the design points they share'." At (ρ=0.05, k=10, n=5) the grids are numerically identical: gaussian `burch_width` 0.448546497847247 in both, t(5) 0.455442806834235 in both. 14 of 16 shared cells differ materially; 2 coincide to ~10 significant digits. A newly-added false claim.
- F14 (87) — "`R/boundary-hint.R`'s width statement has no pin that runs under `R CMD check`." The site is an internal comment and the source leg gates on `data-raw/`, which is `.Rbuildignore`d. Residual of O13 inside the milestone that closed O13.
- F7 (85) — "A grid-wide pooled ratio can be stated on a swept surface and passes." Verified green: "Pooled over the larger grid the median width ratio is 0.9614."
- F9 (85) — "The rater rule does not enforce AC3's 'no site states a rater-count width effect'." Verified green: "The margin is also wider with 10 raters than with 5 raters." — `5 raters` is itself a licensing marker.
- F16 (85) — "The D-009 directive half-settles one stated fact." The paragraph says the largest margin is at 0.1, but the directive checks `lo[1]<lo[0]` and not `lo[1]<lo[2]`; it also settles the marginal-vs-stratified `k = 10` difference for m113 only though the paragraph says both grids.
- F2 (84) — "The AC3 direction-marker pin does not detect a reversed claim." Verified green: `collapses to near parity at 0.6` → `grows far past parity at 0.6`.
- F6 (83) — "The `N of M cells` pin does not check which grid the count is attributed to." Verified green: `59 of 64 cells` → `16 of 16 cells` at both sites, making the text read "16 of 16 cells of the M76 grid and 16 of 16 cells of the M113 one".
- F4 (83) — "The O5 defect can be reintroduced." Reverting "on the one grid reaching a true ICC of 0.6" → "and on both grids at a true ICC of 0.6" reds nothing; the containment test pins the fixture fact but nothing binds the prose to it.
- F3 (82) — "The O4 defect can be reintroduced verbatim in meaning." Verified green: `holds much the same up to a true ICC of 0.3 rather than shrinking as` → `holds up but shrinks steadily as the true ICC rises, so by 0.3 it is far smaller than at 0.05, as`. `claim_patterns$shrinks_in_rho` is an exact string and does not catch the paraphrase.
- F10 (80) — "Several stated quantities are pinned only by pool membership, or not at all." Ten variants pass, four of them re-verified in the real tree this session.
- F8 (80) — "The margin-run floor is per file, so a weakened statement is masked by a sibling in the same file." Replacing `R/icc.R`'s `@param` passage with the pre-M117 wording (which drops the word `margin`, removing the run from `width_claim_runs()`) reds nothing because `@details` satisfies the file.

**Logged, below the action bar (12):** F12 (78, the harness asserts only its control, never that every pin fires; the masked `stopifnot` treats `logical(0)` as passing); F15 (78, the return-#1 Review evidence block is stale and self-contradictory against the return-#1 entry below it); B1 (76, its AC1 line says 10 mutations / 53 pin-reds against the committed harness's 11 / 33); B2 (76, `licensed` matches the bare substring `no rater`, so "there is no rater effect on the width margin" passes as licensed); F5 (75, `NEWS.md` and `R/ci-classical.R` state the ρ shape beside a both-grids attribution — M76 carries no ρ = 0.3 or 0.6, and its two ρ medians run 0.9430 → 0.9453, so "rather than shrinking" is false there); B3 (65, the `data-raw/` gate also skips the source leg in an unpacked source tarball where `R/` and `vignettes/` are present); P2 (45, AC6's two-sided verification is a manual step, not a repeatable test); P1 (45, O12's code-block hazard remains unguarded but dormant); B6 (45, apparatus growth against D-029 — a maintainer judgment); F17 (40, minor bundle: fixture provenance header, redundant allowlist entry, unescaped regex root, a type inconsistency); P3 (25, O19's allowlist unchanged, pre-existing); B4/B5/P0/P4 (20/15/15/10, negative evidence, no defect).

### Consistency gate

`cairn_validate` exit 0 (the two sizing advisories: 8 criteria and 13 tasks against the 7/10 tripwires — a review return's repair load, not a mis-sized cut). `devtools::document()` no diff. `pkgdown::check_pkgdown()` clean. CI fully green on `0183caf`. No `DESIGN.md` principle changed, so `cairn_impact` no-ops.

### Verdict — defect return #2

AC1, AC2 and AC4 fail as written, each verified by command with the tree restored afterwards. Status returns to `in-progress`.

**Thrash trigger (b) fires on AC2.** It failed at return #1 as "the numeral pin is a set-membership test, not an association test" and fails again here as figures outside the two associated shapes going unpinned — a new mechanism of the same shape, which is what (b) names. The alternative the plan gate recorded against is on point: *"chose widening the test's source-tree leg to a directory walk over keeping the six hand-listed paths and **narrowing the promise**"*. The narrow-the-promise half is what has now been declined twice. Trigger (a) has not fired — this is the second defect return, not the third.

---

## Review — pass 3 (2026-08-09)

**PR:** https://github.com/jmgirard/intraclass/pull/126 · CI on `5b55aeb` **fully green**: ubuntu 31m35s, windows 24m41s, test-coverage 21m34s, format-check, lint, pkgdown, check-references, both codecov gates. The `test-coverage` pass settles empirically that the regated source leg does not reopen the `covr` bug that job caught earlier on this branch.

### Evidence per criterion (fresh, this session)

- AC1 — **pass.** The harness now asserts coverage instead of printing it: 14 mutations, 38 distinct pins, control fires nothing, and it exits 0 only when every non-exempt pin has fired. The three pins return #2 found dead (`M76's design is no longer contained in M113's`, `M113 no longer carries design points M76 lacks`, the `lvl()` guard) each fire now. ρ = 0.6 is the only level within 0.01 of parity and its crossing mutation reds both the exact and the direction pin. H1 below is a defect in the exempt list's rationale, not an unverified new pin.
- AC2 — **FAIL, third consecutive round.** The amended criterion says a figure-shaped token outside every canonical shape "fails the test rather than passing unchecked", and that ratio-shaped tokens are "scanned across the whole surface". Neither holds. `width_strip_tables()` is `gsub("\\|(?:[^|]*\\|)+", …)` applied to the whole squashed surface; `[^|]*` matches prose, so the match runs from the first pipe to the last. Measured by this session: it erases **96% of `R/icc.R`** (138283 → 5207 characters) and **50% of the article** (18811 → 9480) before the ratio scan runs. Four further token classes pass unchecked: a spelled cardinal with one intervening adjective (`every cell` → `all nine reversing cells`), a malformed table row, a whole table under an unrecognized header, and any figure equal to an allowlisted value (`5 percentage points`).
- AC3 — **pass.** Every margin-asserting statement on both legs carries all three canonical clauses verbatim, with both true-ICC levels derived from the fixture; the `n = 2`-only-at-`k = 10` assertion is present; the runtime hint stays width-silent. The shipped docs state no rater-count width effect. D3/D4/D5 below are enforcement gaps in the surrounding net, not violations in what ships.
- AC4 — **FAIL on the final clause, second round.** "A grid-wide pooled ratio is barred by AC2's surface-wide ratio scan" is false for the same reason: inserting "Pooled over the larger grid the median width ratio is 0.9614." after the article's last table, or into `R/icc.R`'s roxygen, passes green — the same sentence return #2 used. Placed before the first pipe on a surface it correctly reds, which is what identifies the cause as the table strip rather than the scan. The first two clauses hold: `ratio_rho` matches M113 only, and the containment assertion is present and re-derived.
- AC5 — **pass.** The command the criterion names — `testthat::test_file(..., load_package = "installed")` at `NOT_CRAN=true CI=true` on a `build_vignettes = TRUE` install — gives **0 failed, 0 skipped, 1125 passed**, reproduced independently by the [O] lens. E5 below concerns a different execution context that AC5 does not name, and is recorded as a finding rather than as an AC5 failure.
- AC6 — **pass.** Re-verified over squashed text on the swept surfaces: `about 6% and about 4%` 2 hits on `main` / 0 now; `about 6% narrower` 1 / 0; `shrinks as either grows` 2 on `c63a5fd` / 0; `at a low true ICC with few subjects` 3 / 0. The six M116 patterns are byte-identical.
- AC7 — **pass.** All four checkers exit 0 (79 dated observations, 0 falsified; 343/343 triaged, 0 orphans). The D-009 directive now settles the largest-margin level and the marginal-vs-stratified `k = 10` comparison on both grids; two `mpl-doc-claims.tsv` rows and two `generalizing-claims-triage.tsv` rows re-triaged onto the corrected sentences.
- AC8 — **pass.** `air format --check` clean, `lintr::lint_package()` 0 lints, `pkgdown::check_pkgdown()` clean, `devtools::document()` no diff, `cairn_validate` exit 0, full installed suite 0 failed / 6979 passed / 23 `skip_on_ci`, and the whole CI matrix green on this head.

### Independent review — three lenses, scored

[O] diff-bug: 23 findings, its control run reproducing the milestone's own 1125-passed figure on an isolated copy. [S] blame-history: the removed test blocks are superseded rather than regressed, and an independent from-scratch re-derivation of every figure at every doc site found **no mismatch anywhere**. [S] prior-review: all three of return #2's action-bar findings are closed at the mechanism, not merely at the instance; the GitHub inline-comment surface is empty. Scored by a fresh [S] scorer holding the diff and the amended plan: 9 findings at or above 80.

**Actioned (>= 80), verbatim:**

- D1 (95) — "`width_strip_tables()` is applied to the WHOLE squashed surface. `[^|]*` matches arbitrary prose, so the match runs greedily from the first pipe to the last pipe in the file." Erases 96% of `R/icc.R` and 50% of the article; defeats AC2's surface-wide scan and AC4's final clause with the exact sentence return #2 used.
- D8 (83) — "The `5` allowlist entry launders any figure equal to 5: 'The margin is 5 percentage points wide at every level of both grids.' passes green, and is false (0.29 pp at rho = 0.6)."
- H1 (83) — "The `exempt` list is not honest." Two exempted pins are actually fired by the committed `containment_broken` mutation, and two more are plainly reachable; if a future edit made them dead the coverage assertion would stay silent.
- D2 (82) — "Spelled cardinals escape when an adjective intervenes." `where every cell favouring "searle" sits` → `where all nine reversing cells sit` passes green; the truth is five.
- E5 (82) — "Under `R CMD check` the tests run from `<pkg>.Rcheck/tests/testthat`, whose `../..` has no `R/`, so the source leg returns `list()`." Measured in a synthetic `.Rcheck`-shaped root: 512 passed against 1125 in a source tree — 54% of the file's assertions do not run there.
- D3 (80) — "A run that does not contain the word `margin` or `advantage` is held to no direction template." Appending "The gap between them widens steadily as the true ICC rises…" to the article passes green — the withdrawn claim, reversed, on a user-facing page.
- D6 (80) — "A table row the parser cannot parse is silently skipped, not refused." `| 0.9 (extrapolated) | 0.8000 | 1 of 16 |` passes green.
- E3 (80) — "`width_cardinal_value()` uses `[[`, so an unrecognized word throws `subscript out of bounds` rather than failing." An error aborts the whole `test_that`, dropping the run from 1125 to 994 passed — 131 assertions silently stop running.
- PR-1 (80) — "F14 is not closed and is now MORE exposed: `R/boundary-hint.R` restates the three canonical figures in a plain `#` comment that never reaches the installed help database, while its sibling `R/ci-classical.R` explicitly declines to restate figures for exactly this reason."

**Logged, below the action bar (23):** D4 (78, the templates are necessary but not sufficient — a contradicting sentence may follow one); D7 (78, a whole table under an unrecognized header is invisible); E1 (78, the `level_count` shape is unreachable dead code, consumed first by `k_level`); E4 (76, the heading bound is inert on the source leg because the comment strip removes markdown `##`); D5 (74, a rater-count effect with no number and no "than" passes; `licensed` has no left word boundary); **P2 (73, the flat-to-0.3 clause is stated un-hedged at four sites under a both-grids attribution, and the smaller grid's ρ medians run 0.9430 → 0.9453 — its margin shrinks, the opposite sign)**; E2 (65, a level capture group swallows a sentence-final period); H2 (55, the vacuity fix diverges from real `stopifnot` semantics in the crediting direction); **P1 (50, "the largest margin is at a true ICC of 0.1" is true of the medians but contradicted 11–5 in the paired cells, Wilcoxon p = 0.32)**; E8 (50, a live cairn file now quotes a withdrawn phrase); H3 (45, the label harvester drops short labels); E7 (40, D-029 apparatus growth — 499 → 1559 lines against zero non-comment `R/` changes); B-3 (38, verbatim-template maintainability, no shared constant); P3 (35, "agreeing closely" undersells bit-level identity); E6 (32, 82–132 character lines); B-1 (30, a less specific diagnosis on a fallback path); P4 (30, template-degraded prose); PR-3 (30, return #2's below-bar survivors); B-2 (28, T16's log records no covr reproduction — since settled empirically); PR-2/B-4/PR-4/B-5 (20/15/15/12, negative evidence).

### Consistency gate

`cairn_validate` exit 0 (two sizing advisories). `devtools::document()` no diff. `pkgdown::check_pkgdown()` clean. All four data-raw checkers exit 0. The mutation harness exits 0. No `DESIGN.md` principle changed, so `cairn_impact` no-ops.

### Verdict — defect return #3; thrash triggers (a) and (b) both fire

AC2 and AC4 fail, each inside the domain of the procedure it names, each verified by command with the tree restored afterwards.

**Trigger (a) fires: this is the third defect return.** The rule is a threshold, not a moment — no further retry is queued under the current plan, and the milestone routes through `/milestone-plan` for a re-cut or split.

**Trigger (b) fires again on AC2**, now for the third time and by a third mechanism of the same shape: a figure or a claim reaching a swept surface by a route the guard does not cover. The alternative the plan gate recorded against — *"keeping the six hand-listed paths and narrowing the promise"* — was spent this round, and the narrowed promise failed on the very first mechanism nobody had thought of. That exhausts the recorded alternative, so an escalation via `/milestone-brief` is offered on the underlying question rather than a fourth round of the same work.

What is NOT in doubt: two independent from-scratch re-derivations found every stated figure correct at every doc site, the whole CI matrix is green, and all three of return #2's action-bar findings are closed at the mechanism rather than at the instance.

## Review — pass 4 (2026-08-13, post-re-cut)

**PR:** https://github.com/jmgirard/intraclass/pull/126 (draft) · CI green on `572b8ec` (all nine checks incl. test-coverage); re-polled on the review head `e47c18d` below.

### Evidence per criterion (fresh, this session)

- AC1 — **pass.** Harness fixture leg, fresh run: 14 mutations, 38 distinct pins reddened, control trips nothing, coverage asserted (every non-exempt pin fired, 12 exempt), exit 0.
- AC2 — **pass.** Installed run of the file (`test_dir`, `load_package = "installed"`, `NOT_CRAN=true CI=true`, `build_vignettes = TRUE` install): 0 failed, 1177 passed, 0 skipped — every canonical figure checked against the recomputation. Prose-mutation leg: 18 mutations, each patching a swept surface, ALL refused, control clean, coverage asserted; the class list names each review-return defeat (the three pooled placements included, reddening via the rewritten `width_strip_tables()` segment scanner). Claimed-classes header present, naming checked classes and the not-claimed boundary.
- AC3 — **pass.** Template test green on the installed run: all three canonical clauses verbatim at every margin-asserting run on both legs; per-surface run floors hold; rater forbidden/licensed rules green; the runtime hint stays width-silent.
- AC4 — **pass.** `ratio_rho` checks against M113's medians only; the containment test (M76 ⊂ M113 on (ρ, k, n), strictly) green; the pooled-figure family varies placement (before first table / between tables / running prose), form (4-decimal ratio, digit percentage, spelled percentage) and grid (0.9614 larger, 0.9440 smaller) — each mutation refused in the fresh harness run.
- AC5 — **pass.** The named command on a rebuilt `build_vignettes = TRUE` install: 0 failed, 1177 passed, **0 skipped**.
- AC6 — **pass.** Two-sided, re-verified against the true pre-correction baseline (`dd3038e^`, the branch commit before T11's rewrite — the withdrawn phrasings were this branch's own first pass, so `main` is not the baseline): `shrinks as either grows` 2 pre-correction hits (NEWS, R/icc.R) / 0 corrected; `at a low true ICC with few subjects` 2 verified pre-correction (R/icc.R, glossary) / 0 corrected; withdrawn-claim sweeps green on both legs.
- AC7 — **pass.** All four data-raw checkers exit 0, fresh; the `mpl-doc-claims.tsv` row for the hedged `R/icc.R` sentence re-keyed (full-sentence hash restaled by the AC9 hedge, M105); `check-reference-observations.py` green over the references page's dated observations.
- AC8 — **pass.** `air format --check` clean; `lintr::lint_package()` 0 lints; installed suite 0 failed / 0 errors / 7031 passed / 23 skipped (all `skip_on_ci`) at `NOT_CRAN=true CI=true`.
- AC9 — **pass.** The hedge clause verbatim at all seven statements (grep: R/icc.R ×2, R/ci-classical.R, R/boundary-hint.R, glossary, interval-methods, NEWS; man/icc.Rd ×2 regenerated); the direction pin recomputes both facts (m113 sub-parity spread < 0.005; m76's median ratio rises across its levels); the largest-margin sentence states its cut, checked by `argmax_cut` against the medians with `argmax_bare` failing any unqualified form and `paired_cells` recomputing 11 of 16; the three restoration mutations (hedge dropped, cut dropped, paired count swapped) each refused.
