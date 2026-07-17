<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M60: Freeze the lavaan multilevel recovery sweep

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Principles touched:** GP5, GP6, GP7
- **Branch/PR:** m60-freeze-lavaan-recovery · https://github.com/jmgirard/intraclass/pull/64

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

- [x] AC1 — `data-raw/oracle-sem-multilevel-recovery.R` exists, is standalone
      (`Rscript data-raw/...`), seeded and reproducible, has a provenance header
      citing D-005 + ten Hove et al. 2022, and writes
      `fixtures/sem-multilevel-recovery-oracle.rds`; a re-run reproduces the
      committed summary values. (evidence: run it, diff the `.rds` summary)
- [x] AC2 — `O-SEM-ML/recovery` reads the fixture and asserts the same Cell B /
      Cell D pins at byte-identical target values and tolerances as the current
      test; the 100 live refits are gone from the test path. (evidence: passing
      test + diff showing targets/tolerances unchanged, refit loops removed)
- [x] AC3 — `test-icc-lavaan-multilevel.R` SERIAL time drops materially — no
      longer dominated by the recovery sweep (target: ~137s → its non-recovery
      remainder ~30–45s, i.e. no longer the suite tail). Measured serially per
      the M59 lesson. (evidence: `test_file` serial timing before/after)
- [x] AC4 — Cell B's live pair `O-SEM-ML/parity` is MUTATION-VERIFIED to go red
      under a representative lavaan component-bias mutation (patch source →
      `load_all` → run → revert). (evidence: mutation log — guard red)
- [x] AC5 — Cell D ships EITHER a small live `tau^2`-invariant guard
      mutation-verified red, OR (if no cheap discriminating guard survives) its
      sweep stays live — the file records which (leave-live gate decision).
      (evidence: mutation log, or the retained live Cell-D sweep + rationale)
- [x] AC6 — Full suite green under `NOT_CRAN=true CI=true` (FAIL 0), the profile
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

- [x] T1 — Write `data-raw/oracle-sem-multilevel-recovery.R`: lift the Cell B
      (60) + Cell D (40) refit loops verbatim (same pop/geometry/seeds/`n_rep`/
      `mc_samples`), compute the summary the pins consume (Cell B colMeans
      rel-bias; Cell D mean rater rel-bias, mean `parity_d`, predicted
      `tau^2`/inflation/tol), write the committed `.rds` with a provenance
      header (D-005, pilot ledger, ten Hove 2022). `air format`.
- [x] T2 — Rewrite `O-SEM-ML/recovery` to read the fixture and assert the same
      pins/tolerances (GP5); add an in-place comment naming the generator +
      D-005 (GP7); confirm the refit loops are gone; record before/after serial
      file timing.
- [x] T3 — Cell B guard: mutation-verify `O-SEM-ML/parity` goes red under a
      representative component-bias mutation (M51 protocol); comment it as the
      live discriminating pair for the frozen Cell-B recovery (GP7).
- [x] T4 — Cell D guard: add a small live same-data `tau^2`-parity-invariant
      guard, hand-anchored so the correct value differs from the plausible
      simplification (M51); mutation-verify red. If none survives, leave Cell D
      live and record the finding (gate decision).
- [x] T5 — Green-gate: `NOT_CRAN=true CI=true` full suite FAIL 0, verify slot
      clean, `air format --check .` clean incl. `data-raw`, lintr clean; update
      the work log.

## Work log

- 2026-07-17 (T5): green-gate `NOT_CRAN=true CI=true` full suite **FAIL 0 |
  WARN 2 | SKIP 23 | PASS 1725** (Duration 177.6s; +1 test = the new
  tau2-invariant guard; the 2 WARN are the pre-existing Heywood/boundary
  assert-warning tests, not introduced here). air format --check + lintr clean;
  `data-raw` already `.Rbuildignore`d, fixture ships under `tests/`. Status →
  review. NOTE for review: at 63.8s the lavaan file is no longer the tail —
  ci-bootstrap (~114s serial, M59) now leads `start-first`; a one-line reorder
  would realize the parallel gain but is M59/parallel-config scope (plan kept it
  out) — flag as a possible follow-up, not done here.
