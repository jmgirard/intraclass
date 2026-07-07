# oracle-incomplete.R
# ===========================================================================
# Provenance script for oracle O5 and estimand-spec M3-incomplete-designs.md
# (PRINCIPLES.md #1, #4, #12): establishes the incomplete/imbalanced two-way
# random-rater ICCs by numerical agreement with two independent oracles, since
# no textbook worked example exists for arbitrary unbalanced data.
#
#   Oracle 1 (cross-engine) -- lme4 fits the SAME ragged mixed model as the
#     glmmTMB engine and must return the same variance components / ICCs on
#     INCOMPLETE data (extends the balanced-only lme4 cross-check to M3). This
#     pins the extraction and the k_eff divisor plumbing (ADR-008).
#   Oracle 2 (simulation) -- a seeded, MCAR-incomplete design with KNOWN
#     population components sigma^2_s=4, sigma^2_r=1, sigma^2_res=2. The engine
#     recovers them and the Monte-Carlo interval covers the population ICC.
#     Enough raters (k=30) so sigma^2_r is well-identified in a single draw;
#     with few raters sigma^2_r is inherently noisy (the honest wide-CI case).
#
# Both are additionally asserted as live tests in
# tests/testthat/test-icc-incomplete.R. This script is the standalone,
# engine-level derivation and the source of the O5 registry row.
#
# Run: Rscript data-raw/oracle-incomplete.R
# Requires: glmmTMB, lme4 (Suggests).
# ===========================================================================

suppressMessages(devtools::load_all(quiet = TRUE))
suppressMessages(library(lme4))
options(digits = 8)

icc_all <- function(s, r, e, k) {
  c(
    "ICC(A,1)" = s / (s + r + e),
    "ICC(A,k)" = s / (s + (r + e) / k),
    "ICC(C,1)" = s / (s + e),
    "ICC(C,k)" = s / (s + e / k)
  )
}

## ---------------------------------------------------------------------------
## Oracle 1: lme4 cross-engine on an INCOMPLETE, connected design.
## Shrout & Fleiss data with cells (S1,J1) and (S2,J2) removed -> n_i = 3,3,4,4,4,4
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
inc <- long[
  !(long$subject == "S1" & long$rater == "J1") &
    !(long$subject == "S2" & long$rater == "J2"),
]
inc$subject <- droplevels(inc$subject)
inc$rater <- droplevels(inc$rater)
k_eff <- 1 / mean(1 / c(3, 3, 4, 4, 4, 4))

fit <- icc(inc, score, subject, rater, unit = c("single", "average"), seed = 1)
m <- lmer(score ~ 1 + (1 | subject) + (1 | rater), data = inc, REML = TRUE)
vc <- as.data.frame(VarCorr(m))
lme4_v <- function(g) vc$vcov[vc$grp == g][1]
oracle_icc <- icc_all(
  lme4_v("subject"),
  lme4_v("rater"),
  lme4_v("Residual"),
  k_eff
)

ours <- c(
  generics::tidy(icc(
    inc,
    score,
    subject,
    rater,
    unit = c("single", "average")
  ))$estimate,
  generics::tidy(icc(
    inc,
    score,
    subject,
    rater,
    type = "consistency",
    unit = c("single", "average")
  ))$estimate
)
names(ours) <- c("ICC(A,1)", "ICC(A,k)", "ICC(C,1)", "ICC(C,k)")

cat(
  "Oracle 1 -- lme4 cross-engine on incomplete SF subset (k_eff = ",
  round(k_eff, 4),
  ")\n",
  sep = ""
)
print(round(rbind(intraclass = ours[names(oracle_icc)], lme4 = oracle_icc), 6))
stopifnot(max(abs(ours[names(oracle_icc)] - oracle_icc)) < 1e-4)
cat("  max |diff| < 1e-4: PASS\n\n")

## ---------------------------------------------------------------------------
## Oracle 2: seeded simulation, known components, MCAR-incomplete design.
## ---------------------------------------------------------------------------
set.seed(20260706)
ns <- 120L
k <- 30L
s2s <- 4
s2r <- 1
s2res <- 2
subj <- rnorm(ns, 0, sqrt(s2s))
rat <- rnorm(k, 0, sqrt(s2r))
full <- expand.grid(subject = factor(seq_len(ns)), rater = factor(seq_len(k)))
full$score <- 10 +
  subj[as.integer(full$subject)] +
  rat[as.integer(full$rater)] +
  rnorm(nrow(full), 0, sqrt(s2res))
sim <- full[runif(nrow(full)) > 0.25, ] # ~25% MCAR deletion
sim$subject <- droplevels(sim$subject)
sim$rater <- droplevels(sim$rater)

sfit <- icc(sim, score, subject, rater, type = "agreement", seed = 7)
scon <- icc(sim, score, subject, rater, type = "consistency", seed = 7)
cs <- sfit$components
pop_a1 <- s2s / (s2s + s2r + s2res)
pop_c1 <- s2s / (s2s + s2res)
tidy_a <- generics::tidy(sfit)
tidy_c <- generics::tidy(scon)

cat("Oracle 2 -- seeded MCAR-incomplete simulation (n =", nrow(sim), ")\n")
cat(sprintf(
  "  components: subject %.3f (4), rater %.3f (1), residual %.3f (2)\n",
  cs$subject,
  cs$rater,
  cs$residual
))
cat(sprintf(
  "  ICC(A,1): pop %.4f est %.4f  CI[%.3f, %.3f]\n",
  pop_a1,
  tidy_a$estimate,
  tidy_a$conf.low,
  tidy_a$conf.high
))
cat(sprintf(
  "  ICC(C,1): pop %.4f est %.4f  CI[%.3f, %.3f]\n",
  pop_c1,
  tidy_c$estimate,
  tidy_c$conf.low,
  tidy_c$conf.high
))
stopifnot(
  abs(tidy_a$estimate - pop_a1) < 0.05,
  abs(tidy_c$estimate - pop_c1) < 0.05,
  pop_a1 >= tidy_a$conf.low && pop_a1 <= tidy_a$conf.high,
  pop_c1 >= tidy_c$conf.low && pop_c1 <= tidy_c$conf.high
)
cat("  point ICCs within 0.05 of population; CIs cover: PASS\n")
