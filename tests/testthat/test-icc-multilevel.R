# Oracle O-ML: multilevel ICCs (subject- & cluster-level), M5 -------------------
#
# Design 1 of ten Hove, Jorgensen & van der Ark (2022, Table 3): subjects nested
# in clusters, raters crossed with both. Provenance (seeded reference values and
# the standalone stopifnot checks) in data-raw/oracle-multilevel.R. No textbook
# worked example exists for this estimand (as with O5), so correctness rests on
# an lme4 cross-engine fit, a seeded population-recovery simulation, and a
# reduction to the pinned single-level numbers (PRINCIPLES.md #1).

# Balanced Design-1 generator with known population components.
sim_multilevel <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rt <- stats::rnorm(k, 0, sqrt(vr))
  d <- expand.grid(
    subj = seq_len(ns),
    cluster = seq_len(nc),
    rater = seq_len(k)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  crv <- stats::rnorm(nc * k, 0, sqrt(vcr))
  d$cr <- crv[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rt[d$rater] +
    d$cr +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

# Pull one coefficient out of the estimates table by index + level.
pick <- function(x, index, level) {
  e <- x$estimates
  e$estimate[e$index == index & e$level == level]
}

test_that("O-ML/lme4: multilevel ICCs match an independent lme4 fit (<1e-4)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)

  m <- lme4::lmer(
    score ~
      1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE
  )
  vc <- lme4::VarCorr(m)
  cl <- as.numeric(vc$cluster)
  sc <- as.numeric(vc[["cluster:subject"]])
  ra <- as.numeric(vc$rater)
  cr <- as.numeric(vc[["cluster:rater"]])
  re <- stats::sigma(m)^2
  k <- 6

  expect_equal(
    pick(x, "ICC(A,1)", "subject"),
    sc / (sc + ra + re),
    tolerance = 1e-4
  )
  expect_equal(
    pick(x, "ICC(A,k)", "subject"),
    sc / (sc + (ra + re) / k),
    tolerance = 1e-4
  )
  expect_equal(
    pick(x, "ICC(A,1)", "cluster"),
    cl / (cl + ra + cr),
    tolerance = 1e-4
  )
  expect_equal(
    pick(x, "ICC(A,k)", "cluster"),
    cl / (cl + (ra + cr) / k),
    tolerance = 1e-4
  )

  # Consistency variants read the same fit (residual -> cluster_rater at cluster).
  xc <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "consistency",
    seed = 1
  )
  expect_equal(
    pick(xc, "ICC(C,1)", "subject"),
    sc / (sc + re),
    tolerance = 1e-4
  )
  expect_equal(
    pick(xc, "ICC(C,1)", "cluster"),
    cl / (cl + cr),
    tolerance = 1e-4
  )
})

test_that("O-ML/sim: known population ICCs are recovered and covered", {
  skip_if_not_installed("glmmTMB")
  k <- 20
  pop <- c(
    cluster = 1.0,
    subject = 1.2,
    rater = 0.7,
    cluster_rater = 0.16,
    residual = 0.5
  )
  pop_subj_a1 <- pop[["subject"]] /
    (pop[["subject"]] + pop[["rater"]] + pop[["residual"]])
  pop_clus_a1 <- pop[["cluster"]] /
    (pop[["cluster"]] + pop[["rater"]] + pop[["cluster_rater"]])
  d <- sim_multilevel(40, 5, k, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 424242)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 20260707)

  # Absolute recovery tolerance (expect_equal's `tolerance` is relative).
  expect_lt(abs(pick(x, "ICC(A,1)", "subject") - pop_subj_a1), 0.05)
  expect_lt(abs(pick(x, "ICC(A,1)", "cluster") - pop_clus_a1), 0.05)

  # The boundary-aware Monte-Carlo interval covers both population values.
  e <- x$estimates
  sub <- e[e$index == "ICC(A,1)" & e$level == "subject", ]
  clu <- e[e$index == "ICC(A,1)" & e$level == "cluster", ]
  expect_true(sub$conf.low <= pop_subj_a1 && pop_subj_a1 <= sub$conf.high)
  expect_true(clu$conf.low <= pop_clus_a1 && pop_clus_a1 <= clu$conf.high)
})

test_that("O-ML/reduction: subject level is the single-level estimand", {
  # Algebraic: the subject-level (signal, error set) equals the single-level one.
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

test_that("O-ML/reduction: zero cluster variance reduces to single-level", {
  skip_if_not_installed("glmmTMB")
  # sigma^2_c = sigma^2_cr = 0, many clusters: subject-level ICC matches a
  # single-level two-way fit on the same ratings (M5 spec §5). No exact-SF claim.
  d <- sim_multilevel(40, 8, 6, 0, 1.2, 0.7, 0, 0.5, seed = 99)
  x_ml <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    seed = 1
  )
  x_sl <- icc(d, score, subject, rater, seed = 1)
  expect_equal(
    pick(x_ml, "ICC(A,1)", "subject"),
    x_sl$estimates$estimate[x_sl$estimates$index == "ICC(A,1)"],
    tolerance = 1e-2
  )
})

test_that("multilevel invariants and object shape", {
  skip_if_not_installed("glmmTMB")
  d <- sim_multilevel(20, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 7)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  e <- x$estimates
  # Both levels returned by default; a level column disambiguates them.
  expect_setequal(unique(e$level), c("subject", "cluster"))
  expect_true(all(e$estimate >= 0 & e$estimate <= 1))
  # Average >= single at each level (Spearman-Brown direction).
  expect_gte(pick(x, "ICC(A,k)", "subject"), pick(x, "ICC(A,1)", "subject"))
  expect_gte(pick(x, "ICC(A,k)", "cluster"), pick(x, "ICC(A,1)", "cluster"))
  # Multilevel ICCs carry no Shrout & Fleiss label.
  expect_true(all(is.na(e$sf_index)))
  expect_true(x$design$multilevel)
  expect_identical(x$n$clusters, 20L)

  # A single requested level returns only that level.
  xs <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "cluster",
    seed = 1
  )
  expect_setequal(unique(xs$estimates$level), "cluster")
})

test_that("multilevel identifiability and scope guards fail loudly", {
  skip_if_not_installed("glmmTMB")
  d <- sim_multilevel(20, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 7)

  # < 2 clusters.
  d1 <- d[d$cluster == "1", ]
  expect_error(
    icc(d1, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
  # cluster 1:1 with subject (one subject per cluster) -> unidentified.
  d2 <- d[d$subj == 1, ]
  expect_error(
    icc(d2, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
  # a subject that spans two clusters breaks the nesting assumption.
  d3 <- d
  d3$subject <- factor(d3$subj) # ids reused across clusters
  expect_error(
    icc(d3, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
  # fixed raters and numeric unit are out of multilevel scope (M5).
  expect_error(
    icc(d, score, subject, rater, cluster = cluster, raters = "fixed"),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(d, score, subject, rater, cluster = cluster, unit = c("single", 3)),
    class = "intraclass_unsupported"
  )
  # level without a cluster column is a usage error.
  expect_error(
    icc(ratings, score, subject, rater, level = "cluster"),
    class = "intraclass_error"
  )
})
