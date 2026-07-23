# data-raw/m86-mpl-lib.R
#
# M86 prototype library: naive- and modified-profile-likelihood (MPL) interval
# machinery for the two-way random ICC(A,1), from Xiao & Liu (2013), "Modified
# profile likelihood approach for certain intraclass correlation coefficients,"
# Comput Stat 28:2241-2265 (`cairn/references/xiao2013.md`).
#
# NOT package code. A committed, seeded prototype for the M86/M87 GO/NO-GO pass;
# no `R/` surface, no export. Correctness is established by reproducing xiao2013's
# published Tables 3/4/6/7 (see data-raw/m86-mpl-validate.R).
#
# Notation maps xiao2013's uppercase (R raters, S subjects; index i = rater,
# j = subject -- transposed from shrout1979/this package) to snake_case for the
# package lint config: n_r = R raters, n_s = S subjects, sms/rms/ems = the
# subject/rater/error mean squares. A data matrix `y` is n_s rows (subjects) x
# n_r cols (raters) -- the package layout (n subjects x k raters).

# --- ANOVA layout (xiao2013 Table 1, p. 2244) ------------------------------
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

# --- -2 log-likelihood, Eq. (7) p. 2245 ------------------------------------
# Parameters rho_s (= the ICC estimand rho), rho_r (nuisance). The additive
# constant c (Eq. 66) is DROPPED (data- and parameter-free -> cancels in every
# deviance/MLE below). The four eigenvalues are xiao2013 Appendix Eqs. 37-40;
# the weighted-SS term pairs subject/rater/error SS with lam2/lam3/lam4 by
# matching eigenvalue multiplicity.
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
  o <- optimise(function(rr) mpl_neg2l(rho, rr, ms), c(1e-9, hi), tol = tol)
  lo2 <- max(1e-9, o$minimum - 1e-3)
  hi2 <- min(hi, o$minimum + 1e-3)
  o2 <- optimise(function(rr) mpl_neg2l(rho, rr, ms), c(lo2, hi2), tol = tol)
  min(o$objective, o2$objective)
}

# Global MLE: minimise -2l over (rho_s, rho_r) jointly. A nested 1-D scan seeds
# a 2-D Nelder-Mead polish so the deviance reference min is precise (imprecision
# here biases every deviance and shifts the interval systematically).
mpl_fit <- function(ms) {
  scan <- optimise(
    function(r) mpl_prof_neg2l(r, ms),
    c(1e-6, 1 - 1e-6),
    tol = 1e-11
  )
  rho0 <- scan$minimum
  rr0 <- optimise(
    function(rr) mpl_neg2l(rho0, rr, ms),
    c(1e-9, 1 - rho0 - 1e-9),
    tol = 1e-11
  )$minimum
  pol <- optim(
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

mpl_mle <- function(ms) mpl_fit(ms)$rho_hat

# Deviance D(rho) = -2l_prof(rho) - min(-2l) >= 0.
mpl_deviance <- function(rho, ms, neg2l_min = NULL) {
  if (is.null(neg2l_min)) {
    neg2l_min <- mpl_fit(ms)$neg2l_min
  }
  mpl_prof_neg2l(rho, ms) - neg2l_min
}

# --- Intervals, Eq. (9) two-sided / Eq. (10) one-sided, p. 2245 ------------
# CI = { rho : D(rho) <= (1+kappa) * chi^2_{1,1-alpha} }.  kappa = 0 is naive
# PL; kappa = kappa_m is MPL. `side = "lower"` gives a one-sided lower bound; per
# the LRT one-sided convention its crit uses 1-2*alpha, so a 95% lower bound
# (alpha = 0.05) shares the two-sided 90% lower critical value (xiao2013 Ex. 1).
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
    (1 + kappa) * qchisq(1 - alpha, 1)
  } else {
    (1 + kappa) * qchisq(1 - 2 * alpha, 1)
  }
  f <- function(rho) mpl_deviance(rho, ms, neg2l_min = fit$neg2l_min) - crit
  eps <- 1e-7
  lower <- tryCatch(
    uniroot(f, c(eps, rho_hat), tol = 1e-10)$root,
    error = function(e) 0
  )
  if (side == "lower") {
    return(c(lower = lower, upper = NA_real_, rho_hat = rho_hat))
  }
  upper <- tryCatch(
    uniroot(f, c(rho_hat, 1 - eps), tol = 1e-10)$root,
    error = function(e) 1
  )
  c(lower = lower, upper = upper, rho_hat = rho_hat)
}

