# M120 — the checkpoint staleness guard shared by the data-raw resume harnesses.
#
# The defect this exists to stop: a harness that resumes from a cache keyed on
# an index alone serves rows the current design never computed, and every
# downstream completeness guard passes because the rows are well-formed. On the
# oracle harnesses that is a fabricated "reproduced" verdict; on the M111 sweep
# it is a grid silently mixed across two designs.
#
# Two things are compared on resume, because a cache goes stale two ways:
#   * the declared design PARAMETERS, in the order data-raw/checkpoint-sites.tsv
#     declares for that site (the mismatch names the EARLIEST differing one), and
#   * a hash of the declared GENERATING BLOCK — the functions that actually
#     produce the cached rows. Scoping the hash to those bodies is deliberate: a
#     whole-file fingerprint would mark every cache stale after any comment edit,
#     leaving a permanently-cold cache and an override to defeat it.
# Anything that fails to compare aborts. Nothing here ever recomputes silently,
# and nothing here writes to a path the caller did not name.
#
# The trace at the bottom is the other half. Comparing specs only protects reads
# that come THROUGH this file; the trace watches deserialization itself, so a
# bare readRDS() of a registered checkpoint fails the run whatever spelling it
# was written in.

# ---- spec construction -------------------------------------------------------

# Hash the declared generating block: the deparsed BODIES of the named
# functions, in the declared order, under their declared names. Base R only —
# tools::md5sum needs a file, so the deparsed text goes through a tempfile.
ckpt_block_hash <- function(block, envir = parent.frame()) {
  if (!length(block)) {
    stop("checkpoint spec: no declared generating block", call. = FALSE)
  }
  text <- unlist(lapply(block, function(nm) {
    fn <- get0(nm, envir = envir, mode = "function")
    if (is.null(fn)) {
      stop(
        "checkpoint spec: declared block function not found: ",
        nm,
        call. = FALSE
      )
    }
    c(paste0("## ", nm), deparse(body(fn)))
  }))
  f <- tempfile("ckpt-block-")
  on.exit(unlink(f), add = TRUE)
  writeLines(text, f)
  unname(tools::md5sum(f))
}

# `params` is a NAMED list whose order is the declared order. An empty one is
# refused here rather than at read time: a spec that records nothing never
# mismatches, and a guard that never mismatches is indistinguishable from no
# guard at all.
ckpt_spec <- function(params, block, site, envir = parent.frame()) {
  if (!is.list(params) || !length(params) || is.null(names(params))) {
    stop(
      "checkpoint spec: no declared parameters (a spec that records nothing ",
      "can never go stale, so it is refused at construction)",
      call. = FALSE
    )
  }
  if (any(!nzchar(names(params)))) {
    stop(
      "checkpoint spec: every declared parameter needs a name",
      call. = FALSE
    )
  }
  list(
    site = site,
    params = params,
    order = names(params),
    block = block,
    block_hash = ckpt_block_hash(block, envir = envir)
  )
}

# The first difference between a recorded spec and the current one, as a
# message, or NULL when they agree. Site first (a foreign cache at the expected
# path is not a parameter question), then parameters in DECLARED order, then the
# generating block.
ckpt_spec_mismatch <- function(recorded, current) {
  if (!identical(recorded$site, current$site)) {
    return(sprintf(
      "written by a different site: recorded '%s', current '%s'",
      recorded$site,
      current$site
    ))
  }
  if (!identical(recorded$order, current$order)) {
    return(sprintf(
      "declared parameter set changed: recorded (%s), current (%s)",
      paste(recorded$order, collapse = ", "),
      paste(current$order, collapse = ", ")
    ))
  }
  for (nm in current$order) {
    if (!isTRUE(all.equal(recorded$params[[nm]], current$params[[nm]]))) {
      return(sprintf(
        "%s changed: recorded %s, current %s",
        nm,
        ckpt_fmt(recorded$params[[nm]]),
        ckpt_fmt(current$params[[nm]])
      ))
    }
  }
  if (!identical(recorded$block_hash, current$block_hash)) {
    return(sprintf(
      "the generating block changed (%s); every declared parameter still matches",
      paste(current$block, collapse = ", ")
    ))
  }
  NULL
}

ckpt_fmt <- function(x) {
  if (length(x) > 4L) {
    return(sprintf("<%s[%d]>", class(x)[1], length(x)))
  }
  paste(format(x), collapse = "/")
}

# ---- guarded write / read ----------------------------------------------------

ckpt_write <- function(path, payload, spec) {
  dir <- dirname(path)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  saveRDS(list(ckpt_spec = spec, payload = payload), path)
  invisible(path)
}

# Returns the cached payload, or aborts naming the first difference. A cache
# with no recorded spec is refused rather than trusted: every checkpoint written
# before this guard existed is exactly that file, and its provenance is unknown.
ckpt_read <- function(path, spec) {
  ckpt_trace_note(path, guarded = TRUE)
  ckpt_trace_state$in_guard <- TRUE
  on.exit(ckpt_trace_state$in_guard <- FALSE, add = TRUE)
  raw <- readRDS(path)
  if (!is.list(raw) || is.null(raw$ckpt_spec)) {
    stop(
      "stale-checkpoint guard: ",
      path,
      " carries no recorded spec, so what design produced it is unknown ",
      "(delete it and let the run recompute)",
      call. = FALSE
    )
  }
  bad <- ckpt_spec_mismatch(raw$ckpt_spec, spec)
  if (!is.null(bad)) {
    stop(
      "stale-checkpoint guard: ",
      path,
      " was not computed under the current design -- ",
      bad,
      " (delete the checkpoint and let the run recompute)",
      call. = FALSE
    )
  }
  raw$payload
}

