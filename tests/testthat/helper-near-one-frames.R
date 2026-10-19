# Frames whose glmmTMB and lme4 intervals lie near 1 (D-054, D-056). Shared by
# test-unresolved-interval.R, which reads them through icc(), and
# test-dstudy-band-checks.R, which reads them through d_study() (D-058). Each
# entry holds the data, the extra icc() arguments, and the rater count `k`.

ui_frames <- function() {
  # M161's near-flat frame: each score its subject's index, 1e-12 added to one.
  near_flat <- expand.grid(rater = 1:3, subject = 1:10)
  near_flat <- data.frame(
    subject = factor(near_flat$subject),
    rater = factor(near_flat$rater),
    score = as.numeric(near_flat$subject)
  )
  near_flat$score[1] <- near_flat$score[1] + 1e-12
  # The exactly additive frame of test-zero-residual.R, 3 subjects, 2 raters.
  g <- expand.grid(subject = 1:3, rater = 1:2)
  additive <- data.frame(
    subject = factor(g$subject),
    rater = factor(g$rater),
    score = seq(0, 1, length.out = 2)[g$rater] +
      round(2 * sin(1:3), 3)[g$subject]
  )
  # Rater noise with SD 1e-7 of a unit score spread.
  noisy <- with_rng_seed(1, {
    g <- expand.grid(subject = factor(1:20), rater = factor(1:3))
    g$score <- stats::rnorm(20)[g$subject] + stats::rnorm(nrow(g), 0, 1e-7)
    g
  })
  list(
    near_flat = list(data = near_flat, args = list(model = "oneway"), k = 3),
    additive = list(data = additive, args = list(model = "twoway"), k = 2),
    noisy = list(data = noisy, args = list(model = "twoway"), k = 3)
  )
}

# Two frames the engines resolve: rater noise SD 1e-6, and the same noise on 2
# occasions per cell. At the settings of `ui_icc()` in
# test-unresolved-interval.R, no row lies within 1e-12/d of 1, and on some
# calls an average row lies within 1e-12 of 1: every call on the first frame,
# glmmTMB bootstrap on the second (D-056, M164 work log).
ui_frames_resolved <- function() {
  noisy6 <- with_rng_seed(1, {
    g <- expand.grid(subject = factor(1:20), rater = factor(1:3))
    g$score <- stats::rnorm(20)[g$subject] + stats::rnorm(nrow(g), 0, 1e-6)
    g
  })
  replicated6 <- with_rng_seed(1, {
    g <- expand.grid(
      subject = factor(1:20),
      rater = factor(1:3),
      occasion = 1:2
    )
    g$score <- stats::rnorm(20)[g$subject] + stats::rnorm(nrow(g), 0, 1e-6)
    g
  })
  list(
    noisy6 = list(data = noisy6, args = list(model = "twoway"), k = 3),
    replicated6 = list(
      data = replicated6,
      args = list(occasions = c("single", "average")),
      k = 3
    )
  )
}
