# M121 — `npbootstrap` coverage on the frozen 64-cell one-way skew grid.
#
# NON-EXPORTED research harness (data-raw/, not R/). Measures the SHIPPED
# `ci_method = "npbootstrap"` interval on the same grid D-027 judged the `mc`,
# `searle` and `burch` legs on, and writes the per-cell coverage table
# `data-raw/m121-npbootstrap-skew-coverage.tsv`. It applies no verdict: the
# disposition rule N1 is pre-registered (frozen, dated) in
# cairn/references/npbootstrap-skew-response-comparison.md BEFORE this script
# existed (GP5), and the verdict is read off the table by hand at T6.
#
# The M111 fixture (data-raw/m111-fallback-results.rds) holds three legs and no
# npbootstrap leg, so the fourth leg cannot be read off it. This harness instead
# REGENERATES every replicate from M111's recorded seed scheme
# (`base <- cell$id * 1000000L + rep`, m111-fallback-sweep.R:144) and adds the
# npbootstrap leg to the same datasets. Regeneration is only as good as its
# proof, so two things gate it before any output is written:
#
#   * the PLATFORM GATE — the fixture records the platform it was generated on,
#     and an RNG/BLAS/arithmetic difference would silently produce a different
#     dataset from the same seed. A platform other than the recorded one aborts
#     rather than compares (the M84/M105 platform-dependence lesson).
#   * the ENDPOINT IDENTITY CHECK — every regenerated dataset is put back through
#     the same closed-form `searle` and `burch` legs the fixture recorded, and
#     each endpoint must match the fixture's within 1e-12. Bit-exact equality is
#     a property of the machine's summation order (M105), so the tolerance form
#     is used, as at M118. 64 cells x 2000 reps x 2 legs = 256,000 ROWS are
#     compared, carrying 512,000 ENDPOINTS, and both counts are asserted
#     separately: a loop that silently ran over nothing fails the first, and one
#     that compared only `lower` (or only `upper`) fails the second.
#
# The platform gate reaches exactly the fields the fixture records under
# `meta$platform` — r_version, sysname, machine. Axes it does not record (BLAS,
# compiler, the glmmTMB/TMB linkage M107/M109 moved) are outside the gate, and
# nothing here claims otherwise; the identity check is what would catch them, by
# failing to reproduce.
#
# Run in the background (check for concurrent R sessions and live R.INSTALL
# processes first — M107/M109 lessons):
#   Rscript data-raw/m121-npbootstrap-skew-sweep.R
#
# Self-test (plants a defect into a copy of each thing this harness asserts, and
# requires each assertion to fire — a check that cannot fail is not a check):
#   Rscript data-raw/m121-npbootstrap-skew-sweep.R --self-test

suppressMessages(devtools::load_all(quiet = TRUE))
# Defines searle_f_ci_balanced() and burch_reml_ci_balanced() — the SAME
# prototypes M111 recorded its classical legs with; sourcing skips the file's
# `if (sys.nframe() == 0L)` oracle block.
source("data-raw/m76-classical-oneway-prototype.R")
# M120: the shared stale-checkpoint guard. Sourcing it installs the
# deserialization trace, so a checkpoint read that bypasses the guard fails the
# run rather than quietly seeding the table.
source("data-raw/checkpoint-guard.R")

# Paths are overridable so the self-test can never touch the committed inputs or
# outputs; the defaults are the committed ones.
fixture_path <- Sys.getenv(
  "M121_FIXTURE_IN",
  "data-raw/m111-fallback-results.rds"
)
out_path <- Sys.getenv(
  "M121_OUT",
  "data-raw/m121-npbootstrap-skew-coverage.tsv"
)
# Uncommitted per-cell resume cache; a re-run picks up past finished cells.
ckpt_dir <- Sys.getenv("M121_CKPT_DIR", "data-raw/m121-npbootstrap-checkpoints")
n_workers <- 4L

# The identity tolerance (plan gate 2026-08-15): 1e-12 rather than identical(),
# because exact equality is a property of the machine's summation order, and the
# platform gate above is what pins the machine.
identity_tol <- 1e-12

# ---- data generation ---------------------------------------------------------
# VERBATIM from data-raw/m111-fallback-sweep.R:59-78. It is copied rather than
# sourced because sourcing that file would run its 64-cell sweep's dependencies
# and bind its paths; the endpoint identity check below is what proves the copy
# still generates the fixture's datasets, so a drift between the two files fails
# this run rather than passing silently.
gen_oneway <- function(k, n, rho, dist, seed) {
  set.seed(seed)
  sd_a <- sqrt(rho)
  sd_e <- sqrt(1 - rho)
  a <- switch(
    dist,
    gaussian = stats::rnorm(k, 0, sd_a),
    t5 = stats::rt(k, df = 5) * sd_a / sqrt(5 / 3),
    uniform = (stats::runif(k) - 0.5) * sd_a / sqrt(1 / 12),
    chisq1 = (stats::rchisq(k, df = 1) - 1) * sd_a / sqrt(2),
    stop("unknown dist: ", dist)
  )
  vals <- rep(a, each = n) + stats::rnorm(k * n, 0, sd_e)
  data.frame(
    subject = rep(seq_len(k), each = n),
    rater = rep(seq_len(n), times = k),
    score = vals,
    y = vals # alias consumed by the prototype functions
  )
}

