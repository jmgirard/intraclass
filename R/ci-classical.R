# Classical boundary-robust one-way random-ICC confidence intervals ------------
#
# Two closed-form intervals for the balanced one-way random ICC, exported as
# `ci_method = "searle"` and `ci_method = "burch"` (M82, D-012; assessed
# GO-for-opt-in in M76). Both are DETERMINISTIC (no resampling): a finite,
# well-calibrated interval exists at the near-zero-ICC boundary where the
# Monte-Carlo default aborts (`intraclass_singular_fit`, D-006) -- except that
# `burch` at MSA exactly 0 aborts classed rather than standardize by
# `sqrt(MSA) = 0` (D-022). They differ in their robustness:
#   - SEARLE exact-F (Searle 1971 Ch. 9 Table 9.14; mcgraw1996 Table 7): EXACT under
#     normality, best-calibrated on ~normal data.
#   - Burch (2011) REML (eq. 6/13/15/16/17): kurtosis-adjusted `log(1+nθ̂)`
#     limits; designed for robustness to non-normality -- but measured (M113) to
#     under-cover on strongly skewed subject effects, worst 0.6655, so it is not
#     a remedy for heavy tails.
# NOT "burch is wider than searle" -- that shipped for three milestones and is
# false on both committed grids (M116: burch narrower in 16 of 16 cells of the
# M76 grid and 59 of 64 cells of the M113 one, no family reversing on its
# median; see data-raw/m116-classical-width-comparison.tsv). Nor is it a flat
# margin, which the pooled figure that replaced it implied (M117): burch's width
# margin holds much the same up to a true ICC of 0.3 rather than shrinking as
# the true ICC rises, then collapses to near parity at 0.6, where every cell
# searle won sits; and it shrinks steadily as the subject count grows, measured
# at 5 raters. That is the only rater count present at every subject count, so
# the unstratified subject-count cut would be confounded.
# The per-level figures live in the interval-methods article, tabulated and
# pinned by tests/testthat/test-doc-skew-caveat.R against the committed
# fixture. They are deliberately not restated here: a figure in a source
# comment is not in the built package, so no pin that runs under `R CMD check`
# can reach it. Burch's own eq. 18 comparison
# is against this very exact-F interval and is kurtosis-CONDITIONAL, with his
# reversal measured on data where the errors are non-normal too -- which neither
# grid varies. Neither method is reliably the tighter one.
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
classical_guard_observed <- function(ss, method, call, hint = character(0)) {
  f <- ss$msa / ss$mse
  # This guard REPORTS the quantities that failed and diagnoses nothing. Its
  # condition has two disjuncts but its message described only the first, and it
  # named `ci_method = "montecarlo"` until a seeded sweep of its trigger class
  # measured montecarlo usable on 0 of 3 datasets that reach it. A STATIC name
  # would still need sweep evidence covering every dataset that reaches here.
  # `hint` is not static (M103): it names a method only after running it on THIS
  # caller's data, so on the sweep's own three datasets it stays empty and this
  # message is byte-identical to the one that shipped without it.
  #
  # `searle_ci()` and `burch_ci()` SHARE this guard, so verifying `burch` from a
  # `searle` abort re-enters it. That terminates rather than recursing: the
  # verification run passes no hint of its own, so the re-entered guard aborts
  # with the message alone and `boundary_method_usable()` catches it (M103 AC4).
  if (ss$mse == 0 || !is.finite(f)) {
    abort_intraclass(
      c(
        "The classical one-way {method} interval is undefined for this data.",
        i = "The {.field F = MSA/MSE} pivot is not usable here: \\
             MSA = {.val {signif(ss$msa, 6)}}, MSE = {.val {signif(ss$mse, 6)}}.",
        i = "Inspect the data before retrying.",
        hint
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }
  f
}

# --- SEARLE exact-F ------------------------------------------------------------
# Pivot (Searle 1971, Ch. 9 §9d Table 9.14 row 3 + eq. 60): with F = MSA/MSE and
# n the group size,
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
  call = rlang::caller_env(),
  hint = character(0)
) {
  groups <- npb_groups(df, call = call)
  ss <- classical_oneway_ss(groups)
  classical_guard_observed(ss, "SEARLE exact-F", call, hint)
  ends <- searle_endpoints(ss$msa, ss$mse, ss$df1, ss$df2, ss$n, conf_level)

  lapply(estimands, function(est) {
    m <- est$divisor
    npb_guard_sb_pole(ends, m, "SEARLE exact-F", call)
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
  call = rlang::caller_env(),
  hint = character(0)
) {
  groups <- npb_groups(df, call = call)
  ss <- classical_oneway_ss(groups)
  classical_guard_observed(ss, "Burch REML", call, hint)

  # BURCH-ONLY, and it must not move into the shared guard above (M105, D-022).
  # `burch_kappa_hat()` standardizes the eq. 13 kurtosis plug-in by `sqrt(MSA)`,
  # so at MSA = 0 kappa-hat is NaN and both endpoints follow it -- while SEARLE,
  # which reads MSA only through F = MSA/MSE, returns its ordinary attained
  # minimum on the same data. Folding this into the shared guard would abort a
  # sibling that has a correct answer.
  #
  # The test is `identical(., 0)` and NOT a near-zero tolerance: MSA = 0 exactly
  # is the whole failure, and just above it the construction is defined and its
  # interval ordinary. Measured on the committed fixture, three cells reach
  # exactly 0 while a fourth lands at 3.5e-33 and returns [-1.693, 0.629] --
  # a tolerance wide enough to catch that cell would abort a case Burch answers
  # (`tests/testthat/fixtures/degenerate-classical-cells.tsv`).
  #
  # Before M105 this returned NaN endpoints: a bare `simpleError` out of
  # `npb_guard_sb_pole()`'s non-NaN-safe `!any(denom < 0)` at `unit = "average"`,
  # and a SILENTLY reported NaN interval at `unit = "single"`. #3 and #5 refuse a
  # reported non-interval, and #4 refuses substituting a number this estimator
  # did not produce, so the answer is a classed abort. `hint` carries M103's
  # runtime verification -- it names a method only after running it on THIS
  # caller's data -- so nothing here asserts an alternative works (D-018).
  if (identical(ss$msa, 0)) {
    abort_intraclass(
      c(
        "The Burch REML interval is undefined for this data.",
        i = "There is no between-subject variance at all \\
             ({.field MSA = 0}), and the kurtosis term the Burch width \\
             depends on divides by {.field sqrt(MSA)}.",
        i = "Inspect the data before retrying.",
        hint
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

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
    npb_guard_sb_pole(ends, m, "Burch REML", call)
    list(
      conf.low = npb_sb(ends[["lower"]], m),
      conf.high = npb_sb(ends[["upper"]], m),
      std.error = NA_real_
    )
  })
}
