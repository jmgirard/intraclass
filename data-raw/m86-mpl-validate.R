# data-raw/m86-mpl-validate.R
#
# M86 oracle validation: reproduce xiao2013's published Tables 3/4/6/7 with the
# from-scratch naive-PL / MPL machinery in data-raw/m86-mpl-lib.R, establishing
# its correctness (PRINCIPLES.md #1, IP1). Seeded; run end-to-end with
#   Rscript data-raw/m86-mpl-validate.R
# Prints a report and writes tests/testthat/fixtures/m86-mpl-validation.rds.
#
# xiao2013 tables report coverage as CR x1000 and average interval length AL;
# validation tolerances are pre-registered here: coverage +/- 30 (x1000),
# length +/- 0.05 (matching the M62 oracle cross-check band; the published
# values use 20,000 sims, this harness uses n_rep below).

source("data-raw/m86-mpl-lib.R")

n_rep <- 2000 # coverage MC-SE ~ 0.007 at cover 0.9; interior of the +/-0.03 band
seed <- 20260723

# --- Worked-example spot check (T2): xiao2013 Example 1 (p. 2255) ----------
# The example reports only the summary estimates (rho_hat = 0.8987, delta = 1.26),
# not the raw teeth data, so the (sms, rms, ems) ratios are reconstructed as the
# ANOVA layout whose joint MLE equals that (rho_hat, delta). This pins the MLE
# POINT; the interval is then an independent deviance-root computation, so a
# matching interval tests the likelihood's shape, not the reconstruction.
invert_ms <- function(rho, delta, n_r, n_s) {
  rho_r <- delta * (1 - rho) / (1 + delta)
  grad_sq <- function(par) {
    ms <- list(
      sms = exp(par[1]),
      rms = exp(par[2]),
      ems = 1,
      n_r = n_r,
      n_s = n_s
    )
    h <- 1e-6
    g1 <- (mpl_neg2l(rho + h, rho_r, ms) - mpl_neg2l(rho - h, rho_r, ms)) /
      (2 * h)
    g2 <- (mpl_neg2l(rho, rho_r + h, ms) - mpl_neg2l(rho, rho_r - h, ms)) /
      (2 * h)
    g1^2 + g2^2
  }
  sol <- optim(
    c(log(80), log(14)),
    grad_sq,
    control = list(reltol = 1e-14, maxit = 8000)
  )
  list(
    sms = exp(sol$par[1]),
    rms = exp(sol$par[2]),
    ems = 1,
    n_r = n_r,
    n_s = n_s
  )
}

ex1_ms <- invert_ms(rho = 0.8987, delta = 1.26, n_r = 4, n_s = 10)
ex1_ci <- mpl_interval(ex1_ms, kappa = 0, alpha = 0.10, side = "two")
ex1_lower1s <- mpl_interval(ex1_ms, kappa = 0, alpha = 0.05, side = "lower")[
  "lower"
]

cat("== Worked example (xiao2013 Ex. 1, R=4, S=10) ==\n")
cat(sprintf(
  "  MLE rho_hat = %.4f (published 0.8987)\n",
  ex1_ci["rho_hat"]
))
cat(sprintf(
  "  naive-PL 90%% two-sided: (%.4f, %.4f)  [published (0.7120, 0.9598)]\n",
  ex1_ci["lower"],
  ex1_ci["upper"]
))
cat(sprintf(
  "  naive-PL 95%% one-sided lower: %.4f  [published 0.7120]\n\n",
  ex1_lower1s
))

# --- Coverage/length harness (used by the Table 4/6 reproductions) ---------
mpl_cover_cell <- function(
  rho,
  delta,
  n_r,
  n_s,
  nrep,
  kappa = 0,
  alpha = 0.10,
  side = "two"
) {
  hit <- 0L
  ok <- 0L
  lens <- numeric(0)
  for (i in seq_len(nrep)) {
    y <- mpl_simulate(rho, delta, n_r, n_s)
    ms <- mpl_anova(y)
    ci <- tryCatch(
      mpl_interval(ms, kappa = kappa, alpha = alpha, side = side),
      error = function(e) c(lower = NA, upper = NA, rho_hat = NA)
    )
    if (is.na(ci["lower"])) {
      next
    }
    ok <- ok + 1L
    if (side == "two") {
      covered <- ci["lower"] <= rho && rho <= ci["upper"]
      lens <- c(lens, ci["upper"] - ci["lower"])
    } else {
      covered <- ci["lower"] <= rho
      lens <- c(lens, 1 - ci["lower"]) # xiao2013 p.2254 one-sided "length"
    }
    if (isTRUE(covered)) hit <- hit + 1L
  }
  c(cr = round(hit / ok * 1000), al = round(mean(lens), 3), n_ok = ok)
}

# (T4/T5 append the Table 4/6/3/7 reproductions and the fixture save below.)
