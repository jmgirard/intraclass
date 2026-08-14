# M118 -- Burch's leptokurtic width reversal on a BOTH-COMPONENTS-non-normal grid.
#
# The question, and why this script exists at all: Burch (2011) p. 1024 reports
# his REML interval running WIDER than the normal-based (exact-F) one for
# symmetric leptokurtic data, and SHORTER for symmetric platykurtic data. His
# eq. 18 comparator is eq. 3 -- the very pivot this package ships as "searle" --
# so that is a burch-vs-searle claim, not a claim about some third interval.
#
# Both committed repo grids (m76-coverage-sweep.R, m111-fallback-sweep.R) draw
# the SUBJECT EFFECT from the family and always draw the residual from a normal.
# On them "burch" is the narrower of the two nearly everywhere, which is what
# D-012 Amendment 1 corrected the shipped documentation to say. Burch's Fig. 2
# draws BOTH `A_i` and `e_ij` from the studied family (p. 1023). That condition
# is what this script varies, and it is the only thing it varies.
#
# Pre-registered rules W1-W3: cairn/references/classical-width-reversal-comparison.md,
# frozen before this file existed (GP5). Do not read results against anything else.
#
# NO CHECKPOINT CACHE, deliberately: m111's cache keys on the cell id alone, so a
# re-run after a build_cells() edit serves the old grid past every guard (its own
# ROADMAP row). Both legs here are closed forms, so a resume buys nothing worth
# that risk -- the M114 convention (m114-heldout-sweep.R:17-18).
#
# Run: Rscript data-raw/m118-width-reversal-sweep.R

devtools::load_all(quiet = TRUE)

out_rds <- Sys.getenv(
  "M118_RESULTS_OUT",
  "data-raw/m118-width-reversal-results.rds"
)
out_tsv <- Sys.getenv(
  "M118_TSV_OUT",
  "data-raw/m118-width-reversal-by-cell.tsv"
)
fixture_tsv <- Sys.getenv(
  "M118_FIXTURE_OUT",
  "tests/testthat/fixtures/width-reversal-by-cell.tsv"
)
n_cores <- as.integer(Sys.getenv("M118_CORES", "4"))

conf_level <- 0.95
n_rep <- 2000L

# --- standardized variates ----------------------------------------------------
# Each returns draws with mean 0, variance 1 and the burch2011 Table 2 (p. 1021)
# excess kurtosis for its family, so a cell's population ICC is exactly `rho`
# whichever family it uses. This is Burch's located-and-scaled convention
# (sec 3, p. 1022), applied to BOTH components rather than to the subject effect
# alone.
#
# power exponential(0, 1, 2.78) has no base-R generator. Density
# exp(-|x|^beta): |X|^beta ~ Gamma(1/beta, 1) with a random sign, and
# Var = gamma(3/beta)/gamma(1/beta). At beta = 2.78 the theoretical excess
# kurtosis is -0.50049, matching Burch's printed -0.5 -- which is what fixes the
# parameterization (his third parameter is the exponent, not a scale). T4 asserts
# every family's kurtosis against the printed table; that is the only thing
# standing between a mis-scaled draw and a silently wrong grid.
pe_beta <- 2.78

draw_standard <- function(m, dist) {
  switch(
    dist,
    gaussian = stats::rnorm(m),
    uniform = (stats::runif(m) - 0.5) * sqrt(12),
    powexp = {
      g <- stats::rgamma(m, shape = 1 / pe_beta, rate = 1)
      sgn <- sample(c(-1, 1), m, replace = TRUE)
      sgn * g^(1 / pe_beta) / sqrt(gamma(3 / pe_beta) / gamma(1 / pe_beta))
    },
    t10 = stats::rt(m, df = 10) / sqrt(10 / 8),
    laplace = sample(c(-1, 1), m, replace = TRUE) * stats::rexp(m) / sqrt(2),
    t5 = stats::rt(m, df = 5) / sqrt(5 / 3),
    chisq1 = (stats::rchisq(m, df = 1) - 1) / sqrt(2),
    stop("unknown dist: ", dist)
  )
}

# burch2011 Table 2 (p. 1021), printed excess kurtoses. T4 asserts against these.
table2_kurtosis <- c(
  uniform = -1.2,
  powexp = -0.5,
  gaussian = 0.0,
  t10 = 1.0,
  laplace = 3.0,
  t5 = 6.0,
  chisq1 = 12.0
)

