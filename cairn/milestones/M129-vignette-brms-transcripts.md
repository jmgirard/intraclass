<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M129: Back the hand-pasted engine transcripts in the vignettes

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m129-vignette-brms-transcripts · https://github.com/jmgirard/intraclass/pull/138   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

Make every hand-pasted brms output block in the vignettes reproducible from a
committed fixture, so a stale transcript reds instead of shipping to CRAN.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing** — the deliverable is vignette content readers see
and copy.

**In:** the four `eval = FALSE` brms chunks and the 38 hand-pasted `#>` output
lines they display (`vignettes/engines.Rmd:141,178`;
`vignettes/interval-methods.Rmd:321,352`); a seeded `data-raw/` script and a
committed fixture holding the brms fit(s) those blocks show — no existing
fixture does, `bayesian-oracle.rds` being a 500-rep coverage simulation on a
30-subject DGP, not a `ratings` fit; a verbatim whole-block pin per block;
correcting any block the fixture falsifies; a prose read of the two brms
sections while there.

**Out:** the rest of `interval-methods.Rmd`'s claims → M130; brms on CI → not
attempted, the M52 offline-fixture constraint stands; regenerating any other
`bayesian-*-oracle.rds` → out, no evidence asks for it.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: A seeded, committed `data-raw/` script generates a committed fixture
      under `tests/testthat/fixtures/` holding the brms fit(s) the vignettes'
      pasted blocks display, and `brms_oracle_map`
      (`tests/testthat/test-brms-oracle-map.R:17`) carries the script↔fixture
      pair — that guard's two-sided `expect_setequal` (`:55`, `:58`) fails when
      either side is missing.
- [x] AC2: Every line that `grep -rnE '^[[:space:]]*#>' vignettes/` returns
      belongs to a fenced block that a test renders from the committed fixture
      and compares to the vignette source verbatim, as a whole block.
- [x] AC3: Every line containing a digit that
      `sed -n '124,/^## /p' vignettes/engines.Rmd | grep -nE '[0-9]'` and
      `sed -n '307,/^## /p' vignettes/interval-methods.Rmd | grep -nE '[0-9]'`
      return, excluding the fenced blocks AC2 pins, states either no figure
      about brms output or a figure agreeing with those blocks as shipped.
- [x] AC4: For each block AC2 pins, a planted edit of each of these forms reds
      the test: a changed digit, a changed word of message text, a removed
      line, and an added line. Each planted run is recorded in the work log.
- [ ] AC5: `NOT_CRAN=true CI=true devtools::test()` 0 failures;
      `air format --check .` clean; `R CMD check`'s raw `Status:` line no worse
      than main's (read the raw line, never `devtools::check()`'s 0/0/0
      summary — M127/M128 lesson); `pkgdown::check_pkgdown()` clean;
      `cairn_validate` exit 0.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T5
