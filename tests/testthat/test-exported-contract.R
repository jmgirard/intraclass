# The exported contract fixed at v0.1.0 (D-035, RR04) ---------------------------
#
# Two clauses, each pinned here:
#   1. A vector-valued default in `icc()`'s signature means "report every value"
#      and nothing else. A choice argument takes exactly one value; passing
#      several -- the full choice list included -- aborts classed rather than
#      quietly selecting the first (PRINCIPLES.md #5/#8).
#   2. Every identifier column of `tidy()` output is present on every fit, NA
#      where the design does not define it, so two tidied fits row-bind and a
#      later extension fills cells instead of changing the schema. `glance()`
#      names the replicate split rather than letting `var_residual` change
#      meaning silently.

# A balanced two-way design with two ratings per subject x rater cell: the
# simplest shape where `occasions`, `n_o` and `var_subject_rater` are defined,
# so it is the control that shows the NA columns below are NA by design, not by
# accident. `nested_replicate_frame()` below is the same claim on a
# block-diagonal design, where the flat subject x rater grid is not the
# design's own geometry.
replicate_frame <- function(seed = 4) {
  set.seed(seed)
  grid <- expand.grid(
    subject = seq_len(8L),
    rater = seq_len(3L),
    occ = seq_len(2L)
  )
  s <- stats::rnorm(8L, 0, 2)
  r <- stats::rnorm(3L, 0, 1)
  sr <- stats::rnorm(24L, 0, 0.5)
  grid$score <- 10 +
    s[grid$subject] +
    r[grid$rater] +
    sr[(grid$rater - 1L) * 8L + grid$subject] +
    stats::rnorm(nrow(grid), 0, 1)
  grid$subject <- factor(grid$subject)
  grid$rater <- factor(grid$rater)
  grid
}

# 1. Choice arguments take exactly one value ------------------------------------

test_that("a multi-valued choice argument aborts classed, never collapses", {
  expect_error(
    icc(
      ratings,
      score,
      subject,
      rater,
      raters = c("random", "fixed"),
      seed = 1
    ),
    class = "intraclass_error"
  )
  expect_error(
    icc(
      ratings,
      score,
      subject,
      rater,
      posterior_summary = c("percentile", "hpdi"),
      seed = 1
    ),
    class = "intraclass_error"
  )
  expect_error(
    icc(
      ratings,
      score,
      subject,
      rater,
      model = c("twoway", "oneway"),
      seed = 1
    ),
    class = "intraclass_error"
  )
})

test_that("the scalar defaults still fit, and each choice is still accepted", {
  # The passing control: the abort above is about arity, not about the values.
  fit <- icc(ratings, score, subject, rater, seed = 1)
  expect_s3_class(fit, "icc")
  expect_identical(fit$design$raters, "random")
  expect_identical(
    suppressWarnings(
      icc(ratings, score, subject, rater, raters = "fixed", seed = 1)
    )$design$raters,
    "fixed"
  )
})

test_that("every choose_icc() answer is a choice argument (D-037)", {
  # The chooser asks one question at a time, so `type`, `unit` and `level` are
  # answers here where they are report-all axes in `icc()` -- the same names on
  # opposite sides of D-036's discriminator, which is why D-037 classifies by
  # (function, argument) pair. Before v0.1.0 `validate_choice()` opened with an
  # `identical(value, choices)` shortcut, so passing the exact full choice list
  # returned the first value silently (M48 review G3).
  base <- list(
    model = "twoway",
    type = "agreement",
    unit = "single",
    raters = "random"
  )
  multi <- list(
    model = c("twoway", "oneway"),
    type = c("agreement", "consistency"),
    unit = c("single", "average", "both"),
    raters = c("random", "fixed")
  )
  for (arg in names(multi)) {
    args <- utils::modifyList(base, stats::setNames(list(multi[[arg]]), arg))
    expect_error(do.call(choose_icc, args), class = "intraclass_error")
  }
  # `level` only applies to a multilevel design, so it needs its own call.
  expect_error(
    choose_icc(
      model = "twoway",
      type = "agreement",
      unit = "single",
      raters = "random",
      multilevel = TRUE,
      level = c("subject", "cluster", "both")
    ),
    class = "intraclass_error"
  )
  # The passing control: the abort is about arity, not the values -- each single
  # answer still recommends.
  expect_s3_class(do.call(choose_icc, base), "icc_recommendation")
})

