# M103: Reducer-stage degeneracy aborts name a `ci_method` verified on the caller's own data

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP7
- **Branch/PR:** `m103-runtime-hint-reducer-aborts` / https://github.com/jmgirard/intraclass/pull/111

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

- [x] AC1 Each of the six `intraclass_singular_fit` guards under `R/ci-*.R` —
      the two `mc_ci()` guards M93 wired, plus `bootstrap_ci()`'s
      refit-convergence guard, `classical_guard_observed()`, and
      `npbootstrap_ci()`'s observed-data and degenerate-resample guards —
      accepts a lazily-evaluated `hint` and splices its bullets into its abort
      message. A test fires each of the six with a synthetic one-bullet hint and
      asserts the bullet appears, and asserts each guard's condition class and
      leading message line are the ones it shipped at 703fc1b.
- [x] AC2 No remedy bullet names a `ci_method` that `boundary_method_usable()`
      did not accept by running that method's shipped reducer and finding every
      returned interval usable by `boundary_interval_usable()`. A committed test
      asserts `boundary_method_usable()`'s verdict for `searle`, `burch` and
      `npbootstrap` over every (guard, data) cell in the sweep result AC7 lands,
      read from that file and matching its own usable column — so replacing the
      run with a predicate returning `TRUE` reds it. The two engine-fit methods
      are verified at a screened and capped resample count that column does not
      measure, so a committed `data-raw` checker covers them by the same rule
      read forward: for every such cell it accepts, it runs the call the bullet
      promises and asserts every returned interval is one
      `boundary_interval_usable()` accepts. The resample guard's `montecarlo`
      bullet,
      hard-coded before this milestone, becomes verification-backed like the
      rest.
- [x] AC3 No remedy bullet names the `ci_method` the caller invoked. A test
      fires each guard once per invoking value it lists — `bootstrap` for the
      refit guard, `searle` and `burch` for the classical guard, `npbootstrap`
      for both npbootstrap guards, `montecarlo` for the two `mc_ci()` guards —
      and asserts that value appears in no `ci_method = "…"` rendering in the
      message. A guard's own leading line is not a remedy bullet and is exempt:
      `bootstrap_ci()`'s names "bootstrap" by construction and AC1 freezes it.
- [x] AC4 Forcing a guard's hint never re-enters that guard's own abort path.
      `burch_ci()` and `searle_ci()` share `classical_guard_observed()`, so
      verifying `burch` from a `searle` abort re-enters it; a test asserts that
      call terminates, raising one classed abort rather than recursing, and that
      `boundary_method_usable()` passes no hint to any candidate it runs.
- [x] AC5 On data where no candidate is usable, each guard's message is exactly
      the one it shipped at 703fc1b. Pinned for the three guards the sweep's
      `gen_mse0` cells reach, each fired with a non-empty `hint` argument so the
      pin reds if verification wrongly accepts a method. The resample guard is
      outside this criterion by construction — `gen_mse0` never reaches it.
- [x] AC6 On `gen_ssa0` data `npbootstrap_ci()`'s observed-data guard names
      `ci_method = "bootstrap"`, and a test re-runs `icc()` with that string on
      the same data and asserts the returned interval is one
      `boundary_interval_usable()` accepts — the promised call is the verified
      one.
- [x] AC7 `data-raw/sweep-abort-remedies.R` and its committed result land on the
      default branch with provenance naming their origin, and every figure AC2's
      test asserts is read from that result rather than transcribed.
- [ ] AC8 No degeneracy abort that ultimately names no method costs materially
      more than the guard that raised it. A test measures `icc()` on `gen_mse0`
      data for `ci_method = "searle"`, `"burch"` and the default, and asserts
      each abort returns in under 5 seconds.
- [ ] AC9 The default `icc()` call receives the same verified naming as an
      opt-in one. A test asserts that on `gen_ssa0` data the default call's
      abort names `ci_method = "bootstrap"`, and that re-running with that
      string returns an interval `boundary_interval_usable()` accepts.

## Coverage

