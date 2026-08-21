<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M129: Back the hand-pasted engine transcripts in the vignettes

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m129-vignette-brms-transcripts   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [ ] AC1: A seeded, committed `data-raw/` script generates a committed fixture
      under `tests/testthat/fixtures/` holding the brms fit(s) the vignettes'
      pasted blocks display, and `brms_oracle_map`
      (`tests/testthat/test-brms-oracle-map.R:17`) carries the script↔fixture
      pair — that guard's two-sided `expect_setequal` (`:55`, `:58`) fails when
      either side is missing.
- [ ] AC2: Every line that `grep -rnE '^[[:space:]]*#>' vignettes/` returns
      belongs to a fenced block that a test renders from the committed fixture
      and compares to the vignette source verbatim, as a whole block.
- [ ] AC3: Every line containing a digit that
      `sed -n '124,/^## /p' vignettes/engines.Rmd | grep -nE '[0-9]'` and
      `sed -n '307,/^## /p' vignettes/interval-methods.Rmd | grep -nE '[0-9]'`
      return, excluding the fenced blocks AC2 pins, states either no figure
      about brms output or a figure agreeing with those blocks as shipped.
- [ ] AC4: For each block AC2 pins, a planted edit of each of these forms reds
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
- [ ] T5: Prose read of the two brms sections; reconcile every digit-bearing
      prose line against the corrected blocks.
- [ ] T6: Planted-defect runs (AC4) and the full gate-lite sweep (AC5).

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

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
