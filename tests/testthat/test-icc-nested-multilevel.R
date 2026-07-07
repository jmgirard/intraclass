# Oracle O-NML: nested-rater multilevel ICCs (Design 2), M8 --------------------
#
# Design 2 of ten Hove, Jorgensen & van der Ark (2022, Eqs. 8-9, Table 3 subject
# level, "raters nested in clusters"): each cluster has its own raters, crossed
# with that cluster's subjects. Provenance (seeded reference values and standalone
# stopifnot checks) in data-raw/oracle-nested-multilevel.R. No textbook worked
# example exists for this estimand (as with O-ML), so correctness rests on an lme4
# cross-engine fit, a seeded population-recovery simulation, and a reduction to the
# pinned two-way estimand (PRINCIPLES.md #1). Cluster-level IRR is undefined for
# nested designs (paper p. 6); this is subject-level only.

# Balanced Design-2 generator with known population components. Raters are nested
# in clusters -> rater labels are unique per cluster ("cluster_rater").
sim_design2 <- function(nc, ns, k, vc, vsc, vrc, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  rcv <- stats::rnorm(nc * k, 0, sqrt(vrc))
  d$rc <- rcv[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    d$rc +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
  d
}

pick <- function(x, index, level = "subject") {
  e <- x$estimates
  e$estimate[e$index == index & e$level == level]
}

test_that("O-NML/lme4: Design-2 ICCs match an independent lme4 fit (<1e-4)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_design2(30, 8, 6, 1.0, 1.2, 0.7, 0.5, seed = 20260707)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  xc <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "consistency",
    seed = 1
  )

  m <- lme4::lmer(
    score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater),
    data = d,
    REML = TRUE
  )
  vc <- lme4::VarCorr(m)
  sc <- as.numeric(vc[["cluster:subject"]]) # sigma^2_{s:c}
  rc <- as.numeric(vc[["cluster:rater"]]) # sigma^2_{r:c}
  re <- stats::sigma(m)^2 # sigma^2_{(sr):c}
  k <- 6

  # Table 3, subject level, raters nested in clusters (spec M8 §3a).
  expect_equal(pick(x, "ICC(A,1)"), sc / (sc + rc + re), tolerance = 1e-4)
  expect_equal(pick(x, "ICC(A,k)"), sc / (sc + (rc + re) / k), tolerance = 1e-4)
  expect_equal(pick(xc, "ICC(C,1)"), sc / (sc + re), tolerance = 1e-4)
  expect_equal(pick(xc, "ICC(C,k)"), sc / (sc + re / k), tolerance = 1e-4)
})

test_that("O-NML/sim: known Design-2 population ICC is recovered and covered", {
  skip_if_not_installed("glmmTMB")
  k <- 20
  pop <- c(subject = 1.2, rater = 0.7, residual = 0.5)
  pop_a1 <- pop[["subject"]] /
    (pop[["subject"]] + pop[["rater"]] + pop[["residual"]])
  d <- sim_design2(40, 5, k, 1.0, 1.2, 0.7, 0.5, seed = 424242)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 20260707)

  expect_lt(abs(pick(x, "ICC(A,1)") - pop_a1), 0.05)
  sub <- x$estimates[x$estimates$index == "ICC(A,1)", ]
  expect_true(sub$conf.low <= pop_a1 && pop_a1 <= sub$conf.high)
})

test_that("O-NML/reduction: Design-2 subject level is the two-way estimand", {
  # Algebraic: the Design-2 subject-level (signal, error set) is component-for-
  # component the single-level two-way estimand -- the fit just fills the "rater"
  # slot with sigma^2_{r:c} instead of sigma^2_r (spec M8 §3a/§5).
  ml <- icc_estimand(type = "agreement", level = "subject", multilevel = TRUE)
  sl <- icc_estimand(type = "agreement")
  expect_identical(ml$signal, sl$signal)
  expect_identical(ml$error, sl$error)
  mlc <- icc_estimand(
    type = "consistency",
    level = "subject",
    multilevel = TRUE
  )
  slc <- icc_estimand(type = "consistency")
  expect_identical(mlc$error, slc$error)
})

