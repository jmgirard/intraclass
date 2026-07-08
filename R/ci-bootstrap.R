# Parametric-bootstrap confidence intervals ------------------------------------
#
# ADR-025 (M16): a second `ci_method` alongside the Monte-Carlo default. Where
# `mc_ci()` draws from the fitted parameter covariance on the engine's log scale
# (ADR-003), the parametric bootstrap simulates response vectors FROM the fitted
# model, refits the same model to each, and takes percentile quantiles of the
# resampled ICCs. Because every resample is a real refit, the interval does not
# lean on the asymptotic-normal covariance approximation -- at the cost of a full
# refit per resample. It is boundary-aware by construction: each refit returns
# variances >= 0, and a resample that lands on the boundary is a valid draw, kept.
#
# The per-engine work (simulate + refit) lives behind the `simulate_refit`
# contract on the engine fit (cf. `to_components` for the MC path), so this
# reducer is engine-agnostic: bootMer for lme4, simulate()+refit for glmmTMB, each
# returning a (component x resample) matrix on the shared component names.

# A resample whose refit failed to converge is NA-filled by the engine; if too
# many fail the interval is unreliable, so warn past `warn_frac` and abort past
# `min_frac` (fail loudly, PRINCIPLES.md #5 / #8) rather than return a quietly
# biased interval from a handful of survivors.
bootstrap_ci <- function(
  engine,
  estimands,
  conf_level = 0.95,
  boot_samples = 999L,
  seed = NULL,
  warn_frac = 0.10,
  min_frac = 0.50,
  call = rlang::caller_env()
) {
  if (is.null(engine$simulate_refit)) {
    abort_unsupported(
      c(
        "{.code ci_method = \"bootstrap\"} is not yet available for this \\
         design/engine combination.",
        i = "Use {.code ci_method = \"montecarlo\"} (the default)."
      ),
      call = call
    )
  }

  draws <- engine$simulate_refit(boot_samples, seed = seed)
  ok <- colSums(is.na(draws)) == 0L
  n_ok <- sum(ok)
  n_fail <- length(ok) - n_ok

  if (n_ok < min_frac * boot_samples || n_ok < 2L) {
    abort_intraclass(
      c(
        "The bootstrap interval could not be computed: only \\
         {.val {n_ok}} of {.val {boot_samples}} refits converged.",
        i = "This usually means the model is near a variance boundary or the \\
             design is too small to resample stably.",
        i = "Use {.code ci_method = \"montecarlo\"} or inspect the model."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }
  if (n_fail > warn_frac * boot_samples) {
    warn_intraclass(
      c(
        "{.val {n_fail}} of {.val {boot_samples}} bootstrap refits did not \\
         converge and were dropped.",
        i = "The interval is based on the {.val {n_ok}} that did; treat it with \\
             caution."
      ),
      class = "intraclass_bootstrap_dropouts"
    )
  }

  # Row-per-component matrix -> named list of resample vectors, the shape
  # `icc_point()` consumes (identically to the MC `to_components()` output).
  kept <- draws[, ok, drop = FALSE]
  components <- stats::setNames(
    lapply(rownames(kept), function(r) kept[r, ]),
    rownames(kept)
  )
  out <- lapply(estimands, function(est) {
    two_sided_interval(icc_point(components, est), conf_level)
  })
  # Expose the kept resample components so a D-study projection can reproject them
  # across `m` without a second round of refits (M18 Slice 4, ADR-028). The fit
  # stores these on its `boot` slot; the band then reuses the SAME resamples that
  # produced the reported interval, so at `m = k_eff` the two coincide.
  attr(out, "components") <- components
  out
}
