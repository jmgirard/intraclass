# Monte-Carlo confidence intervals ---------------------------------------------
#
# PRINCIPLES.md #3: the ICC is a non-normal ratio of variance components and the
# delta method is unreliable near the zero-rater-variance boundary, so the
# default interval is Monte-Carlo, simulated from the fitted parameter covariance
# on the engine's internal (log) scale and back-transformed (ADR-003). Because
# the simulation happens on the unconstrained log scale, every draw maps to
# strictly positive variances -- the interval is boundary-aware by construction.
#
# Seeded for reproducibility (PRINCIPLES.md #12): pass `seed` for a deterministic
# interval; otherwise the ambient RNG is used and the interval is still valid,
# just not reproducible.

# Run `code` with a fixed RNG seed, restoring the caller's RNG state afterward so
# a reproducible interval leaves no side effect on the global stream
# (PRINCIPLES.md #9). Dependency-free stand-in for withr::with_seed().
with_rng_seed <- function(seed, code) {
  has_old <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (has_old) {
    old <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
    # .Random.seed is a base R special name (not our object).
    on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE) # nolint: object_name_linter.
  } else {
    on.exit(
      suppressWarnings(rm(".Random.seed", envir = globalenv())),
      add = TRUE
    )
  }
  set.seed(seed)
  force(code)
}

# Draw from a multivariate normal via a symmetric eigen-decomposition, which
# tolerates a numerically semidefinite covariance (tiny negative eigenvalues
# clamped to 0) at the boundary, where a Cholesky factor would fail.
rmvn <- function(n, mu, covariance) {
  p <- length(mu)
  eig <- eigen(covariance, symmetric = TRUE)
  # Negative eigenvalues are clamped to 0 rather than treated as an error. They
  # arise not only from boundary roundoff but also from LEGITIMATELY rank-deficient
  # fits -- e.g. a confounded crossed design where sigma^2_r and sigma^2_cr alias
  # (the covariance then carries a genuinely large negative eigenvalue). Clamping
  # zeroes that unestimable direction; the requested estimand is protected upstream
  # by the identifiability guards in icc() (which reject a design where the aliased
  # direction feeds a requested coefficient), so a naive "indefinite -> abort" here
  # would wrongly reject correct consistency/subject-level results (ADR-003).
  values <- pmax(eig$values, 0)
  factor <- eig$vectors %*% diag(sqrt(values), p, p)
  draws <- mu + factor %*% matrix(stats::rnorm(p * n), nrow = p)
  rownames(draws) <- names(mu)
  draws
}

# Draw the fitted parameters and back-transform to variance components, on the
# engine's internal (log) scale so every draw is boundary-aware (ADR-003). This
# is the shared sampling step: `mc_ci()` reduces the draws to per-estimand
# quantiles, while `d_study()` reuses the SAME draws across a range of projected
# rater counts (so the reliability curve and its band are internally coherent).
# `mc` is a list with `estimate`, `vcov`, and `to_components` (from the engine
# fit, stored on the `icc` object). Seeded via `with_rng_seed()` (PRINCIPLES.md
# #9, #12); the global RNG stream is left untouched.
mc_components <- function(mc, mc_samples = 10000L, seed = NULL) {
  draw <- function() {
    par <- rmvn(mc_samples, mc$estimate, mc$vcov)
    mc$to_components(par)
  }
  if (is.null(seed)) {
    draw()
  } else {
    with_rng_seed(seed, draw())
  }
}

# Reduce a vector of resampled ICC values (Monte-Carlo draws or bootstrap refits)
# to a two-sided percentile interval + SD. Shared by mc_interval() and
# bootstrap_interval() so the two `ci_method`s report intervals identically
# (only how the values are generated differs).
two_sided_interval <- function(vals, conf_level = 0.95) {
  alpha <- 1 - conf_level
  q <- stats::quantile(vals, c(alpha / 2, 1 - alpha / 2), names = FALSE)
  list(
    conf.low = q[[1]],
    conf.high = q[[2]],
    std.error = stats::sd(vals)
  )
}

# Reduce a set of drawn components to a two-sided quantile interval + SD for one
# estimand. Non-finite draws (e.g. a degenerate covariance direction) are dropped.
mc_interval <- function(
  components,
  estimand,
  conf_level = 0.95,
  call = rlang::caller_env()
) {
  vals <- icc_point(components, estimand)
  finite <- is.finite(vals)
  # Non-finite draws arise only when a variance component overflows to Inf (an
  # astronomically large fitted SD). A handful is harmless roundoff at the tail;
  # a material fraction means an unstable fit, and because the overflow is
  # one-sided (upper tail), silently dropping them would bias the interval down --
  # so fail loudly (PRINCIPLES.md #5) instead of truncating.
  if (mean(!finite) > 0.01) {
    abort_intraclass(
      c(
        "The Monte-Carlo interval could not be computed: \\
         {.val {round(100 * mean(!finite))}}% of draws were non-finite.",
        i = "A variance component overflowed, which indicates an unstable fit.",
        i = "Refit with {.code engine = \"glmmTMB\"} or inspect the model."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }
  two_sided_interval(vals[finite], conf_level)
}

mc_ci <- function(
  engine,
  estimands,
  conf_level = 0.95,
  mc_samples = 10000L,
  seed = NULL
) {
  components <- mc_components(engine, mc_samples = mc_samples, seed = seed)
  lapply(estimands, function(est) mc_interval(components, est, conf_level))
}