test_that("Design 2 is detected, subject-level only, with 4 components", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design2(20, 6, 4, 1.0, 1.2, 0.7, 0.5, seed = 7)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)

  expect_identical(x$design$ml_design, "nested_in_clusters")
  # Nested designs define only the subject level (even though level defaults both).
  expect_setequal(unique(x$estimates$level), "subject")
  expect_true(x$design$multilevel)
  # Four components: no separate cluster x rater term (folded into "rater" = r:c).
  expect_null(x$components$cluster_rater)
  expect_true(is.numeric(x$components$rater))
  # Average >= single; all in range; no Shrout & Fleiss label.
  expect_gte(pick(x, "ICC(A,k)"), pick(x, "ICC(A,1)"))
  expect_true(all(x$estimates$estimate >= 0 & x$estimates$estimate <= 1))
  expect_true(all(is.na(x$estimates$sf_index)))
  expect_identical(glance(x)$ml_design, "nested_in_clusters")

  # Print surfaces the inferred design and the 4-component variance line.
  out <- paste(format(x), collapse = "\n")
  expect_match(out, "raters nested in clusters")
  expect_match(out, "rater:cluster")
})

test_that("nested-design scope and identifiability guards fail loudly", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design2(20, 6, 4, 1.0, 1.2, 0.7, 0.5, seed = 7)

  # Cluster-level IRR is undefined for nested designs.
  expect_error(
    icc(d, score, subject, rater, cluster = cluster, level = "cluster"),
    class = "intraclass_unsupported"
  )
  # Incomplete / unbalanced nested design (drop one cell) is deferred.
  d_inc <- d[-1, ]
  expect_error(
    icc(d_inc, score, subject, rater, cluster = cluster),
    class = "intraclass_unsupported"
  )
  # Only one rater per cluster -> nested rater variance unidentified.
  d_solo <- d[grepl("_1$", as.character(d$rater)), ]
  expect_error(
    icc(d_solo, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
})

test_that("Design 3 (raters nested in subjects) aborts as not-yet-supported", {
  skip_if_not_installed("glmmTMB")
  # Each rater rates exactly one subject (nested in subjects and clusters).
  nc <- 6
  ns <- 4
  k <- 3
  set.seed(11)
  d <- expand.grid(
    subj = seq_len(ns),
    rep = seq_len(k),
    cluster = seq_len(nc)
  )
  d$score <- stats::rnorm(nrow(d))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$subj, d$rep, sep = "_")) # one subject/rater
  expect_error(
    icc(d, score, subject, rater, cluster = cluster),
    class = "intraclass_unsupported"
  )
})

test_that("ambiguous (mixed crossed/nested) raters abort", {
  skip_if_not_installed("glmmTMB")
  # Start crossed (shared rater ids across clusters), then confine one rater to a
  # single cluster: some raters span clusters, some do not -> not a clean design.
  set.seed(3)
  d <- expand.grid(subj = 1:4, cluster = 1:4, rater = 1:5)
  d$score <- stats::rnorm(nrow(d))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(d$rater)
  d <- d[!(d$rater == "1" & d$cluster != "1"), ] # rater 1 only in cluster 1
  expect_error(
    icc(d, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
})

test_that("crossed data still infers Design 1 (regression)", {
  skip_if_not_installed("glmmTMB")
  # Shared rater ids across clusters -> raters crossed with clusters (Design 1).
  set.seed(5)
  d <- expand.grid(subj = 1:5, cluster = 1:6, rater = 1:4)
  d$score <- stats::rnorm(nrow(d))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(d$rater)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  expect_identical(x$design$ml_design, "crossed")
  expect_setequal(unique(x$estimates$level), c("subject", "cluster"))
  expect_true(is.numeric(x$components$cluster_rater))
})
