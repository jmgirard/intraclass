# brms (Bayesian) engine + ci_method = "posterior" — Slice 1 wiring (M23/ADR-033)
#
# Slice 1 is ENGINE + INTERVAL-METHOD WIRING; the coverage oracle (O-Bayes) is Slice 2.
# So the tests here split in two:
#   * The COUPLING and SCOPE aborts, and the posterior_mode()/posterior_summary()
#     reducers, need NO brms install (they fire/run before check_installed("brms")) and
#     run on every CI job.
#   * A single LIVE brms fit (skip_if_not_installed + skip_on_cran, tiny chains/iter)
#     exercises the real Stan wiring: draw extraction, the "posterior" branch end to end,
#     the credible-interval labelling, and a loose MAP ~ REML sanity check (a preview of
#     the Slice-2 O-Bayes-agree oracle, not the coverage oracle itself).
#
# We do NOT snapshot the printed MCMC fit: the reported point/interval are functions of
# posterior draws that can drift across brms/Stan versions, so a numeric snapshot is
# brittle. The print/tidy assertions target the DETERMINISTIC structure instead (the
# engine + "posterior credible" label, the row set, ci$method), matching the house
# guidance against snapshotting fitted-model prints.

# --- Coupling: engine <-> ci_method are locked together (no brms needed) -------

test_that("ci_method = \"posterior\" requires engine = \"brms\"", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, ci_method = "posterior"),
    class = "intraclass_unsupported"
  )
})

test_that("engine = \"brms\" rejects non-posterior ci_method", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, engine = "brms", ci_method = "montecarlo"),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(d, score, subject, rater, engine = "brms", ci_method = "bootstrap"),
    class = "intraclass_unsupported"
  )
})

test_that("engine = \"brms\" forces ci_method = \"posterior\" by default", {
  # The forced default is applied before any fit, so we can observe it via the
  # downstream check_installed abort's ABSENCE of a ci_method complaint: with brms
  # installed the fit proceeds; without it, the ONLY error is the missing package,
  # never a ci_method mismatch. Assert the coupling logic directly through the message.
  d <- sf_ratings_long()
  err <- tryCatch(
    icc(d, score, subject, rater, engine = "brms"),
    condition = function(e) e
  )
  # Either it fit (brms present) or it aborted on the missing package -- never on the
  # ci_method (the default upgraded to "posterior" silently).
  if (inherits(err, "icc")) {
    expect_identical(err$ci$method, "posterior")
  } else {
    expect_false(grepl("ci_method", conditionMessage(err)))
  }
})

# --- brm_args passthrough guards (no brms needed) ------------------------------

test_that("brm_args only applies to engine = \"brms\"", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, brm_args = list(chains = 2)),
    class = "intraclass_unsupported"
  )
})

test_that("brm_args may not override the model, prior, data, or seed", {
  d <- sf_ratings_long()
  for (key in c("formula", "data", "prior", "seed")) {
    args <- list(d, quote(score), quote(subject), quote(rater), engine = "brms")
    args$brm_args <- stats::setNames(list("x"), key)
    expect_error(
      do.call(icc, args),
      class = "intraclass_error"
    )
  }
})

test_that("brm_args must be a list", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, engine = "brms", brm_args = "chains"),
    class = "intraclass_error"
  )
})

# --- brms scope: two-way random, balanced/complete only (no brms needed) -------
# These fire before the fit, so they assert the deferral boundary without Stan.

test_that("brms refuses the deferred designs with a teaching abort", {
  d <- sf_ratings_long()
  # one-way
  expect_error(
    icc(d, score, subject, rater, model = "oneway", engine = "brms"),
    class = "intraclass_unsupported"
  )
  # fixed raters (the general fixed-rater advisory warning fires first; expected)
  expect_error(
    suppressWarnings(
      icc(d, score, subject, rater, raters = "fixed", engine = "brms")
    ),
    class = "intraclass_unsupported"
  )
  # numeric unit (D-study projection)
  expect_error(
    icc(d, score, subject, rater, unit = 6, engine = "brms"),
    class = "intraclass_unsupported"
  )
  # incomplete data
  d_inc <- d[-1, , drop = FALSE]
  expect_error(
    icc(d_inc, score, subject, rater, engine = "brms"),
    class = "intraclass_unsupported"
  )
})

test_that("brms multilevel is refused", {
  d <- sf_ratings_long()
  d$cluster <- factor(rep(c("a", "b"), length.out = nrow(d)))
  expect_error(
    icc(d, score, subject, rater, cluster = cluster, engine = "brms"),
    class = "intraclass_unsupported"
  )
})

test_that("brms surfaces the k = 2 bias caveat as a soft note", {
  # The note is emitted BEFORE fit dispatch. Intercept it and abort the call the instant
  # it fires, so the assertion holds whether or not brms is installed and no (slow, noisy)
  # Stan fit is ever run.
  d2 <- sf_ratings_long()
  d2 <- d2[d2$rater %in% c("J1", "J2"), , drop = FALSE]
  d2$rater <- droplevels(d2$rater)
  saw_note <- FALSE
  tryCatch(
    withCallingHandlers(
      icc(d2, score, subject, rater, engine = "brms"),
      message = function(m) {
        if (grepl("k = 2", conditionMessage(m), fixed = TRUE)) {
          saw_note <<- TRUE
          stop("stop-after-note")
        }
      }
    ),
    error = function(e) invisible(NULL)
  )
  expect_true(saw_note)
})

