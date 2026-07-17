<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M57: Multilevel SEM (lavaan) — fixed-rater crossed design

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP5, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m57-lavaan-multilevel-fixed   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Ship `raters = "fixed"` for the crossed (Design 1) multilevel lavaan engine at
the subject and cluster levels on balanced/complete data.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the fixed-rater read of the shipped two-level CFA — the between-level
rater intercepts ν_j yield the Case-3A finite-population θ²_r (McGraw & Wong
1996; the same identity-contrast bias correction the single-level
[`fit_lavaan()`](../../R/engine-lavaan.R) fixed path applies to `vcov()` of the
intercepts) in the **subject**-level rater slot; the **cluster** level reads the
same fit (the estimand keys the cluster error set on `level`, not `raters` —
[icc.R:1510](../../R/icc.R)). Per-MC-draw fixed correction via the shared
`theta2r_moment_draws()` (bias ≠ 0 → 2b + average-floor). Crossed Design 1,
random-cluster-size, balanced/complete only. Narrowing the upstream
fixed-multilevel-lavaan abort ([icc.R:1271](../../R/icc.R)) and adding the
dispatch case in the fixed-multilevel branch ([icc.R:1510](../../R/icc.R)).

**Out:** incomplete/unbalanced fixed cluster level (double-blocked for **all**
engines — ten Hove's open small-`k` estimator + the M9 §9 ICC(c,k) divisor;
stays a parking-lot candidate); incomplete/unbalanced fixed **subject** level →
a candidate row (compounds FIML with the fixed correction; low priority — M58 is
random-only); nested fixed lavaan (no SEM parameterization) → still refused.
Bootstrap for this fixed cell: MC-only ships (`simulate_refit = NULL` for fixed
raters); the parametric bootstrap is deferred to a candidate row (M57 gate,
2026-07-17 — the M56 factory is random-only internally and its cluster-level
bootstrap carries a documented cross-platform flake).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: on a seeded balanced Design-1 dataset, `raters = "fixed"` subject-level
      agreement ICC(A,·) from lavaan agrees with `fit_glmmtmb_multilevel_fixed()`
      (M10 / ADR-019) within the index-class-split tolerance (consistency
      near-exact; agreement asymptotic under the ML-vs-REML gap), and consistency
      is identical to the random-rater case (rater term omitted). Oracle:
      glmmTMB fixed multilevel; McGraw & Wong (1996) Case 3A; ten Hove et al.
      (2022) Eq. 7. (RB tripwire: ip-touching)
- [ ] AC2: the fixed **cluster**-level ICC(c,·) agrees with
      `fit_glmmtmb_multilevel_fixed()` cluster-level (M37 / ADR-047) within the
      index-class-split tolerance (agreement asymptotic under the ML-vs-REML gap).
      Unlike glmmTMB — whose REML random σ²_r gives the M37 balanced θ²_r == σ²_r
      identity — lavaan's random σ²_r is the raw τ²-inflated estimator (ADR-014),
      so the lavaan fixed cluster ICC does **not** equal lavaan's own random
      cluster ICC on balanced data: the two differ by exactly the documented τ²
      finite-population correction that fixing removes (bias = tr(C·V_ν)/(k−1) on
      the between-intercept vcov block), a gap that → 0 as N_c grows and is never
      absorbed into a widened tolerance (GP5).
- [ ] AC3: a direct deterministic unit test (hand-computed, not a coverage sim —
      M51 lesson) pins that the lavaan fixed θ²_r is exactly `max(0, raw − bias)`
      with `bias` the identity-contrast trace of the between-intercept `vcov`
      block, and that the per-draw path applies the 2b + average-floor correction
      (GP7); the documented fixed−random component gap is the finite-population
      correction, never absorbed into a widened tolerance (GP5).
- [ ] AC4: the narrowed guard still aborts loudly (classed `intraclass_unsupported`)
      for fixed lavaan on nested designs, within-cell replicates, and
      incomplete/unbalanced data — each with a message pointing at glmmTMB.
- [ ] AC5: the `verify` slot is clean (`cairn/PROFILE.md`) — `devtools::test()`
      green (installed suite, `NOT_CRAN=true CI=true`), `air format --check` and
      `lintr::lint_package()` clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T3
- AC3 → T1, T3
- AC4 → T2, T3
- AC5 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Extend `fit_lavaan_multilevel()` (`R/engine-lavaan.R`) to accept
      `raters = "fixed"` — read the between-level intercept `vcov` block, form the
      Case-3A bias-corrected θ²_r for the subject-level rater slot (identity
      contrast, cf. the single-level fixed path and `lavaan_components()`), leave
      the cluster error set (σ²_cr) unbiased, and wire the per-draw correction
      into `to_components` via `theta2r_moment_draws()` with `bias ≠ 0`.
      (RB tripwire: ip-touching)
- [ ] T2: Narrow the `icc.R:1271` fixed-multilevel-lavaan abort to admit crossed
      + balanced/complete + equal cluster sizes; add the lavaan case to the
      fixed-multilevel dispatch branch (`icc.R:1510`), routing to
      `fit_lavaan_multilevel(df, raters = "fixed")`; keep nested / replicate /
      incomplete-unbalanced fixed lavaan aborting.
- [ ] T3: Tests in a new `tests/testthat/test-icc-fixed-lavaan-multilevel.R` —
      AC1 subject parity + random-consistency identity, AC2 cluster parity + the
      random-reduction identity, the AC3 deterministic correction guard, and the
      AC4 abort-narrowing checks (`skip_on_cran`,
      `skip_if_not_installed("lavaan")`).
- [ ] T4: Run the `verify` slot; update `@param raters`, the `icc()` engine-roster
      prose, and the `fit_lavaan_multilevel()` header (lavaan now covers crossed
      **fixed** multilevel at both levels on balanced/complete data).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-17: created by /milestone-plan (promotes the lavaan-multilevel-siblings
  candidate, part B; plan gate: 3 separate milestones, all planned now).
- 2026-07-17: /milestone-implement start — set in-progress, branch cut. Gate
  amendments: AC2 corrected (lavaan random σ²_r is raw/τ²-inflated, so fixed
  cluster ICC ≠ lavaan's own random cluster ICC — differs by the τ² correction;
  compare to glmmTMB fixed instead); Scope Out — fixed bootstrap deferred to a
  candidate row, MC-only ships.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