test_that("autoplot's `what` is a choice argument on the same terms", {
  skip_if_not_installed("ggplot2")
  fit <- icc(ratings, score, subject, rater, seed = 1)
  expect_error(
    ggplot2::autoplot(fit, what = c("coefficients", "components")),
    class = "intraclass_error"
  )
  expect_s3_class(ggplot2::autoplot(fit), "ggplot")
  expect_s3_class(ggplot2::autoplot(fit, what = "components"), "ggplot")
})

# Design 2 (raters nested in clusters) with two ratings per cell. The flat
# subject x rater grid is block-diagonal here, so `summarize_design()` cannot
# read an occasion count off it and the design-aware count is the only correct
# one -- the shape that showed `glance()$n_o` reporting NA beside a populated
# `var_subject_rater` (M48 review F1).
nested_replicate_frame <- function(seed = 42) {
  set.seed(seed)
  nc <- 5L
  ns <- 6L
  nr <- 3L
  grid <- expand.grid(
    occ = seq_len(2L),
    r = seq_len(nr),
    subj = seq_len(ns),
    cluster = seq_len(nc)
  )
  grid$subject <- paste0("c", grid$cluster, "_s", grid$subj)
  grid$rater <- paste0("c", grid$cluster, "_r", grid$r)
  ce <- stats::rnorm(nc, 0, 1)
  se <- stats::rnorm(nc * ns, 0, 1.5)
  re <- stats::rnorm(nc * nr, 0, 0.7)
  grid$score <- 10 +
    ce[grid$cluster] +
    se[as.integer(factor(grid$subject))] +
    re[as.integer(factor(grid$rater))] +
    stats::rnorm(nrow(grid), 0, 0.8)
  grid
}

# 2. A stable tidy/glance schema ------------------------------------------------

test_that("tidy.icc names the coefficient column `term` and always carries `occasions`", {
  td <- tidy(icc(ratings, score, subject, rater, seed = 1))
  expect_identical(
    names(td),
    c(
      "term",
      "occasions",
      "type",
      "level",
      "sf_index",
      "estimate",
      "std.error",
      "conf.low",
      "conf.high",
      "conf.level",
      "method"
    )
  )
  expect_true(all(is.na(td$occasions)))
  expect_true(all(grepl("^ICC\\(", td$term)))
})

test_that("a replicate fit fills `occasions`, and the two schemas row-bind", {
  rep_fit <- icc(replicate_frame(), score, subject, rater, seed = 1)
  td_rep <- tidy(rep_fit)
  td_plain <- tidy(icc(ratings, score, subject, rater, seed = 1))
  expect_identical(names(td_rep), names(td_plain))
  expect_false(any(is.na(td_rep$occasions)))
  bound <- rbind(td_rep, td_plain)
  expect_identical(nrow(bound), nrow(td_rep) + nrow(td_plain))
})

test_that("tidy.icc_dstudy always carries `occasions`, `level` and `type`", {
  fit <- icc(ratings, score, subject, rater, seed = 1)
  td <- tidy(d_study(fit, m = 2:4))
  expect_identical(
    names(td),
    c(
      "m",
      "occasions",
      "level",
      "term",
      "type",
      "estimate",
      "std.error",
      "conf.low",
      "conf.high",
      "conf.level",
      "method"
    )
  )
  # Not multilevel and not replicated: those two are NA, `type` is not.
  expect_true(all(is.na(td$occasions)))
  expect_true(all(is.na(td$level)))
  expect_false(any(is.na(td$type)))
})

