# The `occasions` disposition grid (M146) --------------------------------------
#
# What `tidy()$occasions` reads, on the fit and on both D-study projection axes,
# across the design classes `icc()` accepts. The reference manual states a rule
# for that column (`?icc`, `?d_study`); this grid holds the rule to the code on
# every case, so a sentence true of the families someone happened to think of
# cannot pass. AC1 failed review twice before this file existed, each time by a
# doc claim composed per design family and falsified by a family nobody
# enumerated -- the shape `cairn/LESSONS.md:47` names.
#
# The case set is GENERATED (GP8), never a hand-written row list: `expand.grid()`
# over the three axes below, less the rows on which an axis does not apply. Each
# case is joined to its expectation BY ITS AXIS VALUES, never by row position,
# and the two sets are asserted equal in both directions, so adding an axis
# value fails loudly instead of re-aligning every expectation onto the wrong
# case.
#
# The expectations are DERIVED FROM THE DOCUMENTED RULE and the case's own axis
# values, never read back off the column under test:
#
#   * a fit that splits no within-cell replicates reads `NA` on every row;
#   * a row that averages no occasions reads 1 -- every single-occasion row, and
#     every row whose error set carries no pure-error term, which is the cluster
#     level of a multilevel fit;
#   * a row that does average reads the fitted per-cell occasion count;
#   * on a rater projection the column takes every distinct value the fit's own
#     column carries, and cluster rows the smallest of those;
#   * on an occasion projection every row takes the swept `n_o`, cluster rows
#     included.
#
# Every value in the grid was MEASURED by executing `icc()` and `d_study()`
# (M146 T15) before the rule above was written down.

# ---- fixtures ----------------------------------------------------------------
#
# Generated in place, each seeded from its own arguments, so a case's data does
# not depend on the order the grid is walked in. Nothing is read from disk.
#
# The four replicate shapes:
#
#   "none"          one rating per cell -- no within-cell replicates at all
#   "uniform"       every cell the design defines present, each rated 3 times
#   "ragged"        every defined cell present, ONE cell rated a 4th time
#   "missing_cell"  one defined cell absent, every present cell rated 3 times

occ_seed <- function(...) {
  20260828L + sum(utf8ToInt(paste(c(...), collapse = "/")))
}

occ_reps <- 3L

occ_shape_rows <- function(d, shape) {
  first <- d$replicate == 1L
  switch(
    shape,
    none = d[first, , drop = FALSE],
    uniform = d,
    ragged = rbind(
      d,
      transform(d[1L, , drop = FALSE], replicate = occ_reps + 1L)
    ),
    missing_cell = d[!(d$cell == d$cell[1L]), , drop = FALSE]
  )
}

occ_single_level <- function(shape) {
  set.seed(occ_seed("single", shape))
  ns <- 8L
  nr <- 4L
  d <- expand.grid(
    subject = seq_len(ns),
    rater = seq_len(nr),
    replicate = seq_len(occ_reps)
  )
  d$cell <- paste(d$subject, d$rater, sep = "/")
  d <- occ_shape_rows(d, shape)
  s <- stats::rnorm(ns, 0, 1.2)
  r <- stats::rnorm(nr, 0, 0.8)
  sr <- stats::rnorm(ns * nr, 0, 0.6)
  d$score <- 10 +
    s[d$subject] +
    r[d$rater] +
    sr[(d$rater - 1L) * ns + d$subject] +
    stats::rnorm(nrow(d), 0, 0.7)
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  d
}

