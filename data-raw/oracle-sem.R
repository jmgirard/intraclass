# oracle-sem.R
# ===========================================================================
# Provenance for O-SEM: the lavaan (SEM) engine for two-way random ICCs
# (Milestone 7, ADR-014). Run to regenerate/verify the oracle values asserted
# in tests/testthat/test-icc-lavaan.R. Seeded where stochastic (PRINCIPLES.md
# #12); no fabricated values (#4).
#
# METHOD (sourced -- PRINCIPLES.md #1/#4)
# ---------------------------------------------------------------------------
#   Jorgensen, T. D. (2021). How to Estimate Absolute-Error Components in
#     Structural Equation Models of Generalizability Theory. Psych, 3(2),
#     113-133. doi:10.3390/psych3020011.  --> the SEM absolute-error method:
#     with the item intercepts effects-coded to sum to zero, the rater variance
#     component is sigma^2_r = sum_j (nu_j)^2 / (k - 1)  [Eq. 6], the RAW
#     variance of the estimated indicator intercepts (NO bias correction).
#   Lee, H., & Vispoel, W. P. (2024). A Robust Indicator Mean-Based Method ...
#     Psych, 6(1), 401-425. doi:10.3390/psych6010024.  --> confirms the same raw
#     Eq. 8/25 formula ("Robust" = an ordinal scale-coarseness correction,
#     unrelated to bias).
#   Vispoel, W. P., Hong, H., Lee, H., & Xu, G. (2022). Accuracy of Absolute
#     Error Estimates within a G-theory SEM Framework. NCME conference paper.
#     --> validation: the SEM indicator-mean method matches GENOVA / gtheory /
#     SAS / SPSS to <= .001 (G-coef) and <= .005 (D-coef) across 24 real scales.
#
# KEY POINT: SEM absolute agreement is a DIFFERENT (asymptotically equivalent)
# estimator than the mixed model. Consistency (a ratio) matches glmmTMB exactly;
# agreement differs by O(1 / n_subjects) on small designs and converges at large
# N. So the agreement oracle is the Eq. 6 formula + large-N convergence, NOT the
# published Shrout & Fleiss 0.290 / 0.620.
# ===========================================================================

library(lavaan)
library(glmmTMB)

sf_long <- data.frame(
  subject = factor(rep(1:6, 4)),
  rater = factor(rep(1:4, each = 6)),
  score = c(
    9,
    6,
    8,
    7,
    10,
    6,
    2,
    1,
    4,
    1,
    5,
    2,
    5,
    3,
    6,
    2,
    6,
    4,
    8,
    2,
    8,
    6,
    9,
    7
  )
)
k <- 4L

# --- (1) The SEM variance components on the SF data ------------------------
# Fit the one-factor GT-SEM exactly as fit_glmmtmb()'s counterpart does.
wide <- as.data.frame(tapply(
  sf_long$score,
  list(sf_long$subject, sf_long$rater),
  function(x) x[[1]]
))
names(wide) <- paste0("v", 1:k)
model <- "
  subj =~ 1*v1 + 1*v2 + 1*v3 + 1*v4
  v1 ~~ ev*v1
  v2 ~~ ev*v2
  v3 ~~ ev*v3
  v4 ~~ ev*v4
  subj ~~ sv*subj
"
fit <- lavaan(
  model,
  data = wide,
  meanstructure = TRUE,
  int.ov.free = TRUE,
  int.lv.free = FALSE,
  likelihood = "wishart",
  information = "observed"
)
co <- coef(fit)
sv <- unname(co[which(names(co) == "sv")[1]])
ev <- unname(co[which(names(co) == "ev")[1]])
nu <- unname(co[grepl("~1$", names(co))])
center <- diag(k) - matrix(1 / k, k, k)
s2_r <- as.numeric(t(nu) %*% center %*% nu) / (k - 1)

# Independent check of Eq. 6: raw variance of the observed rater means.
rmeans <- tapply(sf_long$score, sf_long$rater, mean)
s2_r_hand <- sum((rmeans - mean(rmeans))^2) / (k - 1)
stopifnot(abs(s2_r - s2_r_hand) < 1e-6) # 5.4144

icc_a1 <- sv / (sv + s2_r + ev)
icc_ak <- sv / (sv + (s2_r + ev) / k)
icc_c1 <- sv / (sv + ev)
icc_ck <- sv / (sv + ev / k)
cat(sprintf(
  "SF lavaan: A1=%.4f Ak=%.4f C1=%.4f Ck=%.4f (sigma^2_r=%.4f)\n",
  icc_a1,
  icc_ak,
  icc_c1,
  icc_ck,
  s2_r
))
# Expected: A1=0.2843 Ak=0.6137 C1=0.7148 Ck=0.9093  (sigma^2_r=5.4144)

# --- (2) Consistency matches glmmTMB REML exactly --------------------------
g <- glmmTMB(score ~ 1 + (1 | subject) + (1 | rater), sf_long, REML = TRUE)
vc <- glmmTMB::VarCorr(g)$cond
gs <- as.numeric(attr(vc$subject, "stddev"))^2
ge <- sigma(g)^2
stopifnot(abs(icc_c1 - gs / (gs + ge)) < 1e-4) # consistency: SEM == REML

# --- (3) Large-N convergence: SEM -> population, SEM ~= glmmTMB -------------
set.seed(2024)
n <- 250L
kk <- 6L
v_s <- 4
v_r <- 1
v_res <- 2
subj <- rnorm(n, 0, sqrt(v_s))
rat <- rnorm(kk, 0, sqrt(v_r))
grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(kk)))
grid$score <- 10 +
  subj[as.integer(grid$subject)] +
  rat[as.integer(grid$rater)] +
  rnorm(n * kk, 0, sqrt(v_res))
pop_a1 <- v_s / (v_s + v_r + v_res)
cat(sprintf(
  "Large-N population ICC(A,1) = %.4f (lavaan and glmmTMB both ~= this)\n",
  pop_a1
))
# See test-icc-lavaan.R for the seeded assertions (lavaan ~= glmmTMB ~= pop).
