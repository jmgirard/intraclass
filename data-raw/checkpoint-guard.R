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
# that come THROUGH this file; the trace watches readRDS() itself, so a read of
# a registered checkpoint that did NOT come through this file's own read
# functions fails the run whenever the call reaches the traced function --
# bare, base::-qualified, via do.call, or through an alias bound AFTER this
# file was sourced. (ckpt_read() reaches it too and is exempt by design; see
# in_guard below.)
#
# What the trace does NOT reach, stated here so nothing downstream assumes
# otherwise:
#   * an alias bound BEFORE this file was sourced. trace() rebinds the VALUE,
#     so a copy taken earlier is the original closure and stays untraced for
#     the life of the run. m120-checkpoint-guard-demo.R demonstrates this
#     escaping, in its own process, rather than leaving it asserted.
#   * a readRDS() handed a CONNECTION rather than a path. Only a path can be
#     compared against a registered location, so `readRDS(gzfile(p))` returns
#     its payload untouched.
#   * every deserialization function other than readRDS -- load(),
#     unserialize(), readr::read_rds(). Within the declared sites those are
#     covered statically instead, by data-raw/check-checkpoint-sites.R.
#   * a process that did not inherit the trace by forking from the one that
#     sourced this file.
# The first two are why the static check exists beside the trace, and neither
# surface claims the other's reach.

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

# EVERY bare name in an expression, not only those in call position. Collecting
# call heads alone was the hole that shipped: a determinant reached by variable
# capture -- `single_est <- est_occ("single")` at top level, then `single_est`
# referenced inside the entry point -- appears in no call position, so editing
# the estimand left the hash byte-identical, and a committed oracle fixture
# would have been written from rows computed under the old estimand.
#
# `pkg::f` and `pkg:::f` are deliberately not collected: a package object is not
# the site's own code, and the package's behavior is pinned by the test suite
# rather than by this hash. `x$y`'s `y` is a member name, not a binding.
#
# Walked BY INDEX, never `for (x in as.list(e))`: an empty argument (the blank
# in `d[keep, , drop = FALSE]`) binds a loop variable to the missing marker and
# every later touch of it raises "argument is missing". Indexing reads the same
# object without binding it.
ckpt_symbols <- function(e, acc = character(0)) {
  if (is.name(e)) {
    nm <- as.character(e)
    return(if (nzchar(nm)) c(acc, nm) else acc)
  }
  if (!is.call(e)) {
    return(acc)
  }
  if (is.name(e[[1]]) && as.character(e[[1]]) %in% c("::", ":::", "$", "@")) {
    return(ckpt_symbols(e[[2]], acc))
  }
  parts <- as.list(e)
  for (i in seq_along(parts)) {
    if (!is.null(parts[[i]]) && !identical(parts[[i]], quote(expr = ))) {
      acc <- ckpt_symbols(parts[[i]], acc)
    }
  }
  acc
}

# Names a function binds for itself: its formals, anything it assigns, and its
# for-loop variables. These are subtracted from the walked symbols, because a
# local that happens to share a name with a top-level binding is not a
# dependency on it -- `oracle-bayesian-incomplete-oneway.R` has a top-level
# `out` (an output path) and a local `out` (a data frame), and without this the
# walk reports the site depending on a path it never reads.
ckpt_local_names <- function(fn) {
  acc <- names(formals(fn))
  walk <- function(e) {
    if (!is.call(e)) {
      return(invisible(NULL))
    }
    if (is.name(e[[1]])) {
      op <- as.character(e[[1]])
      if (op %in% c("<-", "=", "<<-") && length(e) >= 3L && is.name(e[[2]])) {
        acc <<- c(acc, as.character(e[[2]]))
      }
      if (op == "for" && length(e) >= 3L && is.name(e[[2]])) {
        acc <<- c(acc, as.character(e[[2]]))
      }
      if (op == "function") {
        acc <<- c(acc, names(as.list(e[[2]])))
      }
    }
    parts <- as.list(e)
    for (i in seq_along(parts)) {
      if (!is.null(parts[[i]]) && !identical(parts[[i]], quote(expr = ))) {
        walk(parts[[i]])
      }
    }
  }
  walk(body(fn))
  unique(acc)
}

