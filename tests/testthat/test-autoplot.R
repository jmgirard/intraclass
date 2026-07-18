# test-autoplot.R
# ===========================================================================
# Plot methods for `icc` objects (M11, ADR-020) -- and backfill coverage for
# the M4.5 `autoplot.icc_dstudy` reliability curve.
#
# There is no estimand and no new number here (PRINCIPLES.md #1 is numerically
# N/A): a plot method is correct iff it FAITHFULLY RENDERS the object's already
# oracle-pinned `$estimates` / `$components`. So we do not snapshot images
# (platform/font/version-fragile). Instead we build the plot with
# `ggplot2::ggplot_build()` and assert the rendered layer data equals the source
# object's numbers. See ADR-020.
# ===========================================================================

# A small multilevel (Design 1) fixture -- enough clusters/subjects for a clean
# five-component fit, mirroring test-icc-multilevel.R's simulator.
sim_ml_small <- function(seed = 20260707) {
  set.seed(seed)
  nc <- 12
  ns <- 6
  k <- 4
  cl <- stats::rnorm(nc, 0, 1)
  rt <- stats::rnorm(k, 0, sqrt(0.7))
  d <- expand.grid(
    subj = seq_len(ns),
    cluster = seq_len(nc),
    rater = seq_len(k)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(1.2))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  crv <- stats::rnorm(nc * k, 0, sqrt(0.16))
  d$cr <- crv[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rt[d$rater] +
    d$cr +
    stats::rnorm(nrow(d), 0, sqrt(0.5))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

# A small nested Design 2 (raters nested in clusters): rater labels unique per
# cluster, so the fit has a rater:cluster term and no crossed cluster:rater.
sim_design2_small <- function(seed = 20260707) {
  set.seed(seed)
  nc <- 12
  ns <- 6
  k <- 4
  cl <- stats::rnorm(nc, 0, 1)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(1.2))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  rcv <- stats::rnorm(nc * k, 0, sqrt(0.7))
  d$rc <- rcv[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    d$rc +
    stats::rnorm(nrow(d), 0, sqrt(0.5))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
  d
}

# Pull a built layer's data out of a ggplot (1 = linerange/ribbon/col, 2 = point).
built_layer <- function(p, i) ggplot2::ggplot_build(p)$data[[i]]

test_that("coefficient plot renders every estimate as a point (two-way)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    unit = c("single", "average"),
    seed = 1
  )
  p <- ggplot2::autoplot(fit)
  expect_s3_class(p, "ggplot")

  pts <- built_layer(p, 2)
  expect_equal(sort(pts$x), sort(fit$estimates$estimate))
})

test_that("coefficient plot CI band equals the object's conf.low/conf.high", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    unit = c("single", "average"),
    seed = 1
  )
  eb <- built_layer(ggplot2::autoplot(fit), 1)
  expect_equal(sort(eb$xmin), sort(fit$estimates$conf.low))
  expect_equal(sort(eb$xmax), sort(fit$estimates$conf.high))
})

test_that("coefficient plot covers one-way objects", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    model = "oneway",
    unit = c("single", "average"),
    seed = 1
  )
  pts <- built_layer(ggplot2::autoplot(fit), 2)
  expect_equal(sort(pts$x), sort(fit$estimates$estimate))
})

test_that("multilevel coefficient plot facets by level and renders all rows", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sim_ml_small(),
    score,
    subject,
    rater,
    cluster = cluster,
    unit = c("single", "average"),
    seed = 1
  )
  p <- ggplot2::autoplot(fit)
  # Faceted by level: more than one PANEL in the built layout.
  n_panels <- length(unique(ggplot2::ggplot_build(p)$data[[2]]$PANEL))
  expect_gt(n_panels, 1)
  # Every subject- and cluster-level estimate is drawn.
  pts <- built_layer(p, 2)
  expect_equal(sort(pts$x), sort(fit$estimates$estimate))
})

test_that("invalid `what` fails loudly with a classed intraclass error", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  expect_error(
    ggplot2::autoplot(fit, what = "nonsense"),
    class = "intraclass_error"
  )
})

# --- what = "components": the variance-component decomposition -----------------

# Bar heights of the `geom_col` layer (component decomposition has one layer).
bar_heights <- function(p) sort(built_layer(p, 1)$y)

test_that("components plot bar heights equal $components (two-way)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  p <- ggplot2::autoplot(fit, what = "components")
  expect_s3_class(p, "ggplot")
  expect_equal(
    bar_heights(p),
    sort(c(
      fit$components$subject,
      fit$components$rater,
      fit$components$residual
    ))
  )
})

test_that("components plot folds rater into residual for one-way (two bars)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    model = "oneway",
    seed = 1
  )
  p <- ggplot2::autoplot(fit, what = "components")
  expect_equal(
    bar_heights(p),
    sort(c(fit$components$subject, fit$components$residual))
  )
})

test_that("components plot shows all five terms for multilevel Design 1", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(sim_ml_small(), score, subject, rater, cluster = cluster, seed = 1)
  p <- ggplot2::autoplot(fit, what = "components")
  expect_equal(
    bar_heights(p),
    sort(c(
      fit$components$cluster,
      fit$components$subject,
      fit$components$rater,
      fit$components$cluster_rater,
      fit$components$residual
    ))
  )
})

test_that("components plot handles a nested design (Design 2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sim_design2_small(),
    score,
    subject,
    rater,
    cluster = cluster,
    seed = 1
  )
  p <- ggplot2::autoplot(fit, what = "components")
  # Design 2: cluster:rater is confounded; the rater slot holds sigma^2_{r:c}.
  expect_null(fit$components$cluster_rater)
  expect_equal(
    bar_heights(p),
    sort(c(
      fit$components$cluster,
      fit$components$subject,
      fit$components$rater,
      fit$components$residual
    ))
  )
})

