# Classical boundary-robust one-way random-ICC confidence intervals ------------
#
# Two closed-form intervals for the balanced one-way random ICC, exported as
# `ci_method = "searle"` and `ci_method = "burch"` (M82, D-012; assessed
# GO-for-opt-in in M76). Both are DETERMINISTIC (no resampling): a finite,
# well-calibrated interval exists on every dataset, including the near-zero-ICC
# boundary where the Monte-Carlo default aborts (`intraclass_singular_fit`,
# D-006). They differ in their robustness:
#   - SEARLE exact-F (Searle 1971 eq. 4/6; mcgraw1996 Table 7): EXACT under
#     normality, best-calibrated + narrowest on ~normal data.
#   - Burch (2011) REML (eq. 6/13/15/16/17): kurtosis-adjusted `log(1+nθ̂)`
#     limits; wider but never under-covers, robust to non-normality.
#
# Both mirror the sibling `"npbootstrap"` (M75, D-010) exactly on the API
# conventions: balanced one-way only (guarded upstream in `icc()`), the reported
# POINT is the engine (glmmTMB REML) point computed upstream (never the ANOVA
# MoM ρ̂, which is interval machinery only), and the `unit = "average"` (ICC(k))
# interval is the monotone Spearman-Brown image of the ICC(1) endpoints via the
# shared `npb_sb()`. `std.error` is `NA` for both: a deterministic interval has
# no sampling distribution, so no SE is estimated (#4 -- never a fabricated one).
# Extraction (`npb_groups()`) and the SB map (`npb_sb()`) are shared with
# `ci-npbootstrap.R`; both are one-way CI reducers over the same raw data.

# One-way ANOVA decomposition on a balanced list of per-subject score vectors.
# `groups`: a list of numeric vectors (one per subject, each length n). Returns
# the between/within mean squares and their df, plus F = MSA/MSE. A degenerate
# set (MSE = 0, so F is undefined) is a caller-handled condition.
classical_oneway_ss <- function(groups) {
  k <- length(groups)
  n <- length(groups[[1]])
  ybar_i <- vapply(groups, mean, numeric(1))
  grand <- mean(unlist(groups))
  ssa <- n * sum((ybar_i - grand)^2) # between, df = k-1
  sse <- sum(vapply(groups, function(g) sum((g - mean(g))^2), numeric(1)))
  msa <- ssa / (k - 1)
  mse <- sse / (k * (n - 1))
  list(msa = msa, mse = mse, df1 = k - 1, df2 = k * (n - 1), k = k, n = n)
}

