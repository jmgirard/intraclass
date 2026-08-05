# M105: what the two classical one-way reducers do on data carrying no
# between-subject variance.
#
# Two instruments over one committed fixture, deliberately different in kind.
#
# The AC3 block derives its per-cell expectation from `msa_exact_zero` -- a fact
# about the DATA -- rather than from a recorded Burch outcome. An expectation
# regenerated alongside the behaviour it checks would pass over any regression,
# which is exactly what a recorded-outcome column would have been.
#
# The AC4 block pins `searle` against endpoints measured on the default branch
# BEFORE this milestone changed any source. Both reducers share
# `npb_guard_sb_pole()`, so a fix aimed at Burch could move SEARLE; this is the
# assertion that would say so. Its values must not be regenerated.
#
# Both are scoped to the eight rows the fixture contains and claim nothing about
# cells outside it; the grid and its exclusions are documented in
# `data-raw/sweep-degenerate-classical.R`.

read_degenerate_cells <- function() {
  path <- test_path("fixtures", "degenerate-classical-cells.tsv")
  cells <- utils::read.delim(path, comment.char = "#", stringsAsFactors = FALSE)
  # `as.numeric()` reads a C99 hex float exactly (the M95 lesson) and the
  # Inf/-Inf/NaN literals by name, so one converter serves every numeric column.
  for (col in c("msa", "mse", "searle_conf_low", "searle_conf_high")) {
    cells[[col]] <- as.numeric(cells[[col]])
  }
  cells
}

# Matches `gen_ssa0()` in `data-raw/sweep-degenerate-classical.R` byte for byte,
# so the rows below describe the same data the fixture recorded.
gen_ssa0_degenerate <- function(n_s, n_r, seed = 1) {
  set.seed(seed)
  profile <- stats::rnorm(n_r, 0, 3)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(profile, times = n_s)
  )
}

test_that("the committed fixture still describes the grid AC3/AC4 assume", {
  cells <- read_degenerate_cells()
  # Anti-vacuity: every assertion below loops the fixture's rows, so a truncated
  # or empty fixture would satisfy all of them silently.
  expect_identical(nrow(cells), 8L)
  expect_setequal(cells$unit, c("single", "average"))
  # Both arms of AC3's rule must be populated, or the rule is only half tested.
  expect_identical(sum(cells$msa_exact_zero), 6L)
  expect_identical(sum(!cells$msa_exact_zero), 2L)
})

test_that("burch either aborts classed or reports finite ordered limits (AC3)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  cells <- read_degenerate_cells()

  for (i in seq_len(nrow(cells))) {
    row <- cells[i, ]
    d <- gen_ssa0_degenerate(row$n_s, row$n_r, row$seed)
    label <- paste0(row$n_s, "x", row$n_r, " unit=", row$unit)
    call_it <- function() {
      icc(
        d,
        score,
        subject,
        rater,
        model = "oneway",
        ci_method = "burch",
        unit = row$unit
      )
    }

    if (row$msa_exact_zero) {
      # kappa-hat is undefined here: `burch_kappa_hat()` divides by sqrt(MSA).
      cnd <- rlang::catch_cnd(call_it(), classes = "error")
      expect_s3_class(cnd, "intraclass_error")
      expect_match(
        cli::format_message(conditionMessage(cnd)),
        "between-subject",
        fixed = TRUE,
        info = label
      )
    } else {
      # MSA is ~3.5e-33 rather than 0, so the Burch construction is defined and
      # the interval it returns is an ordinary near-boundary one.
      tidied <- generics::tidy(call_it())
      expect_true(is.finite(tidied$conf.low[[1L]]), info = label)
      expect_true(is.finite(tidied$conf.high[[1L]]), info = label)
      expect_lte(tidied$conf.low[[1L]], tidied$conf.high[[1L]])
    }
  }
})

test_that("searle reports exactly what it reported before M105 (AC4)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  cells <- read_degenerate_cells()

  for (i in seq_len(nrow(cells))) {
    row <- cells[i, ]
    d <- gen_ssa0_degenerate(row$n_s, row$n_r, row$seed)
    label <- paste0(row$n_s, "x", row$n_r, " unit=", row$unit)
    tidied <- generics::tidy(icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "searle",
      unit = row$unit
    ))
    # Tolerance-0: the baseline is a bit-exact hex float, and anything that moved
    # these endpoints at all is a change this milestone did not intend.
    expect_identical(tidied$conf.low[[1L]], row$searle_conf_low, info = label)
    expect_identical(tidied$conf.high[[1L]], row$searle_conf_high, info = label)
  }
})
