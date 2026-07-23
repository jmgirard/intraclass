# Unbalanced one-way transformed bootstrap-t -- ICC(k) (M85, MD-1) -------------
#
# Extends `ci_method = "npbootstrap"` to the UNBALANCED one-way ICC(k)
# (`unit = "average"`) as the monotone Spearman-Brown image of the ICC(1)
# endpoints, g(rho) = k_eff*rho/(1 + (k_eff - 1)rho), with the package's
# harmonic-mean k_eff divisor. The load-bearing GO verdict (MD-1):
#   AC1  pole/support alignment -- k_eff <= n0 (ohyama eq. 3) for EVERY one-way
#        design, so the SB pole -1/(k_eff - 1) sits at or below the support
#        boundary -1/(n0 - 1) and never intrudes; g is finite + strictly monotone
#        on the attainable rho range. Verified numerically here on random +
#        adversarial worst-case designs (GP7).
#   AC4  re-derived identity cross-check -- the shipped SB route equals the direct
#        construction g(rho) = k_eff(F - 1)/(k_eff(F - 1) + n0), F = exp(logf),
#        which (unlike balanced) is NOT 1 - 1/F when k_eff != n0. Machine precision.

# k_eff (harmonic mean of ratings/subject, R/design.R:36) and n0 (ohyama eq. 3,
# R/ci-npbootstrap.R). The GO derivation: pole intrudes iff k_eff > n0.
keff_hm <- function(n_i) 1 / mean(1 / n_i)
n0_eq3 <- function(n_i) {
  n_tot <- sum(n_i)
  k <- length(n_i)
  (n_tot - sum(n_i^2) / n_tot) / (k - 1)
}

test_that("the SB pole never intrudes: k_eff <= n0 for every one-way design (AC1 GO)", {
  # Balanced: equality (pole exactly on the support boundary, the M84/RR02 case).
  for (n_i in list(rep(3L, 5L), rep(7L, 10L), rep(2L, 4L))) {
    expect_equal(keff_hm(n_i), n0_eq3(n_i))
  }
  # k = 2 is always the equality case (n0 == harmonic mean of two values).
  for (n_i in list(c(2L, 10L), c(1L, 60L), c(3L, 3L))) {
    expect_equal(keff_hm(n_i), n0_eq3(n_i))
  }
  # Adversarial worst cases (many singletons + one huge group; extreme spread):
  # the pole must stay at or below the boundary, i.e. n0 - k_eff >= 0.
  adversarial <- list(
    c(1L, 1L, 2L),
    c(1L, rep(1L, 9L), 100L),
    c(2L, rep(2L, 20L), 1L),
    c(1L, 1L, 1L, 1L, 50L),
    c(1L, 2L, 3L, 4L, 5L, 60L)
  )
  for (n_i in adversarial) {
    expect_gte(n0_eq3(n_i) - keff_hm(n_i), 0)
  }
  # Randomized sweep: min(n0 - k_eff) >= 0 (>= -1e-12 for float noise) over many
  # random unbalanced designs. A NO-GO (pole intrusion) would surface here.
  set.seed(85L)
  worst <- Inf
  for (trial in seq_len(20000L)) {
    k <- sample(2:40, 1L)
    n_i <- sample(1:60, k, replace = TRUE)
    worst <- min(worst, n0_eq3(n_i) - keff_hm(n_i))
  }
  expect_gte(worst, -1e-12)
})

test_that("the re-derived unbalanced ICC(k) identity matches the shipped SB route (AC4)", {
  # Direct construction (MD-1): g(rho) = k_eff(F - 1)/(k_eff(F - 1) + n0), which the
  # shipped npb_sb(npb_logf_to_rho(logf, n0), k_eff) route must reproduce to <= 1e-10.
  # This is a SECOND, algebraically independent path: it uses k_eff and n0 separately,
  # so a divisor bug (wiring k_eff = n0 or vice versa) breaks it. UNLIKE balanced, the
  # identity is NOT 1 - 1/F because k_eff != n0.
  set.seed(7L)
  for (t in seq_len(2000L)) {
    k_eff <- stats::runif(1, 1.2, 40)
    n0 <- k_eff + stats::runif(1, 0.5, 30) # strictly unbalanced: k_eff < n0
    logf <- stats::runif(1, -3, 6)
    rho <- npb_logf_to_rho(logf, n0)
    shipped <- npb_sb(rho, k_eff)
    ff <- exp(logf)
    direct <- k_eff * (ff - 1) / (k_eff * (ff - 1) + n0)
    expect_equal(shipped, direct, tolerance = 1e-10)
  }
  # Balanced special case: the re-derived identity collapses to 1 - 1/F (RR02 BC2).
  logf <- 1.3
  ff <- exp(logf)
  expect_equal(
    npb_sb(npb_logf_to_rho(logf, 4), 4),
    1 - 1 / ff,
    tolerance = 1e-12
  )
})

