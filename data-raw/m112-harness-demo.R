# M112 — demonstrations that the M111 harness guards actually fire.
#
# Three checks, one per hardened defect (AC1-AC3). Each runs a MUTATED case
# that must fail and a CLEAN case that must pass, so a guard that has quietly
# stopped discriminating is visible here rather than in a silent fixture.
# Nothing here touches the committed M111 evidence: every path is a tempdir
# override (M111_CKPT_DIR / M111_RESULTS_OUT / M111_RESULTS_IN /
# M111_RULES_OUT), and the sweep is re-run at n_rep = 2 rather than 2000.
#
#   Rscript data-raw/m112-harness-demo.R        (~2 min: 128 MC fits)

tmp <- tempfile("m112-demo-")
dir.create(tmp)
Sys.setenv(M111_CKPT_DIR = file.path(tmp, "ckpt"))
Sys.setenv(M111_RESULTS_OUT = file.path(tmp, "results.rds"))

source("data-raw/m111-fallback-sweep.R")

pass <- function(label) cat("PASS  ", label, "\n", sep = "")
expect_error <- function(expr, label) {
  e <- tryCatch(
    {
      force(expr)
      NULL
    },
    error = identity
  )
  if (is.null(e)) {
    stop("expected an error but none was signalled: ", label)
  }
  cat("PASS  ", label, "\n        error: ", conditionMessage(e), "\n", sep = "")
}

# ---- AC1: the post-map completeness guard -----------------------------------
cat("\n== AC1: lost-worker guard ==\n")
dir.create(ckpt_dir, showWarnings = FALSE, recursive = TRUE)
cells <- build_cells(n_rep = 2L)
results <- parallel::mclapply(cells, run_cell, mc.cores = n_workers)

assert_sweep_results(results, cells)
pass(sprintf(
  "clean n_rep = 2 run over %d cells passes the assertions (%d rows)",
  length(cells),
  nrow(do.call(rbind, results))
))

lost <- results
lost[17L] <- list(NULL)
expect_error(
  assert_sweep_results(lost, cells),
  "a cell forced to NULL (the killed-worker shape) is rejected"
)

dropped <- results
dropped[[17L]] <- dropped[[17L]][-1L, , drop = FALSE]
expect_error(
  assert_sweep_results(dropped, cells),
  "a cell short by one row is rejected"
)

short <- results[-17L]
expect_error(
  assert_sweep_results(short, cells),
  "a result list short by one cell is rejected"
)

# ---- AC2: the MC leg's abort flag comes from the classed condition ----------
cat("\n== AC2: abort-classification guard ==\n")
demo_cell <- list(
  id = 1L,
  rho = 0.3,
  k = 10L,
  n = 5L,
  dist = "gaussian",
  n_rep = 1L
)

mc_ci <- function(d, seed) {
  list(status = "ok", lower = NA_real_, upper = NA_real_)
}
expect_error(
  one_rep(demo_cell, 1L),
  "a non-finite MC interval WITHOUT the classed condition errors loudly"
)

mc_ci <- function(d, seed) {
  list(status = "abort", lower = NA_real_, upper = NA_real_)
}
row <- one_rep(demo_cell, 1L)
mc_row <- row[row$method == "mc", ]
stopifnot(nrow(mc_row) == 1L, isTRUE(mc_row$aborted))
pass("a stub signalling intraclass_singular_fit counts as aborted")

mc_ci <- function(d, seed) {
  list(status = "ok", lower = 0.1, upper = 0.5)
}
row <- one_rep(demo_cell, 1L)
mc_row <- row[row$method == "mc", ]
stopifnot(isFALSE(mc_row$aborted), isTRUE(mc_row$covered))
pass("a finite ok stub counts as not aborted")

# ---- AC3: the near-miss window, on a synthetic ledger -----------------------
# One constructed near-miss per implemented rule (F2, F3) plus clear passes and
# clear failures outside the window, including a passing-side value the
# pre-M112 script would have miscounted.
cat("\n== AC3: near-miss window ==\n")

cp_upper <- function(x, n) if (x >= n) 1 else stats::qbeta(0.95, x + 1, n - x)
find_cond <- function(n, lo, hi) {
  for (x in seq(n, 0L)) {
    u <- cp_upper(x, n)
    if (u >= lo && u < hi) return(list(x = x, n = n, ucb = u))
  }
  NULL
}
nm <- find_cond(400L, 0.925, 0.930) # F3 near-miss: bound inside the window
cl <- find_cond(400L, 0.800, 0.850) # F3 clear failure, far below the window
stopifnot(!is.null(nm), !is.null(cl))

