# M104: what `ci_method = "bootstrap"` reports when its interval sits above its
# own point estimate.
#
# Two instruments, deliberately different. The AC2 block reads the COMMITTED
# fixture and pins the bound the shipped documentation states; it can only fail
# when the fixture is regenerated. The AC6 block makes a LIVE call and pins the
# motivating observation itself, so a change in what `icc()` reports reds a test
# without anyone re-running the sweep.
#
# Both are scoped to what was measured. The fixture assertions quantify over the
# rows that fixture contains and claim nothing about cells outside it -- the grid
# and its exclusions are documented in
# `data-raw/sweep-bootstrap-point-containment.R`.

read_containment_sweep <- function() {
  path <- test_path("fixtures", "bootstrap-point-containment.tsv")
  utils::read.delim(path, comment.char = "#", stringsAsFactors = FALSE)
}

# The zero-between-subject-variance generator, matching
# `tests/testthat/test-reducer-abort-hint.R:34` and the `gen_ssa0()` in
# `data-raw/sweep-bootstrap-point-containment.R`. Every subject shares one rater
# profile, so the subject factor carries no signal.
gen_ssa0_containment <- function(n_s, n_r, jitter_sd = 0, seed = 1) {
  set.seed(seed)
  profile <- stats::rnorm(n_r, 0, 3)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(profile, times = n_s) + stats::rnorm(n_s * n_r, 0, jitter_sd)
  )
}

# --- AC2: the committed sweep's containment bound ----------------------------

test_that("every excluding cell in the sweep is inside the 1e-8 bound (AC2)", {
  sweep <- read_containment_sweep()
  ok <- sweep[sweep$status == "ok", ]
  # A guard on the fixture itself: an empty or all-aborted fixture would satisfy
  # every assertion below vacuously, which is the failure mode a bound like this
  # invites. AC1 fixes 12 reported cells per arm, two indices each.
  expect_gte(nrow(ok), 48L)
  expect_setequal(unique(ok$arm), c("zero-between", "nonzero-between"))

  excluding <- ok[ok$excludes_point, ]
  # Every row where the limit sits above the point does so by less than 1e-8, and
  # does so only where the point is itself below 1e-8 -- the two claims the
  # `@param ci_method` paragraph makes.
  expect_true(all(excluding$gap < 1e-8))
  expect_true(all(excluding$estimate < 1e-8))

  # And the converse, over the same rows: where the point carries real signal the
  # interval contains it.
  signal <- ok[ok$estimate >= 1e-8, ]
  expect_true(all(signal$conf_low <= signal$estimate))
})

# --- AC6: the motivating call, live ------------------------------------------

test_that("the motivating 6x3 call reports conf.low above its point (AC6)", {
  skip_on_cran()
  # The observation M104 exists for, at the exact call the milestone pins: the
  # shipped `boot_samples` default, the reducer seed the sweep used, and the
  # shipped defaults for engine, unit and conf_level.
  df <- gen_ssa0_containment(6L, 3L, jitter_sd = 0, seed = 1)
  fit <- icc(
    df,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "bootstrap",
    seed = 1L,
    boot_samples = 999L
  )
  est <- as.data.frame(fit$estimates)
  row <- est[est$index == "ICC(1)", ]
  expect_identical(nrow(row), 1L)

  # The relation itself -- nothing else in the suite pins it.
  expect_gt(row$conf.low, row$estimate)
  # ...and that it stays inside the bound the documentation states, which is what
  # makes the relation harmless rather than a defect.
  expect_lt(row$estimate, 1e-8)
  expect_lt(row$conf.low, 1e-8)
})
