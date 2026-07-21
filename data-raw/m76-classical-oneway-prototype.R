# M76 T1/T2 — SEARLE exact-F confidence interval for the one-way random ICC.
#
# NON-EXPORTED research prototype (data-raw/, not R/). Implements the classical
# exact-F interval so the M76 coverage harness (T4) can compare it against the
# package incumbents (MC default, parametric bootstrap) and the npbootstrap
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
}
