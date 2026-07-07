# oracle-fixed-incomplete.R
# ===========================================================================
# Provenance script for oracle O6 and estimand-spec M3-incomplete-designs.md §6
# (PRINCIPLES.md #1, #4, #12): establishes the REAL fixed-effect fit path for
# raters = "fixed" (two-way mixed, McGraw & Wong Case 3 / 3A), which resolves the
# ADR-006 debt on incomplete data.
#
#   Oracle 1 (balanced reduction) -- on the complete Shrout & Fleiss data the
#     fixed fit reproduces the published ICC(A,1)=0.290, ICC(A,k)=0.620,
#     ICC(C,1)=0.715, ICC(C,k)=0.909, and the bias-corrected theta^2_r equals the
#     random-fit sigma^2_r (5.2444). This is why fixed == random on balanced data
#     (extends O4 from a shared fit to an INDEPENDENT fixed-effect fit).
#   Oracle 2 (lme4 cross-engine) -- lme4 fits the SAME fixed-effect model on an
#     incomplete design and reproduces sigma^2_s, sigma^2_res, and (via the same
#     theta^2_r formula) the fixed ICCs, pinning the extraction on ragged data.
#   Oracle 3 (coverage simulation) -- with KNOWN fixed rater effects (hence a
#     known true theta^2_r and true ICCs), the point estimate is ~unbiased and the
#     boundary-aware Monte-Carlo interval attains nominal 95% coverage on
#     incomplete data. This is the gate for the Case 3A theta^2_r CI, which the
#     estimand spec deferred to oracle verification rather than the formula alone.
#
# Fast assertions (balanced reduction, lme4 cross-check, single-seed recovery)
# are live in tests/testthat/test-icc-fixed-fit.R; the 300-rep coverage run below
# is the expensive validation kept here (and in the scheduled reference-values
# job), not in the unit suite.
#
# Run: Rscript data-raw/oracle-fixed-incomplete.R
# Requires: glmmTMB, lme4 (Suggests).
# ===========================================================================

suppressMessages(devtools::load_all(quiet = TRUE))
suppressMessages(library(lme4))
options(digits = 8)

## ---------------------------------------------------------------------------
## Oracle 1: balanced reduction on the Shrout & Fleiss data.
## ---------------------------------------------------------------------------
wide <- matrix(
  c(9, 2, 5, 8, 6, 1, 3, 2, 8, 4, 6, 8, 7, 1, 2, 6, 10, 5, 6, 9, 6, 2, 4, 7),
  nrow = 6,
  byrow = TRUE
)
long <- data.frame(
  subject = factor(rep(paste0("S", 1:6), times = 4)),
  rater = factor(rep(paste0("J", 1:4), each = 6)),
  score = as.vector(wide)
)
fa <- suppressWarnings(icc(
  long,
  score,
  subject,
  rater,
  raters = "fixed",
  type = "agreement",
  unit = c("single", "average")
))
fc <- suppressWarnings(icc(
  long,
  score,
  subject,
  rater,
  raters = "fixed",
  type = "consistency",
  unit = c("single", "average")
))
cat("Oracle 1 -- balanced reduction (fixed fit on complete SF)\n")
cat(sprintf(
  "  ICC(A,1)=%.4f ICC(A,k)=%.4f ICC(C,1)=%.4f ICC(C,k)=%.4f\n",
  fa$estimates$estimate[1],
  fa$estimates$estimate[2],
  fc$estimates$estimate[1],
  fc$estimates$estimate[2]
))
cat(sprintf(
  "  theta^2_r=%.4f (random-fit sigma^2_r=5.2444)\n",
  fa$components$rater
))
stopifnot(
  round(fa$estimates$estimate[1], 3) == 0.290,
  round(fa$estimates$estimate[2], 3) == 0.620,
  round(fc$estimates$estimate[1], 3) == 0.715,
  round(fc$estimates$estimate[2], 3) == 0.909,
  abs(fa$components$rater - 5.24444) < 1e-2
)
cat("  PASS\n\n")

## ---------------------------------------------------------------------------
## Oracle 2: lme4 cross-engine fixed fit on an incomplete SF subset.
## ---------------------------------------------------------------------------
inc <- long[
  !(long$subject == "S1" & long$rater == "J1") &
    !(long$subject == "S2" & long$rater == "J2"),
]
inc$subject <- droplevels(inc$subject)
inc$rater <- droplevels(inc$rater)
k <- nlevels(inc$rater)