occ_multilevel <- function(shape, ml_design) {
  set.seed(occ_seed("ml", ml_design, shape))
  nc <- 5L
  nsc <- 4L
  nr <- 3L
  rows <- list()
  i <- 0L
  for (cl in seq_len(nc)) {
    for (si in seq_len(nsc)) {
      sid <- (cl - 1L) * nsc + si
      raters <- switch(
        ml_design,
        crossed = seq_len(nr),
        nested_in_clusters = (cl - 1L) * nr + seq_len(nr),
        nested_in_subjects = (sid - 1L) * nr + seq_len(nr)
      )
      for (rr in raters) {
        for (rp in seq_len(occ_reps)) {
          i <- i + 1L
          rows[[i]] <- data.frame(
            cluster = cl,
            subject = sid,
            rater = rr,
            replicate = rp,
            cell = paste(sid, rr, sep = "/")
          )
        }
      }
    }
  }
  d <- do.call(rbind, rows)
  d <- occ_shape_rows(d, shape)
  cl_e <- stats::rnorm(nc, 0, 1.0)
  s <- stats::rnorm(nc * nsc, 0, 1.0)
  rf <- stats::rnorm(max(d$rater), 0, 0.8)
  d$score <- 10 +
    cl_e[d$cluster] +
    s[d$subject] +
    rf[d$rater] +
    stats::rnorm(nrow(d), 0, 0.7)
  d$cluster <- factor(d$cluster)
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  d
}

occ_fit <- function(case) {
  occ <- occ_request(case$request)
  if (case$design == "oneway") {
    d <- occ_single_level(case$shape)
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      occasions = occ,
      seed = 1L,
      mc_samples = 200L
    )
  } else if (case$design == "twoway") {
    d <- occ_single_level(case$shape)
    icc(
      d,
      score,
      subject,
      rater,
      occasions = occ,
      seed = 1L,
      mc_samples = 200L
    )
  } else {
    d <- occ_multilevel(case$shape, occ_ml_design(case$design))
    icc(
      d,
      score,
      subject,
      rater,
      cluster,
      occasions = occ,
      seed = 1L,
      mc_samples = 200L
    )
  }
}

occ_ml_design <- function(design) {
  switch(
    design,
    ml_crossed = "crossed",
    ml_nested_clusters = "nested_in_clusters",
    ml_nested_subjects = "nested_in_subjects"
  )
}

occ_request <- function(request) {
  switch(
    request,
    single = "single",
    average = "average",
    both = c("single", "average")
  )
}

# ---- the generated case set --------------------------------------------------

