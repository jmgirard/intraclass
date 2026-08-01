# M95: Whole-table pin for the shipped κ_m calibration table

**Status:** done (2026-07-31, PR #102 https://github.com/jmgirard/intraclass/pull/102)

**Goal:** Make any change to any cell of the shipped `kappa_m_table` red a test — the table every MPL coverage claim rests on must not silently detach from its calibration runs.

**Outcome:** `tests/testthat/fixtures/kappa-m-table.txt` carries all 162
`(n_r, n_s, conf_level, kappa_m)` rows as C99 hex floats (bit-exact; `%.17g` decimal
parses 1 ulp off on 31/162 values via `R_strtod`) plus a decimal mirror column.
Generator `data-raw/m95-kappa-fixture.R` builds it from the M88/M90 calibration
fixtures (never `R/sysdata.rda`), asserting per-slice `identical()` to the shipped
table, a bit-identical round trip, and the measured drift count. Whole-table pin in
`test-ci-mpl.R`: sorted-key-set equality both directions + `expect_identical()` on all
four columns; pre-existing literal pins retained. Mutation harness + committed record
(`data-raw/m95-mutation-check.R`/`-record.md`): 6 cases (one +0.5 cell per level slice
incl. previously-unpinned (6,15,0.95); added/dropped row; shipped-side `sysdata.rda`
mutation) each red the pin and only the pin.

**Decisions:** none.

**Review:** 15 candidates from the diff-bug lens (other lenses 0), 2 actioned:
(90) harness `on.exit` restore was a top-level no-op → `options(error=)` handler;
(92) drift count "10 of 162" was the 0.95 slice alone, true 31/162 → measured
in-generator. 13 sub-80 logged. CI lint red once on lintr-version drift (`<<-`).
Hygiene: M62 lint lesson extended; hex-float lesson added; M70 anchor lesson pruned.
