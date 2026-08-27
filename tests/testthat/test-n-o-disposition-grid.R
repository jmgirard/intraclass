# The `n_o` disposition grid (M141) ---------------------------------------------
#
# Every disposition of `icc()`'s within-cell-replicate dispatch
# (`R/icc.R:1393-1481`), pinned as a standing grid: what `glance()$n_o` reports
# when a fit is returned, which abort is raised when one is not, and which
# conditions are signalled ahead of either.
#
# The case set is GENERATED (GP8), never a hand-written row list: `expand.grid()`
# over the five axes below, less the rows on which an axis does not apply. Each
# generated case is joined to its expectation BY ITS AXIS VALUES, never by row
# position, and the two sets are asserted equal in both directions -- so adding
# an axis value fails loudly instead of silently re-aligning every expectation
# onto the wrong case.
#
# Every expectation here was MEASURED by executing `icc()` (M141 T1), never
# predicted from reading the branches.

# ---- fixtures ----------------------------------------------------------------
#
# One row per (subject, rater, replicate). The three replicate shapes:
#
#   "uniform"      every cell the design defines is present, each rated twice
#   "ragged"       every defined cell present, ONE cell rated three times
#   "missing_cell" one defined cell absent, every present cell rated twice
#
# "ragged" keeps the full cell grid and "missing_cell" keeps equal per-cell
# counts on purpose: that is what separates the two clauses of
# `replicates_uniform` (`R/design.R:48-50`) under AC3's planted defects.
#
# "missing_cell" drops a whole cell -- both of its replicate rows -- not a single
# rating. Under `ml_design = "nested_in_subjects"` (Design 3) the cells a design
# defines are the observed subject-by-own-rater pairs, so the dropped cell is one
# subject paired with one of its own raters.

# Provenance: both fixtures are generated in place by the constructors below,
# each seeded from its own arguments (`fixture_seed()`), so a case's data does
# not depend on the order the grid is walked in. Nothing is read from disk.

fixture_seed <- function(...) {
  key <- paste(c(...), collapse = "/")
  20260827L + sum(utf8ToInt(key))
}