# --- data generation ----------------------------------------------------------
# BOTH components come from `draw_standard(., dist)`. The AST fence in
# tests/testthat/test-m118-both-components-dgp.R asserts exactly that and fails
# if either component acquires a distribution of its own.
gen_oneway <- function(k, n, rho, dist, seed) {
  set.seed(seed)
  sd_a <- sqrt(rho)
  sd_e <- sqrt(1 - rho)
  a <- sd_a * draw_standard(k, dist)
  e <- sd_e * draw_standard(k * n, dist)
  vals <- rep(a, each = n) + e
  split(vals, rep(seq_len(k), each = n))
}

# --- the two closed-form legs -------------------------------------------------
# Called as the package computes them, not as the M76/M111 prototypes did: this
# measurement should describe what users actually get. AC4's gaussian
# cross-check against the committed M111 cells is what would catch a divergence.
endpoints_both <- function(groups) {
  ss <- classical_oneway_ss(groups)
  f <- ss$msa / ss$mse
  if (ss$mse == 0 || !is.finite(f) || identical(ss$msa, 0)) {
    return(NULL) # the shared classical guard's condition (D-022); recorded, never coerced
  }
  kappa <- burch_kappa_hat(groups, ss$msa, ss$mse)
  g_val <- burch_g(burch_kappa_bc(kappa, ss$k, ss$n))
  list(
    searle = searle_endpoints(ss$msa, ss$mse, ss$df1, ss$df2, ss$n, conf_level),
    burch = burch_reml_endpoints(ss$msa, ss$mse, ss$k, ss$n, g_val, conf_level)
  )
}

# --- cells --------------------------------------------------------------------
# Ids start at 101 to keep the seed streams disjoint from M76 (1-16), M111
# (1-64) and M114 (65-74).
build_cells <- function() {
  fig2 <- expand.grid(
    dist = c("uniform", "powexp", "gaussian", "t10", "laplace", "t5"),
    k = seq(10L, 100L, by = 10L),
    stringsAsFactors = FALSE
  )
  fig2$n <- 5L
  fig2$rho <- 0.5
  fig2$block <- "fig2"

  anchor <- data.frame(
    dist = "uniform",
    k = 100L,
    n = 5L,
    rho = 0.25,
    block = "anchor",
    stringsAsFactors = FALSE
  )

  m111 <- expand.grid(
    dist = c("gaussian", "t5", "uniform", "chisq1"),
    kn = c("10-5", "30-5", "50-5", "10-2"),
    rho = c(0.05, 0.10, 0.30, 0.60),
    stringsAsFactors = FALSE
  )
  m111$k <- as.integer(sub("-.*$", "", m111$kn))
  m111$n <- as.integer(sub("^.*-", "", m111$kn))
  m111$kn <- NULL
  m111$block <- "m111"

  cells <- rbind(
    fig2[, c("block", "rho", "k", "n", "dist")],
    anchor[, c("block", "rho", "k", "n", "dist")],
    m111[, c("block", "rho", "k", "n", "dist")]
  )
  cells$id <- 100L + seq_len(nrow(cells))
  cells
}

