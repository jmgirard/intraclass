# Boundary-fit policy guards (M50 / D-004) ------------------------------------
#
# One consolidated home pinning `DESIGN.md § Boundary-fit policy`: every engine
# and CI method resolves a near-zero / singular variance component by one of
# three documented behaviors -- *smooth (log-SD)*, *classed deferral* (the
# `intraclass_singular_fit` condition), or *kept-at-0*. Each test names its
# governing ADR + D-004 so a future "simplification" fails here instead of
# silently changing the boundary-aware-interval contract (PRINCIPLES.md #3 / GP7).
# These tests PIN existing behavior; M50 changed none of it.
#
# Shared boundary fixture: with no rater effect and few raters, the rater
# variance collapses to exactly zero -- the boundary. glmmTMB stays finite there;
# lme4 (singular merDeriv covariance) and lavaan (Heywood) defer; the sampling CI
# methods keep the 0 draw.

boundary_two_way <- function(seed = 7L, n_s = 20L, n_r = 4L) {
  set.seed(seed)
  subj <- stats::rnorm(n_s, 0, 2)
  grid <- expand.grid(
    subject = factor(seq_len(n_s)),
    rater = factor(seq_len(n_r))
  )
  # NO rater effect -> sigma^2_rater estimated at exactly zero (the boundary).
  grid$score <- subj[as.integer(grid$subject)] + stats::rnorm(n_s * n_r, 0, 1)
  grid
}

# --- Smooth (log-SD): glmmTMB + the Monte-Carlo default (ADR-002/003, D-004) ---

test_that("glmmTMB gives a finite, boundary-aware Monte-Carlo interval at zero rater variance", {
  skip_if_not_installed("glmmTMB")

  # glmmTMB carries variances on the internal log-SD scale, so the boundary maps
  # to -Inf smoothly; the default Monte-Carlo method samples on that scale and
  # back-transforms, so every draw is strictly positive. The interval therefore
  # exists, is finite, and stays inside [0, 1] -- no abort, no NA -- even when a
  # component sits on the boundary (DESIGN.md § Boundary-fit policy; ADR-002/003).
  fit <- suppressWarnings(icc(
    boundary_two_way(),
    score,
    subject,
    rater,
    engine = "glmmTMB",
    mc_samples = 2000L,
    seed = 1
  ))
  est <- fit$estimates
  expect_true(all(is.finite(est$conf.low) & is.finite(est$conf.high)))
  expect_true(all(est$conf.low >= 0 & est$conf.high <= 1))
  # Boundary-aware: the rater-driven interval can reach the floor (never negative).
  expect_gte(min(est$conf.low), 0)
})

# --- Kept-at-0: the parametric bootstrap keeps a boundary resample (ADR-025, D-004) ---

test_that("bootstrap keeps a component-at-0 resample rather than dropping it", {
  skip_if_not_installed("glmmTMB")

  # The parametric bootstrap refits per resample; a resample landing on the
  # boundary returns a variance of exactly 0 and is a VALID draw, kept (not
  # discarded). So the interval comes back finite and can reach 0 at the boundary
  # (DESIGN.md § Boundary-fit policy; ADR-025). Only wholesale refit failure aborts.
  fit <- suppressWarnings(icc(
    boundary_two_way(),
    score,
    subject,
    rater,
    engine = "glmmTMB",
    ci_method = "bootstrap",
    boot_samples = 199L,
    seed = 1
  ))
  est <- fit$estimates
  expect_true(all(is.finite(est$conf.low) & is.finite(est$conf.high)))
  expect_true(all(est$conf.low >= 0 & est$conf.high <= 1))
})

# --- Classed deferral: lme4 singular fit -> intraclass_singular_fit (ADR-012, D-004) ---

test_that("lme4 defers a singular boundary fit via the classed intraclass_singular_fit", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # base lme4 does not expose the joint covariance of the variance parameters; on
  # an exactly-singular fit merDeriv's information matrix is singular, so no
  # Monte-Carlo covariance can be formed. The engine fails loudly with the classed
  # `intraclass_singular_fit` condition pointing at glmmTMB, rather than returning
  # a bogus interval (DESIGN.md § Boundary-fit policy; ADR-012).
  expect_error(
    suppressWarnings(icc(
      boundary_two_way(),
      score,
      subject,
      rater,
      engine = "lme4",
      seed = 1
    )),
    class = "intraclass_singular_fit"
  )
})

# --- Classed deferral: lavaan Heywood boundary -> intraclass_singular_fit (ADR-014/031, D-004) ---

test_that("lavaan defers a Heywood boundary via the classed intraclass_singular_fit", {
  skip_if_not_installed("lavaan")

  # Perfectly correlated raters give a non-positive variance estimate (a Heywood
  # case): sv/ev <= 0 cannot be put on the log-SD scale, so no boundary-aware
  # interval can be formed. The failure is converted to the same classed
  # `intraclass_singular_fit` condition pointing at glmmTMB -- the lavaan analog of
  # the lme4 guard (DESIGN.md § Boundary-fit policy; ADR-014/031).
  d <- data.frame(
    subject = factor(rep(1:6, 4)),
    rater = factor(rep(1:4, each = 6)),
    score = rep(c(3, 5, 7, 2, 9, 4), 4)
  )
  expect_error(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      engine = "lavaan",
      seed = 1
    )),
    class = "intraclass_singular_fit"
  )
})

# --- Kept-at-0: the fixed-rater theta^2_r average-floor (ADR-038, D-004) ------

test_that("fixed-rater theta^2_r is floored at 0, never negative, at the boundary", {
  skip_if_not_installed("glmmTMB")

  # With no rater effect the fixed-rater theta^2_r sits on the boundary. The
  # boundary-aware AVERAGE-floor (2b-corrected draws averaged, then the average
  # floored at 0 -- never per group) keeps the reported rater component >= 0
  # rather than pushing it negative (DESIGN.md § Boundary-fit policy; ADR-038).
  fit <- suppressWarnings(icc(
    boundary_two_way(),
    score,
    subject,
    rater,
    engine = "glmmTMB",
    raters = "fixed",
    mc_samples = 2000L,
    seed = 1
  ))
  expect_gte(fit$components$rater, 0)
  est <- fit$estimates
  expect_true(all(est$conf.low >= 0 & est$conf.high <= 1))
})

# --- Kept-at-0: the boundary-aware posterior mode (ADR-033/044, D-004) --------

test_that("posterior_mode stays boundary-aware for a component piled at 0", {
  # The Bayesian/posterior path reports the boundary-aware MODE of the natural-scale
  # variance draws (kept, never clamped): a component piled at the zero boundary
  # must place the mode at/near 0 through the [0, .] bound, not smear it negative,
  # and degenerate all-equal draws return the common value rather than erroring
  # (DESIGN.md § Boundary-fit policy; ADR-033/044). Uses the internal helper, so no
  # Stan toolchain is needed; the live-brms deferral is pinned in test-icc-brms.R.
  set.seed(2)
  piled <- abs(stats::rnorm(20000, 0, 0.2)) # half-normal mass at the 0 boundary
  m <- posterior_mode(piled, lower = 0)
  expect_gte(m, 0)
  expect_lt(m, 0.1)
  expect_equal(posterior_mode(rep(0.4, 100), lower = 0, upper = 1), 0.4)
})