test_that("glance.icc names the replicate split instead of shifting var_residual", {
  gl <- glance(icc(ratings, score, subject, rater, seed = 1))
  expect_true(all(
    c("var_subject_rater", "n_o", "rhat", "ess_bulk") %in% names(gl)
  ))
  # No replicates and no sampler: each of the four is NA, and `var_residual`
  # is the only error term the fit has.
  expect_true(is.na(gl$var_subject_rater))
  expect_true(is.na(gl$n_o))
  expect_true(is.na(gl$rhat))
  expect_true(is.na(gl$ess_bulk))
  expect_false(is.na(gl$var_residual))

  gl_rep <- glance(
    icc(replicate_frame(), score, subject, rater, seed = 1)
  )
  # With replicates both are reported, so which quantity `var_residual` holds
  # is readable from the row rather than inferred.
  expect_false(is.na(gl_rep$var_subject_rater))
  expect_identical(gl_rep$n_o, 2L)
})

test_that("glance.icc reports `n_o` on a nested replicate design, not just a crossed one", {
  gl <- glance(
    icc(
      nested_replicate_frame(),
      score,
      subject,
      rater,
      cluster = cluster,
      design = "nested_in_clusters",
      seed = 1
    )
  )
  # The block-diagonal design defines an occasion count per cell exactly as the
  # crossed one does, so the two replicate columns agree about whether the fit
  # has replicates rather than contradicting each other.
  expect_false(is.na(gl$var_subject_rater))
  expect_identical(gl$n_o, 2L)
})

# 3. d_study validates its interval settings ------------------------------------

test_that("d_study aborts classed on an out-of-range conf_level or sample count", {
  fit <- icc(ratings, score, subject, rater, seed = 1)
  expect_error(
    d_study(fit, m = 2:4, conf_level = 95),
    class = "intraclass_error"
  )
  expect_error(
    d_study(fit, m = 2:4, conf_level = c(0.9, 0.95)),
    class = "intraclass_error"
  )
  expect_error(
    d_study(fit, m = 2:4, mc_samples = 0),
    class = "intraclass_error"
  )
  expect_error(
    d_study(fit, m = 2:4, mc_samples = 10.5),
    class = "intraclass_error"
  )
  # The passing control: a valid pair still projects, and the level lands in
  # the reported column rather than merely being accepted.
  ok <- tidy(d_study(fit, m = 2:4, conf_level = 0.9, mc_samples = 500L))
  expect_true(all(ok$conf.level == 0.9))
})

test_that("tidy.icc_dstudy fills the columns the design defines, and only those", {
  # The all-NA case above shows the columns are present; these show they are NA
  # by design rather than never populated (M48 review F10).
  rep_proj <- tidy(d_study(
    icc(replicate_frame(), score, subject, rater, seed = 1),
    m = 2:3
  ))
  expect_false(any(is.na(rep_proj$occasions)))
  expect_false(any(is.na(rep_proj$type)))
  expect_true(all(is.na(rep_proj$level)))

  oneway_proj <- tidy(
    d_study(
      icc(ratings, score, subject, rater, model = "oneway", seed = 1),
      m = 2:3
    )
  )
  # A one-way design defines no error definition, so `type` is NA where the
  # two-way projection above fills it.
  expect_true(all(is.na(oneway_proj$type)))
  expect_true(all(is.na(oneway_proj$occasions)))
  expect_true(all(is.na(oneway_proj$level)))
})

test_that("d_study aborts classed on a multi-valued or non-integer seed", {
  fit <- icc(ratings, score, subject, rater, seed = 1)
  # Clause 1 reaches `seed` on this surface too: left unvalidated it took the
  # first element silently, and a string reached `set.seed()` as a bare base
  # error (M48 review F2).
  expect_error(
    d_study(fit, m = 2:4, seed = c(1, 2)),
    class = "intraclass_error"
  )
  expect_error(d_study(fit, m = 2:4, seed = "abc"), class = "intraclass_error")
  expect_error(d_study(fit, m = 2:4, seed = 1.5), class = "intraclass_error")
  # The passing control: a single whole seed still projects, and the same seed
  # reproduces the same band rather than merely being accepted.
  a <- tidy(d_study(fit, m = 2:4, seed = 7))
  b <- tidy(d_study(fit, m = 2:4, seed = 7))
  expect_identical(a$conf.low, b$conf.low)
})

