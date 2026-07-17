<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M56: Multilevel SEM (lavaan) — parametric bootstrap CI

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP5, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Serve `ci_method = "bootstrap"` for the shipped crossed (Design 1) random-rater
balanced multilevel lavaan fit via a two-level parametric `simulate_refit`.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a two-level parametric-bootstrap factory (analog of the single-level
[`lavaan_simulate_refit()`](../../R/engine-lavaan.R), M21 Slice 1 / ADR-031) that
simulates wide two-level datasets from the fitted model's implied within- and
between-level moments, refits the same two-level CFA per resample, recomputes
both-level ICCs, and returns the shared `(component × resample)` contract;
wiring it into [`fit_lavaan_multilevel()`](../../R/engine-lavaan.R) in place of
the current `simulate_refit = NULL`; the existing `bootstrap_ci()` discard
policy (Heywood / non-convergent refits NA-filled and dropped, #5/#8). Only the
already-shipped cell: crossed Design 1, **random** raters, complete/balanced,
equal cluster sizes.

**Out:** fixed-rater multilevel lavaan → M57; incomplete/unbalanced multilevel
lavaan → M58; nested-design lavaan (no two-level SEM parameterization yet) →
still refused upstream. The Monte-Carlo interval stays the default; this only
adds the opt-in bootstrap.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: `icc(..., engine = "lavaan", cluster, ci_method = "bootstrap")` on a
      seeded balanced Design-1 dataset returns finite bootstrap intervals at
      both the subject and cluster levels, each containing its point estimate
      and bounded by 1 — and its endpoints agree with the default Monte-Carlo
      interval within a documented Monte-Carlo tolerance (cross-method oracle;
      single-level M21 / ADR-031 bootstrap pattern).
- [ ] AC2: a seeded fixture drives ≥1 refit to a between-level Heywood /
      non-convergence; that resample is NA-filled and dropped by the
      `bootstrap_ci()` discard policy, and the reported interval is formed from
      the surviving resamples (guards the two-level discard path, GP7).
- [ ] AC3: the bootstrap is reproducible and RNG-hygienic — same `seed` →
      identical interval; the global RNG stream is unchanged across the call
      (`with_rng_seed`, #9/#12).
- [ ] AC4: the `verify` slot is clean (`cairn/PROFILE.md`) — `devtools::test()`
      green (installed-package suite, `NOT_CRAN=true CI=true`), `air format
      --check` and `lintr::lint_package()` clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T3
- AC3 → T1, T3
- AC4 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Write `lavaan_multilevel_simulate_refit()` in `R/engine-lavaan.R` —
      close over the two-level fit's implied within/between moments, cluster
      count, and per-cluster subject count; per resample simulate a wide
      two-level dataset (cluster draws + within-cluster subject draws), refit
      the same two-level model with the same options, and return the five
      components via the existing `lavaan`-multilevel component reader
      (Heywood/non-convergent → NA-fill, seeded via `with_rng_seed`).
- [ ] T2: Replace `simulate_refit = NULL` in `fit_lavaan_multilevel()` with the
      new factory (random raters only); confirm `bootstrap_ci()` consumes it
      unmodified (the six-field contract is engine-generic — M54 lesson).
- [ ] T3: Tests in `tests/testthat/test-icc-lavaan-multilevel.R` — the AC1
      MC↔bootstrap parity + structural-sanity checks at both levels, the AC2
      discard-path fixture, and the AC3 reproducibility/RNG-hygiene checks
      (`skip_on_cran`, `skip_if_not_installed("lavaan")`).
- [ ] T4: Run the `verify` slot; update the roxygen note in
      `fit_lavaan_multilevel()`'s header (the "Bootstrap is deferred" paragraph
      now describes the shipped two-level parametric bootstrap) and
      `@param ci_method` / the `icc()` engine roster prose if they claim "no
      bootstrap" for multilevel lavaan.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-17: created by /milestone-plan (promotes the lavaan-multilevel-siblings
  candidate, part A; plan gate: 3 separate milestones, all planned now).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
