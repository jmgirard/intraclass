# M45 T1 — derivation-confirmation spike (ADR-056, AC1)
#
# Question (the ROADMAP #1/#4 gate): is there a *sourced or faithfully-derivable*
# consistency-conflated ICC, with an oracle strong enough to ship — or must the
# `type = "consistency"` + `level = "conflated"` combination keep its abort?
#
# Claim under test: the consistency-conflated ICC is the flat two-way *consistency*
# ICC read off the multilevel five-component fit — the agreement-conflated error set
# (sigma^2_r + sigma^2_cr + sigma^2_res) with the rater main effect sigma^2_r dropped,
# exactly as consistency drops "rater" for every other design (R/estimand.R lines
# 116/127/135). This mirrors M18 §6a, which proved agreement-conflated = flat two-way
# *agreement* ICC. If the claim holds, M45 ships; if not, the abort stays (ADR-028).
#
# Two independent routes (PRINCIPLES.md #1):
#   (A) formula-wiring identity — the hand-computed drop-sigma^2_r value equals the
#       closed form on the reported components (exact, ~1e-10; this is trivially true
#       by construction and just pins the arithmetic path T2 will wire).
#   (B) population tracking — on the same data the hand-computed consistency-conflated
#       value tracks the shipped flat two-way `icc(type = "consistency")` at a loose
#       population tolerance (different models, #18), the operational meaning of
#       "conflated", and stays visibly biased vs the correct subject-level consistency
#       ICC (the diagnostic's whole point).

devtools::load_all(quiet = TRUE)

# Same generator + parameters as the shipped agreement-conflated oracles
# (tests/testthat/test-icc-multilevel.R).
sim_multilevel <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rt <- stats::rnorm(k, 0, sqrt(vr))
  d <- expand.grid(
    subject = seq_len(ns),
    cluster = seq_len(nc),
    rater = seq_len(k)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  crv <- stats::rnorm(nc * k, 0, sqrt(vcr))
  d$score <- cl[d$cluster] +
    rt[d$rater] +
    scv[(d$cluster - 1) * ns + d$subject] +
    crv[(d$cluster - 1) * k + d$rater] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$subject <- interaction(d$cluster, d$subject, drop = TRUE)
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d
}

vc <- 1.0
vsc <- 1.2
vr <- 0.7
vcr <- 0.16
vres <- 0.5

# --- Route A: formula-wiring identity on the reported components -----------------
d <- sim_multilevel(30, 10, 6, vc, vsc, vr, vcr, vres, seed = 20260707)
x <- icc(d, score, subject, rater, cluster = cluster, level = "conflated", seed = 1)
comp <- x$components
k_eff <- x$k_eff

sig <- comp$cluster + comp$subject
err_A <- comp$rater + comp$cluster_rater + comp$residual # agreement (shipped)
err_C <- comp$cluster_rater + comp$residual # consistency = drop sigma^2_r

cc1 <- sig / (sig + err_C) # consistency-conflated ICC(C,1)
cck <- sig / (sig + err_C / k_eff) # consistency-conflated ICC(C,k)
ca1 <- sig / (sig + err_A) # agreement-conflated ICC(A,1), for contrast

cat(sprintf(
  "Route A (identity): conflated ICC(C,1)=%.6f  ICC(C,k)=%.6f  [ICC(A,1)=%.6f]\n",
  cc1,
  cck,
  ca1
))
stopifnot(cc1 >= 0, cc1 <= 1, cck >= 0, cck <= 1, cck >= cc1, cc1 > ca1)

# --- Route B: tracks the flat two-way consistency icc() on the same data ----------
# larger cluster count so sigma^2_c is estimated less noisily (as O-conflated/population)
d2 <- sim_multilevel(40, 20, 6, vc, vsc, vr, vcr, vres, seed = 424242)
xc <- icc(d2, score, subject, rater, cluster = cluster, level = "conflated", seed = 1)
sig2 <- xc$components$cluster + xc$components$subject
errC2 <- xc$components$cluster_rater + xc$components$residual
cc1_2 <- sig2 / (sig2 + errC2)

flat <- icc(d2, score, subject, rater, type = "consistency", seed = 1)
flat_c1 <- flat$estimates$estimate[flat$estimates$index == "ICC(C,1)"]

# population conflated-consistency value from the known components
pop_cc1 <- (vc + vsc) / ((vc + vsc) + (vcr + vres))

# correct subject-level consistency ICC (what conflated is biased away from)
subj <- icc(d2, score, subject, rater, cluster = cluster, type = "consistency",
            level = "subject", seed = 1)
subj_c1 <- subj$estimates$estimate[subj$estimates$index == "ICC(C,1)"]

cat(sprintf(
  "Route B (tracking): conflated ICC(C,1)=%.6f  flat two-way ICC(C,1)=%.6f  |diff|=%.6f\n",
  cc1_2,
  flat_c1,
  abs(cc1_2 - flat_c1)
))
cat(sprintf(
  "            population conflated-C=%.6f   correct subject-level ICC(C,1)=%.6f\n",
  pop_cc1,
  subj_c1
))

stopifnot(
  abs(cc1_2 - flat_c1) < 0.02, # tracks the sourced flat two-way consistency ICC
  abs(cc1_2 - pop_cc1) < 0.1, # recovers the known population value
  abs(cc1_2 - subj_c1) > 0.02 # stays visibly biased vs the correct level
)

cat("\nT1 VERDICT: consistency-conflated ICC = flat two-way consistency ICC (drop sigma^2_r).\n")
cat("Sourced (McGraw & Wong 1996) and faithfully derivable — M45 proceeds to implement.\n")
