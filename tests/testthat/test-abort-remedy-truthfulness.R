# Abort-remedy truthfulness at the CI-reducer degeneracy guards -----------------
#
# A degeneracy abort's remedy bullet may name a `ci_method` only where that
# method was MEASURED usable on the data that reaches the guard, and its
# diagnostic bullets may assert only what the guard's own condition establishes.
# Two defects motivated these tests, both reproduced on the pre-fix tree:
#
#   1. `npbootstrap_ci()`'s observed-data guard told the user to switch to
#      `ci_method = "montecarlo"` on data where montecarlo also aborts, while
#      `ci_method = "bootstrap"` returns a usable interval -- the message pointed
#      AWAY from the method that works.
#   2. That same guard asserted "Between- or within-subject variance is exactly
#      zero" on data whose log F is finite and whose variances are both healthy;
#      the guard's second disjunct is a zero jackknife SE, which the message did
#      not describe. It printed a finite log F inside a sentence claiming zero
#      variance.
#
# Provenance of the fixtures and the usability verdicts: the seeded sweep
# `data-raw/sweep-abort-remedies.R` -> `data-raw/abort-remedy-sweep.tsv`
# (210 rows) on branch `m100-abort-remedy-truthfulness`; the generators below are
# that script's `gen_mse0`, `gen_ssa0`, `gen_se_zero` and
# `gen_resample_degenerate`. Per-site verdicts are quoted at each test.

# Zero WITHIN-subject variance: every rater gives a subject the same score.
gen_mse0 <- function(n_s = 6L, n_r = 3L, seed = 1) {
  set.seed(seed)
  mu <- stats::rnorm(n_s, 0, 3)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(mu, each = n_r)
  )
}

# Zero BETWEEN-subject variance: every subject has the same score profile, so
# all subject means are equal (SSA = 0, log F = -Inf) while MSE stays positive.
gen_ssa0 <- function(n_s = 6L, n_r = 3L, seed = 1) {
  set.seed(seed)
  profile <- stats::rnorm(n_r, 0, 3)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(profile, times = n_s)
  )
}

# NEITHER variance degenerate, yet the observed-data guard fires: every subject's
# share of SSA equals its share of SSE, so all influence values are zero and
# `se_ij_logf == 0` while `log F` stays finite.
gen_se_zero <- function() {
  data.frame(
    subject = rep(1:3, each = 2),
    rater = rep(1:2, times = 3),
    score = c(-1.5, -0.5, 0, 0, 0.5, 1.5)
  )
}

# Healthy observed data, but so few subjects carry within-subject variance that a
# whole-subject resample routinely draws a degenerate one (M97's "double code").
gen_resample_degenerate <- function(
  n_s = 12L,
  n_r = 3L,
  n_varying = 2L,
  seed = 1
) {
  set.seed(seed)
  mu <- stats::rnorm(n_s, 0, 3)
  score <- rep(mu, each = n_r)
  for (i in seq_len(min(n_varying, n_s))) {
    idx <- ((i - 1) * n_r + 1):(i * n_r)
    score[idx] <- score[idx] + stats::rnorm(n_r, 0, 1)
  }
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = score
  )
}

# The message of the classed abort `expr` raises, as one plain string.
abort_message <- function(expr) {
  cnd <- tryCatch(
    suppressMessages(suppressWarnings(expr)),
    intraclass_error = function(e) e
  )
  expect_s3_class(cnd, "intraclass_error")
  paste(cli::ansi_strip(conditionMessage(cnd)), collapse = " ")
}

test_that("the npbootstrap observed-data abort names no method montecarlo cannot serve (AC1)", {
  skip_if_not_installed("glmmTMB")

  # Sweep verdict, gen_ssa0 at the npbootstrap observed-degeneracy guard:
  # montecarlo usable 0/4, bootstrap usable 4/4. The old text named montecarlo.
  d <- gen_ssa0()
  msg <- abort_message(
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "npbootstrap",
      boot_samples = 99L,
      seed = 1
    )
  )

  expect_match(
    msg,
    "transformed bootstrap-t interval is undefined",
    fixed = TRUE
  )
  expect_false(grepl("montecarlo", msg, fixed = TRUE))

  # The defect is a misdirection, not merely a dead end: montecarlo aborts on
  # this data and bootstrap succeeds on it. Both verdicts are asserted so the
  # test reds if the sweep's premise ever stops holding.
  expect_error(
    suppressMessages(suppressWarnings(
      icc(
        d,
        score,
        subject,
        rater,
        model = "oneway",
        ci_method = "montecarlo",
        mc_samples = 2000L,
        seed = 1
      )
    )),
    class = "intraclass_error"
  )
  boot <- suppressMessages(suppressWarnings(
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "bootstrap",
      boot_samples = 99L,
      seed = 1
    )
  ))
  expect_true(all(is.finite(c(
    boot$estimates$conf.low,
    boot$estimates$conf.high
  ))))
})