- AC4 → T6
- AC5 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Write the seeded `data-raw/` script fitting `ratings` with
      `engine = "brms"` at the vignettes' own arguments (`type = "agreement",
      seed = 1`, and the custom-`prior` call at `vignettes/engines.Rmd:178`);
      record its brms settings; commit the fixture. Follow `data-raw/README.md`'s
      fixture lifecycle.
- [x] T2: Add the script↔fixture pair to `brms_oracle_map` and to the
      `data-raw/README.md` table the same guard pins.
- [x] T3: Write whole-block verbatim pins in a new
      `tests/testthat/test-vignette-transcripts.R`; run RED first against a
      deliberately wrong block before making it green.
- [x] T4: Reconcile — correct every vignette block the fixture falsifies,
      correcting the vignette and never the fixture; log each before/after value.
- [x] T5: Prose read of the two brms sections; reconcile every digit-bearing
      prose line against the corrected blocks.
- [x] T6: Planted-defect runs (AC4) and the full gate-lite sweep (AC5).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-21: created by /milestone-plan (pre-M48 CRAN-readiness slate; user selected this item at the plan gate).
- 2026-08-21: criteria audit ran in FULL mode (user-facing tier), two rounds, fresh-context [O] reader both times. Round 1 returned findings on AC2 (grep proxy: `^#>` misses indented prefixes), AC3-as-drafted (universal over "figures" with no enumerator, plus a records-property clause), AC4-as-drafted (two section headings cited that do not exist as written). Round 2 returned one further finding: AC3's `grep -nE '[0-9]' ` had no file operand and would block on stdin. All fixed before writing; drafted AC3 (reconciliation direction) was demoted to the T4 scope rule as an instrument/records property under D-118.
- 2026-08-21: plan gate chose generating a new `ratings` brms fixture over pinning to an existing `bayesian-*-oracle.rds`, because no committed fixture holds a `ratings` fit (`bayesian-oracle.rds` is a 500-rep coverage sweep, n_subjects=30, s2_s=0.5); falsified by an existing fixture being found to reproduce the pasted blocks.
- 2026-08-21: plan gate chose pinning the transcripts over deleting them or softening them to prose, because the blocks teach what the brms engine returns and M124 established that showing the surface is the point; falsified by the fit proving irreproducible across platforms at the tolerance a verbatim pin needs.
- 2026-08-21: T1 done — `data-raw/oracle-bayesian-vignette.R` fits the two vignette calls (26.5 s and 23.6 s on R 4.6.1 / brms 2.23.0 / rstan 2.32.7) and captures the custom-prior warning by unwinding out of its handler, which needs no Stan run because the warning fires in `icc()`'s argument handling before the fit is built. Fixture `bayesian-vignette-oracle.rds` is 1.3 KB, in line with its 0.8-3 KB siblings.
- 2026-08-21: T1 measurement — a whole brms `icc` object serializes to 3.96 MB and 1.61 MB with `$fit` removed; per-element serialized sizes are `$mc` 1,649,452 B and `$fit` 1,436,432 B (both carrying environments), against 328 B for the largest render-bearing element. The eight elements `format.icc()` reads total ~1.4 KB, so the fixture stores only those. `tests/` ships inside the CRAN tarball, so a whole-object fixture was never viable.
- 2026-08-21: T1 defect found and fixed in this milestone's own script — the strip guard `stopifnot(identical(render(out), render(x)))` PASSED VACUOUSLY: `print.icc()` emits through `cli_verbatim()` and `utils::capture.output()` returns `character(0)` for cli's output connection, so both sides were empty. Switched to `cli::cli_fmt()` and added an explicit `length(full) > 0L` anti-vacuity assertion.
- 2026-08-21: T2 done — `brms_oracle_map` and the `data-raw/README.md` table both gain the pair; the guard's globs (`^oracle-bayesian.*\.R$`, `^bayesian-(.*-)?oracle\.rds$`) forced the naming. `python3 data-raw/check-reference-observations.py` exit 0 (85 observations, 0 falsified): the new script names no citekey token, so the M86 settling-directive trap does not fire.
- 2026-08-21: T3 done — `tests/testthat/test-vignette-transcripts.R` enumerates every maximal run of `#>` lines across `vignettes/*.Rmd` rather than a hand-list of locations (the M118 lesson), and asserts in both directions, so a newly pasted unpinned block and a deleted transcript each fail. 13 assertions pass.
- 2026-08-21: T3 two rendering facts the plan did not know. (a) testthat runs cli in ASCII mode, so a pin fixing only the width compares the vignette's `──` against a rendered `--`; the fixture now carries the whole render-option set (width, `cli.unicode`, `cli.condition_unicode_bullets`, `cli.num_colors`). (b) cli formats a condition's message when the condition is CREATED, not when it is rendered, so the options must wrap the `icc()` call — wrapping `rlang::cnd_message()` changes nothing.
- 2026-08-21: T3 deliberate narrowing — the LIVE custom-prior warning check compares whitespace-normalized text, not the wrap column, because where rlang breaks lines depends on the rendering context even at a fixed width (the M93 format_inline/format_message distinction). The vignette-vs-fixture comparison stays verbatim; only the extra live drift-guard is normalized.
- 2026-08-21: T4 done — reconciliation found the three `icc()` transcripts already exact against a fresh fit on a new machine (nothing stale), and ONE real discrepancy in the custom-prior warning block: `vignettes/engines.Rmd` pasted ASCII `i` bullets on two lines where the package emits Unicode `ℹ` (its `!` bullet already matched). Corrected the vignette, not the fixture: `#> i A vague or flat SD prior...` -> `#> ℹ A vague or flat SD prior...` and `#> i Leave \`prior\` unset...` -> `#> ℹ Leave \`prior\` unset...`.
- 2026-08-21: implement gate chose, per the maintainer's three answers — re-render the stored fits through the package's CURRENT `print()` (over storing rendered text, which would pin only that two frozen files agree); pin the custom-prior warning from the fixture AND additionally assert the live render (over a live-only pin needing an AC2 amendment); and add a prose note that sampler divergences are omitted (over pasting a seed- and platform-dependent divergence count into the blocks).
- 2026-08-21: T5 done — AC3's two sweeps return 16 digit-bearing lines (9 in `engines.Rmd`'s brms section, 7 in `interval-methods.Rmd`'s posterior section). Ten are citation years/sections or code inside the chunks; six state figures, and all six agree, verified mechanically rather than by eye: brms MAP ICC(A,1) 0.241 -> "about 0.24"; glmmTMB REML ICC(A,1) 0.290 -> "(0.29)"; MAP below REML (0.241 < 0.290); HPDI [0.040, 0.601] -> "[0.04, 0.60]"; percentile [0.066, 0.649] -> "[0.07, 0.65]"; HPDI no wider than percentile (width 0.561 vs 0.583).
- 2026-08-21: T5 prose read — added the maintainer's chosen divergence note to `vignettes/engines.Rmd` (both fits emit "There were 1 divergent transitions after warmup" and "Examine the pairs() plot", which the blocks do not show); no count is stated, since divergences are seed- and platform-dependent.
- 2026-08-21: T5 prose read, out-of-AC finding VERIFIED not changed — `engines.Rmd`'s "collapsing the ICC to nearly nothing" describes a fit whose output no block shows, so no criterion reaches it and the fixture cannot check it (the generator unwinds before that fit completes). Ran it once: with `normal(0, 0.1)` the subject and rater components are both exactly 0 and all four ICCs are 0 (intervals [1.29e-06, 0.00798] and [5.14e-06, 0.0312]). The claim is true and if anything understates. Permanently backing it would need a third Stan fit and an AC2 widening; left as prose, offered to the review as a candidate row.
- 2026-08-21: T6 done — AC4's matrix is 16 plants (4 blocks x 4 forms: changed digit, changed word, removed line, added line). Baseline GREEN, all 16 RED, `git status vignettes/` clean afterwards with no residue.
- 2026-08-21: T6 DEFECT IN THIS MILESTONE'S OWN GUARD, found by the gate and fixed — the first `R CMD check --as-cran` returned `Status: 1 ERROR`, worse than main's `1 NOTE`. `R CMD check` runs the suite against the INSTALLED package, where `../../vignettes` does not exist, so `list.files()` returned empty and `readLines()` errored: four failures and the ERROR from one cause. The pins written to protect the vignettes would have turned CI red. Fixed with the repo's existing idiom (`test-brms-oracle-map.R` skips the same way when `data-raw/` is absent) and the resulting coverage limit written into the test header: the guard bites on local `devtools::test()`, at the review gate, and in the coverage job (which runs from source), but NOT inside the CI `R CMD check` job.
- 2026-08-21: AC5 evidence — `NOT_CRAN=true CI=true` full suite FAIL 0 / ERROR 0 / PASS 8263 (main: 8250; the 13 new assertions account for the difference); `air format --check .` clean; `pkgdown::check_pkgdown()` "No problems found"; `cairn_validate` exit 0 on all 16 checks; `R CMD check --as-cran` at `NOT_CRAN=false` **Status: OK** with `Running 'testthat.R' [245s/123s] OK`. Note for review: `OK` beats main's recorded `1 NOTE`, but the two were measured at different `NOT_CRAN` settings — main's NOTE is the `spelling.Rout` diff, which only fires under `NOT_CRAN=true` (M128 lesson); `OK` cannot be worse than any baseline, so the criterion holds either way.
- 2026-08-21: review checkpoint — AC1-AC4 verified with fresh evidence; AC5 partial (suite re-run and post-fix CI in flight). Fix-now: the CI `lint` failure this gate found (UPPER_CASE constants, renamed to snake_case, fixture byte-identical after regeneration) and blame-history F1 (`data-raw/README.md:86` "15 of 20" -> "15 of 21", stale from this milestone's 21st script). F2 (Unicode bullets vs M35's recorded ASCII choice) and F3 (map widening) go to the maintainer at the approval gate.

