# M93: the design-aware hint appended to the CI-stage boundary aborts.
#
# T1 (AC1) lives here: the reproduction that establishes WHICH abort sites a
# near-sigma^2 -> 0 dataset actually reaches. The hint is added only to sites shown
# reachable (M84: an engine point-fit can crash first and leave a downstream guard
# unreachable), so this file is the evidence the AC2 scope rests on.
#
# The three candidate CI-stage `intraclass_singular_fit` sites, by message signature
# (the message text is the only discriminator -- one class covers all three):
#   A  R/ci-montecarlo.R:43   "fitted parameter covariance is not finite"  (rmvn)
#   B  R/ci-montecarlo.R:124  "draws were non-finite"                      (mc_interval)
#   C  R/ci-bootstrap.R:48    "refits converged"                           (bootstrap_ci)

# ---- Shared boundary fixtures -----------------------------------------------
# sigma^2_subject driven to ~0 with a healthy error variance: the cell where the
# MC default aborts (D-006 one-way 28-39%; D-014 two-way 25.9/31.2%).

bh_oneway <- function(n_s = 30, n_k = 5, s2s = 1e-6, s2e = 1.0, seed = 1) {
  set.seed(seed)
  s <- stats::rnorm(n_s, sd = sqrt(s2s))
  y <- rep(s, each = n_k) + stats::rnorm(n_s * n_k, sd = sqrt(s2e))
  data.frame(
    subject = factor(rep(seq_len(n_s), each = n_k)),
    rater = factor(rep(seq_len(n_k), times = n_s)),
    score = as.numeric(y)
  )
}

bh_twoway <- function(
  n_s = 20,
  n_r = 3,
  s2s = 1e-4,
  s2r = 0.3,
  s2e = 0.6,
  seed = 1
) {
  set.seed(seed)
  s <- stats::rnorm(n_s, sd = sqrt(s2s))
  r <- stats::rnorm(n_r, sd = sqrt(s2r))
  y <- outer(s, rep(1, n_r)) +
    outer(rep(1, n_s), r) +
    matrix(stats::rnorm(n_s * n_r, sd = sqrt(s2e)), n_s, n_r)
  data.frame(
    subject = factor(rep(seq_len(n_s), times = n_r)),
    rater = factor(rep(seq_len(n_r), each = n_s)),
    score = as.numeric(y)
  )
}

# Classify an abort by its message. cli hard-wraps the rendered message, so match
# on whitespace-collapsed text -- a fixed-string grep for "draws were non-finite"
# misses a wrap that lands between the words.
bh_site <- function(msg) {
  m <- gsub("[[:space:]]+", " ", msg)
  if (grepl("covariance is not finite", m, fixed = TRUE)) {
    return("A")
  }
  if (grepl("draws were non-finite", m, fixed = TRUE)) {
    return("B")
  }
  if (grepl("refits converged", m, fixed = TRUE)) {
    return("C")
  }
  "other"
}

# Run icc() and report the abort site reached, or "ok".
bh_probe <- function(d, ...) {
  tryCatch(
    {
      suppressWarnings(suppressMessages(icc(d, score, subject, rater, ...)))
      "ok"
    },
    intraclass_singular_fit = function(e) bh_site(conditionMessage(e))
  )
}

# ---- AC1: the reproduction, and which sites it reaches -----------------------

test_that("a near-zero-variance dataset aborts through the DEFAULT MC path (AC1)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Sweep seeds rather than pin one: the abort is a property of the boundary cell,
  # not of a particular draw, and glmmTMB's convergence is platform-sensitive.
  ow <- vapply(
    1:12,
    function(sd) {
      bh_probe(
        bh_oneway(seed = sd),
        ci_method = "montecarlo",
        model = "oneway",
        seed = 1
      )
    },
    character(1)
  )
  tw <- vapply(
    1:12,
    function(sd) {
      bh_probe(bh_twoway(seed = sd), ci_method = "montecarlo", seed = 1)
    },
    character(1)
  )

  # The default MC path aborts on a material fraction of both designs.
  expect_gt(sum(ow != "ok"), 0L)
  expect_gt(sum(tw != "ok"), 0L)

  # Every abort reached is a Monte-Carlo site (A or B), never the bootstrap site.
  expect_setequal(
    setdiff(unique(c(ow, tw)), "ok"),
    intersect(c("A", "B"), c(ow, tw))
  )
  expect_false("C" %in% c(ow, tw))
  expect_false("other" %in% c(ow, tw))

  # Site B (non-finite draws) is the dominant one -- the site the hint most needs.
  expect_gt(sum(c(ow, tw) == "B"), 0L)
})

test_that("the bootstrap abort site is NOT reachable at the sigma^2 -> 0 boundary (AC2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # AC2 excludes R/ci-bootstrap.R:48 from the hint on this evidence. Pinning it here
  # (GP7) means the exclusion cannot rot silently: if a future engine change makes
  # boundary refits fail, this reds and the exclusion is revisited rather than
  # quietly becoming wrong.
  res <- vapply(
    1:4,
    function(sd) {
      bh_probe(
        bh_oneway(n_s = 8, n_k = 3, s2s = 0, seed = sd),
        ci_method = "bootstrap",
        model = "oneway",
        boot_samples = 40L,
        seed = 1
      )
    },
    character(1)
  )
  expect_true(all(res == "ok"))
})

test_that("the reachable bootstrap abort takes DEGENERATE data, where no method helps (AC2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # What DOES reach site C: zero within-subject variance. On such data every method
  # the mapping table would name aborts too, so a hint there would point at another
  # abort -- exactly what AC3 makes a test failure. This is why AC2 excludes it.
  d <- data.frame(
    subject = factor(rep(1:3, each = 2)),
    rater = factor(rep(1:2, times = 3)),
    score = rep(c(1, 5, 9), each = 2)
  )
  expect_identical(
    bh_probe(
      d,
      ci_method = "bootstrap",
      model = "oneway",
      boot_samples = 30L,
      seed = 1
    ),
    "C"
  )
  for (m in c("npbootstrap", "searle", "burch")) {
    expect_error(
      suppressWarnings(suppressMessages(
        icc(d, score, subject, rater, ci_method = m, model = "oneway")
      )),
      class = "intraclass_singular_fit"
    )
  }
})