grid_single <- function(shape) {
  set.seed(fixture_seed("single", shape))
  ns <- 8L
  nr <- 4L
  d <- expand.grid(
    subject = seq_len(ns),
    rater = seq_len(nr),
    replicate = seq_len(2L)
  )
  first <- d$subject == 1L & d$rater == 1L
  d <- switch(
    shape,
    uniform = d,
    ragged = rbind(d, transform(d[first, ][1L, ], replicate = 3L)),
    missing_cell = d[!first, ]
  )
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

grid_multilevel <- function(shape, ml_design) {
  set.seed(fixture_seed("ml", ml_design, shape))
  nc <- 5L
  nsc <- 4L
  nr <- 3L
  cells <- list()
  for (cl in seq_len(nc)) {
    for (si in seq_len(nsc)) {
      subject <- paste0("c", cl, "s", si)
      raters <- switch(
        ml_design,
        crossed = paste0("r", seq_len(nr)),
        nested_in_clusters = paste0("c", cl, "r", seq_len(nr)),
        nested_in_subjects = paste0(subject, "r", seq_len(nr))
      )
      for (r in raters) {
        cells[[length(cells) + 1L]] <- data.frame(
          cluster = paste0("c", cl),
          subject = subject,
          rater = r,
          replicate = seq_len(2L),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  d <- do.call(rbind, cells)
  first <- d$subject == d$subject[[1L]] & d$rater == d$rater[[1L]]
  d <- switch(
    shape,
    uniform = d,
    ragged = rbind(d, transform(d[first, ][1L, ], replicate = 3L)),
    missing_cell = d[!first, ]
  )
  eff <- function(x, sd) {
    lv <- unique(x)
    stats::setNames(stats::rnorm(length(lv), 0, sd), lv)[x]
  }
  d$score <- 10 +
    eff(d$cluster, 1.0) +
    eff(d$subject, 1.2) +
    eff(d$rater, 0.8) +
    eff(paste0(d$subject, ":", d$rater), 0.6) +
    stats::rnorm(nrow(d), 0, 0.7)
  d$cluster <- factor(d$cluster)
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  d
}

case_data <- function(case) {
  if (case$multilevel) {
    grid_multilevel(case$shape, case$ml_design)
  } else {
    grid_single(case$shape)
  }
}

# ---- the generated case set --------------------------------------------------

n_o_grid_cases <- function() {
  cases <- expand.grid(
    multilevel = c(FALSE, TRUE),
    ml_design = c("crossed", "nested_in_clusters", "nested_in_subjects"),
    raters = c("random", "fixed"),
    conflated = c(FALSE, TRUE),
    shape = c("uniform", "ragged", "missing_cell"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  # Drop rule: the rows on which an axis does not apply. Without a `cluster`
  # column an `ml_design` or a `"conflated"` level has no argument to ride on,
  # so every single-level row would issue the identical call -- they are one
  # case, not six. (The refusals `design =` and a non-default `level =` would
  # draw there, `R/icc.R:944-956`, are pre-dispatch and out of this grid's
  # scope.) A NESTED `ml_design` with `"conflated"` is NOT dropped: it reaches
  # `icc()` and is refused at `R/icc.R:1204` / `R/icc.R:1212`.
  keep <- cases$multilevel |
    (cases$ml_design == "crossed" & !cases$conflated)
  cases <- cases[keep, , drop = FALSE]
  rownames(cases) <- NULL
  cases$key <- case_key(cases)
  cases
}

case_key <- function(cases) {
  ifelse(
    cases$multilevel,
    paste0(
      "ml/",
      cases$ml_design,
      "/",
      cases$raters,
      "/",
      ifelse(cases$conflated, "conflated", "plain"),
      "/",
      cases$shape
    ),
    paste0("single/", cases$raters, "/", cases$shape)
  )
}

# ---- the measured dispositions ------------------------------------------------
#
# `n_o` -- the integer `glance()$n_o` must report, or NA_integer_.
# `abort` -- a substring of the RENDERED abort message. An abort is never
#   identified by its condition class alone: guards OUTSIDE the dispatch abort
#   with the same `intraclass_unsupported` class (e.g. `R/icc.R:1232`), so the
#   class cannot separate them. `class` is asserted in addition, not instead.
# `branch` -- the dispatch-block branch this abort identifies, or NA for an
#   abort raised outside the block (read by the AC2 branch-count assertion).
# `conditions` -- substrings of every condition (warning or message) signalled
#   ahead of the disposition, compared as a WHOLE SET: a condition the grid does
#   not expect reddens its case.

FIXED_ADVISORY <- "restricts inference to exactly these raters"
DESIGN3_DROP <- "not defined when raters are nested within subjects (Design 3)"

fitted_case <- function(n_o, conditions = character()) {
  list(
    n_o = n_o,
    abort = NULL,
    class = NULL,
    branch = NA_character_,
    conditions = conditions
  )
}

aborted_case <- function(abort, class, branch, conditions = character()) {
  list(
    n_o = NULL,
    abort = abort,
    class = class,
    branch = branch,
    conditions = conditions
  )
}

n_o_grid_expectations <- function() {
  e <- list()
  add <- function(key, value) e[[key]] <<- value

  # -- single level -------------------------------------------------------------
  add("single/random/uniform", fitted_case(2L))
  add("single/random/ragged", fitted_case(NA_integer_))
  add("single/random/missing_cell", fitted_case(NA_integer_))
  add("single/fixed/uniform", fitted_case(2L, FIXED_ADVISORY))
  for (shape in c("ragged", "missing_cell")) {
    add(
      paste0("single/fixed/", shape),
      aborted_case(
        "within-cell replicates are not supported for fixed raters yet",
        "intraclass_unsupported",
        "single_fixed_nonuniform",
        FIXED_ADVISORY
      )
    )
  }

  # -- multilevel, plain levels, random raters ----------------------------------
  for (design in c("crossed", "nested_in_clusters")) {
    add(paste0("ml/", design, "/random/plain/uniform"), fitted_case(2L))
    for (shape in c("ragged", "missing_cell")) {
      add(
        paste0("ml/", design, "/random/plain/", shape),
        aborted_case(
          "Ragged or incomplete within-cell replicates are not supported for multilevel designs yet",
          "intraclass_unsupported",
          "ml_nonuniform"
        )
      )
    }
  }
  for (shape in c("uniform", "ragged", "missing_cell")) {
    add(
      paste0("ml/nested_in_subjects/random/plain/", shape),
      aborted_case(
        "Within-cell replicates are not defined when raters are nested within subjects",
        "intraclass_unsupported",
        "ml_design3",
        DESIGN3_DROP
      )
    )
  }

  # -- multilevel, plain levels, fixed raters -----------------------------------
  for (design in c("crossed", "nested_in_clusters")) {
    for (shape in c("uniform", "ragged", "missing_cell")) {
      add(
        paste0("ml/", design, "/fixed/plain/", shape),
        aborted_case(
          "Within-cell replicates are not supported for fixed-rater multilevel designs yet",
          "intraclass_unsupported",
          "ml_fixed",
          FIXED_ADVISORY
        )
      )
    }
  }
  for (shape in c("uniform", "ragged", "missing_cell")) {
    # Raised at `R/icc.R:1232`, OUTSIDE the dispatch block -- hence branch NA.
    add(
      paste0("ml/nested_in_subjects/fixed/plain/", shape),
      aborted_case(
        "Fixed raters are not defined when raters are nested within subjects",
        "intraclass_unsupported",
        NA_character_,
        FIXED_ADVISORY
      )
    )
  }

  # -- multilevel, conflated level ----------------------------------------------
  for (shape in c("uniform", "ragged", "missing_cell")) {
    add(
      paste0("ml/crossed/random/conflated/", shape),
      aborted_case(
        "Within-cell replicates are not supported for the conflated ICC yet",
        "intraclass_unsupported",
        "ml_conflated"
      )
    )
  }
  for (design in c("nested_in_clusters", "nested_in_subjects")) {
    for (shape in c("uniform", "ragged", "missing_cell")) {
      # `R/icc.R:1212`, outside the dispatch: a different class again, which is
      # why the grid matches messages rather than classes.
      add(
        paste0("ml/", design, "/random/conflated/", shape),
        aborted_case(
          "The conflated ICC needs raters crossed with clusters (Design 1)",
          "intraclass_inapplicable",
          NA_character_
        )
      )
    }
  }
  for (design in c("crossed", "nested_in_clusters", "nested_in_subjects")) {
    for (shape in c("uniform", "ragged", "missing_cell")) {
      # `R/icc.R:1204`, outside the dispatch. No fixed-rater advisory here: the
      # rule at `R/icc.R:1042` suppresses it for a multilevel conflated request.
      add(
        paste0("ml/", design, "/fixed/conflated/", shape),
        aborted_case(
          "A fixed-rater conflated ICC is not available",
          "intraclass_unsupported",
          NA_character_
        )
      )
    }
  }

  e
}

# ---- running one case ---------------------------------------------------------

render_condition <- function(cnd) {
  txt <- cli::ansi_strip(
    paste(cli::format_message(conditionMessage(cnd)), collapse = " ")
  )
  gsub("[[:space:]]+", " ", txt)
}

run_n_o_case <- function(case) {
  d <- case_data(case)
  signalled <- list()
  outcome <- withCallingHandlers(
    tryCatch(
      {
        fit <- if (case$multilevel) {
          icc(
            d,
            score,
            subject,
            rater,
            cluster = cluster,
            raters = case$raters,
            design = case$ml_design,
            level = if (case$conflated) {
              c("subject", "cluster", "conflated")
            } else {
              c("subject", "cluster")
            }
          )
        } else {
          icc(d, score, subject, rater, raters = case$raters)
        }
        list(fitted = TRUE, n_o = glance(fit)$n_o)
      },
      error = function(e) list(fitted = FALSE, condition = e)
    ),
    warning = function(w) {
      signalled[[length(signalled) + 1L]] <<- w
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      signalled[[length(signalled) + 1L]] <<- m
      invokeRestart("muffleMessage")
    }
  )
  outcome$signalled <- vapply(signalled, render_condition, character(1))
  outcome
}

# ---- the grid -----------------------------------------------------------------

test_that("the generated grid and the declared expectations cover the same cases", {
  cases <- n_o_grid_cases()
  expected <- n_o_grid_expectations()
  expect_gt(nrow(cases), 0L)
  expect_identical(sort(cases$key), sort(names(expected)))
  expect_identical(anyDuplicated(cases$key), 0L)
  # 36 multilevel (3 designs x 2 rater treatments x 2 level sets x 3 shapes)
  # + 6 single-level (2 rater treatments x 3 shapes).
  expect_identical(nrow(cases), 42L)
})

test_that("every case reports the n_o disposition or the abort the grid declares", {
  skip_if_not_installed("glmmTMB")
  cases <- n_o_grid_cases()
  expected <- n_o_grid_expectations()
  for (i in seq_len(nrow(cases))) {
    case <- as.list(cases[i, ])
    want <- expected[[case$key]]
    got <- run_n_o_case(case)

    # The whole condition set, not a uniform assertion: an unexpected warning
    # or message reddens this case.
    expect_identical(
      length(got$signalled),
      length(want$conditions),
      info = paste0(case$key, ": conditions ", toString(got$signalled))
    )
    for (pattern in want$conditions) {
      expect_true(
        any(grepl(pattern, got$signalled, fixed = TRUE)),
        info = paste0(case$key, ": missing condition ", pattern)
      )
    }

    if (is.null(want$abort)) {
      expect_true(got$fitted, info = paste0(case$key, ": expected a fit"))
      expect_identical(
        got$n_o,
        want$n_o,
        info = paste0(case$key, ": n_o")
      )
    } else {
      expect_false(got$fitted, info = paste0(case$key, ": expected an abort"))
      expect_s3_class(got$condition, want$class)
      expect_true(
        grepl(want$abort, render_condition(got$condition), fixed = TRUE),
        info = paste0(
          case$key,
          ": abort message was ",
          render_condition(got$condition)
        )
      )
    }
  }
})

# ---- the dispatch block covers no branch the grid misses -----------------------
#
# The grid is a hand-declared set of dispositions, so a branch added to the
# dispatch later would ship unpinned unless something counts them. Located from
# `deparse(body(icc))` -- the installed function -- never by reading `R/icc.R`
# from disk, which is absent under `R CMD check`.

icc_dispatch_block <- function() {
  src <- trimws(deparse(body(icc)))
  start <- which(src == "if (design_info$has_replicates) {")
  stopifnot(length(start) == 1L)
  closing <- which(src == "replicates <- TRUE")
  closing <- closing[closing > start]
  stopifnot(length(closing) >= 1L)
  # `replicates <- TRUE` is the block's last STATEMENT, not its end: an abort
  # added between it and the closing brace would sit outside a range that
  # stopped there. Take the brace itself.
  end <- closing[[1L]] + 1L
  if (!identical(src[[end]], "}")) {
    stop(
      "the dispatch block's end anchor no longer sits last: `deparse(body(icc))` ",
      "line ",
      end,
      " is <",
      src[[end]],
      ">, not the block's closing brace. ",
      "Re-anchor before trusting the branch count."
    )
  }
  src[seq(start, end)]
}

test_that("the grid's abort cases identify every abort branch in the dispatch", {
  block <- icc_dispatch_block()
  # `icc_dispatch_block()` already stops on a missing or ambiguous anchor; this
  # guards the remaining case -- anchors that still match but bracket a short or
  # empty range, which would make the count agree trivially.
  expect_gt(length(block), 1L)

  # Any `abort_` helper, not `abort_unsupported(` alone -- a branch raised
  # through a differently-named helper must still be counted.
  calls <- sum(grepl("\\babort_[A-Za-z0-9_.]*\\(", block))
  expect_gt(calls, 0L)

  branch <- vapply(n_o_grid_expectations(), function(x) x$branch, character(1))
  branches <- unique(branch[!is.na(branch)])
  expect_gt(length(branches), 0L)

  expect_identical(length(branches), calls)
})

# ---- the fixed-rater abort names the condition it actually guards --------------
#
# The guard is `!design_info$replicates_uniform` (`R/icc.R:1446`), which fails on
# unequal per-cell counts AND on a design missing a cell it defines
# (`R/design.R:48-50`), so the message must name both shapes -- as its multilevel
# sibling already does. It said only "Ragged" until M141 (D-041).

FIXED_ABORT_BULLETS <- c(
  "Ragged or incomplete within-cell replicates are not supported for fixed raters yet.",
  paste(
    "Fixed-rater replicates ship for balanced, complete data (every cell",
    "present and rated the same number of times); the ragged and incomplete",
    "cases are planned for a later milestone."
  ),
  paste(
    "Use `raters = \"random\"` for ragged or incomplete replicated data, or",
    "provide an equal number of ratings in every cell of a complete",
    "subject-by-rater grid."
  )
)

test_that("the fixed-rater replicate abort names both shapes it fires on", {
  skip_if_not_installed("glmmTMB")
  for (shape in c("ragged", "missing_cell")) {
    d <- grid_single(shape)
    cnd <- suppressWarnings(tryCatch(
      icc(d, score, subject, rater, raters = "fixed"),
      intraclass_unsupported = function(e) e
    ))
    expect_s3_class(cnd, "intraclass_unsupported")
    rendered <- render_condition(cnd)
    for (bullet in FIXED_ABORT_BULLETS) {
      expect_true(
        grepl(bullet, rendered, fixed = TRUE),
        info = paste0(shape, ": missing bullet <", bullet, "> in ", rendered)
      )
    }
  }
})

test_that("the fixed-rater and multilevel replicate aborts open alike", {
  skip_if_not_installed("glmmTMB")
  shared <- "Ragged or incomplete within-cell replicates are not supported for"
  fixed <- suppressWarnings(tryCatch(
    icc(grid_single("ragged"), score, subject, rater, raters = "fixed"),
    intraclass_unsupported = function(e) e
  ))
  multilevel <- tryCatch(
    icc(
      grid_multilevel("ragged", "crossed"),
      score,
      subject,
      rater,
      cluster = cluster,
      design = "crossed"
    ),
    intraclass_unsupported = function(e) e
  )
  expect_true(grepl(shared, render_condition(fixed), fixed = TRUE))
  expect_true(grepl(shared, render_condition(multilevel), fixed = TRUE))
})
