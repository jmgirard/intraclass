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

# Pull a built layer's data out of a ggplot (1 = linerange/ribbon, 2 = point).
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

test_that("what = 'components' is a classed 'not yet' in Slice 1", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  expect_error(
    ggplot2::autoplot(fit, what = "components"),
    class = "intraclass_unsupported"
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

test_that("autoplot.icc_dstudy renders the projected curve faithfully", {
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
  p <- ggplot2::autoplot(ds)
  expect_s3_class(p, "ggplot")

  ord <- ds[order(ds$m), , drop = FALSE]
  ribbon <- built_layer(p, 1) # geom_ribbon
  line <- built_layer(p, 2) # geom_line
  expect_equal(line$x, ord$m)
  expect_equal(line$y, ord$estimate)
  expect_equal(ribbon$ymin, ord$conf.low)
  expect_equal(ribbon$ymax, ord$conf.high)
})