m <- lmer(score ~ 1 + rater + (1 | subject), data = inc, REML = TRUE)
vc <- as.data.frame(VarCorr(m))
s <- vc$vcov[vc$grp == "subject"][1]
e <- vc$vcov[vc$grp == "Residual"][1]
# theta^2_r from lme4's fixed effects via the same bias-corrected formula.
contrast <- rater_mean_contrast(k)
center <- diag(k) - matrix(1 / k, k, k)
beta <- lme4::fixef(m)
vbeta <- as.matrix(stats::vcov(m))
v_means <- contrast %*% vbeta %*% t(contrast)
mu <- as.numeric(contrast %*% beta)
theta2 <- max(
  0,
  (as.numeric(t(mu) %*% center %*% mu) - sum(diag(center %*% v_means))) /
    (k - 1)
)
oracle_c1 <- s / (s + e)
oracle_a1 <- s / (s + e + theta2)
gc1 <- icc_estimate(
  suppressWarnings(icc(
    inc,
    score,
    subject,
    rater,
    raters = "fixed",
    type = "consistency"
  )),
  "ICC(C,1)"
)
ga1 <- icc_estimate(
  suppressWarnings(icc(
    inc,
    score,
    subject,
    rater,
    raters = "fixed",
    type = "agreement"
  )),
  "ICC(A,1)"
)
cat("Oracle 2 -- lme4 cross-engine fixed fit on incomplete SF subset\n")
cat(sprintf("  ICC(C,1): ours %.6f  lme4 %.6f\n", gc1, oracle_c1))
cat(sprintf("  ICC(A,1): ours %.6f  lme4 %.6f\n", ga1, oracle_a1))
stopifnot(abs(gc1 - oracle_c1) < 1e-4, abs(ga1 - oracle_a1) < 1e-4)
cat("  PASS\n\n")

## ---------------------------------------------------------------------------
## Oracle 3: coverage simulation, known FIXED rater effects, MCAR-incomplete.
## ---------------------------------------------------------------------------
set.seed(999)
ns <- 50L
k <- 8L
s2s <- 4
s2res <- 2
alpha <- seq(-3, 3, length.out = k) # FIXED rater effects (known)
theta2_true <- sum((alpha - mean(alpha))^2) / (k - 1)
pop_a1 <- s2s / (s2s + s2res + theta2_true)
pop_c1 <- s2s / (s2s + s2res)
grid <- expand.grid(subject = factor(seq_len(ns)), rater = factor(seq_len(k)))
reps <- 300L
cover_a <- cover_c <- est_a <- numeric(reps)
for (i in seq_len(reps)) {
  subj <- rnorm(ns, 0, sqrt(s2s))
  y <- 10 +
    subj[as.integer(grid$subject)] +
    alpha[as.integer(grid$rater)] +
    rnorm(nrow(grid), 0, sqrt(s2res))
  dat <- grid
  dat$score <- y
  dat <- dat[runif(nrow(dat)) > 0.20, ]
  dat$subject <- droplevels(dat$subject)
  dat$rater <- droplevels(dat$rater)
  ta <- generics::tidy(suppressWarnings(icc(
    dat,
    score,
    subject,
    rater,
    type = "agreement",
    raters = "fixed",
    unit = "single",
    mc_samples = 2000L,
    seed = i
  )))
  tc <- generics::tidy(suppressWarnings(icc(
    dat,
    score,
    subject,
    rater,
    type = "consistency",
    raters = "fixed",
    unit = "single",
    mc_samples = 2000L,
    seed = i
  )))
  est_a[i] <- ta$estimate
  cover_a[i] <- pop_a1 >= ta$conf.low && pop_a1 <= ta$conf.high
  cover_c[i] <- pop_c1 >= tc$conf.low && pop_c1 <= tc$conf.high
}
cat("Oracle 3 -- coverage simulation (known fixed effects, MCAR-incomplete)\n")
cat(sprintf(
  "  true theta^2_r=%.4f  pop ICC(A,1)=%.4f  mean est=%.4f (bias %.4f)\n",
  theta2_true,
  pop_a1,
  mean(est_a),
  mean(est_a) - pop_a1
))
cat(sprintf(
  "  coverage ICC(A,1)=%.3f  ICC(C,1)=%.3f  (nominal 0.95)\n",
  mean(cover_a),
  mean(cover_c)
))
stopifnot(
  abs(mean(est_a) - pop_a1) < 0.02,
  mean(cover_a) > 0.90,
  mean(cover_a) < 0.99,
  mean(cover_c) > 0.90
)
cat("  PASS\n")