# A reproducible unbalanced one-way dataset with a known population ICC(1) = rho.
unbalanced_icck_set <- function(seed, rho = 0.5, k = 12L, sizes = 2:5) {
  set.seed(seed)
  n_i <- sample(sizes, k, replace = TRUE)
  a <- stats::rnorm(k, 0, sqrt(rho))
  rows <- lapply(seq_len(k), function(i) {
    data.frame(
      subject = factor(i, levels = seq_len(k)),
      rater = factor(seq_len(n_i[i])),
      score = a[i] + stats::rnorm(n_i[i], 0, sqrt(1 - rho))
    )
  })
  do.call(rbind, rows)
}

test_that("the shipped unbalanced ICC(k) interval is the exact SB image of ICC(1) (AC5)", {
  skip_if_not_installed("glmmTMB")
  # The ICC(k) endpoints must equal npb_sb(ICC(1) endpoint, k_eff), where k_eff is the
  # design's harmonic mean -- the shipped-code realization of g, to machine precision.
  for (s in 1:6) {
    d <- unbalanced_icck_set(seed = s, rho = 0.4)
    k_eff <- 1 / mean(1 / as.integer(table(d$subject)))
    td <- tidy(icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      unit = c("single", "average"),
      ci_method = "npbootstrap",
      boot_samples = 299L,
      seed = s
    ))
    i1 <- td[td$index == "ICC(1)", ]
    ik <- td[td$index == "ICC(k)", ]
    expect_equal(ik$conf.low, npb_sb(i1$conf.low, k_eff), tolerance = 1e-12)
    expect_equal(ik$conf.high, npb_sb(i1$conf.high, k_eff), tolerance = 1e-12)
    # Strictly monotone map -> ordered, finite, and bounded above by 1.
    expect_lt(ik$conf.low, ik$conf.high)
    expect_true(is.finite(ik$conf.low) && is.finite(ik$conf.high))
    expect_lte(ik$conf.high, 1)
  }
})

test_that("ICC(k) coverage inherits from ICC(1) rep-by-rep, tolerance 0 (AC2 identity)", {
  skip_if_not_installed("glmmTMB")
  # Coverage inheritance is an EXACT event identity (MD-1): because g is strictly
  # monotone and finite on the attainable range, the ICC(k) coverage indicator
  # (truth = g(rho; k_eff)) equals the ICC(1) coverage indicator (truth = rho) for
  # every realization. Assert it rep-by-rep with ZERO discrepant reps -- a mechanical
  # check that the shipped code realizes the identity the coverage proof relies on.
  rho <- 0.5
  discrepant <- 0L
  n_ok <- 0L
  for (s in seq_len(60L)) {
    d <- unbalanced_icck_set(seed = 1000L + s, rho = rho)
    k_eff <- 1 / mean(1 / as.integer(table(d$subject)))
    td <- tryCatch(
      tidy(icc(
        d,
        score,
        subject,
        rater,
        model = "oneway",
        unit = c("single", "average"),
        ci_method = "npbootstrap",
        boot_samples = 199L,
        seed = 1000L + s
      )),
      intraclass_singular_fit = function(e) NULL
    )
    if (is.null(td)) {
      next
    }
    n_ok <- n_ok + 1L
    i1 <- td[td$index == "ICC(1)", ]
    ik <- td[td$index == "ICC(k)", ]
    cov1 <- i1$conf.low <= rho && rho <= i1$conf.high
    truth_k <- npb_sb(rho, k_eff)
    covk <- ik$conf.low <= truth_k && truth_k <= ik$conf.high
    if (!identical(cov1, covk)) {
      discrepant <- discrepant + 1L
    }
  }
  expect_gt(n_ok, 40L) # the sweep actually ran
  expect_equal(discrepant, 0L) # exact event identity, zero tolerance
})