# --- kappa_corr / kappa_m calibration (xiao2013 Eqs. 11-13, pp. 2247-2251) --
# kappa_corr(rho, delta) is the kappa making the (1-alpha) interval exact at
# that (rho, delta). The naive interval covers rho_true iff D(rho_true) <= crit,
# so coverage = P(D <= (1+kappa) chi^2). Setting it to 1-alpha gives the
# Bartlett-type MC estimator
#   kappa_corr = quantile_{1-alpha}( D(rho_true) ) / chi^2_{1, q} - 1,
# with q = 1-alpha (two-sided) or 1-2*alpha (one-sided lower) -- the same crit
# base mpl_interval() uses. This is the MC realisation of xiao2013's seven-step
# procedure; it is validated against the published Table 3 kappa_m (Eq. 11).
mpl_kappa_corr <- function(
  rho,
  delta,
  n_r,
  n_s,
  alpha = 0.10,
  side = c("two", "lower"),
  n_mc = 2000
) {
  side <- match.arg(side)
  q <- if (side == "two") 1 - alpha else 1 - 2 * alpha
  chi <- qchisq(q, 1)
  dev <- numeric(n_mc)
  for (i in seq_len(n_mc)) {
    ms <- mpl_anova(mpl_simulate(rho, delta, n_r, n_s))
    dev[i] <- mpl_deviance(rho, ms)
  }
  as.numeric(quantile(dev, probs = 1 - alpha, names = FALSE) / chi - 1)
}

# kappa_m = max_{rho in [rho_L, rho_U], delta in [delta_L, delta_U]} kappa_corr
# (Eq. 11). Grid defaults follow xiao2013 p. 2248: rho step d = 0.05, delta_j =
# 2^j over j = -1..4 (so delta in {0.5,1,2,4,8,16}, delta_U = 16). Returns the
# max plus the per-cell grid for inspection.
mpl_kappa_m <- function(
  n_r,
  n_s,
  alpha = 0.10,
  side = c("two", "lower"),
  rho_l = 0.6,
  rho_u = 0.9,
  d = 0.05,
  deltas = 2^(-1:4),
  n_mc = 2000
) {
  side <- match.arg(side)
  rhos <- seq(rho_l, rho_u, by = d)
  grid <- expand.grid(rho = rhos, delta = deltas)
  grid$kappa_corr <- mapply(
    function(rho, delta) {
      mpl_kappa_corr(
        rho,
        delta,
        n_r,
        n_s,
        alpha = alpha,
        side = side,
        n_mc = n_mc
      )
    },
    grid$rho,
    grid$delta
  )
  list(kappa_m = max(grid$kappa_corr), grid = grid)
}

# --- DGP: balanced two-way random, absolute agreement -----------------------
# Given (rho, delta = sigma^2_r/sigma^2_e), total variance fixed at 1:
#   sigma^2_s = rho ; sigma^2_e = (1-rho)/(1+delta) ; sigma^2_r = delta*sigma^2_e.
mpl_components <- function(rho, delta) {
  s2e <- (1 - rho) / (1 + delta)
  c(s2s = rho, s2r = delta * s2e, s2e = s2e)
}

mpl_simulate <- function(rho, delta, n_r, n_s) {
  cmp <- mpl_components(rho, delta)
  s <- rnorm(n_s, sd = sqrt(cmp["s2s"]))
  r <- rnorm(n_r, sd = sqrt(cmp["s2r"]))
  e <- matrix(rnorm(n_s * n_r, sd = sqrt(cmp["s2e"])), nrow = n_s, ncol = n_r)
  outer(s, rep(1, n_r)) + outer(rep(1, n_s), r) + e
}
