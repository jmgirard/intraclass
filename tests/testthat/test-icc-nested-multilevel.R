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
  # Incomplete / unbalanced nested design now fits (M19 Slice 1): dropping a cell
  # from an otherwise-clear nested layout is still unambiguously nested, so it is
  # detected and estimated rather than aborted.
  d_inc <- d[-1, ]
  x_inc <- icc(d_inc, score, subject, rater, cluster = cluster, seed = 1)
  expect_identical(x_inc$design$ml_design, "nested_in_clusters")
  expect_false(x_inc$design$balanced)
  # Only one rater per cluster -> nested rater variance unidentified.
  d_solo <- d[grepl("_1$", as.character(d$rater)), ]
  expect_error(
    icc(d_solo, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
})

# Balanced Design-3 generator (raters nested in subjects): each subject has its
# own raters. Components sigma^2_c / sigma^2_{s:c} / sigma^2_{r:s:c} (rater
# confounded into residual).
sim_design3 <- function(nc, ns, k, vc, vsc, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  d <- expand.grid(rep = seq_len(k), subj = seq_len(ns), cluster = seq_len(nc))
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  d$score <- 10 + cl[d$cluster] + d$sc + stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$subj, d$rep, sep = "_"))
  d
}

test_that("O-NML/lme4: Design-3 ICCs match an independent lme4 fit (<1e-4)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_design3(30, 8, 6, 1.0, 1.2, 0.5, seed = 20260707)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)

  m <- lme4::lmer(
    score ~ 1 + (1 | cluster) + (1 | cluster:subject),
    data = d,
    REML = TRUE
  )
  vc <- lme4::VarCorr(m)
  sc <- as.numeric(vc[["cluster:subject"]]) # sigma^2_{s:c}
  re <- stats::sigma(m)^2 # sigma^2_{r:s:c}
  k <- 6

  # Table 3, subject level, raters nested in subjects: agreement-only (spec §3b).
  expect_equal(pick(x, "ICC(1)"), sc / (sc + re), tolerance = 1e-4)
  expect_equal(pick(x, "ICC(k)"), sc / (sc + re / k), tolerance = 1e-4)
})

test_that("O-NML/reduction: Design 3 reduces to the M6 one-way ICC(1)", {
  skip_if_not_installed("glmmTMB")
  # sigma^2_c = 0, many clusters: Design 3 (raters nested in subjects) IS a
  # single-level one-way design once cluster is ignored, so its subject-level
  # ICC(1) matches icc(model = "oneway") on the same ratings (spec M8 §5).
  d <- sim_design3(50, 20, 6, 0, 1.2, 0.5, seed = 99)
  x_ml <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  x_ow <- icc(d, score, subject, rater, model = "oneway", seed = 1)
  expect_equal(
    pick(x_ml, "ICC(1)"),
    x_ow$estimates$estimate[x_ow$estimates$index == "ICC(1)"],
    tolerance = 1e-2
  )
})