- AC1 → T3, T4
- AC2 → T2, T4, T13
- AC3 → T2, T5
- AC4 → T5
- AC5 → T6
- AC6 → T3, T6, T14
- AC7 → T1
- AC8 → T8, T11
- AC9 → T9, T11, T14

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
- [x] T7 NEWS, `@details`, and the gate: suite at `NOT_CRAN=true CI=true`,
      `devtools::check()`, `lintr`, `air format --check`, all `data-raw`
      checkers.
- [x] T8 Bound the expensive candidate at both ends: screen `bootstrap` at a
      small resample count and abandon it on failure, then run it in full at a
      capped count that the bullet names, so the promised call is the run.
- [x] T9 Give the Monte-Carlo default path the engine-fit tier, superseding the
      withholding decision; reconcile M93's silence tests.
- [x] T10 Review follow-ups: the bullet names `boot_samples` when it is not the
      default (F8); hedge the `@details` naming claim (F7); repair three stale
      fixture paths (F19); stop pinning a glmmTMB convergence count (F20).
- [x] T11 Tests: AC8 abort latency, AC9 the default path end to end, and the
      unseeded self-exclusion case AC3's cases never reach (F1).
- [x] T12 Re-run the gate and return to review.
- [x] T13 The engine-fit checker asserts the promised call directly (G5), and
      its header's cost figures describe the run it now makes.
- [ ] T14 AC6/AC9 re-run the seeded promise: a helper that reads either bullet
      form and fails on neither, plus a case per form (G1).
- [ ] T15 Prose repairs: NEWS's seed claim (G2), the withheld-tier comment (G7),
      the `@details` method descriptions (G3, G4), and G6, G9, G11, G12.
- [ ] T16 Re-run the gate and return to review.

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

- 2026-08-04: T7 gate. Suite at `NOT_CRAN=true CI=true`: 5603 pass, 0 fail, 0 error, 23 skip. `devtools::check(env_vars = c(NOT_CRAN = "false"))`: 0 errors, 0 warnings, 0 notes. `lintr::lint_package()` 0 lints; `air format --check` clean; `pkgdown::check_pkgdown()` clean; `document()` no diff. `data-raw/check-abort-remedy-verdicts.R`: 52 engine-fit cells, 0 disagreements. The three Python checkers and their `--self-test`s pass; `cairn_validate` all checks passed.
- 2026-08-04: the hotfix regression test `test-abort-remedy-truthfulness.R` "the npbootstrap resample-degeneracy abort KEEPS its montecarlo remedy" is superseded, not deleted. Its intent — the hotfix de-named only condemned sites, so a blanket de-naming sweep reds — is preserved and strengthened: the test now asserts the guard names at least one method AND that every method it names passes `boundary_method_usable()` on that data. The literal `montecarlo` no longer holds because AC2 replaced that hard-coded name with verification, and on this generator the deterministic pair verifies first; pinning the literal would pin the tier order rather than the truthfulness.
- 2026-08-04: the three new `@details` sentences needed rows in `data-raw/mpl-doc-claims.tsv` — the M94 checker enumerates every claim in the `@param ci_method` block. Filed as `out` rows (the M92 fixture cannot settle a boundary-hint claim), each naming where it IS settled, following the existing `b41deb261c52` row for M93's claim. Checker and `--self-test` green.

