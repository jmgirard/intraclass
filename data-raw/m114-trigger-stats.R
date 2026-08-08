# M114 shared helper — the two frozen candidate statistics per dataset.
# Sourced by data-raw/m114-warn-trigger-derivation.R and
# data-raw/m114-heldout-sweep.R so both halves of the derived table compute
# the IDENTICAL statistic (one definition, no copy drift). Frozen family:
# cairn/references/mc-skew-warn-trigger.md § Candidate statistic family.
#
# One-way balanced mean squares + kappa_bc / gamma on the Burch
# z-decomposition, computed from the SHIPPED implementations
# (intraclass:::burch_kappa_hat / :::burch_kappa_bc) so the assessed
# statistic is the one a runtime trigger would actually compute. Undefined at
# MSA = 0 or MSE = 0: stat_defined = FALSE, statistics NA (counts as NOT
# fired downstream — frozen page rule). The z recomputation exists only to
# derive gamma and is pinned per call to the shipped decomposition (the
# recomputed kurtosis must reproduce burch_kappa_hat()).
trigger_stats <- function(d, k, n) {
  groups <- split(d$score, d$subject)
  m_i <- vapply(groups, mean, numeric(1))
  grand <- mean(d$score)
  msa <- n * sum((m_i - grand)^2) / (k - 1)
  mse <- sum((d$score - rep(m_i, each = n))^2) / (k * (n - 1))
  if (msa <= 0 || mse <= 0) {
    return(list(defined = FALSE, kappa_bc = NA_real_, gamma = NA_real_))
  }
  kap <- intraclass:::burch_kappa_hat(groups, msa, mse)
  kap_bc <- intraclass:::burch_kappa_bc(kap, k, n)
  z <- unlist(lapply(groups, function(g) {
    (g - mean(g)) / sqrt(mse) + (mean(g) - grand) / sqrt(msa)
  }))
  if (abs((mean(z^4) - 3) - kap) > 1e-8) {
    stop("z-decomposition diverged from the shipped burch_kappa_hat()")
  }
  list(defined = TRUE, kappa_bc = kap_bc, gamma = mean(z^3))
}

# Fixed-format numerics so the derived table is byte-stable on re-run
# (committed seeds; identical formatting => identical bytes).
stats_fmt <- function(x) ifelse(is.na(x), "NA", sprintf("%.17g", x))
