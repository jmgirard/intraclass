# data-raw/plot-previews.R
# ---------------------------------------------------------------------------
# Reproducible previews of the three autoplot views (M61 plotting polish), for
# the manual visual review at the milestone/PR review gate. `data-raw/` is
# `.Rbuildignore`d, so neither this script nor its output ships in the package.
#
# Run:  Rscript data-raw/plot-previews.R [outdir]
# (outdir defaults to tempdir(); prints the paths of the six PNGs it writes.)
#
# The views: coefficient forest plot, variance-component bars, and the d-study
# reliability curve -- each in a single-level (two-way) and a multilevel
# (Design 1) variant, so the theme, colourblind-safe palette, value labels, and
# the grouped-by-error-definition d-study curves are all exercised.
# ---------------------------------------------------------------------------

devtools::load_all(quiet = TRUE)
library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
outdir <- if (length(args) >= 1) args[1] else tempdir()
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# Single-level fixture: the shipped self-fidelity ratings.
fit <- icc(
  sf_ratings_long(),
  score,
  subject,
  rater,
  unit = c("single", "average"),
  seed = 1
)

# Multilevel Design 1 fixture: matches test-autoplot.R's sim_ml_small(seed).
sim_ml <- function(seed = 20260707) {
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
mlfit <- icc(
  sim_ml(),
  score,
  subject,
  rater,
  cluster = cluster,
  unit = c("single", "average"),
  seed = 1
)

ds <- d_study(fit, m = 1:8, seed = 1)
mlds <- d_study(mlfit, m = 1:8, seed = 1)

save_png <- function(p, name, w = 7, h = 4.5) {
  path <- file.path(outdir, name)
  ggsave(path, p, width = w, height = h, dpi = 110, bg = "white")
  path
}

paths <- c(
  save_png(autoplot(fit), "01-coefficients.png"),
  save_png(autoplot(fit, what = "components"), "02-components.png"),
  save_png(autoplot(ds), "03-dstudy.png"),
  save_png(autoplot(mlfit), "04-coefficients-multilevel.png", h = 6),
  save_png(
    autoplot(mlfit, what = "components"),
    "05-components-multilevel.png"
  ),
  save_png(autoplot(mlds), "06-dstudy-multilevel.png", w = 9)
)

cat(
  "Wrote",
  length(paths),
  "previews:\n",
  paste0("  ", paths, collapse = "\n"),
  "\n"
)
