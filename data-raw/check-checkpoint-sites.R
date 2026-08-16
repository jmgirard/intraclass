# M120 — every declared resume site still routes through the checkpoint guard.
#
# This replaces a text-matching checker that asked only whether a token appeared
# somewhere in the file. Three reversions walked past it: an assertion moved to
# after the fixture write, a registration handed a literal NULL, and a live
# per-entry read replaced by direct payload access while a dead copy of the call
# survived in an `if (FALSE)` block. None of those is visible to a search for
# text, so this reads the parsed source instead.
#
# What it checks, and what it deliberately does not:
#
#   * IT CHECKS the sites declared in data-raw/checkpoint-sites.tsv. That file is
#     an enumeration, not a discovery procedure, and this checker inherits
#     exactly that bound. It cannot tell you a sixth harness has started resuming
#     from a cache, and it does not claim to.
#   * WHAT DOES cover the open-ended case is the run-time trace in
#     checkpoint-guard.R, which installs itself when that file is sourced and
#     watches deserialization as it happens. This checker exists because that
#     trace only fires when a harness actually runs, and the four oracle
#     harnesses need brms/Stan and hours of refits.
#
# So: the trace is the guard, this is the regression net over the sites we know
# about.
#
#   Rscript data-raw/check-checkpoint-sites.R
#   Rscript data-raw/check-checkpoint-sites.R --self-test

guard_path <- "data-raw/checkpoint-guard.R"
sites_tsv <- "data-raw/checkpoint-sites.tsv"

# ---- reading the declaration -------------------------------------------------

read_sites <- function(path = sites_tsv) {
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines)) & !startsWith(lines, "#")]
  parts <- strsplit(lines, "\t", fixed = TRUE)
  header <- parts[[1]]
  lapply(parts[-1], function(row) stats::setNames(as.list(row), header))
}

# A `#@name<TAB>value` line in the declaration file: file-level declarations that
# are not per-site. read_sites() drops every comment line, so these are read
# separately rather than smuggled into the table.
read_directive <- function(name, path = sites_tsv) {
  lines <- readLines(path, warn = FALSE)
  hit <- lines[startsWith(lines, paste0("#@", name, "\t"))]
  if (!length(hit)) {
    stop("no #@", name, " directive in ", path, call. = FALSE)
  }
  split_decl(sub("^#@[^\t]*\t", "", hit[[length(hit)]]))
}

# The four names AC2 requires the list to contain. A list that may be shortened
# at will is not an enumeration, it is whatever the sites happened not to use --
# and the recall it would then rest on is what this milestone exists to stop
# relying on.
required_deserializers <- c("readRDS", "load", "unserialize", "readr::read_rds")

