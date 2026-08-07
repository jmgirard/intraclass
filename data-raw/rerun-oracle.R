# rerun-oracle.R -- the M107 oracle-script re-run harness (D-024).
#
# Re-runs a seeded data-raw/oracle-*.R script and compares what it produces
# against what the repo commits, WITHOUT touching any committed file:
#   * every saveRDS() the script makes is redirected to a scratch directory
#     outside the worktree (tempdir()), so committed fixtures are compared,
#     never modified (M107 AC2);
#   * every stopifnot() the script makes is evaluated NON-fatally -- each
#     call's conditions are checked and recorded block-by-block, and the run
#     continues past a failure, so all pins report even when an early one
#     fails (M107 AC5);
#   * the run's engine/package versions are captured beside the verdict, so
#     a later divergence can be attributed (or not) to an engine upgrade.
#
# Verdicts (D-024 -- pins are the bar; escalate, never re-baseline):
#   fixture-writing script:  reproduced | drift-within-noise | diverged-escalated
#   no-fixture script:       pins-pass  | pins-fail-escalated
# A committed fixture is NEVER overwritten by a re-run; re-baselining is an
# escalation outcome the maintainer decides, not a harness behavior.
#
# Usage (from the repo root):
#   Rscript data-raw/rerun-oracle.R oracle-multilevel.R [oracle-sem.R ...]
# Ledger: data-raw/oracle-rerun-ledger.tsv -- one row per script (a re-run
# replaces the script's row; git history keeps earlier rows).

ledger_path <- file.path("data-raw", "oracle-rerun-ledger.tsv")
fixture_dir <- file.path("tests", "testthat", "fixtures")

# Numeric leaves are compared with this tolerance to split "reproduced"
# (bit-level agreement up to roundoff) from "drift-within-noise".
reproduced_tol <- 1e-12

version_or_na <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    as.character(utils::packageVersion(pkg))
  } else {
    NA_character_
  }
}

# Recursively collect named numeric leaves of a fixture object.
numeric_leaves <- function(x, prefix = "") {
  if (is.list(x)) {
    out <- list()
    nms <- names(x)
    if (is.null(nms)) {
      nms <- as.character(seq_along(x))
    }
    for (i in seq_along(x)) {
      out <- c(
        out,
        numeric_leaves(x[[i]], paste0(prefix, "$", nms[[i]]))
      )
    }
    out
  } else if (is.data.frame(x)) {
    out <- list()
    for (nm in names(x)) {
      if (is.numeric(x[[nm]])) {
        out[[paste0(prefix, "$", nm)]] <- x[[nm]]
      }
    }
    out
  } else if (is.numeric(x)) {
    stats::setNames(list(x), prefix)
  } else {
    list()
  }
}

# Compare a fresh fixture object against the committed one; returns the max
# absolute difference over shared numeric leaves plus a structural note.
compare_fixtures <- function(fresh, committed) {
  fl <- numeric_leaves(fresh)
  cl <- numeric_leaves(committed)
  shared <- intersect(names(fl), names(cl))
  shared <- setdiff(shared, "$generated")
  deltas <- vapply(
    shared,
    function(nm) {
      a <- fl[[nm]]
      b <- cl[[nm]]
      if (length(a) != length(b)) {
        return(Inf)
      }
      m <- suppressWarnings(max(abs(a - b)))
      if (is.na(m)) Inf else m
    },
    numeric(1)
  )
  only_fresh <- setdiff(names(fl), names(cl))
  only_committed <- setdiff(names(cl), names(fl))
  note <- ""
  if (length(only_fresh) || length(only_committed)) {
    note <- paste0(
      "leaf mismatch: fresh-only [",
      paste(only_fresh, collapse = ","),
      "] committed-only [",
      paste(only_committed, collapse = ","),
      "]"
    )
  }
  list(
    max_abs_delta = if (length(deltas)) max(deltas) else NA_real_,
    n_leaves = length(shared),
    note = note
  )
}

