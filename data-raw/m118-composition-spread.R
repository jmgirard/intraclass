# M118 AC2 leg (b) -- the seeded measurement its per-rho tolerances sit on.
#
# The criterion asserts the recovered ICC is within 0.05 of rho at rho = 0.05
# and within 0.10 at rho = 0.25 and 0.50. Those two numbers are load-bearing, so
# they are measured here rather than asserted from memory (#4: a figure is
# pinned to a committed seeded script or it is not a figure).
#
# Two things this prints, and the tolerance has to sit between them:
#   - the LEGITIMATE spread, worst over the seven families, on the real script;
#   - the SEPARATION, worst over families, under each mutation leg (b) rejects.
#
# The rho = 0.05 row is why the tolerances are per-rho and not flat. A flat 0.10
# leaves that cell nearly inert: two of the three mutations land below it there,
# because 0.10 at rho = 0.05 is a +-200% band. It is also why leg (b) runs at
# three rho rather than one -- the component swap is EXACTLY a no-op at
# rho = 0.5, which is the fixed point of rho <-> 1 - rho, so the single-rho
# version of this leg shipped blind to it.
#
# Definitions come from the test file (sourced with `test_that` stubbed), so
# there is one definition of the composition machinery and this script cannot
# drift from what the suite runs (the M117 technique).
#
# Run: Rscript data-raw/m118-composition-spread.R

stopifnot("run this from the repo root" = file.exists("DESCRIPTION"))
suppressMessages(devtools::load_all(quiet = TRUE))

test_file_path <- "tests/testthat/test-m118-both-components-dgp.R"
sweep_path <- "data-raw/m118-width-reversal-sweep.R"

env <- new.env(parent = globalenv())
env$test_that <- function(...) invisible(NULL)
sys.source(test_file_path, envir = env, keep.source = FALSE)
gen_defs <- get("m118_gen_defs", envir = env)
composition_dev <- get("m118_composition_dev", envir = env)
tol <- get("m118_composition_tol", envir = env)

src <- readLines(sweep_path, warn = FALSE)
rhos <- c(0.05, 0.25, 0.5)

mutations <- list(
  "scale error: sd_a <- rho" = c("  sd_a <- sqrt(rho)", "  sd_a <- rho"),
  "component swap" = c(
    "  a <- sd_a * draw_standard(k, dist)",
    "  a <- sd_e * draw_standard(k, dist)"
  ),
  "mis-composition: times = n" = c(
    "  vals <- rep(a, each = n) + e",
    "  vals <- rep(a, times = n) + e"
  )
)

mutate <- function(from, to) {
  hits <- which(src == from)
  if (length(hits) != 1L) {
    stop("anchor matched ", length(hits), " lines; expected exactly 1")
  }
  tmp <- tempfile(fileext = ".R")
  writeLines(append(src[-hits], to, after = hits - 1L), tmp)
  tmp
}

devs <- function(path) {
  e <- gen_defs(path)
  vapply(rhos, function(r) composition_dev(e, r), numeric(1))
}

cat(
  "Worst |icc_hat - rho| over the seven families, k = 400, n = 5, seed 900001\n\n"
)
cat(sprintf("%-28s %10s %10s %10s\n", "", "rho=0.05", "rho=0.25", "rho=0.50"))
cat(sprintf(
  "%-28s %10.3f %10.3f %10.3f\n",
  "tolerance (AC2)",
  tol[["0.05"]],
  tol[["0.25"]],
  tol[["0.5"]]
))
real <- devs(sweep_path)
cat(sprintf(
  "%-28s %10.4f %10.4f %10.4f\n",
  "legitimate (real script)",
  real[1],
  real[2],
  real[3]
))

sep <- list()
for (nm in names(mutations)) {
  tmp <- mutate(mutations[[nm]][1], mutations[[nm]][2])
  sep[[nm]] <- devs(tmp)
  unlink(tmp)
  cat(sprintf(
    "%-28s %10.4f %10.4f %10.4f\n",
    nm,
    sep[[nm]][1],
    sep[[nm]][2],
    sep[[nm]][3]
  ))
}

tolv <- c(tol[["0.05"]], tol[["0.25"]], tol[["0.5"]])

# The property the tolerances must have, asserted rather than eyeballed: the
# real script is inside every one, and each mutation is outside at least one.
stopifnot(
  "the real script exceeds a tolerance" = all(real < tolv),
  "a mutation is inside every tolerance, so no rho catches it" = all(vapply(
    sep,
    function(d) any(d >= tolv),
    logical(1)
  ))
)

caught <- vapply(sep, function(d) sum(d >= tolv), integer(1))
cat("\nmutations caught, by number of rho that catch them:\n")
for (nm in names(caught)) {
  cat(sprintf("  %-28s %d of %d\n", nm, caught[[nm]], length(rhos)))
}
cat(
  "\nOK: the real script clears every tolerance and every mutation is caught\n"
)
cat("by at least one rho.\n")
