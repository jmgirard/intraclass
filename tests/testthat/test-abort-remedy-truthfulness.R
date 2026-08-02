# M100: an abort's remedy may name a `ci_method` only where that method works on
# the data reaching the abort.
#
# Three CI-reducer aborts used to end with "use `ci_method = \"montecarlo\"`" on
# data where the Monte-Carlo default aborts too -- the one remedy they offered was
# the one that could not work. `data-raw/sweep-abort-remedies.R` measured it:
# across the geometries reaching each guard, the default was usable on none of
# them, and so was every other shipped method. Those three bullets now name no
# method and point at the data instead.
#
# The division of labour matters. The SWEEP establishes the empirical claim (which
# methods survive which trigger class) and is committed as evidence in
# `data-raw/abort-remedy-sweep.tsv`; it is a data-raw job, not a per-CI-run one.
# This file pins the property of the SHIPPED TEXT that the sweep licenses, which is
# what a future edit can silently break.
#
# Every abort is fired at its REDUCER directly, never through `icc()`. That is not
# a shortcut: M93's review found the glmmTMB point fit dying with a raw, unclassed
# error before the CI-stage guard is reached on Linux and Windows (the M84 lesson),
# so an `icc()`-routed test of these guards is platform-dependent by construction.
# The bootstrap site goes further and uses a stub engine, so the guard fires on
# arithmetic alone with no fit anywhere in the picture.

# Zero within-subject variance: every rater gives a subject the same score, so
# MSE = 0 and the classical F pivot and the npbootstrap IJ SE are both undefined.
art_mse0 <- function(n_s = 8, n_r = 3) {
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(seq_len(n_s) * 1.5, each = n_r)
  )
}

# Zero between-subject variance: every subject shares one score profile, so all
# subject means are equal, SSA = 0 and log F = -Inf. MSE stays positive, which is
# the OTHER disjunct of the npbootstrap observed-data guard.
art_ssa0 <- function(n_s = 8, n_r = 3) {
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(c(1, 2, 3)[seq_len(n_r)], times = n_s)
  )
}

# NEITHER variance is degenerate, yet the npbootstrap observed-data guard still
# fires: every subject's share of SSA equals its share of SSE, so all influence
# values are zero and `se_ij_logf == 0` while `log F` stays finite (1.79 here).
# Subject means are -1/0/1 and within-subject ranges 1/0/1, so a message claiming
# either "every subject has the same mean score" or "every rater agreed exactly"
# is false on this data. That is what M100's first attempt shipped (review A1).
art_se_zero <- function() {
  data.frame(
    subject = rep(1:3, each = 2),
    rater = rep(1:2, times = 3),
    score = c(-1.5, -0.5, 0, 0, 0.5, 1.5)
  )
}

# One non-finite score drives both mean squares to NaN, so `ss$mse == 0` is NA.
# This is the input that crashed the guard at review pass 2 (finding F1).
art_nan_mse <- function(n_s = 6, n_r = 3) {
  set.seed(1)
  score <- stats::rnorm(n_s * n_r)
  score[1] <- Inf
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = score
  )
}

art_ests <- function(k_eff = 3) {
  list(icc_estimand(unit = "single", k_eff = k_eff, oneway = TRUE))
}

# An engine whose refits all fail. `bootstrap_ci()` reads only `simulate_refit`,
# so this fires the convergence guard deterministically -- no glmmTMB, no
# platform-dependent point fit, no seed sensitivity.
art_stub_engine <- function(n_fail = 99L) {
  list(
    simulate_refit = function(boot_samples, seed = NULL) {
      draws <- matrix(
        NA_real_,
        nrow = 2L,
        ncol = boot_samples,
        dimnames = list(c("subject", "residual"), NULL)
      )
      draws
    }
  )
}

# The rendered text a user really sees, bullets included. `conditionMessage()` on
# an rlang condition carries the body; the message vector alone does not (M93).
# Asserts the SPECIFIC condition class, not just the `intraclass_error` parent.
# AC4 requires each guard to keep the class it signalled, and the parent is shared
# by every abort in the package, so pinning it pinned nothing (review F8/D1): the
# classical guard has no other test of its class anywhere in the suite.
art_message <- function(expr, class = "intraclass_singular_fit") {
  cnd <- tryCatch(expr, error = function(e) e)
  expect_s3_class(cnd, class)
  conditionMessage(cnd)
}

