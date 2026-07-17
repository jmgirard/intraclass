<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M56: Multilevel SEM (lavaan) — parametric bootstrap CI

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP5, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m56-lavaan-multilevel-bootstrap · https://github.com/jmgirard/intraclass/pull/62   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: `icc(..., engine = "lavaan", cluster, ci_method = "bootstrap")` on a
      seeded balanced Design-1 dataset returns finite bootstrap intervals at
      both the subject and cluster levels, each containing its point estimate
      and bounded by 1 — and its endpoints agree with the default Monte-Carlo
      interval within a documented Monte-Carlo tolerance (cross-method oracle;
      single-level M21 / ADR-031 bootstrap pattern).
- [x] AC2: a seeded fixture drives ≥1 refit to a between-level Heywood /
      non-convergence; that resample is NA-filled and dropped by the
      `bootstrap_ci()` discard policy, and the reported interval is formed from
      the surviving resamples (guards the two-level discard path, GP7).
- [x] AC3: the bootstrap is reproducible and RNG-hygienic — same `seed` →
      identical interval; the global RNG stream is unchanged across the call
      (`with_rng_seed`, #9/#12).
- [x] AC4: the `verify` slot is clean (`cairn/PROFILE.md`) — `devtools::test()`
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

- [x] T1: Write `lavaan_ml_simulate_refit()` in `R/engine-lavaan.R` —
      close over the two-level fit's implied within/between moments, cluster
      count, and per-cluster subject count; per resample simulate a wide
      two-level dataset (cluster draws + within-cluster subject draws), refit
      the same two-level model with the same options, and return the five
      components via the new `lavaan_multilevel_components()` reader
      (Heywood/non-convergent → NA-fill, seeded via `with_rng_seed`).
- [x] T2: Replace `simulate_refit = NULL` in `fit_lavaan_multilevel()` with the
      new factory (random raters only); confirm `bootstrap_ci()` consumes it
      unmodified (the six-field contract is engine-generic — M54 lesson).
- [x] T3: Tests in `tests/testthat/test-icc-lavaan-multilevel.R` — the AC1
      MC↔bootstrap parity + structural-sanity checks at both levels, the AC2
      discard-path fixture, and the AC3 reproducibility/RNG-hygiene checks
      (`skip_on_cran`, `skip_if_not_installed("lavaan")`).
- [x] T4: Run the `verify` slot; update the roxygen note in
      `fit_lavaan_multilevel()`'s header (the "Bootstrap is deferred" paragraph
      now describes the shipped two-level parametric bootstrap) and
      `@param ci_method` / the `icc()` engine roster prose if they claim "no
      bootstrap" for multilevel lavaan.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-17: created by /milestone-plan (promotes the lavaan-multilevel-siblings
  candidate, part A; plan gate: 3 separate milestones, all planned now).
- 2026-07-17: T1–T4 done. Added `lavaan_multilevel_model()`,
  `lavaan_multilevel_components()`, and `lavaan_ml_simulate_refit()` (two-level
  DGP rebuilt from the five components: cluster means ~ MVN(ν, svb·11'+diag(evb)),
  within devs ~ MVN(0, svw·11'+diag(evw))); wired the factory into
  `fit_lavaan_multilevel` (random raters). MC↔bootstrap endpoint parity oracle:
  subject ≤.01, cluster ≤.016 (n=40/10/5); AC2 discard-path pinned via the direct
  factory (fully-NA failed columns); AC3 reproducibility + RNG hygiene. Updated
  the stale "bootstrap out of scope" assertion, roxygen, and the M54 NEWS bullet.
  air/lintr clean; both lavaan test files green.
- 2026-07-17: status → review. Full suite (installed, NOT_CRAN=true CI=true):
  1725 pass, 0 fail, 0 error, 23 skip; document() no-diff. Ready for review.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Reviewed 2026-07-17 · PR #62 · branch cut from main @ 39e330b (main unmoved, no sync merge).**

### Acceptance-criteria evidence (fresh)

- **AC1** — `test-icc-lavaan-multilevel.R` "multilevel lavaan bootstrap agrees
  with the Monte-Carlo interval": 5/5 pass. Endpoint |Δ| vs the 4000-draw MC
  interval (n=40/10/5): subject ≤ .01, cluster ≤ .016 — inside the pinned .04 /
  .07 index-class-split tolerances; all endpoints finite, estimate contained,
  ≤ 1.
- **AC2** — "the two-level bootstrap refit NA-fills failed/Heywood resamples":
  6/6 pass. Direct factory fixture (svb=1e-3, 8 clusters): 14 finite / 26
  fully-NA columns; NA pattern ∈ {0, k+2} confirms a dropped resample is
  entirely NA (bootstrap_ci keys the discard on a clean column), finite columns
  are positive 5-vectors.
- **AC3** — "reproducible and RNG-hygienic": 3/3 pass. Same seed → identical
  interval; `.Random.seed` identical across the seeded call.
- **AC4** — full installed suite (`NOT_CRAN=true CI=true`): 1725 pass, 0 fail,
  0 error, 23 skip. `air format --check` clean; `lintr::lint_package()` 0 lints.

### Consistency gate

- `cairn_validate.py`: all checks passed (291 advisory pre-migration-ID
  warnings, not gate failures).
- `devtools::document()`: no diff (man/, NAMESPACE unchanged).
- `pkgdown::check_pkgdown()`: OK (no new exports — all three helpers internal).
- NEWS.md: the M54 multilevel-lavaan bullet amended to record the shipped
  bootstrap (no milestone numbers in user-facing text).
- Full R CMD check delegated to the PR CI matrix (the merge gate).

### Three-lens fresh-context review — zero findings

- **[O] diff-bug (Opus):** no findings. Verified the two-level generating
  covariance (between = svb·11'+diag(evb) @ μ=ν; within = svw·11'+diag(evw) @
  μ=0), the refit uses the identical shared model string + options, the
  fully-NA discard contract (no partial-NA/wrong-length path), cluster
  broadcasting alignment, `with_rng_seed` hygiene, and reader↔inline-point-path
  agreement; no collateral breakage of the single-level or MC paths.
- **[S] blame-history (Sonnet):** no findings. M56 properly *supersedes* the
  M54 `simulate_refit = NULL` deferral — whose stated reason was "unestablished"
  (D-005's establish-by-oracle-first) — by supplying the O-SEM-ML-BOOT
  cross-method oracle (stronger than the single-level M21 precedent's
  structural-only checks); the removed test assertion is legitimately obsolete
  (it locked the now-supported cell); the refactor leaves the M54 point path
  byte-identical.
- **[S] prior-PR-comments (Sonnet):** no prior-PR evidence — the merged PRs
  touching these files carry only codecov-bot comments, no human review points.

Scorer not invoked (empty findings list). No fixes, follow-ups, or rejections.
