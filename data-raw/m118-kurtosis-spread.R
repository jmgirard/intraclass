# M118 -- the seeded measurement behind two things that would otherwise be
# free-standing hand-written figures:
#
#   1. the per-family sample-kurtosis spreads quoted in the M118 work log and in
#      tests/testthat/test-m118-family-kurtosis.R's header, which are the whole
#      justification for pinning a tolerance on three families and not on four;
#   2. the claim that the powexp tolerance is load-bearing -- that a wrong
#      `pe_beta` survives every OTHER leg of that test.
#
# Both are re-derived here rather than asserted from memory. The generator
# definitions come from the test file (sourced with `test_that` stubbed), so
# there is one definition of `m118_defs`/`excess_kurtosis` and this script cannot
# drift from what the suite runs.
#
# Run: Rscript data-raw/m118-kurtosis-spread.R

stopifnot("run this from the repo root" = file.exists("DESCRIPTION"))

test_file_path <- "tests/testthat/test-m118-family-kurtosis.R"
sweep_path <- "data-raw/m118-width-reversal-sweep.R"

env <- new.env(parent = globalenv())
env$test_that <- function(...) invisible(NULL)
sys.source(test_file_path, envir = env, keep.source = FALSE)
m118_defs <- get("m118_defs", envir = env)
excess_kurtosis <- get("excess_kurtosis", envir = env)

defs <- m118_defs(sweep_path)
printed <- defs$table2_kurtosis
n_draw <- 1e6L
seeds <- 1:8

# --- 1. per-family spread -----------------------------------------------------
cat("Sample excess kurtosis over", length(seeds), "seeds at", n_draw, "draws\n")
cat(sprintf(
  "%-9s %8s %9s %9s %8s\n",
  "family",
  "printed",
  "min",
  "max",
  "spread"
))

spreads <- numeric(0)
for (fam in names(printed)[order(printed)]) {
  vals <- vapply(
    seeds,
    function(s) {
      set.seed(s)
      excess_kurtosis(defs$draw_standard(n_draw, fam))
    },
    numeric(1)
  )
  spreads[fam] <- max(vals) - min(vals)
  cat(sprintf(
    "%-9s %8.2f %9.3f %9.3f %8.3f\n",
    fam,
    printed[[fam]],
    min(vals),
    max(vals),
    spreads[fam]
  ))
}

# The three families the test pins must be the three whose spread supports a
# 0.02 tolerance, and the four it does not pin must be the ones that do not.
# Stated as a rule over the measurement rather than as a remembered list, so a
# family changing behaviour reds here instead of silently invalidating the test's
# choice of which three to pin.
pinned <- c("uniform", "powexp", "gaussian")
stopifnot(
  "a pinned family's spread no longer supports the 0.02 tolerance" = all(
    spreads[pinned] < 0.02
  ),
  "an unpinned family's spread is now tight enough that it should be pinned" = all(
    spreads[setdiff(names(spreads), pinned)] > 0.02
  )
)

# --- 2. the powexp tolerance is load-bearing ----------------------------------
# A wrong beta survives the closed-form leg (it recomputes from the same
# constant) and the variance leg (powexp alone derives its divisor from that
# constant). Show that it also survives the ORDERING leg, and that only the
# per-family tolerance catches it -- which is what the acceptance criterion
# claims and what would otherwise be an untested assertion.
cat("\nA wrong pe_beta, against each leg of the kurtosis test\n")
cat(sprintf(
  "%-8s %10s %10s %14s %12s\n",
  "beta",
  "kurtosis",
  "variance",
  "order intact?",
  "|k-(-0.5)|"
))

draw_powexp <- function(m, b) {
  g <- stats::rgamma(m, shape = 1 / b, rate = 1)
  sgn <- sample(c(-1, 1), m, replace = TRUE)
  sgn * g^(1 / b) / sqrt(gamma(3 / b) / gamma(1 / b))
}

neighbours <- c(uniform = -1.2, gaussian = 0.0)
caught <- logical(0)
for (b in c(2.2, 2.5, 2.78, 3.0, 3.4)) {
  set.seed(118L)
  x <- draw_powexp(n_draw, b)
  k <- excess_kurtosis(x)
  v <- stats::var(x)
  in_bracket <- k > neighbours[["uniform"]] && k < neighbours[["gaussian"]]
  gap <- abs(k - printed[["powexp"]])
  caught[as.character(b)] <- gap >= 0.02
  cat(sprintf(
    "%-8.2f %10.3f %10.4f %14s %12.3f\n",
    b,
    k,
    v,
    if (in_bracket) "yes (missed)" else "no (caught)",
    gap
  ))
}

# every wrong beta must be caught by the tolerance, and the true one must not be
stopifnot(
  "a wrong pe_beta is not caught by the 0.02 tolerance" = all(caught[
    names(caught) != "2.78"
  ]),
  "the true pe_beta is rejected by the 0.02 tolerance" = !caught[["2.78"]]
)

cat("\nOK: spreads support the pinned/unpinned split, and the 0.02 powexp\n")
cat("tolerance catches every wrong beta tried while accepting 2.78.\n")