# --- one cell -----------------------------------------------------------------
run_cell <- function(cell) {
  searle_w <- numeric(n_rep)
  burch_w <- numeric(n_rep)
  searle_cov <- logical(n_rep)
  burch_cov <- logical(n_rep)
  n_skip <- 0L

  for (rep in seq_len(n_rep)) {
    seed <- cell$id * 1000000L + rep
    groups <- gen_oneway(cell$k, cell$n, cell$rho, cell$dist, seed)
    ep <- endpoints_both(groups)
    if (is.null(ep)) {
      n_skip <- n_skip + 1L
      searle_w[rep] <- NA_real_
      burch_w[rep] <- NA_real_
      searle_cov[rep] <- NA
      burch_cov[rep] <- NA
      next
    }
    searle_w[rep] <- ep$searle[["upper"]] - ep$searle[["lower"]]
    burch_w[rep] <- ep$burch[["upper"]] - ep$burch[["lower"]]
    searle_cov[rep] <- ep$searle[["lower"]] <= cell$rho &&
      cell$rho <= ep$searle[["upper"]]
    burch_cov[rep] <- ep$burch[["lower"]] <= cell$rho &&
      cell$rho <= ep$burch[["upper"]]
  }

  data.frame(
    block = cell$block,
    cell = cell$id,
    rho = cell$rho,
    k = cell$k,
    n = cell$n,
    dist = cell$dist,
    n_rep = n_rep,
    n_skip = n_skip,
    # Two ratio summaries, and they answer different questions. Burch's eq. 18 is
    # a ratio of EXPECTED lengths, so mean_ratio is the one comparable to his
    # printed 0.88; median_ratio is what the repo's own M116/M117 width records
    # use and is what W1 is read against. Reporting one alone would silently pick
    # a convention.
    mean_ratio = mean(burch_w, na.rm = TRUE) / mean(searle_w, na.rm = TRUE),
    median_ratio = stats::median(burch_w / searle_w, na.rm = TRUE),
    burch_med_width = stats::median(burch_w, na.rm = TRUE),
    searle_med_width = stats::median(searle_w, na.rm = TRUE),
    burch_coverage = mean(burch_cov, na.rm = TRUE),
    searle_coverage = mean(searle_cov, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

# --- completeness guard -------------------------------------------------------
# mclapply reports a killed worker as a NULL element while keeping the list's
# full length, so an inherits(., "try-error") check passes and rbind drops the
# cell silently (M112). Assert class and row count BEFORE any write.
assert_cells_complete <- function(res, cells) {
  if (length(res) != nrow(cells)) {
    stop("sweep returned ", length(res), " results for ", nrow(cells), " cells")
  }
  bad <- which(!vapply(res, is.data.frame, logical(1)))
  if (length(bad)) {
    stop(
      "non-data.frame result(s) at cell index: ",
      paste(bad, collapse = ", ")
    )
  }
  rows <- vapply(res, nrow, integer(1))
  if (any(rows != 1L)) {
    stop("expected 1 row per cell; got ", paste(unique(rows), collapse = "/"))
  }
  ids <- vapply(res, function(d) d$cell, numeric(1))
  if (!identical(as.integer(ids), as.integer(cells$id))) {
    stop("cell ids came back out of order or altered")
  }
  invisible(TRUE)
}

# --- main ---------------------------------------------------------------------
if (sys.nframe() == 0L) {
  cells <- build_cells()
  cat(
    "M118 sweep:",
    nrow(cells),
    "cells x",
    n_rep,
    "reps,",
    n_cores,
    "workers\n"
  )
  t0 <- Sys.time()

  res <- parallel::mclapply(
    split(cells, seq_len(nrow(cells))),
    run_cell,
    mc.cores = n_cores
  )
  assert_cells_complete(res, cells)
  tab <- do.call(rbind, res)
  rownames(tab) <- NULL

  elapsed <- round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1)
  cat("done in", elapsed, "min\n")

  saveRDS(
    list(
      table = tab,
      cells = cells,
      meta = list(
        generated = as.character(Sys.Date()),
        n_rep = n_rep,
        conf_level = conf_level,
        pe_beta = pe_beta,
        rules = "cairn/references/classical-width-reversal-comparison.md (W1-W3, frozen)",
        r_version = R.version.string,
        platform = R.version$platform
      )
    ),
    out_rds
  )

  header <- c(
    "# M118 -- burch-vs-searle interval width on a BOTH-components-non-normal grid.",
    "# Both A_i and e_ij are drawn from `dist`, located and scaled per burch2011",
    "# sec 3 (p. 1022). Generated by data-raw/m118-width-reversal-sweep.R.",
    "# mean_ratio is comparable to Burch's eq. 18 (a ratio of expected lengths);",
    "# median_ratio is the repo's M116/M117 convention and is what W1 reads.",
    "# Rules W1-W3: cairn/references/classical-width-reversal-comparison.md."
  )
  writeLines(header, out_tsv)
  suppressWarnings(
    utils::write.table(
      tab,
      out_tsv,
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      append = TRUE
    )
  )
  writeLines(header, fixture_tsv)
  suppressWarnings(
    utils::write.table(
      tab,
      fixture_tsv,
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      append = TRUE
    )
  )
  cat("wrote", out_rds, "/", out_tsv, "/", fixture_tsv, "\n")
}
