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
# `data-raw/sweep-abort-remedies.R` -> `tests/testthat/fixtures/abort-remedy-sweep.tsv`
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

# The two guards below are reached through their REDUCERS, not through `icc()`,
# because `gen_mse0` (exactly zero within-subject variance) sits at the numerical
# edge of the engine fit: glmmTMB survives it on some platforms and dies first
# with an unclassed "LU factorization ... near-singular" on others, so an
# `icc()`-level test of these two messages is platform-dependent. M100's sweep
# reached every site the same way -- "caught as its classed condition from the
# reducer called directly". The three sites whose fit IS robust (`gen_ssa0`,
# `gen_se_zero`, `gen_resample_degenerate`) stay end-to-end above and below.

test_that("the classical F-pivot abort names no method its sweep condemned (AC3)", {
  # Sweep verdict, gen_mse0 at classical_guard_observed(): montecarlo usable
  # 0/3, and no other shipped method is usable there either.
  ss <- classical_oneway_ss(split(gen_mse0()$score, gen_mse0()$subject))
  expect_identical(ss$mse, 0) # the guard's first disjunct, fired exactly

  msg <- abort_message(
    classical_guard_observed(ss, "SEARLE exact-F", rlang::current_env())
  )

  expect_match(msg, "interval is undefined for this data", fixed = TRUE)
  expect_false(grepl("montecarlo", msg, fixed = TRUE))
  expect_match(msg, "MSE", fixed = TRUE)
})

test_that("the bootstrap refit-convergence abort names no method its sweep condemned (AC4)", {
  # Sweep verdict, gen_mse0 at bootstrap_ci()'s refit guard: montecarlo usable
  # 0/6. The old text also asserted a single cause ("near a variance boundary or
  # the design is too small") that the sweep's jitter cells contradict.
  #
  # The guard counts refits whose draws are non-finite, so a stub engine whose
  # `simulate_refit` returns all-NA draws fires it deterministically -- what the
  # message says is the subject here, not how the draws came to be NA.
  stub <- list(
    simulate_refit = function(n, seed = NULL) {
      matrix(NA_real_, nrow = 2L, ncol = n)
    }
  )
  msg <- abort_message(
    bootstrap_ci(
      stub,
      estimands = list(list(divisor = 1)),
      boot_samples = 99L,
      call = rlang::current_env()
    )
  )

  expect_match(msg, "refits converged", fixed = TRUE)
  expect_false(grepl("montecarlo", msg, fixed = TRUE))
  expect_false(grepl("This usually means", msg, fixed = TRUE))
})

test_that("the npbootstrap resample-degeneracy abort still NAMES a remedy (AC5)", {
  skip_if_not_installed("glmmTMB")

  # What this test guards is that the hotfix de-named only the CONDEMNED sites:
  # it reds on a blanket de-naming sweep across every guard. That intent is
  # unchanged. What changed is how the name is earned.
  #
  # The hotfix asserted the literal "montecarlo", because this bullet was the one
  # hard-coded name the sweep had vindicated (usable 9/9 on this generator) and
  # so the one the hotfix left standing. M103 replaced that literal with the same
  # runtime verification the other five guards now use, and on this data the
  # deterministic pair is usable too, so verification reaches `searle`/`burch`
  # first and never runs the costlier `montecarlo`. Pinning the literal would now
  # pin the tier order rather than the truthfulness the test exists for.
  #
  # So the assertion is the stronger one M103 makes available: the guard names at
  # least one method, and every method it names is one that actually works on
  # this data.
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
  named <- unique(unlist(regmatches(
    msg,
    gregexpr('(?<=ci_method = ")[a-z]+(?=")', msg, perl = TRUE)
  )))
  expect_gt(length(named), 0L)
  ests <- list(
    icc_estimand(unit = "single", k_eff = 3, oneway = TRUE),
    icc_estimand(unit = "average", k_eff = 3, oneway = TRUE)
  )
  for (m in named) {
    expect_true(
      boundary_method_usable(
        m,
        d,
        ests,
        conf_level = 0.95,
        n0 = 3,
        seed = 1,
        boot_samples = 99L
      ),
      info = m
    )
  }
})

test_that("every touched degeneracy guard keeps its condition class (AC6)", {
  skip_if_not_installed("glmmTMB")

  sites <- list(
    list(d = gen_ssa0(), m = "npbootstrap"),
    list(d = gen_se_zero(), m = "npbootstrap"),
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

  # The two `gen_mse0` guards, at their reducers (see AC3/AC4 above for why).
  ss <- classical_oneway_ss(split(gen_mse0()$score, gen_mse0()$subject))
  expect_error(
    classical_guard_observed(ss, "SEARLE exact-F", rlang::current_env()),
    class = "intraclass_singular_fit"
  )
  expect_error(
    bootstrap_ci(
      list(simulate_refit = function(n, seed = NULL) {
        matrix(NA_real_, nrow = 2L, ncol = n)
      }),
      estimands = list(list(divisor = 1)),
      boot_samples = 99L,
      call = rlang::current_env()
    ),
    class = "intraclass_singular_fit"
  )
})
