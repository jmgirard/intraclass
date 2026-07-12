# Vectorized `type` (ADR-054) --------------------------------------------------
#
# `type` is vectorizable like `unit`/`level` and defaults to reporting BOTH error
# definitions, so a default two-way icc() returns all four formulations (A1/Ak/C1/Ck)
# from ONE fit. `type` never reaches an engine (agreement vs. consistency is post-fit
# arithmetic on the same variance components), so the second type must reproduce the
# scalar-`type` call cell-for-cell -- the number-invariance oracle (cf. ADR-053). The
# undefined-by-design cells inform-and-drop when defaulted in but keep their classed
# teaching abort when named explicitly (#5; ADR-029 precedent).

# A crossed Design-1 multilevel generator (subject + cluster levels defined).
ml_ratings <- function(seed = 20260712) {
  set.seed(seed)
  nc <- 12
  ns <- 8
  k <- 4
  cl <- stats::rnorm(nc, 0, 1)
  rt <- stats::rnorm(k, 0, sqrt(0.7))
  d <- expand.grid(
    rater = seq_len(k),
    subj = seq_len(ns),
    cluster = seq_len(nc)
  )
  d$sc <- stats::rnorm(nc * ns, 0, sqrt(1.2))[(d$cluster - 1) * ns + d$subj]
  d$cr <- stats::rnorm(nc * k, 0, sqrt(0.16))[(d$cluster - 1) * k + d$rater]
  d$score <- cl[d$cluster] +
    d$sc +
    rt[d$rater] +
    d$cr +
    stats::rnorm(nrow(d), 0, sqrt(0.5))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

# A Design-3 generator (raters nested in subjects): agreement-only, consistency
# undefined (the rater main effect is confounded into residual).
design3_ratings <- function(seed = 20260712) {
  set.seed(seed)
  nc <- 10
  ns <- 8
  k <- 5
  cl <- stats::rnorm(nc, 0, 1)
  d <- expand.grid(rep = seq_len(k), subj = seq_len(ns), cluster = seq_len(nc))
  d$sc <- stats::rnorm(nc * ns, 0, sqrt(1.2))[(d$cluster - 1) * ns + d$subj]
  d$score <- cl[d$cluster] + d$sc + stats::rnorm(nrow(d), 0, sqrt(0.5))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$subj, d$rep, sep = "_"))
  d
}

# For a design, assert the defaulted `type` vector reproduces the two scalar-type
# calls cell-for-cell: same rows, same point estimate, same (seeded) CI bounds.
expect_type_invariant <- function(both, agr, con) {
  bt <- both$estimates
  for (part in list(agr, con)) {
    sc <- part$estimates
    for (i in seq_len(nrow(sc))) {
      hit <- bt$index == sc$index[i] &
        bt$type == sc$type[i] &
        (is.na(bt$level) | bt$level == sc$level[i])
      row <- bt[hit, , drop = FALSE]
      testthat::expect_equal(nrow(row), 1L)
      testthat::expect_equal(row$estimate, sc$estimate[i], tolerance = 1e-12)
      testthat::expect_equal(row$conf.low, sc$conf.low[i], tolerance = 1e-12)
      testthat::expect_equal(row$conf.high, sc$conf.high[i], tolerance = 1e-12)
    }
  }
}

test_that("a default two-way call reports all four formulations from one fit", {
  skip_if_not_installed("glmmTMB")
  x <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  expect_setequal(
    x$estimates$index,
    c("ICC(A,1)", "ICC(A,k)", "ICC(C,1)", "ICC(C,k)")
  )
  # Rows are type-major (all agreement, then all consistency).
  expect_identical(
    x$estimates$type,
    c("agreement", "agreement", "consistency", "consistency")
  )
  # tidy() carries the per-row type; a one-way fit records type = NA (no type axis).
  expect_true("type" %in% names(tidy(x)))
  ow <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    model = "oneway",
    seed = 1
  )
  expect_true(all(is.na(tidy(ow)$type)))
})

test_that("validate_type mirrors validate_unit: dedup, order, classed abort", {
  expect_identical(
    validate_type(c("agreement", "consistency")),
    c("agreement", "consistency")
  )
  expect_identical(
    validate_type(c("consistency", "consistency")),
    "consistency"
  )
  expect_identical(validate_type("agreement"), "agreement")
  expect_error(validate_type("foo"), class = "intraclass_error")
  expect_error(validate_type(character(0)), class = "intraclass_error")
})

test_that("the defaulted vector reproduces scalar-type calls cell-for-cell (O-invariance)", {
  skip_if_not_installed("glmmTMB")
  # Two-way random and fixed, complete and incomplete -- every cell both types define.
  cases <- list(
    list(data = quote(sf_ratings_long()), args = list()),
    list(data = quote(sf_ratings_long()), args = list(raters = "fixed")),
    list(data = quote(ratings_incomplete), args = list()),
    list(
      data = quote(ratings_incomplete),
      args = list(unit = c("single", "average"))
    )
  )
  for (cs in cases) {
    d <- eval(cs$data)
    call_icc <- function(ty) {
      do.call(
        icc,
        c(
          list(
            d,
            quote(score),
            quote(subject),
            quote(rater),
            seed = 1,
            type = ty
          ),
          cs$args
        )
      )
    }
    both <- suppressWarnings(call_icc(c("agreement", "consistency")))
    agr <- suppressWarnings(call_icc("agreement"))
    con <- suppressWarnings(call_icc("consistency"))
    expect_type_invariant(both, agr, con)
  }
})

