# Modified-profile-likelihood interval for the two-way random ICC(A,1) ----------
#
# Exported as `ci_method = "mpl"` (M88, D-015; assessed GO-for-opt-in in M87,
# D-014). The interval of Xiao & Liu (2013), "Modified profile likelihood approach
# for certain intraclass correlation coefficients," Comput Stat 28:2241-2265
# (`cairn/references/xiao2013.md`), for the balanced-complete two-way random
# absolute-agreement ICC(A,1). ICC(A,k) is the monotone Spearman-Brown image of the
# ICC(A,1) endpoints via the shared `npb_sb()` (kappa-independent; the two-way random
# averaged coefficient is kro/(1+(k-1)ro), McGraw & Wong 1996 Table 4 -- coverage
# inherited as an exact event identity, ORACLES basis = inheritance, as D-010/D-013).
#
# This file holds only the DETERMINISTIC interval machinery + the precomputed
# kappa_m lookup: given the correction constant kappa_m, the interval is a pair of
# profile-deviance roots (no resampling), so the exported method is a deterministic
# closed form like "searle"/"burch" (`ci$samples = NA`, no seed/draws). The kappa_m
# CALIBRATION (an MC coverage simulation) lives OFFLINE in data-raw (the M86/M87
# from-scratch reference implementation + the M88 table generator); the runtime only
# looks a value up. Machinery ported from the M86 prototype (`data-raw/m86-mpl-lib.R`),
# oracle-validated against xiao2013 Tables 3/4/6/7 at M86 (IP1).
#
# Notation follows xiao2013 (R raters, S subjects): `n_r` raters, `n_s` subjects;
# `sms`/`rms`/`ems` the subject/rater/error mean squares. A data matrix `y` is
# n_s rows (subjects) x n_r cols (raters) -- the package layout (n subjects x k raters).

# Long (score, subject, rater) -> the balanced-complete n_s x n_r matrix mpl_anova
# expects. Balance/completeness/two-way structure are guarded upstream in icc(); a
# missing cell here is a defensive classed abort (#5/#8), never a silent NA.
mpl_matrix <- function(df, call = rlang::caller_env()) {
  y <- tapply(df$score, list(df$subject, df$rater), mean)
  if (anyNA(y)) {
    abort_intraclass(
      c(
        "The modified-profile-likelihood interval needs complete two-way data.",
        i = "A subject x rater cell had no observation after reshaping."
      ),
      class = "intraclass_unidentified",
      call = call
    )
  }
  matrix(as.numeric(y), nrow = nrow(y), ncol = ncol(y))
}

# ANOVA layout (xiao2013 Table 1, p. 2244): subject/rater/error mean squares.
mpl_anova <- function(y) {
  y <- as.matrix(y)
  n_s <- nrow(y) # subjects
  n_r <- ncol(y) # raters
  gm <- mean(y)
  subj_means <- rowMeans(y)
  rater_means <- colMeans(y)
  ss_subj <- n_r * sum((subj_means - gm)^2) # df n_s - 1
  ss_rater <- n_s * sum((rater_means - gm)^2) # df n_r - 1
  resid <- y -
    outer(subj_means, rep(1, n_r)) -
    outer(rep(1, n_s), rater_means) +
    gm
  ss_err <- sum(resid^2) # df (n_r - 1)(n_s - 1)
  list(
    sms = ss_subj / (n_s - 1),
    rms = ss_rater / (n_r - 1),
    ems = ss_err / ((n_r - 1) * (n_s - 1)),
    n_r = n_r,
    n_s = n_s
  )
}

# -2 log-likelihood, Eq. (7) p. 2245. Parameters rho_s (= the ICC estimand rho) and
# rho_r (nuisance). The additive constant c (Eq. 66) is DROPPED (data- and
# parameter-free -> cancels in every deviance/MLE below). The four eigenvalues are
# xiao2013 Appendix Eqs. 37-40; the weighted-SS term pairs subject/rater/error SS
# with lam2/lam3/lam4 by matching eigenvalue multiplicity.
mpl_neg2l <- function(rho_s, rho_r, ms) {
  n_r <- ms$n_r
  n_s <- ms$n_s
  lam1 <- 1 + (n_r - 1) * rho_s + (n_s - 1) * rho_r
  lam2 <- 1 + (n_r - 1) * rho_s - rho_r
  lam3 <- 1 - rho_s + (n_s - 1) * rho_r
  lam4 <- 1 - rho_s - rho_r
  if (rho_s <= 0 || rho_r <= 0 || min(lam1, lam2, lam3, lam4) <= 0) {
    return(Inf)
  }
  det_term <- log(lam1) +
    (n_s - 1) * log(lam2) +
    (n_r - 1) * log(lam3) +
    (n_r - 1) * (n_s - 1) * log(lam4)
  quad <- (n_s - 1) *
    ms$sms /
    lam2 +
    (n_r - 1) * ms$rms / lam3 +
    (n_r - 1) * (n_s - 1) * ms$ems / lam4
  if (quad <= 0) {
    return(Inf)
  }
  det_term + n_r * n_s * log(quad)
}