# ---- multi-entry stores ------------------------------------------------------
# A harness that checkpoints one FILE holding many entries (a rep list, a
# per-cell list) can go stale entry by entry: the early entries predate a design
# change and the later ones do not. Specs therefore live per entry, not only per
# file, and a matching sibling is served while a stale one is refused.

ckpt_store_new <- function() {
  list(entries = list())
}

ckpt_store_put <- function(store, key, payload, spec) {
  store$entries[[key]] <- list(ckpt_spec = spec, payload = payload)
  store
}

ckpt_store_has <- function(store, key) {
  !is.null(store$entries[[key]])
}

# NULL when the entry is absent (the caller computes it); an abort when the
# entry is present but was computed under another design.
ckpt_store_get <- function(store, key, spec) {
  e <- store$entries[[key]]
  if (is.null(e)) {
    return(NULL)
  }
  if (is.null(e$ckpt_spec)) {
    stop(
      "stale-checkpoint guard: entry '",
      key,
      "' carries no recorded spec (delete the checkpoint and recompute)",
      call. = FALSE
    )
  }
  bad <- ckpt_spec_mismatch(e$ckpt_spec, spec)
  if (!is.null(bad)) {
    stop(
      "stale-checkpoint guard: entry '",
      key,
      "' was not computed under the current design -- ",
      bad,
      " (delete the checkpoint and let the run recompute)",
      call. = FALSE
    )
  }
  e$payload
}

# ---- the run-scoped deserialization trace ------------------------------------
# Comparing specs protects reads routed through ckpt_read(). The trace protects
# the run against reads that are not: it records every readRDS() as it happens,
# so no spelling of the call -- bare, base::-qualified, or through an alias --
# is invisible to it. Registered locations bound what it judges; a read outside
# them is somebody else's business and is left alone.

ckpt_trace_state <- new.env(parent = emptyenv())
ckpt_trace_state$registered <- character(0)
ckpt_trace_state$observed <- character(0)
ckpt_trace_state$guarded <- character(0)
ckpt_trace_state$installed <- FALSE
ckpt_trace_state$in_guard <- FALSE

ckpt_norm <- function(path) {
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

# Register a checkpoint file or directory. Reads under it are the trace's
# business; reads elsewhere are not.
ckpt_trace_register <- function(path) {
  ckpt_trace_state$registered <- union(
    ckpt_trace_state$registered,
    ckpt_norm(path)
  )
  invisible(ckpt_trace_state$registered)
}

# Fail FAST, in the process that did the read, rather than only at the
# end-of-run assertion. M111 maps its cells with parallel::mclapply, and a
# forked worker's copy of this environment dies with the worker -- so a
# parent-side assertion cannot see a worker's reads at all, and would pass
# vacuously over exactly the harness this guard was written for. Aborting at the
# read keeps the check in whichever process performed it.
ckpt_trace_note <- function(path, guarded = FALSE) {
  # readRDS() also accepts a connection; only a path can be compared against a
  # registered location, so anything else is somebody else's business.
  if (!is.character(path) || length(path) != 1L) {
    return(invisible(NULL))
  }
  p <- ckpt_norm(path)
  if (guarded) {
    ckpt_trace_state$guarded <- union(ckpt_trace_state$guarded, p)
    return(invisible(NULL))
  }
  if (isTRUE(ckpt_trace_state$in_guard)) {
    return(invisible(NULL))
  }
  ckpt_trace_state$observed <- union(ckpt_trace_state$observed, p)
  if (length(ckpt_under_registered(p))) {
    stop(
      "stale-checkpoint guard: ",
      basename(p),
      " bypassed the checkpoint guard (read with a bare readRDS rather than ",
      "ckpt_read(); its provenance is therefore unknown)",
      call. = FALSE
    )
  }
  invisible(NULL)
}

ckpt_trace_reset <- function() {
  ckpt_trace_state$observed <- character(0)
  ckpt_trace_state$guarded <- character(0)
  invisible(NULL)
}

ckpt_trace_install <- function() {
  if (isTRUE(ckpt_trace_state$installed)) {
    return(invisible(FALSE))
  }
  suppressMessages(trace(
    "readRDS",
    # NOT wrapped in try(): the note aborts on an unguarded read of a
    # registered checkpoint, and that abort is the whole point -- swallowing it
    # here would leave the trace recording bypasses it never acts on.
    tracer = quote(ckpt_trace_note(file)),
    where = baseenv(),
    print = FALSE
  ))
  ckpt_trace_state$installed <- TRUE
  invisible(TRUE)
}

ckpt_trace_remove <- function() {
  if (!isTRUE(ckpt_trace_state$installed)) {
    return(invisible(FALSE))
  }
  suppressMessages(untrace("readRDS", where = baseenv()))
  ckpt_trace_state$installed <- FALSE
  invisible(TRUE)
}

ckpt_under_registered <- function(paths) {
  reg <- ckpt_trace_state$registered
  if (!length(reg) || !length(paths)) {
    return(character(0))
  }
  hit <- vapply(
    paths,
    function(p) any(p == reg | startsWith(p, paste0(reg, "/"))),
    logical(1)
  )
  paths[hit]
}

# Call before any output write: a run that deserialized a registered checkpoint
# without going through the guard has already read rows of unknown provenance,
# and must not go on to write a fixture from them.
ckpt_trace_assert <- function() {
  suspect <- setdiff(
    ckpt_under_registered(ckpt_trace_state$observed),
    ckpt_trace_state$guarded
  )
  if (length(suspect)) {
    stop(
      "stale-checkpoint guard: ",
      length(suspect),
      " checkpoint read(s) bypassed the checkpoint guard: ",
      paste(basename(suspect), collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}