test_that("Design 3 is detected: agreement-only, 3 components, no A/C label", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design3(20, 6, 4, 1.0, 1.2, 0.5, seed = 7)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)

  expect_identical(x$design$ml_design, "nested_in_subjects")
  expect_setequal(unique(x$estimates$level), "subject")
  # One-way-style labels ICC(1)/ICC(k), not ICC(A,*); no rater component.
  expect_setequal(x$estimates$index, c("ICC(1)", "ICC(k)"))
  expect_null(x$components$rater)
  expect_null(x$components$cluster_rater)
  expect_true(is.numeric(x$components$cluster))
  expect_gte(pick(x, "ICC(k)"), pick(x, "ICC(1)"))
  expect_true(all(is.na(x$estimates$sf_index)))
  expect_identical(glance(x)$ml_design, "nested_in_subjects")

  # Consistency is undefined for Design 3.
  expect_error(
    icc(d, score, subject, rater, cluster = cluster, type = "consistency"),
    class = "intraclass_unsupported"
  )
  # A subject rated only once cannot separate residual from subject variance.
  d_thin <- d[!duplicated(paste(d$subject)), ] # one rating per subject
  expect_error(
    icc(d_thin, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )

  # Print surfaces the design and the rater-confounded variance line.
  out <- paste(format(x), collapse = "\n")
  expect_match(out, "raters nested in subjects")
  expect_match(out, "rater confounded")
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

# Incomplete (ragged) nested designs -- M19 Slice 1 (ADR-029) ------------------
#
# M8 shipped balanced/complete nested designs; M19 Slice 1 lifts the balance guard.
# The fit formulas are unchanged and the averaging divisor is the harmonic-mean
# k_eff (ratings per subject), which reduces EXACTLY to the pinned M3 two-way / M6
# one-way incomplete divisor (data-raw/oracle-nested-multilevel.R: ragged
# single-cluster Design 2 == ragged two-way for all four coefficients, diff 0;
# ragged Design 3 == ragged one-way). Correctness here rests on the cross-engine
# fit (glmmTMB the independent oracle for lme4), the Design-3 -> one-way reduction,
# seeded recovery, and the balanced no-op regression (PRINCIPLES.md #1).

# Drop a random fraction of subject x rater cells, restoring any subject that falls
# below 2 ratings (subject-vs-residual identifiability), then droplevels().
drop_cells <- function(d, frac, seed) {
  set.seed(seed)
  keep <- rep(TRUE, nrow(d))
  keep[sample(nrow(d), floor(frac * nrow(d)))] <- FALSE
  repeat {
    tab <- table(d$subject[keep])
    bad <- names(tab)[tab < 2L]
    if (length(bad) == 0L) {
      break
    }
    for (s in bad) {
      cand <- which(!keep & d$subject == s)
      if (length(cand)) keep[cand[1L]] <- TRUE
    }
  }
  droplevels(d[keep, , drop = FALSE])
}

test_that("O-NML/incomplete: ragged Design 2 matches lme4 cross-engine (<1e-4)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")
  d <- drop_cells(
    sim_design2(30, 8, 6, 1.0, 1.2, 0.7, 0.5, seed = 20260708),
    0.25,
    11
  )
  # Genuinely ragged (unequal ratings per subject), still detected as Design 2.
  expect_false(
    icc(d, score, subject, rater, cluster = cluster, seed = 1)$design$balanced
  )

  xg <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  xl <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lme4",
    seed = 1
  )
  # Point estimates agree across engines for both single and averaged coefficients
  # (the averaged one exercises the k_eff divisor on ragged data).
  merged <- merge(
    xg$estimates[c("index", "estimate")],
    xl$estimates[c("index", "estimate")],
    by = "index"
  )
  expect_lt(max(abs(merged$estimate.x - merged$estimate.y)), 1e-4)
})

test_that("O-NML/incomplete: ragged Design 2 k_eff is the harmonic mean of ratings", {
  skip_if_not_installed("glmmTMB")
  d <- drop_cells(
    sim_design2(30, 8, 6, 1.0, 1.2, 0.7, 0.5, seed = 20260708),
    0.25,
    11
  )
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  # Averaged coefficient divides the error by k_eff; reconstruct it from the
  # reported components and check it equals ICC(A,k). Ties the averaged divisor to
  # the (independently pinned, M3) harmonic-mean k_eff on ragged nested data.
  k_eff <- 1 / mean(1 / as.integer(table(d$subject)))
  cmp <- x$components
  ak <- cmp$subject / (cmp$subject + (cmp$rater + cmp$residual) / k_eff)
  expect_equal(pick(x, "ICC(A,k)"), ak, tolerance = 1e-8)
})

test_that("O-NML/incomplete: balanced data is a no-op (M8 numbers unchanged)", {
  skip_if_not_installed("glmmTMB")
  # The lifted balance guard must not perturb the balanced/complete path: a complete
  # Design 2 gives identical estimates whether or not the incomplete gates run.
  d <- sim_design2(20, 6, 4, 1.0, 1.2, 0.7, 0.5, seed = 7)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  expect_true(x$design$balanced)
  m <- lme4::lmer(
    score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater),
    data = d,
    REML = TRUE
  )
  vc <- lme4::VarCorr(m)
  sc <- as.numeric(vc[["cluster:subject"]])
  rc <- as.numeric(vc[["cluster:rater"]])
  re <- stats::sigma(m)^2
  expect_equal(pick(x, "ICC(A,1)"), sc / (sc + rc + re), tolerance = 1e-4)
  expect_equal(pick(x, "ICC(A,k)"), sc / (sc + (rc + re) / 4), tolerance = 1e-4)
})

