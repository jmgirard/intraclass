# M93: Design-aware boundary-abort hint — name the boundary-robust `ci_method` for the design in hand

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP7
- **Branch/PR:** `m93-boundary-abort-hint` · https://github.com/jmgirard/intraclass/pull/100

## Goal

When the Monte-Carlo default aborts near the σ²→0 boundary, have the classed error
name the boundary-robust opt-in `ci_method` that actually applies to the user's
design, instead of only the generic refit/aggregate remedies.

## Scope

**In:** an internal design→method mapping computed from the predicates `icc()` already
holds at its `ci_method` fences (`R/icc.R:1381-1497`) — `oneway`, `multilevel`,
`replicates`, `raters`, `balanced`, `type`, `conf_level` — threaded as extra `i =`
bullets into the CI-stage `intraclass_singular_fit` aborts in `R/ci-montecarlo.R` that
T1 showed reachable at the boundary; a guard test that every method the hint names is
actually accepted on that design; NEWS + `@param` docs.

**Out:** fallback or auto-routing — the default still aborts; replacing the abort with
a classical interval is the `#3`/ADR-003 contract change D-012 fenced out ("A classical
**fallback-on-abort** default behaviour is a distinct, later `#3` question, not decided
here") and stays its own ROADMAP candidate · engine-stage `intraclass_singular_fit`
aborts in `R/engine-lme4.R` / `R/engine-lavaan.R`, where the POINT fit failed and no
`ci_method` is a remedy → candidate row if T1 shows they matter · `R/ci-bootstrap.R:56`,
excluded on T1 evidence (see AC2); that site's own generic remedy names
`ci_method = "montecarlo"`, which also aborts on the degenerate data reaching it →
ROADMAP candidate row · identifiability
aborts (`intraclass_unidentified`), which no interval method fixes · any new
`ci_method`, or widening an existing one's design fence.

## Acceptance criteria

- [ ] AC1: a committed reproduction test builds a near-zero-variance dataset on which
      `icc()` aborts `intraclass_singular_fit` through the DEFAULT Monte-Carlo path,
      and the work log records which abort sites that reproduction actually reaches —
      the hint is added only to sites shown reachable, never to sites assumed so.
- [ ] AC2: `icc()` derives the hint from the predicates it already computes and passes
      it to the two Monte-Carlo boundary aborts T1 showed reachable
      (`R/ci-montecarlo.R:43` non-finite covariance, `:124` non-finite draws); the abort
      class, the leading message, and the existing generic remedies are all unchanged —
      the hint is additive. `R/ci-bootstrap.R:48` is excluded on T1 evidence: it is
      unreachable at the σ²→0 boundary (90/90 refits converged across six geometries
      including exact-zero σ²_s at 5 subjects × 2) and is reached only by degenerate
      data (σ²_e = 0, all-identical scores) on which every method the mapping table
      would name ALSO aborts — so a hint there would point at another abort, which AC3
      forbids.
- [ ] AC3 (GP7): a test asserts over a design grid — one-way balanced and unbalanced,
      two-way random agreement and consistency, fixed-rater, multilevel, and
      within-cell-replicate — that every `ci_method` the hint names for a design is
      ACCEPTED by `icc()` on that design. A hint that points at another abort is a
      test failure, so a later fence change cannot silently rot the mapping.
- [ ] AC4: designs with no boundary-robust opt-in — fixed raters, multilevel,
      replicates, two-way consistency, and an `mpl`-shaped design at a `conf_level`
      outside the calibrated set — receive NO method hint; a test pins the message to
      its generic remedies alone (a blanket "try mpl" is wrong off two-way random
      agreement).
- [ ] AC5: the contract is unchanged — a test asserts the boundary case still aborts
      with class `intraclass_singular_fit` and returns no interval, so nothing here
      implements the D-012-fenced fallback default.
- [ ] AC6: the change is documented where users meet it — a `NEWS.md` entry, and the
      `@param ci_method` boundary-robustness note updated if it does not already say
      an opt-in method exists for the aborting cases.
- [ ] AC7: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; any changed message
      snapshot reviewed deliberately via `testthat::snapshot_review()`, never accepted
      blind.

**Mapping to implement** (each row mirrors a shipped fence; AC3 is what keeps it true):

| design in hand | hint names |
|---|---|
| one-way random, balanced | `"npbootstrap"`, `"searle"`, `"burch"` (D-006/D-010, D-012/D-013) |
| one-way random, unbalanced | `"npbootstrap"` only — `"searle"`/`"burch"` are balanced-only |
| two-way random, agreement, balanced+complete, calibrated `conf_level` | `"mpl"` (D-014/D-015) |
| anything else | nothing — generic remedies only |

## Coverage

- AC1 → T1
- AC2 → T2, T3
- AC3 → T4
- AC4 → T2
- AC5 → T3, T4
- AC6 → T5
- AC7 → T5

## Tasks

- [x] T1: Write the failing reproduction test first: a near-σ²→0 dataset that reaches
      `intraclass_singular_fit` via the default MC path. Then enumerate which of
      `R/ci-montecarlo.R:54`, `R/ci-montecarlo.R:131` and `R/ci-bootstrap.R:56` that
      reproduction actually fires, and log it — M84 showed an engine point-fit can
      crash first and leave a downstream guard unreachable.
- [x] T2: Add the internal hint builder — a pure function of the fence predicates,
      returning a possibly-empty character vector of `i =` bullets — with unit tests
      covering every row of the mapping table, including the empty-hint designs.
- [x] T3: Thread the hint from `icc()` into `mc_ci()`/`mc_components()`/`rmvn()` as an
      argument defaulting to none, so no other caller changes, and append it to the two
      reachable abort sites from T1 (`bootstrap_ci()` dropped by the AC2 amendment).
- [x] T4: Add the GP7 guard test: for each design in the AC3 grid, call `icc()` with
      every `ci_method` the hint names and assert it does not abort.
- [x] T5: NEWS entry, `@param ci_method` touch-up, `devtools::document()`, snapshot
      review, full AC7 gate, PR.

## Work log

- 2026-07-25: created by /milestone-plan (promotes the design-aware boundary-abort-hint candidate; plan gate confirmed D-012's fence bites only the fallback DEFAULT, not a message, and scoped engine-stage aborts out pending T1's reachability finding).
- 2026-07-25: implement gate — hint names each qualifying method with its D-012 one-line character (not a bare list, not a single recommendation); unbalanced one-way is worded as availability, not as "succeeds where the default aborts", since D-012's 0-abort evidence is balanced-only.
- 2026-07-25: T1 reachability finding — of the three planned abort sites, `R/ci-montecarlo.R:124` (non-finite draws) fires on 21/40 two-way and 19/40 one-way near-zero datasets, `R/ci-montecarlo.R:43` (non-finite covariance) on 1/40, and `R/ci-bootstrap.R:48` on 0/90 across six boundary geometries. Site C is reachable only by degenerate data (σ²_e = 0, all-identical scores), where npbootstrap/searle/burch/mpl and montecarlo all abort too.
- 2026-07-25: T2 — `R/boundary-hint.R` adds the pure `boundary_method_hint()`; unit tests cover every mapping row plus the empty-hint designs, incl. the unbalanced+numeric-`unit` case (npbootstrap aborts there, so no hint) and the level set read from `kappa_m_table`.
- 2026-07-25: T3 — `hint` threaded through `mc_ci()`/`mc_components()`/`mc_interval()`/`rmvn()` defaulting to `character(0)`; `icc()` builds it from the fence predicates. `rmvn()`'s new arg sits after `call` so the lavaan engine's positional calls are unaffected, and `d_study()` takes the default. Full suite FAIL 0 / PASS 4281 at `NOT_CRAN=true CI=true`.
- 2026-07-25: T4 — AC3 grid guard added (both halves: every named method is accepted, and every silent design's methods really do abort). Mutation-verified: naming `searle` in the two-way random hint reds 4 assertions, and the grid names the offending row.
- 2026-07-25: T5 — NEWS entry + `@param ci_method` note that the abort names the applicable method (the per-method boundary-robustness prose AC6 asks about was already there, so only the pointer was added). Gate: `devtools::check()` 0/0/0, `devtools::test()` FAIL 0 / PASS 4300, `lintr::lint_package()` clean, `air format --check` clean, `document()` no-diff. No message snapshot changed, so none was accepted.
- 2026-07-25: gated amendment — AC2 and Scope narrowed to the two reachable Monte-Carlo sites; `R/ci-bootstrap.R:56` moved to Out with its evidence, and its misleading `montecarlo` remedy carried out as a candidate row.

## Decisions

## Review
