# M97: `npbootstrap` in the boundary hint — a resample-stability predicate for unbalanced one-way

- **Status:** planned
- **Priority:** normal
- **Depends on:** M93
- **Driving RR:** —
- **Principles touched:** GP1, GP6, GP7

## Goal

Let the boundary abort name `ci_method = "npbootstrap"` on unbalanced one-way designs —
the only method shipping that cell (D-013) — without ever naming it where its
resample-stage guard then fires, by predicting resample stability from the observed
data rather than from the design.

## Scope

**In:** a measured characterization of when `npbootstrap_ci()`'s resample-degeneracy
guard (`R/ci-npbootstrap.R:178-191`) fires, swept along the axis the failure grows on —
imbalance SHAPE, not just subject count (GP6); an internal predicate computable from
the observed data (the count of subjects carrying within-subject variance, ties among
subject means, `k`, `boot_samples`) with a stated failure-probability target; the
unbalanced one-way row restored in `boundary_method_hint()` behind it; M93's
message-driven AC3 sweep extended over imbalance shape at the shipped
`boot_samples = 999`; the stale `R/ci-npbootstrap.R:177` comment ("negligibly rare at
k >= 10") corrected against the measurement; NEWS + `@param`.

**Out:** changing `npbootstrap_ci()`'s own guard, its abort message, or its design
fence — this milestone predicts the shipped guard, it does not move it; a case for
moving it → ROADMAP candidate · the balanced one-way row, which names the deterministic
pair and gains nothing from a bootstrap (M93, and D-012's 0-abort evidence is
`searle`/`burch`-only) · the `mpl` and classical rows and the per-row degeneracy check →
M93 · fallback or auto-routing on abort, the `#3`/ADR-003 contract change D-012 fenced
out → standing ROADMAP candidate.

## Acceptance criteria

- [ ] AC1 (GP6): a committed seeded sweep measures the guard's firing rate over subject
      count × imbalance shape × number of subjects carrying within-subject variance, at
      the shipped `boot_samples = 999`, and includes the double-code shape that defeated
      M93's subject-count floor (most subjects rated once, a few doubled — measured
      there at 100% hinted-then-aborting for every `n_s` from 15 to 60). The fixture is
      committed with its script (#4); per-cell rates are recorded, not summarized.
- [ ] AC2: an internal predicate, a pure function of the observed data and
      `boot_samples`, decides whether the resample is stable enough to name the method.
      Its criterion is stated numerically before it is fitted (GP5) — an expected count
      of degenerate resamples over `boot_samples`, below a named threshold — and its
      derivation is either cited or committed as a seeded script, never asserted (#4).
- [ ] AC3: the predicate is validated against AC1's measurement — no swept cell where
      the predicate says "stable" and the measured abort rate exceeds the AC2
      threshold; the double-code shape is checked by name, not by aggregate.
- [ ] AC4 (GP7): M93's message-driven sweep, re-run with `npbootstrap` back in the
      mapping and extended over imbalance shape, records ZERO hinted-then-aborting runs
      at the shipped `boot_samples = 999` — not a reduced count, which masks a guard
      firing on any degenerate resample (M93 pass-3 F3).
- [ ] AC5: designs the predicate rejects get no bootstrap hint, pinned by a test; the
      contract is unchanged — the boundary case still aborts `intraclass_singular_fit`
      and returns no interval.
- [ ] AC6: documented where users meet it — a `NEWS.md` entry, the `@param ci_method`
      note, and `R/ci-npbootstrap.R:177`'s "negligibly rare at k >= 10" comment
      corrected against AC1's measurement (contradicted by it, and pre-existing).
- [ ] AC7: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; snapshot changes
      reviewed via `testthat::snapshot_review()`, never accepted blind; CI green.

## Coverage

- AC1 → T1
- AC2 → T2, T3
- AC3 → T3
- AC4 → T5
- AC5 → T4, T5
- AC6 → T6
- AC7 → T6

## Tasks

- [ ] T1: Write the `data-raw/` seeded sweep and commit its fixture — guard firing rate
      over subject count × imbalance shape (balanced, mildly ragged, double-code) ×
      subjects carrying within-subject variance, at `boot_samples = 999`.
- [ ] T2: Derive the stability criterion analytically — for a whole-subject resample of
      `k` with replacement, the probability that no drawn subject carries within-subject
      variance is `(1 - j/k)^k` for `j` such subjects, plus the subject-mean-tie route
      to `SSA* = 0` — and fix the numeric threshold before fitting it to T1 (GP5).
- [ ] T3: Implement the predicate as a pure internal function with unit tests over T1's
      measured cells, and assert AC3's no-false-"stable" property against the fixture.
- [ ] T4: Restore the unbalanced one-way row in `boundary_method_hint()` behind the
      predicate, wording it as availability (D-012's 0-abort evidence is not an
      npbootstrap result), with unit tests for both branches.
- [ ] T5: Extend M93's message-driven AC3 sweep over imbalance shape at
      `boot_samples = 999`; require zero hinted-then-aborting runs.
- [ ] T6: NEWS, `@param`, the `R/ci-npbootstrap.R:177` comment correction,
      `devtools::document()`, full AC7 gate, PR.

## Work log

- 2026-07-25: created by /milestone-plan as the remainder of the M93 re-cut — the half three M93 review passes could not fence with design predicates (pass-2 F1: raw subject count; pass-3 F1: the count is decoupled from the effective one under imbalance). Depends on M93 because both edit `R/boundary-hint.R` and its test file.

## Decisions

## Review