- 2026-07-17 (T2-T4): rewrote `O-SEM-ML/recovery` to read the fixture (same
  pins/targets/tolerances, GP5); added the live `O-SEM-ML/tau2-invariant` guard
  (k=6, n_rep=3 — per-rep parity within .0015 of tau^2, |mean-tau^2| ~1e-4 vs
  .004 tol); tagged `O-SEM-ML/parity` as the Cell-B live pair. **Both cells
  cleared the rigor bar — no leave-live fallback.** Mutations (M51 protocol):
  `/(k-1)->/k` at engine-lavaan.R:437 → tau2 guard dev .0247 ≥ .004 RED;
  `svw->svw*1.1` at :441 → parity subject rel .10 ≥ .02 RED; both revert clean.
  File serial time **137s → 63.8s** (−73s / −53%; residual is the out-of-scope
  B=99 bootstrap tests). air + lintr clean.
- 2026-07-17 (T1): wrote `data-raw/oracle-sem-multilevel-recovery.R` (verbatim
  Cell B/D loops, same pop/seeds/n_rep/mc_samples) → committed
  `fixtures/sem-multilevel-recovery-oracle.rds`. Reproduces the original passing
  values: Cell B max |rel_bias| .0784 < .10; Cell D parity .00747 vs tau^2
  .00742 (Δ 5e-5 — same-data differencing is tight, so a few live reps suffice).
- 2026-07-17: created by /milestone-plan. Promoted from the lever-b candidate
  (test-suite-speed-audit → M59 safe levers a/c/d/e; this is the deferred
  rigor-sensitive lever). Prize: the lavaan file is 137s serial (measured), the
  recovery sweep ~90–110s of it and the current parallel tail.

## Decisions

## Review

**Reviewed 2026-07-17 · PR #64 · branch m60-freeze-lavaan-recovery**

### Acceptance-criteria evidence (fresh)

- **AC1 ✓** — `data-raw/oracle-sem-multilevel-recovery.R` runs standalone
  (`Rscript`), clean exit; provenance header cites D-005 + ten Hove 2022 +
  pilot ledger, records pop/geometry/seeds/n_rep/versions; writes
  `fixtures/sem-multilevel-recovery-oracle.rds`. Re-run reproduces the committed
  values **exactly** (Cell B/D max abs diff 0; `all.equal` TRUE).
- **AC2 ✓** — `O-SEM-ML/recovery` now reads the fixture via `test_path()` and
  asserts the identical pins (Cell B 4-comp rel-bias < .10; Cell D rater-vs-infl
  < tol; tau^2-invariant < .005). Targets/tolerances match the generator, which
  lifted the loops verbatim (GP5). The 60+40 live `icc(... engine="lavaan")`
  refit loops are gone from the test path. Passes.
- **AC3 ✓** — file serial `test_file` time 137.2s → 63.8s (−73s / −53%);
  measured serially (M59 lesson). Residual is the out-of-scope B=99 bootstrap
  tests, not the recovery sweep.
- **AC4 ✓** — mutation `svw → svw*1.1` at engine-lavaan.R:441 → `O-SEM-ML/parity`
  subject rel-delta .10 ≥ .02 tol → RED; source reverted clean.
- **AC5 ✓** — mutation `/(k-1) → /k` at engine-lavaan.R:437 → `O-SEM-ML/
  tau2-invariant` |mean−tau^2| .0247 ≥ .004 tol → RED; reverted clean. Both
  cells cleared the bar — **no leave-live fallback triggered.**
- **AC6 ✓** — full suite `NOT_CRAN=true CI=true`: **FAIL 0 | WARN 2 | SKIP 23 |
  PASS 1725** (Duration 177.6s; +1 test vs M59's 1724 = the new guard; the 2
  WARN are pre-existing Heywood/boundary assert-warning tests). `air format
  --check .` clean; `lintr` clean on both changed files; `data-raw` already
  `.Rbuildignore`d, fixture ships under `tests/`.

### Consistency gate

- `cairn_validate` — all checks passed (290 advisories = pre-existing legacy-id
  citations, not gate failures; none reference M60).
- `devtools::document()` — no diff (no roxygen/Rd/NAMESPACE change).
- NEWS / README / pkgdown — no-op: M60 changes no user-visible behavior, adds no
  exports, touches no README.
- Full R CMD check — delegated to PR #64 cross-platform CI (local `check()` is
  documented to flake here on the Courier PDF-manual font + the brms live
  suite); gated on CI-green at merge.

### Independent three-lens review

_(in progress)_ Lens 3 (prior-PR-comments): **no prior-PR evidence** — the
merged PRs touching these files (#59/#60/#62) carry only Codecov bot comments,
no human review points; zero findings. Lenses 1 (diff-bug, Opus) and 2
(blame-history, Sonnet) still running; scorer + triage to follow.
