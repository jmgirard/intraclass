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
  # M76 given a design point M113 lacks: the containment the docs' "derived
  # from the larger grid alone" choice rests on.
  containment_broken = quote({
    # A design point M113 does not carry at all -- copying an existing M113
    # combination into M76 leaves the containment intact, which is how the
    # first attempt at this mutation reddened nothing.
    donor <- cells[cells$grid == "m113" & cells$rho == 0.6, ][1, ]
    donor$grid <- "m76"
    donor$k <- 99L
    rbind(cells, donor)
  }),
  # M113 cut back to M76's design points, so the containment is no longer
  # strict and the larger grid carries nothing the smaller lacks.
  containment_equal = quote({
    keep <- !(cells$grid == "m113" & cells$rho %in% c(0.3, 0.6))
    cells[keep, ]
  }),
  # A level removed outright: `lvl()` finds no row, which must trip its own
  # guard rather than silently returning an empty frame.
  level_removed = quote(cells[!(cells$grid == "m113" & cells$rho == 0.3), ]),
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
      # A zero-length condition is vacuous, never satisfied: `all(logical(0))`
      # is TRUE, so a mutation removing a level would otherwise silence every
      # downstream pin that indexes into it instead of tripping them.
      ok <- length(args[[i]]) > 0L && isTRUE(all(args[[i]]))
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

# Coverage, asserted rather than eyeballed. Printing which pins fired says
# nothing about the ones that fired on NOTHING -- three M117 pins sat
# unexercised through a whole review because the harness only printed. A pin
# absent from `fired` now fails here unless it is explicitly exempted, so a
# newly added pin cannot arrive dead.
#
# The exemptions are M116's input fences: they guard the SOURCES this script
# reads (the sweep scripts' DGP, the grids' abort rates, the run directory),
# which no perturbation of the derived `cells` frame can reach.
exempt <- c(
  "run this from the repo root",
  "subject effect does not branch on dist",
  "the error term uses a non-rnorm generator",
  "the error term draws no random numbers at all",
  "a random draw happens outside the subject effect and the error term",
  "M76: a classical leg aborts",
  "M113: a classical leg aborts",
  "cell is not exactly one searle + one burch",
  "M76 all-cell count moved",
  "M76 narrower count moved",
  "M76 gaussian count moved",
  "a family's median ratio is not below 1"
)
labels <- unique(sub(
  '^"',
  "",
  sub(
    '" = $',
    "",
    regmatches(
      paste(src, collapse = "\n"),
      gregexpr('"[^"]{15,}" = ', paste(src, collapse = "\n"))
    )[[1]]
  )
))
dead <- setdiff(setdiff(labels, fired), exempt)
if (length(dead)) {
  stop(
    "pin(s) reddened by no mutation and not exempt:\n  ",
    paste(dead, collapse = "\n  ")
  )
}
cat("every non-exempt pin fired; ", length(exempt), " exempt\n", sep = "")

# ==== prose-mutation leg (M117 re-cut, T18) ===================================
#
# Each mutation below patches ONE swept surface's text (the article) and the
# canonical-shape scan must refuse something it did not refuse unmutated. The
# scan run here is the suite's own: the test file is sourced with `test_that`
# stubbed, so the helpers exercised are the single definitions the tests use —
# a duplicated scanner would drift from the one it claims to exercise.
#
# CLASS LIST — each mutation names the review-return defeat it encodes:
#   r1_swap_rho_figure      return #1: real figure stated against the wrong
#                           level (association, rho table)
#   r1_swap_k_figure        return #1: same, subject-count table
#   r1_pooled_no_method     return #1/#2: grid-wide pooled ratio in a sentence
#                           naming no method — running-prose placement (AC4)
#   r2_count_swap           return #2: narrower-count swapped ("59 of 64")
#   r2_family_count         return #2: distribution-family count swapped
#   r3_pooled_before_table  return #3: pooled ratio BEFORE a surface's first
#                           table pipe (the placement that still reddened)
#   r3_pooled_between_tables return #3: pooled ratio BETWEEN two tables — the
#                           placement `width_strip_tables()` erased
#   r3_spelled_qualifier    return #3: spelled cardinal with intervening
#                           qualifiers before a measure noun
#   r3_malformed_row        return #3: ratio-bearing table row the row regex
#                           rejects
#   r3_unknown_header       return #3: data table under an unrecognized header
#   pooled_pct              AC4 form axis: pooled figure as a percentage — the
#                           ancestral M116 defect form
#   pooled_pct_spelled      AC4 form axis: spelled percentage
#   smaller_grid_pooled     AC4 grid axis: the smaller grid's pooled median
#   template_reversed       return #2: directional template reversed
#   hedge_dropped           return #2: one-grid hedge dropped from the parity
#                           template
#
# NOT probed, disclosed (the narrowed AC2 promise — see the claimed-classes
# header in the test file): figures equal to an allowlisted value, spelled
# forms beyond the cardinal net, figures in sentences with no width
# vocabulary, cell-shaped fragments between pipes.

