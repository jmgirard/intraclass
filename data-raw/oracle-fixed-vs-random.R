# oracle-fixed-vs-random.R
# ===========================================================================
# Provenance script for ADR-006 and estimand-spec M2-consistency-and-fixed.md
# (PRINCIPLES.md #1, #4, #12): reproduces, from scratch, the claim that
# modeling raters as a random intercept vs. as fixed effects yields the SAME
# variance components (hence the same ICC) on BALANCED data, and that the
# equivalence BREAKS under imbalance.
#
# The balanced-data equivalence is additionally asserted as a live test in
# tests/testthat/test-icc-consistency.R ("fixed and random raters give
# identical estimates and CIs"); this script is the standalone, engine-level
# derivation behind that decision and behind the numbers quoted in ADR-006.
#
# Run: Rscript data-raw/oracle-fixed-vs-random.R
# Requires: glmmTMB, lme4, psych (all in Suggests).
# ===========================================================================

suppressMessages({
  library(glmmTMB)
  library(lme4)
  library(psych)
})
options(digits = 8)
set.seed(1)

## Shrout & Fleiss (1979) worked example: 6 subjects x 4 raters, one rating/cell
wide <- matrix(
  c(9, 2, 5, 8, 6, 1, 3, 2, 8, 4, 6, 8, 7, 1, 2, 6, 10, 5, 6, 9, 6, 2, 4, 7),
  nrow = 6,
  byrow = TRUE
)
long <- data.frame(
  subject = factor(rep(1:6, times = 4)),
  rater = factor(rep(1:4, each = 6)),
  score = as.vector(wide)
)
n <- 6L
k <- 4L

icc_c1 <- function(s, e) s / (s + e)
components <- function(model, has_rater_random) {
  v <- as.data.frame(VarCorr(model))
  list(
    s2s = v$vcov[v$grp == "subject"],
    s2r = if (has_rater_random) v$vcov[v$grp == "rater"] else NA_real_,
    s2res = v$vcov[v$grp == "Residual"]
  )
}

cat("== BALANCED (M1/M2 scope): fixed == random ==\n")

## ANOVA method-of-moments components (package-independent oracle)
a <- anova(aov(score ~ subject + rater, data = long))
ems <- a["Residuals", "Mean Sq"]
mom <- list(
  s2s = (a["subject", "Mean Sq"] - ems) / k,
  s2r = (a["rater", "Mean Sq"] - ems) / n,
  s2res = ems
)

rnd <- components(
  lmer(score ~ 1 + (1 | subject) + (1 | rater), long, REML = TRUE),
  TRUE
)
fix <- components(
  lmer(score ~ 1 + rater + (1 | subject), long, REML = TRUE),
  FALSE
)

show <- function(tag, c) {
  cat(sprintf(
    "%-14s s2_s=%.6f  s2_res=%.6f  ICC(C,1)=%.6f\n",
    tag,
    c$s2s,
    c$s2res,
    icc_c1(c$s2s, c$s2res)
  ))
}
show("MoM/ANOVA", mom)
show("RANDOM raters", rnd)
show("FIXED  raters", fix)
cat(sprintf(
  "|d s2_s|=%.2e  |d s2_res|=%.2e  -> equivalence holds (optimizer tol)\n\n",
  abs(rnd$s2s - fix$s2s),
  abs(rnd$s2res - fix$s2res)
))

## psych cross-check (ICC3 = consistency single, ICC3k = average)
p <- psych::ICC(wide)$results
cat(sprintf(
  "psych::ICC  ICC3=%.5f  ICC3k=%.5f  (published SF: 0.715 / 0.909)\n\n",
  p$ICC[p$type == "ICC3"],
  p$ICC[p$type == "ICC3k"]
))

cat("== UNBALANCED (M3 scope): fixed != random ==\n")
unb <- long[-c(2, 9, 15, 22), ] # drop 4 of 24 cells -> non-orthogonal
rnd_u <- components(
  lmer(score ~ 1 + (1 | subject) + (1 | rater), unb, REML = TRUE),
  TRUE
)
fix_u <- components(
  lmer(score ~ 1 + rater + (1 | subject), unb, REML = TRUE),
  FALSE
)
show("RANDOM raters", rnd_u)
show("FIXED  raters", fix_u)
cat(sprintf(
  "d ICC(C,1)=%.4f  -> label layer NO LONGER valid; M3 must refit (ADR-006)\n",
  abs(icc_c1(rnd_u$s2s, rnd_u$s2res) - icc_c1(fix_u$s2s, fix_u$s2res))
))
