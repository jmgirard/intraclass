# M105: Non-finite input and the zero-between-variance Burch interval fail classed, never raw and never silently

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP7
- **Branch/PR:** `m105-degenerate-input-and-burch-guards` / https://github.com/jmgirard/intraclass/pull/113

## Goal

On any data a user can supply, `icc()` either returns finite ordered endpoints
or raises a condition inheriting `intraclass_error` — never a bare
`simpleError` from an engine, and never a silent `NaN` interval.

## Scope

**In:** the three measured defects and their two root causes.
(a) A non-finite `score` (`Inf`/`-Inf`/`NaN`) reaches the engine and surfaces its
raw, engine-specific `simpleError` on all four `model` × `engine` combinations —
`negative log-likelihood is NaN at starting parameter values` (glmmTMB),
`NA/NaN/Inf in 'y'` (lme4). Rejected at input validation, before any fit.
(b) An `NA` score reaches the engine too and produces a classed but misleading
abort; rows are dropped instead, with a classed warning, and the remainder
analysed through the existing incomplete-design path.
(c) `ci_method = "burch"` on exactly-zero between-subject variance: `burch_kappa_hat()`
divides by `sqrt(MSA)` (`R/ci-classical.R:146`), so κ̂ is `NaN` and both endpoints
follow. At `unit = "average"` that `NaN` hits `!any(denom < 0)` in
`npb_guard_sb_pole()` (`R/ci-npbootstrap.R:135`) and raises a bare `simpleError`;
at `unit = "single"` the guard returns early and the `NaN` interval ships silently.
Plus the D-entry and `DESIGN.md` boundary row that D-004 requires for the change.

**Out:** `searle` returning `-Inf`/`-Inf` on the same data → stays as-is; the
in-place comment at `R/ci-npbootstrap.R:126` records it as the correct limit,
in-support for the projected form under D-010. Making `npb_guard_sb_pole()`
refuse the exact pole (`denom == 0`) → stays as-is, same comment, and pinned by
`tests/testthat/test-boundary-abort-hint.R:2240`; reopening either takes a
D-entry superseding D-010 and reaches all three methods sharing that guard —
both left at the M105 plan gate (2026-08-05), promote on a user report.
The other four `ci_method` values on zero-between-variance data → already classed;
candidate row if one is ever measured otherwise. The M104 fixture-guard
hardening candidate → unrelated, stays a candidate row.

## Acceptance criteria

- [ ] AC1. For each case its test loops over — the four pairs of
      `model` ∈ {`"oneway"`, `"twoway"`} × `engine` ∈ {`"glmmTMB"`, `"lme4"`},
      each with `Inf`, `-Inf`, and `NaN` in turn placed in `score` — `icc()`
      raises a condition inheriting `intraclass_error` whose message names the
      `score` column and the offending row positions.
- [ ] AC2. `icc()` drops rows whose `score` is `NA` before fitting and emits a
      condition inheriting `intraclass_warning` naming the number dropped; on a
      frame whose NA removal leaves a connected two-way design, the returned
      estimate and both endpoints are `identical()` to those from the same call
      on a frame with those rows physically absent; and on a one-way frame with
      a missing score, the `ci_method` values reachable after the drop are
      exactly those the resulting unbalanced design supports — `searle` and
      `burch` refused by their existing balance fence with
      `intraclass_unsupported`, `npbootstrap` and `montecarlo` each returning an
      interval — asserted by a test enumerating those four.
- [ ] AC3. For each case its test loops over — the four committed
      zero-between-variance fixture cells (6×3, 10×2, 20×3, 8×4 from `gen_ssa0`)
      × `unit` ∈ {`"single"`, `"average"`} — `icc(..., ci_method = "burch")`
      matches that case's committed expectation, each of which is either a
      condition inheriting `intraclass_error` whose message names zero
      between-subject variance as the cause, or finite endpoints with
      `conf.low <= conf.high`. The three cells whose MSA is `identical(., 0)`
      (6×3, 10×2, 20×3) carry the abort expectation; 8×4, whose MSA is 3.5e-33,
      carries the finite one.
- [ ] AC4. Over that same eight-case enumeration, `ci_method = "searle"` returns
      what it returns on `main` today, asserted against endpoint values recorded
      from `main` in T1 before any source change.
- [ ] AC5. `cairn/DECISIONS.md` gains an entry recording the exported-contract
      change, listing exactly the refusals AC1–AC3 introduce and no others, and
      `cairn/DESIGN.md § Boundary-fit policy`'s interval-time table gains a
      classical-family (SEARLE/Burch) row citing it as classed deferral.
- [ ] AC6. The `verify` slot is clean (`devtools::test()`, `devtools::document()`),
      and all three `data-raw` checkers pass locally
      (`check-reference-observations.py`, `enumerate-generalizing-claims.py --check`,
      `check-mpl-doc-claims.py`). Each line this milestone adds to `NEWS.md`,
      enumerated by `git diff <default-branch>..HEAD -- NEWS.md` restricted to
      added lines, names in the work log a `file:test-name` the log records red
      before the change and green after.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T3