split_decl <- function(x) {
  out <- trimws(strsplit(x %||% "", ",", fixed = TRUE)[[1]])
  out[nzchar(out)]
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- walking the parsed source ----------------------------------------------
# Every check below is asked of the LIVE code. `if (FALSE) { ... }` is the
# cheapest way to keep a call's text while removing the call, so those branches
# are dropped before anything is counted; a dead call is not a call.

drop_dead <- function(e) {
  if (!is.call(e)) {
    return(e)
  }
  if (identical(e[[1]], as.name("if")) && identical(e[[2]], FALSE)) {
    return(if (length(e) >= 4L) drop_dead(e[[4]]) else NULL)
  }
  if (identical(e[[1]], as.name("if")) && identical(e[[2]], TRUE)) {
    return(drop_dead(e[[3]]))
  }
  as.call(lapply(as.list(e), function(x) if (is.null(x)) x else drop_dead(x)))
}

# bare f(), pkg::f(), and pkg:::f() all name the same call head.
call_head_name <- function(head) {
  if (is.name(head)) {
    return(as.character(head))
  }
  if (
    is.call(head) &&
      is.name(head[[1]]) &&
      as.character(head[[1]]) %in% c("::", ":::")
  ) {
    return(as.character(head[[3]]))
  }
  ""
}

# Every call to `name` in the live source, as call objects. This asks only
# whether the text is there; whether anything REACHES it is reach_scan()'s
# question, and the two are kept apart deliberately -- a call nothing reaches is
# how three separate reversions walked past this checker's predecessors.
calls_to <- function(exprs, name) {
  found <- list()
  walk <- function(e) {
    if (is.call(e)) {
      nm <- call_head_name(e[[1]])
      if (identical(nm, name)) {
        found[[length(found) + 1L]] <<- e
      }
      # BY INDEX: an empty argument (the blank in `d[keep, , drop = FALSE]`)
      # binds a loop variable to the missing marker, and every later touch of
      # that variable raises "argument is missing". Indexing reads the same
      # object without binding it.
      args <- as.list(e)[-1]
      for (i in seq_along(args)) {
        if (!is.null(args[[i]]) && !identical(args[[i]], quote(expr = ))) {
          walk(args[[i]])
        }
      }
    }
  }
  for (e in exprs) {
    walk(e)
  }
  found
}

# The source line a call sits on, for the ordering check. Top-level scripts run
# in source order, so a line number is an execution order.
line_of <- function(exprs, name) {
  refs <- attr(exprs, "srcref")
  hits <- integer(0)
  for (i in seq_along(exprs)) {
    if (length(calls_to(exprs[i], name))) {
      hits <- c(hits, if (is.null(refs)) NA_integer_ else refs[[i]][1L])
    }
  }
  hits
}

parse_live <- function(path) {
  exprs <- parse(path, keep.source = TRUE)
  refs <- attr(exprs, "srcref")
  live <- lapply(exprs, drop_dead)
  keep <- !vapply(live, is.null, logical(1))
  live <- live[keep]
  # Filtered TOGETHER with the expressions: dropping a dead top-level expression
  # while keeping every srcref shifts each later line number by one, which turns
  # the ordering check's diagnostic into a lie about a file it is right about.
  attr(live, "srcref") <- if (is.null(refs)) NULL else refs[keep]
  live
}

# ---- reachability and liveness ----------------------------------------------
# A guard call is made only if something reaches it. Parking the call in a
# function nobody calls, or under a condition that never holds, leaves the text
# in place while removing the call -- and a checker that counts occurrences
# cannot tell the two apart. So the walk starts at live top-level code and
# follows calls; a function handed BY NAME to a declared applier is followed
# too, because m111's ckpt_read() is reached only through
# `mclapply(cells, run_cell)`.
#
# Liveness is the second half. A branch counts only when its condition is
# literally TRUE or is one of the declared idioms in checkpoint-sites.tsv, each
# carrying its reason there. `if (0)`, `if (FALSE || FALSE)` and
# `if (getOption("x", FALSE))` are none of the three, and each of them parked a
# guard call past the previous version of this checker.

cond_is_live <- function(cond, idioms) {
  if (identical(cond, TRUE)) {
    return(TRUE)
  }
  paste(deparse(cond), collapse = " ") %in% idioms
}

# Every call the walk REACHES, as list(name, index, call) -- index being the
# top-level expression it sits under, which is what gives it a line number.
reach_scan <- function(exprs, idioms, appliers) {
  bindings <- static_bindings(exprs)
  fn_names <- names(bindings)[vapply(
    names(bindings),
    function(n) static_resolve(n, bindings)$is_fn,
    logical(1)
  )]
  def_index <- list()
  is_def <- logical(length(exprs))
  for (i in seq_along(exprs)) {
    e <- exprs[[i]]
    if (
      is.call(e) &&
        is.name(e[[1]]) &&
        as.character(e[[1]]) %in% c("<-", "=") &&
        length(e) >= 3L &&
        is.name(e[[2]]) &&
        is_fn_expr(e[[3]])
    ) {
      is_def[[i]] <- TRUE
      def_index[[as.character(e[[2]])]] <- i
    }
  }

  hits <- list()
  reachable <- character(0)
  queue <- character(0)
  cur <- NA_integer_
  # Order WITHIN a top-level expression. A line number cannot separate two calls
  # in the same top-level block -- m111 makes its output write and its
  # assertion inside one `if (sys.nframe() == 0L)`, so both carry that block's
  # line -- and the ordering check would then be blind on exactly the site whose
  # assertion matters most. Pre-order traversal is source order for sequential
  # code, so (index, step) orders every call the walk reaches.
  step <- 0L

  mark <- function(nm) {
    if (nm %in% fn_names && !(nm %in% reachable)) {
      reachable <<- c(reachable, nm)
      queue <<- c(queue, nm)
    }
  }

  walk <- function(x, live) {
    if (!is.call(x)) {
      return(invisible(NULL))
    }
    nm <- call_head_name(x[[1]])
    if (identical(nm, "function")) {
      # An anonymous function in reachable code is run by whatever it was
      # handed to; its body is reachable.
      return(walk(x[[3]], live))
    }
    if (nzchar(nm)) {
      step <<- step + 1L
      hits[[length(hits) + 1L]] <<- list(
        name = nm,
        index = cur,
        step = step,
        live = live,
        call = x
      )
      if (live) {
        mark(nm)
        if (nm %in% appliers) {
          for (a in as.list(x)[-1]) {
            if (is.name(a)) {
              mark(as.character(a))
            }
          }
        }
      }
    }
    if (identical(nm, "if")) {
      walk(x[[2]], live) # the condition itself is evaluated
      inner <- live && cond_is_live(x[[2]], idioms)
      walk(x[[3]], inner)
      if (length(x) >= 4L) {
        # Both arms stand or fall with the condition: a declared idiom says the
        # branch is a real execution path, and an undeclared one says nothing
        # about either arm.
        walk(x[[4]], inner)
      }
      return(invisible(NULL))
    }
    parts <- as.list(x)[-1]
    for (i in seq_along(parts)) {
      if (!is.null(parts[[i]]) && !identical(parts[[i]], quote(expr = ))) {
        walk(parts[[i]], live)
      }
    }
    invisible(NULL)
  }

  for (i in seq_along(exprs)) {
    if (is_def[[i]]) {
      next # a definition is not an execution
    }
    cur <- i
    step <- 0L
    walk(exprs[[i]], TRUE)
  }
  while (length(queue)) {
    nm <- queue[[1]]
    queue <- queue[-1]
    idx <- def_index[[nm]]
    if (is.null(idx)) {
      next
    }
    cur <- idx
    step <- 0L
    walk(exprs[[idx]][[3]][[3]], TRUE)
  }
  Filter(function(h) !is.null(h$name), hits)
}

# Reached means BOTH: the walk got here, and every condition on the way was
# literally true or a declared idiom. A call the walk visited under a dead
# condition is recorded but is not a call.
reached_calls <- function(hits, name) {
  Filter(function(h) identical(h$name, name) && isTRUE(h$live), hits)
}

# The source lines of the reached occurrences of `name`. A call inside a
# reachable function is attributed to that function's DEFINITION line, which is
# the only line a top-level srcref can give it.
# Execution order over the reached occurrences of `name`: the top-level
# expression they sit under, then their position within it.
reached_order <- function(hits, name) {
  h <- reached_calls(hits, name)
  if (!length(h)) {
    return(numeric(0))
  }
  vapply(h, function(x) x$index + x$step / 1e6, numeric(1))
}

reached_lines <- function(hits, name, exprs) {
  refs <- attr(exprs, "srcref")
  idx <- vapply(reached_calls(hits, name), function(h) h$index, integer(1))
  idx <- idx[!is.na(idx)]
  if (!length(idx) || is.null(refs)) {
    return(integer(0))
  }
  vapply(idx, function(i) refs[[i]][1L], integer(1))
}

# ---- the checks --------------------------------------------------------------

check_site <- function(site, root = ".") {
  out <- character(0)
  path <- file.path(root, site$script)
  if (!file.exists(path)) {
    return(paste0(site$script, ": declared in ", sites_tsv, " but absent"))
  }
  exprs <- tryCatch(parse_live(path), error = function(e) NULL)
  if (is.null(exprs)) {
    return(paste0(site$script, ": does not parse"))
  }

  # 1. The guard is sourced, by a live call naming the guard file.
  sourced <- calls_to(exprs, "source")
  if (
    !any(vapply(
      sourced,
      function(e) {
        any(vapply(as.list(e)[-1], identical, logical(1), guard_path))
      },
      logical(1)
    ))
  ) {
    out <- c(out, paste0(site$script, ": no live source() of ", guard_path))
  }

  hits <- reach_scan(
    exprs,
    read_directive("idioms", file.path(root, sites_tsv)),
    read_directive("appliers", file.path(root, sites_tsv))
  )

  # 2. Every declared guard call is REACHED, live. ALL of them: a site that
  #    keeps its file-level load and drops its per-entry read has stopped
  #    checking the thing that goes stale, and no single call stands in for the
  #    set. A call the text contains but nothing reaches is reported as the
  #    parked call it is, not as a call.
  required <- split_decl(site$api)
  if (!length(required)) {
    out <- c(out, paste0(site$script, ": declares no guard calls"))
  }
  for (call_name in required) {
    if (!length(reached_calls(hits, call_name))) {
      out <- c(
        out,
        paste0(
          site$script,
          ": nothing reaches ",
          call_name,
          "()",
          if (length(calls_to(exprs, call_name))) {
            " -- the call is in the file, but parked: under a condition that is neither literally true nor a declared idiom, or inside a function nothing calls"
          } else {
            " -- the call is not in the file at all"
          }
        )
      )
    }
  }

  # 3. The checkpoint is registered with the trace, with a real argument. A
  #    literal NULL registers nothing and leaves every later read unwatched.
  reg <- reached_calls(hits, "ckpt_trace_register")
  if (!length(reg)) {
    out <- c(
      out,
      paste0(site$script, ": nothing reaches ckpt_trace_register()")
    )
  } else if (
    !any(vapply(
      reg,
      function(h) {
        e <- h$call
        length(e) >= 2L && !is.null(e[[2]]) && !identical(e[[2]], NULL)
      },
      logical(1)
    ))
  ) {
    out <- c(
      out,
      paste0(site$script, ": ckpt_trace_register() is given no real path")
    )
  }

  # 4. The pre-write assertion runs BEFORE the site's output write. Asserting
  #    after the fixture has been written is not a guard, it is a postmortem.
  assert_lines <- reached_lines(hits, "ckpt_trace_assert", exprs)
  write_lines <- reached_lines(hits, "saveRDS", exprs)
  if (!length(assert_lines)) {
    out <- c(
      out,
      paste0(site$script, ": nothing reaches ckpt_trace_assert()")
    )
  } else if (
    length(write_lines) &&
      min(reached_order(hits, "ckpt_trace_assert")) >
        min(reached_order(hits, "saveRDS"))
  ) {
    out <- c(
      out,
      paste0(
        site$script,
        ": ckpt_trace_assert() (line ",
        min(assert_lines),
        ") comes after the first output write (line ",
        min(write_lines),
        ")"
      )
    )
  }

  # 5. The declared parameters appear in a ckpt_spec() call, in the declared
  #    ORDER — the mismatch message names the earliest differing one, so the
  #    order is part of the contract, not a formatting detail.
  specs <- lapply(reached_calls(hits, "ckpt_spec"), function(h) h$call)
  if (!length(specs)) {
    out <- c(out, paste0(site$script, ": never builds a ckpt_spec()"))
  } else {
    declared <- split_decl(site$params)
    seen_any <- FALSE
    for (e in specs) {
      params <- e[["params"]]
      if (is.null(params) || !is.call(params)) {
        next
      }
      nms <- names(as.list(params))[-1]
      if (is.null(nms)) {
        next
      }
      seen_any <- TRUE
      if (!identical(nms, declared)) {
        out <- c(
          out,
          paste0(
            site$script,
            ": ckpt_spec() parameters (",
            paste(nms, collapse = ", "),
            ") do not match the declared set in declared order (",
            paste(declared, collapse = ", "),
            ")"
          )
        )
      }
    }
    if (!seen_any) {
      out <- c(out, paste0(site$script, ": no ckpt_spec() declares params"))
    }
  }

  # 6. The declared block roots and values are the ones the site passes.
  for (nm in c(split_decl(site$roots), split_decl(site$values))) {
    if (
      !any(vapply(
        specs,
        function(e) nm %in% all_strings(e),
        logical(1)
      ))
    ) {
      out <- c(
        out,
        paste0(
          site$script,
          ": declared block entry '",
          nm,
          "' is in no ckpt_spec()"
        )
      )
    }
  }

  # 7. Every determinant the generating walk reaches is accounted for. The walk
  #    starts at the declared roots and follows the site's own definitions; a
  #    symbol resolving to a top-level binding that is neither hashed nor
  #    declared is reported BY NAME. Four sites can never be run here, so this
  #    static walk is the only one that ever reaches them.
  scan <- static_block_scan(
    static_bindings(exprs),
    split_decl(site$roots),
    split_decl(site$values),
    split_decl(site$params),
    split_decl(site$exemptions)
  )
  for (nm in scan$unresolved) {
    out <- c(
      out,
      paste0(
        site$script,
        ": declared entry point '",
        nm,
        "' is not a top-level function of this site"
      )
    )
  }
  # 8. Neither the site nor anything it sources deserializes for itself.
  deser <- read_directive("deserializers", file.path(root, sites_tsv))
  if (!all(required_deserializers %in% deser)) {
    out <- c(
      out,
      paste0(
        site$script,
        ": the declared deserialization list is missing ",
        paste(setdiff(required_deserializers, deser), collapse = ", ")
      )
    )
  }
  deser_bad <- deserialization_failures(site$script, root, deser)$out
  for (msg in deser_bad) {
    out <- c(out, paste0(site$script, ": ", msg))
  }

  for (nm in scan$uncovered) {
    out <- c(
      out,
      paste0(
        site$script,
        ": the generating walk reaches '",
        nm,
        "', which is neither hashed nor declared (declare it as a value, or as",
        " an exemption with a stated reason in ",
        sites_tsv,
        ")"
      )
    )
  }
  out
}

# ---- the static generating-block walk ---------------------------------------
# A mirror of ckpt_block_scan() in data-raw/checkpoint-guard.R, run over PARSED
# SOURCE rather than over live bindings. Four of the five sites need brms/Stan
# and hours of refits, so their run-time walk cannot be executed here at all --
# this is the only walk that ever reaches them. The two are pinned against each
# other on a synthetic site in data-raw/m120-checkpoint-guard-demo.R; that pin,
# not inspection, is what keeps the two implementations answering alike.
#
# One deliberate difference: the run-time walk resolves a name up the
# environment chain as far as globalenv(), so a function the site does not
# define -- the guard's own, say -- is reached and hashed there. Here only the
# site's own top-level bindings resolve, and anything else stops the walk. The
# difference cannot produce a false report: a symbol that does not resolve is
# skipped, never called uncovered.

is_fn_expr <- function(e) {
  is.call(e) && is.name(e[[1]]) && identical(as.character(e[[1]]), "function")
}

# name -> the expression last assigned to it at top level. Last assignment wins,
# which is what the run-time walk sees: it reads the binding as it stands when
# the spec is built.
static_bindings <- function(exprs) {
  out <- list()
  for (e in exprs) {
    if (
      is.call(e) &&
        is.name(e[[1]]) &&
        as.character(e[[1]]) %in% c("<-", "=") &&
        length(e) >= 3L &&
        is.name(e[[2]])
    ) {
      out[[as.character(e[[2]])]] <- e[[3]]
    }
  }
  out
}

# Follow `f <- g` chains, so a function reached through an alias is a function
# here exactly as is.function() finds it at run time.
static_resolve <- function(nm, bindings, depth = 0L) {
  if (!nm %in% names(bindings)) {
    return(list(found = FALSE, expr = NULL, is_fn = FALSE))
  }
  e <- bindings[[nm]]
  if (is_fn_expr(e)) {
    return(list(found = TRUE, expr = e, is_fn = TRUE))
  }
  if (is.name(e) && depth < 10L) {
    onward <- static_resolve(as.character(e), bindings, depth + 1L)
    if (onward$found) {
      return(onward)
    }
  }
  list(found = TRUE, expr = e, is_fn = FALSE)
}

# EVERY bare name in an expression, not only those in call position -- the
# counterpart of ckpt_symbols(). `pkg::f`, `x$y` and `x@y` contribute only their
# left operand, and walking is BY INDEX so an empty argument (the blank in
# `d[keep, , drop = FALSE]`) is never bound to a variable.
expr_symbols <- function(e, acc = character(0)) {
  if (is.name(e)) {
    nm <- as.character(e)
    return(if (nzchar(nm)) c(acc, nm) else acc)
  }
  if (!is.call(e)) {
    return(acc)
  }
  if (is.name(e[[1]]) && as.character(e[[1]]) %in% c("::", ":::", "$", "@")) {
    return(expr_symbols(e[[2]], acc))
  }
  parts <- as.list(e)
  for (i in seq_along(parts)) {
    if (!is.null(parts[[i]]) && !identical(parts[[i]], quote(expr = ))) {
      acc <- expr_symbols(parts[[i]], acc)
    }
  }
  acc
}

# The names a function literal binds for itself -- the counterpart of
# ckpt_local_names(). Subtracted from the walked symbols so a local that shares
# a name with a top-level binding is not read as a dependency on it.
expr_locals <- function(fn) {
  acc <- names(as.list(fn[[2]]))
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
  walk(fn[[3]])
  unique(acc)
}

static_block_scan <- function(
  bindings,
  roots,
  values = character(0),
  params = character(0),
  exemptions = character(0)
) {
  seen <- character(0)
  queue <- roots
  uncovered <- character(0)
  unresolved <- character(0)
  declared <- c(values, params, exemptions)
  while (length(queue)) {
    nm <- queue[[1]]
    queue <- queue[-1]
    if (nm %in% seen) {
      next
    }
    r <- static_resolve(nm, bindings)
    if (!r$found || !r$is_fn) {
      unresolved <- c(unresolved, nm)
      next
    }
    seen <- c(seen, nm)
    locals <- expr_locals(r$expr)
    for (s in setdiff(unique(expr_symbols(r$expr[[3]])), locals)) {
      if (s %in% seen || s %in% queue) {
        next
      }
      h <- static_resolve(s, bindings)
      if (!h$found) {
        next # not this site's own: a local, a formal, or a package object
      }
      if (h$is_fn) {
        queue <- c(queue, s)
      } else if (!(s %in% declared)) {
        uncovered <- c(uncovered, s)
      }
    }
  }
  list(
    fns = sort(seen),
    uncovered = sort(unique(uncovered)),
    unresolved = sort(unique(unresolved))
  )
}

# The walk over one file, given that file's declaration. Used by check_site()
# and by the run-time/static pin in the demonstration script.
static_scan_file <- function(
  path,
  roots,
  values = character(0),
  params = character(0),
  exemptions = character(0)
) {
  static_block_scan(
    static_bindings(parse_live(path)),
    roots,
    values,
    params,
    exemptions
  )
}

# ---- the deserialization check ----------------------------------------------
# A site that deserializes for itself has left the guard behind: the bytes on
# disk become an R object without anything asking what design produced them. The
# guard file is the one place allowed to do it, so it is excluded; every other
# file a site source()s is scanned exactly as the site is, transitively.
#
# The list is an enumeration and claims nothing about a name outside it. A read
# through a connection is likewise outside it, and outside AC3's watcher too — a
# candidate row carries both.

# The literal paths a file source()s, from live code only.
sourced_paths <- function(exprs) {
  out <- character(0)
  for (e in calls_to(exprs, "source")) {
    for (a in as.list(e)[-1]) {
      if (is.character(a) && length(a) == 1L) {
        out <- c(out, a)
      }
    }
  }
  unique(out)
}

# `readr::read_rds` and a bare `read_rds` are the same call to this check, so a
# declared name is matched on its last component.
bare_name <- function(x) sub("^.*::+", "", x)

deserialization_failures <- function(path, root, deser, seen = character(0)) {
  if (path %in% seen) {
    return(list(out = character(0), seen = seen))
  }
  seen <- c(seen, path)
  full <- file.path(root, path)
  if (!file.exists(full)) {
    return(list(out = character(0), seen = seen))
  }
  exprs <- tryCatch(parse_live(full), error = function(e) NULL)
  if (is.null(exprs)) {
    return(list(
      out = paste0(path, ": does not parse, so it cannot be checked"),
      seen = seen
    ))
  }
  out <- character(0)
  for (nm in deser) {
    if (length(calls_to(exprs, bare_name(nm)))) {
      out <- c(
        out,
        paste0(
          path,
          " calls ",
          nm,
          "(), which deserializes without going through the checkpoint guard"
        )
      )
    }
  }
  for (child in setdiff(sourced_paths(exprs), guard_path)) {
    res <- deserialization_failures(child, root, deser, seen)
    out <- c(out, res$out)
    seen <- res$seen
  }
  list(out = out, seen = seen)
}

all_strings <- function(e) {
  out <- character(0)
  walk <- function(x) {
    if (is.character(x)) {
      out <<- c(out, x)
    } else if (is.call(x) || is.list(x)) {
      ys <- as.list(x)
      for (i in seq_along(ys)) {
        if (!is.null(ys[[i]]) && !identical(ys[[i]], quote(expr = ))) {
          walk(ys[[i]])
        }
      }
    }
  }
  walk(e)
  out
}

run_check <- function(root = ".") {
  sites <- read_sites(file.path(root, sites_tsv))
  failures <- unlist(lapply(sites, check_site, root = root))
  list(sites = sites, failures = failures %||% character(0))
}

# ---- mutation self-test ------------------------------------------------------
# A checker that passes on a reverted guard is false coverage, which is the trap
# this repo keeps re-finding — and which this checker's predecessor fell into
# three more times. Every declared site is probed, not a representative one.

# Move the assertion to immediately after the site's first output write, INSIDE
# the block that write happens in, rather than appending it at end of file. On
# m111 both sit in one `if (sys.nframe() == 0L)` expression, so an appended copy
# would land outside that block and be caught by line number alone -- and the
# within-block move, the one an ordinary edit makes, would go unprobed.
# Returns NA when the site performs no output write; the self-test reports that
# rather than silently skipping the form.
move_assert_after_write <- function(site, src) {
  exprs <- parse_live(site$script)
  hits <- reach_scan(
    exprs,
    read_directive("idioms"),
    read_directive("appliers")
  )
  if (!length(reached_lines(hits, "saveRDS", exprs))) {
    return(NA_character_)
  }
  lines <- strsplit(src, "\n", fixed = TRUE)[[1]]
  write_at <- grep("saveRDS\\(", lines)
  write_at <- write_at[!grepl("^\\s*#", lines[write_at])]
  if (!length(write_at)) {
    return(NA_character_)
  }
  moved <- sub("ckpt_trace_assert()", "invisible(TRUE)", lines, fixed = TRUE)
  # The write may span several lines, and a statement inserted into the middle
  # of one would not parse -- which check_site() would report, giving a
  # detection for the wrong reason. So step forward to the first insertion point
  # that parses.
  for (at in seq(write_at[[1]], length(moved))) {
    cand <- paste(
      c(moved[seq_len(at)], "ckpt_trace_assert()", moved[-seq_len(at)]),
      collapse = "\n"
    )
    if (!inherits(tryCatch(parse(text = cand), error = identity), "error")) {
      return(cand)
    }
  }
  NA_character_
}

# Remove every live call to `call_name`, leaving nothing behind. Each parked
# form below then adds its own way of keeping the TEXT while the call is gone.
strip_calls <- function(src, call_name) {
  gsub(
    paste0("(?<![\\w.$])", call_name, "\\s*\\("),
    "bypassed_(",
    src,
    perl = TRUE
  )
}

mutations_for <- function(site, src, forms = read_directive("mutations")) {
  muts <- list()
  add <- function(form, label, ...) {
    if (form %in% forms) {
      muts[[length(muts) + 1L]] <<- c(list(label = label), list(...))
    }
  }

  add(
    "source-commented",
    "commented out the source() of the guard",
    text = sub(
      paste0('source("', guard_path, '")'),
      paste0('# source("', guard_path, '")'),
      src,
      fixed = TRUE
    )
  )
  add(
    "assert-after-write",
    "moved ckpt_trace_assert() after the output write",
    text = move_assert_after_write(site, src),
    reason = "this site performs no output write"
  )
  add(
    "register-non-path",
    "registered a literal NULL instead of the checkpoint path",
    text = sub(
      "ckpt_trace_register(",
      "ckpt_trace_register(NULL) # ",
      src,
      fixed = TRUE
    )
  )
  # Withdraw one declared determinant. Nothing about the SCRIPT changes; what
  # changes is the declaration, and the generating walk must then name the
  # determinant it reaches and can no longer account for. A site with no
  # declared values has nothing to withdraw and gets no such mutation.
  #
  # It must be a determinant the walk REACHES, which is not every declared one:
  # `base_formula`, `base_prior` and `brm_args` are referenced only at top level,
  # where the base fit is compiled from them, and never inside a walked body.
  # They are hashed all the same, but no walk can see them go undeclared, and
  # AC1 claims nothing about a determinant reached other than as a symbol in a
  # walked body. So the mutation is aimed at one the walk does reach.
  reached <- static_block_scan(
    static_bindings(parse_live(site$script)),
    split_decl(site$roots),
    character(0),
    split_decl(site$params),
    split_decl(site$exemptions)
  )$uncovered
  droppable <- intersect(split_decl(site$values), reached)
  if (length(droppable)) {
    dropped <- site
    dropped$values <- paste(
      setdiff(split_decl(site$values), droppable[[1]]),
      collapse = ","
    )
    add(
      "declaration-withdrawn",
      paste0(
        "withdrew the declaration of the determinant '",
        droppable[[1]],
        "'"
      ),
      text = src,
      site = dropped
    )
  } else {
    # Reported, not omitted. A form that quietly does not apply to a site reads
    # exactly like a form that passed on it, and the summary's count then says
    # more sites were probed than were.
    add(
      "declaration-withdrawn",
      "withdrew a declared determinant",
      text = NA_character_,
      reason = "this site declares no determinant the walk reaches"
    )
  }
  # One call to each declared deserialization name, planted live at top level.
  # This is AC2's own procedure, run on every site rather than on a
  # representative one.
  for (nm in read_directive("deserializers")) {
    add(
      "deserialization-planted",
      paste0("planted a live ", nm, "() call"),
      text = paste0(src, "\n", nm, '("planted.rds")\n')
    )
  }

  # And one planted in a file the site SOURCES rather than in the site itself:
  # the check follows source() transitively, and a harness that moved its read
  # into a helper file would otherwise be invisible.
  sourced <- setdiff(
    sourced_paths(parse_live(site$script)),
    guard_path
  )
  sourced <- sourced[file.exists(sourced)]
  if (length(sourced)) {
    add(
      "deserialization-planted",
      paste0("planted a live readRDS() call in ", sourced[[1]]),
      target = sourced[[1]],
      text = paste0(
        paste(readLines(sourced[[1]], warn = FALSE), collapse = "\n"),
        '\nreadRDS("planted.rds")\n'
      )
    )
  } else {
    add(
      "deserialization-planted",
      "planted a live readRDS() call in a file the site sources",
      text = NA_character_,
      reason = "this site sources nothing but the guard"
    )
  }

  # Once per declared guard call, each form removing the site's live call and
  # then trying a different way to leave the text behind. These are the
  # reversions that walked past this checker's predecessors: a text search sees
  # all of them, and each of the first four defeated a version of the parsing
  # checker too.
  for (call_name in split_decl(site$api)) {
    gone <- strip_calls(src, call_name)
    park <- paste0(call_name, "(a, b, c)")
    add(
      "deleted",
      paste0("deleted every live ", call_name, "() outright"),
      text = gone
    )
    add(
      "dead-copy",
      paste0("replaced every live ", call_name, "() with a dead copy"),
      text = paste0(gone, "\nif (FALSE) {\n  ", park, "\n}\n")
    )
    add(
      "parked-unreached",
      paste0("parked ", call_name, "() in a function nothing calls"),
      text = paste0(
        gone,
        "\nm120_parked_helper <- function() {\n  ",
        park,
        "\n}\n"
      )
    )
    add(
      "parked-false-cond",
      paste0("parked ", call_name, "() under conditions that are not literals"),
      text = paste0(
        gone,
        "\nif (0) {\n  ",
        park,
        "\n}\n",
        "if (FALSE || FALSE) {\n  ",
        park,
        "\n}\n",
        'if (getOption("m120.never", FALSE)) {\n  ',
        park,
        "\n}\n"
      )
    )
    # The idiom list may not become a back door: a DECLARED idiom around a call
    # nothing reaches still leaves the call unmade.
    add(
      "parked-idiom-unreached",
      paste0(
        "parked ",
        call_name,
        "() under a declared idiom inside a function nothing calls"
      ),
      text = paste0(
        gone,
        "\nm120_parked_idiom <- function() {\n  if (sys.nframe() == 0L) {\n    ",
        park,
        "\n  }\n}\n"
      )
    )
  }
  muts
}

# The forms AC4 requires the declared mutation list to contain. A probe that may
# be shortened at will measures nothing: each of these is a reversion that
# actually walked past a version of this checker.
required_mutations <- c(
  "deleted",
  "parked-unreached",
  "parked-false-cond",
  "parked-idiom-unreached",
  "assert-after-write",
  "register-non-path"
)

self_test <- function() {
  ok <- TRUE
  forms <- read_directive("mutations")
  missing_forms <- setdiff(required_mutations, forms)
  if (length(missing_forms)) {
    cat(
      "FAIL self-test: the declared mutation list is missing ",
      paste(missing_forms, collapse = ", "),
      "\n",
      sep = ""
    )
    return(FALSE)
  }
  planted <- 0L
  skipped <- 0L
  sites <- read_sites()
  for (site in sites) {
    src <- paste(readLines(site$script, warn = FALSE), collapse = "\n")
    site_planted <- 0L
    site_na <- 0L
    for (m in mutations_for(site, src)) {
      planted <- planted + 1L
      site_planted <- site_planted + 1L
      # A mutation plants either an edited SCRIPT or an edited DECLARATION; the
      # declaration ones leave the script alone by design.
      mutated_site <- m$site %||% site
      if (is.na(m$text)) {
        # AC4: a form that does not apply to a site is REPORTED, never skipped
        # in silence -- a form that quietly does not apply reads exactly like a
        # form that passed, and inflates nothing while the count says otherwise.
        cat(
          "N/A  self-test [",
          site$script,
          "]: ",
          m$label,
          " -- ",
          m$reason %||% "does not apply to this site",
          "\n",
          sep = ""
        )
        planted <- planted - 1L
        site_planted <- site_planted - 1L
        skipped <- skipped + 1L
        site_na <- site_na + 1L
        next
      }
      if (identical(m$text, src) && is.null(m$site)) {
        cat(
          "FAIL self-test [",
          site$script,
          "]: cannot plant '",
          m$label,
          "' -- the mutation changed nothing\n",
          sep = ""
        )
        ok <- FALSE
        next
      }
      # The whole data-raw R tree is copied, not just the one script: the
      # deserialization check follows source() transitively, and a tree holding
      # only the mutated file would make every sourced file silently absent.
      td <- tempfile("ckpt-selftest-")
      dir.create(file.path(td, "data-raw"), recursive = TRUE)
      file.copy(
        c(
          list.files("data-raw", pattern = "[.]R$", full.names = TRUE),
          sites_tsv
        ),
        file.path(td, "data-raw")
      )
      writeLines(m$text, file.path(td, m$target %||% site$script))
      found <- check_site(mutated_site, root = td)
      unlink(td, recursive = TRUE)
      if (length(found)) {
        cat(
          "PASS self-test [",
          site$script,
          "]: ",
          m$label,
          " -> detected\n",
          sep = ""
        )
      } else {
        cat(
          "FAIL self-test [",
          site$script,
          "]: ",
          m$label,
          " was NOT detected\n",
          sep = ""
        )
        ok <- FALSE
      }
    }
    if (length(check_site(site))) {
      cat(
        "FAIL self-test [",
        site$script,
        "]: the unmutated site does not pass\n",
        sep = ""
      )
      ok <- FALSE
    } else {
      cat(
        "PASS self-test [",
        site$script,
        "]: the unmutated site passes\n",
        sep = ""
      )
    }
    # The per-site count, printed rather than left to be totted up from the log:
    # a form that did not apply here is in site_na, so this number counts what
    # was actually planted on this site and never what the declaration offers.
    cat(
      "     self-test [",
      site$script,
      "]: ",
      site_planted,
      " planted over ",
      length(split_decl(site$api)),
      " declared guard call(s), ",
      site_na,
      " not applying\n",
      sep = ""
    )
  }
  # The quantification, stated rather than left to be counted off the log: this
  # probe is per site, per declared form, and per declared guard call, and a
  # form that did not apply is named above rather than absorbed here.
  cat(
    "\nself-test: ",
    planted,
    " mutations planted over ",
    length(sites),
    " site(s) and ",
    length(forms),
    " declared form(s), each detected; ",
    skipped,
    " form(s) reported as not applying.\n",
    sep = ""
  )
  ok
}

# ---- entry point -------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--self-test" %in% args) {
    quit(status = if (self_test()) 0L else 1L)
  }
  res <- run_check()
  if (length(res$failures)) {
    cat(
      "FAIL: ",
      length(res$failures),
      " checkpoint-routing failure(s):\n",
      sep = ""
    )
    for (f in res$failures) {
      cat("  - ", f, "\n", sep = "")
    }
    quit(status = 1L)
  }
  cat(
    "OK: ",
    length(res$sites),
    " declared resume site(s) route through the checkpoint guard.\n",
    sep = ""
  )
  cat(
    "(Declared sites only -- the run-time trace in checkpoint-guard.R is what",
    " covers a site nobody declared.)\n",
    sep = ""
  )
}
