# M76 T1/T2/T3 — classical boundary-robust one-way random-ICC confidence
# intervals: SEARLE exact-F (T2) and Burch (2011) REML-based (T3).
#
# NON-EXPORTED research prototype (data-raw/, not R/). Implements the two
# classical intervals so the M76 coverage harness (T4) can compare them against
# the package incumbents (MC default, parametric bootstrap) and the npbootstrap
# bootstrap-t. GO/NO-GO assessment only; ships no exported code (D-006 shape).
#
# Method (Searle 1971 eq. 4/6, as compared by ohyama2025 §2; the same limits are
# in mcgraw1996 Table 7 for ICC(1)). Exact UNDER NORMALITY. Pivot: with
# lambda = sigma_a^2/sigma_e^2 and F = MSA/MSE,
#     (MSA/MSE) / (1 + n0*lambda) ~ F(df1, df2),
# so a 1-alpha interval for (1 + n0*lambda) is [F/F_U, F/F_L] with
# F_U = qf(1-alpha/2, df1, df2), F_L = qf(alpha/2, df1, df2); back-transforming
# g -> rho via rho = (g-1)/(g+n0-1) (the same map as the point estimate
# rho_hat = (F-1)/(F+n0-1)) gives the ICC limits. Monotone, so order-preserving.
#
# n0 is the group size (= n for balanced data, the M76 scope); the unbalanced
# harmonic-mean n0 is shown only to reproduce the ohyama Ex.2 oracle and is NOT
# the balanced construction this milestone assesses.

# --- SEARLE exact-F interval from an ANOVA summary ---------------------------
# msa, mse: between/within mean squares. df1 = k-1, df2 = N-k. n0: group size.
searle_f_ci <- function(msa, mse, df1, df2, n0, conf = 0.95) {
  alpha <- 1 - conf
  f_obs <- msa / mse
  f_u <- stats::qf(1 - alpha / 2, df1, df2)
  f_l <- stats::qf(alpha / 2, df1, df2)
  g_lo <- f_obs / f_u
  g_hi <- f_obs / f_l
  rho_of_g <- function(g) (g - 1) / (g + n0 - 1)
  c(lower = rho_of_g(g_lo), upper = rho_of_g(g_hi))
}

# Convenience: SEARLE interval directly from a balanced long data.frame, reusing
# the M62 one-way ANOVA decomposition convention (subject/rater/y).
searle_f_ci_balanced <- function(df, conf = 0.95) {
  groups <- split(df$y, df$subject)
  k <- length(groups)
  n <- length(groups[[1]])
  ybar_i <- vapply(groups, mean, numeric(1))
  grand <- mean(unlist(groups))
  ssa <- n * sum((ybar_i - grand)^2)
  sse <- sum(vapply(groups, function(g) sum((g - mean(g))^2), numeric(1)))
  searle_f_ci(ssa / (k - 1), sse / (k * (n - 1)), k - 1, k * (n - 1), n, conf)
}

# --- Burch (2011) REML-based CI (kurtosis-adjusted log(1+n*theta) limits) -----
# Primary source: burch2011.md (eq. 6/13/15/16/17). NOTATION TRAP: Burch's a =
# subjects (repo k), b = per-subject (repo n); mapped to repo (k, n) throughout.
# rho = theta/(1+theta). Unlike SEARLE, the interval WIDTH depends on the data
# kurtosis (eq. 13), which is what makes it robust under non-normality.

# eq. 16 empirical variance-inflation g(): fit by Burch (sec 3; a=10, b=5,
# rho=.25) to correct kappa-hat's over/under-estimation of kurtosis. NOT a
# universal identity -- an empirical calibration applied across all cells.
burch_g <- function(kappa_bc) 2.0 * kappa_bc + 0.5 * kappa_bc^2

# eq. 14 term P(k, n) and the normal-data expectation E(kappa-hat); drives the
# bias correction (eq. 15) and the self-consistency oracle below. The three
# terms form the perfect square (n-1)^2 + 2(n-1) + 1 = n^2 in the leading a^2
# coefficient, so 3P/(k^2 n^2) -> 3 and E(kappa-hat) -> 0 as k grows (the
# estimator is consistent); a missing cube on (n-1) breaks that and was the
# transcription bug the self-consistency oracle below caught.
burch_P <- function(k, n) {
  k^3 *
    (n - 1)^3 /
    (k * (n - 1) + 2) +
    2 * k * (n - 1) * (k - 1) +
    (k - 1)^3 / (k + 1)
}
burch_ekappa_normal <- function(k, n) 3 * burch_P(k, n) / (k^2 * n^2) - 3

# eq. 13: kurtosis plug-in from RAW balanced data (needs the individual y_ij),
# standardized by the dataset's own MSE/MSA.
burch_kappa_hat <- function(df, msa, mse) {
  groups <- split(df$y, df$subject)
  grand <- mean(unlist(groups))
  z <- unlist(lapply(groups, function(g) {
    (g - mean(g)) / sqrt(mse) + (mean(g) - grand) / sqrt(msa)
  }))
  mean(z^4) - 3
}

