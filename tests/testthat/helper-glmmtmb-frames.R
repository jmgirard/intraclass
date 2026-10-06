# A 17-subject, 2-rater, complete two-way frame on a score scale near 1 -- the
# shape of the user report behind PR #176 and M158. Shared by
# test-glmmtmb-start-scale.R and test-glmmtmb-false-zero.R.
scale_two_way <- function(seed = 11L, n_s = 17L, n_r = 2L) {
  set.seed(seed)
  grid <- expand.grid(
    subject = factor(seq_len(n_s)),
    rater = factor(letters[seq_len(n_r)])
  )
  subj <- stats::rnorm(n_s, 0, 0.65)
  rater <- seq(-0.3, 0.3, length.out = n_r)
  grid$score <- 6 +
    subj[as.integer(grid$subject)] +
    rater[as.integer(grid$rater)] +
    stats::rnorm(nrow(grid), 0, 0.9)
  grid
}