# Profile -2l at fixed rho (= rho_s): minimise over rho_r in (0, 1-rho), with a
# short Brent polish so the profile is tight enough for stable root-finding.
mpl_prof_neg2l <- function(rho, ms, tol = 1e-11) {
  hi <- 1 - rho - 1e-9
  if (hi <= 1e-9) {
    return(Inf)
  }
  o <- stats::optimise(
    function(rr) mpl_neg2l(rho, rr, ms),
    c(1e-9, hi),
    tol = tol
  )
  lo2 <- max(1e-9, o$minimum - 1e-3)
  hi2 <- min(hi, o$minimum + 1e-3)
  o2 <- stats::optimise(
    function(rr) mpl_neg2l(rho, rr, ms),
    c(lo2, hi2),
    tol = tol
  )
  min(o$objective, o2$objective)
}

# Global MLE: minimise -2l over (rho_s, rho_r) jointly. A nested 1-D scan seeds a
# 2-D Nelder-Mead polish so the deviance reference min is precise (imprecision here
# biases every deviance and shifts the interval systematically).
mpl_fit <- function(ms) {
  scan <- stats::optimise(
    function(r) mpl_prof_neg2l(r, ms),
    c(1e-6, 1 - 1e-6),
    tol = 1e-11
  )
  rho0 <- scan$minimum
  rr0 <- stats::optimise(
    function(rr) mpl_neg2l(rho0, rr, ms),
    c(1e-9, 1 - rho0 - 1e-9),
    tol = 1e-11
  )$minimum
  pol <- stats::optim(
    c(rho0, rr0),
    function(p) mpl_neg2l(p[1], p[2], ms),
    method = "Nelder-Mead",
    control = list(reltol = 1e-13, maxit = 2000)
  )
  if (pol$value <= scan$objective) {
    list(rho_hat = pol$par[1], rho_r_hat = pol$par[2], neg2l_min = pol$value)
  } else {
    list(rho_hat = rho0, rho_r_hat = rr0, neg2l_min = scan$objective)
  }
}

# Deviance D(rho) = -2l_prof(rho) - min(-2l) >= 0.
mpl_deviance <- function(rho, ms, neg2l_min = NULL) {
  if (is.null(neg2l_min)) {
    neg2l_min <- mpl_fit(ms)$neg2l_min
  }
  mpl_prof_neg2l(rho, ms) - neg2l_min
}

# Interval, Eq. (9) two-sided / Eq. (10) one-sided, p. 2245.
# CI = { rho : D(rho) <= (1+kappa) * chi^2_{1,1-alpha} }.  kappa = 0 is naive PL;
# kappa = kappa_m is MPL. `side = "lower"` gives a one-sided lower bound; per the LRT
# one-sided convention its crit uses 1-2*alpha, so a 95% lower bound (alpha = 0.05)
# shares the two-sided 90% lower critical value (xiao2013 Ex. 1). A root that runs off
# the parameter space clamps to the [0,1] boundary -- the interval EXISTS on every
# dataset (the residual value D-014 ships mpl for), unlike the MC default's abort.
mpl_interval <- function(
  ms,
  kappa = 0,
  alpha = 0.10,
  side = c("two", "lower")
) {
  side <- match.arg(side)
  fit <- mpl_fit(ms)
  rho_hat <- fit$rho_hat
  crit <- if (side == "two") {
    (1 + kappa) * stats::qchisq(1 - alpha, 1)
  } else {
    (1 + kappa) * stats::qchisq(1 - 2 * alpha, 1)
  }
  f <- function(rho) mpl_deviance(rho, ms, neg2l_min = fit$neg2l_min) - crit
  eps <- 1e-7
  lower <- tryCatch(
    stats::uniroot(f, c(eps, rho_hat), tol = 1e-10)$root,
    error = function(e) 0
  )
  if (side == "lower") {
    return(c(lower = lower, upper = NA_real_, rho_hat = rho_hat))
  }
  upper <- tryCatch(
    stats::uniroot(f, c(rho_hat, 1 - eps), tol = 1e-10)$root,
    error = function(e) 1
  )
  c(lower = lower, upper = upper, rho_hat = rho_hat)
}