test_that("the npbootstrap observed-data abort asserts no cause its guard does not test (AC2)", {
  skip_if_not_installed("glmmTMB")

  # gen_se_zero: log F is FINITE (1.7918) and both variances are healthy; the
  # guard fires on its second disjunct, a zero jackknife SE. The old text
  # asserted "Between- or within-subject variance is exactly zero" here.
  d <- gen_se_zero()
  msg <- abort_message(
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "npbootstrap",
      boot_samples = 99L,
      seed = 1
    )
  )

  expect_false(grepl("variance is exactly zero", msg, fixed = TRUE))
  expect_false(grepl("montecarlo", msg, fixed = TRUE))
  # It reports both quantities the guard actually tested, so the reader can see
  # which disjunct fired.
  expect_match(msg, "log F", fixed = TRUE)
  expect_match(msg, "SE", fixed = TRUE)
})

test_that("the classical F-pivot abort names no method its sweep condemned (AC3)", {
  skip_if_not_installed("glmmTMB")

  # Sweep verdict, gen_mse0 at classical_guard_observed(): montecarlo usable
  # 0/3, and no other shipped method is usable there either.
  d <- gen_mse0()
  msg <- abort_message(
    icc(d, score, subject, rater, model = "oneway", ci_method = "searle")
  )

  expect_match(msg, "interval is undefined for this data", fixed = TRUE)
  expect_false(grepl("montecarlo", msg, fixed = TRUE))
  expect_match(msg, "MSE", fixed = TRUE)
})

test_that("the bootstrap refit-convergence abort names no method its sweep condemned (AC4)", {
  skip_if_not_installed("glmmTMB")

  # Sweep verdict, gen_mse0 at bootstrap_ci()'s refit guard: montecarlo usable
  # 0/6. The old text also asserted a single cause ("near a variance boundary or
  # the design is too small") that the sweep's jitter cells contradict.
  d <- gen_mse0()
  msg <- abort_message(
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "bootstrap",
      boot_samples = 99L,
      seed = 1
    )
  )

  expect_match(msg, "refits converged", fixed = TRUE)
  expect_false(grepl("montecarlo", msg, fixed = TRUE))
  expect_false(grepl("This usually means", msg, fixed = TRUE))
})

test_that("the npbootstrap resample-degeneracy abort KEEPS its montecarlo remedy (AC5)", {
  skip_if_not_installed("glmmTMB")

  # Sweep verdict, gen_resample_degenerate: montecarlo usable 9/9. This bullet
  # is truthful and must survive -- the fix de-names only condemned sites, and
  # this test reds on a blanket de-naming sweep.
  d <- gen_resample_degenerate()
  msg <- abort_message(
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "npbootstrap",
      boot_samples = 99L,
      seed = 1
    )
  )

  expect_match(msg, "resamples were degenerate", fixed = TRUE)
  expect_match(msg, "montecarlo", fixed = TRUE)
})

test_that("every touched degeneracy guard keeps its condition class (AC6)", {
  skip_if_not_installed("glmmTMB")

  sites <- list(
    list(d = gen_ssa0(), m = "npbootstrap"),
    list(d = gen_se_zero(), m = "npbootstrap"),
    list(d = gen_mse0(), m = "searle"),
    list(d = gen_mse0(), m = "bootstrap"),
    list(d = gen_resample_degenerate(), m = "npbootstrap")
  )
  for (s in sites) {
    expect_error(
      suppressMessages(suppressWarnings(
        icc(
          s$d,
          score,
          subject,
          rater,
          model = "oneway",
          ci_method = s$m,
          boot_samples = 99L,
          seed = 1
        )
      )),
      class = "intraclass_singular_fit"
    )
  }
})
