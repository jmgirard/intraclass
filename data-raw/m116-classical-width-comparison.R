# M116 T2 — burch vs searle interval WIDTH, re-derived from the two committed
# classical grids. No sweep, no fits, no seed: pure aggregation over committed
# fixtures, so this script is deterministic and re-runnable anywhere.
#
# Why it exists: the package shipped "burch is wider than searle" / "searle is
# narrowest on near-normal data" at six user-facing sites. No source supports it
# (cairn/references/searle1971.md, mcgraw1996.md, burch2011.md) and both grids
# below measure the opposite. This script is the measurement those doc rewrites
# cite.
#
# Inputs (both committed):
#   data-raw/m76-sweep-results.rds            — the M76 GO/NO-GO sweep (D-012)
#   data-raw/m113-skew-response-coverage.tsv  — the M113 re-derivation (D-027)
# Output (committed text fixture):
#   data-raw/m116-classical-width-comparison.tsv
#
# COMPARATOR FENCE: searle vs burch only. Both legs abort in 0 cells of both
# grids, so their median widths are computed over the same reps and compare
# directly. The MC leg is deliberately excluded — its widths are conditioned on
# its non-aborted reps (up to 764 of 2000 aborted at one M113 cell), so ranking
# it against non-aborting legs measures selection, not width. This is the same
# artifact cairn/references/classical-oneway-comparison.md flags for C3.
#
# DGP FENCE: neither grid varies the ERROR term's distribution. Both draw the
# subject effect from `dist` and the error always from rnorm. That is asserted
# below against the generating scripts' PARSED bodies, because the fixtures carry
# only a `dist` label and cannot witness it.

# Run from the repo root, like the sibling data-raw scripts.
stopifnot("run this from the repo root" = file.exists("DESCRIPTION"))

# --- the DGP fence, asserted against the generating scripts --------------------
# M113's tsv re-derives data-raw/m111-fallback-results.rds (it runs no sweep of
# its own), so the M111 sweep script is the M113 grid's generator.
# Checked on the PARSED body, not on line text. Two weaker guards were tried and
# both were defeated: a lexical search for the t-generator matches `sqrt(`, which
# contains `rt(`; and a positional rule ("no non-gaussian call at or below the
# error line") passes as soon as the offending draw is hoisted into a variable
# one line above. Only the AST states the actual property.
rng_calls <- function(expr) {
  # every random-generator function called anywhere inside `expr`
  out <- character(0)
  walk <- function(e) {
    if (is.call(e)) {
      fn <- e[[1]]
      nm <- if (is.name(fn)) {
        as.character(fn)
      } else if (is.call(fn) && identical(as.character(fn[[1]]), "::")) {
        as.character(fn[[3]])
      } else {
        ""
      }
      if (grepl("^r[a-z]+$", nm) && nm != "rep" && nm != "return") {
        out <<- c(out, nm)
      }
      for (i in seq_along(e)) {
        if (!is.null(e[[i]]) && !identical(e[[i]], quote(expr = ))) walk(e[[i]])
      }
    }
  }
  walk(expr)
  out
}

assert_subject_only_dgp <- function(path) {
  exprs <- parse(path)
  gen <- NULL
  for (e in exprs) {
    if (
      is.call(e) &&
        as.character(e[[1]]) %in% c("<-", "=") &&
        identical(as.character(e[[2]]), "gen_oneway")
    ) {
      gen <- e[[3]]
    }
  }
  if (is.null(gen)) {
    stop("gen_oneway() not found in ", path)
  }

  body_exprs <- as.list(body(eval(gen)))
  assigns <- Filter(
    function(e) is.call(e) && as.character(e[[1]]) %in% c("<-", "="),
    body_exprs
  )
  named <- function(nm) {
    hit <- Filter(function(e) identical(as.character(e[[2]]), nm), assigns)
    if (length(hit) != 1L) {
      stop("expected exactly one `", nm, " <- ...` in ", path)
    }
    hit[[1]][[3]]
  }

  subject_rhs <- named("a")
  vals_rhs <- named("vals")

  # 1. the subject effect is the only thing that depends on `dist`
  stopifnot(
    "subject effect does not branch on dist" = grepl(
      "\\bdist\\b",
      paste(deparse(subject_rhs), collapse = " ")
    )
  )
  # 2. the error component is drawn by rnorm and nothing else
  stopifnot(
    "the error term uses a non-rnorm generator" = all(
      rng_calls(vals_rhs) == "rnorm"
    ),
    "the error term draws no random numbers at all" = length(rng_calls(
      vals_rhs
    )) >=
      1L
  )
  # 3. nothing between the two assignments smuggles in another draw: every
  #    generator call in the whole body belongs to one of the two right-hand
  #    sides above.
  all_calls <- unlist(lapply(assigns, function(e) rng_calls(e[[3]])))
  accounted <- c(rng_calls(subject_rhs), rng_calls(vals_rhs))
  stopifnot(
    "a random draw happens outside the subject effect and the error term" = length(
      all_calls
    ) ==
      length(accounted)
  )
  invisible(TRUE)
}

dgp_scripts <- c(
  "data-raw/m76-coverage-sweep.R",
  "data-raw/m111-fallback-sweep.R"
)
invisible(lapply(dgp_scripts, assert_subject_only_dgp))

