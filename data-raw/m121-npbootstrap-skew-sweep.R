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

# ---- per-cell regeneration + identity check ----------------------------------
# Returns the per-rep regenerated rows for one cell together with the identity
# evidence (how many endpoint pairs were compared and the worst absolute
# difference), so the aggregate count assertion is made over recorded evidence
# rather than over an assumption about what the loop did.
cell_rows <- function(cell, fx) {
  fx_cell <- fx[fx$cell == cell$id, ]
  n_compared <- 0L
  n_endpoints <- 0L
  max_delta <- 0
  for (rep in seq_len(cell$n_rep)) {
    base <- cell$id * 1000000L + rep
    d <- gen_oneway(cell$k, cell$n, cell$rho, cell$dist, seed = base)
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
  }
  list(
    id = cell$id,
    n_compared = n_compared,
    n_endpoints = n_endpoints,
    max_delta = max_delta
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
  fx_all <- readRDS(fixture_path)
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

  cat(
    "self-test OK: control reproduces 40 rows / 80 endpoints exactly; four ",
    "leg x endpoint plants (two at 5e-12) each abort at their own row and a ",
    "5e-13 plant does not; both count assertions and the platform gate ",
    "(each recorded field, and an absent one) fire on planted defects.\n",
    sep = ""
  )
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  if ("--self-test" %in% commandArgs(trailingOnly = TRUE)) {
    self_test()
  } else {
    fx_all <- readRDS(fixture_path)
    fx <- fx_all$raw
    assert_platform(fx_all$meta)
    cells <- cells_from_fixture(fx)
    cat(sprintf(
      "regenerating %d cells from the M111 seed scheme (%d workers)\n",
      length(cells),
      n_workers
    ))
    evidence <- parallel::mclapply(
      cells,
      function(cell) cell_rows(cell, fx),
      mc.cores = n_workers
    )
    failed <- vapply(evidence, inherits, logical(1), what = "try-error")
    if (any(failed)) {
      stop(
        "cells errored: ",
        paste(
          vapply(
            which(failed),
            function(i) {
              sprintf(
                "%d (%s)",
                i,
                conditionMessage(attr(evidence[[i]], "condition"))
              )
            },
            character(1)
          ),
          collapse = "; "
        )
      )
    }
    worst <- assert_identity_evidence(evidence, cells)
    cat(sprintf(
      "endpoint identity check: 256000 rows / 512000 endpoints match within %.0e (worst |delta| %.3g)\n",
      identity_tol,
      worst
    ))
  }
}
