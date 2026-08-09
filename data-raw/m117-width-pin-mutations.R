# Mutation harness for the width pins in m116-classical-width-comparison.R.
#
# A `stopifnot` pin is worthless until something has been shown to trip it, and
# "I perturbed a number and it reddened" is only evidence about the number that
# was perturbed. This script runs the generator's whole pin block under a
# masked `stopifnot` that RECORDS rather than aborts, once per mutation, so a
# single run reports which pins each mutation trips and which pins nothing
# trips at all.
#
# Run: Rscript data-raw/m117-width-pin-mutations.R
# It writes nothing. The generator's own output-writing tail is cut off before
# evaluation, so this cannot overwrite the committed .tsv or the fixture.
#
# The control mutation is the unmutated tree: it must trip NOTHING. A harness
# whose control reds is measuring its own breakage, not the pins.

generator <- "data-raw/m116-classical-width-comparison.R"
src <- readLines(generator, warn = FALSE)

# Everything from the output header onward writes files; the pins are all above
# it. Anchored on the assignment, which occurs once.
cut <- grep("^header <- c\\($", src)
stopifnot(
  "generator layout changed -- no unique `header <- c(` line" = length(
    cut
  ) ==
    1L
)
body <- src[seq_len(cut - 1L)]

# The mutation is injected immediately after `cells` is built, so every pin and
# every summary downstream sees the perturbed data.
inject_at <- grep("^cells <- rbind\\($", body)
stopifnot(
  "generator layout changed -- no unique `cells <- rbind(` line" = length(
    inject_at
  ) ==
    1L
)
close_at <- inject_at + which(body[seq(inject_at, length(body))] == ")")[1] - 1L

# Each mutation is an expression evaluated with `cells` in scope, returning the
# mutated `cells`. Every one is chosen to move a figure a doc surface states.
mutations <- list(
  control = quote(cells),
  # The 5-rater k = 10 median the article's subject-count table quotes. Moving
  # the whole n = 5 / k = 10 block moves that median and nothing else.
  k_at_n5_10 = quote({
    i <- cells$grid == "m113" & cells$k == 10 & cells$n == 5
    cells$ratio[i] <- cells$ratio[i] + 0.02
    cells
  }),
  k_at_n5_50 = quote({
    i <- cells$grid == "m113" & cells$k == 50 & cells$n == 5
    cells$ratio[i] <- cells$ratio[i] - 0.02
    cells
  }),
  m76_k_at_n5_10 = quote({
    i <- cells$grid == "m76" & cells$k == 10 & cells$n == 5
    cells$ratio[i] <- cells$ratio[i] + 0.03
    cells
  }),
  m76_k_at_n5_30_50 = quote({
    i <- cells$grid == "m76" & cells$k %in% c(30, 50) & cells$n == 5
    cells$ratio[i] <- cells$ratio[i] - 0.015
    cells
  }),
  # A two-rater cell appearing away from k = 10, which is the design change
  # that would make the marginal and stratified k = 30 rows diverge -- and, if
  # it happened at every subject count, would retire the stratification.
  n2_at_k30 = quote({
    donor <- cells[cells$grid == "m113" & cells$k == 30 & cells$n == 5, ][1, ]
    donor$n <- 2
    donor$ratio <- donor$ratio - 0.05
    donor$burch_narrower <- donor$ratio < 1
    rbind(cells, donor)
  }),
  # Collapse the confounding: give the n = 2 cells the same ratios as their
  # n = 5 siblings, so the marginal and stratified k = 10 medians coincide and
  # the marginal rows become statable. The stratification pin must red.
  confound_removed = quote({
    for (g in c("m76", "m113")) {
      i <- cells$grid == g & cells$k == 10 & cells$n == 2
      j <- cells$grid == g & cells$k == 10 & cells$n == 5
      cells$ratio[i] <- stats::median(cells$ratio[j])
    }
    cells
  }),
  # Make the sub-0.6 rho medians monotone decreasing in the ratio, i.e. make
  # "the advantage shrinks as the true ICC grows" TRUE. The flat-shape pins
  # must red -- they are the ones standing between the docs and the claim that
  # shipped for three milestones.
  rho_made_monotone = quote({
    cells$ratio[cells$grid == "m113" & cells$rho == 0.05] <- cells$ratio[
      cells$grid == "m113" & cells$rho == 0.05
    ] -
      0.02
    cells$ratio[cells$grid == "m113" & cells$rho == 0.3] <- cells$ratio[
      cells$grid == "m113" & cells$rho == 0.3
    ] +
      0.02
    cells
  }),
  # Direction reversal at rho = 0.6 that stays inside the pre-existing rounding
  # bucket: 0.9971 -> 1.0049. The M117 exact pin and the direction pin must
  # both red; the bucket idiom alone does not see it.
  rho_06_reversed = quote({
    i <- cells$grid == "m113" & cells$rho == 0.6
    cells$ratio[i] <- cells$ratio[i] + 0.0078
    cells$burch_narrower[i] <- cells$ratio[i] < 1
    cells
  }),
  # A reversing cell moved off rho = 0.6, falsifying "every cell where searle
  # came out narrower sits at 0.6".
  reversal_off_06 = quote({
    i <- which(cells$grid == "m113" & cells$rho == 0.3)[1]
    cells$ratio[i] <- 1.01
    cells$burch_narrower[i] <- FALSE
    cells
  }),
  # A narrower-count the article's tables quote, moved without moving a median.
  narrower_count = quote({
    i <- which(
      cells$grid == "m113" & cells$k == 50 & cells$n == 5 & cells$burch_narrower
    )[1]
    cells$burch_narrower[i] <- FALSE
    cells
  }),
  # The subject-count direction itself, on the stratified cut only.
  k_direction = quote({
    i <- cells$grid == "m113" & cells$k == 50 & cells$n == 5
    cells$ratio[i] <- cells$ratio[i] - 0.08
    cells
  })
)

run_one <- function(mutation) {
  tripped <- character(0)
  env <- new.env(parent = globalenv())
  # Masked `stopifnot`: records the label of every failing condition instead of
  # aborting, so one run reports EVERY pin a mutation trips rather than the
  # first.
  env$stopifnot <- function(...) {
    args <- list(...)
    labs <- names(args)
    for (i in seq_along(args)) {
      ok <- isTRUE(all(args[[i]]))
      if (!ok) {
        lab <- if (!is.null(labs) && nzchar(labs[i])) {
          labs[i]
        } else {
          "(unlabelled)"
        }
        tripped <<- c(tripped, lab)
      }
    }
    invisible(NULL)
  }
  code <- c(
    body[seq_len(close_at)],
    "cells <- (function(cells) MUTATION)(cells)",
    body[seq(close_at + 1L, length(body))]
  )
  code <- sub(
    "MUTATION",
    paste(deparse(mutation), collapse = "\n"),
    code,
    fixed = TRUE
  )
  eval(parse(text = paste(code, collapse = "\n")), envir = env)
  unique(tripped)
}

results <- lapply(mutations, run_one)

for (nm in names(results)) {
  cat("\n== ", nm, " -- ", length(results[[nm]]), " pin(s) tripped\n", sep = "")
  for (p in results[[nm]]) {
    cat("   - ", p, "\n", sep = "")
  }
}

control <- results[["control"]]
if (length(control)) {
  stop(
    "the unmutated control tripped pins -- the harness is broken, not the pins"
  )
}

fired <- unique(unlist(results[names(results) != "control"]))
cat(
  "\ndistinct pins reddened across ",
  length(mutations) - 1L,
  " mutations: ",
  length(fired),
  "\n",
  sep = ""
)
