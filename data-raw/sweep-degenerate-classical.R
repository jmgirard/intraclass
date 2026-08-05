# What the two classical one-way `ci_method` reducers report on data with NO
# between-subject variance at all, and which of those cells sit at MSA exactly 0.
#
# WHY THIS EXISTS. `burch_kappa_hat()` (R/ci-classical.R) standardizes the
# kurtosis plug-in by `sqrt(MSA)`. At MSA = 0 that is a division by zero, so
# kappa-hat is NaN and both Burch endpoints follow it. The NaN then reaches
# `npb_guard_sb_pole()`, whose `!any(denom < 0)` is not NaN-safe -- a bare
# `simpleError` at `unit = "average"`, and a silently reported NaN interval at
# `unit = "single"`. M105 replaces both with a classed abort.
#
# MSA = 0 is a floating-point fact, not a design fact: three of the four cells
# below reach it exactly and the fourth lands at ~3.5e-33, where kappa-hat is
# finite and Burch returns an interval. The `msa_exact_zero` column records
# which, and the suite derives its per-cell expectation FROM that column rather
# than from a recorded Burch outcome -- an expectation regenerated alongside the
# behaviour it checks would pass over any regression.
#
# THE SEARLE COLUMNS ARE A BEFORE-BASELINE (M105 AC4). They are measured on the
# default branch BEFORE M105 changes any source, and pin that this milestone
# moves nothing on the sibling reducer that shares the guard. Do NOT regenerate
# them after the change -- that would erase the comparison they exist to make.
#
# Re-run (from the repo root; seconds, no fitting):
#   Rscript data-raw/sweep-degenerate-classical.R
#
# WHAT THE GRID GENERATES, AND WHAT IT DOES NOT. GENERATED: four balanced
# one-way cells whose subjects all carry the identical rater profile, so the
# between-subject sum of squares is zero up to floating point, at both shipped
# `unit` values. NOT GENERATED: unbalanced or incomplete designs; two-way,
# nested or multilevel estimands; any `ci_method` but the two classical ones;
# any non-zero between-subject variance. Nothing here is evidence about those,
# and the assertions reading this fixture are scoped to the rows it contains.

suppressMessages(devtools::load_all(quiet = TRUE))

out_path <- "tests/testthat/fixtures/degenerate-classical-cells.tsv"

# Subjects share one rater profile exactly, so every subject mean is the grand
# mean and SSA is zero up to accumulated floating-point error. Identical to the
# `gen_ssa0` generator M100's abort-remedy sweep used, kept byte-for-byte so the
# two measurements describe the same data.
gen_ssa0 <- function(n_s, n_r, seed = 1) {
  set.seed(seed)
  profile <- stats::rnorm(n_r, 0, 3)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(profile, times = n_s)
  )
}

# A double survives a text round trip through R's own parser only as a C99 hex
# float -- `%.17g` lands 1 ulp off often enough to red a tolerance-0 comparison
# (the M95 lesson). Non-finite values have no hex form, so they are written as
# their own literals and read back by name.
as_exact <- function(x) {
  if (is.na(x) && !is.nan(x)) {
    "NA"
  } else if (is.nan(x)) {
    "NaN"
  } else if (!is.finite(x)) {
    if (x > 0) "Inf" else "-Inf"
  } else {
    sprintf("%a", x)
  }
}

cells <- list(c(6, 3), c(10, 2), c(20, 3), c(8, 4))
units <- c("single", "average")

rows <- list()
for (cell in cells) {
  n_s <- cell[[1]]
  n_r <- cell[[2]]
  d <- gen_ssa0(n_s, n_r)
  ss <- classical_oneway_ss(split(d$score, d$subject))
  for (u in units) {
    fit <- icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "searle",
      unit = u
    )
    tidied <- generics::tidy(fit)
    rows[[length(rows) + 1L]] <- data.frame(
      n_s = n_s,
      n_r = n_r,
      seed = 1L,
      unit = u,
      msa = as_exact(ss$msa),
      msa_exact_zero = identical(ss$msa, 0),
      mse = as_exact(ss$mse),
      searle_conf_low = as_exact(tidied$conf.low[[1L]]),
      searle_conf_high = as_exact(tidied$conf.high[[1L]])
    )
  }
}
tab <- do.call(rbind, rows)

header <- c(
  "# degenerate-classical-cells.tsv -- what the classical one-way reducers meet",
  "# on zero-between-subject-variance data. Source: generated data only, no",
  "# external oracle -- every cell comes from the gen_ssa0 generator in the",
  "# script below. Generator: data-raw/sweep-degenerate-classical.R",
  "# (re-run: Rscript data-raw/sweep-degenerate-classical.R).",
  "# Seeds: every cell is generated at seed = 1; both reducers are deterministic",
  "# and consume no seed of their own.",
  "# msa/mse/searle_* are C99 hex floats (as.numeric() reads them exactly);",
  "# non-finite values are written as Inf/-Inf/NaN literals.",
  "# The searle_* columns are a BEFORE-baseline measured on the default branch",
  "# prior to M105's source changes -- do not regenerate them after the change.",
  "# msa_exact_zero, not a recorded Burch outcome, is what the suite derives its",
  "# per-cell Burch expectation from.",
  "# Do not hand-edit: regenerate with the script above.",
  paste0(
    "# Written by that script under ",
    R.version.string,
    ", ",
    R.version$platform,
    "."
  )
)

con <- file(out_path, open = "wt")
writeLines(header, con)
utils::write.table(
  tab,
  con,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)
close(con)

message("wrote ", out_path, " (", nrow(tab), " rows)")