- AC3 → T1, T4
- AC4 → T1, T5
- AC5 → T6
- AC6 → T5, T6

## Tasks

- [x] T1. Tests first. Commit the four `gen_ssa0` cells as a fixture with their
      MSA values and per-case expectations; record `searle`'s current endpoints
      on all eight cases from `main` (AC4's baseline). Add the non-finite, NA,
      and Burch cases to `tests/testthat/test-icc-errors.R` and assert each one
      red against current behavior before any source change.
- [x] T2. Classed abort for non-finite `score` in `icc()`'s canonicalization,
      before `summarize_design()` (`R/icc.R:1170`) and before any engine call, so
      it is engine-independent; message names the column and the row positions.
- [x] T3. Drop `NA`-score rows at the same site with a classed
      `warn_intraclass()` naming the count, then let the existing
      incomplete-design path handle the remainder. Confirm the existing
      connectivity and per-subject guards still fire when a drop leaves the
      design unidentified. (RB tripwire: irreversible-api)
- [x] T4. Guard `burch_ci()` on `identical(ss$msa, 0)` before `burch_kappa_hat()`
      (`R/ci-classical.R:191`) with a classed abort naming the cause, threading
      the M103 runtime `hint` already carried by the sibling guard at
      `R/ci-classical.R:61`; GP7 in-place comment naming the new D-entry.
- [x] T5. Run the AC4 `searle` pin and the full `devtools::test()`; confirm no
      other reducer's behavior moved on the fixture cells.
- [x] T6. D-entry, `DESIGN.md` boundary-table row, `NEWS.md`, roxygen for the
      new input contract; re-run all three `data-raw` checkers (M85/M97/M104 —
      a locally-green gate has reddened `check-references` in CI three times).

## Work log

- 2026-08-05: created by /milestone-plan.
- 2026-08-05: plan gate chose a classed abort for Burch at MSA = 0 over returning the estimator's attained floor because that number comes from SEARLE's formula, not Burch's (IP1, #4), and over warn-plus-NaN because a bad endpoint still flows downstream (#5, the ground D-019 rejected the same option on); falsified by a Burch-family source deriving a defined limit at MSA = 0.
- 2026-08-05: plan gate chose dropping NA-score rows with a classed warning over rejecting them outright because absent ratings are already a supported incomplete design, and the two spellings should not diverge; falsified by a case where dropping leaves a design that fits without aborting yet answers a different estimand than the user asked for.
- 2026-08-05: plan chose input-side validation over wrapping the engine error in a classed condition because the raw message differs per engine (glmmTMB vs lme4 measured) and a wrapper would have to match on text; falsified by an engine whose non-finite failure is not reachable before the fit.
- 2026-08-05: criteria audit ([O], fresh context) returned findings on five of six drafted criteria. Two verified against source and actioned as scope cuts: the exact-pole and `searle` `-Inf` behaviors are recorded deliberate decisions (`R/ci-npbootstrap.R:126`, D-010) — dropped to Out. Three actioned as wording fixes: `boundary_interval_usable()` replaced by a directly stated finite-and-ordered condition (the predicate is M93/D-018's is-it-worth-naming test and deliberately rejects the attained floor MSA = 0 produces, `R/boundary-hint.R:86`); the `searle` criterion recast as a regression pin; the NEWS criterion's unverifiable mutation claim replaced by the red-then-green work-log record.
- 2026-08-05: T1 red-before-fix recorded. `test-icc-errors.R` FAIL 8 + ERROR 1 (non-finite score on all 12 model x engine x value cases; the column/row-naming message; the NA-drop warning class and the three identical() comparisons). `test-degenerate-classical.R` FAIL 2 (burch at 6x3 unit=single returns NaN silently, so no condition is raised to classify). Fixture `degenerate-classical-cells.tsv` written from `main` before any source change; 6 of 8 rows have MSA identical(.,0), 2 do not.
- 2026-08-05: T2 + T3 code landed, their own tests green (test-icc-errors.R FAIL 0 PASS 29). Tasks NOT yet checked off: the full suite reds 13 assertions in test-boundary-abort-hint.R, whose NA-scored fixture cells were built on the premise T3 removes. Measured consequence on a one-way frame with one NA score: before, the NA row counted as an observed cell so the design looked balanced and searle/burch/npbootstrap all aborted inside their extractors; after, the design is genuinely unbalanced, searle/burch are refused up front by their balance fence (intraclass_unsupported) and npbootstrap returns an interval. Wider than AC2 describes -- gated.
- 2026-08-05: T2 implementation note -- `is.na(NaN)` is TRUE in R, so the first draft's `!is.na()` filter routed every NaN into the drop branch and reported a number for a corrupt score; the split is now written explicitly with `is.nan()` on both sides.
- 2026-08-05: AC2 amended via the implement gate -- added the availability clause after measurement showed the drop changes which `ci_method` values are reachable, which the plan did not anticipate. Amended text shown verbatim in chat before this commit.
- 2026-08-05: amended the one-way NA-scored cell in test-boundary-abort-hint.R ("a missing score silences every row"). Its forbid/candidates lists encoded that an NA row fences searle/burch/npbootstrap out; after T3 the design is unbalanced, so npbootstrap is genuinely usable and searle/burch are genuinely design-fenced. Lists corrected to the measured truth, not relaxed. The `expect_identical(fenced_named(r_ow), 0L)` line flips to `expect_gt(..., 0L)`: it only ever counted whether the fenced tier fired, and the property that no UNUSABLE method is named stays enforced by the unchanged per-seed `named == usable` assertion. The two-way cell is unmoved.
- 2026-08-05: T2/T3 green -- test-icc-errors.R FAIL 0 PASS 37, test-boundary-abort-hint.R FAIL 0 PASS 1331. Only outstanding reds in the suite are test-degenerate-classical.R's two, which are T4's planned tests-first reds.
- 2026-08-05: T4 green -- test-degenerate-classical.R FAIL 0 PASS 38 (was FAIL 1 ERROR 1 at T1). The guard is burch-only and tests `identical(ss$msa, 0)`, not a tolerance: the fixture's 8x4 cell sits at 3.5e-33 and returns [-1.693, 0.629], so any tolerance wide enough to catch it would abort a case Burch answers.
- 2026-08-05: T5 -- full suite at NOT_CRAN=true CI=true: FAIL 0, WARN 2, SKIP 23, PASS 5856. The 2 warnings are the pre-existing glmmTMB convergence warnings in test-icc-type-vector.R, present in the pre-change baseline run. AC4's searle pin green on all 8 fixture cells at tolerance 0, so nothing moved on the sibling reducer.
- 2026-08-05: T6 -- D-022 appended, DESIGN.md interval-time table gains the classical-family row citing it, NEWS + `@param score` updated, `devtools::document()` clean.
- 2026-08-05: AC6's checker list is a HAND-LIST and under-inclusive -- `.github/workflows/lint.yaml` runs FOUR checkers plus a `--self-test` for each, not the three AC6 names. All eight invocations were run rather than the three; flagged for review rather than amended, since running more than the criterion demands makes nothing in it false.
- 2026-08-05: running the fourth checker caught a PRE-EXISTING failure, not one this branch caused: `check-record-claims.py` reds on `record-claims.tsv:6 [roadmap-terminal-rows]`, whose expected figure still reads M103/M101/M100/M102/M99 while the ROADMAP holds M104/M103/M101/M100/M102. Reproduced at `f3199b0`, before M105 existed -- M104's post-merge hygiene updated the ROADMAP retention comment but not the ledger row that re-derives it, so `main`'s lint job is red today. Corrected in place here per D-021 (a false record is fixed in the milestone that finds it, never promoted to its own); checker and self-test now pass.
- 2026-08-05: AC6 red-then-green record. NEWS non-finite claim -> test-icc-errors.R:"a non-finite score aborts classed on every model and engine" + "the non-finite abort names the column and the offending rows", red at T1, green at T2. NEWS NA-drop claim -> test-icc-errors.R:"NA scores are dropped with a suppressible classed warning", red at T1, green at T3. NEWS Burch claim -> test-degenerate-classical.R:"burch either aborts classed or reports finite ordered limits (AC3)", red at T1, green at T4. NEWS method-availability claim -> test-icc-errors.R:"dropping NA scores leaves exactly the methods the design supports", authored after the fix so its red was recorded by mutation: disabling the drop (`na_scores <- integer(0)`) reds it FAIL 1 PASS 0 with the pre-M105 error verbatim ("The one-way bootstrap could not extract complete subject rows"); source restored and re-verified.
- 2026-08-05: gates -- full suite NOT_CRAN=true CI=true FAIL 0 WARN 2 SKIP 23 PASS 5856; `air format .` clean; `lintr::lint_package()` no lints; `cairn_validate` all checks passed; plan-owned body 118/149.
- 2026-08-05: all six tasks complete, gates clean; status -> review.
- 2026-08-05: review in progress -- draft PR #113 opened; consistency gate clean (cairn_validate all checks passed, devtools::check() 0/0/0, document() no-diff, pkgdown OK, README in sync, no milestone numbers in user-facing text; cairn_impact skipped, no IP/GP text changed). Criterion evidence gathered but NOT yet ticked, pending the third reviewer. Two prose defects queued to fix: R/boundary-hint.R:29 and :167 assert in the present tense that a missing score is caught by the extractors, which this branch makes unreachable via icc() (lines 24 and 61 are historical and stay); and a NEWS claim that such a frame "previously reached the fitting engine and failed there" is wrong -- the fit succeeded and the failure was downstream at the interval stage.