# The property, stated once: does this text send the user to a `ci_method`?
art_named_methods <- function(text) {
  hits <- regmatches(text, gregexpr('ci_method\\s*=\\s*"[a-z]+"', text))[[1]]
  sort(unique(gsub('.*"([a-z]+)".*', "\\1", hits)))
}

test_that("the de-named aborts still fire, classed, with their leading line", {
  # AC4: this milestone changed remedy bullets and nothing else. If a rewrite had
  # drifted into the class or the leading sentence, the abort would have become a
  # different abort, and every downstream handler keyed on it would be wrong.
  boot <- art_message(bootstrap_ci(
    art_stub_engine(),
    art_ests(),
    conf_level = 0.95,
    boot_samples = 99L
  ))
  expect_match(boot, "only .*0.* of .*99.* refits converged", perl = TRUE)

  classical <- art_message(searle_ci(art_mse0(), art_ests(), conf_level = 0.95))
  expect_match(classical, "interval is undefined for this data", fixed = TRUE)

  npb <- art_message(npbootstrap_ci(
    art_mse0(),
    art_ests(),
    conf_level = 0.95,
    boot_samples = 49L,
    seed = 1L
  ))
  expect_match(npb, "interval is undefined for this data", fixed = TRUE)
})

test_that("aborts on degenerate data name no ci_method as a remedy", {
  # THE criterion. Asserted as the property ("names no method") rather than as the
  # sentence, so rewording the guidance is free and re-introducing a method name
  # is not -- which is the way round that matters. The three sites were measured
  # to have NO usable alternative across their trigger classes, so any name here
  # would be a claim the evidence does not support.
  cases <- list(
    bootstrap = art_message(bootstrap_ci(
      art_stub_engine(),
      art_ests(),
      conf_level = 0.95,
      boot_samples = 99L
    )),
    classical_mse0 = art_message(
      searle_ci(art_mse0(), art_ests(), conf_level = 0.95)
    ),
    npbootstrap_mse0 = art_message(npbootstrap_ci(
      art_mse0(),
      art_ests(),
      conf_level = 0.95,
      boot_samples = 49L,
      seed = 1L
    )),
    npbootstrap_ssa0 = art_message(npbootstrap_ci(
      art_ssa0(),
      art_ests(),
      conf_level = 0.95,
      boot_samples = 49L,
      seed = 1L
    ))
  )
  for (nm in names(cases)) {
    expect_identical(art_named_methods(cases[[nm]]), character(0), info = nm)
  }
})

test_that("the de-named aborts still tell the user what to do", {
  # Naming no method must not degrade into naming nothing: #8 asks for an
  # actionable message, and GP1 puts the applied reader first. Each rewritten
  # bullet directs the user at something they can go and look at.
  #
  # Pinned by the IMPERATIVE alone, not by what follows it. The first draft
  # asserted the literal "Inspect the ratings" and went red the moment the
  # bootstrap bullet correctly became "Inspect the fitted model and the ratings
  # behind it" -- a form pinned where a property was meant (the M68 lesson).
  texts <- c(
    art_message(bootstrap_ci(
      art_stub_engine(),
      art_ests(),
      conf_level = 0.95,
      boot_samples = 99L
    )),
    art_message(searle_ci(art_mse0(), art_ests(), conf_level = 0.95)),
    art_message(npbootstrap_ci(
      art_mse0(),
      art_ests(),
      conf_level = 0.95,
      boot_samples = 49L,
      seed = 1L
    ))
  )
  for (txt in texts) {
    expect_match(txt, "\\bInspect\\b")
  }
})

test_that("the resample guard keeps the remedy the sweep confirmed", {
  # The deliberate asymmetry, pinned so that a later sweep-blind tidy-up cannot
  # strip it as "another one of those". This guard fires on HEALTHY observed data
  # -- only the resamples degenerate -- and the sweep found the Monte-Carlo
  # default usable on every dataset that reached it, so here the name is earned.
  #
  # Few subjects carry within-subject variance, so a whole-subject resample draws
  # a degenerate one (M97's double-code shape). The observed-data guard above
  # passes; this one fires.
  set.seed(1)
  n_s <- 12L
  n_r <- 3L
  score <- rep(stats::rnorm(n_s, 0, 3), each = n_r)
  score[1:n_r] <- score[1:n_r] + stats::rnorm(n_r, 0, 1)
  score[(n_r + 1):(2 * n_r)] <- score[(n_r + 1):(2 * n_r)] +
    stats::rnorm(n_r, 0, 1)
  df <- data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = score
  )
  txt <- art_message(npbootstrap_ci(
    df,
    art_ests(),
    conf_level = 0.95,
    boot_samples = 99L,
    seed = 1L
  ))
  expect_match(txt, "resamples were degenerate", fixed = TRUE)
  expect_identical(art_named_methods(txt), "montecarlo")
})

