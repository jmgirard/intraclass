# M37 Slice 1 feasibility spike (BOUNDARY PARITY): is the sigma^2_c = 0 boundary
# under-coverage an M37 defect, or inherited from the shipped M5 random cluster-level
# interval? Decisive because M37 reduces to M5 EXACTLY on balanced data (point spike:
# |d| ~ 1e-6). Runs BOTH the M5 random (fit_glmmtmb_multilevel) and the M37 fixed
# (fit_glmmtmb_multilevel_fixed) cluster-level MC intervals on the SAME sigma^2_c = 0
# data and compares boundary coverage of the truth ICC_c = 0.
#
# RESULT (240 reps): M5-RANDOM = 0.550, M37-FIXED = 0.550 -- IDENTICAL. The boundary
# under-coverage is a PRE-EXISTING cluster-signal-at-zero property shared with M5, not
# an M37 regression. At sigma^2_c = 0 the ICC = cluster/(cluster + rater + cr) is a
# ratio floored at 0 in its numerator, so a percentile lower bound sits above 0 unless
# >= 2.5% of draws floor sigma^2_c to exactly 0 -- the standard boundary-of-the-
# parameter-space coverage loss, and there is no moment correction for the SIGNAL
# variance (unlike the rater theta^2 boundary, M28). M37 ships at exact parity with M5;
# improving cluster-signal-zero boundary coverage is a cross-cutting interval matter
# (M5/M9/M37 alike) -> a candidate follow-up, OUT of M37's scope.

suppressMessages({ library(glmmTMB); devtools::load_all(".", quiet = TRUE) })

sim_df <- function(seed, Nc, ns, rho, s2c, s2s, s2cr, s2e) {
  set.seed(seed)
  k <- length(rho)
  cl <- gl(Nc, ns * k, labels = paste0("c", seq_len(Nc)))
  sub <- factor(rep(rep(seq_len(ns), each = k), times = Nc))
  rat <- factor(rep(seq_len(k), times = Nc * ns), labels = paste0("r", seq_len(k)))
  c_eff <- rnorm(Nc, 0, sqrt(s2c))[as.integer(cl)]
  s_eff <- rnorm(Nc * ns, 0, sqrt(s2s))[as.integer(interaction(cl, sub, drop = TRUE))]
  cr_eff <- rnorm(Nc * k, 0, sqrt(s2cr))[as.integer(interaction(cl, rat, drop = TRUE))]
  y <- 10 + c_eff + s_eff + rho[as.integer(rat)] + cr_eff + rnorm(Nc * ns * k, 0, sqrt(s2e))
  data.frame(subject = sub, rater = rat, cluster = cl, score = y)
}
covered <- function(v, t) {
  q <- quantile(v[is.finite(v)], c(.025, .975), names = FALSE)
  t >= q[1] && t <= q[2]
}

rho4 <- c(-0.8, -0.2, 0.3, 0.7)
hitF <- hitR <- 0L
n <- 0L
for (i in 1:240) {
  df <- sim_df(37700 + i, 80, 6, rho4, s2c = 0, s2s = 0.80, s2cr = 0.25, s2e = 1.0)
  rf <- tryCatch(fit_glmmtmb_multilevel(df), error = function(e) NULL)
  ff <- tryCatch(fit_glmmtmb_multilevel_fixed(df), error = function(e) NULL)
  if (is.null(rf) || is.null(ff)) next
  n <- n + 1L
  dr <- mc_components(rf, mc_samples = 4000L, seed = 37700 + i)
  dfx <- mc_components(ff, mc_samples = 4000L, seed = 37700 + i)
  iccR <- dr$cluster / (dr$cluster + dr$rater + dr$cluster_rater)
  iccF <- dfx$cluster / (dfx$cluster + dfx$rater + dfx$cluster_rater)
  hitR <- hitR + covered(iccR, 0)
  hitF <- hitF + covered(iccF, 0)
}
cat(sprintf(
  "boundary sigma^2_c=0 coverage (%d reps): M5-RANDOM=%.3f  M37-FIXED=%.3f\n",
  n, hitR / n, hitF / n
))
cat("=> identical -> boundary under-coverage inherited from M5, not an M37 defect.\n")