rerun_one <- function(script_name) {
  script_path <- file.path("data-raw", script_name)
  stopifnot(file.exists(script_path))
  scratch <- file.path(
    tempdir(),
    paste0("rerun-", sub("\\.R$", "", script_name))
  )
  dir.create(scratch, showWarnings = FALSE, recursive = TRUE)

  pin_log <- new.env(parent = emptyenv())
  pin_log$rows <- list()
  write_log <- new.env(parent = emptyenv())
  write_log$rows <- list()

  # Non-fatal stopifnot: evaluate each condition of each call, record the
  # call's verdict, never abort the sourced script.
  recording_stopifnot <- function(...) {
    exprs <- as.list(substitute(list(...)))[-1L]
    labels <- names(exprs)
    ok <- TRUE
    detail <- character(0)
    for (i in seq_along(exprs)) {
      val <- tryCatch(
        eval(exprs[[i]], envir = parent.frame()),
        error = function(e) e
      )
      cond_ok <- is.logical(val) && length(val) > 0 && all(val)
      if (!isTRUE(cond_ok)) {
        ok <- FALSE
        lab <- if (!is.null(labels) && nzchar(labels[i] %||% "")) {
          labels[[i]]
        } else {
          paste(deparse(exprs[[i]]), collapse = " ")
        }
        detail <- c(detail, lab)
      }
    }
    pin_log$rows[[length(pin_log$rows) + 1L]] <- list(
      ok = ok,
      detail = paste(detail, collapse = " & ")
    )
    invisible(ok)
  }

  redirecting_save_rds <- function(object, file = "", ...) {
    dest <- file.path(scratch, basename(file))
    base::saveRDS(object, dest, ...)
    write_log$rows[[length(write_log$rows) + 1L]] <- list(
      original = file,
      redirected = dest
    )
    invisible(dest)
  }

  run_env <- new.env(parent = globalenv())
  assign("stopifnot", recording_stopifnot, envir = run_env)
  # The name must be exactly saveRDS to shadow base::saveRDS in the script.
  assign("saveRDS", redirecting_save_rds, envir = run_env) # nolint: object_name_linter.

  message("== re-running ", script_name, " (writes -> ", scratch, ")")
  t0 <- Sys.time()
  source_err <- tryCatch(
    {
      source(script_path, local = run_env, chdir = FALSE)
      NULL
    },
    error = function(e) conditionMessage(e)
  )
  elapsed_min <- round(
    as.numeric(difftime(Sys.time(), t0, units = "mins")),
    2
  )

  pins <- pin_log$rows
  n_pins <- length(pins)
  n_pass <- sum(vapply(pins, function(p) isTRUE(p$ok), logical(1)))
  failed <- Filter(function(p) !isTRUE(p$ok), pins)
  pin_detail <- paste(
    vapply(failed, function(p) p$detail, character(1)),
    collapse = "; "
  )

  # Fixture comparison: every redirected write whose ORIGINAL destination is
  # a committed file under tests/testthat/fixtures/.
  writes <- write_log$rows
  fixture_writes <- Filter(
    function(w) {
      normalizePath(dirname(w$original), mustWork = FALSE) ==
        normalizePath(fixture_dir, mustWork = FALSE) &&
        file.exists(w$original)
    },
    writes
  )
  max_abs_delta <- NA_real_
  n_leaves <- NA_integer_
  compare_note <- ""
  for (w in fixture_writes) {
    cmp <- compare_fixtures(readRDS(w$redirected), readRDS(w$original))
    if (is.na(max_abs_delta) || cmp$max_abs_delta > max_abs_delta) {
      max_abs_delta <- cmp$max_abs_delta
      n_leaves <- cmp$n_leaves
      compare_note <- cmp$note
    }
  }

  is_fixture_script <- length(fixture_writes) > 0
  pins_ok <- n_pass == n_pins && is.null(source_err)
  verdict <- if (is_fixture_script) {
    if (!pins_ok) {
      "diverged-escalated"
    } else if (!is.na(max_abs_delta) && max_abs_delta <= reproduced_tol) {
      "reproduced"
    } else {
      "drift-within-noise"
    }
  } else {
    if (pins_ok) "pins-pass" else "pins-fail-escalated"
  }

  notes <- c(
    if (!is.null(source_err)) paste0("source error: ", source_err),
    if (nzchar(compare_note)) compare_note,
    paste0("elapsed_min=", elapsed_min)
  )

  data.frame(
    script = script_name,
    run_date = format(Sys.Date()),
    verdict = verdict,
    pins = paste0(n_pass, "/", n_pins),
    pin_detail = pin_detail,
    max_abs_delta = if (is.na(max_abs_delta)) {
      "NA"
    } else {
      formatC(max_abs_delta, format = "e", digits = 3)
    },
    n_compared_leaves = n_leaves,
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    glmmtmb = version_or_na("glmmTMB"),
    lme4 = version_or_na("lme4"),
    brms = version_or_na("brms"),
    rstan = version_or_na("rstan"),
    stanheaders = version_or_na("StanHeaders"),
    lavaan = version_or_na("lavaan"),
    notes = paste(notes, collapse = "; "),
    stringsAsFactors = FALSE
  )
}

`%||%` <- function(a, b) if (is.null(a)) b else a

update_ledger <- function(row) {
  ledger <- if (file.exists(ledger_path)) {
    utils::read.delim(
      ledger_path,
      stringsAsFactors = FALSE,
      na.strings = NULL,
      colClasses = "character"
    )
  } else {
    NULL
  }
  row[] <- lapply(row, as.character)
  if (!is.null(ledger)) {
    ledger <- ledger[ledger$script != row$script, , drop = FALSE]
    ledger <- rbind(ledger, row)
    ledger <- ledger[order(ledger$script), , drop = FALSE]
  } else {
    ledger <- row
  }
  utils::write.table(
    ledger,
    ledger_path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
  )
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("usage: Rscript data-raw/rerun-oracle.R <oracle-script.R> [...]")
}
for (script_name in args) {
  row <- rerun_one(script_name)
  update_ledger(row)
  message(
    "== ",
    script_name,
    ": ",
    row$verdict,
    " (pins ",
    row$pins,
    ", max_abs_delta ",
    row$max_abs_delta,
    ")"
  )
}