- [O] diff-bug F1 -- FIXED NOW. Blocks were matched as an unordered multiset, so swapping `interval-methods.Rmd`'s percentile and HPDI blocks left the multiset unchanged and the suite green, showing HPDI numbers under a percentile call. Verified the premise (the two files' first blocks are byte-identical, so equality matching cannot distinguish position), rewrote to per-file ORDERED matching, planted that exact swap and confirmed it now reds.
- [O] diff-bug F2 -- FIXED NOW. `tryCatch(error = function(e) NULL)` swallowed every error, so renaming the `intraclass_custom_prior` class would have let `icc()` proceed to a live Stan compile inside the suite, reported as "cond is NULL". Both test and generator now re-raise anything that is not their own sentinel.
- [O] diff-bug F3 -- FIXED NOW. The test enumerated vignettes with a non-recursive, case-sensitive `list.files()` while AC2's domain is a recursive grep; a `vignettes/children/*.Rmd` or `*.Rmd.orig` would have escaped the pin. Now `recursive = TRUE`, `\\.[Rr]md$`.
- [O] diff-bug F4 -- FIXED NOW, and it is a CONSISTENCY-GATE MISS from the implement phase, not a lens nicety: the profile's gate slot requires a `NEWS.md` entry for user-visible changes and this diff ships vignette prose. Added under `## Documentation`, no milestone numbers in user-facing text.
- [O] diff-bug F6 -- FIXED NOW. Missing `skip_if_not_installed("withr")`.
- [O] diff-bug F5/F7 -- FIXED NOW (comment accuracy). The header claimed the test matches every line against a rendered transcript, untrue of the `Warning message:` banner (R's console framing, a literal in both article and expectation); and the wrap comment overstated what is pinned, since both compared artifacts are frozen. Both reworded to state the real limit.
- [O] diff-bug F8 -- LOGGED, no change. The eight-element strip is verified in the generator, not the suite; a future ninth element read by `format.icc()` would red with a confusing transcript diff rather than a clear message. Fail-loud, so a note.
- [O] diff-bug F9 -- LOGGED (stated here at the lens's request). The pins do not run inside the CI `R CMD check` job; coverage is local `devtools::test()`, this review gate, and the source-run coverage job.
- [O] diff-bug F10 -- LOGGED. `engines.Rmd`'s "collapsing the ICC to nearly nothing" remains unbacked by any criterion or fixture; verified once by hand this milestone (components exactly 0). Offered to the maintainer as a candidate row.
- [O] diff-bug F11 -- RESOLVED. Working-tree drift versus HEAD; the rename was committed at f4fd05b.

### Post-fix verification (2026-08-21)

`air format --check .` clean; `lintr::lint_package()` 0 lints; AC4 plant matrix re-run against the REWRITTEN test 16/16 RED with 0 probes failing to bite; full suite `NOT_CRAN=true CI=true` FAIL 0 / ERROR 0 / SKIP 25 / PASS 8263; `cairn_validate` all checks passed. The F1 swap probe (not part of the 16) reds on the rewritten test and passed on the old one.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

### Acceptance-criteria evidence (fresh, 2026-08-21)

- AC1 — VERIFIED. `data-raw/oracle-bayesian-vignette.R` (199 lines) is committed and seeded (`fit_seed <- 1L`); `tests/testthat/fixtures/bayesian-vignette-oracle.rds` is 1.3 KB. `test-brms-oracle-map.R` passes 5 assertions including both `expect_setequal` directions. Regenerating after the lint rename produced a BYTE-IDENTICAL fixture (`cmp` clean; `fits`, `custom_prior_warning`, `render_options` all `identical()`), so the generator is deterministic on a fixed seed.
- AC2 — VERIFIED. `grep -rnE '^[[:space:]]*#>' vignettes/` returns 38 lines (engines.Rmd 18, interval-methods.Rmd 20) and every one falls in a block the test compares whole against a re-render; `test-vignette-transcripts.R` passes 13 assertions. (A first count of 37 was taken while the AC4 plant matrix had a line temporarily deleted; re-measured on a stable tree it is 38.)
- AC3 — VERIFIED. The two sweeps return 16 digit-bearing lines outside the pinned fences. Ten carry no figure about brms output (citation years/sections, chunk code). The six that do were re-checked mechanically and all agree: MAP 0.241 -> "about 0.24"; glmmTMB REML 0.290 -> "(0.29)"; MAP < REML; HPDI [0.040, 0.601] -> "[0.04, 0.60]"; percentile [0.066, 0.649] -> "[0.07, 0.65]"; HPDI width 0.561 <= percentile 0.583.
- AC4 — VERIFIED. Plant matrix re-run fresh: baseline GREEN, 16/16 plants RED (4 blocks x changed digit, changed word, removed line, added line), `git status vignettes/` clean afterwards.
- AC5 — PARTIAL at this checkpoint. `cairn_validate` exit 0 (all checks passed); `air format --check .` clean; `devtools::document()` no diff; `pkgdown::check_pkgdown()` "No problems found"; `lintr::lint_package()` 0 lints; all four `data-raw` checkers exit 0. `R CMD check --as-cran` at `NOT_CRAN=false` returned raw `Status: OK` (implement phase, pre-rename). Full-suite re-run and post-fix CI still in flight.

### Consistency gate

`cairn_validate` exit 0. Toolchain slot: `devtools::document()` no diff; generated files unedited; `pkgdown::check_pkgdown()` clean; `air format --check` clean; `lintr::lint_package()` 0 lints. NEWS.md: no entry -- see finding F4 below, pending triage.

### Findings (independent fresh-context review, 3 lenses)

- [S] prior-PR-comments lens: NO prior-review regression. GitHub inline-comment probe returned `[]`, so the archive was the primary surface; M52's guard-vacuity fix, M118's no-hand-list lesson and M127/M128's raw-Status lesson are all honored rather than unlearned.
- [S] blame-history F1 -- FIXED NOW. `data-raw/README.md:86` read "the long-sweep scripts (15 of 20)"; this milestone's 21st script made it stale. Verified independently (21 scripts match the guard glob, 15 contain checkpoint logic, the new one does not) and corrected to "15 of 21". Not a registered `record-claims` row, so no checker would have caught it.
- [S] blame-history F2 -- MAINTAINER CALL, surfaced at the gate. The ASCII->Unicode bullet correction overturns a choice M35 recorded in its commit message ("cli glyphs shown in ASCII fallback", d69f39e).
- [S] blame-history F3 -- surfaced at the gate. Adding a vignette-transcript fixture to `brms_oracle_map` widens a map M52 built for coverage/bias oracles.
- CI lint failure (found by this gate, not by a lens) -- FIXED NOW. `lintr::lint_package()` rejected four UPPER_CASE constants in the new generator; every sibling oracle script uses snake_case and `.lintr`'s UPPER_CASE exclusion covers only `data-raw/reviews`. Renamed to `fit_seed`/`out_path`/`render_options`/`render_elements` rather than widening the exclusion; 0 lints, fixture byte-identical.