- 2026-08-04: review gate FAILED (first defect return), status -> in-progress. Two confirmed user-facing defects, both outside every acceptance criterion: (F5) the milestone's own withholding decision is falsified by its own AC6 fixture — on `gen_ssa0` the DEFAULT `icc()` call aborts with no bullet while `ci_method = "bootstrap"` returns a usable interval, so the motivating benefit never reaches the default path and the Decisions entry's "holds no evidence either way" is false; (F11) `searle_ci()`/`burch_ci()` share one guard on identical `ss`, so tier 1 there is empty by construction and every classical degeneracy abort now pays a 999-refit bootstrap — measured 25.6 s to emit a message with no bullet, against instant before this branch. Also actioned: F8 (`boot_samples` means different things across methods, so the promised retry is not the verified run), F7 (unconditional `@details` claim that an error names a method, false in 3 of 6 measured cases), F1 (AC3's test green with self-exclusion deleted). AC1-AC7 evidence stands as recorded; the gap is in what the criteria cover.

- 2026-08-04: return gate chose, with recommendations, (1) bounding the expensive candidate with a cheap negative screen rather than dropping it or accepting the wait, (2) giving the Monte-Carlo default path the engine-fit tier, and (3) adding AC8 and AC9 so both review defects are pinned by criteria rather than by hand. Plan amendment (substantive): AC8/AC9 added with Coverage rows and tasks T8-T12; plan-owned body 135/149 after the amendment.
- 2026-08-04: T8/T9 measured. Screen at 25 refits: a hopeless dataset is rejected in 0.69 s where the full run took 27.20 s, and `gen_ssa0` passes it in 0.45 s. Default path on `gen_ssa0` now names `bootstrap`; `searle` on `gen_mse0` returns in 0.93 s against 25.6 s at the failed gate.
- 2026-08-04: second cost gate. The T9 change made the M93 hint suite ~4x slower (three files ~55 min against ~10), because every default-path abort now verifies. Chose capping the full `bootstrap` verification at 199 resamples and NAMING that count in the bullet, over leaving it uncapped or making the old fixtures cheap: the promise stays exactly as strong (the call the message gives is the call that ran), while the default abort drops 20.5 s -> 4.36 s. Falsified by 199 resamples proving too few to be worth recommending.
- 2026-08-04: T10 done — the bullet names `boot_samples`; the `@details` naming claim is hedged and its cost sentence rewritten; three stale fixture paths repaired; the AC5 pin no longer hard-codes a glmmTMB convergence count.
- 2026-08-04: reconciling M93's suite with the two new behaviours took four rounds and is the milestone's main churn. Four distinct causes, each a real gap rather than a rename: its leak guard's seed exception was keyed on the `npbootstrap` method rather than on the seed mention, so the new bullet form fell to the token-free branch; its distinct-rendering pin went 5 -> 6, which is that pin doing its job; two sites matched a method by bare substring, and `boot_samples` contains "mpl"; and its "named == everything usable" invariant is no longer the contract now that bullets are tiered.

- 2026-08-04: T12 gate clean, status -> review (second time). Suite at `NOT_CRAN=true CI=true`: 5756 pass, 0 fail, 0 error, 23 skip (5603 before this return). `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0/0/0; `lintr` 0; `air format --check`, `document()`, `cairn_validate` all clean; `data-raw/check-abort-remedy-verdicts.R` 52 cells, 0 disagreements. The MPL doc-claims checker caught the `@details` rewrite in both directions -- two ledger rows orphaned and four claims uncovered -- and its four replacement `out` rows bind; checker and `--self-test` green.

- 2026-08-04: review pass 2 FAILED (second defect return), status -> in-progress. Two actioned findings demonstrate a criterion failing: AC6's test extracts `seed` from the message with a digits pattern, but the seeded bullet says "run under your `seed`" with no digits, so the re-run is UNSEEDED and AC6's "the promised call is the verified one" is not what it tests; and AC2's only evidence for the `bootstrap`/`montecarlo` rows now compares `boundary_method_usable()` (screened at 25, capped at 199) against a fixture column measured at 999, so "0 disagreements" is coincidence rather than the designed identity. Also actioned: a NEWS sentence false in the seeded case, and a code comment still asserting the withholding this milestone superseded. Thirteen further findings logged below the bar. The recurring shape across both passes is prose -- comments, NEWS, `@details`, evidence lines -- drifting from the code it describes.

- 2026-08-04: second return gate settled three choices, all as recommended. (1) G1 is repaired test-side — the seeded bullet's "run under your `seed`" is correct advice and M97's own wording, so the test learns to read both forms rather than the message dropping one. (2) G5's checker stops consulting the fixture column for the two engine-fit methods and asserts the promise forward instead: for every cell it accepts, the promised call is run and its intervals must be usable. (3) The below-bar findings that are simply false prose are fixed; the design ones (G13 floor, G14 the 199 choice, G15/G16 test strength) are not.
- 2026-08-04: T13 — `data-raw/check-abort-remedy-verdicts.R` now runs the promised call for every cell `boundary_method_usable()` accepts and requires its intervals to be usable; a refusal asserts nothing, and the fixture column is printed as context only. Run: 52 cells checked, 24 accepted, 0 broken promises, exit 0. Falsifiability checked directly rather than assumed: on a refused cell (`gen_mse0` 6x3, `bootstrap`) the promised `icc()` call raises `intraclass_singular_fit`, so a wrongly-accepted cell breaks its promise and exits non-zero. A vacuity guard fails the script if nothing is accepted at all.
- 2026-08-04: plan amendment (substantive) — AC2 now states both halves of its evidence: the fixture column for `searle`/`burch`/`npbootstrap`, the forward promise check for `bootstrap`/`montecarlo`, which the screen and cap made incomparable to that column. Tasks T13-T16 added.

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

### 2026-08-04 (supersedes the withholding entry below): the default path gets the engine-fit tier, and verification is bounded at both ends

**Context.** The entry below withheld the engine-fit tier from the Monte-Carlo
default path and named its falsifier: a dataset where that default aborts and
`ci_method = "bootstrap"` returns a usable interval. It asserted the sweep grid
held no such case. The M103 review found one, and it is this milestone's own AC6
fixture: on `gen_ssa0(6, 3)` the default aborts with "49% of draws were
non-finite" and `bootstrap` returns a usable interval. That assertion was false
when written, and checking it would have cost one command.

**Decision.** The default path builds its hint with the engine fit like every
other guard. The cost that motivated withholding is bounded instead, at both
ends: a candidate is screened at 25 resamples before the full run, and the full
run is capped at 199 with the bullet naming that count.

**Why the promise survives the cap.** M97's rule is that the promised call is the
verified one, not that verification runs at any particular size. A bullet reading
`ci_method = "bootstrap"`, `seed = 1`, `boot_samples = 199` promises exactly the
run that was made. Measured: the default abort on `gen_ssa0` goes 20.5 s -> 4.36 s
and still names `bootstrap`; a `searle` abort on `gen_mse0`, which names nothing,
goes 25.6 s -> 0.93 s.

**Falsifier.** 199 resamples proving too few for the recommendation to be worth
making — a percentile bootstrap that a user should not be pointed at.

### 2026-08-04 (SUPERSEDED, see above): the engine-fit tier is withheld from the Monte-Carlo default path

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

2026-08-04, PR #111. All evidence below is from runs made in this review session
on `m103-runtime-hint-reducer-aborts` at eb98e4a, not recalled from implement.

### Criterion evidence

- AC1 — `test-reducer-abort-hint.R` "each of the six degeneracy guards splices a
  lazily-built hint": 30 assertions, 0 failures. Fires all six guards at the
  function that owns each (`rmvn`, `mc_interval`, `bootstrap_ci` with a stubbed
  all-NA `simulate_refit`, `searle_ci`, and both `npbootstrap_ci` guards) with a
  synthetic bullet; asserts the bullet appears, the leading line equals the
  703fc1b text, and the class is `intraclass_singular_fit`. Companion test "a
  hint is never forced on a call that succeeds": 2 assertions — `hint =
  stop(...)` passed to two reducers that succeed raises nothing, so the promise
  is genuinely lazy.
- AC2 — "boundary_method_usable() agrees with the sweep, cell by cell": 80
  assertions, 0 failures, one per (reached cell x method) for `searle`, `burch`
  and `npbootstrap`, each expecting `isTRUE(row$remedy_usable)` read from the
  fixture. The `bootstrap` and `montecarlo` columns re-derive via
  `Rscript data-raw/check-abort-remedy-verdicts.R`: 52 cells, 0 disagreements,
  exit 0. Mutation clause exercised directly — inserting an unconditional
  `return(TRUE)` at the head of `boundary_method_usable()` reds the verdict
  table (10+ failures at the same assertion); source restored and re-verified
  green. Companion test "the engine-fit rows refuse to verify with no fit in
  hand": 2 assertions. The resample guard's hard-coded `montecarlo` literal is
  gone from `R/ci-npbootstrap.R` and that site now splices the verified hint.
- AC3 — "no remedy bullet names the ci_method the caller invoked": 12
  assertions, 0 failures. Six cases, one per (guard, invoking value): `bootstrap`
  at the refit guard, `searle` and `burch` at the classical guard, `npbootstrap`
  at both npbootstrap guards, `montecarlo` at the Monte-Carlo guards. Each fires
  through `icc()` and asserts the invoking value appears in no
  `ci_method = "…"` rendering after the leading line, which the criterion
  exempts.
- AC4 — "verifying burch from a searle abort terminates, not recurses": 2
  assertions. The call returns (non-termination would hang the suite, which is
  the substantive check) and the escaping condition is one
  `intraclass_singular_fit` carrying the classical guard's leading text exactly
  once. "verification passes no hint to any candidate it runs": 4 assertions —
  `local_mocked_bindings()` captures the dots of `searle_ci`/`burch_ci` as
  `boundary_method_usable()` calls them and asserts no `hint` argument is
  present at all, not merely that an empty one is.
- AC5 — "no usable candidate leaves the shipped message untouched": 6
  assertions, 0 failures. The three guards `gen_mse0` reaches are fired through
  `icc()` — so each builds and forces its real hint, running every candidate —
  and each rendered message is `expect_identical` to the 703fc1b text. The
  renderer is pinned (`cli.width`, `cli.unicode`) so the pin measures the
  message, not the terminal. Cross-checked against the diff: `git diff 703fc1b`
  over the four `R/ci-*.R` files shows the only message-text change is the
  resample guard's own bullet, which this criterion excludes by construction.
- AC6 — "the gen_ssa0 abort names bootstrap, and that call delivers": 4
  assertions. The `npbootstrap` abort on `gen_ssa0` 6x3 names
  `ci_method = "bootstrap"`, and re-running `icc()` with that string at the
  named seed returns ICC(1) and ICC(k) intervals `boundary_interval_usable()`
  accepts. Consistent with the fixture, where `bootstrap` is usable on 4 of 4
  `gen_ssa0` cells and `searle`/`burch`/`montecarlo` on 0 of 4.
- AC7 — `data-raw/sweep-abort-remedies.R` is on the branch at 5abdd05 with a
  provenance header naming its origin branch, the two edits made in landing it,
  and the re-run command; its result is at
  `tests/testthat/fixtures/abort-remedy-sweep.tsv` (220 lines: 9 provenance
  lines + header + 210 rows). Re-running the script under the M103 code
  reproduced the pre-M103 result row for row on `reached`, `point_fit_ok`,
  `site_confirmed`, `outcome` and `remedy_usable`. No verdict figure is
  transcribed into the AC2 test: its expected value is `isTRUE(row$remedy_usable)`
  read from the file, and the dataset for each row is rebuilt from that row's own
  `generator`/`n_s`/`n_r`/`seed`/`trigger` columns.

### Consistency gate

`cairn_validate` exit 0 — `weight caps`, `status vocabulary`,
`roadmap<->disk orphans`, `scaffold present`, `coverage complete`,
`record density`, `sizing`, `work-log format`, `decisions format`,
`references staleness`, `release window` all pass; the one WARN is the
pre-existing `dangling id tokens` advisory (321, unchanged by this branch). No
DESIGN principle changed, so `cairn_impact` is skipped. Toolchain slot
(`r-package`): `devtools::check(env_vars = c(NOT_CRAN = "false"))` 0 errors /
0 warnings / 0 notes; `devtools::document()` no diff; `pkgdown::check_pkgdown()`
clean; `lintr::lint_package()` 0; `air format --check` clean; NEWS.md carries a
user-visible entry with no milestone numbers; README.Rmd/README.md untouched by
this branch. CI on PR #111: `lint`, `check-references`, `format-check`,
`pkgdown` green; platform matrix still running at the time of this gate.

### Independent review — three lenses, then a scorer

Three fresh-context reviewers with distinct evidence bases (diff / blame-history
/ prior-review record), then a separate Sonnet scorer holding the diff and the
plan. 22 candidate findings; 5 scored >= 80. The prior-review lens probed for
GitHub inline review comments, found none real, and correctly skipped the walk;
its evidence is the archived `## Review` sections.

**Actioned (>= 80).** Two clear the M130 return floor at 95, both re-confirmed by
this session's own commands rather than taken from the reviewer:

- **F5 (95) — the milestone's own falsifier has fired.** The Decisions entry
  "the engine-fit tier is withheld from the Monte-Carlo default path" claims the
  sweep grid "does not generate that combination, so it holds no evidence either
  way". `gen_ssa0(6,3)` is that combination and is this milestone's own AC6
  fixture. Measured: `icc(gen_ssa0(6,3), ...)` on the default path aborts with
  "49% of draws were non-finite" and no bullet, while
  `ci_method = "bootstrap"` returns a usable interval on the same data. So the
  motivating benefit does not reach the default call, and a durable record
  states something false.
- **F11 (95) — the classical guard's tier 1 is structurally dead, at a 25.6 s
  cost.** `searle_ci()` and `burch_ci()` compute the same `ss` and both call
  `classical_guard_observed()` on it, so whenever one aborts the other does:
  `Filter(usable, c("searle", "burch"))` at that guard is always empty by
  construction, never by data. Every classical degeneracy abort therefore falls
  through to tier 2 and pays a 999-refit bootstrap. Measured:
  `icc(gen_mse0(6,3), ci_method = "searle")` takes 25.6 s to produce a message
  containing no bullet at all. It was instant before this branch.
- **F8 (85)** — the promised retry is not the verified run when `boot_samples`
  differs in meaning across methods: verification runs `bootstrap_ci()` at the
  caller's `boot_samples` (which meant *subject* resamples for `npbootstrap`),
  while the bullet's promised retry runs at the `bootstrap` default 999.
- **F7 (82)** — the new `@details` sentence asserts unconditionally that the
  error "names a method verified on that same data"; in 3 of 6 measured cases it
  names none. On a milestone about message truthfulness, an unhedged doc claim.
- **F1 (80)** — AC3's test is vacuous: deleting the self-exclusion term leaves
  all six assertions green, because no tested case has the invoked method as a
  candidate. The case where self-exclusion is load-bearing (no caller `seed`,
  verification re-running under `hint_verify_seed`) is untested.

**Logged, not actioned (17 below 80),** one line each: F2 (25) in-suite verdict
table excludes exactly the two new rows — the implement gate's recorded split;
F3 (55) engine-fit-refusal test passes on main for a different reason; F4 (55)
both AC4 tests pass on main; F6 (60) NEWS reads as a default-path improvement;
F9 (50) "That run" singular when two runs occurred; F10 (45) "cannot" framing at
a stochastic guard, inherited from M93; F12 (62) the `@details` cost sentence
frames as exceptional what F11 makes the only case; F13 (55) the
"drift is caught, not trusted" comment overstates what triplicated generators
catch; F14 (45) `sweep_data()` transcribes the jitter magnitude and `n_varying`;
F15 (38) the fixture is a reproducibility check, not an independent oracle;
F16 (32) `run_remedy()` hardcodes `divisor = 2`; F17 (65) the rewritten hotfix
test's per-method loop is near-tautological; F18 (55) that test would mis-fail
if tier-2 methods were ever named there; F19 (68) three stale
`data-raw/abort-remedy-sweep.tsv` path references left by the T1 move; F20 (70)
the AC5 pin hard-codes a glmmTMB convergence count ("55 of 999"), a
cross-platform flake candidate; F21 (60) design-consistency echo of F5;
F22 (28) the hotfix test could have pinned the named set.

**Gate outcome: returned to `in-progress`** (first defect return for this
milestone). F5 and F11 are defects in what the package does for its users,
scored 95, so the M130 return floor is met. Both sit outside every acceptance
criterion — no criterion covers abort latency or the default-path hint — which
is itself the coverage lesson to carry into the fix.

### Second pass, 2026-08-04 (PR #111, at d89024f)

Criterion evidence re-run fresh: `test-reducer-abort-hint.R` 158 assertions, 0
failures, covering AC1-AC9 (AC8 3 cells all under 1.0 s; AC9 the default call
naming `bootstrap`). Full suite 5756 pass / 0 fail / 0 error. `R CMD check`
0/0/0; `lintr` 0; `air`, `document()`, `pkgdown`, `cairn_validate` clean; the
verdict checker 52 cells, 0 disagreements. CI on #111: `lint`,
`check-references`, `format-check`, `pkgdown` green; the platform matrix and
`test-coverage` still running at the gate.

Three fresh-context reviewers, then a scorer holding the diff and the plan. 17
candidate findings; 4 scored >= 80. Two of them demonstrate an acceptance
criterion failing, so the M130 return floor is met again.

**Actioned (>= 80).** Both >= 90-adjacent ones re-confirmed by this session's own
commands rather than accepted from the reviewer:

- **G1 (93) — AC6 does not test the promised call.** When the caller supplied a
  seed the bullet reads "run under your `seed` and `boot_samples = 199`" with no
  `seed = <digits>`, so the test's `promised_args(msg, "seed")` returns `NULL`
  and it re-runs `icc()` UNSEEDED. AC6 requires the re-run to be the promised
  call; an unseeded fresh draw is the very thing M97's seed discipline exists to
  prevent, and it makes the assertion stochastic. The first-pass evidence line
  claiming it ran "at the named seed" was wrong.
- **G5 (85) — AC2's evidence for the two new rows compares two experiments.**
  `data-raw/check-abort-remedy-verdicts.R` is AC2's only cover for `bootstrap`
  and `montecarlo`, and it now checks `boundary_method_usable()` (screened at 25,
  capped at 199) against a fixture column measured by a full `icc()` at 999. The
  "0 disagreements" is coincidental agreement, not the designed identity. Its
  header's cost figures describe a run that no longer happens.
- **G2 (80)** — `NEWS.md` claims a `bootstrap` suggestion "names the `seed` and
  `boot_samples` the trial ran at". False whenever the caller set a seed, where
  the message names only `boot_samples`.
- **G7 (80)** — `R/icc.R:2129` still says the engine-fit tier "is deliberately
  withheld on the Monte-Carlo default path", left from the superseded decision,
  contradicting both the code and a correct comment 100 lines below.

**Logged, not actioned (13 below 80):** G3 (76) `@details` calls `montecarlo`
"model-refitting" and tier 1 "closed form", both false; G4 (78) `@details` says
"every interval method" but `mpl` splices no hint; G6 (76) the
`boundary_method_usable()` header now reads as asserting the engine rows use the
caller's own count, which the cap overturned; G16 (76) three of AC3's six cases
are vacuous on `gen_mse0` and tier-2 self-exclusion is untested; G14 (78) 199 is
a bootstrap-test convention, not an interval one, and the measured 199-vs-999
upper limit differs ~4%; G13 (68) the cap has no floor, so a caller at
`boot_samples = 20` is promised a 20-refit bootstrap; G15 (68) the rewritten
hotfix test would mis-fail if tier 2 were ever named there; G12 (66) the
two-method bullet says "That run" of two runs and attributes `boot_samples` to
`montecarlo`; G9 (60) the sweep helper models the cap but not the screen, a
latent false-failure; G11 (60) the rendering-count comment understates how many
engine-tier forms exist; G8 (45) AC8's wall-clock threshold may flake on slower
runners; G17 (40) `invoked` has a default; G10 (38) the leak guard's re-keying.

**Gate outcome: returned to `in-progress`** (second defect return). One further
return trips the thrash rule.
