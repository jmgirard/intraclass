# M118 -- the seven simulated families against burch2011 Table 2 (p. 1021).
#
# Why three legs rather than one tolerance on the simulated kurtosis. The sample
# excess kurtosis needs a finite EIGHTH moment to have a finite asymptotic
# variance. t(5)'s moments are finite only below order 5, so that statistic never
# settles: measured over 8 seeds at 1e6 draws it ranges 4.54-6.45 against a
# printed 6.0 (`data-raw/m118-kurtosis-spread.R` re-derives every spread quoted
# here). A single tolerance covering that would have to be ~30x the original and
# would be toothless for the five well-behaved families.
#
# So: (a) an exact closed form per family, (b) mean/variance -- which DO converge
# and are what a mis-scaling breaks, (c) an ordering check across all seven, plus
# a real tolerance for the three families whose spread supports one.
#
# Leg (c)'s powexp tolerance is load-bearing, not decoration. `pe_beta` is the
# only distributional constant that legs (a) and (b) both inherit from the draw
# itself -- every other family's scale is a literal (sqrt(12), sqrt(10/8),
# sqrt(2), sqrt(5/3)), so a wrong df there breaks the variance leg and is caught.
# A wrong beta does not: it survives (a) (same constant), survives (b) (the
# divisor is derived from it), and for beta in roughly (2.2, 3.4) leaves the
# kurtosis inside its neighbours' bracket, so it would survive the ordering too.

sweep_script <- testthat::test_path(
  "..",
  "..",
  "data-raw",
  "m118-width-reversal-sweep.R"
)

# Pull the generator definitions WITHOUT running the script -- it calls
# devtools::load_all() and a sweep at top level.
m118_defs <- function(path) {
  env <- new.env(parent = globalenv())
  wanted <- c("draw_standard", "pe_beta", "table2_kurtosis")
  for (e in as.list(parse(path))) {
    if (
      is.call(e) &&
        is.name(e[[1]]) &&
        as.character(e[[1]]) %in% c("<-", "=") &&
        is.name(e[[2]]) &&
        as.character(e[[2]]) %in% wanted
    ) {
      eval(e, envir = env)
    }
  }
  missing <- setdiff(wanted, ls(env))
  if (length(missing)) {
    stop("not found in ", path, ": ", paste(missing, collapse = ", "))
  }
  env
}

excess_kurtosis <- function(x) mean(((x - mean(x)) / stats::sd(x))^4) - 3

test_that("each family's closed-form kurtosis matches Table 2's printed value", {
  skip_if_not(
    file.exists(sweep_script),
    "data-raw/ not present (built package)"
  )
  env <- m118_defs(sweep_script)
  b <- env$pe_beta

  # Written out in each family's OWN parameters, never read back from
  # table2_kurtosis -- otherwise this leg compares the table to itself.
  closed_form <- c(
    uniform = -6 / 5, # continuous uniform
    powexp = gamma(5 / b) * gamma(1 / b) / gamma(3 / b)^2 - 3,
    gaussian = 0,
    t10 = 6 / (10 - 4), # t(nu): 6/(nu-4), nu > 4
    laplace = 3,
    t5 = 6 / (5 - 4),
    chisq1 = 12 / 1 # chi-squared(k): 12/k
  )

  printed <- env$table2_kurtosis
  expect_identical(sort(names(closed_form)), sort(names(printed)))
  for (fam in names(printed)) {
    expect_lt(abs(closed_form[[fam]] - printed[[fam]]), 0.01)
  }
})

test_that("the family enumeration equals the generator's own switch arms", {
  skip_if_not(
    file.exists(sweep_script),
    "data-raw/ not present (built package)"
  )
  env <- m118_defs(sweep_script)
  # An eighth family added to draw_standard() but not to table2_kurtosis would
  # otherwise escape every check in this file while satisfying "the seven
  # families" as written.
  sw <- body(env$draw_standard)[[2]]
  arms <- setdiff(names(as.list(sw))[-(1:2)], "")
  expect_identical(sort(arms), sort(names(env$table2_kurtosis)))
})

test_that("every family draws mean 0, variance 1, at both component sizes", {
  skip_if_not(
    file.exists(sweep_script),
    "data-raw/ not present (built package)"
  )
  env <- m118_defs(sweep_script)
  # Both sizes a cell actually uses. The DGP fence
  # (test-m118-both-components-dgp.R) is what establishes that BOTH the subject
  # effect and the residual route through this one function, so checking it here
  # covers both components.
  for (m in c(1e6L, 2e6L)) {
    for (fam in names(env$table2_kurtosis)) {
      set.seed(118L)
      x <- env$draw_standard(m, fam)
      expect_lt(abs(mean(x)), 0.01, label = paste("mean", fam, m))
      expect_lt(abs(stats::var(x) - 1), 0.01, label = paste("var", fam, m))
    }
  }
})

test_that("simulated kurtoses rise with printed kurtosis, and pin the three that can be pinned", {
  skip_if_not(
    file.exists(sweep_script),
    "data-raw/ not present (built package)"
  )
  env <- m118_defs(sweep_script)
  printed <- env$table2_kurtosis
  ord <- names(printed)[order(printed)]

  sim <- vapply(
    ord,
    function(fam) {
      set.seed(118L)
      excess_kurtosis(env$draw_standard(1e6L, fam))
    },
    numeric(1)
  )

  # (c1) ordering -- this is what catches a swapped df or two families
  # exchanged. The tightest measured gap is laplace to t5 (~1.5).
  expect_true(all(diff(sim) > 0))

  # (c2) a real tolerance where the estimator converges well enough to carry
  # one. Dropping these would be a bar-drop, not a mis-set-pin correction:
  # measured spreads over 8 seeds are 0.002 / 0.007 / 0.017.
  for (fam in c("uniform", "powexp", "gaussian")) {
    expect_lt(
      abs(sim[[fam]] - printed[[fam]]),
      0.02,
      label = paste("kurt", fam)
    )
  }
})
