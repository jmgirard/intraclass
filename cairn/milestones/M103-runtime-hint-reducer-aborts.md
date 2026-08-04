# M103: Reducer-stage degeneracy aborts name a `ci_method` verified on the caller's own data

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP7
- **Branch/PR:** `m103-runtime-hint-reducer-aborts`

## Goal

Every CI-reducer degeneracy abort names an alternative `ci_method` only after
running that method on the caller's own data, or names none.

## Scope

**In:** the four reducer-stage degeneracy guards — `bootstrap_ci()`'s
refit-convergence guard, `classical_guard_observed()`, and `npbootstrap_ci()`'s
observed-data and degenerate-resample guards — gain the lazily-evaluated `hint`
M93 already gives the two `mc_ci()` guards. `boundary_method_usable()` gains
rows for the two engine-fit methods, `bootstrap` and `montecarlo`, without which
the motivating cell names nothing (`bootstrap` is the only method usable on
zero-between-variance data); `boundary_method_hint()` gains self-exclusion so a
guard never names the method that just aborted. `icc()`'s dispatch threads the
engine fit down to the guards that never saw one. M100's sweep generator and its
committed result land under `data-raw/` as the evidence every verdict cites.
NEWS and `@details`.

**Out:** `icc()`'s pre-dispatch design and argument fences — they refuse a
*design*, not degenerate data, so nothing is verified for them (M100 Scope,
unchanged). A source census asserting no seventh such guard can be added
unwired → **declined at this plan gate (2026-08-04)**: a checker whose subject
is this repo's own source text is the class D-021 closed, and the promise here
is bounded to the six guards a test fires. The fallback-on-abort default
(returning a classical interval instead of aborting) stays fenced out by
D-012/D-013 as a `#3` contract change → ROADMAP candidate row. The two unclassed
error paths (`burch_ci()` on SSA = 0; a non-finite score surfacing glmmTMB's own
error) → ROADMAP candidate row.

## Acceptance criteria

- [ ] AC1 Each of the six `intraclass_singular_fit` guards under `R/ci-*.R` —
      the two `mc_ci()` guards M93 wired, plus `bootstrap_ci()`'s
      refit-convergence guard, `classical_guard_observed()`, and
      `npbootstrap_ci()`'s observed-data and degenerate-resample guards —
      accepts a lazily-evaluated `hint` and splices its bullets into its abort
      message. A test fires each of the six with a synthetic one-bullet hint and
      asserts the bullet appears, and asserts each guard's condition class and
      leading message line are the ones it shipped at 703fc1b.
- [ ] AC2 No remedy bullet names a `ci_method` that `boundary_method_usable()`
      did not accept by running that method's shipped reducer and finding every
      returned interval usable by `boundary_interval_usable()`. A committed test
      asserts `boundary_method_usable()`'s verdict for every (guard, data,
      method) cell in the sweep result AC7 lands, read from that file and
      matching its own usable column — so replacing the run with a predicate
      returning `TRUE` reds it. The resample guard's `montecarlo` bullet,
      hard-coded before this milestone, becomes verification-backed like the
      rest.
- [ ] AC3 No remedy bullet names the `ci_method` the caller invoked. A test
      fires each guard once per invoking value it lists — `bootstrap` for the
      refit guard, `searle` and `burch` for the classical guard, `npbootstrap`
      for both npbootstrap guards, `montecarlo` for the two `mc_ci()` guards —
      and asserts that value appears in no `ci_method = "…"` rendering in the
      message. A guard's own leading line is not a remedy bullet and is exempt:
      `bootstrap_ci()`'s names "bootstrap" by construction and AC1 freezes it.
- [ ] AC4 Forcing a guard's hint never re-enters that guard's own abort path.
      `burch_ci()` and `searle_ci()` share `classical_guard_observed()`, so
      verifying `burch` from a `searle` abort re-enters it; a test asserts that
      call terminates, raising one classed abort rather than recursing, and that
      `boundary_method_usable()` passes no hint to any candidate it runs.
- [ ] AC5 On data where no candidate is usable, each guard's message is exactly
      the one it shipped at 703fc1b. Pinned for the three guards the sweep's
      `gen_mse0` cells reach, each fired with a non-empty `hint` argument so the
      pin reds if verification wrongly accepts a method. The resample guard is
      outside this criterion by construction — `gen_mse0` never reaches it.
- [ ] AC6 On `gen_ssa0` data `npbootstrap_ci()`'s observed-data guard names
      `ci_method = "bootstrap"`, and a test re-runs `icc()` with that string on
      the same data and asserts the returned interval is one
      `boundary_interval_usable()` accepts — the promised call is the verified
      one.
- [ ] AC7 `data-raw/sweep-abort-remedies.R` and its committed result land on the
      default branch with provenance naming their origin, and every figure AC2's
      test asserts is read from that result rather than transcribed.

