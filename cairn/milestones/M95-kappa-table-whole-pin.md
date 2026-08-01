# M95: Whole-table pin for the shipped κ_m calibration table

- **Status:** review
- **Branch:** m95-kappa-table-whole-pin
- **PR:** https://github.com/jmgirard/intraclass/pull/102
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP7

## Goal

Make any change to any cell of the shipped `kappa_m_table` red a test, so the table
every MPL coverage claim rests on cannot silently detach from its calibration runs.

## Scope

**In:** a committed, human-readable fixture under `tests/testthat/fixtures/` carrying
every `(n_r, n_s, conf_level, kappa_m)` row, written at a precision that round-trips
bit-identically and generated from the COMMITTED CALIBRATION fixtures
(`data-raw/m88-kappa-table.rds` for 0.95; `data-raw/m90-kappa-tables.rds` for
0.90/0.99 — verified this plan to be `identical()` to the shipped slices, all cells);
an exact-equality pin in `tests/testthat/test-ci-mpl.R` over values AND key set; the
GP7 in-place comment; mutation evidence that the pin actually fires. `data-raw/` is
`.Rbuildignore`d, which is why the fixture is copied under `tests/` rather than read
in place.

**Out:** changing any κ_m value, adding a level or an (R,S) node — D-015/D-017 own the
table's contents · the monotone envelope/smoother, still a standing rejection from the
M91 plan gate (2026-07-24) and still a candidate row · the exported doc surface → M94 ·
the sweep generators' failure accounting → M96 · the `uniroot` boundary/failure
conflation in `R/ci-mpl.R` → candidate row added by this plan · a `NEWS.md` entry —
this ships no user-visible change.

## Acceptance criteria

- [x] AC1 (GP7): a committed text fixture under `tests/testthat/fixtures/` carries
      every row of the shipped table's `(n_r, n_s, conf_level, kappa_m)` grid, and its
      generator asserts a bit-identical write→read round trip (`identical()` on the
      doubles, never a tolerance) — a lossy text format is a silent hole in the pin.
- [x] AC2: a test in `test-ci-mpl.R` asserts the shipped `kappa_m_table` matches that
      fixture on BOTH axes — `identical()` over the κ_m values and equality of the
      `(n_r, n_s, conf_level)` key set — so an added or dropped cell fails as loudly as
      a changed one.
- [x] AC3: the fixture is built from the calibration fixtures, never from
      `R/sysdata.rda`; the generator `stopifnot()`s each level slice `identical()` to
      the shipped slice at generation time, so the pin traces to the calibration
      evidence rather than to a copy of the thing it checks.
- [x] AC4 (the M92 P6-1 lesson made mechanical): the pin is mutation-verified, not
      asserted — perturbing one cell in each of the three level slices, adding a row,
      and dropping a row each red the AC2 test. Committed as a record naming, per case,
      the cell, the perturbation, and the expectation that failed.
- [x] AC5: the mutation record includes a perturbation confined to cells NOT covered by
      the existing literal pins in `test-ci-mpl.R`, and shows it reds — that is exactly
      the gap M92's pass-6 mutation found (+0.5 on the unpinned cells left the file at
      FAIL 0 / PASS 172). Those existing literal pins are RETAINED, not replaced: they
      carry provenance prose the fixture cannot.
- [x] AC6: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; the full suite green
      against the INSTALLED package at `NOT_CRAN=true CI=true`.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T1
- AC4 → T3
- AC5 → T3
- AC6 → T4

## Tasks

- [x] T1: Add the fixture generator under `data-raw/`: read the 0.95 slice from
      `m88-kappa-table.rds` and the 0.90/0.99 slices from `m90-kappa-tables.rds`,
      `stopifnot()` each is `identical()` to the shipped `kappa_m_table` slice, write
      the fixture at full precision, and re-read it asserting a bit-identical round
      trip. Fails loudly if a calibration fixture is missing.
- [x] T2: Add the whole-table pin to `tests/testthat/test-ci-mpl.R` (key set + exact
      values) with the GP7 in-place comment naming D-015 and the M92 P6-1 finding it
      closes.
- [x] T3: Mutation-verify and commit the record — one perturbed cell per level slice,
      one perturbation confined to previously-unpinned cells, one added row, one
      dropped row; each must red T2's test.
- [x] T4: Full gate — `devtools::document()`, `air format --check`,
      `lintr::lint_package()` (it lints `data-raw/` and rejects UPPERCASE constants,
      M62), `devtools::check()`, installed-package suite at `NOT_CRAN=true CI=true`;
      open the PR.

## Work log