# ---- the platform gate -------------------------------------------------------
# The fixture's recorded platform is the machine whose RNG stream and summation
# order the recorded endpoints are a property of. Regenerating on another one is
# not a weaker comparison, it is a different experiment, so it aborts.
assert_platform <- function(meta) {
  want <- meta$platform
  if (is.null(want)) {
    stop(
      "the fixture records no platform, so regeneration cannot be gated ",
      "(M84/M105: the abort split and the summation order are both ",
      "platform-dependent)",
      call. = FALSE
    )
  }
  have <- list(
    r_version = R.version.string,
    sysname = Sys.info()[["sysname"]],
    machine = Sys.info()[["machine"]]
  )
  differing <- names(want)[
    vapply(
      names(want),
      function(nm) !identical(want[[nm]], have[[nm]]),
      logical(1)
    )
  ]
  if (length(differing)) {
    stop(
      "platform gate: this machine differs from the one that generated ",
      basename(fixture_path),
      " in ",
      paste(
        vapply(
          differing,
          function(nm) {
            sprintf(
              "%s (recorded '%s', current '%s')",
              nm,
              want[[nm]],
              have[[nm]]
            )
          },
          character(1)
        ),
        collapse = "; "
      ),
      " — the recorded endpoints are a property of that machine, so ",
      "regeneration would compare two different experiments",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# `parallel::mclapply` reports a worker killed by a signal or OOM as a NULL
# element and keeps the list's full length, so an `inherits(., "try-error")`
# test passes over a lost worker and the short result binds away silently
# (M112 lesson, verified there against a SIGKILLed worker). Both mclapply sites
# below route their results through this, so a lost worker is named where it
# happened rather than surfacing later as an opaque shape error.
mclapply_failures <- function(results, labels) {
  bad <- vapply(
    seq_along(results),
    function(i) inherits(results[[i]], "try-error") || is.null(results[[i]]),
    logical(1)
  )
  if (!any(bad)) {
    return(character(0))
  }
  vapply(
    which(bad),
    function(i) {
      if (is.null(results[[i]])) {
        sprintf("%s (worker lost: NULL result)", labels[[i]])
      } else {
        sprintf(
          "%s (%s)",
          labels[[i]],
          conditionMessage(attr(results[[i]], "condition"))
        )
      }
    },
    character(1)
  )
}

# ---- the published-oracle precondition (AC2) ---------------------------------
# Before a single grid cell is read, the shipped reducer is re-run at the SAME
# two per-rep seed streams data-raw/m75-npbootstrap-coverage.R:82,88 uses for the
# ukoumunne2003 Table I anchors, and each reproduced coverage must land within
# the +-0.03 that tests/testthat/test-ci-npbootstrap-coverage.R:31 already
# pre-registers against those figures. The bound is the repo's published one, not
# one invented here (GP5).
#
# What a green precondition does and does not license: the anchors are GAUSSIAN
# cells at rho = 0.05, and the grid below is the skew grid, so passing them is
# evidence about the REDUCER and never about the swept domain (GP6).
anchor_tol <- 0.03
anchor_n_rep <- 2000L
anchor_boot <- 999L
anchor_fixture <- "tests/testthat/fixtures/npbootstrap-coverage-oracle.rds"
# ukoumunne2003 Table I, n = 10 ratings, rho = 0.05, transformed bootstrap-t.
anchor_cells <- list(
  U10 = list(k = 10, n = 10, rho = 0.05, base = 50000000L, table_i = 0.938),
  U30 = list(k = 30, n = 10, rho = 0.05, base = 60000000L, table_i = 0.944),
  U50 = list(k = 50, n = 10, rho = 0.05, base = 70000000L, table_i = 0.9395)
)

# VERBATIM from data-raw/m75-npbootstrap-coverage.R:28-36 (its `sim_oneway`) —
# the anchors are only the anchors if the datasets are the ones M75 measured.
sim_oneway_gaussian <- function(k, n, rho, seed) {
  set.seed(seed)
  a <- stats::rnorm(k, 0, sqrt(rho))
  y <- rep(a, each = n) + stats::rnorm(k * n, 0, sqrt(1 - rho))
  data.frame(
    subject = factor(rep(seq_len(k), each = n)),
    rater = factor(rep(seq_len(n), times = k)),
    score = y
  )
}

# `reducer` is a parameter so the self-test can hand in a perturbed resample
# stream; every real call takes the shipped `npbootstrap_ci`.
anchor_coverage <- function(cl, n_rep, reducer) {
  ests <- list(
    icc_estimand(unit = "single", k_eff = NA_real_, oneway = TRUE),
    icc_estimand(unit = "average", k_eff = cl$n, oneway = TRUE)
  )
  covered <- logical(n_rep)
  for (r in seq_len(n_rep)) {
    d <- sim_oneway_gaussian(cl$k, cl$n, cl$rho, seed = cl$base + r)
    iv <- reducer(
      d,
      ests,
      conf_level = 0.95,
      boot_samples = anchor_boot,
      # The distinct per-rep resample stream (RR01 finding 2); omitting the
      # offset would red a correct package.
      seed = cl$base + 3000000L + r
    )
    covered[r] <- iv[[1]]$conf.low <= cl$rho && cl$rho <= iv[[1]]$conf.high
  }
  mean(covered)
}

# Returns the anchor table, or aborts classed. The committed fixture's value is
# reported beside each anchor as a DELTA and never as a bar: D-024 clause 2 makes
# oracle re-run divergence something to record and escalate, not to re-baseline
# or to fail on, and the operative gate is the published figure.
assert_anchors <- function(
  n_rep = anchor_n_rep,
  reducer = npbootstrap_ci,
  cells = anchor_cells,
  workers = 3L
) {
  fixture <- if (file.exists(anchor_fixture)) {
    ckpt_read_input(anchor_fixture)
  } else {
    NULL
  }
  got <- parallel::mclapply(
    names(cells),
    function(nm) anchor_coverage(cells[[nm]], n_rep, reducer),
    mc.cores = min(workers, length(cells))
  )
  lost <- mclapply_failures(got, names(cells))
  if (length(lost)) {
    rlang::abort(
      paste0("anchor validation errored at ", paste(lost, collapse = "; ")),
      class = c("intraclass_anchor_error", "intraclass_error")
    )
  }
  tab <- data.frame(
    anchor = names(cells),
    k = vapply(cells, function(cl) cl$k, numeric(1)),
    coverage = unlist(got),
    table_i = vapply(cells, function(cl) cl$table_i, numeric(1)),
    stringsAsFactors = FALSE
  )
  tab$delta_table_i <- tab$coverage - tab$table_i
  tab$fixture <- vapply(
    tab$anchor,
    function(nm) {
      if (is.null(fixture[[nm]])) NA_real_ else fixture[[nm]]$coverage_icc1
    },
    numeric(1)
  )
  tab$delta_fixture <- tab$coverage - tab$fixture
  rownames(tab) <- NULL
  miss <- which(abs(tab$delta_table_i) >= anchor_tol)
  if (length(miss)) {
    rlang::abort(
      paste0(
        "anchor validation failed: ",
        paste(
          sprintf(
            "%s reproduced %.4f against ukoumunne2003 Table I %.4f (delta %+.4f, tolerance +-%.2f)",
            tab$anchor[miss],
            tab$coverage[miss],
            tab$table_i[miss],
            tab$delta_table_i[miss],
            anchor_tol
          ),
          collapse = "; "
        ),
        " — the reducer does not reproduce its published oracle, so nothing is written"
      ),
      class = c("intraclass_anchor_miss", "intraclass_error")
    )
  }
  tab
}

# A reducer whose RESAMPLE STREAM is degenerate: `sample.int` is masked in a
# child of the package namespace, so every bootstrap resample is the identity
# one. The pivot then has zero spread and the interval collapses to a point, so
# coverage goes to ~0 and the anchors miss by a mile. A perturbation of the
# resample SEED would not do: measured 2026-08-15 on the U10 stream at 300 reps,
# colliding the resample stream with the data stream (0.9633) or holding it
# constant across reps (0.9533) both land within the tolerance of the correct
# stream (0.9567), because reseeding a correct resampler is statistically
# neutral. The plant has to change the draws, not their seed.
planted_stream_reducer <- function() {
  f <- npbootstrap_ci
  env <- new.env(parent = environment(f))
  env$sample.int <- function(n, size, replace = FALSE, ...) seq_len(n)
  environment(f) <- env
  f
}

# ---- the npbootstrap leg -----------------------------------------------------
np_boot_samples <- 999L
np_conf <- 0.95
# The npbootstrap resample stream, offset from the rep's data seed by 300000 —
# inside the cell's own 1e6 block, so no two cells' streams can meet, and clear
# of the +100000 offset M111's mc leg used on the same base.
np_seed_offset <- 300000L

# The abort caught here is any classed `intraclass_*` ERROR (every one carries
# `intraclass_error`, R/abort.R:34), and the leg's `aborted` flag is set from
# that condition — never from endpoint finiteness. A non-finite endpoint
# arriving WITHOUT a condition is a defect, so it raises rather than being
# quietly counted as an abort (the M112 T2 convention for the mc leg).
np_ci <- function(d, seed) {
  tryCatch(
    {
      td <- generics::tidy(icc(
        d,
        score,
        subject,
        rater,
        model = "oneway",
        ci_method = "npbootstrap",
        boot_samples = np_boot_samples,
        conf_level = np_conf,
        seed = seed
      ))
      i1 <- td[td$index == "ICC(1)", ]
      list(
        status = "ok",
        cond_class = NA_character_,
        lower = i1$conf.low,
        upper = i1$conf.high
      )
    },
    intraclass_error = function(e) {
      list(
        status = "abort",
        cond_class = class(e)[[1]],
        lower = NA_real_,
        upper = NA_real_
      )
    }
  )
}

# ---- per-cell regeneration + identity check + npbootstrap leg ----------------
# One rep: regenerate M111's dataset from its seed, re-verify the two classical
# legs against the fixture, and run the npbootstrap leg on that same dataset.
# Returns the np row and this rep's identity evidence.
one_rep <- function(cell, rep, fx_cell) {
  base <- cell$id * 1000000L + rep
  d <- gen_oneway(cell$k, cell$n, cell$rho, cell$dist, seed = base)
  n_compared <- 0L
  n_endpoints <- 0L
  max_delta <- 0
  for (m in c("searle", "burch")) {
    recorded <- fx_cell[fx_cell$rep == rep & fx_cell$method == m, ]
    if (nrow(recorded) != 1L) {
      stop(sprintf(
        "fixture holds %d %s rows for cell %d rep %d (want exactly 1)",
        nrow(recorded),
        m,
        cell$id,
        rep
      ))
    }
    ci <- if (m == "searle") {
      searle_f_ci_balanced(d)
    } else {
      burch_reml_ci_balanced(d)
    }
    deltas <- c(
      abs(ci[["lower"]] - recorded$lower),
      abs(ci[["upper"]] - recorded$upper)
    )
    if (!all(is.finite(deltas)) || any(deltas > identity_tol)) {
      stop(sprintf(
        paste0(
          "endpoint identity check failed at cell %d rep %d leg %s: ",
          "regenerated [%.17g, %.17g] vs recorded [%.17g, %.17g] ",
          "(max |delta| %.3g > %.3g) — the regenerated dataset is not the ",
          "one the fixture was computed from"
        ),
        cell$id,
        rep,
        m,
        ci[["lower"]],
        ci[["upper"]],
        recorded$lower,
        recorded$upper,
        max(deltas),
        identity_tol
      ))
    }
    n_compared <- n_compared + 1L
    # Counted from the vector actually compared, never as 2 * rows: the point
    # of the second count is that it goes short when an endpoint is skipped.
    n_endpoints <- n_endpoints + length(deltas)
    max_delta <- max(max_delta, deltas)
  }
  np <- np_ci(d, seed = base + np_seed_offset)
  aborted <- identical(np$status, "abort")
  finite_ci <- is.finite(np$lower) && is.finite(np$upper)
  if (!aborted && !finite_ci) {
    stop(sprintf(
      paste0(
        "npbootstrap leg returned a non-finite interval [%s, %s] without ",
        "signalling a classed intraclass_* condition (cell %d, rep %d)"
      ),
      format(np$lower),
      format(np$upper),
      cell$id,
      rep
    ))
  }
  list(
    row = data.frame(
      cell = cell$id,
      rho = cell$rho,
      k = cell$k,
      n = cell$n,
      dist = cell$dist,
      rep = rep,
      method = "npbootstrap",
      lower = np$lower,
      upper = np$upper,
      aborted = aborted,
      covered = !aborted && np$lower <= cell$rho && cell$rho <= np$upper,
      width = if (aborted) NA_real_ else np$upper - np$lower,
      lo_miss = !aborted && cell$rho < np$lower,
      hi_miss = !aborted && cell$rho > np$upper,
      cond_class = np$cond_class,
      stringsAsFactors = FALSE
    ),
    n_compared = n_compared,
    n_endpoints = n_endpoints,
    max_delta = max_delta
  )
}

# One cell: every rep, plus the cell's identity evidence rolled up. The evidence
# travels with the rows into the checkpoint, so a resumed cell contributes the
# count it actually compared rather than an assumed one.
cell_rows <- function(cell, fx) {
  fx_cell <- fx[fx$cell == cell$id, ]
  reps <- lapply(seq_len(cell$n_rep), function(rep) one_rep(cell, rep, fx_cell))
  list(
    id = cell$id,
    rows = do.call(rbind, lapply(reps, function(x) x$row)),
    n_compared = sum(vapply(reps, function(x) x$n_compared, integer(1))),
    n_endpoints = sum(vapply(reps, function(x) x$n_endpoints, integer(1))),
    max_delta = max(vapply(reps, function(x) x$max_delta, numeric(1)))
  )
}

# ---- grid --------------------------------------------------------------------
# Rebuilt from the fixture rather than re-declared, so the grid this harness
# sweeps is the grid the fixture holds by construction and cannot drift from it.
cells_from_fixture <- function(fx) {
  ids <- sort(unique(fx$cell))
  lapply(ids, function(id) {
    g <- fx[fx$cell == id, ]
    list(
      id = as.integer(id),
      rho = g$rho[1],
      k = as.integer(g$k[1]),
      n = as.integer(g$n[1]),
      dist = g$dist[1],
      n_rep = length(unique(g$rep))
    )
  })
}

# ---- aggregate identity assertion -------------------------------------------
# 64 cells x 2000 reps x 2 legs. Asserted against the grid the fixture holds AND
# against the frozen constant, so neither a short fixture nor a short loop can
# satisfy it.
assert_identity_evidence <- function(evidence, cells) {
  compared <- sum(vapply(evidence, function(e) e$n_compared, integer(1)))
  endpoints <- sum(vapply(evidence, function(e) e$n_endpoints, integer(1)))
  want_rows <- sum(vapply(cells, function(cell) cell$n_rep * 2L, integer(1)))
  if (!identical(want_rows, 256000L)) {
    stop(sprintf(
      "the fixture's grid is %d rows, not the frozen 64 x 2000 x 2 = 256000",
      want_rows
    ))
  }
  if (!identical(compared, want_rows)) {
    stop(sprintf(
      "endpoint identity check compared %d rows, want %d",
      compared,
      want_rows
    ))
  }
  if (!identical(endpoints, 2L * want_rows)) {
    stop(sprintf(
      "endpoint identity check compared %d endpoints, want %d (2 per row)",
      endpoints,
      2L * want_rows
    ))
  }
  invisible(max(vapply(evidence, function(e) e$max_delta, numeric(1))))
}

# ---- checkpointed sweep ------------------------------------------------------
# M120: the resume cache is keyed on the cell's design parameters AND a hash of
# the generating block, so a checkpoint written under any other grid or any
# earlier version of one_rep() is refused rather than served.
cell_spec <- function(cell) {
  ckpt_spec(
    params = list(
      rho = cell$rho,
      k = cell$k,
      n = cell$n,
      dist = cell$dist,
      n_rep = cell$n_rep,
      base_seed = cell$id * 1000000L
    ),
    roots = "one_rep",
    values = c(
      "identity_tol",
      "np_boot_samples",
      "np_conf",
      "np_seed_offset"
    ),
    site = "m121-npbootstrap-skew-sweep",
    envir = environment(gen_oneway)
  )
}

run_cell <- function(cell, fx, ckpt_dir) {
  ckpt <- file.path(ckpt_dir, sprintf("cell-%02d.rds", cell$id))
  if (file.exists(ckpt)) {
    return(ckpt_read(ckpt, cell_spec(cell)))
  }
  t0 <- Sys.time()
  res <- cell_rows(cell, fx)
  ckpt_write(ckpt, payload = res, spec = cell_spec(cell))
  cat(sprintf(
    "cell %2d/64 done: rho=%.2f k=%d n=%d %-8s (%.1f min, %d aborts)\n",
    cell$id,
    cell$rho,
    cell$k,
    cell$n,
    cell$dist,
    as.numeric(difftime(Sys.time(), t0, units = "mins")),
    sum(res$rows$aborted)
  ))
  res
}

# ---- the per-cell coverage table --------------------------------------------
# Column semantics are data-raw/m113-skew-response-derivation.R's, unchanged, so
# the fourth leg's row reads against the other three's without translation:
#   coverage_uncond   — mean(covered), an aborted rep counting as a miss
#   coverage_nonabort — mean(covered) among non-aborted reps
#   lo_miss/hi_miss   — tail-miss rates among non-aborted reps
#   width_ratio_vs_mc — med_width / the mc leg's med_width at that cell
one_group <- function(g) {
  data.frame(
    cell = g$cell[[1L]],
    rho = g$rho[[1L]],
    k = g$k[[1L]],
    n = g$n[[1L]],
    dist = g$dist[[1L]],
    method = g$method[[1L]],
    n_rep = nrow(g),
    n_abort = sum(g$aborted),
    coverage_uncond = mean(g$covered),
    coverage_nonabort = mean(g$covered[!g$aborted]),
    lo_miss = mean(g$lo_miss[!g$aborted]),
    hi_miss = mean(g$hi_miss[!g$aborted]),
    med_width = stats::median(g$width[!g$aborted]),
    stringsAsFactors = FALSE
  )
}

build_table <- function(np_rows, fx) {
  shared <- c(
    "cell",
    "rho",
    "k",
    "n",
    "dist",
    "rep",
    "method",
    "lower",
    "upper",
    "aborted",
    "covered",
    "width",
    "lo_miss",
    "hi_miss"
  )
  raw <- rbind(fx[shared], np_rows[shared])
  stopifnot(
    identical(nrow(raw), 64L * 2000L * 4L),
    identical(
      sort(unique(raw$method)),
      c("burch", "mc", "npbootstrap", "searle")
    )
  )
  tab <- do.call(
    rbind,
    lapply(split(raw, list(raw$cell, raw$method), drop = TRUE), one_group)
  )
  rownames(tab) <- NULL
  mc_width <- tab$med_width[tab$method == "mc"]
  names(mc_width) <- tab$cell[tab$method == "mc"]
  tab$width_ratio_vs_mc <- tab$med_width / mc_width[as.character(tab$cell)]
  stopifnot(identical(nrow(tab), 64L * 4L), all(tab$n_rep == 2000L))
  tab[order(tab$cell, tab$method), ]
}

write_table <- function(tab, path) {
  num <- vapply(tab, is.numeric, logical(1L))
  out <- tab
  out[num] <- lapply(
    out[num],
    function(x) trimws(formatC(x, digits = 10, format = "g"))
  )
  write.table(out, path, sep = "\t", quote = FALSE, row.names = FALSE)
  invisible(path)
}

# ---- self-test ---------------------------------------------------------------
# Plants a drift into a COPY of the fixture (one endpoint moved by 1e-9, three
# orders of magnitude above the tolerance) and requires the identity check to
# abort on that cell. Runs one cell, at a reduced rep count, in a temporary
# directory: the point is that the check bites, not that it is slow.
expect_abort <- function(expr, want, what) {
  got <- try(expr, silent = TRUE)
  if (!inherits(got, "try-error")) {
    stop("self-test FAILED: ", what, " did not abort", call. = FALSE)
  }
  msg <- conditionMessage(attr(got, "condition"))
  if (!grepl(want, msg, fixed = TRUE)) {
    stop(
      "self-test FAILED: ",
      what,
      " aborted, but not with the failure the probe is about — wanted a ",
      "message containing '",
      want,
      "', got: ",
      msg,
      call. = FALSE
    )
  }
  invisible(msg)
}

self_test <- function() {
  fx_all <- ckpt_read_input(fixture_path)
  fx <- fx_all$raw
  assert_platform(fx_all$meta)
  cell <- cells_from_fixture(fx)[[1]]
  cell$n_rep <- 20L

  # --- control: the unperturbed cell reproduces, so every abort below is the
  # plant's doing and not the harness failing to reproduce at all.
  clean <- try(cell_rows(cell, fx), silent = TRUE)
  if (inherits(clean, "try-error")) {
    stop(
      "self-test control failed: the unperturbed fixture does not reproduce ",
      "(so an abort under perturbation would prove nothing): ",
      conditionMessage(attr(clean, "condition"))
    )
  }
  if (!identical(clean$n_compared, 40L) || !identical(clean$n_endpoints, 80L)) {
    stop(sprintf(
      "self-test control compared %d rows / %d endpoints, want 40 / 80",
      clean$n_compared,
      clean$n_endpoints
    ))
  }
  if (clean$max_delta > identity_tol) {
    stop(sprintf(
      "self-test control reproduces only to %.3g, above the %.0e tolerance",
      clean$max_delta,
      identity_tol
    ))
  }

  # --- probe 1: the identity check, on every axis the drift family is free in.
  # Location (leg x endpoint) and magnitude both vary: a plant just above the
  # tolerance must abort and one just below must not, so the probe discriminates
  # THIS tolerance rather than any looser one that would pass a 1e-9 plant.
  plant_at <- function(rep, method, endpoint, delta) {
    hit <- which(fx$cell == cell$id & fx$rep == rep & fx$method == method)
    if (length(hit) != 1L) {
      stop("self-test could not locate the row to perturb", call. = FALSE)
    }
    bad <- fx
    bad[[endpoint]][hit] <- bad[[endpoint]][hit] + delta
    bad
  }
  plants <- list(
    list(rep = 7L, method = "searle", endpoint = "lower", delta = 1e-9),
    list(rep = 11L, method = "searle", endpoint = "upper", delta = 5e-12),
    list(rep = 3L, method = "burch", endpoint = "lower", delta = 5e-12),
    list(rep = 19L, method = "burch", endpoint = "upper", delta = 1e-9)
  )
  for (p in plants) {
    expect_abort(
      cell_rows(cell, plant_at(p$rep, p$method, p$endpoint, p$delta)),
      sprintf(
        "endpoint identity check failed at cell %d rep %d leg %s",
        cell$id,
        p$rep,
        p$method
      ),
      sprintf(
        "a %.0e plant on the %s %s endpoint",
        p$delta,
        p$method,
        p$endpoint
      )
    )
  }
  # The matched sub-tolerance plant: 5e-13 is a real perturbation of the same
  # site, and it must NOT abort. Without this the four aborts above are equally
  # consistent with a check that rejects any difference at all.
  under <- try(
    cell_rows(cell, plant_at(3L, "burch", "lower", 5e-13)),
    silent = TRUE
  )
  if (inherits(under, "try-error")) {
    stop(
      "self-test FAILED: a 5e-13 plant, below the 1e-12 tolerance, aborted — ",
      "the check is not discriminating the declared tolerance: ",
      conditionMessage(attr(under, "condition"))
    )
  }
  if (!(under$max_delta > 0 && under$max_delta <= identity_tol)) {
    stop(sprintf(
      "self-test FAILED: the sub-tolerance plant left max |delta| at %.3g — ",
      under$max_delta
    ))
  }

  # --- probe 2: the row/endpoint count assertions. A truncated cell is exactly
  # the "loop silently ran over nothing" failure the counts exist to catch.
  full_cells <- cells_from_fixture(fx)
  expect_abort(
    assert_identity_evidence(
      lapply(full_cells, function(cl) {
        list(id = cl$id, n_compared = 4000L, n_endpoints = 8000L, max_delta = 0)
      })[-1L],
      full_cells
    ),
    "compared 252000 rows, want 256000",
    "a cell missing from the identity evidence"
  )
  expect_abort(
    assert_identity_evidence(
      lapply(full_cells, function(cl) {
        list(id = cl$id, n_compared = 4000L, n_endpoints = 4000L, max_delta = 0)
      }),
      full_cells
    ),
    "compared 256000 endpoints, want 512000",
    "evidence comparing one endpoint per row"
  )

  # --- probe 3: the platform gate, once per recorded field plus the absent case.
  for (nm in names(fx_all$meta$platform)) {
    bad_meta <- fx_all$meta
    bad_meta$platform[[nm]] <- paste0(bad_meta$platform[[nm]], "-planted")
    msg <- expect_abort(
      assert_platform(bad_meta),
      "platform gate: this machine differs",
      sprintf("a perturbed %s", nm)
    )
    if (!grepl(nm, msg, fixed = TRUE)) {
      stop(
        "self-test FAILED: the platform abort did not name the differing ",
        "field ",
        nm,
        " — got: ",
        msg
      )
    }
  }
  expect_abort(
    assert_platform(list()),
    "the fixture records no platform",
    "a fixture with no recorded platform"
  )

  # --- probe 4: the anchor precondition. Run at a reduced rep count (the gate
  # itself pins 2000): the control has to pass and the plant has to miss, or the
  # abort would prove only that something went wrong.
  # U10 alone, at the cheapest rep count whose control clears the bound with
  # margin on this platform (0.9400 against Table I's 0.938 — every rep is
  # seeded, so this is a fixed number and not a coin flip). The gate itself runs
  # all three anchors at 2000.
  probe_reps <- 150L
  probe_cells <- anchor_cells["U10"]
  ctrl <- try(
    assert_anchors(n_rep = probe_reps, cells = probe_cells),
    silent = TRUE
  )
  if (inherits(ctrl, "try-error")) {
    stop(
      "self-test control failed: the shipped reducer misses its own anchors at ",
      probe_reps,
      " reps, so the planted miss below would prove nothing: ",
      conditionMessage(attr(ctrl, "condition"))
    )
  }
  planted <- try(
    assert_anchors(
      n_rep = probe_reps,
      reducer = planted_stream_reducer(),
      cells = probe_cells
    ),
    silent = TRUE
  )
  if (!inherits(planted, "try-error")) {
    stop(
      "self-test FAILED: a degenerate resample stream did not miss the anchors"
    )
  }
  cond <- attr(planted, "condition")
  if (!inherits(cond, "intraclass_anchor_miss")) {
    stop(
      "self-test FAILED: the planted run aborted with class ",
      paste(class(cond), collapse = "/"),
      ", not the anchor-miss condition the precondition is about: ",
      conditionMessage(cond)
    )
  }

  # --- probe 6: a lost mclapply worker. A killed child arrives as NULL, not as a
  # try-error, so the completeness test has to name it (M112). Planted directly
  # on the result list, because killing a real worker is not reproducible.
  if (length(mclapply_failures(list(1, 2), c("a", "b")))) {
    stop("self-test FAILED: mclapply_failures flagged two healthy results")
  }
  lost_report <- mclapply_failures(list(1, NULL), c("cell 1", "cell 2"))
  if (
    !identical(length(lost_report), 1L) ||
      !grepl("cell 2 (worker lost", lost_report[[1]], fixed = TRUE)
  ) {
    stop(
      "self-test FAILED: a NULL mclapply element was not reported as a lost ",
      "worker — got: ",
      paste(lost_report, collapse = "; ")
    )
  }
  errored <- try(stop("planted"), silent = TRUE)
  if (!length(mclapply_failures(list(errored), "cell 1"))) {
    stop("self-test FAILED: a try-error element was not reported")
  }

  # --- probe 5: a non-finite npbootstrap endpoint arriving WITHOUT a classed
  # condition must raise, not be counted as an abort (AC4). `np_ci` is masked in
  # a child of the harness's own environment, so the reducer's return is planted
  # without touching the leg's accounting.
  planted_np <- function(result) {
    f <- one_rep
    env <- new.env(parent = environment(f))
    env$np_ci <- function(d, seed) result
    environment(f) <- env
    f
  }
  fx_cell1 <- fx[fx$cell == cell$id, ]
  ok_row <- planted_np(list(
    status = "ok",
    cond_class = NA_character_,
    lower = 0.1,
    upper = 0.2
  ))(cell, 1L, fx_cell1)
  if (!identical(ok_row$row$aborted, FALSE)) {
    stop(
      "self-test control failed: a finite planted interval was counted as an abort"
    )
  }
  expect_abort(
    planted_np(list(
      status = "ok",
      cond_class = NA_character_,
      lower = NA_real_,
      upper = 0.2
    ))(cell, 1L, fx_cell1),
    "without signalling a classed intraclass_* condition",
    "a non-finite npbootstrap endpoint with no classed condition"
  )
  # And the converse: a classed condition IS counted, and from the class rather
  # than from the endpoints.
  ab_row <- planted_np(list(
    status = "abort",
    cond_class = "intraclass_singular_fit",
    lower = NA_real_,
    upper = NA_real_
  ))(cell, 1L, fx_cell1)
  if (
    !identical(ab_row$row$aborted, TRUE) ||
      !identical(ab_row$row$cond_class, "intraclass_singular_fit")
  ) {
    stop("self-test FAILED: a classed abort was not counted from its class")
  }

  cat(
    "self-test OK: control reproduces 40 rows / 80 endpoints exactly; four ",
    "leg x endpoint plants (two at 5e-12) each abort at their own row and a ",
    "5e-13 plant does not; both count assertions and the platform gate ",
    "(each recorded field, and an absent one) fire on planted defects; the ",
    "U10 anchor passes at ",
    probe_reps,
    " reps with the shipped reducer and abort intraclass_anchor_miss under a ",
    "degenerate resample stream; the npbootstrap leg raises on a non-finite ",
    "endpoint carrying no classed condition and counts an abort from its ",
    "condition class; a lost (NULL) mclapply worker is reported as lost.\n",
    sep = ""
  )
  invisible(TRUE)
}

# ---- the sweep ---------------------------------------------------------------
# Called from live top-level code below so the checkpoint routing walk reaches
# the guard calls inside it (data-raw/check-checkpoint-sites.R).
run_sweep <- function() {
  fx_all <- ckpt_read_input(fixture_path)
  fx <- fx_all$raw
  assert_platform(fx_all$meta)
  cells <- cells_from_fixture(fx)
  # AC2: before any grid cell is read, and before anything is written.
  cat("validating the ukoumunne2003 Table I anchors (n_rep = 2000)\n")
  anchors <- assert_anchors()
  print(anchors, row.names = FALSE, digits = 5)
  cat(sprintf(
    "anchors OK: worst |delta| vs Table I %.4f (tolerance %.2f); worst |delta| vs the committed fixture %.4f, recorded not gated (D-024 clause 2)\n",
    max(abs(anchors$delta_table_i)),
    anchor_tol,
    max(abs(anchors$delta_fixture))
  ))
  cat(sprintf(
    "regenerating %d cells from the M111 seed scheme and adding the npbootstrap leg (%d workers)\n",
    length(cells),
    n_workers
  ))
  dir.create(ckpt_dir, showWarnings = FALSE, recursive = TRUE)
  ckpt_trace_register(ckpt_dir)
  evidence <- parallel::mclapply(
    cells,
    function(cell) run_cell(cell, fx, ckpt_dir),
    mc.cores = n_workers
  )
  lost <- mclapply_failures(
    evidence,
    vapply(cells, function(cell) sprintf("cell %d", cell$id), character(1))
  )
  if (length(lost)) {
    stop("cells errored: ", paste(lost, collapse = "; "))
  }
  # Before anything is written: no cell may have come from an unguarded read.
  ckpt_trace_assert()
  worst <- assert_identity_evidence(evidence, cells)
  cat(sprintf(
    "endpoint identity check: 256000 rows / 512000 endpoints match within %.0e (worst |delta| %.3g)\n",
    identity_tol,
    worst
  ))
  np_rows <- do.call(rbind, lapply(evidence, function(e) e$rows))
  tab <- build_table(np_rows, fx)
  write_table(tab, out_path)
  cat(sprintf("wrote %s (%d rows)\n", out_path, nrow(tab)))
  aborts <- np_rows$cond_class[np_rows$aborted]
  cat("npbootstrap abort classes: ")
  cat(
    if (length(aborts)) {
      paste(
        sprintf("%s x %d", names(table(aborts)), as.integer(table(aborts))),
        collapse = ", "
      )
    } else {
      "none"
    }
  )
  cat("\n")
  np <- tab[tab$method == "npbootstrap", ]
  cat(sprintf(
    "npbootstrap: %d/64 cells below 0.93 coverage_uncond; worst %.4f at (rho=%.2f, k=%d, n=%d, %s)\n",
    sum(np$coverage_uncond < 0.93),
    min(np$coverage_uncond),
    np$rho[which.min(np$coverage_uncond)],
    np$k[which.min(np$coverage_uncond)],
    np$n[which.min(np$coverage_uncond)],
    np$dist[which.min(np$coverage_uncond)]
  ))
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  if ("--self-test" %in% commandArgs(trailingOnly = TRUE)) {
    self_test()
    quit(save = "no")
  }
  run_sweep()
}