## Coverage

- AC1 → T3, T4
- AC2 → T2, T4
- AC3 → T2, T5
- AC4 → T5
- AC5 → T6
- AC6 → T3, T6
- AC7 → T1

## Tasks

- [x] T1 Land M100's sweep generator and its 210-row result under `data-raw/`
      with a provenance header naming the branch they came from and the run
      that produced them.
- [x] T2 Add `bootstrap` and `montecarlo` rows to `boundary_method_usable()`
      (both take the engine fit, not `df`), and an `exclude` argument to
      `boundary_method_hint()`.
- [x] T3 Thread the engine fit and a lazy `hint` from `icc()`'s dispatch into
      the four reducer-stage guards.
- [x] T4 Tests: the six-guard wiring, class and leading-line preservation; the
      verdict table against the committed sweep result.
- [x] T5 Tests: self-exclusion per invoking method; no re-entry through the
      shared classical guard.
- [x] T6 Tests: byte-identity where no candidate is usable; the `gen_ssa0`
      promise end to end.
- [ ] T7 NEWS, `@details`, and the gate: suite at `NOT_CRAN=true CI=true`,
      `devtools::check()`, `lintr`, `air format --check`, all `data-raw`
      checkers.

## Work log

- 2026-08-04: created by /milestone-plan, promoting the ROADMAP candidate whose stated falsifier fired — M100's sweep found two trigger datasets where shipped methods return usable intervals (`gen_se_zero`, four methods 1/1; `gen_ssa0`, `bootstrap` 4/4), so runtime verification emits a real recommendation rather than the `character(0)` the M100 plan gate rejected it for. Motivating user-facing behaviour, per D-021's door: the 2026-08-03 hotfix (PR #110) had to strip the `ci_method` suggestion from three aborts, so a user on `gen_ssa0` data is told to inspect their data when `bootstrap` would have worked.
- 2026-08-04: criteria audit ([O], fresh context) ran over the drafted wording and returned findings against all six drafted criteria; five fixed before the gate — AC1 named four guards where six exist (`R/ci-montecarlo.R:49` and `:138` already splice a hint, so the test would have failed against unmodified `main` and been satisfiable only by deleting M93's feature); AC3 was unsatisfiable because `bootstrap_ci()`'s frozen leading line contains "bootstrap" itself, now scoped to the remedy bullets; AC4 was vacuous, true on `main` before any work, now re-pointed at the shared classical guard's real re-entry route; AC5's pin was taken at the reducer where no hint is passed, so it held trivially and would not have red under AC2's mutation, now fired with a non-empty hint; and AC5's quantifier covered three of four guards without saying so. The sixth (the candidate set could not reach `bootstrap` at all, making the motivating case unreachable) went to the gate as a question.
- 2026-08-04: plan gate chose adding both engine-fit methods (`bootstrap`, `montecarlo`) to the candidate set over `bootstrap` alone, because leaving `montecarlo` out keeps a standing exception to AC2's rule at the resample guard; falsified by evidence that threading the engine fit to that guard costs more than the exception is worth.
- 2026-08-04: plan gate chose bounding AC1's promise to six named guards over a `data-raw` source census asserting no seventh can be added unwired, because a checker whose subject is this repo's own source text is the class D-021 closed; falsified by a seventh such guard shipping unwired. Accepted cost: that drift is not mechanically caught.
- 2026-08-04: plan gate chose landing M100's sweep generator and result on the default branch over re-deriving fixtures in the test file, so every usability verdict cites a committed re-runnable artifact rather than a branch nothing protects; falsified by the sweep proving too costly to re-run in CI, which it is not asked to do.
- 2026-08-04: plan chose extending M93's `boundary_method_hint()` over writing a second hint mechanism for the reducer stage, because D-018 already licenses computing a candidate interval to decide whether to name it and the two stages (admissibility, usability) transfer unchanged; falsified by the reducer guards needing an admissibility rule M93's design split cannot express.

- 2026-08-04: implement gate settled three open choices, all as recommended. (1) The AC2 verdict table is split: the three cheap methods assert in the suite on every reached cell, the `bootstrap` column re-derives via a committed `data-raw` script at the gate — measured 16.8 s per dataset for a 999-refit bootstrap, so a full in-suite table would add ~8 min per platform to a suite M78 exists to shrink. (2) The sweep script's two reads of M100's unshipped source-enumerator artifact are replaced by inline literals, so it runs from a clean checkout without importing the machinery D-021 closed. (3) Bullets are tiered — deterministic fenced methods verified first, the engine-fit pair only when none of them serves.
- 2026-08-04: T1 landed `data-raw/sweep-abort-remedies.R` + `abort-remedy-sweep.tsv`. Re-run on this branch reproduces M100's committed result exactly: all 210 rows key-aligned, and `reached`, `point_fit_ok`, `site_confirmed`, `outcome` and `remedy_usable` identical row for row; the only schema change is the dropped `named_by_remedy` column.

- 2026-08-04: T2/T3 wired the hint through all four reducer-stage guards and added the two engine-fit candidate rows. `npb_hint_seed` renamed `hint_verify_seed` (it now seeds three stochastic verifications, not one). M93/M97's whole `boundary-abort-hint` suite passes unchanged, as do `ci-classical`, `ci-npbootstrap*`, `ci-bootstrap` and `ci-montecarlo` — the default Monte-Carlo path is untouched by construction (see the Decisions entry on withholding the engine tier). NEWS and the `ci_method` `@details` written here rather than at T7; T7 keeps the gate.
- 2026-08-04: T1 amendment (minor) — the sweep result is written to `tests/testthat/fixtures/`, not `data-raw/`. `data-raw/` is `.Rbuildignore`d, so a result left there is absent under `R CMD check` and AC2's cell-by-cell assertion would skip in CI rather than run. The generator stays in `data-raw/`, and now emits a fixture provenance header per the profile's test-doctrine.

- 2026-08-04: T4/T5/T6 — `tests/testthat/test-reducer-abort-hint.R`, 142 assertions, 0 failures, 245 s. AC2's mutation clause verified by hand: making `boundary_method_usable()` return `TRUE` unconditionally reds the verdict table (10+ failures at the same assertion), source restored. The AC5 pins render through a fixed renderer (`cli.width`, `cli.unicode`) after the first run failed on nothing but the bullet glyph — a pin that varies with the terminal is evidence about the terminal.
- 2026-08-04: sweep re-run under the M103 code writes `tests/testthat/fixtures/abort-remedy-sweep.tsv` with `reached`, `point_fit_ok`, `site_confirmed`, `outcome` and `remedy_usable` identical row for row to the pre-M103 run — the feature changes what the guards *say*, not what the methods *do*. The script's own runtime roughly doubled (~25 → ~60 min) because each `icc()` retry it makes now pays for a hint; noted in its header.

## Decisions

### 2026-08-04: remedy bullets are tiered by cost, and the fenced methods go first

**Context.** With `bootstrap` and `montecarlo` added to the candidate set, a
balanced one-way guard can have four usable alternatives at once. A 999-refit
parametric bootstrap costs 16.8 s measured on a 30x2 cell, against ~5 ms for
either closed form, and every candidate is run inside an abort message.

**Decision.** `boundary_method_hint()` verifies the design-fenced opt-in methods
(`searle`, `burch`, `npbootstrap`, `mpl`) first and returns as soon as any of them
is usable; the engine-fit pair (`bootstrap`, `montecarlo`) is reached only when
none of them serves this design and data.

**Why.** Three things fall out at once. M93's shipped wording stays byte-identical
wherever it already fired, which is what AC5 pins. A message carries at most two
suggestions instead of four. And on the sweep's nine resample-guard datasets,
where `searle` and `burch` are usable 9/9, the 17 s bootstrap is never run — the
cost lands only on the cells that motivated the milestone, where nothing cheaper
works.

**Falsifier.** A case where a fenced method is usable but materially worse advice
than an engine-fit one, so that returning early recommends the weaker method.

### 2026-08-04: the engine-fit tier is withheld from the Monte-Carlo default path

**Context.** The hint is shared by all six guards. On the default path
`montecarlo` self-excludes, so what the new tier would add there is `bootstrap`.

**Decision.** `icc()` builds the two `mc_ci()` guards' hint with `engine = NULL`,
which makes both engine-fit rows return `FALSE` and leaves M93's default-path
behaviour exactly as it shipped. The four reducer-stage guards get the fit and
reach the tier.

**Why.** The two kinds of guard fail for different reasons. The `mc_ci()` guards
fire because the *fitted model* came back unusable — a non-finite parameter
covariance, or draws overflowing — and `bootstrap` refits that same model, making
it the least promising candidate there; the sweep measured it usable on 0 of 6
datasets at the sibling engine-fit guard. The reducer-stage guards fire on
degenerate *raw data* with a healthy fit behind them, where `bootstrap` is a
genuinely different instrument: usable on 5 of 8 datasets at the npbootstrap
observed-data guard, 4 of 4 on the zero-between-variance cells. Against a weak
prospect stands a 17 s wait added to the package's default abort path.

**Falsifier.** A dataset where the Monte-Carlo default aborts and
`ci_method = "bootstrap"` returns a usable interval. The sweep's grid does not
generate that combination, so it holds no evidence either way; one such dataset
reopens the withholding.

## Review
