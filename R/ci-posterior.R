# Posterior credible intervals (ci_method = "posterior", M23 / ADR-033) --------
#
# The third `ci_method`, native to the Bayesian (brms) engine. Where mc_ci() draws from
# the fitted parameter covariance (ADR-003) and bootstrap_ci() refits simulated data
# (ADR-025), the posterior method takes the engine's OWN posterior draws (the `draws`
# field on the brms contract, R/engine-brms.R) and reduces them to:
#   * a MAP point  -- the mode of each estimand's posterior ICC-draw vector, and
#   * a percentile CREDIBLE interval -- reusing the M16 percentile reduction verbatim.
# Both come from the SAME draw matrix because the posterior mode is not
# transform-invariant: MAP(ICC) != icc_point(MAP components), so the ICC point must be the
# mode of the ICC draws, not icc_point() of the modal components (ADR-033). That is why
# this returns point AND interval together (posterior_summary), unlike the mc/bootstrap
# reducers which only build the interval and let icc()'s shared icc_point() path make the
# point -- the Bayesian branch in icc() takes the point from here instead.
#
# WHY MAP, WHY PERCENTILE (sourced, #1/#4). ten Hove, Jorgensen & van der Ark (2020) §4.2
# (Figs 1-5): the posterior MODE (MAP) is unbiased for sigma_r and ICC(A,1) at k > 2 while
# the posterior MEAN (EAP) severely overestimates sigma_r; and PERCENTILE credible
# intervals (not HPDIs) give nominal coverage at k > 2. The coverage oracle that pins this
# (O-Bayes) is M23 Slice 2; Slice 1 wires the reduction.

# Boundary-aware posterior mode of a draw vector (PRINCIPLES.md #3). A reflected kernel
# density estimate: the draws are mirrored across each FINITE bound before the KDE so the
# density is not biased downward at a boundary (the ICC piles up near 0 or 1; a variance
# component near 0), then the mode is the argmax of the estimated density restricted to
# [lower, upper]. Serves both the [0, 1] ICC draws (lower = 0, upper = 1) and the [0, Inf)
# variance-component draws (lower = 0) through its bounds.
#
# BANDWIDTH (#4 guardrail). Silverman's rule (`bw.nrd0`, stats::density's default),
# computed on the ORIGINAL draws. It is fixed A PRIORI -- chosen before any comparison to
# ten Hove 2020 and NOT tuned to reproduce their MAP-bias/coverage numbers; reproducing
# them (Slice 2) is treated as validation of an independent estimator, not a tuning target.
posterior_mode <- function(vals, lower = -Inf, upper = Inf) {
  vals <- vals[is.finite(vals)]
  if (length(vals) < 2L) {
    return(if (length(vals) == 1L) vals[[1]] else NA_real_)
  }
  # A degenerate posterior (all draws essentially equal, e.g. a component pinned at the
  # boundary) has no density to smooth -- return the common value rather than let
  # density()/bw.nrd0() fail on zero spread.
  if (stats::sd(vals) < .Machine$double.eps^0.5) {
    return(stats::median(vals))
  }
  bw <- stats::bw.nrd0(vals)
  aug <- vals
  if (is.finite(lower)) {
    aug <- c(aug, 2 * lower - vals)
  }
  if (is.finite(upper)) {
    aug <- c(aug, 2 * upper - vals)
  }
  # Evaluate on [lower, upper]; on an unbounded side extend by 3 bandwidths, matching
  # stats::density()'s default `cut` so an interior mode near the sample edge is not
  # clipped.
  from <- if (is.finite(lower)) lower else min(vals) - 3 * bw
  to <- if (is.finite(upper)) upper else max(vals) + 3 * bw
  d <- stats::density(aug, bw = bw, from = from, to = to, n = 512L)
  d$x[which.max(d$y)]
}

# Reduce a brms posterior component draw matrix to a per-estimand MAP point + percentile
# credible interval. `draws` is (component x draw) on the natural variance scale (rows
# named as icc_point() expects: subject/rater/residual); it is turned into the named list
# of draw vectors icc_point() consumes (identically to the MC to_components() / bootstrap
# outputs), then each estimand's ICC-draw vector is reduced to its mode (bounded to [0, 1])
# and its two-sided percentile interval (two_sided_interval(), the SAME reduction the
# mc/bootstrap methods use -- only the draws' provenance differs). Returns, per estimand, a
# list with `point`, `conf.low`, `conf.high`, `std.error`.
posterior_summary <- function(draws, estimands, conf_level = 0.95) {
  components <- stats::setNames(
    lapply(rownames(draws), function(r) draws[r, ]),
    rownames(draws)
  )
  lapply(estimands, function(est) {
    vals <- icc_point(components, est)
    vals <- vals[is.finite(vals)]
    interval <- two_sided_interval(vals, conf_level)
    c(list(point = posterior_mode(vals, lower = 0, upper = 1)), interval)
  })
}
