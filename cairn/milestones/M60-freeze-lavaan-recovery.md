<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M60: Freeze the lavaan multilevel recovery sweep

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Principles touched:** GP5, GP6, GP7
- **Branch/PR:** m60-freeze-lavaan-recovery

## Goal

Freeze the 100-refit lavaan `O-SEM-ML/recovery` sweep to a committed fixture —
cutting the test suite's tail file — with a mutation-verified live guard per
frozen pin so no discriminating power is lost.

## Scope

**In:**

- A standalone, seeded `data-raw/oracle-sem-multilevel-recovery.R` that runs
  Cell B (60 refits) + Cell D (40 refits) verbatim from the current test (same
  population, geometry, seeds, `n_rep`, `mc_samples`) and writes the committed
  summary `tests/testthat/fixtures/sem-multilevel-recovery-oracle.rds`, with a
  provenance header citing the estimand (D-005; the pilot ledger; ten Hove et
  al. 2022 recovery).
- Rewrite `O-SEM-ML/recovery` (`test-icc-lavaan-multilevel.R:208`) to READ the
  fixture and assert the **same** pins at the **same** tolerances (GP5): Cell B
  4-component rel-bias `< .10`; Cell D rater rel-bias centred on the predicted
  `tau^2` inflation at the k-axis floor; the `tau^2`-law parity invariant
  `< .005`.
- A paired LIVE discriminating guard per frozen cell, mutation-verified red
  (M51 protocol): Cell B leans on the existing single-fit `O-SEM-ML/parity`
  (`:81`, lavaan vs independently-validated glmmTMB); Cell D gets a small live
  same-data `tau^2`-invariant guard.
- **Leave-live fallback (gate decision, 2026-07-17):** any cell whose paired
  guard can't be mutation-verified red stays a live sweep — freeze only what
  keeps its rigor.

**Out:**

- Any change to the recovery estimand, populations, seeds, `n_rep`, or pin
  tolerances — the freeze relocates compute, it never moves the bar (GP5) →
  estimand stays as M53/M54 established.
- The already-frozen heavy sweeps: fixed/nested/incomplete cluster coverage
  fixtures and every brms `bayesian-*-oracle.rds` (+ `skip_on_ci`) → untouched.
- The cheap single-fit recovery-by-coverage checks (`O-ML/sim`, `O-NML/sim`,
  `O-IML/sim`, d-study `O-*/sim`) — one refit each, freezing saves ~nothing
  (M59) → left live.
- `parallel`/`start-first` retuning → M59 (done); note if the frozen file drops
  off the tail, but don't re-tune here.

## Acceptance criteria

- [ ] AC1 — `data-raw/oracle-sem-multilevel-recovery.R` exists, is standalone
      (`Rscript data-raw/...`), seeded and reproducible, has a provenance header
      citing D-005 + ten Hove et al. 2022, and writes
      `fixtures/sem-multilevel-recovery-oracle.rds`; a re-run reproduces the
      committed summary values. (evidence: run it, diff the `.rds` summary)
- [ ] AC2 — `O-SEM-ML/recovery` reads the fixture and asserts the same Cell B /
      Cell D pins at byte-identical target values and tolerances as the current
      test; the 100 live refits are gone from the test path. (evidence: passing
      test + diff showing targets/tolerances unchanged, refit loops removed)
- [ ] AC3 — `test-icc-lavaan-multilevel.R` SERIAL time drops materially — no
      longer dominated by the recovery sweep (target: ~137s → its non-recovery
      remainder ~30–45s, i.e. no longer the suite tail). Measured serially per
      the M59 lesson. (evidence: `test_file` serial timing before/after)
- [ ] AC4 — Cell B's live pair `O-SEM-ML/parity` is MUTATION-VERIFIED to go red
      under a representative lavaan component-bias mutation (patch source →
      `load_all` → run → revert). (evidence: mutation log — guard red)
- [ ] AC5 — Cell D ships EITHER a small live `tau^2`-invariant guard
      mutation-verified red, OR (if no cheap discriminating guard survives) its
      sweep stays live — the file records which (leave-live gate decision).
      (evidence: mutation log, or the retained live Cell-D sweep + rationale)
- [ ] AC6 — Full suite green under `NOT_CRAN=true CI=true` (FAIL 0), the profile
      verify slot clean, `air format --check .` clean incl. the new `data-raw`
      script (M59), lintr clean. (evidence: test summary + check/lint output)

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T2
- AC4 → T3
- AC5 → T4
- AC6 → T5

## Tasks

- [ ] T1 — Write `data-raw/oracle-sem-multilevel-recovery.R`: lift the Cell B
      (60) + Cell D (40) refit loops verbatim (same pop/geometry/seeds/`n_rep`/
      `mc_samples`), compute the summary the pins consume (Cell B colMeans
      rel-bias; Cell D mean rater rel-bias, mean `parity_d`, predicted
      `tau^2`/inflation/tol), write the committed `.rds` with a provenance
      header (D-005, pilot ledger, ten Hove 2022). `air format`.
- [ ] T2 — Rewrite `O-SEM-ML/recovery` to read the fixture and assert the same
      pins/tolerances (GP5); add an in-place comment naming the generator +
      D-005 (GP7); confirm the refit loops are gone; record before/after serial
      file timing.
- [ ] T3 — Cell B guard: mutation-verify `O-SEM-ML/parity` goes red under a
      representative component-bias mutation (M51 protocol); comment it as the
      live discriminating pair for the frozen Cell-B recovery (GP7).
- [ ] T4 — Cell D guard: add a small live same-data `tau^2`-parity-invariant
      guard, hand-anchored so the correct value differs from the plausible
      simplification (M51); mutation-verify red. If none survives, leave Cell D
      live and record the finding (gate decision).
- [ ] T5 — Green-gate: `NOT_CRAN=true CI=true` full suite FAIL 0, verify slot
      clean, `air format --check .` clean incl. `data-raw`, lintr clean; update
      the work log.

## Work log

- 2026-07-17: created by /milestone-plan. Promoted from the lever-b candidate
  (test-suite-speed-audit → M59 safe levers a/c/d/e; this is the deferred
  rigor-sensitive lever). Prize: the lavaan file is 137s serial (measured), the
  recovery sweep ~90–110s of it and the current parallel tail.

## Decisions

## Review
