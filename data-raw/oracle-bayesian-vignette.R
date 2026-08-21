# oracle-bayesian-vignette.R
# ===========================================================================
# Provenance for the brms transcripts shown in the vignettes (M129). Run to
# regenerate the committed reference
# (tests/testthat/fixtures/bayesian-vignette-oracle.rds) asserted in
# tests/testthat/test-vignette-transcripts.R. Seeded (PRINCIPLES.md #12); no
# fabricated values (#4) -- the reference is this script's own seeded output.
#
# WHAT THIS BACKS
# ---------------------------------------------------------------------------
# Four hand-pasted output blocks that no evaluated chunk reproduces, because
# fitting a Stan model needs a toolchain the pkgdown/knit environment lacks
# (the M52 offline-fixture constraint; data-raw/README.md):
#
#   vignettes/engines.Rmd          `brms` chunk        -> fits$percentile
#   vignettes/engines.Rmd          `brms-prior` chunk  -> custom_prior_warning
#   vignettes/interval-methods.Rmd `posterior` chunk   -> fits$percentile
#   vignettes/interval-methods.Rmd `posterior-hpdi`    -> fits$hpdi
#
# The engines.Rmd `brms` block and the interval-methods.Rmd `posterior` block
# are the SAME call and are pinned against the same stored fit.
#
# WHY THE STORED FITS ARE STRIPPED
# ---------------------------------------------------------------------------
# A whole `icc` object from the brms engine serializes to ~4 MB, and ~1.6 MB
# even with `$fit` removed, because `$mc`/`$boot`/`$call` carry environments
# that drag the brmsfit back in. tests/ ships inside the CRAN tarball, so the
# fixture stores ONLY the elements `format.icc()` reads -- verified below by
# re-rendering the stripped object and requiring the render to be identical to
# the full object's. That keeps this fixture in line with its siblings (the
# other bayesian-*-oracle.rds files are 0.8-3 KB).
#
# WHY THE RENDER OPTIONS ARE RECORDED
# ---------------------------------------------------------------------------
# `print.icc()` draws a cli rule padded to the console width and uses Unicode
# box-drawing and bullet glyphs, so a block's text depends on the cli rendering
# MODE as well as the width -- and testthat runs cli in ASCII mode by default.
# The vignettes were written at width 80 with Unicode on; the fixture records
# the whole option set and the test renders under it.
#
# SOURCE (sourced -- PRINCIPLES.md #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions to Estimate Variance Components for Interrater
#     Reliability Coefficients. Springer Proc. Math. & Stat. 322, 79-93.
#     doi:10.1007/978-3-030-43469-4_7.
#   The engine's fixed half-t(4, 0, 1) prior on every random-effect SD is that
#   paper's; this script does not re-derive it, it records what the shipped
#   engine prints on the shipped `ratings` dataset.
#
# REGENERATION (data-raw/README.md fixture lifecycle)
# ---------------------------------------------------------------------------
#   Rscript data-raw/oracle-bayesian-vignette.R
# Any change to the printed values is a REPORTABLE EVENT, not a re-baseline
# (D-024): the vignette prose is written against these figures, so a diff here
# means the vignette needs re-reading, not just the fixture rewriting.
# ===========================================================================

stopifnot(requireNamespace("brms", quietly = TRUE))
devtools::load_all(".", quiet = TRUE)

SEED <- 1L
OUT <- "tests/testthat/fixtures/bayesian-vignette-oracle.rds"

# The cli rendering mode, not just the width. `print.icc()` draws a cli rule
# padded to the console width AND uses Unicode box-drawing and bullet glyphs;
# testthat runs cli in ASCII mode by default, so a pin that fixed only the width
# would compare the vignette's "──" against a rendered "--" and fail for a
# reason that has nothing to do with the transcript. The fixture carries this
# set so the generator and the test cannot drift apart.
RENDER_OPTIONS <- list(
  cli.width = 80L,
  width = 80L,
  cli.unicode = TRUE,
  cli.condition_unicode_bullets = TRUE,
  cli.num_colors = 1L
)