# --- grid 1: M76 (.rds) --------------------------------------------------------
m76 <- as.data.frame(readRDS("data-raw/m76-sweep-results.rds")$summary)
m76 <- m76[m76$method %in% c("searle", "burch"), ]
stopifnot("M76: a classical leg aborts" = all(m76$abort_rate == 0))

# --- grid 2: M113 (.tsv) -------------------------------------------------------
m113 <- utils::read.delim(
  "data-raw/m113-skew-response-coverage.tsv",
  stringsAsFactors = FALSE
)
m113 <- m113[m113$method %in% c("searle", "burch"), ]
stopifnot("M113: a classical leg aborts" = all(m113$n_abort == 0))

# --- one comparison routine over both -----------------------------------------
compare <- function(d, width_col, grid) {
  cell <- interaction(d$rho, d$k, d$n, d$dist, drop = TRUE)
  split_cells <- split(d, cell)
  per_cell <- do.call(
    rbind,
    lapply(split_cells, function(x) {
      stopifnot("cell is not exactly one searle + one burch" = nrow(x) == 2L)
      b <- x[[width_col]][x$method == "burch"]
      s <- x[[width_col]][x$method == "searle"]
      data.frame(
        grid = grid,
        rho = x$rho[1],
        k = x$k[1],
        n = x$n[1],
        dist = x$dist[1],
        burch_width = b,
        searle_width = s,
        ratio = b / s,
        burch_narrower = b < s
      )
    })
  )
  per_cell[order(per_cell$dist, per_cell$rho, per_cell$k, per_cell$n), ]
}

cells <- rbind(
  compare(m76, "median_width", "m76"),
  compare(m113, "med_width", "m113")
)

# --- the figures the docs cite -------------------------------------------------
summarize_grid <- function(d, grid, dist) {
  x <- d[d$grid == grid & (is.na(dist) | d$dist == dist), ]
  data.frame(
    grid = grid,
    dist = if (is.na(dist)) "all" else dist,
    cells = nrow(x),
    burch_narrower = sum(x$burch_narrower),
    ratio_min = round(min(x$ratio), 4),
    ratio_median = round(stats::median(x$ratio), 4),
    ratio_max = round(max(x$ratio), 4)
  )
}

keys <- do.call(
  rbind,
  lapply(c("m76", "m113"), function(g) {
    ds <- sort(unique(cells$dist[cells$grid == g]))
    data.frame(grid = g, dist = c(NA_character_, ds), stringsAsFactors = FALSE)
  })
)
summary_tbl <- do.call(
  rbind,
  Map(function(g, d) summarize_grid(cells, g, d), keys$grid, keys$dist)
)
rownames(summary_tbl) <- NULL

# --- pins: the figures the prose sites are allowed to state --------------------
pick <- function(grid, dist) {
  summary_tbl[summary_tbl$grid == grid & summary_tbl$dist == dist, ]
}
stopifnot(
  "M76 all-cell count moved" = pick("m76", "all")$cells == 16L,
  "M76 narrower count moved" = pick("m76", "all")$burch_narrower == 16L,
  "M76 gaussian count moved" = pick("m76", "gaussian")$burch_narrower == 8L,
  "M113 all-cell count moved" = pick("m113", "all")$cells == 64L,
  "M113 narrower count moved" = pick("m113", "all")$burch_narrower == 59L,
  "M113 gaussian count moved" = pick("m113", "gaussian")$burch_narrower == 14L,
  "M113 uniform count moved" = pick("m113", "uniform")$burch_narrower == 16L,
  "M113 t5 count moved" = pick("m113", "t5")$burch_narrower == 15L,
  "M113 chisq1 count moved" = pick("m113", "chisq1")$burch_narrower == 14L
)

# Every family's median ratio is below 1 on both grids — the claim the docs make
# is "narrower in nearly every cell of both grids", never a kurtosis-conditional
# direction, because no family here reverses.
stopifnot(
  "a family's median ratio is not below 1" = all(summary_tbl$ratio_median < 1)
)

header <- c(
  "# M116 burch-vs-searle interval width over the two committed classical grids.",
  "# Generator: data-raw/m116-classical-width-comparison.R (deterministic, no seed).",
  "# Sources: data-raw/m76-sweep-results.rds (M76/D-012) and",
  "#          data-raw/m113-skew-response-coverage.tsv (M113/D-027, itself a",
  "#          re-derivation of data-raw/m111-fallback-results.rds).",
  "# Comparator: searle vs burch only; both abort in 0 cells of both grids. The MC",
  "#          leg is excluded because its widths are conditioned on non-aborted reps.",
  "# DGP: both grids draw the SUBJECT EFFECT from `dist` and the error always from",
  "#          rnorm, asserted by the generator against the sweep scripts' source.",
  "#          Burch (2011) measures with BOTH effects non-normal, so his reported",
  "#          leptokurtic reversal is untested here, not refuted.",
  "# ratio = burch median width / searle median width; < 1 means burch is NARROWER."
)

as_tsv <- function(d) {
  con <- textConnection(NULL, "w")
  on.exit(close(con))
  utils::write.table(d, con, sep = "\t", row.names = FALSE, quote = FALSE)
  textConnectionValue(con)
}

out <- "data-raw/m116-classical-width-comparison.tsv"
writeLines(
  c(header, as_tsv(summary_tbl), "", "# per-cell detail", as_tsv(cells)),
  out
)

print(summary_tbl)
cat("\nwrote ", out, "\n", sep = "")