prose_env <- new.env(parent = globalenv())
prose_env$test_that <- function(...) invisible(NULL)
sys.source(
  "tests/testthat/test-doc-skew-caveat.R",
  envir = prose_env,
  keep.source = FALSE
)

article_path <- "vignettes/interval-methods.Rmd"
article <- readLines(article_path, warn = FALSE)

# One verdict for one surface state: every refusal the suite's scans would
# emit for these lines.
prose_scan <- function(lines) {
  e <- prose_env
  text <- e$squash(lines)
  w <- e$width_fixture()
  shapes <- e$width_canonical_shapes(w)
  fails <- character(0)
  for (run in e$width_neighbourhood(text)) {
    run_text <- paste(run, collapse = " ")
    found <- e$width_unchecked_figures(run_text, shapes)
    for (cl in found$claims) {
      if (!cl$ok) {
        fails <- c(fails, paste0("figure: ", cl$text))
      }
    }
    fails <- c(
      fails,
      if (length(found$spelled)) paste0("spelled: ", found$spelled),
      if (length(found$numerals)) paste0("numeral: ", found$numerals)
    )
    if (e$width_asserts_margin(run)) {
      tmpl <- e$width_templates(w)
      for (tm in names(tmpl)) {
        if (!grepl(tmpl[[tm]], run_text, fixed = TRUE)) {
          fails <- c(fails, paste0("template-missing: ", tm))
        }
      }
    }
  }
  loose <- e$width_loose_ratios(text, shapes)
  if (length(loose)) {
    fails <- c(fails, paste0("loose-ratio: ", loose))
  }
  pct <- e$width_pct_violations(text)$bad
  if (length(pct)) {
    fails <- c(fails, paste0("pct: ", substr(pct, 1, 60)))
  }
  claims <- e$width_table_claims(lines)
  orph <- attr(claims, "orphans")
  if (length(orph)) {
    fails <- c(fails, paste0("orphan-row: ", orph))
  }
  for (cl in claims) {
    med <- e$width_level_medians(w, "m113", cl$factor)
    cnt <- e$width_level_counts(w, "m113", cl$factor)
    i <- which(abs(as.numeric(names(med)) - cl$level) < 1e-9)
    ok <- length(i) == 1L &&
      abs(cl$ratio - med[[i]]) < 1e-9 &&
      cl$narrower == cnt[[i]][["narrower"]] &&
      cl$cells == cnt[[i]][["cells"]]
    if (!ok) {
      fails <- c(fails, paste0("table-row: ", cl$factor, " = ", cl$level))
    }
  }
  fails
}

# `sub_must` / `insert_after` assert the patch landed: a mutation whose anchor
# has drifted must fail loudly, never scan the unmutated text (the stale-anchor
# trap the fixture leg guards with its layout stopifnots).
sub_must <- function(lines, from, to) {
  hit <- grep(from, lines, fixed = TRUE)
  stopifnot("prose-mutation anchor not found" = length(hit) >= 1L)
  lines[hit[1]] <- sub(from, to, lines[hit[1]], fixed = TRUE)
  lines
}
insert_after <- function(lines, anchor, new) {
  hit <- grep(anchor, lines, fixed = TRUE)
  stopifnot("prose-mutation anchor not found" = length(hit) >= 1L)
  append(lines, c("", new, ""), after = hit[1])
}
strip_must <- function(lines, from) {
  sub_must(lines, from, "")
}