# `format.icc()` reads exactly these; nothing else survives into the fixture.
RENDER_ELEMENTS <- c(
  "estimates", "components", "design", "k_eff", "k_c_eff", "engine", "ci", "n"
)

# `print.icc()` emits through cli, and cli writes to its OWN output connection --
# `utils::capture.output()` returns character(0) for it, which would make the
# strip check below compare two empty vectors and pass vacuously. `cli::cli_fmt()`
# captures the real print() path.
render <- function(x) {
  withr::with_options(RENDER_OPTIONS, cli::cli_fmt(print(x)))
}

strip_to_render_elements <- function(x) {
  out <- x[RENDER_ELEMENTS]
  class(out) <- class(x)
  # The stripped object must render identically to the full one, or the fixture
  # would pin something the package never shows a user. The length check is an
  # anti-vacuity guard: an empty-vs-empty comparison would otherwise pass.
  full <- render(x)
  stripped <- render(out)
  stopifnot(length(full) > 0L, identical(stripped, full))
  out
}

message("Fitting the percentile transcript (engines.Rmd, interval-methods.Rmd) ...")
fit_percentile <- suppressWarnings(icc(
  ratings, score, subject, rater,
  engine = "brms", type = "agreement", seed = SEED
))

message("Fitting the HPDI transcript (interval-methods.Rmd) ...")
fit_hpdi <- suppressWarnings(icc(
  ratings, score, subject, rater,
  engine = "brms", type = "agreement",
  posterior_summary = "hpdi", seed = SEED
))

# The custom-prior warning fires in icc()'s argument handling, BEFORE the Stan
# fit is built (R/icc.R, warn_intraclass(class = "intraclass_custom_prior")), so
# it is captured by unwinding out of the handler -- no second Stan run.
message("Capturing the custom-prior warning (engines.Rmd) ...")
# cli formats a condition's message when the condition is CREATED, not when it
# is rendered, so the options have to wrap the icc() call itself -- rendering a
# already-built condition under them changes nothing.
custom_prior_cond <- NULL
withr::with_options(RENDER_OPTIONS, {
  tryCatch(
    withCallingHandlers(
      icc(
        ratings, score, subject, rater,
        engine = "brms",
        prior = brms::set_prior("normal(0, 0.1)", class = "sd"),
        seed = SEED
      ),
      intraclass_custom_prior = function(w) {
        custom_prior_cond <<- w
        stop("captured; unwinding before the fit", call. = FALSE)
      }
    ),
    error = function(e) NULL
  )
})
stopifnot(!is.null(custom_prior_cond))

# Store the RENDERED warning rather than the condition object: an rlang
# condition carries a call and a backtrace whose environments would drag the
# whole fitting frame into the fixture.
custom_prior_warning <- strsplit(
  rlang::cnd_message(custom_prior_cond), "\n", fixed = TRUE
)[[1]]

fixture <- list(
  generated = Sys.Date(),
  generator = "data-raw/oracle-bayesian-vignette.R",
  seed = SEED,
  render_options = RENDER_OPTIONS,
  r_version = R.version.string,
  brms_version = as.character(utils::packageVersion("brms")),
  rstan_version = as.character(utils::packageVersion("rstan")),
  fits = list(
    percentile = strip_to_render_elements(fit_percentile),
    hpdi = strip_to_render_elements(fit_hpdi)
  ),
  custom_prior_warning = custom_prior_warning,
  custom_prior_classes = class(custom_prior_cond)
)

saveRDS(fixture, OUT, compress = "xz")
message(sprintf("wrote %s (%.1f KB)", OUT, file.size(OUT) / 1024))

cat("\n--- percentile render ---\n"); cat(render(fixture$fits$percentile), sep = "\n")
cat("\n--- hpdi render ---\n"); cat(render(fixture$fits$hpdi), sep = "\n")
cat("\n--- custom-prior warning ---\n"); cat(custom_prior_warning, sep = "\n")
