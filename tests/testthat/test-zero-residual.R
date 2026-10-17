# Two-way data whose residual is exactly zero (D-053) --------------------------
#
# Scores that vary only by rater, or that are exactly a subject value plus a
# rater value, leave the residual variance at zero while scores still vary
# within subjects, so D-052's input check does not refuse them. On such data
# the glmmTMB and lme4 engines raised their own errors, which carry no package
# class. icc() now re-raises those as `intraclass_singular_fit`. Each call of
# the grid must return a result or abort with that class.

zr_frame <- function(n, k, shape) {
  d <- expand.grid(subject = seq_len(n), rater = seq_len(k))
  rater_value <- seq(0, 1, length.out = k)[d$rater]
  # Fixed subject values with no RNG, distinct for every n used here.
  subject_value <- round(2 * sin(seq_len(n)), 3)[d$subject]
  data.frame(
    subject = factor(d$subject),
    rater = factor(d$rater),
    score = rater_value + if (shape == "additive") subject_value else 0
  )
}

zr_grid <- function() {
  expand.grid(
    n = c(3L, 5L, 12L),
    k = c(2L, 3L, 5L),
    shape = c("rater", "additive"),
    engine = c("glmmTMB", "lme4"),
    ci_method = c("montecarlo", "bootstrap"),
    stringsAsFactors = FALSE
  )
}

# The outcome of one call: "result", the class vector of an error, or NULL when
# the call neither returned a result nor raised an error.
zr_outcome <- function(row) {
  d <- zr_frame(row$n, row$k, row$shape)
  res <- tryCatch(
    suppressWarnings(suppressMessages(icc(
      d,
      score = score,
      subject = subject,
      rater = rater,
      engine = row$engine,
      ci_method = row$ci_method,
      mc_samples = 500L,
      boot_samples = 30L,
      seed = 1
    ))),
    error = function(e) e
  )
  if (inherits(res, "intraclass_icc")) {
    "result"
  } else if (inherits(res, "error")) {
    res
  } else {
    NULL
  }
}

test_that("zero-residual two-way data return a result or a classed singular-fit abort (AC1)", {
  skip_on_cran()
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  grid <- zr_grid()
  expect_identical(nrow(grid), 72L)
  bad <- character(0)
  n_abort <- 0L
  for (i in seq_len(nrow(grid))) {
    row <- grid[i, ]
    out <- zr_outcome(row)
    label <- sprintf(
      "n=%d k=%d %s %s %s",
      row$n,
      row$k,
      row$shape,
      row$engine,
      row$ci_method
    )
    if (identical(out, "result")) {
      next
    }
    if (inherits(out, "intraclass_singular_fit")) {
      n_abort <- n_abort + 1L
      next
    }
    if (is.null(out)) {
      bad <- c(bad, paste0(label, ": no result and no error"))
      next
    }
    bad <- c(
      bad,
      sprintf(
        "%s: <%s> %s",
        label,
        paste(class(out), collapse = "/"),
        conditionMessage(out)
      )
    )
  }
  expect(
    length(bad) == 0L,
    paste(c("Unclassed outcomes:", bad), collapse = "\n")
  )
  # The grid reaches the degenerate path, so the check above is not vacuous.
  expect_gt(n_abort, 0L)
})