# 4. The schema remainder closed before the one-way door shuts (M138) -----------

# A crossed multilevel design (Design 1) with two ratings per subject x rater
# cell. Its `d_study()` projection builds the `occasions` column per level --
# holding the cluster curve at `min(proj_occ)` -- rather than off one flat grid,
# so it is the only shape that exercises that construction.
multilevel_replicate_frame <- function(seed = 11) {
  set.seed(seed)
  nc <- 5L
  ns <- 6L
  nr <- 3L
  grid <- expand.grid(
    occ = seq_len(2L),
    rater = seq_len(nr),
    subj = seq_len(ns),
    cluster = seq_len(nc)
  )
  ce <- stats::rnorm(nc, 0, 1)
  se <- stats::rnorm(nc * ns, 0, 1.5)
  re <- stats::rnorm(nr, 0, 0.8)
  grid$subject <- factor(paste0("c", grid$cluster, "_s", grid$subj))
  grid$score <- 10 +
    ce[grid$cluster] +
    se[(grid$cluster - 1L) * ns + grid$subj] +
    re[grid$rater] +
    stats::rnorm(nrow(grid), 0, 1)
  grid$cluster <- factor(grid$cluster)
  grid$rater <- factor(grid$rater)
  grid
}

# Design 3 (raters nested in subjects): one-way-style ICC(1)/ICC(k) labels and
# no rater component, yet `design$raters` holds the untouched "random".
design3_frame <- function(seed = 7) {
  set.seed(seed)
  nc <- 20L
  ns <- 6L
  k <- 4L
  cl <- stats::rnorm(nc, 0, 1)
  d <- expand.grid(subj = seq_len(ns), r = seq_len(k), cluster = seq_len(nc))
  sc <- stats::rnorm(nc * ns, 0, 1.2)
  d$score <- 10 +
    cl[d$cluster] +
    sc[(d$cluster - 1L) * ns + d$subj] +
    stats::rnorm(nrow(d), 0, 0.7)
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$subj, d$r, sep = "_"))
  d
}

test_that("glance.icc carries `raters` and `replicates`, one name set per design", {
  skip_if_not_installed("glmmTMB")
  ml <- multilevel_replicate_frame()
  fits <- list(
    oneway = icc(ratings, score, subject, rater, model = "oneway", seed = 1),
    random = icc(ratings, score, subject, rater, seed = 1),
    fixed = suppressWarnings(
      icc(ratings, score, subject, rater, raters = "fixed", seed = 1)
    ),
    multilevel = icc(
      ml[ml$occ == 1L, ],
      score,
      subject,
      rater,
      cluster = cluster,
      seed = 1
    ),
    replicate = icc(replicate_frame(), score, subject, rater, seed = 1),
    design3 = icc(
      design3_frame(),
      score,
      subject,
      rater,
      cluster = cluster,
      seed = 1
    )
  )
  gls <- lapply(fits, glance)

  # A one-way design has no rater facet, and neither does Design 3, whose raters
  # are nested in subjects: the treatment does not apply on either, so both read
  # NA (D-042). Every other design reports the treatment it was fitted under.
  expect_identical(gls$oneway$raters, NA_character_)
  expect_identical(gls$design3$raters, NA_character_)
  expect_identical(gls$random$raters, "random")
  expect_identical(gls$fixed$raters, "fixed")
  expect_identical(gls$multilevel$raters, "random")
  expect_identical(gls$replicate$raters, "random")
  # `replicates` is not inferable from `n_o`, which is also NA on a ragged
  # replicate design, so it is reported in its own right.
  expect_identical(
    vapply(gls, function(g) g$replicates, logical(1)),
    c(
      oneway = FALSE,
      random = FALSE,
      fixed = FALSE,
      multilevel = FALSE,
      replicate = TRUE,
      design3 = FALSE
    )
  )

  # `replicates` reports the FITTED design's split, not the data layout: a
  # one-way fit ignores rater identity, so it has no cells to split and reads
  # FALSE even on data holding two ratings in every subject x rater cell.
  ow_rep <- icc(
    replicate_frame(),
    score,
    subject,
    rater,
    model = "oneway",
    seed = 1
  )
  expect_false(glance(ow_rep)$replicates)
  expect_true(
    glance(icc(replicate_frame(), score, subject, rater, seed = 1))$replicates
  )

  # One name set across every design family, so any two rows bind.
  for (g in gls) {
    expect_setequal(names(g), names(gls[[1]]))
  }
  expect_identical(nrow(do.call(rbind, gls)), length(gls))
})

