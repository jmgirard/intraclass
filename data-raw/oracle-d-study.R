# oracle-d-study.R
# ===========================================================================
# Provenance script for the D-study projection (ROADMAP; estimand-spec
# M4.5-d-study.md; PRINCIPLES.md #1, #4, #12). Regenerates, from scratch, the
# oracle values behind tests/testthat/test-d-study.R:
#
#   1. ANALYTIC. The projection is a change of the averaging divisor, so it has
#      two closed-form oracles independent of the estimator's own arithmetic:
#        * consistency -> Spearman-Brown:  Phi_C(m) = m*rho / (1 + (m-1)*rho)
#        * agreement   -> GT dependability: Phi_A(m) = s / (s + (r + res)/m)
#      Both reduce, at m = n_raters, to psych::ICC's average-measure ICC (a
#      third, independent implementation) on the balanced Shrout & Fleiss data.
#
#   2. SIMULATION. Draw data from known components, fit, and confirm the
#      projection recovers the population Phi(m) for an m NOT run and that the
#      Monte-Carlo interval covers it.
#
# Run: Rscript data-raw/oracle-d-study.R
# Requires: glmmTMB, psych (Suggests).
# ===========================================================================

suppressMessages({
  library(glmmTMB)
  library(psych)
})
options(digits = 8)

## --- Closed-form oracles ---------------------------------------------------
sb_project <- function(rho1, m) m * rho1 / (1 + (m - 1) * rho1)
gt_project <- function(s, r, res, m) s / (s + (r + res) / m)

## --- Shrout & Fleiss (1979): 6 subjects x 4 raters, one rating/cell --------
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

## Variance components on the estimable scale (subject, rater, residual).
components <- function(data) {
  fit <- glmmTMB(score ~ 1 + (1 | subject) + (1 | rater), data, REML = TRUE)
  vc <- VarCorr(fit)$cond
  list(
    s = as.numeric(attr(vc$subject, "stddev"))^2,
    r = as.numeric(attr(vc$rater, "stddev"))^2,
    res = sigma(fit)^2
  )
}
vc <- components(long)

## Consistency ICC(C,1) = s / (s + res); its Spearman-Brown projection.
rho_c1 <- vc$s / (vc$s + vc$res)
m_grid <- c(1, 2, 3, 4, 5, 10, 20)
cat("Consistency Phi_C(m) (Spearman-Brown):\n")
print(data.frame(m = m_grid, phi = sb_project(rho_c1, m_grid)))

## Agreement dependability Phi_A(m).
cat("\nAgreement Phi_A(m) (GT dependability):\n")
print(data.frame(m = m_grid, phi = gt_project(vc$s, vc$r, vc$res, m_grid)))

## Cross-check at m = 4 against psych::ICC average-measure (independent impl).
res <- psych::ICC(wide)$results
cat("\nCross-check at m = n_raters = 4:\n")
cat(sprintf(
  "  agreement:    Phi_A(4) = %.6f  vs psych ICC2k = %.6f\n",
  gt_project(vc$s, vc$r, vc$res, 4),
  res$ICC[res$type == "ICC2k"]
))
cat(sprintf(
  "  consistency:  Phi_C(4) = %.6f  vs psych ICC3k = %.6f\n",
  sb_project(rho_c1, 4),
  res$ICC[res$type == "ICC3k"]
))

## --- Simulation oracle -----------------------------------------------------
## Known components; project to m = 12 from k = 6 observed (a design not run).
set.seed(2025)
n <- 120L
k <- 6L
v_s <- 4
v_r <- 1
v_res <- 2
subj <- rnorm(n, 0, sqrt(v_s))
rat <- rnorm(k, 0, sqrt(v_r))
grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
grid$score <- 10 +
  subj[as.integer(grid$subject)] +
  rat[as.integer(grid$rater)] +
  rnorm(n * k, 0, sqrt(v_res))

vc_sim <- components(grid)
cat("\nSimulation: recovered vs population components:\n")
print(data.frame(
  component = c("subject", "rater", "residual"),
  recovered = c(vc_sim$s, vc_sim$r, vc_sim$res),
  population = c(v_s, v_r, v_res)
))
cat("\nSimulation Phi(m), recovered vs population:\n")
print(data.frame(
  m = c(6, 12),
  recovered = gt_project(vc_sim$s, vc_sim$r, vc_sim$res, c(6, 12)),
  population = gt_project(v_s, v_r, v_res, c(6, 12))
))