# The generating block, DERIVED rather than hand-listed: walk from the site's
# declared entry points over every symbol their bodies mention, following those
# that resolve to functions the site defines, and CLASSIFY every symbol that
# resolves to a top-level binding of the site's own. A symbol that is neither
# hashed, nor a declared parameter, nor a declared value, nor a declared
# exemption is returned as uncovered, and the caller refuses to build a spec
# while any remains. That is the whole point of the redesign: what a cache
# depends on is decided by the walk, and anything the walk cannot cover is a
# recorded decision rather than a silent omission.
#
# Sorted, so the hash does not depend on walk order.
ckpt_block_scan <- function(roots, values, params, exemptions, envir) {
  seen <- character(0)
  queue <- roots
  uncovered <- character(0)
  declared <- c(values, params, exemptions)
  while (length(queue)) {
    nm <- queue[[1]]
    queue <- queue[-1]
    if (nm %in% seen) {
      next
    }
    hit <- ckpt_find_block(nm, envir)
    if (!hit$found) {
      stop(
        "checkpoint spec: declared entry point not found: ",
        nm,
        call. = FALSE
      )
    }
    if (!is.function(hit$value)) {
      stop(
        "checkpoint spec: declared entry point is not a function: ",
        nm,
        call. = FALSE
      )
    }
    seen <- c(seen, nm)
    locals <- ckpt_local_names(hit$value)
    for (s in setdiff(unique(ckpt_symbols(body(hit$value))), locals)) {
      if (s %in% seen || s %in% queue) {
        next
      }
      h <- ckpt_find_block(s, envir)
      if (!h$found) {
        next # a local, a formal, or a package object: not the site's own
      }
      if (is.function(h$value)) {
        queue <- c(queue, s)
      } else if (!(s %in% declared)) {
        uncovered <- c(uncovered, s)
      }
    }
  }
  list(fns = sort(seen), uncovered = sort(unique(uncovered)))
}

# Hash the generating block: every function the walk reached (deparsed bodies,
# in sorted name order), then every declared VALUE in its declared order
# (deparsed value). Base R only: tools::md5sum needs a file, so the deparsed
# text goes through a tempfile.
ckpt_block_hash <- function(
  roots,
  values,
  params = character(0),
  exemptions = character(0),
  envir = parent.frame()
) {
  if (!length(roots)) {
    stop("checkpoint spec: no declared entry points", call. = FALSE)
  }
  scan <- ckpt_block_scan(roots, values, params, exemptions, envir)
  if (length(scan$uncovered)) {
    stop(
      "checkpoint spec: the generating walk reached ",
      length(scan$uncovered),
      " object(s) this site defines that are neither hashed nor declared: ",
      paste(scan$uncovered, collapse = ", "),
      " (declare each as a value, or as an exemption with a stated reason in ",
      "data-raw/checkpoint-sites.tsv)",
      call. = FALSE
    )
  }
  text <- unlist(lapply(scan$fns, function(nm) {
    c(paste0("## fn ", nm), deparse(body(ckpt_find_block(nm, envir)$value)))
  }))
  text <- c(
    text,
    unlist(lapply(values, function(nm) {
      hit <- ckpt_find_block(nm, envir)
      if (!hit$found) {
        stop("checkpoint spec: declared value not found: ", nm, call. = FALSE)
      }
      c(paste0("## val ", nm), deparse(hit$value))
    }))
  )
  f <- tempfile("ckpt-block-")
  on.exit(unlink(f), add = TRUE)
  writeLines(text, f)
  unname(tools::md5sum(f))
}

# `params` is a NAMED list whose order is the declared order. An empty one is
# refused here rather than at read time: a spec that records nothing never
# mismatches, and a guard that never mismatches is indistinguishable from no
# guard at all.
ckpt_spec <- function(
  params,
  roots,
  values = character(0),
  exemptions = character(0),
  site,
  envir = parent.frame()
) {
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
    block = c(roots, values),
    block_hash = ckpt_block_hash(
      roots,
      values,
      params = names(params),
      exemptions = exemptions,
      envir = envir
    )
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
# the run against reads that are not: it watches readRDS() as it happens, so a
# call that reaches the traced function -- bare, base::-qualified, via do.call,
# or through an alias bound after this file was sourced -- is caught whatever
# the spelling. An alias bound BEFORE it was sourced is not; see the header.
# Registered locations bound what it judges; a read outside them is somebody
# else's business and is left alone.

# CREATED ONCE PER PROCESS, not once per source(). Sourcing this file a second
# time is not hypothetical -- the demonstration sources the guard and then
# sources m111-fallback-sweep.R, which sources the guard again, and
# rerun-oracle.R runs several guarded scripts in one process. A fresh
# environment there would silently discard every registration made so far,
# leaving the trace watching nothing, and would orphan every bypass already
# recorded.
if (
  !exists("ckpt_trace_state", inherits = FALSE) ||
    !is.environment(ckpt_trace_state)
) {
  ckpt_trace_state <- new.env(parent = emptyenv())
  ckpt_trace_state$registered <- character(0)
  ckpt_trace_state$installed <- FALSE
  ckpt_trace_state$in_guard <- FALSE
  # Bypasses are recorded on DISK, not in this environment. A forked worker gets
  # a copy of the environment that dies with it, so a worker that swallowed the
  # abort left the parent's assertion nothing to see -- vacuous on exactly the
  # harness (M111's mclapply sweep) this guard was written for. A directory
  # crosses the fork boundary in the one direction that matters: the child
  # writes, the parent lists.
  ckpt_trace_state$marker_dir <- ""
}

# Resolve a path's identity in a way that does not depend on the file existing
# YET. normalizePath() returns an existing path absolute and a non-existent one
# unchanged, so a checkpoint registered before its first write compared unequal
# to the very same path read back later -- and every oracle site registers
# before the store exists. Resolving the deepest EXISTING ancestor and
# re-appending the remainder gives one answer either way.
ckpt_norm <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    return(NA_character_)
  }
  if (file.exists(path)) {
    return(normalizePath(path, winslash = "/", mustWork = FALSE))
  }
  # Not there yet. Absolute-ize against the working directory FIRST -- the
  # oracle sites register relative paths (`data-raw/.oracle-*-checkpoint.rds`),
  # and a relative answer could never match the absolute one the same path gives
  # once it exists -- then resolve the deepest existing ancestor, which is also
  # what turns /var into /private/var on macOS.
  abs <- if (grepl("^(/|~|[A-Za-z]:[/\\\\])", path)) {
    path
  } else {
    file.path(getwd(), path)
  }
  parent <- dirname(abs)
  if (identical(parent, abs)) {
    return(abs)
  }
  file.path(ckpt_norm(parent), basename(abs))
}