test_that("O-NML/incomplete: ragged Design 3 reduces to the incomplete one-way", {
  skip_if_not_installed("glmmTMB")
  # sigma^2_c = 0, many clusters, missing cells: ragged Design 3 is a ragged
  # single-level one-way once cluster is ignored, so ICC(1) AND ICC(k) match
  # icc(model = "oneway") on the same ratings (the one-way k_eff is also the
  # harmonic mean, so the averaged divisors coincide) -- ties the ragged nested
  # divisor to the pinned M6 incomplete one-way.
  d <- drop_cells(sim_design3(50, 20, 6, 0, 1.2, 0.5, seed = 99), 0.25, 7)
  x_ml <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  x_ow <- icc(d, score, subject, rater, model = "oneway", seed = 1)
  ow <- function(i) x_ow$estimates$estimate[x_ow$estimates$index == i]
  expect_equal(pick(x_ml, "ICC(1)"), ow("ICC(1)"), tolerance = 1e-2)
  expect_equal(pick(x_ml, "ICC(k)"), ow("ICC(k)"), tolerance = 1e-2)
})

test_that("incomplete nested d_study projects the subject level (M18 path)", {
  skip_if_not_installed("glmmTMB")
  # Lifting the balance guard makes incomplete-nested d_study() reachable: nested
  # designs are subject-level only, so the M18 Slice 3 subject-level projection
  # applies unchanged. The curve is monotone increasing and equals ICC(A,1) at m = 1.
  d <- drop_cells(
    sim_design2(30, 8, 6, 1.0, 1.2, 0.7, 0.5, seed = 20260708),
    0.25,
    11
  )
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  ds <- as.data.frame(d_study(x, m = c(1, 4, 8)))
  expect_setequal(unique(ds$level), "subject")
  expect_equal(ds$estimate[ds$m == 1], pick(x, "ICC(A,1)"), tolerance = 1e-8)
  expect_true(all(diff(ds$estimate) > 0))
})

test_that("decision A: ambiguous ragged nesting requires an explicit design=", {
  skip_if_not_installed("glmmTMB")
  # Confine every rater to one cluster (nested), then drop cells so one rater ends
  # up rating a single subject -> auto-detection can no longer tell Design 2 from
  # Design 3 and aborts, pointing at design=. Declaring it lets the fit proceed.
  d <- sim_design2(8, 6, 4, 1.0, 1.2, 0.7, 0.5, seed = 21)
  # Remove all but one subject for rater "1_1": it now rates a single subject.
  r11 <- d$rater == "1_1"
  keep_one <- r11 & d$subject != "1_1"
  d_amb <- d[!keep_one, ]
  expect_error(
    icc(d_amb, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
  # Declaring the design resolves the ambiguity (validated against the data).
  x <- icc(
    d_amb,
    score,
    subject,
    rater,
    cluster = cluster,
    design = "nested_in_clusters",
    seed = 1
  )
  expect_identical(x$design$ml_design, "nested_in_clusters")
  expect_false(x$design$balanced)
})

test_that("ragged nested design that disconnects a cluster aborts (identifiability)", {
  skip_if_not_installed("glmmTMB")
  # Split one cluster's raters and subjects into two non-overlapping blocks: that
  # cluster's subject x rater graph is disconnected, so sigma^2_{s:c} cannot be
  # separated from residual there -- a classed abort, not a silent number.
  d <- sim_design2(6, 6, 4, 1.0, 1.2, 0.7, 0.5, seed = 31)
  c1 <- d$cluster == "1"
  # In cluster 1: raters 1_1/1_2 rate subjects 1_1..1_3; raters 1_3/1_4 rate
  # subjects 1_4..1_6 -> two disconnected blocks.
  block_a <- c1 &
    d$rater %in% c("1_1", "1_2") &
    d$subject %in% c("1_4", "1_5", "1_6")
  block_b <- c1 &
    d$rater %in% c("1_3", "1_4") &
    d$subject %in% c("1_1", "1_2", "1_3")
  d_disc <- d[!(block_a | block_b), ]
  expect_error(
    icc(
      d_disc,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "nested_in_clusters"
    ),
    class = "intraclass_unidentified"
  )
})
