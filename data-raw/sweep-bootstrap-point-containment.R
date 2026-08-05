# Does `ci_method = "bootstrap"` ever report a confidence limit that lies above
# the point estimate it accompanies, and if so by how much?
#
# WHY THIS EXISTS. On zero-between-subject-variance data the reported ICC(1)
# point and the reported `conf.low` are both numerically zero, but not the SAME
# numerically zero: the point comes from the engine's REML fit and the limit from
# a quantile of refits, so the two land a few 1e-10 apart in either order. M103
# now points a user at `ci_method = "bootstrap"` on exactly this data, so the
# shape they meet there is one this package chose to recommend, and a claim about
# it needs a measurement rather than a reading of the code.
#
# This script MEASURES and concludes nothing about what should be reported. It
# changes no number and licenses no clamp: M104 documents the relation this
# fixture records and leaves every reported value alone.
#
# Re-run (from the repo root; ~30 min at boot_samples = 999 on an M-series Mac):
#   Rscript data-raw/sweep-bootstrap-point-containment.R
#
# WHAT THE GRID GENERATES, AND WHAT IT DOES NOT. A sample is not a class. The
# failure axis here is BETWEEN-SUBJECT VARIANCE (GP6), and the grid walks it:
#
#   GENERATED: the exact zero-between-variance boundary (`gen_ssa0`, subjects
#     carry no signal at all), and three nonzero rungs above it (`gen_small`,
#     sd_s = 0.05 / 0.3 / 1.0 against a residual SD of 3, so ICC ranges from
#     ~3e-4 to ~0.1). Balanced one-way data only.
#
#   NOT GENERATED: unbalanced or incomplete designs; the two-way and multilevel
#     estimands; any engine but the shipped default; any `ci_method` but
#     `"bootstrap"`. Nothing here is evidence about those, and the assertions
#     that read this fixture are scoped to the rows it contains.
#
#   NOT GENERATED EITHER: a cell whose refits fail often enough to trip
#     `R/ci-bootstrap.R:58`. Such a cell would abort rather than report, and the
#     `status` column below records it as a row so its absence from the
#     containment question is visible instead of silent.

suppressMessages(devtools::load_all(quiet = TRUE))

# The result is a committed TEST FIXTURE, not a `data-raw` by-product: the suite
# reads it to assert the containment bound (M104 AC2), and `data-raw/` is
# `.Rbuildignore`d, so a result left there would be invisible under `R CMD check`
# and the assertion would silently skip in CI.
out_path <- "tests/testthat/fixtures/bootstrap-point-containment.tsv"

# The SHIPPED default, not a reduced count -- the same rule `sweep-abort-remedies.R`
# records: a sweep at a lower count measures a different experiment from the one a
# user's own call runs. M104 AC6 pins a live call at this count, so the fixture and
# that test speak about the same experiment.
boot_samples_n <- 999L
conf_level_n <- 0.95
reducer_seed <- 1L

# ---- data generators ---------------------------------------------------------
# Both return balanced one-way long data on a residual SD of 3.

# Zero BETWEEN-subject variance: every subject shares one rater profile, so the
# subject factor carries no signal and the fitted between-variance sits at the
# boundary. `jitter_sd` adds RESIDUAL noise only -- it does not move the between-
# subject variance off zero, which is why this arm cannot supply the axis's
# nonzero rungs and `gen_small()` below exists.
gen_ssa0 <- function(n_s, n_r, jitter_sd = 0, seed = 1) {
  set.seed(seed)
  profile <- stats::rnorm(n_r, 0, 3)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(profile, times = n_s) + stats::rnorm(n_s * n_r, 0, jitter_sd)
  )
}

# Nonzero BETWEEN-subject variance at a controllable size: `sd_s` is the rung on
# the failure axis, from just-off-the-boundary (0.05) to comfortably interior (1).
gen_small <- function(n_s, n_r, sd_s, seed = 1) {
  set.seed(seed)
  mu <- stats::rnorm(n_s, 0, sd_s)
  data.frame(
    subject = rep(seq_len(n_s), each = n_r),
    rater = rep(seq_len(n_r), times = n_s),
    score = rep(mu, each = n_r) + stats::rnorm(n_s * n_r, 0, 3)
  )
}