# --- posterior_mode(): boundary-aware mode of a draw vector (no brms needed) ---

test_that("posterior_mode recovers a known interior mode", {
  set.seed(1)
  # Beta(8, 2) has mode (a-1)/(a+b-2) = 7/8 = 0.875 on [0, 1].
  expect_equal(
    posterior_mode(rbeta(20000, 8, 2), lower = 0, upper = 1),
    0.875,
    tolerance = 0.03
  )
  # Gamma(3, 2) has mode (a-1)/rate = 2/2 = 1 on [0, Inf).
  expect_equal(
    posterior_mode(rgamma(20000, 3, 2), lower = 0),
    1,
    tolerance = 0.05
  )
})

test_that("posterior_mode handles a boundary pile-up and degenerate draws", {
  set.seed(2)
  # Half-normal-ish mass piled at 0 (a variance component near the boundary): the
  # reflected KDE should place the mode at/near 0, not smear it negative.
  v <- abs(rnorm(20000, 0, 0.2))
  m <- posterior_mode(v, lower = 0)
  expect_gte(m, 0)
  expect_lt(m, 0.1)
  # All-equal draws: no density to smooth -> return the common value, not an error.
  expect_equal(posterior_mode(rep(0.4, 100), lower = 0, upper = 1), 0.4)
  # A single draw / empty input degrade gracefully.
  expect_equal(posterior_mode(0.3), 0.3)
  expect_true(is.na(posterior_mode(numeric(0))))
})

# --- posterior_summary(): reduce a draw matrix to point + credible interval ----

test_that("posterior_summary returns a MAP point inside its percentile interval", {
  set.seed(3)
  n <- 4000
  # A plausible two-way posterior: subject/rater/residual variance draws.
  draws <- rbind(
    subject = rgamma(n, 5, 5),
    rater = rgamma(n, 2, 8),
    residual = rgamma(n, 6, 6)
  )
  ests <- list(
    icc_estimand(
      type = "agreement",
      unit = "single",
      raters = "random",
      k_eff = 4
    ),
    icc_estimand(
      type = "consistency",
      unit = "average",
      raters = "random",
      k_eff = 4
    )
  )
  summ <- posterior_summary(draws, ests, conf_level = 0.95)
  expect_length(summ, 2)
  for (s in summ) {
    expect_true(all(
      c("point", "conf.low", "conf.high", "std.error") %in% names(s)
    ))
    expect_gte(s$point, s$conf.low)
    expect_lte(s$point, s$conf.high)
    expect_gte(s$conf.low, 0)
    expect_lte(s$conf.high, 1)
  }
})

# --- Live brms fit: the full pipeline (needs brms + a Stan toolchain) ----------

test_that("brms fits the two-way random ICC end to end (O-Bayes-agree sanity)", {
  skip_on_cran()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  # Tiny sampler for a fast wiring check (NOT the coverage oracle -- that is Slice 2's
  # committed reference). Seeded via `seed` -> Stan. Sampling warnings on this 6-subject
  # design (low ESS at tiny iter) are expected and irrelevant to the wiring, so muffle.
  fit <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1000, refresh = 0)
  ))

  expect_s3_class(fit, "icc")
  expect_identical(fit$engine, "brms")
  expect_identical(fit$ci$method, "posterior")
  # samples = post-warmup draws = chains * (iter/2) = 2 * 500.
  expect_identical(fit$ci$samples, 1000L)

  # A default call reports the agreement family (single + average); consistency is a
  # separate call. Both rows must be finite probabilities with the point in its interval.
  td <- tidy(fit)
  expect_setequal(td$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_true(all(td$estimate >= 0 & td$estimate <= 1))
  expect_true(all(td$conf.low <= td$estimate & td$estimate <= td$conf.high))

  # Wiring sanity (a preview of Slice-2's O-Bayes-agree, not the oracle): the glmmTMB
  # REML point falls inside the brms credible interval. NOTE we do NOT assert MAP ~ REML
  # pointwise -- the MAP is the mode of the ICC DRAWS, not icc_point() of the modal
  # components (MAP(ICC) != icc_point(MAP components), ADR-033), so on a wide skewed
  # n = 6 posterior it legitimately sits below the REML plug-in.
  g <- tidy(icc(d, score, subject, rater, engine = "glmmTMB", seed = 1))
  by_index <- function(x, i) x$estimate[x$index == i]
  for (i in c("ICC(A,1)", "ICC(A,k)")) {
    reml <- by_index(g, i)
    expect_gte(reml, td$conf.low[td$index == i])
    expect_lte(reml, td$conf.high[td$index == i])
  }

  # The header reports a Bayesian (MCMC) engine and a CREDIBLE interval (format() is the
  # deterministic source print.icc renders verbatim).
  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
})