test_that("the degeneracy guards report values and diagnose nothing", {
  # The property that cost this milestone two review returns. Twice a message
  # asserted a fact about the user's data -- which degeneracy had occurred -- and
  # twice it was false in a corner the author had not thought of (review A1: the
  # guard has a third cause needing no degenerate variance; review F2: NaN from
  # overflow read as NaN from 0/0). The maintainer's disposition was to stop
  # diagnosing: print the quantities the guard actually tested, which cannot be
  # false because they ARE the test.
  #
  # So this asserts the ABSENCE of a diagnosis, over inputs that hit different
  # causes. A future author who reintroduces a cause sentence reds this, whatever
  # the sentence says, because the pattern is what it claims to know.
  diagnosis <- "variance is exactly zero|every rater gave each subject|every subject has the same mean"

  cases <- list(
    npb_se_zero = art_message(npbootstrap_ci(
      art_se_zero(),
      art_ests(2),
      conf_level = 0.95,
      boot_samples = 49L,
      seed = 1L
    )),
    npb_ssa0 = art_message(npbootstrap_ci(
      art_ssa0(),
      art_ests(),
      conf_level = 0.95,
      boot_samples = 49L,
      seed = 1L
    )),
    npb_mse0 = art_message(npbootstrap_ci(
      art_mse0(),
      art_ests(),
      conf_level = 0.95,
      boot_samples = 49L,
      seed = 1L
    )),
    classical_mse0 = art_message(
      searle_ci(art_mse0(), art_ests(), conf_level = 0.95)
    ),
    classical_nan = art_message(
      searle_ci(art_nan_mse(), art_ests(), conf_level = 0.95)
    )
  )
  for (nm in names(cases)) {
    expect_no_match(cases[[nm]], diagnosis, info = nm)
  }

  # ...and each does report the quantities it tested, so refusing to diagnose has
  # not left the user with nothing (#8, GP1).
  for (nm in c("npb_se_zero", "npb_ssa0", "npb_mse0")) {
    expect_match(cases[[nm]], "log F = ", fixed = TRUE, info = nm)
    expect_match(cases[[nm]], "standard error = ", fixed = TRUE, info = nm)
  }
  for (nm in c("classical_mse0", "classical_nan")) {
    expect_match(cases[[nm]], "MSA = ", fixed = TRUE, info = nm)
    expect_match(cases[[nm]], "MSE = ", fixed = TRUE, info = nm)
  }
})

test_that("a NaN mean square still aborts classed, not with a bare R error", {
  # Review finding F1: M100's own first repair branched a second time on
  # `ss$mse == 0`, which is NA when MSE is NaN, so `if (NA)` killed the guard with
  # an unclassed simpleError where `main` had raised a classed abort -- a #5/#8
  # regression introduced by a truthfulness fix. One `Inf` score reaches it.
  cnd <- tryCatch(
    searle_ci(art_nan_mse(), art_ests(), conf_level = 0.95),
    error = function(e) e
  )
  expect_s3_class(cnd, "intraclass_singular_fit")
  expect_false(inherits(cnd, "simpleError"))
})

test_that("the SE-zero guard still names no ci_method", {
  # AC3 over the branch the sweep never generated. Its own case, because the
  # earlier no-method test only covered branches the sweep had exercised.
  txt <- art_message(npbootstrap_ci(
    art_se_zero(),
    art_ests(2),
    conf_level = 0.95,
    boot_samples = 49L,
    seed = 1L
  ))
  expect_identical(art_named_methods(txt), character(0))
  expect_match(txt, "[Ii]nspect the ratings")
})

test_that("the bootstrap convergence guard asserts no single cause", {
  # Review finding A2: the guard fires on a refit COUNT, which no one data fact
  # entails -- the milestone's own sweep reached it on jittered cells where
  # subjects are not identical. So the message must not claim they are.
  txt <- art_message(bootstrap_ci(
    art_stub_engine(),
    art_ests(),
    conf_level = 0.95,
    boot_samples = 99L
  ))
  expect_no_match(txt, "scored identically")
  # ...and must not describe the PARAMETRIC bootstrap as resampling ratings.
  expect_no_match(txt, "to resample\\.")
  expect_match(txt, "near a variance boundary", fixed = TRUE)
})
