# M117: State the `"burch"`/`"searle"` width relationship conditionally

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
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
      stated figure is a grid-wide median pooling ρ and `k` together — every
      figure is cut at one level of one factor. A test asserts the two grids'
      `(ρ, k, n)` design-combination sets stand in the containment M76 ⊂ M113
      that made the pooled figure misread as a between-grid difference, and that
      no swept surface states a grid-wide pooled ratio.
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
- [ ] AC7 `check-mpl-doc-claims.py`, `check-reference-observations.py`,
      `enumerate-generalizing-claims.py --check` and `check-record-claims.py`
      each exit 0 on the final tree, with `mpl-doc-claims.tsv` re-triaged for
      every sentence changed inside the blocks it keys, and
      `cairn/references/classical-oneway-comparison.md` recording the per-factor
      breakdown under a D-009 dated observation.
- [x] AC8 The profile's verify slot is clean: `air format --check`,
      `lintr::lint_package()`, and the installed-package suite at
      `NOT_CRAN=true CI=true`.

## Coverage

- AC1 → T1
- AC2 → T3, T5, T9, T10, T11
- AC3 → T3, T5, T10, T11
- AC4 → T3, T5, T9, T10, T11
- AC5 → T2
- AC6 → T6
- AC7 → T7, T12
- AC8 → T8, T13

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

Review return #1 repair:

- [x] T9 Generator: a `k_at_n5` factor cut (subject count at 5 raters, the only
      rater count present at every subject count) replacing the confounded
      marginal `k` rows as what the docs quote; regenerate; pin the new rows and
      the flat-below-0.6 ρ shape; commit the mutation harness.
- [ ] T10 Rewrite the test's width apparatus: a level↔figure ASSOCIATION pin
      (not set membership) run over the installed surfaces as well as the source
      tree, a discriminating conditional-statement pin, a fixed-stratum rater
      rule in place of the blanket rater ban, anti-vacuity floors at the
      measured site count.
- [ ] T11 Correct the prose at the six reported sites: the ρ shape is
      flat-then-collapse, not shrinking; the subject-count figures are the
      5-rater ones; ρ = 0.6 is attributed to M113 alone; the grid-containment
      claim is bounded to what it explains; the figures move out of
      `R/ci-classical.R` into the article.
- [ ] T12 Extend the D-009 directive to settle every figure and fact the
      references paragraph states; re-triage the ledgers; four checkers green.
- [ ] T13 Full gate and push: air, lintr, `pkgdown::check_pkgdown()`,
      installed-package suite at `NOT_CRAN=true CI=true`, CI matrix.

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
- 2026-08-09: amendment return: AC4 — "no stated figure is a grid-wide median pooling ρ and `k` together — every figure is cut at one level of one factor"; the original second clause forbade pooling over ρ OR over `k`, which every per-factor cut necessarily does (review O15). Gate chose the rewrite over keeping wording no work could satisfy.
- 2026-08-09: gate chose recomputing the subject-count figures at 5 raters (0.9154/0.9646/0.9769 on M113, 0.9017/0.9611/0.9775 on M76) over keeping the marginal ones with a caveat or dropping them, because k = 10 is the only subject count carrying n = 2 and the marginal cut repeats one level down the confounding the milestone used to refuse a rater claim (review O6); falsified by a grid balancing the rater count across subject counts.
- 2026-08-09: gate chose moving the stated figures out of `R/ci-classical.R`'s internal comment into the article over keeping them beside the code, because an internal comment is not in the built package, so every pin over it skips under `R CMD check` (review O13); falsified by a figure that has no installed surface to live on.
- 2026-08-09: T9 — `k_at_n5` factor rows (both grids, 3 levels each) added through the same `width_summary()` core; 12 new pins plus a structural pin that the marginal and 5-rater k cuts coincide at k = 30/50 and differ at k = 10. Mutation harness now committed (`data-raw/m117-width-pin-mutations.R`, review O18): 11 mutations red 33 distinct pins between them, every new pin fires on at least one, unmutated control fires none.
- 2026-08-09: plan gate read D-012 Amendment 1's reopening clause ("a grid on which Burch's median width exceeds SEARLE's") as not tripped by the ρ=0.6/`k`=50 region's 1.0015 median, the clause being scoped to whole grids and M76 carrying no reversal; no D-012 Amendment 2. Falsified by a whole committed grid whose median ratio exceeds 1.

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