# eq. 15: bias-corrected kurtosis; E(kappa-hat-hat) = 0 under normality by design.
burch_kappa_bc <- function(kappa, k, n) {
  kappa + 3 * (1 - burch_P(k, n) / (k^2 * n^2))
}

# Core eq. 16/17: REML CI for rho from (MSA, MSE, k, n) and the eq. 16 g-value.
# Splitting g out lets the published-example oracles feed the sources' PRINTED
# g(kappa-hat), isolating the CI construction from the raw-data kurtosis pipeline.
burch_reml_ci_core <- function(msa, mse, k, n, g_val, conf = 0.95) {
  theta_hat <- if (msa >= mse) (msa / mse - 1) / n else 0
  one_plus <- 1 + n * theta_hat # = MSA/MSE when MSA >= MSE
  v <- 2 * (g_val / (k * n) + (k * n - 1) / (k * (n - 1) * (k - 1)))
  z <- stats::qnorm(1 - (1 - conf) / 2)
  theta_lo <- (one_plus * exp(-z * sqrt(v)) - 1) / n
  theta_hi <- (one_plus * exp(z * sqrt(v)) - 1) / n
  rho_of_theta <- function(th) th / (1 + th)
  c(lower = rho_of_theta(theta_lo), upper = rho_of_theta(theta_hi))
}

# Full pipeline from a balanced long data.frame: ANOVA -> kappa-hat (eq. 13) ->
# bias-correct (eq. 15) -> g (eq. 16) -> CI (eq. 17). The T4/T5 sweep entry point.
burch_reml_ci_balanced <- function(df, conf = 0.95) {
  groups <- split(df$y, df$subject)
  k <- length(groups)
  n <- length(groups[[1]])
  ybar_i <- vapply(groups, mean, numeric(1))
  grand <- mean(unlist(groups))
  msa <- n * sum((ybar_i - grand)^2) / (k - 1)
  mse <- sum(vapply(groups, function(g) sum((g - mean(g))^2), numeric(1))) /
    (k * (n - 1))
  kappa_bc <- burch_kappa_bc(burch_kappa_hat(df, msa, mse), k, n)
  burch_reml_ci_core(msa, mse, k, n, burch_g(kappa_bc), conf)
}