# Loud guard (#5/#8) shared by both classical reducers: the exact-F pivot and the
# Burch kurtosis standardization both divide by MSE, and F must be finite. MSE = 0
# (no within-subject variance) or a non-finite F leaves the interval ill-posed.
# This is the pathological exact-zero boundary, NOT the near-zero ICC the methods
# exist to serve (small-but-positive F passes and returns a finite interval).
classical_guard_observed <- function(ss, method, call) {
  f <- ss$msa / ss$mse
  if (ss$mse == 0 || !is.finite(f)) {
    abort_intraclass(
      c(
        "The classical one-way {method} interval is undefined for this data.",
        i = "Within-subject variance is exactly zero (MSE = {.val {ss$mse}}), so \\
             the {.field F = MSA/MSE} pivot does not exist.",
        i = "Inspect the data or use {.code ci_method = \"montecarlo\"}."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }
  f
}

# --- SEARLE exact-F ------------------------------------------------------------
# Pivot (Searle 1971): with F = MSA/MSE and n the group size,
#   F / (1 + n·λ) ~ F(df1, df2) where λ = σ²_a/σ²_e, so a 1-α interval for
#   g = (1 + n·λ) is [F/F_U, F/F_L] with F_U = qf(1-α/2), F_L = qf(α/2);
# back-transform g -> ρ via ρ(g) = (g-1)/(g+n-1) (the ICC(1) endpoint). Monotone,
# so order-preserving.

# The interval CORE, from an ANOVA summary. Returns the two ICC(1) ρ endpoints.
# Exposed so the published worked-example oracles (given as mean squares) assert
# it directly (O-Classical-OW, test-ci-classical.R); `searle_ci()` calls it.
searle_endpoints <- function(msa, mse, df1, df2, n, conf_level = 0.95) {
  f <- msa / mse
  alpha <- 1 - conf_level
  g_lo <- f / stats::qf(1 - alpha / 2, df1, df2)
  g_hi <- f / stats::qf(alpha / 2, df1, df2)
  rho_of_g <- function(g) (g - 1) / (g + n - 1)
  c(lower = rho_of_g(g_lo), upper = rho_of_g(g_hi))
}

# The `ci_method = "searle"` reducer over raw one-way data. The ICC(k) endpoint
# is npb_sb(ρ, divisor); by the monotone identity npb_sb(ρ(g), n) = 1 - 1/g
# (verified in the suite, AC4). Deterministic, so std.error is NA.
searle_ci <- function(
  df,
  estimands,
  conf_level = 0.95,
  call = rlang::caller_env()
) {
  groups <- npb_groups(df, call = call)
  ss <- classical_oneway_ss(groups)
  classical_guard_observed(ss, "SEARLE exact-F", call)
  ends <- searle_endpoints(ss$msa, ss$mse, ss$df1, ss$df2, ss$n, conf_level)

  lapply(estimands, function(est) {
    m <- est$divisor
    list(
      conf.low = npb_sb(ends[["lower"]], m),
      conf.high = npb_sb(ends[["upper"]], m),
      std.error = NA_real_
    )
  })
}

# --- Burch (2011) REML reducer ------------------------------------------------
# Primary source: burch2011.md (eq. 6/13/15/16/17). NOTATION TRAP: Burch's a =
# subjects (repo k), b = per-subject (repo n); mapped to repo (k, n) throughout.
# ρ = θ/(1+θ). Unlike SEARLE the interval WIDTH depends on the data kurtosis
# (eq. 13), which is what makes it robust under non-normality.

# eq. 16 empirical variance-inflation g(): fit by Burch (sec 3; a=10, b=5,
# ρ=.25) to correct κ̂'s over/under-estimation of kurtosis. An empirical
# calibration applied across all cells, NOT a universal identity.
burch_g <- function(kappa_bc) 2.0 * kappa_bc + 0.5 * kappa_bc^2

# eq. 14 term P(k, n): drives the bias correction (eq. 15). The (n-1) cube and
# the two remaining terms form the perfect square in the leading a² coefficient,
# so E(κ̂) -> 0 as k grows (the estimator is consistent); a missing cube breaks
# that (the transcription bug the M76 self-consistency oracle caught).
burch_p_term <- function(k, n) {
  k^3 *
    (n - 1)^3 /
    (k * (n - 1) + 2) +
    2 * k * (n - 1) * (k - 1) +
    (k - 1)^3 / (k + 1)
}

# eq. 13: kurtosis plug-in from RAW balanced data, standardized by the dataset's
# own MSE/MSA. `groups`: per-subject score vectors; msa/mse from the ANOVA.
burch_kappa_hat <- function(groups, msa, mse) {
  grand <- mean(unlist(groups))
  z <- unlist(lapply(groups, function(g) {
    (g - mean(g)) / sqrt(mse) + (mean(g) - grand) / sqrt(msa)
  }))
  mean(z^4) - 3
}

# eq. 15: bias-corrected kurtosis; E(κ̂̂) = 0 under normality by construction.
burch_kappa_bc <- function(kappa, k, n) {
  kappa + 3 * (1 - burch_p_term(k, n) / (k^2 * n^2))
}

# The interval CORE (eq. 16/17): REML CI for ρ from (MSA, MSE, k, n) and the
# eq. 16 g-value. At MSA < MSE the point θ̂ truncates to 0 (one_plus = 1), so the
# interval is well-defined at the near-zero boundary -- the boundary robustness
# (D-012). Splitting g out lets the published-example oracles feed the sources'
# PRINTED g(κ̂), isolating the CI construction from the raw-data kurtosis
# pipeline (O-Classical-OW, test-ci-classical.R); `burch_ci()` calls it.
burch_reml_endpoints <- function(msa, mse, k, n, g_val, conf_level = 0.95) {
  theta_hat <- if (msa >= mse) (msa / mse - 1) / n else 0
  one_plus <- 1 + n * theta_hat # = MSA/MSE when MSA >= MSE
  v <- 2 * (g_val / (k * n) + (k * n - 1) / (k * (n - 1) * (k - 1)))
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  theta_lo <- (one_plus * exp(-z * sqrt(v)) - 1) / n
  theta_hi <- (one_plus * exp(z * sqrt(v)) - 1) / n
  rho_of_theta <- function(th) th / (1 + th)
  c(lower = rho_of_theta(theta_lo), upper = rho_of_theta(theta_hi))
}

# The `ci_method = "burch"` reducer over raw one-way data: ANOVA -> κ̂ (eq. 13)
# -> bias-correct (eq. 15) -> g (eq. 16) -> CI core (eq. 17). The ICC(k) endpoint
# is npb_sb(ρ(θ), divisor); npb_sb(ρ(θ), n) = 1 - 1/(1+nθ) by the monotone
# identity (verified in the suite, AC4). Deterministic, so std.error is NA.
burch_ci <- function(
  df,
  estimands,
  conf_level = 0.95,
  call = rlang::caller_env()
) {
  groups <- npb_groups(df, call = call)
  ss <- classical_oneway_ss(groups)
  classical_guard_observed(ss, "Burch REML", call)

  kappa_bc <- burch_kappa_bc(
    burch_kappa_hat(groups, ss$msa, ss$mse),
    ss$k,
    ss$n
  )
  ends <- burch_reml_endpoints(
    ss$msa,
    ss$mse,
    ss$k,
    ss$n,
    burch_g(kappa_bc),
    conf_level
  )

  lapply(estimands, function(est) {
    m <- est$divisor
    list(
      conf.low = npb_sb(ends[["lower"]], m),
      conf.high = npb_sb(ends[["upper"]], m),
      std.error = NA_real_
    )
  })
}