test_that("plot.icc returns its input invisibly", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  expect_invisible(plot(fit))
})

test_that("autoplot.icc_dstudy renders each projected curve faithfully", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    unit = c("single", "average"),
    seed = 1
  )
  ds <- d_study(fit, m = 1:5, seed = 1) # two curves: agreement + consistency
  p <- ggplot2::autoplot(ds)
  expect_s3_class(p, "ggplot")

  line <- built_layer(p, 2) # geom_line
  # Every projected (m, estimate) point is drawn, across both curves.
  expect_equal(
    sort(paste(line$x, round(line$y, 8))),
    sort(paste(ds$m, round(ds$estimate, 8)))
  )
  ribbon <- built_layer(p, 1) # geom_ribbon
  expect_equal(sort(round(ribbon$ymin, 8)), sort(round(ds$conf.low, 8)))
  expect_equal(sort(round(ribbon$ymax, 8)), sort(round(ds$conf.high, 8)))
})

test_that("autoplot.icc_dstudy draws overlaid curves as separate lines", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    unit = c("single", "average"),
    seed = 1
  )
  ds <- d_study(fit, m = 1:5, seed = 1)
  line <- built_layer(ggplot2::autoplot(ds), 2)
  # Agreement and consistency are two grouped lines, not one line zigzagging
  # between them (the pre-M61 sawtooth).
  expect_equal(length(unique(line$group)), 2L)
  # Within each group the x-sequence is monotone (a proper left-to-right curve).
  for (g in unique(line$group)) {
    expect_false(is.unsorted(line$x[line$group == g]))
  }
})

test_that("autoplot.icc_dstudy separates replicate occasion curves too", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  # A within-cell replicate fit projects one curve per occasion setting; on the
  # rater axis those must not be connected into a sawtooth either (the `occasions`
  # series dimension, not just `type`).
  set.seed(42)
  ns <- 25
  k <- 4
  reps <- 3
  d <- expand.grid(subject = seq_len(ns), rater = seq_len(k), r = seq_len(reps))
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  sv <- stats::rnorm(ns, 0, 1.2)
  rv <- stats::rnorm(k, 0, 0.8)
  d$score <- 10 + sv[d$subject] + rv[d$rater] + stats::rnorm(nrow(d), 0, 0.6)
  fit <- icc(
    d,
    score,
    subject,
    rater,
    occasions = c("single", "average"),
    type = "consistency",
    seed = 1
  )
  ds <- d_study(fit, m = 1:3, seed = 1)
  expect_gt(length(unique(ds$occasions)), 1L) # fixture has >1 occasion curve
  line <- built_layer(ggplot2::autoplot(ds), 2)
  # One grouped line per occasion setting, each monotone in x.
  expect_equal(length(unique(line$group)), length(unique(ds$occasions)))
  for (g in unique(line$group)) {
    expect_false(is.unsorted(line$x[line$group == g]))
  }
})

# --- M61 polish: shared theme, colourblind-safe palette, value labels ---------
# These structural assertions pin the polish (theme applied, palette fills, label
# text == the object's numbers); the faithful-rendering tests above pin that the
# polish did not disturb what each layer draws (ADR-020: no image snapshots).

test_that("all three views carry the house theme (icc_theme fingerprint)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    unit = c("single", "average"),
    seed = 1
  )
  ds <- d_study(fit, m = 1:5, seed = 1)
  # plot.title.position = "plot" is icc_theme()'s fingerprint (ggplot2's default
  # is "panel"); assert it on each of the three views.
  expect_identical(ggplot2::autoplot(fit)$theme$plot.title.position, "plot")
  expect_identical(
    ggplot2::autoplot(fit, what = "components")$theme$plot.title.position,
    "plot"
  )
  expect_identical(ggplot2::autoplot(ds)$theme$plot.title.position, "plot")
})

test_that("component bars are filled from the colourblind-safe palette", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  fills <- built_layer(ggplot2::autoplot(fit, what = "components"), 1)$fill
  expect_true(all(fills %in% icc_palette()))
  # Not the ggplot2 default single grey: distinct fills across components.
  expect_gt(length(unique(fills)), 1)
})

test_that("multilevel coefficient points are coloured from the palette", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(sim_ml_small(), score, subject, rater, cluster = cluster, seed = 1)
  cols <- built_layer(ggplot2::autoplot(fit), 2)$colour # geom_point layer
  expect_true(all(cols %in% icc_palette()))
  # Subject and cluster levels get distinct palette colours.
  expect_gt(length(unique(cols)), 1)
})

test_that("coefficient plot value labels equal the rounded estimates", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    unit = c("single", "average"),
    seed = 1
  )
  labs <- built_layer(ggplot2::autoplot(fit), 3)$label # geom_text layer
  expect_equal(sort(as.numeric(labs)), sort(round(fit$estimates$estimate, 2)))
})

test_that("components plot value labels equal the component variances", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  labs <- built_layer(ggplot2::autoplot(fit, what = "components"), 2)$label
  view <- icc_components_view(fit)
  expect_equal(
    sort(as.numeric(labs)),
    sort(signif(view$variance, 3)),
    tolerance = 1e-6
  )
})

test_that("ggplot2 stays a Suggests dependency (light-install, ADR-010)", {
  desc <- read.dcf(system.file("DESCRIPTION", package = "intraclass"))
  expect_match(desc[, "Suggests"], "ggplot2")
  imports <- if ("Imports" %in% colnames(desc)) desc[, "Imports"] else ""
  expect_false(grepl("ggplot2", imports))
})