occ_grid_cases <- function() {
  cases <- expand.grid(
    design = c(
      "oneway",
      "twoway",
      "ml_crossed",
      "ml_nested_clusters",
      "ml_nested_subjects"
    ),
    shape = c("none", "uniform", "ragged", "missing_cell"),
    request = c("single", "average", "both"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  cases$key <- paste(cases$design, cases$shape, cases$request, sep = "/")
  rownames(cases) <- NULL
  cases
}

# ---- the declared dispositions ----------------------------------------------
#
# `fits` -- TRUE when `icc()` returns; FALSE when it aborts, and then `abort` is
#   a substring of the RENDERED message (a class alone cannot separate the
#   guards, which share `intraclass_unsupported`).
# `replicates` -- what `glance()$replicates` must report on a case that fits.
# `n_o` -- what `glance()$n_o` must report: the shared per-cell count, or NA.
# `levels` -- the levels the fit reports rows at.
#
# Everything the grid then asserts about `occasions` is DERIVED from these four
# and the case's own `request`, by the documented rule at the top of this file.

# Abort messages are matched over WHITESPACE-COLLAPSED text: `cli` wraps them
# to the console width, so a literal substring spanning a wrap point would not
# match the rendered message.
occ_squash <- function(x) gsub("[[:space:]]+", " ", x)

occ_abort_average <- "requires within-cell replicates"
occ_abort_ragged <- "not supported for ragged"
occ_abort_ml_ragged <- "not supported for multilevel designs"
occ_abort_design3 <- "not defined when raters are nested within subjects"

occ_expectations <- function() {
  cases <- occ_grid_cases()
  out <- vector("list", nrow(cases))
  for (i in seq_len(nrow(cases))) {
    ca <- cases[i, ]
    design <- ca$design
    shape <- ca$shape
    request <- ca$request
    averaged <- request %in% c("average", "both")
    ml <- startsWith(design, "ml_")
    # A one-way fit has no rater facet and so no cells to split: it never
    # splits replicates, whatever the data holds (D-038 / M138).
    replicates <- design != "oneway" && shape != "none"
    # `n_o` reports a number only on a uniform AND complete replicate design
    # (D-041); a ragged or missing-cell one reads NA.
    n_o <- if (replicates && shape == "uniform") occ_reps else NA_real_
    levels <- if (design == "ml_crossed") {
      c("subject", "cluster")
    } else if (ml) {
      "subject"
    } else {
      NA_character_
    }

    fits <- TRUE
    abort <- NULL
    if (design == "ml_nested_subjects" && shape != "none") {
      # Design 3 confounds the rater effect into the residual, so there is no
      # interaction to split from pure error and replicates are refused.
      fits <- FALSE
      abort <- occ_abort_design3
    } else if (averaged && !replicates) {
      fits <- FALSE
      abort <- occ_abort_average
    } else if (ml && shape %in% c("ragged", "missing_cell")) {
      fits <- FALSE
      abort <- occ_abort_ml_ragged
    } else if (averaged && shape %in% c("ragged", "missing_cell")) {
      fits <- FALSE
      abort <- occ_abort_ragged
    }

    out[[ca$key]] <- list(
      fits = fits,
      abort = abort,
      replicates = replicates,
      n_o = n_o,
      levels = levels
    )
  }
  out[!vapply(out, is.null, logical(1))]
}

# The values the documented rule predicts for the SUBJECT-side rows of a fit
# (the rows carrying `level` "subject" or NA): 1 for a single-occasion setting,
# the fitted per-cell count for an averaged one.
occ_expected_fit_values <- function(exp, request) {
  if (!exp$replicates) {
    return(NA_real_)
  }
  vals <- c(
    if (request %in% c("single", "both")) 1,
    if (request %in% c("average", "both")) exp$n_o
  )
  sort(unique(vals))
}

# The values the rule predicts across the WHOLE column of a fit -- the subject
# side plus the cluster level's placeholder 1. A rater projection takes exactly
# this set, so on a crossed multilevel fit asked for `occasions = "average"`
# alone it still projects a subject curve at 1, which the fit does not report
# (`?d_study` says so).
occ_expected_all_values <- function(exp, request) {
  vals <- occ_expected_fit_values(exp, request)
  if (exp$replicates && "cluster" %in% exp$levels) {
    vals <- sort(unique(c(vals, 1)))
  }
  vals
}

occ_subject_rows <- function(td) {
  is.na(td$level) | td$level == "subject"
}

occ_values <- function(td, rows) {
  v <- td$occasions[rows]
  if (all(is.na(v))) NA_real_ else sort(unique(v))
}

# ---- the grid ---------------------------------------------------------------

test_that("the generated grid and the declared expectations cover the same cases", {
  cases <- occ_grid_cases()
  exp <- occ_expectations()

  expect_gt(nrow(cases), 0L)
  expect_setequal(cases$key, names(exp))
  expect_identical(anyDuplicated(cases$key), 0L)
  # A guard on the axis set itself: a new design, shape or request value moves
  # this count and has to be dispositioned rather than silently absorbed.
  expect_identical(nrow(cases), 60L)
})

test_that("every case reports the occasions the documented rule predicts, or the abort the grid declares", {
  cases <- occ_grid_cases()
  exp <- occ_expectations()

  for (i in seq_len(nrow(cases))) {
    ca <- cases[i, ]
    e <- exp[[ca$key]]
    fit <- tryCatch(
      suppressWarnings(suppressMessages(occ_fit(ca))),
      error = function(cnd) cnd
    )

    if (!e$fits) {
      expect_s3_class(fit, "rlang_error", exact = FALSE)
      expect_true(
        grepl(e$abort, occ_squash(conditionMessage(fit)), fixed = TRUE),
        info = paste(ca$key, "|", occ_squash(conditionMessage(fit)))
      )
      next
    }

    expect_false(inherits(fit, "condition"), info = ca$key)
    gl <- glance(fit)
    expect_identical(gl$replicates, e$replicates, info = ca$key)
    expect_equal(as.numeric(gl$n_o), e$n_o, info = ca$key)

    td <- tidy(fit)
    expect_setequal(unique(td$level), e$levels)

    # The subject-side rows carry the requested settings.
    expect_equal(
      occ_values(td, occ_subject_rows(td)),
      occ_expected_fit_values(e, ca$request),
      info = paste(ca$key, "fit/subject")
    )
    # The cluster rows average no occasions, so they read 1 whatever was asked
    # for -- and NA on a fit that splits no replicates.
    if ("cluster" %in% e$levels) {
      expect_equal(
        occ_values(td, !is.na(td$level) & td$level == "cluster"),
        if (e$replicates) 1 else NA_real_,
        info = paste(ca$key, "fit/cluster")
      )
    }
    # `occasions` equals `glance()$n_o` on exactly the averaged subject rows,
    # and on no others: the two columns are different quantities.
    if (e$replicates && !is.na(e$n_o) && ca$request == "both") {
      expect_true(any(td$occasions == e$n_o), info = ca$key)
      expect_true(any(td$occasions == 1), info = ca$key)
    }
  }
})

test_that("both projection axes report the occasions the documented rule predicts", {
  cases <- occ_grid_cases()
  exp <- occ_expectations()
  swept <- c(1, 2.5, 4)

  for (i in seq_len(nrow(cases))) {
    ca <- cases[i, ]
    e <- exp[[ca$key]]
    if (!e$fits) {
      next
    }
    fit <- suppressWarnings(suppressMessages(occ_fit(ca)))
    fit_values <- occ_expected_fit_values(e, ca$request)
    all_values <- occ_expected_all_values(e, ca$request)

    # A ragged replicate fit refuses both axes: its occasion-averaged divisor
    # is an open modeling question (ADR-030). Everything else projects.
    ragged <- e$replicates && is.na(e$n_o)

    rater <- tryCatch(
      suppressWarnings(suppressMessages(d_study(fit, m = 1:2))),
      error = function(cnd) cnd
    )
    if (ragged) {
      expect_s3_class(rater, "rlang_error", exact = FALSE)
    } else {
      td <- tidy(rater)
      # The rater axis takes every distinct value the fit's own column carries,
      # cluster rows the smallest of those.
      expect_equal(
        occ_values(td, occ_subject_rows(td)),
        all_values,
        info = paste(ca$key, "rater/subject")
      )
      if ("cluster" %in% e$levels) {
        expect_equal(
          occ_values(td, !is.na(td$level) & td$level == "cluster"),
          if (e$replicates) min(all_values) else NA_real_,
          info = paste(ca$key, "rater/cluster")
        )
      }
    }

    occasion <- tryCatch(
      suppressWarnings(suppressMessages(d_study(fit, n_o = swept))),
      error = function(cnd) cnd
    )
    if (!e$replicates || ragged) {
      # An occasion projection needs a replicate fit to sweep.
      expect_s3_class(occasion, "rlang_error", exact = FALSE)
    } else {
      td <- tidy(occasion)
      # Every row takes the swept count, cluster rows included, and a
      # non-integer sweep is carried verbatim (M138).
      expect_equal(
        occ_values(td, rep(TRUE, nrow(td))),
        swept,
        info = paste(ca$key, "occasion/all")
      )
      if ("cluster" %in% e$levels) {
        expect_equal(
          occ_values(td, !is.na(td$level) & td$level == "cluster"),
          swept,
          info = paste(ca$key, "occasion/cluster")
        )
      }
    }
  }
})