pooled_sentence <- "The pooled median width ratio is 0.9614."

prose_mutations <- list(
  r1_swap_rho_figure = function(l) {
    sub_must(l, "| 0.6 | 0.9971 | 11 of 16 |", "| 0.6 | 0.9769 | 11 of 16 |")
  },
  r1_swap_k_figure = function(l) {
    sub_must(l, "| 10 | 0.9154 | 15 of 16 |", "| 10 | 0.9646 | 15 of 16 |")
  },
  r1_pooled_no_method = function(l) {
    insert_after(l, "A pooled figure over both grids", pooled_sentence)
  },
  r2_count_swap = function(l) {
    sub_must(l, "59 of 64 cells", "61 of 64 cells")
  },
  r2_family_count = function(l) {
    sub_must(l, "spanning four", "spanning six")
  },
  r3_pooled_before_table = function(l) {
    insert_after(l, "**Which is the tighter interval?**", pooled_sentence)
  },
  r3_pooled_between_tables = function(l) {
    insert_after(l, "| 0.6 | 0.9971 | 11 of 16 |", pooled_sentence)
  },
  r3_spelled_qualifier = function(l) {
    insert_after(
      l,
      "of the larger grid, but how much narrower depends",
      "That margin holds across four further subject levels."
    )
  },
  r3_malformed_row = function(l) {
    insert_after(l, "| 0.3 | 0.9475 | 16 of 16 |", "| 0.15 | 0.9999 ")
  },
  r3_unknown_header = function(l) {
    insert_after(
      l,
      "| 50 | 0.9769 | 13 of 16 |",
      c("| rho | ratio |", "|---:|---:|", "| 0.15 | 0.9999 |")
    )
  },
  pooled_pct = function(l) {
    insert_after(
      l,
      "A pooled figure over both grids",
      "Overall, `\"burch\"` is about 5% narrower."
    )
  },
  pooled_pct_spelled = function(l) {
    insert_after(
      l,
      "A pooled figure over both grids",
      "It is narrower by about four percent overall."
    )
  },
  smaller_grid_pooled = function(l) {
    insert_after(
      l,
      "A pooled figure over both grids",
      paste(
        "Across the smaller grid the pooled median width ratio is",
        "0.9440."
      )
    )
  },
  template_reversed = function(l) {
    sub_must(
      l,
      "collapses to near parity at a true ICC of 0.6",
      "grows far past parity at a true ICC of 0.6"
    )
  },
  hedge_dropped = function(l) {
    strip_must(l, ", on the one grid reaching that")
  }
)

control_fails <- prose_scan(article)
if (length(control_fails)) {
  stop(
    "the unmutated article already fails the prose scan -- fix that first:\n  ",
    paste(control_fails, collapse = "\n  ")
  )
}

cat("\n==== prose-mutation leg ====\n")
prose_dead <- character(0)
for (nm in names(prose_mutations)) {
  fails <- prose_scan(prose_mutations[[nm]](article))
  cat("\n== ", nm, " -- ", length(fails), " refusal(s)\n", sep = "")
  for (f in fails) {
    cat("   - ", substr(f, 1, 100), "\n", sep = "")
  }
  if (!length(fails)) {
    prose_dead <- c(prose_dead, nm)
  }
}
# Coverage, asserted rather than eyeballed (same rule as the fixture leg): a
# prose mutation the scan does not refuse is a defeat class the suite has
# stopped covering.
if (length(prose_dead)) {
  stop(
    "prose mutation(s) the scan did not refuse:\n  ",
    paste(prose_dead, collapse = "\n  ")
  )
}
cat("\nevery prose mutation refused; control clean\n")