# ---- grid --------------------------------------------------------------------
# 12 cells per arm. The zero arm varies geometry and seed at a fixed (zero)
# between-variance; the nonzero arm walks `sd_s` up the axis, which is the
# variation GP6 asks for and the one the zero arm cannot produce.
cells <- rbind(
  data.frame(
    arm = "zero-between",
    n_s = rep(c(6L, 12L), each = 6L),
    n_r = rep(rep(c(3L, 5L), each = 3L), times = 2L),
    spread = 0,
    seed = rep(1:3, times = 4L)
  ),
  data.frame(
    arm = "nonzero-between",
    n_s = rep(c(6L, 12L), each = 6L),
    n_r = 3L,
    spread = rep(rep(c(0.05, 0.3, 1.0), each = 2L), times = 2L),
    seed = rep(1:2, times = 6L)
  )
)

# ---- sweep -------------------------------------------------------------------
rows <- list()
for (i in seq_len(nrow(cells))) {
  cell <- cells[i, ]
  df <- if (identical(cell$arm, "zero-between")) {
    gen_ssa0(cell$n_s, cell$n_r, jitter_sd = cell$spread, seed = cell$seed)
  } else {
    gen_small(cell$n_s, cell$n_r, sd_s = cell$spread, seed = cell$seed)
  }
  fit <- tryCatch(
    icc(
      df,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "bootstrap",
      seed = reducer_seed,
      boot_samples = boot_samples_n,
      conf_level = conf_level_n
    ),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    # A cell that aborted still gets rows -- one per index -- so it stays visible
    # in the fixture rather than dropping out of the domain the assertions quantify
    # over. The class is recorded, not just the fact of failure.
    status <- paste0("abort:", class(fit)[[1]])
    rows[[length(rows) + 1L]] <- data.frame(
      cell,
      index = c("ICC(1)", "ICC(k)"),
      boot_samples = boot_samples_n,
      conf_level = conf_level_n,
      status = status,
      estimate = NA_real_,
      conf_low = NA_real_,
      conf_high = NA_real_,
      excludes_point = NA,
      gap = NA_real_
    )
    next
  }
  est <- as.data.frame(fit$estimates)
  rows[[length(rows) + 1L]] <- data.frame(
    cell,
    index = est$index,
    boot_samples = boot_samples_n,
    conf_level = conf_level_n,
    status = "ok",
    estimate = est$estimate,
    conf_low = est$conf.low,
    conf_high = est$conf.high,
    excludes_point = est$conf.low > est$estimate,
    gap = est$conf.low - est$estimate
  )
  cat(sprintf(
    "%2d/%2d %-16s n_s=%2d n_r=%d spread=%-5g seed=%d -> %s\n",
    i,
    nrow(cells),
    cell$arm,
    cell$n_s,
    cell$n_r,
    cell$spread,
    cell$seed,
    paste(
      ifelse(est$conf.low > est$estimate, "excludes", "contains"),
      collapse = "/"
    )
  ))
}
res <- do.call(rbind, rows)

# Fixture provenance header (PROFILE.md test-doctrine): source, generator, seeds.
# `read.delim(..., comment.char = "#")` skips it; the suite reads it that way.
writeLines(
  c(
    "# bootstrap-point-containment.tsv -- whether `ci_method = \"bootstrap\"`",
    "# reports a `conf.low` above its own point estimate, and by how much.",
    "# Source: generated data only, no external oracle -- every dataset comes from",
    "# the two generators in the script below. Generator:",
    "# data-raw/sweep-bootstrap-point-containment.R",
    "# (re-run: Rscript data-raw/sweep-bootstrap-point-containment.R).",
    "# Seeds: each cell's `seed` column seeds its generator; the reducer runs at",
    "# seed = 1 and the shipped boot_samples = 999 (both recorded per row).",
    "# Do not hand-edit: regenerate with the script above.",
    paste0(
      "# Written by that script under R ",
      getRversion(),
      ", glmmTMB ",
      utils::packageVersion("glmmTMB"),
      ", ",
      R.version$platform,
      "."
    )
  ),
  out_path
)
utils::write.table(
  res,
  out_path,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE,
  append = TRUE
)

# ---- report ------------------------------------------------------------------
ok <- res[res$status == "ok", ]
excl <- ok[ok$excludes_point, ]
cat(sprintf(
  "\nwrote %s (%d rows; %d ok, %d aborted)\n",
  out_path,
  nrow(res),
  nrow(ok),
  nrow(res) - nrow(ok)
))
cat(sprintf(
  "conf.low > estimate in %d of %d reported rows\n",
  nrow(excl),
  nrow(ok)
))
if (nrow(excl)) {
  cat(sprintf(
    "  largest gap %.3g; largest point estimate among them %.3g\n",
    max(excl$gap),
    max(excl$estimate)
  ))
  cat("  by arm: ")
  print(table(excl$arm))
}
cat(sprintf(
  "R %s, glmmTMB %s, platform %s\n",
  getRversion(),
  utils::packageVersion("glmmTMB"),
  R.version$platform
))
