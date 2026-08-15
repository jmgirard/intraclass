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

# Resolve a declared block name WITHOUT inheriting past the global environment.
# get0()'s ordinary lookup continues up the search path, so a declared function
# that has been renamed resolves to any same-named function in an attached
# package and the hash then tracks that stranger forever: two sites declare a
# block function named `simulate`, which stats:: also exports. Stopping at
# globalenv() turns a rename back into the "not found" abort it is.
ckpt_find_block <- function(nm, envir) {
  e <- envir
  repeat {
    if (exists(nm, envir = e, inherits = FALSE)) {
      return(list(found = TRUE, value = get(nm, envir = e)))
    }
    if (identical(e, globalenv()) || identical(e, emptyenv())) {
      return(list(found = FALSE, value = NULL))
    }
    e <- parent.env(e)
  }
}

# Hash the declared generating block, in the declared order, under the declared
# names. A declared FUNCTION contributes its deparsed body; a declared VALUE
# contributes its deparsed value. Values are in the block because not everything
# that decides a cached number is a function: the seed-offset vectors, the
# sampler argument lists, and the formula and prior the base fit is compiled
# from all determine the cached rows and would otherwise change unnoticed.
# Base R only — tools::md5sum needs a file, so the deparsed text goes through a
# tempfile.
ckpt_block_hash <- function(block, envir = parent.frame()) {
  if (!length(block)) {
    stop("checkpoint spec: no declared generating block", call. = FALSE)
  }
  text <- unlist(lapply(block, function(nm) {
    hit <- ckpt_find_block(nm, envir)
    if (!hit$found) {
      stop(
        "checkpoint spec: declared block entry not found: ",
        nm,
        call. = FALSE
      )
    }
    if (is.function(hit$value)) {
      c(paste0("## fn ", nm), deparse(body(hit$value)))
    } else {
      c(paste0("## val ", nm), deparse(hit$value))
    }
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
#
# The FILE carries no design spec at all — only which site wrote it and the
# container format. A file-level design spec cannot be right here: it has to be
# some entry's spec, and stamping the file with one entry's parameters both
# discards every valid sibling when that entry is edited (on the nested-fixed
# site, ~720 Stan refits) and fires before the per-entry check can ever
# discriminate, leaving the per-entry machinery inert. So all design comparison
# happens per entry, and the file check answers only the question a file-level
# record can answer: is this cache even ours?

ckpt_store_format_version <- 1L

ckpt_store_new <- function(site) {
  if (!is.character(site) || length(site) != 1L || !nzchar(site)) {
    stop("checkpoint store: a store needs its site name", call. = FALSE)
  }
  list(
    ckpt_store_format = ckpt_store_format_version,
    site = site,
    entries = list()
  )
}

ckpt_store_save <- function(path, store) {
  dir <- dirname(path)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  saveRDS(store, path)
  invisible(path)
}

# Load a store, or abort. The only file-level questions are whether this is a
# store this guard wrote and whether the site that wrote it is the one asking;
# staleness is an entry-level question and is asked by ckpt_store_get().
ckpt_store_load <- function(path, site) {
  ckpt_trace_state$in_guard <- TRUE
  on.exit(ckpt_trace_state$in_guard <- FALSE, add = TRUE)
  store <- readRDS(path)
  if (
    !is.list(store) ||
      !identical(store$ckpt_store_format, ckpt_store_format_version)
  ) {
    stop(
      "stale-checkpoint guard: ",
      path,
      " is not a guarded checkpoint store, so what design produced it is ",
      "unknown (delete it and let the run recompute)",
      call. = FALSE
    )
  }
  if (!identical(store$site, site)) {
    stop(
      "stale-checkpoint guard: ",
      path,
      " was written by a different site: recorded '",
      store$site,
      "', current '",
      site,
      "' (delete the checkpoint and let the run recompute)",
      call. = FALSE
    )
  }
  store
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
# Comparing specs protects reads routed through the guard. The trace protects
# the run against reads that are not: it watches readRDS() as it happens, so no
# spelling of the call -- bare, base::-qualified, or through an alias -- is
# invisible to it. Registered locations bound what it judges; a read outside
# them is somebody else's business and is left alone.

ckpt_trace_state <- new.env(parent = emptyenv())
ckpt_trace_state$registered <- character(0)
ckpt_trace_state$bypassed <- character(0)
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
#
# What is recorded is the BYPASS, not the path. Recording paths and subtracting
# the guarded ones at the end cannot work: a path is read through the guard on
# nearly every resume, so any later bare read of that same path is subtracted
# out by its own earlier legitimate sibling, and a bypass a caller swallowed is
# then never reported at all. A bypass is an event; it is recorded when it
# happens and is never cancelled by anything that happened before or after it.
ckpt_trace_note <- function(path) {
  # readRDS() also accepts a connection; only a path can be compared against a
  # registered location, so anything else is somebody else's business.
  if (!is.character(path) || length(path) != 1L) {
    return(invisible(NULL))
  }
  if (isTRUE(ckpt_trace_state$in_guard)) {
    return(invisible(NULL))
  }
  p <- ckpt_norm(path)
  if (length(ckpt_under_registered(p))) {
    ckpt_trace_state$bypassed <- union(ckpt_trace_state$bypassed, p)
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
  ckpt_trace_state$bypassed <- character(0)
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
  suspect <- ckpt_trace_state$bypassed
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