- 2026-07-25: created by /milestone-plan (promotes the "no whole-table κ_m guard" candidate from M92's review; plan gate chose a readable full-precision text fixture over a binary one or a checksum, and verified all shipped cells are `identical()` to the two committed calibration fixtures).
- 2026-07-31: T1 done — `data-raw/m95-kappa-fixture.R` writes `tests/testthat/fixtures/kappa-m-table.txt` (162 rows) from the two calibration fixtures, `stopifnot()`s each level slice `identical()` to the shipped slice, and asserts a bit-identical re-read. Found: `%.17g` decimal does NOT round-trip through R's parser (`R_strtod` lands 1 ulp off on 10 of 162 values), so the pin column is a C99 hex float (`%a`, bit-exact) with a `%.17g` decimal column kept for the human reader. Suite FAIL 0 | PASS 5368.
- 2026-07-31: T2 done — whole-table pin added to `test-ci-mpl.R`: key-set equality (sorted `(n_r, n_s, conf_level)` keys, both directions) + `expect_identical()` on all four columns; GP7 comment names D-015/D-017 ownership and the M92 P6-1 gap it closes. Full suite FAIL 0 | PASS 5373 (3 pre-existing brms warnings).
- 2026-07-31: T3 done — scripted mutation harness `data-raw/m95-mutation-check.R` → committed record `data-raw/m95-mutation-record.md`: 6 cases all red the pin and only the pin (one +0.5 cell per level slice incl. the unpinned AC5 cell (6,15,0.95); added row; dropped row; plus a shipped-side `R/sysdata.rda` mutation with the fixture intact), green baseline before and after. First harness run invalidated: a global `kappa_m_table` shadowed the package table inside the test env — fixed to a scratch env and rerun whole.
- 2026-07-31: T4 done — `devtools::document()` no-diff; `air format --check .` clean; `lintr::lint_package()` 0; `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings / 0 notes; installed-package suite at `NOT_CRAN=true CI=true`: FAIL 0 | WARN 2 | SKIP 23 | PASS 5111. PR opened.

## Decisions

## Review

### Acceptance-criteria evidence (2026-07-31, all by command this session)

- AC1: `Rscript data-raw/m95-kappa-fixture.R` fresh at review — "162 rows, 54 per level; round trip identical() on all columns" (the round trip is `identical()` per column, doubles as C99 hex floats since `%.17g` decimal parses 1 ulp off on 10/162 values); rerun left the committed fixture byte-identical (`git status` clean). ✓
- AC2: the pin test asserts sorted-key-set equality (both directions) and `expect_identical()` on all four columns; fresh green runs at review: harness baseline + restored-state runs (pin green, whole file green), plus implement-gate full suite FAIL 0 | PASS 5373. ✓
- AC3: generator sources are `m88-kappa-table.rds`/`m90-kappa-tables.rds` only; `R/sysdata.rda` is loaded into a verification-only env and each level slice `stopifnot()`-`identical()`-checked at generation — fresh exit 0 at review. ✓
- AC4: `Rscript data-raw/m95-mutation-check.R` fresh at review, exit 0 — 6 cases (one +0.5 cell per level slice, added row, dropped row, shipped-side `R/sysdata.rda` +0.5 with fixture intact) each red the pin and only the pin (asserted in-script); committed record names cell, perturbation, and first failed expectation per case; record regenerated byte-identical. ✓
- AC5: record case 3 — (6, 15, 0.95), covered by no pre-M95 literal pin (the M92 P6-1 unpinned set), +0.5 → RED, 1 failed expectation; existing literal pins untouched (diff to `test-ci-mpl.R` is insertion-only). ✓
- AC6: `devtools::test()` FAIL 0 | PASS 5373; `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors / 0 warnings / 0 notes; `lintr::lint_package()` 0; `air format --check .` clean; `devtools::document()` no-diff (re-run at review); installed-package suite at `NOT_CRAN=true CI=true` FAIL 0 | WARN 2 | SKIP 23 | PASS 5111. ✓

### Consistency gate (2026-07-31)

- `cairn_validate.py`: all checks passed; 321 advisory `dangling id tokens` warnings (legacy M-ids in COVERAGE.md etc., pre-existing, advisory-only).
- No IP/GP changed → `cairn_impact` skipped.
- Profile slot: `document()` no-diff ✓; `pkgdown::check_pkgdown()` no problems ✓; README untouched by branch ✓; NEWS — none owed (no user-visible change, per Scope Out) ✓; no new top-level files ✓; full `check()` 0/0/0 ✓.
- No Driving RR → projection-vs-outcome n/a.
