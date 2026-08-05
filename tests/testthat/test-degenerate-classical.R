# M105: what the two classical one-way reducers do on data carrying no
# between-subject variance.
#
# Two instruments over one committed fixture, deliberately different in kind.
#
# The AC3 block derives its per-cell expectation from MSA RECOMPUTED on the
# running platform, never from a recorded Burch outcome and never from the
# fixture's `msa_exact_zero` column. Two distinct traps, both real:
# an expectation regenerated alongside the behaviour it checks would pass over
# any regression; and whether MSA reaches exactly 0 is accumulated summation
# roundoff that DIFFERS BY PLATFORM, so the recorded verdict asserts the
# generating machine's arithmetic everywhere (it failed on Windows CI at M105
# review pass 2). The fixture's column is kept as the generating platform's
# record, for provenance -- nothing derives an expectation from it.
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
  # The abort side must be populated or AC3's rule is only half tested. The floor
  # is SIX of the eight cases, not an exact split, and it is recomputed here
  # rather than read from the fixture's `msa_exact_zero` column -- see the note
  # on that column in `read_degenerate_cells()`'s neighbours below. Six is what
  # both observed platforms clear: macOS/aarch64 puts the 8x4 cell at 3.5e-33
  # (finite side, 6 aborting) and the Windows runner puts it at exactly 0
  # (abort side, 8 aborting).
  exact_zero <- vapply(
    seq_len(nrow(cells)),
    function(i) {
      d <- gen_ssa0_degenerate(cells$n_s[[i]], cells$n_r[[i]], cells$seed[[i]])
      identical(classical_oneway_ss(split(d$score, d$subject))$msa, 0)
    },
    logical(1)
  )
  expect_gte(sum(exact_zero), 6L)
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

    # Recomputed HERE, on the running platform, never read from the fixture's
    # `msa_exact_zero` column. Whether a cell's MSA reaches exactly 0 is
    # accumulated summation roundoff, not a property of the cell: the 8x4 cell is
    # 3.5e-33 on macOS/aarch64 (where the fixture was generated) and exactly 0 on
    # the Windows runner. Reading the recorded verdict made this test assert one
    # machine's arithmetic everywhere, and it failed on Windows CI (M105 review
    # pass 2). The invariant that IS portable is the rule itself.
    msa_exact_zero <- identical(
      classical_oneway_ss(split(d$score, d$subject))$msa,
      0
    )

    if (msa_exact_zero) {
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