# Register a checkpoint file or directory. Reads under it are the trace's
# business; reads elsewhere are not.
ckpt_trace_register <- function(path) {
  # Refuse a path that cannot be resolved rather than record it. ckpt_norm()
  # returns NA for an empty or non-character path -- which is what
  # ckpt_trace_register(Sys.getenv("SOME_CKPT")) gives when the variable is
  # unset -- and an NA in the registry matched EVERY later read, so a single
  # unset environment variable turned the guard into a run-wide abort on any
  # readRDS at all. Failing at the registration names the defect where it is.
  p <- ckpt_norm(path)
  if (is.na(p)) {
    stop(
      "stale-checkpoint guard: cannot register a checkpoint location from ",
      "a non-path (an unset Sys.getenv() gives \"\"); pass the path the ",
      "harness actually reads",
      call. = FALSE
    )
  }
  ckpt_trace_state$registered <- union(ckpt_trace_state$registered, p)
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
  # registered location, so anything else is outside this trace's reach -- see
  # the header, which states that limit rather than papering over it.
  if (!is.character(path) || length(path) != 1L) {
    return(invisible(NULL))
  }
  if (isTRUE(ckpt_trace_state$in_guard)) {
    return(invisible(NULL))
  }
  p <- ckpt_norm(path)
  if (length(ckpt_under_registered(p))) {
    ckpt_mark_bypass(p)
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

# Record the bypass where a forked worker's record survives it. One file per
# bypassed path, named by hash so concurrent workers never collide, holding the
# path itself.
ckpt_mark_bypass <- function(p) {
  dir <- ckpt_trace_state$marker_dir
  if (!nzchar(dir)) {
    return(invisible(NULL))
  }
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  f <- tempfile("bypass-", tmpdir = dir, fileext = ".txt")
  writeLines(p, f)
  invisible(f)
}

ckpt_trace_bypassed <- function() {
  dir <- ckpt_trace_state$marker_dir
  if (!nzchar(dir) || !dir.exists(dir)) {
    return(character(0))
  }
  files <- list.files(dir, pattern = "^bypass-", full.names = TRUE)
  if (!length(files)) {
    return(character(0))
  }
  unique(unlist(lapply(files, function(f) readLines(f, warn = FALSE))))
}

ckpt_trace_reset <- function() {
  dir <- ckpt_trace_state$marker_dir
  if (nzchar(dir) && dir.exists(dir)) {
    unlink(list.files(dir, pattern = "^bypass-", full.names = TRUE))
  }
  invisible(NULL)
}

ckpt_trace_install <- function() {
  if (isTRUE(ckpt_trace_state$installed)) {
    return(invisible(FALSE))
  }
  ckpt_trace_state$marker_dir <- tempfile("ckpt-bypass-")
  dir.create(
    ckpt_trace_state$marker_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
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
# and must not go on to write a fixture from them. Reads the on-disk markers, so
# a bypass a FORKED worker swallowed is reported here even though that worker's
# memory is long gone.
ckpt_trace_assert <- function() {
  suspect <- ckpt_trace_bypassed()
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

# ---- install on load ---------------------------------------------------------
# Sourcing this file installs the trace. Deferring installation to a call each
# harness makes for itself left two holes that both bit: an alias bound to
# readRDS before that call was untraced for the rest of the run, and a harness
# that simply never made the call got no trace at all while every routing check
# still passed. Installing here closes the second for any harness that sources
# this file -- which the routing check is what enforces on the declared sites --
# and narrows the first to the window before this file is sourced: a narrowing,
# not a closure, since an alias bound ahead of the source() is still untraced,
# and the demonstration shows it escaping. The five sites' comments saying "sourcing it
# installs the trace" are true.
# ckpt_trace_install() remains callable and is a no-op once installed.
ckpt_trace_install()