# --- Oracle validation (ohyama2025 §4 worked examples, pp. 599-600) ----------
# Run non-interactively: Rscript data-raw/m76-classical-oneway-prototype.R
if (sys.nframe() == 0L) {
  fmt <- function(x) sprintf("(%.3f, %.3f)", x[[1]], x[[2]])

  # Oracle 1 -- ohyama2025 Ex.1 PMOC, balanced k=30, n=2. Table 2 (p. 599):
  #   between df 29, MS 185.43; within df 30, MS 22.17. Printed SEARLE (0.600, 0.891).
  #   Residual ~0.001 is the paper's own integer-SS rounding (5377/29 = 185.41 vs a
  #   printed 185.43), flagged in ohyama2025.md; tol 0.002 absorbs it.
  ex1 <- searle_f_ci(msa = 185.43, mse = 22.17, df1 = 29, df2 = 30, n0 = 2)
  cat("Ex.1 PMOC   SEARLE:", fmt(ex1), " oracle (0.600, 0.891)\n")
  stopifnot(
    abs(ex1[["lower"]] - 0.600) < 0.002,
    abs(ex1[["upper"]] - 0.891) < 0.002
  )

  # Oracle 2 (independent type) -- mcgraw1996 Table 7 ICC(1) form on the same ANOVA:
  #   (F_L-1)/(F_L+n0-1), (F_U-1)/(F_U+n0-1) with F_L = F/F*(df1,df2),
  #   F_U = F * F*(df2,df1) (df SWAPPED between limits). Must equal the SEARLE pivot.
  f_obs <- 185.43 / 22.17
  fl <- f_obs / stats::qf(0.975, 29, 30)
  fu <- f_obs * stats::qf(0.975, 30, 29)
  mcgraw <- c((fl - 1) / (fl + 1), (fu - 1) / (fu + 1)) # n0 = 2
  cat(
    "Ex.1 mcgraw Table 7:",
    fmt(mcgraw),
    " (2nd oracle type; must match SEARLE)\n"
  )
  stopifnot(max(abs(mcgraw - ex1)) < 1e-9)

  # Ex.2 PaCO2 (Table 3, p. 600) is UNBALANCED (harmonic mean n0 = 5.02); printed
  # SEARLE (0.232, 0.847). The balanced pivot with a plugged-in harmonic n0 does
  # NOT reproduce it -- expected: ohyama's "SEARLE via eq. (6)" is a distinct
  # unbalanced construction. Printed (no assertion) to document that unbalanced
  # SEARLE is its own derivation, deferred (out of M76's balanced scope).
  ex2 <- searle_f_ci(msa = 2.198, mse = 0.272, df1 = 7, df2 = 38, n0 = 5.02)
  cat(
    "Ex.2 PaCO2  SEARLE:",
    fmt(ex2),
    " oracle (0.232, 0.847) -- unbalanced, expected mismatch\n"
  )

  cat(
    "All balanced SEARLE exact-F oracle checks passed (2 independent types).\n"
  )

  # ---- Burch (2011) REML leg (T3) ----
  cat("\n--- Burch (2011) REML leg ---\n")

  # Oracle A -- ohyama2025 Ex.1 PMOC REML: k=30, n=2, MSA=185.43, MSE=22.17.
  #   ohyama prints the bias-corrected kurtosis kappa-hat-hat = -0.277 and
  #   g(kappa) = -0.515, REML CI (0.620, 0.885). Check g() reproduces -0.515 and
  #   the eq.17 interval reproduces the printed limits.
  stopifnot(abs(burch_g(-0.277) - (-0.515)) < 0.001)
  reml_ex1 <- burch_reml_ci_core(185.43, 22.17, k = 30, n = 2, g_val = -0.515)
  cat("Ex.1 PMOC    REML:", fmt(reml_ex1), " oracle (0.620, 0.885)\n")
  stopifnot(
    abs(reml_ex1[["lower"]] - 0.620) < 0.002,
    abs(reml_ex1[["upper"]] - 0.885) < 0.002
  )

  # Oracle B (independent published source) -- burch2011 sec 4 arsenic example,
  #   Table 3 (p. 1027): a=28 labs, b=4 reps. Reproduce MS from SS (the printed
  #   MSE=0.92 is rounded; 76.88/84 = 0.91524 gives the paper's theta-hat=7.57).
  #   g(kappa-hat-hat)=7.75 printed; REML rho CI (0.73, 0.95), rho-hat=0.88.
  msa_ars <- 773.33 / 27
  mse_ars <- 76.88 / 84
  theta_ars <- (msa_ars / mse_ars - 1) / 4
  stopifnot(
    abs(theta_ars - 7.57) < 0.01,
    abs(theta_ars / (1 + theta_ars) - 0.88) < 0.005
  )
  reml_ars <- burch_reml_ci_core(msa_ars, mse_ars, k = 28, n = 4, g_val = 7.75)
  cat("Arsenic      REML:", fmt(reml_ars), " oracle (0.73, 0.95)\n")
  stopifnot(
    abs(reml_ars[["lower"]] - 0.73) < 0.005,
    abs(reml_ars[["upper"]] - 0.95) < 0.005
  )

  # SEARLE cross-check on the SAME arsenic data: burch2011 eq.3 (normal-based) is
  # algebraically the SEARLE exact-F pivot, so its printed (0.81, 0.94) is a
  # second, independent published SEARLE oracle (distinct dataset + paper).
  searle_ars <- searle_f_ci(msa_ars, mse_ars, df1 = 27, df2 = 84, n0 = 4)
  cat("Arsenic    SEARLE:", fmt(searle_ars), " oracle (0.81, 0.94)\n")
  stopifnot(
    abs(searle_ars[["lower"]] - 0.81) < 0.005,
    abs(searle_ars[["upper"]] - 0.94) < 0.005
  )

  # Oracle C (self-consistency of the raw-data kurtosis pipeline the sweep uses):
  #   the printed-g oracles above bypass eq.13/eq.15, but the T4/T5 sweep computes
  #   kappa-hat from raw data. Under normality eq.13's E(kappa-hat) = eq.14 and the
  #   bias-corrected E(kappa-hat-hat) = 0 by construction -- an internal two-equation
  #   cross-check (NOT an independent CI oracle). MC over normal balanced datasets.
  set.seed(76)
  kk <- 25L
  nn <- 5L
  nrep <- 4000L
  kh <- numeric(nrep)
  kbc <- numeric(nrep)
  for (r in seq_len(nrep)) {
    a_i <- stats::rnorm(kk, 0, 1) # rho = 0.5 (sigma_a = sigma_e = 1)
    y <- rep(a_i, each = nn) + stats::rnorm(kk * nn, 0, 1)
    d <- data.frame(subject = rep(seq_len(kk), each = nn), y = y)
    grps <- split(d$y, d$subject)
    ybar_i <- vapply(grps, mean, numeric(1))
    grand <- mean(d$y)
    msa <- nn * sum((ybar_i - grand)^2) / (kk - 1)
    mse <- sum(vapply(grps, function(g) sum((g - mean(g))^2), numeric(1))) /
      (kk * (nn - 1))
    kh[r] <- burch_kappa_hat(d, msa, mse)
    kbc[r] <- burch_kappa_bc(kh[r], kk, nn)
  }
  cat(sprintf(
    "kappa self-consistency (k=%d,n=%d,nrep=%d): mean(kappa-hat)=%.4f vs eq.14 %.4f; mean(kbc)=%.4f vs 0\n",
    kk,
    nn,
    nrep,
    mean(kh),
    burch_ekappa_normal(kk, nn),
    mean(kbc)
  ))
  stopifnot(
    abs(mean(kh) - burch_ekappa_normal(kk, nn)) < 0.03,
    abs(mean(kbc)) < 0.03
  )

  cat(
    "All Burch REML oracle checks passed: 2 independent published sources",
    "(ohyama Ex.1 + burch arsenic) + eq.13/14/15 self-consistency.\n"
  )
}