test_that("O-invariance holds at the multilevel subject and cluster levels", {
  skip_if_not_installed("glmmTMB")
  d <- ml_ratings()
  both <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  agr <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "agreement",
    seed = 1
  )
  con <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "consistency",
    seed = 1
  )
  expect_type_invariant(both, agr, con)
  # Both levels carry both error definitions.
  expect_setequal(unique(both$estimates$type), c("agreement", "consistency"))
  expect_setequal(unique(both$estimates$level), c("subject", "cluster"))
})

test_that("O-invariance holds across engines (lme4)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")
  call_icc <- function(ty) {
    suppressWarnings(icc(
      sf_ratings_long(),
      score,
      subject,
      rater,
      engine = "lme4",
      type = ty,
      seed = 1
    ))
  }
  expect_type_invariant(
    call_icc(c("agreement", "consistency")),
    call_icc("agreement"),
    call_icc("consistency")
  )
})

# --- drop-vs-abort policy per agreement-only surface (ADR-054) -----------------

test_that("conflated: default reports both types (M45); explicit consistency ships", {
  skip_if_not_installed("glmmTMB")
  d <- ml_ratings()
  withr::local_options(rlib_message_verbosity = "verbose")
  # M45/ADR-056: consistency-conflated now ships (the flat two-way consistency ICC),
  # so the default vector no longer drops it -- no "Dropping ... consistency conflated".
  expect_no_message(
    x <- icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = c("subject", "cluster", "conflated"),
      seed = 1
    ),
    message = "Dropping the .*consistency.* conflated"
  )
  e <- x$estimates
  # Conflated now carries both types, like subject/cluster.
  expect_setequal(e$type[e$level == "conflated"], c("agreement", "consistency"))
  expect_setequal(e$type[e$level == "subject"], c("agreement", "consistency"))
  # Explicit consistency at the conflated level now computes (was a classed abort).
  x2 <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    type = "consistency",
    seed = 1
  )
  expect_setequal(x2$estimates$type, "consistency")
  expect_true(all(x2$estimates$level == "conflated"))
})

test_that("Design 3: default drops consistency design-wide, explicit consistency aborts", {
  skip_if_not_installed("glmmTMB")
  d <- design3_ratings()
  withr::local_options(rlib_message_verbosity = "verbose")
  expect_message(
    x <- suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      seed = 1
    )),
    "Dropping .*consistency.*nested within"
  )
  # Design 3 is the multilevel one-way: agreement survives as ICC(1)/ICC(k) (type NA),
  # and no consistency coefficient is reported.
  expect_setequal(x$estimates$index, c("ICC(1)", "ICC(k)"))
  expect_false(any(grepl("C,", x$estimates$index, fixed = TRUE)))
  expect_error(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      type = "consistency"
    )),
    class = "intraclass_unsupported"
  )
})

test_that("connectedness: non-bridging raters drop agreement, keep consistency (guard 4)", {
  skip_if_not_installed("glmmTMB")
  # Raters 1-2 rate only cluster 1, raters 3-4 only cluster 2: no rater bridges
  # clusters, so the rater main-effect variance is unidentified for absolute agreement
  # (the design is effectively rater-nested for agreement), while consistency is fine.
  # This surface is not enumerated in ADR-054; it is resolved by the ADR-029 precedent.
  set.seed(1)
  d <- rbind(
    expand.grid(subject = 1:4, rater = 1:2, cluster = 1),
    expand.grid(subject = 5:8, rater = 3:4, cluster = 2)
  )
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  d$cluster <- factor(d$cluster)
  d$score <- stats::rnorm(nrow(d))
  withr::local_options(rlib_message_verbosity = "verbose")
  expect_message(
    x <- icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "crossed",
      level = "subject",
      seed = 1
    ),
    "Dropping .*agreement.*bridge clusters"
  )
  expect_setequal(unique(x$estimates$type), "consistency")
  # Explicit agreement on the same design still aborts loudly.
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "crossed",
      level = "subject",
      type = "agreement"
    ),
    class = "intraclass_unidentified"
  )
})

test_that("fixed numeric-unit agreement: default drops the projection, explicit aborts", {
  skip_if_not_installed("glmmTMB")
  withr::local_options(rlib_message_verbosity = "verbose")
  # Defaulted: agreement is dropped for the numeric (projection) unit, kept for average.
  expect_message(
    x <- suppressWarnings(icc(
      sf_ratings_long(),
      score,
      subject,
      rater,
      raters = "fixed",
      unit = c("average", 6),
      seed = 1
    )),
    "Dropping the .*agreement.* D-study projection"
  )
  e <- x$estimates
  expect_true(any(e$type == "agreement" & e$index == "ICC(A,k)"))
  expect_false(any(e$type == "agreement" & grepl("ICC\\(A,6\\)", e$index)))
  expect_true(any(e$type == "consistency"))
  # Explicit agreement + numeric unit + fixed still aborts.
  expect_error(
    icc(
      sf_ratings_long(),
      score,
      subject,
      rater,
      raters = "fixed",
      type = "agreement",
      unit = 6
    ),
    class = "intraclass_unidentified"
  )
})
