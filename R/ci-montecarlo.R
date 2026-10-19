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
rmvn <- function(
  n,
  mu,
  covariance,
  call = rlang::caller_env(),
  hint = character(0)
) {
  p <- length(mu)
  # A non-finite parameter covariance means the fit did not identify some component
  # (an over-parameterized or degenerate model -- e.g. a ragged replicate design with
  # too few replicated cells to separate the interaction from pure error). `eigen()`
  # would crash with an unclassed error, so fail loudly with a classed one (#5/#8).
  if (anyNA(covariance) || any(!is.finite(covariance))) {
    abort_intraclass(
      c(
        "The Monte-Carlo interval could not be computed: the fitted parameter \\
         covariance is not finite.",
        i = "A variance component was not identified: the model is \\
             over-parameterized or degenerate for this design. For replicates, \\
             this means too few cells were rated more than once to separate the \\
             interaction from pure error.",
        i = "Provide more replicated cells (or a less degenerate design), or \\
             aggregate to one rating per subject-by-rater cell.",
        # M93: the design-aware opt-in `ci_method` bullet, or nothing.
        hint
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }
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
# fit, stored on the `intraclass_icc` object). Seeded via `with_rng_seed()`
# (PRINCIPLES.md #9, #12); the global RNG stream is left untouched.
mc_components <- function(
  mc,
  mc_samples = 10000L,
  seed = NULL,
  hint = character(0)
) {
  draw <- function() {
    par <- rmvn(mc_samples, mc$estimate, mc$vcov, hint = hint)
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
  call = rlang::caller_env(),
  hint = character(0),
  engine = NULL
) {
  vals <- icc_point(components, estimand)
  finite <- is.finite(vals)
  # Non-finite draws arise only when a variance component overflows to Inf (an
  # astronomically large fitted SD). A handful is harmless roundoff at the tail;
  # a material fraction means an unstable fit, and because the overflow is
  # one-sided (upper tail), silently dropping them would bias the interval down --
  # so fail loudly (PRINCIPLES.md #5) instead of truncating.
  # The remedy names the glmmTMB engine only to a caller on another engine: a
  # glmmTMB fit told to refit with glmmTMB is told nothing (M158). `engine` is
  # the engine object, as in `mc_ci()`; NULL (a caller that does not pass it)
  # keeps the line.
  remedy <- if (identical(engine$engine, "glmmTMB")) {
    "Inspect the data and the fitted model."
  } else {
    "Refit with {.code engine = \"glmmTMB\"} or inspect the model."
  }
  if (mean(!finite) > 0.01) {
    abort_intraclass(
      c(
        "The Monte-Carlo interval could not be computed: \\
         {.val {round(100 * mean(!finite))}}% of draws were non-finite.",
        i = "A variance component overflowed, which indicates an unstable fit.",
        i = remedy,
        # M93: the design-aware opt-in `ci_method` bullet, or nothing.
        hint
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }
  two_sided_interval(vals[finite], conf_level)
}

# The zero-width refusal (D-048; narrowed by D-049, M158). A glmmTMB fit that
# leaves a variance at zero can put every Monte-Carlo draw or bootstrap refit on
# the same ICC, so the interval collapses to a point: data with no variation
# within subjects printed 1 [1, 1]. That describes no uncertainty in the data,
# so an interval whose two limits are finite and exactly equal is refused rather
# than reported. Only exact equality: a width bound also refused correct tight
# intervals of near-perfect agreement (M158 review), and no bound tells those
# from a false zero, which the second start of `fit_glmmtmb_ml_model()` handles.
# Gated to glmmTMB and lme4 fits (D-053, M162). The lavaan and brms engines
# meet the boundary through their own guards (D-004), and a lavaan fit is
# pinned as not refused here. lme4 intervals that print as [1, 1] on near-flat
# data have limits that differ in the last digits, so they are reported, with
# the warning of `warn_unresolved_interval()` below (D-054, D-056). Shared by `mc_ci()`,
# `bootstrap_ci()`, and `check_band_single_rating()` of `d_study()` (D-058).
refuse_zero_width <- function(
  intervals,
  engine,
  call = rlang::caller_env(),
  hint = character(0)
) {
  if (!isTRUE(engine$engine %in% c("glmmTMB", "lme4"))) {
    return(invisible(intervals))
  }
  equal <- vapply(
    intervals,
    function(iv) {
      is.finite(iv$conf.low) &&
        is.finite(iv$conf.high) &&
        iv$conf.low == iv$conf.high
    },
    logical(1)
  )
  if (any(equal)) {
    abort_intraclass(
      c(
        "The interval could not be computed: its lower and upper limits are \\
         equal.",
        i = "An interval with no width says nothing about the uncertainty in \\
             your data.",
        i = "Inspect the data and the fitted variances, for example for scores \\
             that do not vary within subjects.",
        hint
      ),
      class = c("intraclass_zero_width_interval", "intraclass_singular_fit"),
      call = call
    )
  }
  invisible(intervals)
}

# The gap from 1 below which a single-rating interval is warned about (D-054).
unresolved_interval_bound <- 1e-12

# The warning on intervals near 1 (D-054, M163; D-056, M164). On near-flat or
# exactly additive data, lme4 reports intervals whose lower limit lies within
# about 1e-13 of 1 and whose limits differ, so `refuse_zero_width()` lets them
# through. Data with rater noise of about 1e-7 of the score spread give
# intervals of the same width, and those are correct (the SEARLE exact-F
# interval agrees, M163 work log), so a refusal is ruled out (D-049). Instead
# the interval is reported, and one classed warning says that data with almost
# no residual variation can give it. Called after
# `refuse_zero_width()`, so equal limits abort first. Takes no `hint`: forcing
# that promise would run the hint's trial fits. Gated to glmmTMB and lme4 fits,
# as the refusal is. The bound is set on the single-rating scale. A row whose
# error terms are divided by d lies about d times nearer 1, so each row is read
# against the bound divided by the largest of its error divisors, the occasion
# count included where the row averages occasions (D-056). Without that, an
# average-rater row warned on data the engines resolve (M163 review, D-055).
warn_unresolved_interval <- function(intervals, estimands, engine) {
  if (!isTRUE(engine$engine %in% c("glmmTMB", "lme4"))) {
    return(invisible(intervals))
  }
  near <- near_one(intervals, estimands)
  n <- sum(near)
  if (n > 0L) {
    rows <- collapse_and(
      vapply(estimands[near], unresolved_row_name, character(1))
    )
    projected <- any(vapply(
      estimands[near],
      function(est) is.numeric(est$unit),
      logical(1)
    ))
    bound_text <- c(
      "For a single-rating row, a lower limit is near 1 when it lies within \\
       1e-12 of 1. For a row that averages ratings over raters or occasions, \\
       1e-12 is divided by the number of ratings, or effective ratings, it \\
       averages.",
      if (projected) {
        "For a numeric {.arg unit}, the number of raters is the projected count."
      }
    )
    warn_intraclass(
      c(
        "{n} interval{?s} {?has/have} a lower limit near 1: {rows}.",
        i = paste(bound_text, collapse = " "),
        i = "{cli::qty(n)}Data with almost no residual variation can give \\
             {?such an interval/such intervals}, so {?its width/their widths} \\
             may reflect rounding rather than your data.",
        i = "Suppress the {.cls intraclass_unresolved_interval} warning class \\
             to silence this."
      ),
      class = "intraclass_unresolved_interval"
    )
  }
  invisible(intervals)
}

# Which intervals have a finite lower limit within 1e-12/d of 1, d the largest
# error divisor of each interval's estimand (D-056). Shared by
# `warn_unresolved_interval()` and `warn_unresolved_band()`. The gap
# `1 - low` is compared, not `low` with `1 - bound / d`: from d of about 4500,
# `1 - bound / d` rounds to one of the two largest doubles below 1, and from
# about 18000 to 1, so a lower limit there would not warn (M164 review). Above
# d of about 9000 the bound is below the smallest gap a double below 1 has, so
# only a lower limit of exactly 1 is near, and its equal limits abort first.
near_one <- function(intervals, estimands) {
  vapply(
    seq_along(intervals),
    function(i) {
      low <- intervals[[i]]$conf.low
      d <- max(unlist(estimands[[i]]$error_divisors))
      isTRUE(is.finite(low) && 1 - low < unresolved_interval_bound / d)
    },
    logical(1)
  )
}

# The near-1 warning for a `d_study()` band (D-058, M166). `intervals` are the
# single-rating intervals that `check_band_single_rating()` reads, one per
# curve, so d is 1 and the bound is 1e-12, the scale D-054 set it on. The
# message says the coefficients it names are the single-rating coefficients
# behind the projected curves, since a call need not report a one-rater row.
# Gated to glmmTMB and lme4 fits, as `warn_unresolved_interval()` is.
warn_unresolved_band <- function(intervals, estimands, engine) {
  if (!isTRUE(engine$engine %in% c("glmmTMB", "lme4"))) {
    return(invisible(intervals))
  }
  near <- near_one(intervals, estimands)
  n <- sum(near)
  if (n > 0L) {
    rows <- collapse_and(
      vapply(estimands[near], unresolved_row_name, character(1))
    )
    warn_intraclass(
      c(
        "{n} single-rating coefficient{?s} behind the projected curves \\
         {?has a lower limit/have lower limits} near 1: {rows}.",
        i = "{.fn d_study} reads each curve's coefficient at one rater, and at \\
             one occasion on a replicate fit, from the same draws as the band. \\
             A lower limit is near 1 when it lies within 1e-12 of 1.",
        i = "Data with almost no residual variation can give such an interval, \\
             so the band's width may reflect rounding rather than your data.",
        i = "Suppress the {.cls intraclass_unresolved_interval} warning class \\
             to silence this."
      ),
      class = "intraclass_unresolved_interval"
    )
  }
  invisible(intervals)
}

# The name of a row in the near-1 warning: the coefficient label, with the
# level of a multilevel row and the occasion count of a replicate row, since
# two rows can share a label and differ only by those (D-056, M164).
unresolved_row_name <- function(estimand) {
  name <- estimand$label
  level <- estimand$level
  if (length(level) == 1L && !is.na(level)) {
    name <- sprintf("%s at the %s level", name, level)
  }
  occ <- estimand$occasions
  if (length(occ) == 1L && !is.na(occ)) {
    name <- sprintf(
      "%s over %s occasion%s",
      name,
      format(occ, trim = TRUE),
      if (occ == 1) "" else "s"
    )
  }
  name
}

# Joins names as "a", "a and b", or "a, b, and c", in full. cli's `{x}`
# collapse shows only the first 20 and the last of a longer vector, and the
# near-1 warning names every row (M164 review).
collapse_and <- function(x) {
  n <- length(x)
  if (n <= 2L) {
    return(paste(x, collapse = " and "))
  }
  paste0(paste(x[-n], collapse = ", "), ", and ", x[n])
}

mc_ci <- function(
  engine,
  estimands,
  conf_level = 0.95,
  mc_samples = 10000L,
  seed = NULL,
  hint = character(0),
  call = rlang::caller_env()
) {
  components <- mc_components(
    engine,
    mc_samples = mc_samples,
    seed = seed,
    hint = hint
  )
  out <- lapply(estimands, function(est) {
    mc_interval(
      components,
      est,
      conf_level,
      call = call,
      hint = hint,
      engine = engine
    )
  })
  refuse_zero_width(out, engine, call = call, hint = hint)
  warn_unresolved_interval(out, estimands, engine)
  out
}