# cov: unconditional composite coverage (F2's binding statistic)
# cond: (x, n) driving the Clopper-Pearson bound (F3's binding statistic)
spec <- list(
  list(cov = 0.9270, cond = list(x = 400L, n = 400L), tag = "F2 near-miss"),
  list(cov = 0.9320, cond = list(x = 400L, n = 400L), tag = "F2 passing-side"),
  list(cov = 0.8000, cond = list(x = 400L, n = 400L), tag = "F2 clear failure"),
  list(cov = 0.9800, cond = nm[c("x", "n")], tag = "F3 near-miss"),
  list(cov = 0.9800, cond = cl[c("x", "n")], tag = "F3 clear failure"),
  list(cov = 0.9800, cond = list(x = 400L, n = 400L), tag = "F3 clear pass"),
  list(
    cov = 0.9800,
    cond = nm[c("x", "n")],
    n_abort = 50L,
    tag = "sub-100 aborts: reported, never judged"
  )
)

syn_summary <- do.call(
  rbind,
  lapply(seq_along(spec), function(i) {
    s <- spec[[i]]
    n_ab <- if (is.null(s$n_abort)) s$cond$n else s$n_abort
    data.frame(
      cell = i,
      rho = 0.3,
      k = 10L,
      n = 5L,
      dist = "gaussian",
      n_rep = 1000L,
      n_abort = n_ab,
      mc_abort_rate = n_ab / 1000,
      comp_searle_coverage = s$cov,
      comp_searle_lo_miss = 0.01,
      comp_searle_hi_miss = 0.01,
      comp_burch_coverage = 0.98,
      comp_burch_lo_miss = 0.01,
      comp_burch_hi_miss = 0.01,
      cond_searle_coverage = s$cond$x / s$cond$n,
      cond_burch_coverage = 1,
      cond_searle_med_width = 0.5,
      cond_burch_med_width = 0.5,
      mc_med_width_ok = 0.4,
      stringsAsFactors = FALSE
    )
  })
)

syn_wide <- do.call(
  rbind,
  lapply(seq_along(spec), function(i) {
    n_ab <- syn_summary$n_abort[i]
    data.frame(
      cell = i,
      rep = seq_len(1000L),
      mc_aborted = seq_len(1000L) <= n_ab,
      searle_lo_miss = FALSE,
      searle_hi_miss = FALSE,
      burch_lo_miss = FALSE,
      burch_hi_miss = FALSE,
      stringsAsFactors = FALSE
    )
  })
)

syn_raw <- data.frame(
  method = rep(c("mc", "searle", "burch"), each = 4L),
  aborted = c(rep(TRUE, 4L), rep(FALSE, 8L)),
  stringsAsFactors = FALSE
)

syn_in <- file.path(tmp, "synthetic-results.rds")
syn_out <- file.path(tmp, "synthetic-rules.rds")
saveRDS(
  list(raw = syn_raw, wide = syn_wide, summary = syn_summary),
  syn_in
)

log <- system2(
  "Rscript",
  "data-raw/m111-fallback-verdict.R",
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    paste0("M111_RESULTS_IN=", syn_in),
    paste0("M111_RULES_OUT=", syn_out)
  )
)
if (!file.exists(syn_out)) {
  stop(paste(log, collapse = "\n"))
}
syn_rules <- readRDS(syn_out)
se <- syn_rules[syn_rules$arm == "searle", ]

stopifnot(
  # near-miss fires at exactly the constructed cell of each rule
  identical(which(se$f2_near_miss), 1L),
  identical(which(se$f3_near_miss), 4L),
  # a near-miss is on the FAILING side, so each near-miss cell also fails
  identical(which(!se$f2_pass), c(1L, 3L)),
  identical(which(!se$f3_pass), c(4L, 5L)),
  # the sub-100-abort cell is reported, never judged
  identical(which(se$f3_applicable), 1:6)
)
pass(sprintf(
  "F2 near-miss counted at exactly the constructed cell (%s); the %s at 0.9320 is not counted",
  spec[[1]]$tag,
  spec[[2]]$tag
))
pass(sprintf(
  "F3 near-miss counted at exactly the constructed cell (bound %.4f); clear pass/failure and the sub-100-abort cell are not",
  nm$ucb
))

cat("\nAll M112 demonstrations passed.\n")
unlink(tmp, recursive = TRUE)
