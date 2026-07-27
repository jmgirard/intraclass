# M97: `npbootstrap` in the boundary hint — verified by running it, not predicted

- **Status:** planned
- **Priority:** normal
- **Depends on:** M93
- **Driving RR:** —
- **Principles touched:** GP1, GP7

## Goal

Let the boundary abort name `ci_method = "npbootstrap"` on unbalanced one-way designs —
the only method shipping that cell (D-013) — by RUNNING the bootstrap on the data in
hand and naming it only if it returned a usable interval, rather than predicting from
the design whether its resampling will hold up.

## Scope

**In:** `"npbootstrap"` added to M93's verification helper — the same run-it-and-look-at-
the-interval check, extended to a method that resamples: run `npbootstrap_ci()` at the
shipped `boot_samples` under the seed the user's own call would use, catch every error,
accept only a finite, correctly ordered, in-support interval on every estimand (M93's
predicate, unchanged); the unbalanced one-way row
restored in `boundary_method_hint()` behind it; RNG neutrality (#9) via the existing
`with_rng_seed()`, so a hint that fires cannot perturb the user's stream; a decision,
recorded in this file, on what to do when the caller set no `seed` — a run that succeeds
under one seed can fail under another, measured at this gate as 8/8 seeds succeeding on
a 20×3 design and 1/8 on a 6×2; M93's AC3 sweep extended over imbalance shape incl. the
double-code design; the stale `R/ci-npbootstrap.R:177` comment ("negligibly rare at
k >= 10") corrected against measurement; NEWS + `@param`.

**Out:** deriving an ANALYTIC stability predicate from the observed data (subjects
carrying within-subject variance, ties among subject means) — this milestone's original
premise, dropped at the 2026-07-26 gate once running the bootstrap was measured at
135 ms, which answers the same question exactly rather than approximately; revive only
if the seed question makes running it unworkable · a SECOND verification helper — M93
ships the generic one and M97 registers a method with it; a divergent copy is the
drift pattern that produced M93's pass-2 finding · changing `npbootstrap_ci()`'s own
guards, message or design fence — this evaluates the shipped guard, it does not move it
→ ROADMAP candidate · the deterministic rows → M93 · fallback or auto-routing on abort,
the `#3`/ADR-003 change D-012 fenced out and D-018 draws the line against → standing
ROADMAP candidate.

## Acceptance criteria

- [ ] AC1: `"npbootstrap"` is registered with M93's verification helper rather than
      given a second one — it runs `npbootstrap_ci()` on the data in hand and returns
      TRUE only under M93's unchanged predicate (every estimand finite,
      `conf.low <= conf.high`, in support); every error is caught, so the check itself
      can never turn the boundary abort into a different error (the M93 pass-4 F2
      failure mode, in a new place). A test asserts one helper serves both families.
- [ ] AC2 (#9): the check is RNG-neutral — a committed test captures `.Random.seed`
      across an `icc()` call that fires it and asserts the stream is unchanged, so a
      user who never asked for a bootstrap cannot have their draws perturbed by one.
- [ ] AC3: the no-seed case is decided, and the decision recorded in this file with its
      rationale; a test pins whatever behaviour is chosen. Measured at the plan gate:
      `npbootstrap_ci()` succeeded at 8/8 seeds on a 20×3 design and 1/8 on a 6×2, so
      the risk is real and size-dependent, not theoretical.
- [ ] AC4 (GP7): M93's message-driven sweep, re-run with `npbootstrap` in the mapping
      and extended over imbalance SHAPE (balanced, mildly ragged, and the double-code
      design that defeated M93 pass 3), records ZERO hinted-then-unusable runs at the
      shipped `boot_samples = 999` — never a reduced count, which lowers the chance of
      tripping a guard that fires on any degenerate resample (M93 pass-3 F3).
- [ ] AC5: the added cost is measured and recorded — the check runs only on a path that
      has already failed, and this gate measured 135 ms at 999 resamples; a recorded
      measurement confirms the success path is untouched, the hint being a promise
      forced only inside an abort message.
- [ ] AC6: documented where users meet it — a `NEWS.md` entry, the `@param ci_method`
      note, and `R/ci-npbootstrap.R:177`'s "negligibly rare at k >= 10" comment
      corrected against AC4's measurement (contradicted by it, and pre-existing).
- [ ] AC7: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; snapshot changes
      reviewed via `testthat::snapshot_review()`, never accepted blind; CI green.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T5
- AC5 → T1, T5
- AC6 → T6
- AC7 → T6

## Tasks

- [ ] T1: Register `"npbootstrap"` with M93's verification helper — run
      `npbootstrap_ci()` at the shipped `boot_samples`, catch everything, accept only
      under M93's unchanged predicate — with unit tests over designs where it succeeds
      and where it fails, and record its measured cost.
- [ ] T2: Wrap it RNG-neutral via `with_rng_seed()`, and add the AC2 test capturing
      `.Random.seed` across a firing `icc()` call.
- [ ] T3: Settle the no-seed case at the implement gate and record it here: name it
      anyway with the run as evidence, stay silent unless the caller set a `seed`, or
      name it and say which seed reproduces the run. Pin the choice.
- [ ] T4: Restore the unbalanced one-way row in `boundary_method_hint()` behind the
      check, worded as availability (D-012's 0-abort evidence is a searle/burch result,
      never an npbootstrap one).
- [ ] T5: Extend M93's sweep over imbalance shape at `boot_samples = 999`; require zero
      hinted-then-unusable runs.
- [ ] T6: NEWS, `@param`, the `R/ci-npbootstrap.R:177` comment correction,
      `devtools::document()`, full AC7 gate, PR.

## Work log

- 2026-07-25: created by /milestone-plan as the remainder of the M93 re-cut — the half three M93 review passes could not fence with design predicates (pass-2 F1: raw subject count; pass-3 F1: the count is decoupled from the effective one under imbalance). Depends on M93 because both edit `R/boundary-hint.R` and its test file.
- 2026-07-26: re-scoped at the second M93 re-cut gate — the analytic stability predicate is dropped in favour of RUNNING the bootstrap (135 ms at 999 resamples, on an already-failed path), which answers the same question exactly rather than approximately. The seed question is what keeps this separate from M93: 8/8 seeds succeed on a 20×3 design, 1/8 on a 6×2, so a run is evidence about that seed, not about every seed. GP6 drops from the header slot — the failure axis is no longer swept for a formula, it is run directly.
- 2026-07-26: amended at the M93 third re-cut gate — M93 now adopts verification for the deterministic methods too, and ships the helper generic over a method name, so M97's own T1/AC1 narrow from "add an internal check" to "register `npbootstrap` with M93's helper"; a second copy is explicitly out (the M93 pass-2 drift pattern). M93's acceptance predicate gains an in-support clause (D-010) that M97 inherits unchanged, and D-018 records why running a candidate inside an abort path is not D-012's fenced fallback.

- 2026-07-27: inherited constraint, carried in from the M93 review pass-10 [O] lens so it is not rediscovered here — M93's AC5 leak detector (`num_tokens()`) matches DIGIT strings only, so a leaked NON-finite endpoint (`Inf`, `-Inf`, `NaN`, `NA`) is invisible to both the bullet invariant and the whole-message enumeration. Unreachable in M93 by construction, because a bullet is built only for a method whose every reported endpoint is finite (measured: 0 of 28 endpoints inspected across the guard's grid were non-finite). It becomes live the moment an `npbootstrap` bullet quotes or characterises a REJECTED candidate, which is exactly the shape T3's "name it and say which seed reproduces the run" wording invites. Settle at the M97 implement gate: either keep bullets free of any candidate-derived value, or widen the detector to non-finite tokens before adding such a bullet.

## Decisions

## Review