test_that("tidy()$occasions is double on every fit and every projection", {
  skip_if_not_installed("glmmTMB")
  f_two <- icc(ratings, score, subject, rater, seed = 1)
  f_rep <- icc(replicate_frame(), score, subject, rater, seed = 1)
  f_mlrep <- icc(
    multilevel_replicate_frame(),
    score,
    subject,
    rater,
    cluster = cluster,
    seed = 1
  )
  tidied_fits <- list(tidy(f_two), tidy(f_rep))
  tidied_projs <- list(
    tidy(d_study(f_two, m = 2:3)),
    tidy(d_study(f_rep, m = 2:3)),
    tidy(d_study(f_mlrep, m = 2:3)),
    tidy(d_study(f_rep, n_o = 1:3)),
    tidy(d_study(f_rep, n_o = c(1, 1.5, 2)))
  )
  for (td in c(tidied_fits, tidied_projs)) {
    expect_identical(typeof(td$occasions), "double")
  }
  # `d_study()` allows a non-integer occasion count on purpose (symmetry with
  # `m`), so an integer column would report a projected 1.5 as 1.
  expect_identical(
    sort(unique(tidied_projs[[5]]$occasions)),
    c(1, 1.5, 2)
  )
  expect_identical(
    nrow(do.call(rbind, tidied_fits)),
    sum(vapply(tidied_fits, nrow, integer(1)))
  )
  expect_identical(
    nrow(do.call(rbind, tidied_projs)),
    sum(vapply(tidied_projs, nrow, integer(1)))
  )
})

test_that("glance() on a projection reads `raters` as glance() on the fit does", {
  skip_if_not_installed("glmmTMB")
  ow <- icc(ratings, score, subject, rater, model = "oneway", seed = 1)
  expect_identical(glance(d_study(ow, m = 1:3))$raters, NA_character_)
  rnd <- icc(ratings, score, subject, rater, seed = 1)
  expect_identical(glance(d_study(rnd, m = 1:3))$raters, "random")
  fx <- suppressWarnings(icc(
    ratings,
    score,
    subject,
    rater,
    raters = "fixed",
    type = "consistency",
    seed = 1
  ))
  expect_identical(glance(d_study(fx, m = 1:3))$raters, "fixed")
  # Design 3 has no rater component either -- its raters are nested in subjects,
  # so no rater main effect is separable -- and reads NA on the projection just
  # as it does on the fit (D-042, superseding D-038 clause 1's Design 3
  # sentence).
  d3 <- icc(design3_frame(), score, subject, rater, cluster = cluster, seed = 1)
  expect_identical(glance(d_study(d3, m = 1:3))$raters, NA_character_)
  # The occasion axis is the only one a fixed-rater agreement fit projects on,
  # so it is the only route by which that design reaches this column.
  fxa <- suppressWarnings(icc(
    replicate_frame(),
    score,
    subject,
    rater,
    raters = "fixed",
    type = "agreement",
    seed = 1
  ))
  expect_identical(glance(d_study(fxa, n_o = 1:3))$raters, "fixed")
})

test_that("the multilevel header names a rater treatment only where one exists", {
  skip_if_not_installed("glmmTMB")
  # All three multilevel designs render through the same `format.icc()` branch.
  # Design 3's raters are nested in subjects, so no rater main effect is
  # separable: its header states the rater count without a treatment word
  # (D-042). Designs 1 and 2 each keep theirs -- the controls that show the edit
  # is keyed on the design, not on the branch.
  fits <- list(
    design1 = icc(
      multilevel_replicate_frame(),
      score,
      subject,
      rater,
      cluster = cluster,
      seed = 1
    ),
    design2 = icc(
      nested_replicate_frame(),
      score,
      subject,
      rater,
      cluster = cluster,
      design = "nested_in_clusters",
      seed = 1
    ),
    design3 = icc(
      design3_frame(),
      score,
      subject,
      rater,
      cluster = cluster,
      seed = 1
    )
  )
  expect_identical(
    vapply(fits, function(x) x$design$ml_design, character(1)),
    c(
      design1 = "crossed",
      design2 = "nested_in_clusters",
      design3 = "nested_in_subjects"
    )
  )

  # The rater line, captured through cli's own sink: `print.icc()` writes via
  # cli, so `capture.output()` returns character(0) for it (M129).
  rater_line <- vapply(
    fits,
    function(x) {
      line <- grep(
        "Raters: ",
        cli::cli_fmt(print(x)),
        fixed = TRUE,
        value = TRUE
      )
      expect_length(line, 1L)
      line
    },
    character(1)
  )

  # Every design states its rater count, ...
  expect_identical(
    vapply(
      names(fits),
      function(nm) {
        grepl(
          sprintf("Raters: %d", fits[[nm]]$n$raters),
          rater_line[[nm]],
          fixed = TRUE
        )
      },
      logical(1)
    ),
    c(design1 = TRUE, design2 = TRUE, design3 = TRUE)
  )
  # ... and only the two with a separable rater main effect qualify it.
  expect_identical(
    vapply(
      rater_line,
      function(l) {
        if (grepl("(random)", l, fixed = TRUE)) {
          "random"
        } else if (grepl("(fixed)", l, fixed = TRUE)) {
          "fixed"
        } else {
          NA_character_
        }
      },
      character(1)
    ),
    c(design1 = "random", design2 = "random", design3 = NA_character_)
  )
})

test_that("summary() explains Design 3's nesting instead of a rater main effect", {
  skip_if_not_installed("glmmTMB")
  # The absolute-agreement note attributes error to a rater main effect. Design 3
  # cannot separate one -- its raters are nested in subjects -- so that note is
  # replaced there by what the nesting does (D-042). The crossed two-way
  # agreement fit is the control: it keeps the note.
  d3 <- icc(design3_frame(), score, subject, rater, cluster = cluster, seed = 1)
  crossed <- icc(ratings, score, subject, rater, type = "agreement", seed = 1)
  agreement_note <- "Absolute agreement counts the rater main effect"
  nesting_note <- "Raters nested in subjects"

  got <- vapply(
    list(design3 = d3, crossed = crossed),
    function(x) {
      out <- paste(cli::cli_fmt(summary(x)), collapse = "\n")
      c(
        agreement = grepl(agreement_note, out, fixed = TRUE),
        nesting = grepl(nesting_note, out, fixed = TRUE)
      )
    },
    logical(2)
  )
  expect_identical(
    got,
    matrix(
      c(FALSE, TRUE, TRUE, FALSE),
      nrow = 2L,
      dimnames = list(c("agreement", "nesting"), c("design3", "crossed"))
    )
  )
  # The replacement says what the nesting costs, not merely that it happened.
  expect_match(
    paste(cli::cli_fmt(summary(d3)), collapse = " "),
    "cannot be separated and are absorbed into the residual"
  )
})
